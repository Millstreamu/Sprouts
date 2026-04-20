from fastapi import FastAPI, status
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.db import can_connect

settings = get_settings()
app = FastAPI(title="Sprouts Backend", version="1.0.0")


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/readyz")
def readyz() -> JSONResponse:
    if can_connect(settings.database_url):
        return JSONResponse(status_code=status.HTTP_200_OK, content={"status": "ready", "database": "ok"})

    return JSONResponse(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        content={"status": "not_ready", "database": "unavailable"},
    )
