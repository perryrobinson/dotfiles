#!/usr/bin/env bash
# Java configuration with SDKMAN

export SDKMAN_DIR="$HOME/.sdkman"
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi