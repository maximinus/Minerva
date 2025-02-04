#include "sdl_wrapper.c"


int main() {
    FrameInput input;
    input.exit = false;
    Engine engine;

    init_engine(&engine, "SDL Hello", SCREEN_WIDTH, SCREEN_HEIGHT);
    Rect rect = {100, 100, 200, 200};

    while(!input.exit) {
        process_events(&input);
        clear_screen(&engine);
        draw_rectangle(engine.render, &rect, "#FF7F00");
        update_screen(&engine);
    }
    cleanup(engine.window);
    return 0;
}

