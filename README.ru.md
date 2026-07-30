# Thorium Docker (Headless & Automation Browser)

[![Build & Push](https://github.com/bropines/thorium-docker/actions/workflows/build.yml/badge.svg)](https://github.com/bropines/thorium-docker/actions/workflows/build.yml)
[![Performance Benchmark](https://github.com/bropines/thorium-docker/actions/workflows/benchmark.yml/badge.svg)](https://github.com/bropines/thorium-docker/actions/workflows/benchmark.yml)
[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](LICENSE)

[English](README.md) | [Русский](README.ru.md)

Высокопроизводительный Docker-образ браузера **Thorium**, оптимизированный для работы в headless-режиме, отладки по CDP, веб-скрапинга и автоматизации (Playwright, Selenium, Puppeteer). Поддерживает различные наборы инструкций CPU.

---

## 📌 Обзор проекта

[Thorium](https://github.com/Alex313031/thorium) — это оптимизированная по производительности версия браузера на базе Chromium (прирост производительности на 8%-38% по сравнению с обычным Chromium).

Этот проект предоставляет автоматическую сборку и публикацию Docker-образов в **GitHub Container Registry (GHCR)**:

- 🚀 **Официальные сборки Thorium**: Установка оригинальных `.deb` пакетов [Alex313031/thorium](https://github.com/Alex313031/thorium/releases).
- 🔄 **Два канала релиза**:
  - **`stable` / `latest`**: Стабильная версия (Thorium M138).
  - **`beta`**: Свежая бета-версия (Thorium M138Beta1 / M150).
- ⚡ **Поддержка наборов инструкций CPU**: Сборки под `AVX2`, `AVX`, `SSE3`, `SSE4`.
- 🌍 **Мультиязычность и шрифты**: Встроенные шрифты CJK (китайский, японский, корейский), кириллица, Emoji и FreeFont (`fonts-wqy-zenhei`, `fonts-noto-color-emoji`, `fonts-liberation`, `fonts-dejavu`).
- 🎬 **Полный медиа-стек**: Кодеки `ffmpeg`, Widevine DRM и аудио-подсистема.
- 🔒 **Безопасность**: Запуск от имени не-root пользователя (`thorium`).
- 🎛️ **Динамические флаги БЕЗ ПЕРЕСБОРКИ**:
  - `EXTRA_FLAGS`: Прокидывайте **любые флаговые аргументы Chromium** прямо в `docker-compose.yml` без пересборки контейнера.
  - `DISABLE_PASSKEYS=true/false`: Отключает всплывающие окна Passkey / WebAuthn.
  - `BLOCK_NEW_WINDOWS=true/false`: Запрещает браузеру спавнить новые окна/вкладки.
  - `DISABLE_AUTOMATION=true/false`: Скрывает `AutomationControlled`.
  - `USER_AGENT`: Произвольный User-Agent.
- 🖥️ **Поддержка Headless и Xvfb (Virtual Display)**:
  - Режим по умолчанию: `--headless=new`.
  - Режим Xvfb: Установите переменную `USE_XVFB=true`, чтобы запустить браузер на виртуальном дисплее.
- 🔌 **Удаленная отладка**: Поддержка Chrome DevTools Remote Debugging (порт 9222).

---

## ⚡ Поддержка инструкций CPU

| Набор инструкций | Производительность | Совместимость | Рекомендуемый сценарий |
|---|---|---|---|
| **AVX2** | Максимальная | Современные CPU (2013+) | Продакшн, высокая нагрузка |
| **AVX** | Высокая | Более старые CPU (2011+) | Баланс производительности и совместимости |
| **SSE3** | Средняя | Старые CPU (2004+) | Базовая совместимость |
| **SSE4** | Базовая | Максимально широкая | Максимальная совместимость |

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

## 🚀 Быстрый старт

### Использование Docker Run

```bash
docker run -d \
  --name thorium-browser \
  -p 9222:9222 \
  -v ./profile:/data/thorium_profile \
  --security-opt seccomp=unconfined \
  ghcr.io/bropines/thorium-docker:latest-AVX2
```

### Использование Docker Compose

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

## 💻 Подключение автотестов и скраперов

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

## 📊 Бенчмарки производительности

Проект содержит автоматизированную систему бенчмаркинга (`benchmark/`), которая измеряет скорость холодного и горячего запуска Thorium под разными инструкциями CPU.

### Локальная сборка и запуск тестов

```bash
# Сборка версии AVX2 (по умолчанию)
make build-avx2

# Сборка всех версий
make build-all

# Запуск тестов бенчмарка
make test
```

---

## 📄 Лицензия

BSD 3-Clause License
