# Thorium Docker (Stable & Beta)

Высокопроизводительный, мульти-платформенный Docker-образ браузера **Thorium**, оптимизированный для веб-скрапинга, автоматизации (Playwright, Selenium, Puppeteer), медиа-стриминга и удаленной отладки по CDP.

---

## 📌 Особенности и возможности

- 🚀 **Официальные сборки Thorium**: Скачивание и установка оригинальных `.deb` пакетов от [Alex313031/thorium](https://github.com/Alex313031/thorium/releases) под все наборы инструкций CPU (`AVX2`, `AVX`, `SSE3`, `SSE4`).
- ⚡ **Два канала релиза**:
  - **`stable` / `latest`**: Последняя стабильная версия (Thorium M138).
  - **`beta`**: Свежая бета-версия (Thorium M150 / M144).
- 🎬 **Полный медиа-стек**: Встроенные кодеки `ffmpeg`, поддержка Widevine DRM и аудио-сервисов (ALSA/PulseAudio).
- 🔤 **Мультиязычные шрифты**: Заранее установлены шрифты CJK (китайский, японский, корейский), кириллица, Emoji и FreeFont (`fonts-wqy-zenhei`, `fonts-noto-color-emoji`, `fonts-liberation`, `fonts-dejavu`).
- 🛡️ **Anti-Bot & Google OAuth Stealth**: 
  - Отключены флаги автоматизации (`--disable-blink-features=AutomationControlled`).
  - Актуальный десктопный Chrome User-Agent.
  - Автоматическая очистка Singleton-блокировок профиля.
- 🖥️ **Поддержка Headless и Xvfb (Virtual Display)**:
  - Режим по умолчанию: `--headless=new`.
  - Режим Xvfb: Установите переменную `USE_XVFB=true`, чтобы запустить браузер на виртуальном дисплее (обходит продвинутые проверки на headless у Cloudflare / Google).
- 🔌 **Безопасный CDP Bridge (порт 9222)**: Встроенный `socat`-мост для безопасного проброса `0.0.0.0:9222 -> 127.0.0.1:9223` (обходит ограничения лупбэка Chromium M113+).

---

## 🐳 Теги контейнеров в GHCR (`ghcr.io/bropines/thorium-docker`)

### Стабильный канал (Stable / Latest):
- `latest`, `stable`, `latest-AVX2`, `stable-AVX2` — Версия AVX2 (Рекомендуется)
- `latest-AVX`, `stable-AVX` — Версия AVX
- `latest-SSE3`, `stable-SSE3` — Версия SSE3
- `latest-SSE4`, `stable-SSE4` — Версия SSE4

### Бета канал (Beta):
- `beta`, `beta-AVX2` — Бета-версия AVX2
- `beta-AVX`, `beta-SSE3`, `beta-SSE4` — Бета-версии под другие CPU

---

## 🚀 Быстрый запуск

### 1. Запуск через Docker run (CDP Headless)

```bash
docker run -d \
  --name thorium-browser \
  -p 9222:9222 \
  -v ./profile:/data/thorium_profile \
  --security-opt seccomp=unconfined \
  ghcr.io/bropines/thorium-docker:latest-AVX2
```

### 2. Запуск в режиме Xvfb (Virtual Display для сложной эмуляции)

```bash
docker run -d \
  --name thorium-browser-xvfb \
  -p 9222:9222 \
  -e USE_XVFB=true \
  -e WINDOW_SIZE=1920x1080x24 \
  -v ./profile:/data/thorium_profile \
  ghcr.io/bropines/thorium-docker:latest-AVX2
```

### 3. Использование Docker Compose

```yaml
services:
  thorium-browser:
    image: ghcr.io/bropines/thorium-docker:latest-AVX2
    container_name: thorium-browser
    restart: unless-stopped
    network_mode: "host"
    environment:
      - WINDOW_SIZE=1280,720
      - USE_XVFB=false
    volumes:
      - ./profile:/data/thorium_profile
```

---

## 💻 Подключение автотестов и скраперов

### Selenium (Python):
```python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

chrome_options = Options()
chrome_options.add_experimental_option("debuggerAddress", "127.0.0.1:9222")

driver = webdriver.Chrome(options=chrome_options)
driver.get("https://google.com")
print(driver.title)
```

### Playwright (Node.js):
```javascript
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.connectOverCDP('http://127.0.0.1:9222');
  const context = browser.contexts()[0];
  const page = await context.newPage();
  await page.goto('https://google.com');
})();
```

---

## 📄 Лицензия

BSD 3-Clause License
