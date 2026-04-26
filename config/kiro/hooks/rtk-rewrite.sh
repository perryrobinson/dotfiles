#!/usr/bin/env bash
set -uo pipefail

if ! command -v jq &>/dev/null; then echo "rtk-rewrite: jq not found, skipping" >&2; exit 0; fi
if ! command -v rtk &>/dev/null; then echo "rtk-rewrite: rtk not found, skipping" >&2; exit 0; fi

# Cache version check — requires rtk >= 0.23.0
CACHE="$HOME/.cache/rtk-hook-version-ok"
if [ ! -f "$CACHE" ]; then
    V=$(rtk --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [ -z "$V" ]; then exit 0; fi
    MAJOR=${V%%.*}
    MINOR=${V#*.}; MINOR=${MINOR%%.*}
    if [ "$MAJOR" -eq 0 ] && [ "$MINOR" -lt 23 ]; then
        echo "rtk-rewrite: rtk >= 0.23.0 required (found $V)" >&2
        exit 0
    fi
    mkdir -p "$(dirname "$CACHE")" && echo "$V" > "$CACHE"
fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -z "$CMD" ] && exit 0

REWRITTEN=$(rtk rewrite "$CMD" 2>/dev/null)
RC=$?

case $RC in
    0|3)
        if [ "$REWRITTEN" != "$CMD" ]; then
            echo "BLOCKED: rtk rewrote this command. Run this instead: $REWRITTEN" >&2
            exit 2
        fi
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
