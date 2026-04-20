from __future__ import annotations

import os
from datetime import datetime
from typing import Annotated

from fastapi import Depends, FastAPI, Header, HTTPException, status
from pydantic import BaseModel, Field

from .security import TokenStore, verify_password
from .user_store import ALLOWED_ROLES, UserRecord, UserStore


class LoginRequest(BaseModel):
    username: str = Field(min_length=1)
    password: str = Field(min_length=1)


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime
    role: str


ROLE_ACCESS = {
    "approvals": {"owner", "manager"},
    "manager_summary": {"owner", "manager"},
    "agent_logs": {"owner", "manager"},
    "admin_config": {"owner"},
}

app = FastAPI(title="Sprouts API", version="0.1.0")
user_store = UserStore(os.environ.get("SPROUTS_AUTH_DB", "./data/auth.db"))
token_store = TokenStore()


@app.on_event("startup")
def startup() -> None:
    user_store.init_db()


def _extract_bearer(authorization: str | None) -> str:
    if not authorization:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing Authorization header")
    prefix = "Bearer "
    if not authorization.startswith(prefix):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid auth scheme")
    return authorization[len(prefix) :].strip()


def current_user(authorization: Annotated[str | None, Header()] = None) -> UserRecord:
    token = _extract_bearer(authorization)
    username = token_store.validate(token)
    if not username:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    user = user_store.get_user(username)
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unknown or inactive user")
    return user


def require_roles(*roles: str):
    invalid = [r for r in roles if r not in ALLOWED_ROLES]
    if invalid:
        raise ValueError(f"Unknown role(s): {invalid}")

    def checker(user: Annotated[UserRecord, Depends(current_user)]) -> UserRecord:
        if user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient role")
        return user

    return checker


@app.post("/auth/login", response_model=LoginResponse)
def login(payload: LoginRequest) -> LoginResponse:
    user = user_store.get_user(payload.username)
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not verify_password(payload.password, user.password_salt, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    token, expires_at = token_store.issue(user.username)
    return LoginResponse(access_token=token, expires_at=expires_at, role=user.role)


@app.get("/approvals/{approval_id}")
def approval_details(
    approval_id: str,
    user: Annotated[UserRecord, Depends(require_roles(*ROLE_ACCESS["approvals"]))],
) -> dict:
    return {"approval_id": approval_id, "status": "pending", "reviewed_by": user.username}


@app.get("/manager/summary")
def manager_summary(
    user: Annotated[UserRecord, Depends(require_roles(*ROLE_ACCESS["manager_summary"]))],
) -> dict:
    return {"manager": user.username, "queue_size": 3, "high_risk": 1}


@app.get("/agent/logs")
def agent_logs(
    user: Annotated[UserRecord, Depends(require_roles(*ROLE_ACCESS["agent_logs"]))],
) -> dict:
    return {"viewer": user.username, "logs": ["[REDACTED] sensitive"]}


@app.get("/admin/config")
def admin_config(
    user: Annotated[UserRecord, Depends(require_roles(*ROLE_ACCESS["admin_config"]))],
) -> dict:
    return {"viewer": user.username, "config_version": 1}


@app.get("/tasks")
def tasks(user: Annotated[UserRecord, Depends(require_roles("owner", "manager", "staff", "read_only"))]) -> dict:
    return {"viewer": user.username, "items": ["water tile", "heal grove"]}
