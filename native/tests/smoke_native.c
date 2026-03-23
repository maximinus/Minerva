#include "minerva_native.h"

#include <stdio.h>

int main(void) {
    if (!init()) {
        fprintf(stderr, "init failed: %s\n", last_error());
        return 1;
    }

    Window *window = window_create("Minerva Native Smoke", 800, 600);
    if (window == NULL) {
        fprintf(stderr, "window create failed: %s\n", last_error());
        minerva_shutdown();
        return 1;
    }

    unsigned long long start = ticks_ms();
    Event event;

    while (!window_should_close(window)) {
        while (poll_event(&event)) {
            if (event.type == EVENT_QUIT) {
                window_request_close(window);
            }
        }

        begin_frame(window);
        clear(window, 0, 0, 0, 255);
        fill_rect(window, 200, 150, 300, 180, 0, 64, 255, 255);
        end_frame(window);

        if (ticks_ms() - start > 1500) {
            window_request_close(window);
        }

        sleep_ms(16);
    }

    window_destroy(window);
    minerva_shutdown();

    return 0;
}
