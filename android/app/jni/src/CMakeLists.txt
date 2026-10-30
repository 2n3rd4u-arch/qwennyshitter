cmake_minimum_required(VERSION 3.16)

project(my_app LANGUAGES C)

set(GAME_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../../src/main.c
)

# The activity loads "libSDL3.so" then "libmain.so"; SDLActivity calls the
# exported SDL_main() of libmain.so, so use SDL's main-callbacks model.
add_library(main SHARED ${GAME_SOURCES})
target_compile_definitions(main PRIVATE SDL_MAIN_USE_CALLBACKS)

if(TARGET SDL3::SDL3)
    target_link_libraries(main PRIVATE SDL3::SDL3)
else()
    find_package(SDL3 CONFIG REQUIRED)
    target_link_libraries(main PRIVATE SDL3::SDL3)
endif()
