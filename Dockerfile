FROM alpine:edge

ARG INSTRUCTION_SET=AVX2
ENV INSTRUCTION_SET=${INSTRUCTION_SET}

# Set environment variables
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Enable community and testing repositories for packages, fonts, and socat
RUN echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
        chromium \
        ca-certificates \
        ttf-freefont \
        font-noto-emoji \
        nss \
        nspr \
        freetype \
        harfbuzz \
        alsa-lib \
        ffmpeg \
        bash \
        tzdata \
        socat && \
    (apk add --no-cache font-wqy-zenhei || apk add --no-cache wqy-zenhei || true) && \
    rm -rf /var/cache/apk/*

# Create non-root user for security and prepare data profile directory
RUN addgroup -S thorium && adduser -S -G thorium thorium && \
    mkdir -p /home/thorium /data/thorium_profile && \
    chown -R thorium:thorium /home/thorium /data/thorium_profile

# Create symlink so thorium-browser calls chromium
RUN ln -sf /usr/bin/chromium-browser /usr/bin/thorium-browser

# Create wrapper script that runs socat to relay 0.0.0.0:9222 to 127.0.0.1:9223 (bypassing Chromium M113+ loopback restriction)
RUN echo '#!/bin/bash' > /usr/bin/wrapped-thorium && \
    echo 'BIN=/usr/bin/chromium-browser' >> /usr/bin/wrapped-thorium && \
    echo 'if ! pgrep chromium > /dev/null && ! pgrep thorium > /dev/null; then' >> /usr/bin/wrapped-thorium && \
    echo '  rm -f /data/thorium_profile/Singleton*' >> /usr/bin/wrapped-thorium && \
    echo 'fi' >> /usr/bin/wrapped-thorium && \
    echo 'socat TCP-LISTEN:9222,fork,reuseaddr TCP:127.0.0.1:9223 &' >> /usr/bin/wrapped-thorium && \
    echo 'exec ${BIN} --remote-debugging-port=9223 --remote-debugging-address=127.0.0.1 --remote-allow-origins="*" "$@"' >> /usr/bin/wrapped-thorium && \
    chmod +x /usr/bin/wrapped-thorium

# Record instruction set info in container
RUN echo "Thorium/Chromium built for ${INSTRUCTION_SET} on Alpine Linux with socat CDP relay" > /etc/thorium-info.txt

WORKDIR /home/thorium

# Declare persistent profile volume
VOLUME ["/data/thorium_profile"]

# Switch to non-root user
USER thorium

# Expose CDP Remote Debugging Port
EXPOSE 9222

# Default command with all required CDP flags
CMD ["/usr/bin/wrapped-thorium", "--headless=new", "--no-sandbox", "--disable-dev-shm-usage", "--user-data-dir=/data/thorium_profile", "--disable-gpu", "--disable-software-rasterizer"]