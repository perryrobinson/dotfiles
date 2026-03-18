#!/usr/bin/env bash
# Rust configuration (rustup + cargo)

export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"

# Add cargo bin to PATH
[ -d "$CARGO_HOME/bin" ] && export PATH="$CARGO_HOME/bin:$PATH"

# Enable shell completions for cargo and rustup
if command -v rustup &> /dev/null; then
    eval "$(rustup completions bash 2>/dev/null || true)"
    eval "$(rustup completions bash cargo 2>/dev/null || true)"
fi
