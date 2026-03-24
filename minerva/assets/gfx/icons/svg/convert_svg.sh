#!/usr/bin/bash

for f in *.svg
do
    inkscape -w 24 -h 24 "$f" -o "${f%%.*}.png"
done

