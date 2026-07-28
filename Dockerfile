# Multi-stage build for Thorium headless browser
FROM debian:bullseye-slim AS base

# Install system dependencies and fonts for headless browser
RUN apt-get update && apt-get install -y \
    ca-certificates \
    fonts-liberation \
    fonts-freefont-ttf \
    fonts-wqy-zenhei \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
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
    locales \
    && rm -rf /var/lib/apt/lists/*

# Set locale for proper character encoding
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create non-root user for security and prepare data profile directory
RUN groupadd -r thorium && useradd -r -g thorium -G audio,video thorium \
    && mkdir -p /home/thorium /config /data/thorium_profile \
    && chown -R thorium:thorium /home/thorium /config /data/thorium_profile

# Thorium installation stage
FROM base AS thorium-install

# Switch back to root for installation
USER root

# Install additional dependencies for Thorium
RUN apt-get update && apt-get install -y \
    wget \
    dpkg \
    && rm -rf /var/lib/apt/lists/*

# Set Thorium version and instruction set
ARG THORIUM_VERSION=M138.0.7204.303
ARG INSTRUCTION_SET=AVX2
ENV THORIUM_VERSION=${THORIUM_VERSION}
ENV INSTRUCTION_SET=${INSTRUCTION_SET}

# Download Thorium package
RUN echo "Downloading Thorium ${THORIUM_VERSION} for ${INSTRUCTION_SET}..." && \
    echo "download URL: https://github.com/Alex313031/thorium/releases/download/${THORIUM_VERSION}/thorium-browser_${THORIUM_VERSION#M}_${INSTRUCTION_SET}.deb" && \
    wget -q "https://github.com/Alex313031/thorium/releases/download/${THORIUM_VERSION}/thorium-browser_${THORIUM_VERSION#M}_${INSTRUCTION_SET}.deb" -O thorium.deb

# Try alternative URL if download failed
RUN if [ ! -f thorium.deb ] || [ ! -s thorium.deb ]; then \
        echo "Trying alternative URL format..." && \
        wget -q "https://github.com/Alex313031/thorium/releases/download/${THORIUM_VERSION}/thorium_${THORIUM_VERSION}_amd64_${INSTRUCTION_SET}.deb" -O thorium.deb; \
    fi

# Install Thorium package
RUN echo "Installing Thorium..." && \
    apt-get update && \
    apt install -y ./thorium.deb && \
    rm thorium.deb && \
    rm -rf /var/lib/apt/lists/*

# Verify installation
RUN echo "Verifying installation..." && \
    ls -la /opt/chromium.org/thorium/ && \
    ls -la /usr/bin/thorium-browser

# Create symlink
RUN ln -sf /opt/chromium.org/thorium/thorium-browser /usr/bin/thorium

# Create wrapper script for better container compatibility
RUN echo '#!/bin/bash' > /usr/bin/wrapped-thorium
RUN echo 'BIN=/opt/chromium.org/thorium/thorium-browser' >> /usr/bin/wrapped-thorium
RUN echo 'if ! pgrep thorium > /dev/null; then' >> /usr/bin/wrapped-thorium
RUN echo '  rm -f /data/thorium_profile/Singleton*' >> /usr/bin/wrapped-thorium
RUN echo '  rm -f $HOME/.config/thorium/Singleton*' >> /usr/bin/wrapped-thorium
RUN echo 'fi' >> /usr/bin/wrapped-thorium
RUN echo 'exec ${BIN} "$@"' >> /usr/bin/wrapped-thorium
RUN chmod +x /usr/bin/wrapped-thorium

# Add instruction set info to container
RUN echo "Thorium ${THORIUM_VERSION} built for ${INSTRUCTION_SET}" > /etc/thorium-info.txt

# Final stage
FROM thorium-install

WORKDIR /home/thorium

# Declare volume for persistent CDP session profiles
VOLUME ["/data/thorium_profile"]

# Switch to non-root user
USER thorium

# Expose port for CDP remote debugging
EXPOSE 9222

# Default command for headless CDP mode
CMD ["/usr/bin/wrapped-thorium", "--headless=new", "--no-sandbox", "--disable-dev-shm-usage", "--remote-debugging-port=9222", "--remote-debugging-address=0.0.0.0", "--user-data-dir=/data/thorium_profile", "--disable-gpu", "--disable-software-rasterizer"]