# Thorium Docker (Headless & Automation Browser)

[![Build & Push](https://github.com/bropines/thorium-docker/actions/workflows/build.yml/badge.svg)](https://github.com/bropines/thorium-docker/actions/workflows/build.yml)
[![Performance Benchmark](https://github.com/bropines/thorium-docker/actions/workflows/benchmark.yml/badge.svg)](https://github.com/bropines/thorium-docker/actions/workflows/benchmark.yml)
[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](LICENSE)

[English](README.md) | [Русский](README.ru.md)

High-performance Docker container for the **Thorium Browser**, optimized for headless operations, Chrome DevTools Protocol (CDP) remote debugging, web scraping, and automation frameworks (Playwright, Selenium, Puppeteer). Supports multiple CPU instruction set builds.

---

## 📌 Project Overview

[Thorium](https://github.com/Alex313031/thorium) is a performance-optimized build of Chromium (boasting an 8%-38% speedup over stock Chromium).

This repository provides automated Docker builds published to **GitHub Container Registry (GHCR)**:

- 🚀 **Official Thorium Releases**: Installs authentic `.deb` packages directly from [Alex313031/thorium](https://github.com/Alex313031/thorium/releases).
- 🔄 **Dual Release Channels**:
  - **`stable` / `latest`**: Production-ready stable release (Thorium M138).
  - **`beta`**: Cutting-edge beta release (Thorium M138Beta1 / M150).
- ⚡ **CPU Instruction Sets**: Tailored builds for `AVX2`, `AVX`, `SSE3`, and `SSE4`.
- 🌍 **Font & Language Support**: Pre-installed CJK (Chinese, Japanese, Korean), Cyrillic, Emoji, and FreeFont packages (`fonts-wqy-zenhei`, `fonts-noto-color-emoji`, `fonts-liberation`, `fonts-dejavu`).
- 🎬 **Full Media Capabilities**: `ffmpeg` codecs, Widevine DRM support, and audio subsystem integrations.
- 🔒 **Security Hardening**: Non-root container process execution (`thorium` user).
- 🎛️ **Dynamic Flag Configuration (No Image Rebuild Required)**:
  - `EXTRA_FLAGS`: Pass any custom Chromium flags directly in `docker-compose.yml` or `docker run -e`.
  - `DISABLE_PASSKEYS=true/false`: Optionally disable Passkey / WebAuthn popups.
  - `BLOCK_NEW_WINDOWS=true/false`: Optionally prevent opening new windows or popup tabs.
  - `DISABLE_AUTOMATION=true/false`: Optionally strip `AutomationControlled` flags.
  - `USER_AGENT`: Custom User-Agent string override.
- 🖥️ **Headless & Virtual Display (Xvfb)**:
  - Default mode: `--headless=new`.
  - Xvfb mode: Set `USE_XVFB=true` to render on a virtual X11 display (bypassing anti-bot / headless detection).
- 🔌 **Remote Debugging**: Native Chrome DevTools Remote Debugging on port `9222`.

---

## ⚡ CPU Instruction Sets

| Instruction Set | Performance | Compatibility | Recommended Use Case |
|---|---|---|---|
| **AVX2** | Maximum | Modern CPUs (2013+) | Production, high load (Recommended) |
| **AVX** | High | Older CPUs (2011+) | Balanced performance & compatibility |
| **SSE3** | Medium | Legacy CPUs (2004+) | Basic compatibility |
| **SSE4** | Base | Maximum range | Maximum hardware compatibility |

---

## 🐳 Container Tags in GHCR (`ghcr.io/bropines/thorium-docker`)

### Stable Channel:
- `latest`, `stable`, `latest-AVX2`, `stable-AVX2` — Recommended AVX2 build
- `latest-AVX`, `stable-AVX` — AVX build
- `latest-SSE3`, `stable-SSE3` — SSE3 build
- `latest-SSE4`, `stable-SSE4` — SSE4 build

### Beta Channel:
- `beta`, `beta-AVX2` — Beta AVX2 build
- `beta-AVX`, `beta-SSE3`, `beta-SSE4` — Beta builds for other CPU architectures

---

## 🚀 Quick Start

### Using Docker Run

```bash
docker run -d \
  --name thorium-browser \
  -p 9222:9222 \
  -v ./profile:/data/thorium_profile \
  --security-opt seccomp=unconfined \
  ghcr.io/bropines/thorium-docker:latest-AVX2
```

### Using Docker Compose

```yaml
services:
  thorium-browser:
    image: ghcr.io/bropines/thorium-docker:latest-AVX2
    container_name: thorium-browser
    restart: unless-stopped
    network_mode: "host"
    environment:
      - WINDOW_SIZE=1280,720
      - DISABLE_PASSKEYS=true
      - EXTRA_FLAGS=--proxy-pac-url=http://127.0.0.1:21048/proxy.pac --incognito
    volumes:
      - ./profile:/data/thorium_profile
```

---

## 💻 Automation Examples

### Selenium (Python):
```python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

chrome_options = Options()
chrome_options.add_experimental_option("debuggerAddress", "localhost:9222")

driver = webdriver.Chrome(options=chrome_options)
driver.get("https://example.com")
print(driver.title)
driver.save_screenshot("screenshot.png")
driver.quit()
```

### Playwright (Node.js):
```javascript
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.connectOverCDP('http://localhost:9222');
  const context = browser.contexts()[0];
  const page = await context.newPage();
  await page.goto('https://example.com');
  console.log(await page.title());
})();
```

---

## 📊 Performance Benchmarks

This project includes an automated benchmarking suite (`benchmark/`) to measure cold and hot startup times across CPU architectures.

### Local Development & Testing

```bash
# Build AVX2 version (default)
make build-avx2

# Build all instruction set versions
make build-all

# Run benchmark suite
make test
```

---

## 📄 License

BSD 3-Clause License
