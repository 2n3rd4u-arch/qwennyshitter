cmake_minimum_required(VERSION 3.16)
project(myapp LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED TRUE)

# ---------------------------------------------------------------------------
# SDL3 (vendored in ./SDL). Built from source for every platform, including
# Android (the android/ gradle project adds this same file via externalNativeBuild).
# ---------------------------------------------------------------------------
if(NOT TARGET SDL3::SDL3)
    set(SDL_TESTS OFF CACHE BOOL "" FORCE)
    set(SDL_TEST_LIBRARY OFF CACHE BOOL "" FORCE)
    set(SDL_EXAMPLES OFF CACHE BOOL "" FORCE)
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/SDL" sdl-build)
endif()

# ---------------------------------------------------------------------------
# Game sources (shared between Android and desktop)
# ---------------------------------------------------------------------------
file(GLOB GAME_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c")

if(ANDROID)
    # The Java activity loads libmain.so and calls its exported SDL_main(),
    # so use SDL's main-callbacks model and ship no native main() here.
    add_library(main SHARED ${GAME_SOURCES})
    target_compile_definitions(main PRIVATE SDL_MAIN_USE_CALLBACKS)
    target_link_libraries(main PRIVATE SDL3::SDL3)
else()
    # Desktop: X11/Wayland dev packages may be absent in CI containers;
    # allow a "console" build in that case instead of failing configure.
    if(UNIX AND NOT APPLE AND NOT EXISTS "${CMAKE_INSTALL_PREFIX}/include/X11/Xlib.h")
        find_package(X11 QUIET)
        if(NOT X11_FOUND)
            set(SDL_UNIX_CONSOLE_BUILD ON CACHE BOOL "" FORCE)
        endif()
    endif()

    add_executable(myapp ${GAME_SOURCES})
    target_link_libraries(myapp PRIVATE SDL3::SDL3)

    enable_testing()
    add_test(NAME myapp-smoke COMMAND myapp --smoke)
endif()
