#!/usr/bin/env bash
# Install Rust via rustup
# rustup manages Rust toolchains (rustc, cargo, clippy, rustfmt)

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$DOTFILES_DIR/tools/common.sh"

log_header "Rust Setup (rustup)"

log_section "Installing Rust"

if command -v rustup &> /dev/null; then
    log_info "Rust is already installed, checking for updates..."
    rustup update stable 2>/dev/null || true
    log_success "Rust updated"
else
    log_step 1 "Installing Rust via rustup..."
    # Install with --no-modify-path since PATH is managed by tool_configs/rust.sh
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

    # Add to PATH for this session
    export PATH="$HOME/.cargo/bin:$PATH"
    log_success "Rust installed"

    log_detail "Note: PATH is managed by ~/.tool_configs/rust.sh"
fi

# Verify installation
if ! command -v rustc &> /dev/null; then
    die "Rust installation failed"
fi

log_success "rustc $(rustc --version | awk '{print $2}') ready"

log_section "Setup Complete"
log_info "Quick reference:"
log_kv "rustup update" "Update Rust toolchain"
log_kv "rustup component add" "Add components (e.g., rust-analyzer)"
log_kv "cargo new" "Create a new project"
log_kv "cargo build" "Build the project"
log_kv "cargo run" "Build and run"
log_kv "cargo test" "Run tests"
