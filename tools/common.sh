#!/usr/bin/env bash
# Common bootstrapping for tools/ setup scripts.
# Requires DOTFILES_DIR to be set before sourcing.

if [[ -z "${DOTFILES_DIR:-}" ]] || [[ ! -f "$DOTFILES_DIR/bash/bash_logger" ]]; then
    echo "Error: bash_logger not found (DOTFILES_DIR=${DOTFILES_DIR:-unset})" >&2
    exit 1
fi

# shellcheck source=../bash/bash_logger
source "$DOTFILES_DIR/bash/bash_logger"
