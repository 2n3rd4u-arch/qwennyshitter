/* Minimal SDL3 app: opens a window, clears it, runs an event loop.
 * Built for both desktop and Android by the top-level CMakeLists.txt.
 *
 * On Android we use SDL's main-callbacks model (the activity calls our
 * exported SDL_main(), which drives SDL_EnterAppMainCallbacks). Everywhere
 * else we just use a classic main(). */
#include <SDL3/SDL.h>

#if defined(SDL_PLATFORM_ANDROID)
#define USE_SDL_MAIN_CALLBACKS 1
#endif

#ifdef USE_SDL_MAIN_CALLBACKS
#define SDL_MAIN_USE_CALLBACKS 1
#endif
#include <SDL3/SDL_main.h>

#include <string.h>

static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;

static void draw_frame(void)
{
    SDL_SetRenderDrawColor(renderer, 0x20, 0x20, 0x40, 0xFF);
    SDL_RenderClear(renderer);
    SDL_RenderPresent(renderer);
}

static bool init_app(void)
{
    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("SDL_Init failed: %s", SDL_GetError());
        return false;
    }
    window = SDL_CreateWindow("myapp", 640, 480, SDL_WINDOW_RESIZABLE);
    if (!window) {
        SDL_Log("SDL_CreateWindow failed: %s", SDL_GetError());
        return false;
    }
    if (!SDL_CreateRenderer(window, NULL)) {
        SDL_Log("SDL_CreateRenderer failed: %s", SDL_GetError());
        return false;
    }
    return true;
}

#ifdef USE_SDL_MAIN_CALLBACKS

SDL_AppResult SDL_AppInit(void **appstate, int argc, char *argv[])
{
    (void)argc;
    (void)argv;
    if (!init_app())
        return SDL_APP_FAILURE;
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *appstate)
{
    (void)appstate;
    draw_frame();
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event)
{
    (void)appstate;
    if (event->type == SDL_EVENT_QUIT)
        return SDL_APP_SUCCESS;
    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, SDL_AppResult result)
{
    (void)appstate;
    (void)result;
    SDL_Quit();
}

#else /* classic main() entry point (desktop) */

int main(int argc, char *argv[])
{
    const bool smoke = (argc > 1 && strcmp(argv[1], "--smoke") == 0);

    if (!init_app())
        return 1;

    if (smoke) {           /* headless CI self-test: init + render one frame */
        draw_frame();
        SDL_Quit();
        SDL_Log("smoke test OK");
        return 0;
    }

    for (bool running = true; running; ) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_EVENT_QUIT)
                running = false;
        }
        draw_frame();
    }
    SDL_Quit();
    return 0;
}

#endif
