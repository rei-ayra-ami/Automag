# Automag API — бэкенд

REST API каталога автозапчастей для мобильного приложения **Automag**.

- **Стек:** FastAPI + SQLite (стандартный модуль `sqlite3`, без ORM).
- **База данных:** `automag.db` создаётся автоматически при первом запуске
  и наполняется из `../assets/data/parts.json` (20 запчастей).
- Приложение Flutter ходит на API по HTTP, а если сервер недоступен —
  откатывается на тот же `parts.json` из ассетов (офлайн-режим).

## Запуск

```bash
cd backend

# 1. Виртуальное окружение (один раз)
virtualenv -p python3 .venv          # или: python3 -m venv .venv
source .venv/bin/activate

# 2. Зависимости
pip install -r requirements.txt

# 3. Запуск сервера
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

После старта API доступен на <http://127.0.0.1:8000>.

> На Ubuntu/Debian для `python3 -m venv` нужен пакет `python3-venv`
> (`sudo apt install python3.13-venv`). Если его нет — используйте
> `virtualenv`, он не требует системных пакетов.

## Эндпоинты

| Метод | Путь                 | Описание                          |
|-------|----------------------|-----------------------------------|
| GET   | `/`                  | Проверка работоспособности        |
| GET   | `/api/parts`         | Список всех запчастей (JSON-массив)|
| GET   | `/api/parts/{id}`    | Одна запчасть по `id`             |
| GET   | `/api/categories`    | Список категорий                  |

Интерактивная документация (Swagger UI): <http://127.0.0.1:8000/docs>

## Быстрая проверка

```bash
curl http://127.0.0.1:8000/api/parts | head
```

## Связь с приложением

В `lib/services/api_service.dart` базовый URL задаётся константой `_baseUrl`:

- **Веб (Chrome) и desktop:** `http://127.0.0.1:8000`
- **Эмулятор Android:** замените на `http://10.0.2.2:8000`

Сервер должен быть запущен **до** старта приложения
(`flutter run -d chrome`), иначе приложение покажет данные из локального
каталога (фолбэк).
