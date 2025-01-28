#!/usr/bin/bash

rm hello
cmake --build build
mv build/Debug/hello .
./hello
