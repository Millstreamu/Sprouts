from __future__ import annotations

import hashlib
import hmac
import os
import secrets
from datetime import datetime, timedelta, timezone
from typing import Dict

PBKDF2_ITERATIONS = 210_000
SALT_BYTES = 16
TOKEN_TTL_HOURS = 12


def hash_password(password: str, salt: bytes | None = None) -> tuple[str, str]:
    if not password:
        raise ValueError("Password cannot be empty")
    use_salt = salt or os.urandom(SALT_BYTES)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), use_salt, PBKDF2_ITERATIONS)
    return use_salt.hex(), digest.hex()


def verify_password(password: str, salt_hex: str, digest_hex: str) -> bool:
    salt = bytes.fromhex(salt_hex)
    expected = bytes.fromhex(digest_hex)
    actual = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, PBKDF2_ITERATIONS)
    return hmac.compare_digest(actual, expected)


class TokenStore:
    def __init__(self) -> None:
        self._tokens: Dict[str, tuple[str, datetime]] = {}

    def issue(self, username: str) -> tuple[str, datetime]:
        token = secrets.token_urlsafe(32)
        expires_at = datetime.now(timezone.utc) + timedelta(hours=TOKEN_TTL_HOURS)
        self._tokens[token] = (username, expires_at)
        return token, expires_at

    def validate(self, token: str) -> str | None:
        found = self._tokens.get(token)
        if not found:
            return None
        username, expires_at = found
        if datetime.now(timezone.utc) > expires_at:
            self._tokens.pop(token, None)
            return None
        return username
