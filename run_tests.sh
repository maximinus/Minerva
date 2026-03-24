#!/usr/bin/env bash
set -euo pipefail

sbcl --noinform \
     --eval '(require :asdf)' \
     --eval '(setf *compile-verbose* nil *compile-print* nil *load-verbose* nil asdf:*asdf-verbose* nil)' \
     --eval '(asdf:load-asd (truename "minerva.asd"))' \
     --eval '(asdf:test-system "minerva/tests")' \
     --quit
