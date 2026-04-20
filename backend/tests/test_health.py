from fastapi.testclient import TestClient

from app import main


client = TestClient(main.app)


def test_healthz_ok() -> None:
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_readyz_when_db_is_unavailable(monkeypatch) -> None:
    monkeypatch.setattr(main, "can_connect", lambda _url: False)

    response = client.get("/readyz")
    assert response.status_code == 503
    assert response.json()["status"] == "not_ready"


def test_readyz_when_db_is_available(monkeypatch) -> None:
    monkeypatch.setattr(main, "can_connect", lambda _url: True)

    response = client.get("/readyz")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"
