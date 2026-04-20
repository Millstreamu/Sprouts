#!/usr/bin/env sh
set -eu

: "${APP_HOST:=0.0.0.0}"
: "${APP_PORT:=8000}"
: "${LOG_LEVEL:=info}"

exec uvicorn app.main:app --host "$APP_HOST" --port "$APP_PORT" --log-level "$LOG_LEVEL"
