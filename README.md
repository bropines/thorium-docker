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
- 🎛️ **Динамическое изменение флагов БЕЗ ПЕРЕСБОРКИ**:
  - `EXTRA_FLAGS`: Прокидывайте **любые флаговые аргументы Chromium** прямо в `docker-compose.yml` / `docker run -e` без пересборки контейнера!
  - `DISABLE_PASSKEYS=true/false`: Отключает всплывающие окна Passkey / WebAuthn (по умолчанию `true`).
  - `BLOCK_NEW_WINDOWS=true/false`: Запрещает браузеру спавнить новые окна/вкладки (по умолчанию `true`).
  - `DISABLE_AUTOMATION=true/false`: Скрывает `AutomationControlled` (по умолчанию `true`).
  - `USER_AGENT`: Произвольный User-Agent.

---

## 🚀 Быстрый запуск и Docker Compose

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
      - DISABLE_PASSKEYS=true
      - BLOCK_NEW_WINDOWS=true
      - EXTRA_FLAGS=--proxy-pac-url=http://127.0.0.1:21048/proxy.pac --incognito
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

---

## 📄 Лицензия

BSD 3-Clause License
