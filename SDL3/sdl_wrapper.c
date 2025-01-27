#include <SDL3/SDL.h>


SDL_Window *setup(char* title, int width, int height) {
    SDL_Window *window;
    SDL_Init(SDL_INIT_VIDEO);

    window = SDL_CreateWindow(title, width, height, SDL_WINDOW_OPENGL);
    return window;
}


void cleanup(SDL_Window *window) {
    // Close and destroy the window
    SDL_DestroyWindow(window);
    // Clean up
    SDL_Quit();
}


void wait() {
    SDL_Delay(3000);
}

