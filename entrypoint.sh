#!/bin/bash
set -e

# Ensure profile directory permissions and remove stale lock files unconditionally before startup
mkdir -p /data/thorium_profile
chmod -R 777 /data/thorium_profile 2>/dev/null || true
rm -f /data/thorium_profile/Singleton*

WS="${WINDOW_SIZE:-1280,720}"
WS_X="${WS//,/x}"

FLAGS=(
  "--no-sandbox"
  "--disable-dev-shm-usage"
  "--no-first-run"
  "--no-default-browser-check"
  "--user-data-dir=/data/thorium_profile"
  "--remote-debugging-port=9223"
  "--remote-debugging-address=127.0.0.1"
  "--remote-allow-origins=*"
  "--window-size=${WS}"
  "--disable-gpu"
  "--disable-software-rasterizer"
)
if [ "$DISABLE_PASSKEYS" = "true" ]; then
  FLAGS+=("--disable-features=WebAuthentication,WebAuthenticationUI,PasskeyRegistration,WebAuthenticationConditionalUI")
fi
if [ "$BLOCK_NEW_WINDOWS" = "true" ]; then
  FLAGS+=("--block-new-web-contents")
fi
if [ "$DISABLE_AUTOMATION" = "true" ]; then
  FLAGS+=("--disable-blink-features=AutomationControlled")
fi
if [ -n "$USER_AGENT" ]; then
  FLAGS+=("--user-agent=$USER_AGENT")
fi
if [ -n "$EXTRA_FLAGS" ]; then
  echo "Appending EXTRA_FLAGS: $EXTRA_FLAGS"
  eval "EXTRA_ARR=($EXTRA_FLAGS)"
  FLAGS+=("${EXTRA_ARR[@]}")
fi

if [ $# -gt 0 ]; then
  FLAGS+=("$@")
fi

BIN=/opt/chromium.org/thorium/thorium-browser
if [ ! -f "$BIN" ]; then BIN=$(which thorium-browser || which thorium); fi

CMD_STR=""
for flag in "${FLAGS[@]}"; do
  CMD_STR="$CMD_STR \"$flag\""
done

mkdir -p /tmp/supervisor /var/log/supervisor

cat <<CONF > /tmp/supervisord.conf
[supervisord]
nodaemon=true
logfile=/tmp/supervisord.log
pidfile=/tmp/supervisord.pid

[program:socat]
command=socat TCP-LISTEN:9222,fork,reuseaddr TCP:127.0.0.1:9223
priority=10
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

CONF

if [ "$USE_XVFB" = "true" ]; then
cat <<CONF >> /tmp/supervisord.conf
[program:xvfb]
command=Xvfb :99 -screen 0 ${WS_X}x24 -nolisten tcp
priority=5
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:thorium]
command=${BIN} ${CMD_STR}
environment=DISPLAY=":99"
priority=20
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
CONF
else
cat <<CONF >> /tmp/supervisord.conf
[program:thorium]
command=${BIN} --headless=new ${CMD_STR}
priority=20
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
CONF
fi

exec supervisord -c /tmp/supervisord.conf
