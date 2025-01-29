#include <stdint.h>
#include <stdlib.h>
#include <SDL3/SDL.h>

// we want some simple things
// a function to get a window
// a function to cleanup
// a function that returns true if "q" is pressed
// a function that draw a colored rectangle to the screen

const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;


SDL_Window *setup(char* title, int width, int height) {
    SDL_Window *window;
    SDL_Init(SDL_INIT_VIDEO);

    window = SDL_CreateWindow(title, width, height, SDL_WINDOW_OPENGL);
    return window;
}


SDL_Surface* get_window_surface(SDL_Window* window) {
    return SDL_GetWindowSurface(window);
}


Uint32 get_color(SDL_Surface *screen, Uint8 red, Uint8 green, Uint8 blue) {
    return SDL_MapSurfaceRGB(screen, red, green, blue);
}


SDL_Rect* get_rect(int xpos, int ypos, int width, int height) {
    SDL_Rect* rect = (SDL_Rect*)malloc(sizeof(SDL_Rect));
    if(!rect) return NULL;
    rect->x = xpos;
    rect->y = ypos;
    rect->w = width;
    rect->h = height;
    return rect;
}


void free_memory(void* data) {
    free(data);
}


void draw_rectangle(SDL_Surface *screen, SDL_Rect *area, Uint32 color) {
    SDL_FillSurfaceRect(screen, area, color);
}


void clear_screen(SDL_Surface* screen) {
    SDL_FillSurfaceRect(screen, NULL, UINT32_MAX);
}


void update_window(SDL_Window *window) {
    SDL_UpdateWindowSurface(window);
}


bool quit_game() {
    SDL_Event test_event;

    SDL_WaitEvent(&test_event);
    if(test_event.type == SDL_EVENT_KEY_DOWN) {
        if(test_event.key.key == SDLK_Q) {
            return true;
        }
    }
    return false;
}


void cleanup(SDL_Window *window) {
    // Close and destroy the window
    SDL_DestroyWindow(window);
    // Clean up
    SDL_Quit();
}


int main() {
    SDL_Window* window = setup("SDL Hello", SCREEN_WIDTH, SCREEN_HEIGHT);
    SDL_Surface* screen = get_window_surface(window);
    clear_screen(screen);
    SDL_Rect* rect = get_rect(100, 100, 200, 200);
    Uint32 color = get_color(screen, 252, 102, 0);
    draw_rectangle(screen, rect, color);
    update_window(window);
    while(!quit_game()) {}
    return 0;
}
