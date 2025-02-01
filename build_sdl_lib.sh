#!/bin/bash

cd SDL_LIB
cc -fPIC -shared -o libsdlwrapper.so sdl_wrapper.c -I/home/sparky/code/Minerva/SDL_LIB/SDL/include -L/home/sparky/code/Minerva/SDL_LIB/build -lSDL3
cd ..

