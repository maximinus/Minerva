#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/.logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/smoke-$(date +%Y%m%d-%H%M%S).log"

cd "$ROOT_DIR"

echo "[tool] mode=smoke log=$LOG_FILE"
sbcl --noinform --disable-debugger --script tools/run-smoke.lisp 2>&1 | tee "$LOG_FILE"
status=${PIPESTATUS[0]}
echo "[tool] mode=smoke exit=$status"
exit "$status"
