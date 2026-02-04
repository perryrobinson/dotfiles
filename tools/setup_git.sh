#!/usr/bin/env bash
# Git setup script for user authentication and basic configuration

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source Logger
if [ -f "$DOTFILES_DIR/bash/bash_logger" ]; then
    source "$DOTFILES_DIR/bash/bash_logger"
else
    echo "Error: bash_logger not found at $DOTFILES_DIR/bash/bash_logger"
    exit 1
fi

log_header "Git Setup"

# --- Check if git is installed ---
if ! command -v git &> /dev/null; then
    die "Git is not installed. Please install git first."
fi

log_step "Setting up Git configuration..."

# --- Get user information ---
log_info "Please provide your Git configuration details:"

# Get name
current_name=$(git config --global user.name 2>/dev/null || echo "")
if [ -n "$current_name" ]; then
    read -p "Git user name (current: $current_name): " git_name
    git_name=${git_name:-$current_name}
else
    read -p "Git user name: " git_name
    while [ -z "$git_name" ]; do
        log_warn "Name cannot be empty."
        read -p "Git user name: " git_name
    done
fi

# Get email
current_email=$(git config --global user.email 2>/dev/null || echo "")
if [ -n "$current_email" ]; then
    read -p "Git user email (current: $current_email): " git_email
    git_email=${git_email:-$current_email}
else
    read -p "Git user email: " git_email
    while [ -z "$git_email" ]; do
        log_warn "Email cannot be empty."
        read -p "Git user email: " git_email
    done
fi

# --- Set git configuration ---
log_info "Configuring Git with user information..."
git config --global user.name "$git_name"
git config --global user.email "$git_email"

# --- Set basic git preferences ---
log_info "Setting up Git preferences..."
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global push.default simple
git config --global core.autocrlf input

# Optional: Set up credential helper based on OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Check if we're in WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        log_info "WSL detected - setting up Git credential manager"
        git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
    else
        log_info "Setting up credential helper for Linux"
        git config --global credential.helper store
    fi
fi

# --- SSH Key Setup ---
ssh_dir="$HOME/.ssh"
ssh_key="$ssh_dir/id_ed25519"

if [ ! -f "$ssh_key" ]; then
    if confirm "Do you want to generate an SSH key for Git authentication?"; then
        log_step "Generating SSH key..."
        mkdir -p "$ssh_dir"
        ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key" -N ""
        
        # Start ssh-agent and add key
        eval "$(ssh-agent -s)" >/dev/null
        ssh-add "$ssh_key" 2>/dev/null || true
        
        log_success "SSH key generated at: $ssh_key"
        log_info "Public key:"
        log_separator
        cat "$ssh_key.pub"
        log_separator
        
        log_info "Copy the above public key and add it to your Git hosting service:"
        log_kv "GitHub" "https://github.com/settings/ssh/new"
        log_kv "GitLab" "https://gitlab.com/-/profile/keys"
        log_kv "Bitbucket" "https://bitbucket.org/account/settings/ssh-keys/"
        
        echo
        read -p "Press Enter after you've added the key to your Git hosting service..."
        
        # Test SSH connection to common Git hosts
        log_step "Testing SSH connections..."
        
        # Test GitHub
        if ssh -T git@github.com -o ConnectTimeout=5 -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
            log_success "GitHub SSH connection successful"
        else
            log_warn "GitHub SSH connection failed (this is normal if you haven't added the key yet)"
        fi
        
        # Test GitLab
        if ssh -T git@gitlab.com -o ConnectTimeout=5 -o StrictHostKeyChecking=no 2>&1 | grep -q "Welcome to GitLab"; then
            log_success "GitLab SSH connection successful"
        else
            log_warn "GitLab SSH connection failed (this is normal if you haven't added the key yet)"
        fi
    fi
else
    log_info "SSH key already exists at: $ssh_key"
    log_info "Public key:"
    log_separator
    cat "$ssh_key.pub"
    log_separator
fi

# --- Display current configuration ---
log_success "Git configuration complete!"
log_info "Current Git configuration:"
log_kv "Name" "$(git config --global user.name)"
log_kv "Email" "$(git config --global user.email)"
log_kv "Default branch" "$(git config --global init.defaultBranch)"
log_kv "Pull strategy" "$(git config --global pull.rebase)"

if [ -f "$ssh_key" ]; then
    log_kv "SSH key" "$ssh_key"
fi

log_info "You can now clone repositories using SSH or HTTPS authentication."
