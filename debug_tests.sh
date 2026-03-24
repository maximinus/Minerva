#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "[tool] mode=debug-tests debugger=enabled"
sbcl --noinform --script tools/debug-tests.lisp
