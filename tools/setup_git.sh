#!/usr/bin/env bash
# Git setup script for user authentication and basic configuration

set -e

# --- Helper Functions ---
info() { echo "INFO: $1"; }
warn() { echo "WARN: $1"; }
error() { echo "ERROR: $1" >&2; exit 1; }

# --- Check if git is installed ---
if ! command -v git &> /dev/null; then
    error "Git is not installed. Please install git first."
fi

info "Setting up Git configuration..."

# --- Get user information ---
echo "Please provide your Git configuration details:"

# Get name
current_name=$(git config --global user.name 2>/dev/null || echo "")
if [ -n "$current_name" ]; then
    read -p "Git user name (current: $current_name): " git_name
    git_name=${git_name:-$current_name}
else
    read -p "Git user name: " git_name
    while [ -z "$git_name" ]; do
        echo "Name cannot be empty."
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
        echo "Email cannot be empty."
        read -p "Git user email: " git_email
    done
fi

# --- Set git configuration ---
info "Configuring Git with user information..."
git config --global user.name "$git_name"
git config --global user.email "$git_email"

# --- Set basic git preferences ---
info "Setting up Git preferences..."
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global push.default simple
git config --global core.autocrlf input

# Optional: Set up credential helper based on OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Check if we're in WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        info "WSL detected - setting up Git credential manager"
        git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
    else
        info "Setting up credential helper for Linux"
        git config --global credential.helper store
    fi
fi

# --- SSH Key Setup ---
ssh_dir="$HOME/.ssh"
ssh_key="$ssh_dir/id_ed25519"

if [ ! -f "$ssh_key" ]; then
    echo
    read -p "Do you want to generate an SSH key for Git authentication? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Generating SSH key..."
        mkdir -p "$ssh_dir"
        ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key" -N ""
        
        # Start ssh-agent and add key
        eval "$(ssh-agent -s)" >/dev/null
        ssh-add "$ssh_key" 2>/dev/null || true
        
        info "SSH key generated at: $ssh_key"
        info "Public key:"
        echo "----------------------------------------"
        cat "$ssh_key.pub"
        echo "----------------------------------------"
        echo
        info "Copy the above public key and add it to your Git hosting service:"
        info "  GitHub: https://github.com/settings/ssh/new"
        info "  GitLab: https://gitlab.com/-/profile/keys"
        info "  Bitbucket: https://bitbucket.org/account/settings/ssh-keys/"
        echo
        read -p "Press Enter after you've added the key to your Git hosting service..."
        
        # Test SSH connection to common Git hosts
        echo
        info "Testing SSH connections..."
        
        # Test GitHub
        if ssh -T git@github.com -o ConnectTimeout=5 -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
            info "✓ GitHub SSH connection successful"
        else
            warn "✗ GitHub SSH connection failed (this is normal if you haven't added the key yet)"
        fi
        
        # Test GitLab
        if ssh -T git@gitlab.com -o ConnectTimeout=5 -o StrictHostKeyChecking=no 2>&1 | grep -q "Welcome to GitLab"; then
            info "✓ GitLab SSH connection successful"
        else
            warn "✗ GitLab SSH connection failed (this is normal if you haven't added the key yet)"
        fi
    fi
else
    info "SSH key already exists at: $ssh_key"
    info "Public key:"
    echo "----------------------------------------"
    cat "$ssh_key.pub"
    echo "----------------------------------------"
fi

# --- Display current configuration ---
echo
info "Git configuration complete!"
info "Current Git configuration:"
echo "  Name: $(git config --global user.name)"
echo "  Email: $(git config --global user.email)"
echo "  Default branch: $(git config --global init.defaultBranch)"
echo "  Pull strategy: $(git config --global pull.rebase)"

if [ -f "$ssh_key" ]; then
    echo "  SSH key: $ssh_key"
fi

echo
info "You can now clone repositories using SSH or HTTPS authentication."