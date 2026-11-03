#!/usr/bin/env bash
# Install the Android build toolchain (no emulator): cmdline-tools, platform,
# build-tools, NDK, and Rust Android targets. For Tauri 2 / Gradle builds.
# The emulator is expected to run on the Windows host, not in WSL.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES_DIR/tools/common.sh"

# --- Configuration ---
ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
ANDROID_PLATFORM="platforms;android-35"
ANDROID_BUILD_TOOLS="build-tools;35.0.0"
ANDROID_NDK="ndk;27.2.12479018"
RUST_ANDROID_TARGETS=(aarch64-linux-android x86_64-linux-android)
MIN_JAVA_MAJOR=17

# Command-line tools: exact build, SHA-256 as published in the
# "Command line tools only" table at https://developer.android.com/studio
CMDLINE_TOOLS_BUILD="15859902"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_BUILD}_latest.zip"
CMDLINE_TOOLS_SHA256="4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583"

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
NDK_DIR="$ANDROID_HOME/ndk/${ANDROID_NDK#ndk;}"

log_header "Android Build Toolchain Setup"

# --- Prerequisites ---
log_section "Checking Prerequisites"

log_step 1 "Checking for Java $MIN_JAVA_MAJOR+..."
JAVA_SDKMAN_HOME="$HOME/.sdkman/candidates/java/current"
if [ -x "$JAVA_SDKMAN_HOME/bin/java" ]; then
    # SDKMAN owns JAVA_HOME; use it for sdkmanager in this process only
    export JAVA_HOME="$JAVA_SDKMAN_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
fi
if ! command -v java &> /dev/null || [ ! -x "$JAVA_SDKMAN_HOME/bin/java" ]; then
    die "Java not found via SDKMAN. Run ./tools/setup_java.sh first."
fi
JAVA_MAJOR="$(java -version 2>&1 | awk -F'"' '/version/ {split($2, v, "."); print (v[1] == "1" ? v[2] : v[1]); exit}')"
if ! [[ "$JAVA_MAJOR" =~ ^[0-9]+$ ]] || [ "$JAVA_MAJOR" -lt "$MIN_JAVA_MAJOR" ]; then
    die "Java $MIN_JAVA_MAJOR+ required (found: ${JAVA_MAJOR:-unknown}). Run ./tools/setup_java.sh first."
fi
log_success "Java $JAVA_MAJOR found"

log_step 2 "Checking dependencies..."
for dep in curl unzip sha256sum; do
    command -v "$dep" &> /dev/null || die "$dep is required. Install it and re-run this script."
done
log_success "Dependencies found (curl, unzip, sha256sum)"

# --- CI: offline sanity path only ---
# The SDK/NDK is multi-GB; CI verifies prerequisite logic and pins, not downloads.
if [[ "${DOTFILES_CI:-}" == "1" ]]; then
    log_section "CI Mode"
    log_info "DOTFILES_CI=1: skipping downloads (SDK/NDK/Rust targets)"
    log_kv "SDK location" "$ANDROID_HOME"
    log_kv "cmdline-tools" "$CMDLINE_TOOLS_URL"
    log_kv "Packages" "$ANDROID_PLATFORM, $ANDROID_BUILD_TOOLS, $ANDROID_NDK"
    log_kv "Rust targets" "${RUST_ANDROID_TARGETS[*]}"
    log_success "Sanity checks passed"
    exit 0
fi

# --- Command-line tools ---
log_section "Android Command-Line Tools"

if [ -x "$SDKMANAGER" ]; then
    log_success "cmdline-tools already installed at $ANDROID_HOME/cmdline-tools/latest"
else
    log_step 3 "Downloading cmdline-tools ($CMDLINE_TOOLS_BUILD)..."
    WORK_DIR="$(mktemp -d)"
    trap 'rm -rf "$WORK_DIR"' EXIT
    curl -fsSL -o "$WORK_DIR/cmdline-tools.zip" "$CMDLINE_TOOLS_URL"

    log_detail "Verifying SHA-256..."
    ACTUAL_SHA256="$(sha256sum "$WORK_DIR/cmdline-tools.zip" | awk '{print $1}')"
    if [ "$ACTUAL_SHA256" != "$CMDLINE_TOOLS_SHA256" ]; then
        die "SHA-256 mismatch for cmdline-tools (expected $CMDLINE_TOOLS_SHA256, got $ACTUAL_SHA256)"
    fi
    log_success "Checksum verified"

    unzip -q "$WORK_DIR/cmdline-tools.zip" -d "$WORK_DIR/unpacked"
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    rm -rf "$ANDROID_HOME/cmdline-tools/latest"
    mv "$WORK_DIR/unpacked/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
    log_success "cmdline-tools installed"
fi

# --- SDK packages ---
log_section "SDK Packages"

INSTALLED="$("$SDKMANAGER" --sdk_root="$ANDROID_HOME" --list_installed 2>/dev/null || true)"
MISSING=()
for pkg in "$ANDROID_PLATFORM" "$ANDROID_BUILD_TOOLS" "$ANDROID_NDK"; do
    if grep -qE "^[[:space:]]*${pkg//./\\.}[[:space:]]*\|" <<< "$INSTALLED"; then
        log_success "$pkg already installed"
    else
        MISSING+=("$pkg")
    fi
done

if [ "${#MISSING[@]}" -gt 0 ]; then
    log_step 4 "Installing: ${MISSING[*]}"
    # Accept the SDK licenses non-interactively so the script never hangs on a prompt.
    # Running this script is taken as acceptance of the Android SDK License Agreement
    # (https://developer.android.com/studio/terms); sdkmanager records it under $ANDROID_HOME/licenses.
    # Process substitution (not a pipe) avoids a pipefail SIGPIPE from `yes`.
    log_warn "Accepting Android SDK licenses (https://developer.android.com/studio/terms)"
    "$SDKMANAGER" --sdk_root="$ANDROID_HOME" --licenses < <(yes) > /dev/null
    "$SDKMANAGER" --sdk_root="$ANDROID_HOME" "${MISSING[@]}" < /dev/null
    # sdkmanager exits 0 when a license is declined, so confirm what landed
    INSTALLED="$("$SDKMANAGER" --sdk_root="$ANDROID_HOME" --list_installed 2>/dev/null || true)"
    for pkg in "${MISSING[@]}"; do
        grep -qE "^[[:space:]]*${pkg//./\\.}[[:space:]]*\|" <<< "$INSTALLED" \
            || die "$pkg was not installed . Re-run this script."
    done
    log_success "SDK packages installed"
else
    log_info "Nothing to do: all SDK packages already installed"
fi

# --- Rust targets ---
log_section "Rust Android Targets"

if ! command -v rustup &> /dev/null; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi
if command -v rustup &> /dev/null; then
    RUST_INSTALLED="$(rustup target list --installed)"
    RUST_MISSING=()
    for target in "${RUST_ANDROID_TARGETS[@]}"; do
        if grep -qx "$target" <<< "$RUST_INSTALLED"; then
            log_success "$target already installed"
        else
            RUST_MISSING+=("$target")
        fi
    done
    if [ "${#RUST_MISSING[@]}" -gt 0 ]; then
        log_step 5 "Adding Rust targets: ${RUST_MISSING[*]}"
        rustup target add "${RUST_MISSING[@]}"
        log_success "Rust targets added"
    fi
else
    die "rustup not found. Run ./tools/setup_rust.sh first."
fi

# --- Verify ---
[ -d "$NDK_DIR" ] || die "NDK not found at $NDK_DIR"
[ -d "$ANDROID_HOME/platforms/${ANDROID_PLATFORM#platforms;}" ] || die "Platform not found under $ANDROID_HOME/platforms"

log_section "Setup Complete"
log_info "Installed:"
log_kv "Java"          "$(java -version 2>&1 | head -1)"
log_kv "sdkmanager"    "$("$SDKMANAGER" --sdk_root="$ANDROID_HOME" --version 2>/dev/null)"
log_kv "Platform"      "${ANDROID_PLATFORM#platforms;}"
log_kv "Build tools"   "${ANDROID_BUILD_TOOLS#build-tools;}"
log_kv "NDK"           "${ANDROID_NDK#ndk;}"
log_kv "Rust targets"  "${RUST_ANDROID_TARGETS[*]}"
log_info "Paths (set by ~/.tool_configs/android.sh):"
log_kv "ANDROID_HOME"  "$ANDROID_HOME"
log_kv "NDK_HOME"      "$NDK_DIR"
log_kv "sdkmanager"    "$SDKMANAGER"
