# Ultimate Thorium Headless & Automation Browser Container
FROM debian:bookworm-slim AS base

# Prevent interactive prompts during apt installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core system dependencies, media codecs, X11/Xvfb tools, xauth, and full font packs
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    dpkg \
    procps \
    socat \
    xvfb \
    xauth \
    x11vnc \
    locales \
    ffmpeg \
    libasound2 \
    libatspi2.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libexpat1 \
    libfontconfig1 \
    libfreetype6 \
    libgbm1 \
    libgcc-s1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libharfbuzz0b \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcb-dri3-0 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxshmfence1 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    fonts-liberation \
    fonts-freefont-ttf \
    fonts-wqy-zenhei \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# Configure UTF-8 Locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Create non-root user and persistent profile directory
RUN groupadd -r thorium && useradd -r -g thorium -G audio,video thorium \
    && mkdir -p /home/thorium /data/thorium_profile \
    && chown -R thorium:thorium /home/thorium /data/thorium_profile

# Build Arguments for Version and CPU Instruction Set
ARG THORIUM_VERSION=M138.0.7204.303
ARG INSTRUCTION_SET=AVX2
ARG GITHUB_TOKEN=""
ENV THORIUM_VERSION=${THORIUM_VERSION} \
    INSTRUCTION_SET=${INSTRUCTION_SET}

# Download & Install Official Thorium Package from GitHub Releases
RUN echo "Installing Thorium ${THORIUM_VERSION} for ${INSTRUCTION_SET}..." && \
    CLEAN_VER="${THORIUM_VERSION#M}" && \
    CURL_HDR="" && \
    if [ -n "$GITHUB_TOKEN" ]; then CURL_HDR="-H \"Authorization: Bearer ${GITHUB_TOKEN}\""; fi && \
    RELEASE_JSON=$(eval "curl -s $CURL_HDR 'https://api.github.com/repos/Alex313031/thorium/releases/tags/${THORIUM_VERSION}'") && \
    DEB_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep -i "${INSTRUCTION_SET}" | grep "\.deb" | head -n 1 | cut -d '"' -f 4) && \
    if [ -z "$DEB_URL" ]; then \
        DEB_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep "\.deb" | head -n 1 | cut -d '"' -f 4); \
    fi && \
    if [ -z "$DEB_URL" ]; then \
        DEB_URL="https://github.com/Alex313031/thorium/releases/download/${THORIUM_VERSION}/thorium-browser_${CLEAN_VER}_${INSTRUCTION_SET}.deb"; \
    fi && \
    echo "Fetching ${DEB_URL}" && \
    (wget -q "${DEB_URL}" -O /tmp/thorium.deb || \
     wget -q "https://github.com/Alex313031/thorium/releases/download/${THORIUM_VERSION}/thorium-browser_${CLEAN_VER}_${INSTRUCTION_SET}.deb" -O /tmp/thorium.deb || \
     wget -q "https://github.com/Alex313031/thorium/releases/download/${THORIUM_VERSION}/thorium-browser_${CLEAN_VER}_AVX2.deb" -O /tmp/thorium.deb) && \
    apt-get update && \
    apt-get install -y /tmp/thorium.deb && \
    rm /tmp/thorium.deb && \
    rm -rf /var/lib/apt/lists/*

# Symlink binary for convenience
RUN ln -sf /opt/chromium.org/thorium/thorium-browser /usr/bin/thorium-browser || true

# Create Clean Startup Wrapper Script using SERVERARGS env var for xvfb-run
RUN cat << 'EOF' > /usr/bin/wrapped-thorium
#!/bin/bash
set -f
BIN=/opt/chromium.org/thorium/thorium-browser
if [ ! -f "$BIN" ]; then BIN=$(which thorium-browser || which thorium); fi

# Remove stale profile lock files unconditionally before startup
rm -f /data/thorium_profile/Singleton*

socat TCP-LISTEN:9222,fork,reuseaddr TCP:127.0.0.1:9223 &
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
if [ "$USE_XVFB" = "true" ]; then
  echo "Starting with Xvfb virtual display (${WS_X})..."
  exec xvfb-run -a --server-args="-screen 0 ${WS_X}x24" "${BIN}" "${FLAGS[@]}" "$@"
else
  exec "${BIN}" --headless=new "${FLAGS[@]}" "$@"
fi
EOF
RUN chmod +x /usr/bin/wrapped-thorium

# Write container build information file
RUN echo "Thorium ${THORIUM_VERSION} (${INSTRUCTION_SET}) built on Debian Bookworm Slim" > /etc/thorium-info.txt

WORKDIR /home/thorium

VOLUME ["/data/thorium_profile"]

USER thorium

EXPOSE 9222

CMD ["/usr/bin/wrapped-thorium"]