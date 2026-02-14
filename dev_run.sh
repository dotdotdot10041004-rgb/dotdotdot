#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$ROOT_DIR/server"

# Usage:
#   ./dev_run.sh <flutter-device-id>
# Env:
#   SOCKET_URL (default: http://192.168.0.154:3001)
#   FLUTTER_FLAGS (optional extra flags)

DEVICE_ID="${1:-}"
if [[ -z "$DEVICE_ID" ]]; then
  echo "[usage] ./dev_run.sh <flutter-device-id>"
  echo "[hint ] flutter devices"
  exit 1
fi

SOCKET_URL="${SOCKET_URL:-http://192.168.0.154:3001}"
FLUTTER_FLAGS="${FLUTTER_FLAGS:-}"

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]] && kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    echo "\n[dev_run] stopping socket server(pid=$SERVER_PID)..."
    kill "$SERVER_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

echo "[dev_run] starting socket server..."
cd "$SERVER_DIR"
if [[ ! -d node_modules ]]; then
  npm install --cache ./.npm-cache
fi
npm start &
SERVER_PID=$!

sleep 1

echo "[dev_run] running flutter on device=$DEVICE_ID"
cd "$ROOT_DIR"
flutter run -d "$DEVICE_ID" --dart-define=SOCKET_URL="$SOCKET_URL" $FLUTTER_FLAGS
