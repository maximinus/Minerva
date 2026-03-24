#include "minerva_native.h"

#include <SDL3/SDL.h>

#include <stdbool.h>
#include <stddef.h>
#include <string.h>

struct Window {
    SDL_Window *window;
    SDL_Renderer *renderer;
    int should_close;
};

struct Surface {
    SDL_Surface *surface;
};

struct Font {
    char *name_or_path;
    int size;
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

static Surface *wrap_surface(SDL_Surface *surface) {
    if (surface == NULL) {
        return NULL;
    }
    Surface *wrapped = (Surface *)SDL_calloc(1, sizeof(Surface));
    if (wrapped == NULL) {
        set_last_error_from_sdl();
        SDL_DestroySurface(surface);
        return NULL;
    }
    wrapped->surface = surface;
    return wrapped;
}

static SDL_Surface *convert_to_rgba32(SDL_Surface *source) {
    if (source == NULL) {
        return NULL;
    }
    SDL_Surface *converted = SDL_ConvertSurface(source, SDL_PIXELFORMAT_RGBA32);
    if (converted == NULL) {
        set_last_error_from_sdl();
        return NULL;
    }
    if (!SDL_SetSurfaceBlendMode(converted, SDL_BLENDMODE_BLEND)) {
        set_last_error_from_sdl();
        SDL_DestroySurface(converted);
        return NULL;
    }
    return converted;
}

static bool validate_surface_rect(Surface *surface, int x, int y, int width, int height) {
    if (surface == NULL || surface->surface == NULL) {
        set_last_error_literal("surface is null");
        return false;
    }
    if (width <= 0 || height <= 0) {
        set_last_error_literal("rectangle size must be positive");
        return false;
    }
    if (x < 0 || y < 0) {
        set_last_error_literal("rectangle origin must be non-negative");
        return false;
    }
    if (x + width > surface->surface->w || y + height > surface->surface->h) {
        set_last_error_literal("rectangle is out of source bounds");
        return false;
    }
    return true;
}

static bool validate_window_and_surface(Window *window, Surface *surface) {
    if (window == NULL || window->renderer == NULL) {
        set_last_error_literal("window or renderer is null");
        return false;
    }
    if (surface == NULL || surface->surface == NULL) {
        set_last_error_literal("surface is null");
        return false;
    }
    return true;
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

Surface *surface_create_blank(int width, int height) {
    if (width <= 0 || height <= 0) {
        set_last_error_literal("surface size must be positive");
        return NULL;
    }

    SDL_Surface *surface = SDL_CreateSurface(width, height, SDL_PIXELFORMAT_RGBA32);
    if (surface == NULL) {
        set_last_error_from_sdl();
        return NULL;
    }

    if (!SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_BLEND)) {
        set_last_error_from_sdl();
        SDL_DestroySurface(surface);
        return NULL;
    }

    Uint32 transparent = SDL_MapSurfaceRGBA(surface, 0, 0, 0, 0);
    if (!SDL_FillSurfaceRect(surface, NULL, transparent)) {
        set_last_error_from_sdl();
        SDL_DestroySurface(surface);
        return NULL;
    }

    return wrap_surface(surface);
}

Surface *surface_load_file(const char *path) {
    if (path == NULL || *path == '\0') {
        set_last_error_literal("surface path is empty");
        return NULL;
    }

    SDL_Surface *loaded = SDL_LoadPNG(path);
    if (loaded == NULL) {
        loaded = SDL_LoadBMP(path);
    }
    if (loaded == NULL) {
        set_last_error_from_sdl();
        return NULL;
    }

    SDL_Surface *converted = convert_to_rgba32(loaded);
    SDL_DestroySurface(loaded);
    if (converted == NULL) {
        return NULL;
    }

    return wrap_surface(converted);
}

void surface_destroy(Surface *surface) {
    if (surface == NULL) {
        return;
    }

    if (surface->surface != NULL) {
        SDL_DestroySurface(surface->surface);
        surface->surface = NULL;
    }

    SDL_free(surface);
}

int surface_width(Surface *surface) {
    if (surface == NULL || surface->surface == NULL) {
        return 0;
    }
    return surface->surface->w;
}

int surface_height(Surface *surface) {
    if (surface == NULL || surface->surface == NULL) {
        return 0;
    }
    return surface->surface->h;
}

int surface_blit(Surface *src, Surface *dst, int dst_x, int dst_y) {
    if (src == NULL || src->surface == NULL || dst == NULL || dst->surface == NULL) {
        set_last_error_literal("source or destination surface is null");
        return 0;
    }

    SDL_Rect dst_rect = { dst_x, dst_y, src->surface->w, src->surface->h };
    if (!SDL_BlitSurface(src->surface, NULL, dst->surface, &dst_rect)) {
        set_last_error_from_sdl();
        return 0;
    }
    return 1;
}

int surface_blit_rect(Surface *src, int src_x, int src_y, int src_width, int src_height,
                      Surface *dst, int dst_x, int dst_y) {
    if (!validate_surface_rect(src, src_x, src_y, src_width, src_height)) {
        return 0;
    }
    if (dst == NULL || dst->surface == NULL) {
        set_last_error_literal("destination surface is null");
        return 0;
    }

    SDL_Rect src_rect = { src_x, src_y, src_width, src_height };
    SDL_Rect dst_rect = { dst_x, dst_y, src_width, src_height };
    if (!SDL_BlitSurface(src->surface, &src_rect, dst->surface, &dst_rect)) {
        set_last_error_from_sdl();
        return 0;
    }
    return 1;
}

int surface_blit_rect_scaled(Surface *src, int src_x, int src_y, int src_width, int src_height,
                             Surface *dst, int dst_x, int dst_y, int dst_width, int dst_height) {
    if (!validate_surface_rect(src, src_x, src_y, src_width, src_height)) {
        return 0;
    }
    if (dst == NULL || dst->surface == NULL) {
        set_last_error_literal("destination surface is null");
        return 0;
    }
    if (dst_width <= 0 || dst_height <= 0) {
        set_last_error_literal("destination rectangle size must be positive");
        return 0;
    }

    SDL_Rect src_rect = { src_x, src_y, src_width, src_height };
    SDL_Rect dst_rect = { dst_x, dst_y, dst_width, dst_height };
    if (!SDL_BlitSurfaceScaled(src->surface, &src_rect, dst->surface, &dst_rect, SDL_SCALEMODE_LINEAR)) {
        set_last_error_from_sdl();
        return 0;
    }
    return 1;
}

int window_draw_surface(Window *window, Surface *surface, int dst_x, int dst_y) {
    if (!validate_window_and_surface(window, surface)) {
        return 0;
    }

    SDL_Texture *texture = SDL_CreateTextureFromSurface(window->renderer, surface->surface);
    if (texture == NULL) {
        set_last_error_from_sdl();
        return 0;
    }
    (void)SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND);

    SDL_FRect dst_rect = { (float)dst_x, (float)dst_y, (float)surface->surface->w, (float)surface->surface->h };
    bool ok = SDL_RenderTexture(window->renderer, texture, NULL, &dst_rect);
    SDL_DestroyTexture(texture);
    if (!ok) {
        set_last_error_from_sdl();
        return 0;
    }
    return 1;
}

int window_draw_surface_rect(Window *window, Surface *surface,
                             int src_x, int src_y, int src_width, int src_height,
                             int dst_x, int dst_y) {
    if (!validate_window_and_surface(window, surface)) {
        return 0;
    }
    if (!validate_surface_rect(surface, src_x, src_y, src_width, src_height)) {
        return 0;
    }

    SDL_Texture *texture = SDL_CreateTextureFromSurface(window->renderer, surface->surface);
    if (texture == NULL) {
        set_last_error_from_sdl();
        return 0;
    }
    (void)SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND);

    SDL_FRect src_rect = { (float)src_x, (float)src_y, (float)src_width, (float)src_height };
    SDL_FRect dst_rect = { (float)dst_x, (float)dst_y, (float)src_width, (float)src_height };
    bool ok = SDL_RenderTexture(window->renderer, texture, &src_rect, &dst_rect);
    SDL_DestroyTexture(texture);
    if (!ok) {
        set_last_error_from_sdl();
        return 0;
    }
    return 1;
}

int window_draw_surface_rect_scaled(Window *window, Surface *surface,
                                    int src_x, int src_y, int src_width, int src_height,
                                    int dst_x, int dst_y, int dst_width, int dst_height) {
    if (!validate_window_and_surface(window, surface)) {
        return 0;
    }
    if (!validate_surface_rect(surface, src_x, src_y, src_width, src_height)) {
        return 0;
    }
    if (dst_width <= 0 || dst_height <= 0) {
        set_last_error_literal("destination rectangle size must be positive");
        return 0;
    }

    SDL_Texture *texture = SDL_CreateTextureFromSurface(window->renderer, surface->surface);
    if (texture == NULL) {
        set_last_error_from_sdl();
        return 0;
    }
    (void)SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND);

    SDL_FRect src_rect = { (float)src_x, (float)src_y, (float)src_width, (float)src_height };
    SDL_FRect dst_rect = { (float)dst_x, (float)dst_y, (float)dst_width, (float)dst_height };
    bool ok = SDL_RenderTexture(window->renderer, texture, &src_rect, &dst_rect);
    SDL_DestroyTexture(texture);
    if (!ok) {
        set_last_error_from_sdl();
        return 0;
    }
    return 1;
}

Font *font_get(const char *name_or_path, int size) {
    if (size <= 0) {
        set_last_error_literal("font size must be positive");
        return NULL;
    }

    Font *font = (Font *)SDL_calloc(1, sizeof(Font));
    if (font == NULL) {
        set_last_error_from_sdl();
        return NULL;
    }

    const char *resolved_name = (name_or_path != NULL && *name_or_path != '\0') ? name_or_path : "default";
    font->name_or_path = SDL_strdup(resolved_name);
    if (font->name_or_path == NULL) {
        set_last_error_from_sdl();
        SDL_free(font);
        return NULL;
    }
    font->size = size;
    return font;
}

void font_destroy(Font *font) {
    if (font == NULL) {
        return;
    }
    if (font->name_or_path != NULL) {
        SDL_free(font->name_or_path);
        font->name_or_path = NULL;
    }
    SDL_free(font);
}

int font_measure_text(Font *font, const char *text, int *width, int *height) {
    if (font == NULL) {
        set_last_error_literal("font is null");
        return 0;
    }

    size_t text_len = text != NULL ? SDL_strlen(text) : 0;
    int glyph_width = (font->size >= 2) ? (font->size * 3 / 5) : 1;
    int measured_width = (int)text_len * glyph_width;
    int measured_height = font->size;

    if (width != NULL) {
        *width = measured_width;
    }
    if (height != NULL) {
        *height = measured_height;
    }
    return 1;
}

Surface *font_render_text(Font *font, const char *text,
                          unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    if (font == NULL) {
        set_last_error_literal("font is null");
        return NULL;
    }

    int width = 0;
    int height = 0;
    if (!font_measure_text(font, text, &width, &height)) {
        return NULL;
    }

    int safe_width = width > 0 ? width : 1;
    int safe_height = height > 0 ? height : 1;
    Surface *surface = surface_create_blank(safe_width, safe_height);
    if (surface == NULL || surface->surface == NULL) {
        return NULL;
    }

    size_t text_len = text != NULL ? SDL_strlen(text) : 0;
    int glyph_width = (font->size >= 2) ? (font->size * 3 / 5) : 1;
    int glyph_height = (font->size >= 2) ? (font->size - 1) : 1;
    Uint32 aa_color = SDL_MapSurfaceRGBA(surface->surface, r, g, b, (Uint8)(a / 2));
    Uint32 fg_color = SDL_MapSurfaceRGBA(surface->surface, r, g, b, a);

    for (size_t i = 0; i < text_len; ++i) {
        unsigned char ch = (unsigned char)text[i];
        if (ch == ' ' || ch == '\t') {
            continue;
        }

        int x = (int)i * glyph_width;
        SDL_Rect aa_rect = { x, 0, glyph_width, glyph_height };
        SDL_Rect fg_rect = { x + 1, 1, glyph_width - 2 > 0 ? glyph_width - 2 : 1, glyph_height - 2 > 0 ? glyph_height - 2 : 1 };

        if (!SDL_FillSurfaceRect(surface->surface, &aa_rect, aa_color)) {
            set_last_error_from_sdl();
            surface_destroy(surface);
            return NULL;
        }
        if (!SDL_FillSurfaceRect(surface->surface, &fg_rect, fg_color)) {
            set_last_error_from_sdl();
            surface_destroy(surface);
            return NULL;
        }
    }

    return surface;
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
