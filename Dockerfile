# Multi-stage build for Thorium headless browser
FROM debian:bookworm-slim AS base

# Install system dependencies, fonts, and socat
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    fonts-liberation \
    fonts-freefont-ttf \
    fonts-wqy-zenhei \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-dejavu-core \
    libgtk-3-0 \
    libnss3 \
    libnspr4 \
    libfreetype6 \
    libharfbuzz0b \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    libxss1 \
    libxtst6 \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libgbm1 \
    libasound2 \
    libatspi2.0-0 \
    libxshmfence1 \
    libdrm2 \
    ffmpeg \
    wget \
    dpkg \
    procps \
    socat \
    locales \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create non-root user for security and prepare data profile directory
RUN groupadd -r thorium && useradd -r -g thorium -G audio,video thorium \
    && mkdir -p /home/thorium /data/thorium_profile \
    && chown -R thorium:thorium /home/thorium /data/thorium_profile

ARG THORIUM_VERSION=M130.0.6723.174
ARG INSTRUCTION_SET=AVX2
ENV THORIUM_VERSION=${THORIUM_VERSION}
ENV INSTRUCTION_SET=${INSTRUCTION_SET}

# Download & install official Thorium package from GitHub release
RUN echo "Downloading Thorium ${THORIUM_VERSION} for ${INSTRUCTION_SET}..." && \
    CLEAN_VER="${THORIUM_VERSION#M}" && \
    URL="https://github.com/Alex313031/thorium/releases/download/${THORIUM_VERSION}/thorium-browser_${CLEAN_VER}_${INSTRUCTION_SET}.deb" && \
    echo "Downloading ${URL}" && \
    wget -q "${URL}" -O /tmp/thorium.deb && \
    apt-get update && \
    apt-get install -y /tmp/thorium.deb && \
    rm /tmp/thorium.deb && \
    rm -rf /var/lib/apt/lists/*

RUN ln -sf /opt/chromium.org/thorium/thorium-browser /usr/bin/thorium-browser || true

# Create wrapper script with socat bridge for CDP (0.0.0.0:9222 -> 127.0.0.1:9223)
RUN echo '#!/bin/bash' > /usr/bin/wrapped-thorium && \
    echo 'BIN=/opt/chromium.org/thorium/thorium-browser' >> /usr/bin/wrapped-thorium && \
    echo 'if [ ! -f "$BIN" ]; then BIN=$(which thorium-browser || which thorium); fi' >> /usr/bin/wrapped-thorium && \
    echo 'if ! pgrep thorium > /dev/null; then' >> /usr/bin/wrapped-thorium && \
    echo '  rm -f /data/thorium_profile/Singleton*' >> /usr/bin/wrapped-thorium && \
    echo 'fi' >> /usr/bin/wrapped-thorium && \
    echo 'socat TCP-LISTEN:9222,fork,reuseaddr TCP:127.0.0.1:9223 &' >> /usr/bin/wrapped-thorium && \
    echo 'exec ${BIN} --headless=new --no-sandbox --disable-dev-shm-usage --user-data-dir=/data/thorium_profile --disable-gpu --disable-software-rasterizer --remote-debugging-port=9223 --remote-debugging-address=127.0.0.1 --remote-allow-origins="*" --disable-blink-features=AutomationControlled --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.6723.174 Safari/537.36" "$@"' >> /usr/bin/wrapped-thorium && \
    chmod +x /usr/bin/wrapped-thorium

WORKDIR /home/thorium

VOLUME ["/data/thorium_profile"]

USER thorium

EXPOSE 9222

CMD ["/usr/bin/wrapped-thorium"]