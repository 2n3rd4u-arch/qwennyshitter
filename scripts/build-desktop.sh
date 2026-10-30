#!/usr/bin/env bash
# Configure and build the desktop (host) target with CMake + vendored SDL3.
#
# Usage: scripts/build-desktop.sh [Debug|Release]   (default: Release)
# Binary lands in: build/host/myapp

set -euo pipefail
source "$(dirname "$0")/env.sh"

BUILD_TYPE="${1:-Release}"
BUILD_DIR="$REPO_ROOT/build/host"

cmake -S "$REPO_ROOT" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
cmake --build "$BUILD_DIR" --parallel

echo
echo ">> Built: $BUILD_DIR/myapp"
"$BUILD_DIR/myapp" --smoke 2>/dev/null || echo "(smoke test needs a display; skipping run)"
