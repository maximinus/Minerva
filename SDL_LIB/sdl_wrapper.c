#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <SDL3/SDL.h>

const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;


typedef struct {
    int mousex;
    int mousey;
    bool mouse_left_down;
    bool mouse_right_down;
    bool exit;
} FrameInput;


typedef struct {
    unsigned int r;
    unsigned int g;
    unsigned int b;
    unsigned int alpha;
} Color;


typedef struct {
    int xpos;
    int ypos;
    int width;
    int height;
} Rect;


typedef struct {
    // this is the main data point passed to SDL calls
    // we never pass the window or the render
    SDL_Window* window;
    SDL_Renderer* render;
} Engine;


void set_sdl_rect(Rect *rect, SDL_FRect* sdl_rect) {
    sdl_rect->x = (float)rect->xpos;
    sdl_rect->y = (float)rect->ypos;
    sdl_rect->w = (float)rect->width;
    sdl_rect->h = (float)rect->height;
}

void set_color_from_html(const char* html_color, Color* color) {
    sscanf(html_color, "#%2x%2x%2x", &color->r, &color->g, &color->b);
    color->alpha = 255; // Default alpha value.
}

void init_engine(Engine* engine, const char* title, int width, int height) {
    SDL_Init(SDL_INIT_VIDEO);

    engine->window = SDL_CreateWindow(title, width, height, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
    engine->render = SDL_CreateRenderer(engine->window, NULL);
    SDL_SetRenderVSync(engine->render, 1);
}

void draw_rectangle(Engine* engine, Rect *rect, const char *html_color) {
    Color color;
    SDL_FRect sdl_rect;
    set_sdl_rect(rect, &sdl_rect);
    set_color_from_html(html_color, &color);
    SDL_SetRenderDrawColor(engine->render, color.r, color.g, color.g, color.alpha);
    SDL_RenderFillRect(engine->render, &sdl_rect);
}

void process_events(FrameInput *input) {
    // returns true if we need to quuit

    SDL_Event event;
    SDL_MouseButtonFlags mouse_buttons;
    float xpos, ypos;

    mouse_buttons = SDL_GetMouseState(&xpos, &ypos);
    input->mousex = (int)xpos;
    input->mousey = (int)ypos;
    input->mouse_left_down = mouse_buttons & SDL_BUTTON_LEFT;
    input->mouse_right_down = mouse_buttons & SDL_BUTTON_RIGHT;

    // process all events
    while(SDL_PollEvent(&event)) {
        switch(event.type) {
            case SDL_EVENT_KEY_DOWN:
                if(event.key.key == SDLK_Q) {
                    input->exit = true;
                    return;
                }
                break;
            case SDL_EVENT_QUIT:
                input->exit = true;
                return;
        }
    }
}

void clear_screen(Engine* engine) {
    SDL_SetRenderDrawColor(engine->render, 255, 255, 255, 255);
    SDL_RenderClear(engine->render);
}

void update_screen(Engine *engine) {
    SDL_RenderPresent(engine->render);
}

void cleanup(Engine *engine) {
    // Close and destroy the window
    SDL_DestroyWindow(engine->window);
    // Clean up
    SDL_Quit();
}


