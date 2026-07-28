# Thorium Docker

Высокопроизводительный Docker-образ браузера Thorium, оптимизированный для работы в headless-режиме и веб-скрапинга. Поддерживает различные наборы инструкций CPU.

## Обзор проекта

[Thorium](https://github.com/Alex313031/thorium) — это оптимизированная по производительности версия браузера на базе Chromium (прирост производительности на 8%-38% по сравнению с обычным Chromium).

Этот проект предоставляет автоматическую сборку и публикацию Docker-образов в **GitHub Container Registry (GHCR)**:

- 🚀 Автоматическое определение новых версий Thorium
- 🔄 Автоматическая сборка через GitHub Actions
- 🐳 Публикация в GHCR (`ghcr.io/bropines/thorium-docker`)
- 🌍 Поддержка шрифтов CJK (китайский, японский, корейский) и кириллицы
- 🔒 Безопасный запуск от имени не-root пользователя
- 📸 Оптимизация для снятия скриншотов и веб-скрапинга
- ⚡ **Поддержка различных наборов инструкций CPU** (AVX2, AVX, SSE3, SSE4)
- 📊 **Бенчмарки производительности** (сравнение с chromedp/docker-headless-shell)

## Поддержка инструкций CPU

| Набор инструкций | Производительность | Совместимость | Рекомендуемый сценарий |
|---|---|---|---|
| **AVX2** | Максимальная | Современные CPU (2013+) | Продакшн, высокая нагрузка |
| **AVX** | Высокая | Более старые CPU (2011+) | Баланс производительности и совместимости |
| **SSE3** | Средняя | Старые CPU (2004+) | Базовая совместимость |
| **SSE4** | Базовая | Максимально широкая | Максимальная совместимость |

## Особенности

- **Высокая производительность**: Движок Thorium с оптимизациями под CPU
- **Headless режим**: Разработан специально для автоматического тестирования и скрапинга
- **Мультиязычность**: Встроенные шрифты CJK, Emoji и поддержка UTF-8
- **Безопасность**: Запуск от не-root пользователя (`thorium`)
- **Удаленная отладка**: Поддержка Chrome DevTools Remote Debugging (порт 9222)
- **CI/CD**: Полная автоматизация сборки и публикации в `ghcr.io`

## Быстрый старт

### Использование готовых контейнеров из GHCR

```bash
# Выкачать образ с поддержкой AVX2 (рекомендуется)
docker pull ghcr.io/bropines/thorium-docker:latest-avx2

# Запустить контейнер AVX2
docker run -d \
  --name thorium-headless \
  -p 9222:9222 \
  --security-opt seccomp=unconfined \
  --cap-add SYS_ADMIN \
  ghcr.io/bropines/thorium-docker:latest-avx2
```

### Использование Docker Compose

```bash
# Запустить версию AVX2 (по умолчанию)
docker-compose up -d thorium-headless-avx2

# Запустить версию AVX
docker-compose up -d thorium-headless-avx

# Запустить версию SSE3
docker-compose up -d thorium-headless-sse3

# Запустить версию SSE4
docker-compose up -d thorium-headless-sse4

# Проверить статус удаленной отладки
curl http://localhost:9222/json/version  # AVX2
```

### Подключение через Selenium (Python)

```python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

chrome_options = Options()
chrome_options.add_experimental_option("debuggerAddress", "localhost:9222")

driver = webdriver.Chrome(options=chrome_options)
driver.get("https://example.com")
driver.save_screenshot("screenshot.png")
driver.quit()
```

## Разработка и локальная сборка

```bash
# Сборка версии AVX2 (по умолчанию)
make build-avx2

# Сборка всех версий
make build-all

# Запуск тестов
make test
```

## Теги контейнеров в GHCR

Каждая сборка публикует следующие теги в `ghcr.io/bropines/thorium-docker`:

- `latest`, `latest-avx2`, `avx2` — Рекомендуемая версия AVX2
- `latest-avx`, `avx` — Версия AVX
- `latest-sse3`, `sse3` — Версия SSE3
- `latest-sse4`, `sse4` — Версия SSE4
- `{version}-AVX2`, `{version}-AVX` и т.д. — Конкретные версии Thorium

## Лицензия

BSD 3-Clause License
