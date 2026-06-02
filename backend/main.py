"""
Automag — REST API автозапчастей.

Стек: FastAPI + SQLite (стандартная библиотека sqlite3, без ORM).
Назначение: отдавать каталог автозапчастей по HTTP, чтобы мобильное
приложение получало данные через сетевой API, а не из локального файла.

Запуск:
    uvicorn main:app --reload --host 127.0.0.1 --port 8000

Эндпоинты:
    GET /                  — проверка работоспособности
    GET /api/parts         — список всех запчастей
    GET /api/parts/{id}    — одна запчасть по id
    GET /api/categories    — список категорий
"""

import json
import os
import sqlite3
from contextlib import closing

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "automag.db")
# Источник первичного наполнения БД — тот же каталог, что и в приложении.
SEED_PATH = os.path.join(BASE_DIR, "..", "assets", "data", "parts.json")


# --- Работа с базой данных -------------------------------------------------

def get_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    """Создаёт таблицу parts, если её ещё нет."""
    with closing(get_connection()) as conn, conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS parts (
                id          TEXT PRIMARY KEY,
                name        TEXT    NOT NULL,
                brand       TEXT    NOT NULL,
                model       TEXT    NOT NULL,
                category    TEXT    NOT NULL,
                price       INTEGER NOT NULL,
                description TEXT    NOT NULL,
                image       TEXT,
                specs       TEXT    NOT NULL  -- JSON-строка {ключ: значение}
            )
            """
        )


def seed_db() -> None:
    """Наполняет БД из parts.json, если таблица пустая."""
    with closing(get_connection()) as conn:
        count = conn.execute("SELECT COUNT(*) AS c FROM parts").fetchone()["c"]
        if count > 0:
            return

    with open(SEED_PATH, "r", encoding="utf-8") as f:
        parts = json.load(f)["parts"]

    with closing(get_connection()) as conn, conn:
        for p in parts:
            conn.execute(
                """
                INSERT INTO parts
                    (id, name, brand, model, category, price, description, image, specs)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    p["id"],
                    p["name"],
                    p.get("brand", ""),
                    p.get("model", "Универсальный"),
                    p.get("category", "Прочее"),
                    int(p["price"]),
                    p.get("description", ""),
                    p.get("image"),
                    json.dumps(p.get("specs", {}), ensure_ascii=False),
                ),
            )


def row_to_part(row: sqlite3.Row) -> dict:
    """Преобразует строку БД в JSON-объект запчасти (specs -> словарь)."""
    return {
        "id": row["id"],
        "name": row["name"],
        "brand": row["brand"],
        "model": row["model"],
        "category": row["category"],
        "price": row["price"],
        "description": row["description"],
        "image": row["image"],
        "specs": json.loads(row["specs"]),
    }


# --- Приложение FastAPI -----------------------------------------------------

app = FastAPI(title="Automag API", version="1.0.0")

# CORS: разрешаем запросы из Flutter-приложения (в т.ч. веб-версии).
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    init_db()
    seed_db()


@app.get("/")
def root() -> dict:
    with closing(get_connection()) as conn:
        count = conn.execute("SELECT COUNT(*) AS c FROM parts").fetchone()["c"]
    return {"service": "Automag API", "status": "ok", "parts": count}


@app.get("/api/parts")
def list_parts() -> list[dict]:
    with closing(get_connection()) as conn:
        rows = conn.execute("SELECT * FROM parts ORDER BY category, name").fetchall()
    return [row_to_part(r) for r in rows]


@app.get("/api/parts/{part_id}")
def get_part(part_id: str) -> dict:
    with closing(get_connection()) as conn:
        row = conn.execute(
            "SELECT * FROM parts WHERE id = ?", (part_id,)
        ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="Запчасть не найдена")
    return row_to_part(row)


@app.get("/api/categories")
def list_categories() -> list[str]:
    with closing(get_connection()) as conn:
        rows = conn.execute(
            "SELECT DISTINCT category FROM parts ORDER BY category"
        ).fetchall()
    return [r["category"] for r in rows]
