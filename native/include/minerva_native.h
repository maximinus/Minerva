#ifndef MINERVA_NATIVE_H
#define MINERVA_NATIVE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Window Window;
typedef struct Surface Surface;
typedef struct Font Font;

typedef enum {
    EVENT_NONE = 0,
    EVENT_QUIT,
    EVENT_WINDOW_RESIZED,
    EVENT_KEY_DOWN,
    EVENT_KEY_UP,
    EVENT_MOUSE_BUTTON_DOWN,
    EVENT_MOUSE_BUTTON_UP,
    EVENT_MOUSE_MOVE
} EventType;

typedef struct {
    EventType type;
    int a;
    int b;
    int c;
    int d;
} Event;

int init(void);
void minerva_shutdown(void);
const char *last_error(void);

Window *window_create(const char *title, int width, int height);
void window_destroy(Window *window);
int window_should_close(Window *window);
void window_request_close(Window *window);
void window_get_size(Window *window, int *width, int *height);

int poll_event(Event *out_event);

void begin_frame(Window *window);
void clear(Window *window, unsigned char r, unsigned char g, unsigned char b, unsigned char a);
void fill_rect(Window *window, int x, int y, int width, int height,
                     unsigned char r, unsigned char g, unsigned char b, unsigned char a);
void end_frame(Window *window);

Surface *surface_create_blank(int width, int height);
Surface *surface_load_file(const char *path);
void surface_destroy(Surface *surface);
int surface_width(Surface *surface);
int surface_height(Surface *surface);
int surface_is_rgba32(Surface *surface);

int surface_fill_rect(Surface *surface, int x, int y, int width, int height,
                      unsigned char r, unsigned char g, unsigned char b, unsigned char a);
int surface_read_pixel(Surface *surface, int x, int y,
                       unsigned char *r, unsigned char *g, unsigned char *b, unsigned char *a);

int surface_blit(Surface *src, Surface *dst, int dst_x, int dst_y);
int surface_blit_rect(Surface *src, int src_x, int src_y, int src_width, int src_height,
                      Surface *dst, int dst_x, int dst_y);
int surface_blit_rect_scaled(Surface *src, int src_x, int src_y, int src_width, int src_height,
                             Surface *dst, int dst_x, int dst_y, int dst_width, int dst_height);

int window_draw_surface(Window *window, Surface *surface, int dst_x, int dst_y);
int window_draw_surface_rect(Window *window, Surface *surface,
                             int src_x, int src_y, int src_width, int src_height,
                             int dst_x, int dst_y);
int window_draw_surface_rect_scaled(Window *window, Surface *surface,
                                    int src_x, int src_y, int src_width, int src_height,
                                    int dst_x, int dst_y, int dst_width, int dst_height);

Font *font_get(const char *name_or_path, int size);
void font_destroy(Font *font);
int font_measure_text(Font *font, const char *text, int *width, int *height);
Surface *font_render_text(Font *font, const char *text,
                          unsigned char r, unsigned char g, unsigned char b, unsigned char a);

unsigned long long ticks_ms(void);
void sleep_ms(int ms);

#ifdef __cplusplus
}
#endif

#endif
