from __future__ import annotations

import sqlite3
from dataclasses import dataclass
from pathlib import Path

from .security import hash_password


@dataclass(slots=True)
class UserRecord:
    username: str
    role: str
    password_salt: str
    password_hash: str
    is_active: bool


ALLOWED_ROLES = {"owner", "manager", "staff", "read_only"}


class UserStore:
    def __init__(self, db_path: str = "./data/auth.db") -> None:
        self.db_path = Path(db_path)
        self.db_path.parent.mkdir(parents=True, exist_ok=True)

    def _connect(self) -> sqlite3.Connection:
        return sqlite3.connect(self.db_path)

    def init_db(self) -> None:
        with self._connect() as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                    username TEXT PRIMARY KEY,
                    role TEXT NOT NULL,
                    password_salt TEXT NOT NULL,
                    password_hash TEXT NOT NULL,
                    is_active INTEGER NOT NULL DEFAULT 1,
                    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            conn.execute(
                """
                CREATE TRIGGER IF NOT EXISTS users_updated_at
                AFTER UPDATE ON users
                BEGIN
                    UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE username = NEW.username;
                END;
                """
            )

    def upsert_user(self, username: str, password: str, role: str, is_active: bool = True) -> None:
        if role not in ALLOWED_ROLES:
            raise ValueError(f"Invalid role '{role}'. Allowed: {sorted(ALLOWED_ROLES)}")
        salt_hex, digest_hex = hash_password(password)
        with self._connect() as conn:
            conn.execute(
                """
                INSERT INTO users (username, role, password_salt, password_hash, is_active)
                VALUES (?, ?, ?, ?, ?)
                ON CONFLICT(username) DO UPDATE SET
                    role=excluded.role,
                    password_salt=excluded.password_salt,
                    password_hash=excluded.password_hash,
                    is_active=excluded.is_active
                """,
                (username, role, salt_hex, digest_hex, 1 if is_active else 0),
            )

    def get_user(self, username: str) -> UserRecord | None:
        with self._connect() as conn:
            row = conn.execute(
                """
                SELECT username, role, password_salt, password_hash, is_active
                FROM users WHERE username = ?
                """,
                (username,),
            ).fetchone()
        if not row:
            return None
        return UserRecord(
            username=row[0],
            role=row[1],
            password_salt=row[2],
            password_hash=row[3],
            is_active=bool(row[4]),
        )
