#!/usr/bin/env bash
# Shared build environment. Source this from the other scripts:
#   source "$(dirname "$0")/env.sh"
#
# Override any of these by exporting them before running a script, e.g.:
#   ANDROID_HOME=/path/to/sdk scripts/build-android.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# ---------------------------------------------------------------------------
# Android SDK / NDK discovery
# ---------------------------------------------------------------------------
if [[ -z "${ANDROID_HOME:-}" ]]; then
    for cand in /opt/android-sdk "$HOME/Android/Sdk" /usr/lib/android-sdk /usr/local/android-sdk; do
        if [[ -d "$cand" ]]; then export ANDROID_HOME="$cand"; break; fi
    done
fi
export ANDROID_HOME="${ANDROID_HOME:-}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"

# Pick an NDK: explicit ANDROID_NDK_HOME wins, else newest under $ANDROID_HOME/ndk,
# else whatever ndk-bundle exists.
if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
    if [[ -d "$ANDROID_HOME/ndk" ]]; then
        ANDROID_NDK_HOME="$(ls -1 "$ANDROID_HOME/ndk" 2>/dev/null | sort -V | tail -1 || true)"
        [[ -n "$ANDROID_NDK_HOME" ]] && ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$ANDROID_NDK_HOME"
    elif [[ -d "$ANDROID_HOME/ndk-bundle" ]]; then
        ANDROID_NDK_HOME="$ANDROID_HOME/ndk-bundle"
    fi
fi
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-}"

# Toolchain versions used by scripts/setup-android-sdk.sh (override via env).
export NDK_VERSION="${NDK_VERSION:-27.2.12479018}"
export SDK_BUILD_TOOLS_VERSION="${SDK_BUILD_TOOLS_VERSION:-35.0.0}"
export SDK_PLATFORM_VERSION="${SDK_PLATFORM_VERSION:-android-35}"
export CMDLINE_TOOLS_VERSION="${CMDLINE_TOOLS_VERSION:-11076708}"

# PATH additions (safe if the dirs don't exist yet)
[[ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ]] && PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
[[ -d "$ANDROID_HOME/platform-tools" ]]           && PATH="$ANDROID_HOME/platform-tools:$PATH"
[[ -n "$ANDROID_NDK_HOME" ]]                      && PATH="$ANDROID_NDK_HOME:$PATH"
export PATH

# ABI list for native builds; must match abiFilters in app/build.gradle.
# Override before running the script, e.g.: ABIS="arm64-v8a x86_64" scripts/build-android.sh
export ABIS="${ABIS:-arm64-v8a}"

# Generate app/build.gradle abiFilters from $ABIS so both Gradle's Java config
# and the native (CMake) config stay in sync with the env var.
python3 - "$REPO_ROOT/android/app/build.gradle" <<'PYEOF'
import re, sys, os
path = sys.argv[1]
abis = os.environ.get("ABIS", "arm64-v8a").split()
filters = ", ".join(f"'{a}'" for a in abis)
src = open(path).read()
# Replace every active abiFilters line inside externalNativeBuild blocks.
out = re.sub(r"(?m)^(\s*)(//\s*)?abiFilters [^\n]*$", lambda m: f"{m.group(1)}abiFilters {filters}", src)
open(path, "w").write(out)
PYEOF

echo "REPO_ROOT=$REPO_ROOT"
echo "ANDROID_HOME=${ANDROID_HOME:-<not found>}"
echo "ANDROID_NDK_HOME=${ANDROID_NDK_HOME:-<not found>}"
