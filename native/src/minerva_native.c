#include "minerva_native.h"

#include <SDL3/SDL.h>

#include <stddef.h>

struct Window {
    SDL_Window *window;
    SDL_Renderer *renderer;
    int should_close;
};

static char g_last_error[512];

static void set_last_error_from_sdl(void) {
    const char *sdl_error = SDL_GetError();
    if (sdl_error == NULL || *sdl_error == '\0') {
        SDL_strlcpy(g_last_error, "Unknown SDL error", sizeof(g_last_error));
        return;
    }
    SDL_strlcpy(g_last_error, sdl_error, sizeof(g_last_error));
}

static void set_last_error_literal(const char *message) {
    if (message == NULL || *message == '\0') {
        SDL_strlcpy(g_last_error, "Unknown error", sizeof(g_last_error));
        return;
    }
    SDL_strlcpy(g_last_error, message, sizeof(g_last_error));
}

int init(void) {
    g_last_error[0] = '\0';
    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS)) {
        set_last_error_from_sdl();
        return 0;
    }
    return 1;
}

void minerva_shutdown(void) {
    SDL_Quit();
}

const char *last_error(void) {
    if (g_last_error[0] == '\0') {
        return "";
    }
    return g_last_error;
}

Window *window_create(const char *title, int width, int height) {
    if (width <= 0 || height <= 0) {
        set_last_error_literal("window size must be positive");
        return NULL;
    }

    Window *window = (Window *)SDL_calloc(1, sizeof(Window));
    if (window == NULL) {
        set_last_error_from_sdl();
        return NULL;
    }

    const char *window_title = title != NULL ? title : "Minerva";
    window->window = SDL_CreateWindow(window_title, width, height, SDL_WINDOW_RESIZABLE);
    if (window->window == NULL) {
        set_last_error_from_sdl();
        SDL_free(window);
        return NULL;
    }

    window->renderer = SDL_CreateRenderer(window->window, NULL);
    if (window->renderer == NULL) {
        set_last_error_from_sdl();
        SDL_DestroyWindow(window->window);
        SDL_free(window);
        return NULL;
    }

    return window;
}

void window_destroy(Window *window) {
    if (window == NULL) {
        return;
    }

    if (window->renderer != NULL) {
        SDL_DestroyRenderer(window->renderer);
        window->renderer = NULL;
    }

    if (window->window != NULL) {
        SDL_DestroyWindow(window->window);
        window->window = NULL;
    }

    SDL_free(window);
}

int window_should_close(Window *window) {
    if (window == NULL) {
        set_last_error_literal("window is null");
        return 1;
    }
    return window->should_close != 0;
}

void window_request_close(Window *window) {
    if (window == NULL) {
        return;
    }
    window->should_close = 1;
}

void window_get_size(Window *window, int *width, int *height) {
    if (window == NULL || window->window == NULL) {
        if (width != NULL) {
            *width = 0;
        }
        if (height != NULL) {
            *height = 0;
        }
        return;
    }

    SDL_GetWindowSize(window->window, width, height);
}

int poll_event(Event *out_event) {
    if (out_event == NULL) {
        set_last_error_literal("out_event is null");
        return 0;
    }

    SDL_Event event;
    if (!SDL_PollEvent(&event)) {
        out_event->type = EVENT_NONE;
        out_event->a = 0;
        out_event->b = 0;
        out_event->c = 0;
        out_event->d = 0;
        return 0;
    }

    out_event->type = EVENT_NONE;
    out_event->a = 0;
    out_event->b = 0;
    out_event->c = 0;
    out_event->d = 0;

    switch (event.type) {
        case SDL_EVENT_QUIT:
            out_event->type = EVENT_QUIT;
            break;
        case SDL_EVENT_WINDOW_RESIZED:
            out_event->type = EVENT_WINDOW_RESIZED;
            out_event->a = event.window.data1;
            out_event->b = event.window.data2;
            break;
        case SDL_EVENT_KEY_DOWN:
            out_event->type = EVENT_KEY_DOWN;
            out_event->a = (int)event.key.key;
            break;
        case SDL_EVENT_KEY_UP:
            out_event->type = EVENT_KEY_UP;
            out_event->a = (int)event.key.key;
            break;
        case SDL_EVENT_MOUSE_BUTTON_DOWN:
            out_event->type = EVENT_MOUSE_BUTTON_DOWN;
            out_event->a = (int)event.button.button;
            out_event->b = (int)event.button.x;
            out_event->c = (int)event.button.y;
            break;
        case SDL_EVENT_MOUSE_BUTTON_UP:
            out_event->type = EVENT_MOUSE_BUTTON_UP;
            out_event->a = (int)event.button.button;
            out_event->b = (int)event.button.x;
            out_event->c = (int)event.button.y;
            break;
        case SDL_EVENT_MOUSE_MOTION:
            out_event->type = EVENT_MOUSE_MOVE;
            out_event->a = (int)event.motion.x;
            out_event->b = (int)event.motion.y;
            break;
        default:
            break;
    }

    return 1;
}

void begin_frame(Window *window) {
    if (window == NULL || window->renderer == NULL) {
        set_last_error_literal("window or renderer is null");
    }
}

void clear(Window *window, unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    if (window == NULL || window->renderer == NULL) {
        set_last_error_literal("window or renderer is null");
        return;
    }

    if (!SDL_SetRenderDrawColor(window->renderer, r, g, b, a)) {
        set_last_error_from_sdl();
        return;
    }

    if (!SDL_RenderClear(window->renderer)) {
        set_last_error_from_sdl();
    }
}

void fill_rect(Window *window, int x, int y, int width, int height,
                     unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    if (window == NULL || window->renderer == NULL) {
        set_last_error_literal("window or renderer is null");
        return;
    }

    if (width <= 0 || height <= 0) {
        return;
    }

    if (!SDL_SetRenderDrawColor(window->renderer, r, g, b, a)) {
        set_last_error_from_sdl();
        return;
    }

    SDL_FRect rect = {(float)x, (float)y, (float)width, (float)height};
    if (!SDL_RenderFillRect(window->renderer, &rect)) {
        set_last_error_from_sdl();
    }
}

void end_frame(Window *window) {
    if (window == NULL || window->renderer == NULL) {
        set_last_error_literal("window or renderer is null");
        return;
    }

    if (!SDL_RenderPresent(window->renderer)) {
        set_last_error_from_sdl();
    }
}

unsigned long long ticks_ms(void) {
    return (unsigned long long)SDL_GetTicks();
}

void sleep_ms(int ms) {
    if (ms <= 0) {
        return;
    }
    SDL_Delay((Uint32)ms);
}
