#!/usr/bin/env bash
# Build the Android APK with Gradle + the NDK (CMake native mode).
#
# Prerequisites (run once):  scripts/setup-android-sdk.sh
# Usage:                     scripts/build-android.sh [gradle task, default: assembleDebug]
#
# Env overrides: ABIS="arm64-v8a x86_64" to build more ABIs.

set -euo pipefail
source "$(dirname "$0")/env.sh"

TASK="${1:-assembleDebug}"

if [[ -z "${ANDROID_NDK_HOME:-}" || ! -d "$ANDROID_NDK_HOME" ]]; then
    echo "ERROR: NDK not found. Run scripts/setup-android-sdk.sh first." >&2
    exit 1
fi

# Make sure Gradle can find the SDK. The NDK is selected via android.ndkVersion
# in app/build.gradle (ndk.dir in local.properties is deprecated), so we only
# write sdk.dir here.
if [[ ! -f "$REPO_ROOT/android/local.properties" ]]; then
    echo "sdk.dir=$ANDROID_HOME" > "$REPO_ROOT/android/local.properties"
    echo ">> Wrote android/local.properties (generated)."
fi

# The native build is driven by android/app/jni/CMakeLists.txt, which builds
# vendored SDL3 from the repo root plus the game sources in jni/src/. Create
# the conventional "SDL" symlink there so the template CMake/ndk-build files
# both resolve it.
ln -sfn ../../../SDL "$REPO_ROOT/android/app/jni/SDL"

cd "$REPO_ROOT/android"

echo ">> Building ($TASK, ABIS=$ABIS)..."
./gradlew --no-daemon -PBUILD_WITH_CMAKE=1 \
    "-PNDK_VERSION=$NDK_VERSION" \
    "$TASK"

APK_DIR="$REPO_ROOT/android/app/build/outputs/apk"
echo
echo ">> APKs:"
find "$APK_DIR" -name '*.apk' -exec ls -lh {} \;
