# Top-level CMake project used by Gradle's externalNativeBuild (CMake mode).
# It builds SDL3 itself (from the "SDL" symlink) plus the game library in src/.
cmake_minimum_required(VERSION 3.16)

project(GAME LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED TRUE)

# SDL sources are vendored at the repo root (./SDL). The app's jni/ dir lives
# at android/app/jni, so the repo root is THREE levels up. A symlink named
# "SDL" here (created by scripts/build-android.sh) also works.
get_filename_component(REPO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
set(REPO_ROOT_CANDIDATE "${REPO_ROOT}/SDL")
set(SDK_BUILD_WITH_SDL3 ON)

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/SDL/CMakeLists.txt")
    set(SDL_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/SDL")
elseif(EXISTS "${REPO_ROOT_CANDIDATE}/CMakeLists.txt")
    set(SDL_SRC_DIR "${REPO_ROOT_CANDIDATE}")
else()
    message(FATAL_ERROR "Vendored SDL not found; run builds via scripts/build-android.sh")
endif()
message(STATUS "Using SDL sources: ${SDL_SRC_DIR}")

set(SDL_TESTS OFF CACHE BOOL "" FORCE)
set(SDL_TEST_LIBRARY OFF CACHE BOOL "" FORCE)
set(SDL_EXAMPLES OFF CACHE BOOL "" FORCE)
add_subdirectory("${SDL_SRC_DIR}" "${CMAKE_BINARY_DIR}/sdl-build")

# Compilation of companion libraries
#add_subdirectory(SDL_image)
#add_subdirectory(SDL_mixer)
#add_subdirectory(SDL_ttf)

# Your game and its CMakeLists.txt are in a subfolder named "src"
add_subdirectory(src)
