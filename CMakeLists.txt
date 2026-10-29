cmake_minimum_required(VERSION 3.16)
project(myapp LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED TRUE)

# ---------------------------------------------------------------------------
# SDL3 (vendored in ./SDL). On Android this builds libSDL3.so via the
# android/SDL3Config.cmake shim; on desktop it uses SDL's own build system.
# ---------------------------------------------------------------------------
if(ANDROID)
    # Shim package config that builds SDL from source and defines SDL3::SDL3
    set(SDL3_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android/SDL3")
endif()

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/SDL" sdl-build)

# ---------------------------------------------------------------------------
# Game sources (shared between Android and desktop)
# ---------------------------------------------------------------------------
file(GLOB GAME_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c")

if(ANDROID)
    # The Java activity dlopen()s libmyapp.so and calls main() directly,
    # so we ship our own entry point instead of SDL's android main shim.
    add_library(myapp SHARED ${GAME_SOURCES})
    target_compile_definitions(myapp PRIVATE SDL_MAIN_HANDLED)
else()
    add_executable(myapp ${GAME_SOURCES})
endif()

target_link_libraries(myapp PRIVATE SDL3::SDL3)

if(NOT ANDROID)
    enable_testing()
    add_test(NAME myapp-smoke COMMAND myapp --smoke)
endif()
