# Ultimate Thorium Headless & Automation Browser Container
FROM debian:bookworm-slim AS base

# Prevent interactive prompts during apt installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core system dependencies, media codecs, X11/Xvfb tools, and full font packs
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    dpkg \
    procps \
    socat \
    xvfb \
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
ENV THORIUM_VERSION=${THORIUM_VERSION} \
    INSTRUCTION_SET=${INSTRUCTION_SET}

# Download & Install Official Thorium Package from GitHub Releases
RUN echo "Installing Thorium ${THORIUM_VERSION} for ${INSTRUCTION_SET}..." && \
    CLEAN_VER="${THORIUM_VERSION#M}" && \
    DEB_URL=$(curl -s "https://api.github.com/repos/Alex313031/thorium/releases/tags/${THORIUM_VERSION}" | grep "browser_download_url" | grep -i "${INSTRUCTION_SET}" | grep "\.deb" | head -n 1 | cut -d '"' -f 4) && \
    if [ -z "$DEB_URL" ]; then \
        DEB_URL=$(curl -s "https://api.github.com/repos/Alex313031/thorium/releases/tags/${THORIUM_VERSION}" | grep "browser_download_url" | grep "\.deb" | head -n 1 | cut -d '"' -f 4); \
    fi && \
    if [ -z "$DEB_URL" ]; then \
        DEB_URL="https://github.com/Alex313031/thorium/releases/download/${THORIUM_VERSION}/thorium-browser_${CLEAN_VER}_${INSTRUCTION_SET}.deb"; \
    fi && \
    echo "Fetching ${DEB_URL}" && \
    wget -q "${DEB_URL}" -O /tmp/thorium.deb && \
    apt-get update && \
    apt-get install -y /tmp/thorium.deb && \
    rm /tmp/thorium.deb && \
    rm -rf /var/lib/apt/lists/*

# Symlink binary for convenience
RUN ln -sf /opt/chromium.org/thorium/thorium-browser /usr/bin/thorium-browser || true

# Create Ultimate Startup Wrapper Script
RUN echo '#!/bin/bash' > /usr/bin/wrapped-thorium && \
    echo 'BIN=/opt/chromium.org/thorium/thorium-browser' >> /usr/bin/wrapped-thorium && \
    echo 'if [ ! -f "$BIN" ]; then BIN=$(which thorium-browser || which thorium); fi' >> /usr/bin/wrapped-thorium && \
    echo 'if ! pgrep thorium > /dev/null; then' >> /usr/bin/wrapped-thorium && \
    echo '  rm -f /data/thorium_profile/Singleton*' >> /usr/bin/wrapped-thorium && \
    echo 'fi' >> /usr/bin/wrapped-thorium && \
    echo 'socat TCP-LISTEN:9222,fork,reuseaddr TCP:127.0.0.1:9223 &' >> /usr/bin/wrapped-thorium && \
    echo 'FLAGS=("--no-sandbox" "--disable-dev-shm-usage" "--user-data-dir=/data/thorium_profile" "--remote-debugging-port=9223" "--remote-debugging-address=127.0.0.1" "--remote-allow-origins=*" "--disable-blink-features=AutomationControlled" "--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.7204.303 Safari/537.36")' >> /usr/bin/wrapped-thorium && \
    echo 'if [ "$USE_XVFB" = "true" ]; then' >> /usr/bin/wrapped-thorium && \
    echo '  echo "Starting with Xvfb virtual display..."' >> /usr/bin/wrapped-thorium && \
    echo '  exec xvfb-run --server-args="-screen 0 ${WINDOW_SIZE:-1280x720x24}" ${BIN} "${FLAGS[@]}" "$@"' >> /usr/bin/wrapped-thorium && \
    echo 'else' >> /usr/bin/wrapped-thorium && \
    echo '  exec ${BIN} --headless=new --disable-gpu --disable-software-rasterizer "${FLAGS[@]}" "$@"' >> /usr/bin/wrapped-thorium && \
    echo 'fi' >> /usr/bin/wrapped-thorium && \
    chmod +x /usr/bin/wrapped-thorium

# Write container build information file
RUN echo "Thorium ${THORIUM_VERSION} (${INSTRUCTION_SET}) built on Debian Bookworm Slim" > /etc/thorium-info.txt

WORKDIR /home/thorium

VOLUME ["/data/thorium_profile"]

USER thorium

EXPOSE 9222

CMD ["/usr/bin/wrapped-thorium"]