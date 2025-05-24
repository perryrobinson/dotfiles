#!/usr/bin/env bash

# Go configuration
# Ensure GOROOT is set if Go is installed in /usr/local/go
if [ -d "/usr/local/go/bin" ]; then
    export GOROOT="/usr/local/go"
    export PATH="${PATH}:${GOROOT}/bin"
fi

# Set GOPATH to the default location if it's not already set
if [ -z "$GOPATH" ]; then
    export GOPATH="$HOME/go"
fi

# Add GOPATH/bin to PATH
export PATH="${PATH}:${GOPATH}/bin"
