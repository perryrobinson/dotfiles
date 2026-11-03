#!/usr/bin/env bash
# Android build toolchain configuration (SDK + NDK, no emulator)
# JAVA_HOME is intentionally not set here; SDKMAN owns it (see java.sh).

if [ -d "$HOME/Android/Sdk" ]; then
    export ANDROID_HOME="$HOME/Android/Sdk"

    # Pinned NDK (keep in sync with ANDROID_NDK in tools/setup_android.sh)
    [ -d "$ANDROID_HOME/ndk/27.2.12479018" ] && export NDK_HOME="$ANDROID_HOME/ndk/27.2.12479018"

    [ -d "$ANDROID_HOME/cmdline-tools/latest/bin" ] && export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
fi
