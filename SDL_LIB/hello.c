#include <stdio.h>
#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <SDL3_image/SDL_image.h>


struct Data {
    SDL_Window *window;
    SDL_Surface *image;
    SDL_Surface *patch;
    SDL_Surface *screen;
    TTF_Text *font;
};


SDL_Window *setup(char* title, int width, int height) {
    SDL_Window *window;
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Init(SDL_INIT_AUDIO);
    window = SDL_CreateWindow(title, width, height, SDL_WINDOW_RESIZABLE);
    return window;
}


SDL_Surface* load_image(char* filepath) {
    SDL_Surface *new_image = IMG_Load(filepath);
    if(new_image == NULL) {
        printf("Failed to get image: %s\n", SDL_GetError());
    }
    return new_image;
}


TTF_Text* load_font() {
    TTF_Init();
    TTF_Font *font = TTF_OpenFont("./assets/dominica.ttf", 32.0);
    TTF_TextEngine *engine = TTF_CreateSurfaceTextEngine();
    TTF_Text *text = TTF_CreateText(engine, font, "Minerva Lisp IDE", 16);
    TTF_SetTextColor(text, 0, 0, 0, 255);
    return text;
}


void play_audio() {
    SDL_AudioStream *audio;
    struct SDL_AudioSpec audio_spec;
    Uint8 *audio_stream;
    Uint32 audio_size;

    SDL_LoadWAV("./assets/song.wav", &audio_spec, &audio_stream, &audio_size);
    audio = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &audio_spec, NULL, NULL);
    SDL_PutAudioStreamData(audio, audio_stream, audio_size);
    SDL_ResumeAudioStreamDevice(audio);
}


char* get_mod_keys() {
    SDL_Keymod mod = SDL_GetModState();

    static char str[64];
    str[0] = '\0';  /* start with an empty string */

    bool needSpace = false;
    /* Check SHIFT (either left or right) */
    if (mod & SDL_KMOD_SHIFT) {
        strcat(str, "SHIFT");
        needSpace = true;
    }
    /* Check CTRL (either left or right) */
    if (mod & SDL_KMOD_CTRL) {
        if (needSpace) strcat(str, " ");
        strcat(str, "CTRL");
        needSpace = true;
    }
    /* Check ALT (either left or right) */
    if (mod & SDL_KMOD_ALT) {
        if (needSpace) strcat(str, " ");
        strcat(str, "ALT");
        needSpace = true;
    }
    /* Check CAPS lock */
    if (mod & SDL_KMOD_CAPS) {
        if (needSpace) strcat(str, " ");
        strcat(str, "CAPS");
    }

    return str;
}


void blit_image(SDL_Surface *source, SDL_Surface *dest, int xpos, int ypos) {
    struct SDL_Rect pos = {xpos, ypos, 0, 0};
    SDL_BlitSurface(source, NULL, dest, &pos);
}


void update_screen(struct Data *data) {
    int txt_width;
    int xpos;

    data->screen = SDL_GetWindowSurface(data->window);
    SDL_FillSurfaceRect(data->screen, NULL, (Uint32)0xFFFFFFFFu);
    // blit 9-patch
    SDL_BlitSurface9Grid(data->patch, NULL, 16, 16, 16, 16, 0.0, SDL_SCALEMODE_NEAREST, data->screen, NULL);

    // blit text
    TTF_GetTextSize(data->font, &txt_width, NULL);
    xpos = (data->screen->w - txt_width) / 2;
    TTF_DrawSurfaceText(data->font, xpos, 420, data->screen);

    // blit logo
    xpos = (data->screen->w - data->image->w) / 2;
    blit_image(data->image, data->screen, xpos, 64);
    SDL_UpdateWindowSurface(data->window);
}


void show_mouse_information(SDL_MouseButtonEvent *event) {
    if(event->down) {
        printf("Mouse %d down @ (%d, %d)\n", event->button, (int)event->x, (int)event->y);
    } else {
        printf("Mouse %d up @ (%d, %d)\n", event->button, (int)event->x, (int)event->y);
    }
}


void wait_for_keypress(struct Data *data) {
    SDL_Event test_event;

    while(SDL_WaitEvent(&test_event)) {
        switch (test_event.type) {
            case SDL_EVENT_KEY_DOWN:
                // check the key type, print it and quit only on "q"
                // get current modifiers, shift, ctrl, alt
                printf("Got key: %s %s\n", get_mod_keys(), SDL_GetKeyName(test_event.key.key));
                if(test_event.key.key == SDLK_Q) {
                    printf("Quitting\n");
                    return;
                }
                break;
            case SDL_EVENT_WINDOW_RESIZED:
                update_screen(data);
                break;
            case SDL_EVENT_MOUSE_BUTTON_DOWN:
                show_mouse_information((SDL_MouseButtonEvent *)&test_event);
                break;
            case SDL_EVENT_QUIT:
                return;
        }
    }
}


void cleanup(struct Data *data) {
    SDL_DestroySurface(data->image);
    SDL_DestroyWindow(data->window);
    SDL_Quit();
}


int main(int argc, char* argv[]) {
    struct Data data;

    data.window = setup("SDL3 Test", 800, 600);
    data.screen = SDL_GetWindowSurface(data.window);
    data.image = load_image("./assets/logo.png");
    data.patch = load_image("./assets/patch.png");
    data.font = load_font();
    update_screen(&data);
    play_audio();
    wait_for_keypress(&data);
    cleanup(&data);
    return 0;
}
