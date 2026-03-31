#include "minerva_native.h"

#include <SDL3/SDL.h>
#include <ft2build.h>
#include FT_FREETYPE_H

#include <stdbool.h>
#include <stdio.h>
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
    FT_Face face;
};

static char g_last_error[512];
static FT_Library g_ft_library = NULL;
static bool g_ft_initialized = false;

static bool utf8_next_codepoint(const char *text, size_t text_len, size_t *index, unsigned int *codepoint) {
    if (text == NULL || index == NULL || codepoint == NULL || *index >= text_len) {
        return false;
    }

    unsigned char c0 = (unsigned char)text[*index];
    if (c0 < 0x80) {
        *codepoint = c0;
        *index += 1;
        return true;
    }

    if ((c0 & 0xE0) == 0xC0 && (*index + 1) < text_len) {
        unsigned char c1 = (unsigned char)text[*index + 1];
        if ((c1 & 0xC0) == 0x80) {
            *codepoint = ((unsigned int)(c0 & 0x1F) << 6) | (unsigned int)(c1 & 0x3F);
            *index += 2;
            return true;
        }
    }

    if ((c0 & 0xF0) == 0xE0 && (*index + 2) < text_len) {
        unsigned char c1 = (unsigned char)text[*index + 1];
        unsigned char c2 = (unsigned char)text[*index + 2];
        if (((c1 & 0xC0) == 0x80) && ((c2 & 0xC0) == 0x80)) {
            *codepoint = ((unsigned int)(c0 & 0x0F) << 12)
                       | ((unsigned int)(c1 & 0x3F) << 6)
                       | (unsigned int)(c2 & 0x3F);
            *index += 3;
            return true;
        }
    }

    if ((c0 & 0xF8) == 0xF0 && (*index + 3) < text_len) {
        unsigned char c1 = (unsigned char)text[*index + 1];
        unsigned char c2 = (unsigned char)text[*index + 2];
        unsigned char c3 = (unsigned char)text[*index + 3];
        if (((c1 & 0xC0) == 0x80) && ((c2 & 0xC0) == 0x80) && ((c3 & 0xC0) == 0x80)) {
            *codepoint = ((unsigned int)(c0 & 0x07) << 18)
                       | ((unsigned int)(c1 & 0x3F) << 12)
                       | ((unsigned int)(c2 & 0x3F) << 6)
                       | (unsigned int)(c3 & 0x3F);
            *index += 4;
            return true;
        }
    }

    *codepoint = 0xFFFDu;
    *index += 1;
    return true;
}

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
    if (FT_Init_FreeType(&g_ft_library) != 0) {
        set_last_error_literal("freetype init failed");
        SDL_Quit();
        return 0;
    }
    g_ft_initialized = true;
    return 1;
}

void minerva_shutdown(void) {
    if (g_ft_initialized && g_ft_library != NULL) {
        FT_Done_FreeType(g_ft_library);
        g_ft_library = NULL;
        g_ft_initialized = false;
    }
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

int surface_is_rgba32(Surface *surface) {
    if (surface == NULL || surface->surface == NULL) {
        return 0;
    }
    return surface->surface->format == SDL_PIXELFORMAT_RGBA32 ? 1 : 0;
}

int surface_fill_rect(Surface *surface, int x, int y, int width, int height,
                      unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    if (surface == NULL || surface->surface == NULL) {
        set_last_error_literal("surface is null");
        return 0;
    }
    if (width <= 0 || height <= 0) {
        return 1;
    }

    SDL_Rect rect = { x, y, width, height };
    Uint32 pixel = SDL_MapSurfaceRGBA(surface->surface, r, g, b, a);
    if (!SDL_FillSurfaceRect(surface->surface, &rect, pixel)) {
        set_last_error_from_sdl();
        return 0;
    }
    return 1;
}

int surface_fill(Surface *surface,
                 unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    if (surface == NULL || surface->surface == NULL) {
        set_last_error_literal("surface is null");
        return 0;
    }

    Uint32 pixel = SDL_MapSurfaceRGBA(surface->surface, r, g, b, a);
    if (!SDL_FillSurfaceRect(surface->surface, NULL, pixel)) {
        set_last_error_from_sdl();
        return 0;
    }
    return 1;
}

int surface_read_pixel(Surface *surface, int x, int y,
                       unsigned char *r, unsigned char *g, unsigned char *b, unsigned char *a) {
    if (surface == NULL || surface->surface == NULL) {
        set_last_error_literal("surface is null");
        return 0;
    }
    if (x < 0 || y < 0 || x >= surface->surface->w || y >= surface->surface->h) {
        set_last_error_literal("pixel coordinates out of bounds");
        return 0;
    }

    if (!SDL_LockSurface(surface->surface)) {
        set_last_error_from_sdl();
        return 0;
    }

    Uint8 *base = (Uint8 *)surface->surface->pixels;
    int pitch = surface->surface->pitch;
    Uint32 *row = (Uint32 *)(base + (y * pitch));
    Uint32 pixel = row[x];

    SDL_UnlockSurface(surface->surface);

    const SDL_PixelFormatDetails *format_details = SDL_GetPixelFormatDetails(surface->surface->format);
    if (format_details == NULL) {
        set_last_error_from_sdl();
        return 0;
    }

    Uint8 pr = 0, pg = 0, pb = 0, pa = 0;
    SDL_GetRGBA(pixel, format_details, NULL, &pr, &pg, &pb, &pa);

    if (r != NULL) *r = pr;
    if (g != NULL) *g = pg;
    if (b != NULL) *b = pb;
    if (a != NULL) *a = pa;

    return 1;
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

    if (!g_ft_initialized || g_ft_library == NULL) {
        set_last_error_literal("freetype is not initialized");
        return NULL;
    }

    Font *font = (Font *)SDL_calloc(1, sizeof(Font));
    if (font == NULL) {
        set_last_error_from_sdl();
        return NULL;
    }

    const char *resolved_name = (name_or_path != NULL && *name_or_path != '\0') ? name_or_path : "default";
    if (SDL_strcmp(resolved_name, "default") != 0) {
        FILE *font_file = fopen(resolved_name, "rb");
        if (font_file == NULL) {
            set_last_error_literal("font file not found");
            SDL_free(font);
            return NULL;
        }
        fclose(font_file);
    }
    font->name_or_path = SDL_strdup(resolved_name);
    if (font->name_or_path == NULL) {
        set_last_error_from_sdl();
        SDL_free(font);
        return NULL;
    }

    if (FT_New_Face(g_ft_library, resolved_name, 0, &font->face) != 0) {
        set_last_error_literal("font file could not be loaded by freetype");
        SDL_free(font->name_or_path);
        SDL_free(font);
        return NULL;
    }

    if (FT_Set_Pixel_Sizes(font->face, 0, (unsigned int)size) != 0) {
        set_last_error_literal("freetype failed to set pixel size");
        FT_Done_Face(font->face);
        SDL_free(font->name_or_path);
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
    if (font->face != NULL) {
        FT_Done_Face(font->face);
        font->face = NULL;
    }
    if (font->name_or_path != NULL) {
        SDL_free(font->name_or_path);
        font->name_or_path = NULL;
    }
    SDL_free(font);
}

int font_measure_text(Font *font, const char *text, int *width, int *height) {
    if (font == NULL || font->face == NULL) {
        set_last_error_literal("font is null");
        return 0;
    }

    size_t text_len = text != NULL ? SDL_strlen(text) : 0;
    int measured_width = 0;
    int measured_height = font->size;

    if (font->face->size != NULL) {
        int ascender = (int)((font->face->size->metrics.ascender + 63) >> 6);
        int descender = (int)((-font->face->size->metrics.descender + 63) >> 6);
        int line_height = (int)((font->face->size->metrics.height + 63) >> 6);
        int metric_height = ascender + descender;
        if (metric_height > measured_height) {
            measured_height = metric_height;
        }
        if (line_height > measured_height) {
            measured_height = line_height;
        }
    }

    FT_UInt prev_glyph_index = 0;
    size_t index = 0;
    while (index < text_len) {
        unsigned int codepoint = 0;
        if (!utf8_next_codepoint(text, text_len, &index, &codepoint)) {
            break;
        }

        FT_UInt glyph_index = FT_Get_Char_Index(font->face, codepoint);
        if (FT_HAS_KERNING(font->face) && prev_glyph_index != 0 && glyph_index != 0) {
            FT_Vector kerning;
            if (FT_Get_Kerning(font->face, prev_glyph_index, glyph_index, FT_KERNING_DEFAULT, &kerning) == 0) {
                measured_width += (int)(kerning.x >> 6);
            }
        }

        if (FT_Load_Glyph(font->face, glyph_index, FT_LOAD_DEFAULT) != 0) {
            set_last_error_literal("freetype failed to load glyph for measure");
            return 0;
        }

        measured_width += (int)(font->face->glyph->advance.x >> 6);
        prev_glyph_index = glyph_index;
    }

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
    if (font == NULL || font->face == NULL) {
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

    if (!SDL_LockSurface(surface->surface)) {
        set_last_error_from_sdl();
        surface_destroy(surface);
        return NULL;
    }

    int pen_x = 0;
    int baseline = 0;
    if (font->face->size != NULL) {
        baseline = (int)(font->face->size->metrics.ascender >> 6);
        if (baseline < 0) {
            baseline = 0;
        }
    }

    size_t text_len = text != NULL ? SDL_strlen(text) : 0;
    size_t index = 0;
    FT_UInt prev_glyph_index = 0;
    Uint8 *pixels = (Uint8 *)surface->surface->pixels;
    int pitch = surface->surface->pitch;
    const SDL_PixelFormatDetails *format_details = SDL_GetPixelFormatDetails(surface->surface->format);
    if (format_details == NULL) {
        SDL_UnlockSurface(surface->surface);
        set_last_error_from_sdl();
        surface_destroy(surface);
        return NULL;
    }

    while (index < text_len) {
        unsigned int codepoint = 0;
        if (!utf8_next_codepoint(text, text_len, &index, &codepoint)) {
            break;
        }

        FT_UInt glyph_index = FT_Get_Char_Index(font->face, codepoint);
        if (FT_HAS_KERNING(font->face) && prev_glyph_index != 0 && glyph_index != 0) {
            FT_Vector kerning;
            if (FT_Get_Kerning(font->face, prev_glyph_index, glyph_index, FT_KERNING_DEFAULT, &kerning) == 0) {
                pen_x += (int)(kerning.x >> 6);
            }
        }

        if (FT_Load_Glyph(font->face, glyph_index, FT_LOAD_DEFAULT | FT_LOAD_TARGET_NORMAL) != 0) {
            SDL_UnlockSurface(surface->surface);
            set_last_error_literal("freetype failed to render glyph");
            surface_destroy(surface);
            return NULL;
        }

        if (FT_Render_Glyph(font->face->glyph, FT_RENDER_MODE_NORMAL) != 0) {
            SDL_UnlockSurface(surface->surface);
            set_last_error_literal("freetype failed to rasterize glyph in normal mode");
            surface_destroy(surface);
            return NULL;
        }

        FT_GlyphSlot glyph = font->face->glyph;
        FT_Bitmap *bitmap = &glyph->bitmap;
        int glyph_x = pen_x + glyph->bitmap_left;
        int glyph_y = baseline - glyph->bitmap_top;

        for (int row = 0; row < (int)bitmap->rows; ++row) {
            for (int col = 0; col < (int)bitmap->width; ++col) {
                int dst_x = glyph_x + col;
                int dst_y = glyph_y + row;
                if (dst_x < 0 || dst_y < 0 || dst_x >= safe_width || dst_y >= safe_height) {
                    continue;
                }

                unsigned char coverage = 0;
                if (bitmap->pixel_mode == FT_PIXEL_MODE_GRAY) {
                    coverage = bitmap->buffer[row * bitmap->pitch + col];
                } else if (bitmap->pixel_mode == FT_PIXEL_MODE_MONO) {
                    unsigned char byte = bitmap->buffer[row * bitmap->pitch + (col >> 3)];
                    unsigned char bit = (unsigned char)(0x80u >> (col & 7));
                    coverage = (byte & bit) ? 255 : 0;
                }
                if (coverage == 0) {
                    continue;
                }

                Uint8 effective_alpha = (Uint8)(((unsigned int)a * (unsigned int)coverage) / 255u);
                Uint32 *row = (Uint32 *)(pixels + (dst_y * pitch));
                Uint32 dst_pixel = row[dst_x];
                Uint8 dst_r = 0;
                Uint8 dst_g = 0;
                Uint8 dst_b = 0;
                Uint8 dst_a = 0;
                SDL_GetRGBA(dst_pixel, format_details, NULL, &dst_r, &dst_g, &dst_b, &dst_a);

                unsigned int src_a = effective_alpha;
                unsigned int inv_a = 255u - src_a;

                Uint8 out_r = (Uint8)((r * src_a + dst_r * inv_a) / 255u);
                Uint8 out_g = (Uint8)((g * src_a + dst_g * inv_a) / 255u);
                Uint8 out_b = (Uint8)((b * src_a + dst_b * inv_a) / 255u);
                Uint8 out_a = (Uint8)(src_a + ((unsigned int)dst_a * inv_a) / 255u);
                row[dst_x] = SDL_MapRGBA(format_details, NULL, out_r, out_g, out_b, out_a);
            }
        }

        pen_x += (int)(glyph->advance.x >> 6);
        prev_glyph_index = glyph_index;
    }

    SDL_UnlockSurface(surface->surface);

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
