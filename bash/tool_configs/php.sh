#!/usr/bin/env bash
# PHP configuration with Composer and Laravel

# Add Composer global bin directory to PATH
if [ -d "$HOME/.composer/vendor/bin" ]; then
    export PATH="$HOME/.composer/vendor/bin:$PATH"
fi

# Alternative Composer global directory (newer versions)
if [ -d "$HOME/.config/composer/vendor/bin" ]; then
    export PATH="$HOME/.config/composer/vendor/bin:$PATH"
fi