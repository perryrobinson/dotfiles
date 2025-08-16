#!/usr/bin/env bash
# Install PHP, Composer, and Laravel

echo "Installing PHP and required extensions..."
if command -v apt-get &> /dev/null; then
    # Update package list
    sudo apt update
    
    # Install PHP and required extensions
    sudo apt install -y php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath
    
    echo "PHP installation complete"
else
    echo "This script currently supports Debian/Ubuntu systems only"
    exit 1
fi

# Verify PHP installation
echo "Verifying PHP installation..."
php --version

echo "Installing Composer (PHP package manager)..."
if ! command -v composer &> /dev/null; then
    # Download and install Composer
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    
    echo "Composer installation complete"
else
    echo "Composer is already installed"
fi

# Verify Composer installation
echo "Verifying Composer installation..."
composer --version

echo "Installing Laravel globally..."
if command -v composer &> /dev/null; then
    composer global require laravel/installer
    
    echo "Laravel installer installed globally"
    echo "You can now create Laravel projects with: laravel new project-name"
else
    echo "Could not install Laravel - Composer not found"
    exit 1
fi

echo "PHP setup complete!"
echo "Make sure to restart your shell or run 'source ~/.bashrc' to use Laravel commands"