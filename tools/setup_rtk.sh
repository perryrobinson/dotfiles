#!/usr/bin/env bash
# Install RTK (Rust Token Killer) and configure for all AI coding tools

set -euo pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
source "$DOTFILES_DIR/tools/common.sh"

log_header "RTK - Rust Token Killer Setup"

# Install RTK binary
install_rtk() {
    if command -v rtk &>/dev/null; then
        log_info "RTK already installed: $(rtk --version)"
        return
    fi

    log_step 1 "Installing RTK..."

    local arch os asset
    arch="$(uname -m)"
    os="$(uname -s)"

    case "$os" in
        Linux)
            case "$arch" in
                x86_64)  asset="rtk-x86_64-unknown-linux-musl.tar.gz" ;;
                aarch64) asset="rtk-aarch64-unknown-linux-gnu.tar.gz" ;;
                *) die "Unsupported architecture: $arch" ;;
            esac
            ;;
        Darwin)
            case "$arch" in
                x86_64)  asset="rtk-x86_64-apple-darwin.tar.gz" ;;
                arm64)   asset="rtk-aarch64-apple-darwin.tar.gz" ;;
                *) die "Unsupported architecture: $arch" ;;
            esac
            ;;
        *) die "Unsupported OS: $os" ;;
    esac

    local url="https://github.com/rtk-ai/rtk/releases/latest/download/$asset"
    local tmp; tmp="$(mktemp -d)"

    log_detail "Downloading $asset..."
    curl -fsSL "$url" -o "$tmp/$asset"
    tar -xzf "$tmp/$asset" -C "$tmp"
    mkdir -p "$HOME/.local/bin"
    mv "$tmp/rtk" "$HOME/.local/bin/rtk"
    chmod +x "$HOME/.local/bin/rtk"
    rm -rf "$tmp"

    log_success "RTK installed: $(rtk --version)"
}

# Configure Claude Code: add preToolUse hook to settings.json
configure_claude() {
    log_step 2 "Configuring Claude Code..."
    local settings="$HOME/.claude/settings.json"

    if [ ! -f "$settings" ]; then
        log_warn "~/.claude/settings.json not found — skipping hook injection (install Claude Code first)"
        return
    fi

    if grep -q "rtk hook claude" "$settings" 2>/dev/null; then
        log_info "Claude Code RTK hook already configured"
        return
    fi

    local tmp; tmp="$(mktemp)"
    jq '.hooks.PreToolUse = (.hooks.PreToolUse // []) + [{
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "rtk hook claude"}]
    }]' "$settings" > "$tmp" && mv "$tmp" "$settings"

    log_success "Claude Code RTK hook added to settings.json"
}

install_rtk
configure_claude

log_section "RTK Setup Complete"
log_info "All AI tool configs already include RTK instructions via dotfiles."
log_info "Claude Code: hook active via settings.json"
log_info "Codex:       @RTK.md reference in AGENTS.md"
log_info "OpenCode:    rewrite plugin at ~/.config/opencode/plugins/rtk.ts"
log_info "Kiro:        RTK steering doc at ~/.kiro/steering/rtk.md"
log_warn "Ensure ~/.local/bin is in your PATH."
