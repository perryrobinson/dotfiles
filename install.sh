#!/usr/bin/env bash
# Dotfiles installation script

# Strict mode
set -euo pipefail

# Calculate directories
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"

source "$DOTFILES_DIR/tools/common.sh"

log_header "Dotfiles Installation"
log_info "Dotfiles directory: $DOTFILES_DIR"
log_info "Backup directory: $BACKUP_DIR"

# Create backup directory
log_step 1 "Creating backup directory..."
mkdir -p "$BACKUP_DIR"
log_success "Created $BACKUP_DIR"

# Backup existing files
log_step 2 "Backing up existing configuration..."
for file in .bashrc .bash_aliases .bash_functions .bash_paths .bash_logger .tmux.conf .codex/AGENTS.md; do
    if [ -f "$HOME/$file" ] || [ -L "$HOME/$file" ]; then
        log_detail "Backing up $HOME/$file"
        mv "$HOME/$file" "$BACKUP_DIR/"
    fi
done

# Backup .bash_secrets but keep it in place (copy instead of move)
if [ -f "$HOME/.bash_secrets" ] || [ -L "$HOME/.bash_secrets" ]; then
    log_detail "Backing up $HOME/.bash_secrets (keeping original in place)"
    cp "$HOME/.bash_secrets" "$BACKUP_DIR/"
fi

# Ask user for installation method
log_section "Installation Configuration"
log_info "Select installation method:"
log_kv "Symlinks" "Recommended for git tracking"
log_kv "Copies" "Recommended for local-only changes"

if confirm "Do you want to use symlinks?" "y"; then
    install_method="symlink"
else
    install_method="copy"
fi
log_info "Selected method: $install_method"

# Function to install files
install_files() {
    local src="$1"
    local dest="$2"
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"
    
    if [ "$install_method" = "symlink" ]; then
        ln -sf "$src" "$dest"
        log_success "Linked $(basename "$src") -> $dest"
    else
        cp "$src" "$dest"
        log_success "Copied $(basename "$src") -> $dest"
    fi
}

# Install configuration files
log_section "Installing Core Configuration"
install_files "$DOTFILES_DIR/bash/bashrc" "$HOME/.bashrc"
install_files "$DOTFILES_DIR/bash/bash_aliases" "$HOME/.bash_aliases"
install_files "$DOTFILES_DIR/bash/bash_functions" "$HOME/.bash_functions"
install_files "$DOTFILES_DIR/bash/bash_paths" "$HOME/.bash_paths"
install_files "$DOTFILES_DIR/bash/bash_logger" "$HOME/.bash_logger"
install_files "$DOTFILES_DIR/config/tmux.conf" "$HOME/.tmux.conf"
install_files "$DOTFILES_DIR/config/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"

# Create secrets file from template if it doesn't exist
if [ ! -f "$HOME/.bash_secrets" ]; then
    log_info "Creating ~/.bash_secrets from template"
    cp "$DOTFILES_DIR/bash/bash_secrets.template" "$HOME/.bash_secrets"
    log_warn "Please edit ~/.bash_secrets to add your actual credentials"
fi

# Create tool configs directory and install files
log_section "Installing Tool Configurations"
mkdir -p "$HOME/.tool_configs"
for file in "$DOTFILES_DIR/bash/tool_configs/"*.sh; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        install_files "$file" "$HOME/.tool_configs/$filename"
    fi
done

# Install packages if on Debian/Ubuntu
if command -v apt-get &> /dev/null; then
    log_section "System Packages"
    if confirm "Do you want to install essential packages?"; then
        log_step 1 "Installing essential packages..."
        
        # Set timezone to America/Chicago (CST)
        log_detail "Setting timezone to America/Chicago..."
        if sudo ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime && \
           echo "America/Chicago" | sudo tee /etc/timezone > /dev/null; then
           log_success "Timezone set"
        else
           log_error "Failed to set timezone"
        fi
        
        log_detail "Updating apt repositories..."
        sudo apt-get update >/dev/null
        
        # Read packages from essentials.txt file
        log_detail "Installing packages from packages/essentials.txt..."
        if [ ! -f "$DOTFILES_DIR/packages/essentials.txt" ]; then
            die "packages/essentials.txt not found — dotfiles repo may be incomplete"
        fi
        if xargs sudo apt-get install -y < "$DOTFILES_DIR/packages/essentials.txt"; then
            log_success "Essential packages installed"
        else
            log_error "Failed to install some packages"
        fi
        
        # Install Docker if not already installed (skip in CI — no systemd in containers)
        if [[ "${DOTFILES_CI:-}" != "1" ]]; then
            if ! command -v docker &> /dev/null; then
                if confirm "Do you want to install Docker?"; then
                    log_step 2 "Installing Docker..."
                    curl -fsSL https://get.docker.com | sh
                    sudo usermod -aG docker "$USER"
                    log_warn "You may need to log out and back in for Docker permissions to take effect"
                fi
            fi

            # Docker Compose - modern Docker ships with 'docker compose' as a plugin
            if docker compose version &> /dev/null; then
                log_success "Docker Compose plugin already available: $(docker compose version --short)"
            elif ! command -v docker-compose &> /dev/null; then
                if confirm "Do you want to install the Docker Compose plugin?"; then
                    log_step 3 "Installing Docker Compose plugin..."
                    sudo apt-get install -y docker-compose-plugin
                    log_success "Docker Compose plugin installed"
                fi
            else
                log_info "Legacy docker-compose found: $(docker-compose --version)"
            fi
        fi
    fi
fi

# Make setup scripts executable
chmod +x "$DOTFILES_DIR/tools/"*.sh

# Function to install development tools
install_dev_tools() {
    log_section "Development Tools Setup"
    
    # Setup Git configuration
    if confirm "Do you want to set up Git configuration and SSH keys?"; then
        bash "$DOTFILES_DIR/tools/setup_git.sh"
    fi

    # Install Java with SDKMAN
    if confirm "Do you want to install Java (using SDKMAN)?"; then
        bash "$DOTFILES_DIR/tools/setup_java.sh"
    fi
    
    # Install Python with uv
    if confirm "Do you want to install Python (using uv)?"; then
        bash "$DOTFILES_DIR/tools/setup_python.sh"
    fi
    
    # Install Node.js with nvm
    if confirm "Do you want to install Node.js (using nvm)?"; then
        bash "$DOTFILES_DIR/tools/setup_node.sh"
    fi

    # Install Bun
    if confirm "Do you want to install Bun (JavaScript runtime)?"; then
        bash "$DOTFILES_DIR/tools/setup_bun.sh"
    fi

    # Install Go
    if confirm "Do you want to install Go?"; then
        bash "$DOTFILES_DIR/tools/setup_golang.sh"
    fi

    # Install Rust
    if confirm "Do you want to install Rust?"; then
        bash "$DOTFILES_DIR/tools/setup_rust.sh"
    fi

    # Install Neovim with LazyVim
    if confirm "Do you want to install Neovim with LazyVim?"; then
        bash "$DOTFILES_DIR/tools/setup_nvim.sh"
    fi
}

# Ask if the user wants to install development tools
if confirm "Do you want to set up development tools now?"; then
    install_dev_tools
else
    log_info "You can set up development tools later by running individual scripts in tools/:"
    log_kv "Git" "./tools/setup_git.sh"
    log_kv "Java" "./tools/setup_java.sh"
    log_kv "Python" "./tools/setup_python.sh"
    log_kv "Node.js" "./tools/setup_node.sh"
    log_kv "Bun" "./tools/setup_bun.sh"
    log_kv "Go" "./tools/setup_golang.sh"
    log_kv "Rust" "./tools/setup_rust.sh"
    log_kv "Neovim" "./tools/setup_nvim.sh"
fi

log_section "Installation Complete"
if [ "$install_method" = "symlink" ]; then
    log_success "Method: Symlinks (changes tracked)"
else
    log_success "Method: Copies (local changes only)"
fi
log_info "Backup location: $BACKUP_DIR"
log_warn "Please log out and log back in to ensure all changes are applied."
