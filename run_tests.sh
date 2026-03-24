#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT_DIR/.logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/tests-$(date +%Y%m%d-%H%M%S).log"

cd "$ROOT_DIR"

echo "[tool] mode=tests log=$LOG_FILE"
sbcl --noinform --disable-debugger --script tools/run-tests.lisp 2>&1 | tee "$LOG_FILE"
status=${PIPESTATUS[0]}
echo "[tool] mode=tests exit=$status"
exit "$status"
