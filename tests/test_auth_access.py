from __future__ import annotations

from pathlib import Path

from fastapi.testclient import TestClient

from backend import main
from backend.user_store import UserStore


def _client_with_db(tmp_path: Path) -> TestClient:
    db_path = tmp_path / "auth.db"
    store = UserStore(str(db_path))
    store.init_db()
    store.upsert_user("owner", "owner-pass", "owner")
    store.upsert_user("manager", "manager-pass", "manager")
    store.upsert_user("staff", "staff-pass", "staff")
    store.upsert_user("reader", "reader-pass", "read_only")
    main.user_store = store
    main.token_store = main.TokenStore()
    return TestClient(main.app)


def _token(client: TestClient, username: str, password: str) -> str:
    resp = client.post("/auth/login", json={"username": username, "password": password})
    assert resp.status_code == 200
    return resp.json()["access_token"]


def _auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_login_rejects_invalid_credentials(tmp_path: Path) -> None:
    client = _client_with_db(tmp_path)
    resp = client.post("/auth/login", json={"username": "owner", "password": "wrong"})
    assert resp.status_code == 401


def test_role_matrix_for_sensitive_endpoints(tmp_path: Path) -> None:
    client = _client_with_db(tmp_path)
    tokens = {
        "owner": _token(client, "owner", "owner-pass"),
        "manager": _token(client, "manager", "manager-pass"),
        "staff": _token(client, "staff", "staff-pass"),
        "read_only": _token(client, "reader", "reader-pass"),
    }

    matrix = {
        "/approvals/a-1": {"owner": 200, "manager": 200, "staff": 403, "read_only": 403},
        "/manager/summary": {"owner": 200, "manager": 200, "staff": 403, "read_only": 403},
        "/agent/logs": {"owner": 200, "manager": 200, "staff": 403, "read_only": 403},
        "/admin/config": {"owner": 200, "manager": 403, "staff": 403, "read_only": 403},
        "/tasks": {"owner": 200, "manager": 200, "staff": 200, "read_only": 200},
    }

    for path, expected in matrix.items():
        for role, status_code in expected.items():
            response = client.get(path, headers=_auth_headers(tokens[role]))
            assert response.status_code == status_code, (path, role, response.text)


def test_missing_token_rejected(tmp_path: Path) -> None:
    client = _client_with_db(tmp_path)
    response = client.get("/manager/summary")
    assert response.status_code == 401
