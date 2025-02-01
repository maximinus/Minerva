#!/usr/bin/bash

rm test
cmake --build build
mv build/test .
./test
