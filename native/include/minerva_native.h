#ifndef MINERVA_NATIVE_H
#define MINERVA_NATIVE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Window Window;

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

unsigned long long ticks_ms(void);
void sleep_ms(int ms);

#ifdef __cplusplus
}
#endif

#endif
