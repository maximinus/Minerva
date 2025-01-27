#!/usr/bin/bash

rm hello
cmake --build build
mv build/hello .
./hello
