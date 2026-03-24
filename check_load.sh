#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/.logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/check-load-$(date +%Y%m%d-%H%M%S).log"

cd "$ROOT_DIR"

echo "[tool] mode=check-load log=$LOG_FILE"
sbcl --noinform --disable-debugger --script tools/check-load.lisp 2>&1 | tee "$LOG_FILE"
status=${PIPESTATUS[0]}
echo "[tool] mode=check-load exit=$status"
exit "$status"
