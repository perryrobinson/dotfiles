#!/usr/bin/env bash
# Demo script to visually test bash_logger output

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bash/bash_logger"

log_header "Bash Logger Demo"

log_section "Log Levels"
log_debug "This is a debug message (only visible with LOG_LEVEL=debug)"
log_info "This is an info message"
log_success "This is a success message"
log_warn "This is a warning message"
log_error "This is an error message"

log_section "Steps & Details"
log_step "1" "First step of the process"
log_detail "Sub-task A"
log_detail "Sub-task B"
log_detail_last "Sub-task C (last)"

log_step "2" "Second step with key-value pairs"
log_kv "Version" "1.0.0"
log_kv "Platform" "$(uname -s)"
log_kv "User" "$USER"

log_section "Commands & Separators"
log_cmd "apt-get install -y curl wget"
log_separator
log_info "After separator"

log_section "Utilities"
log_info "require_cmd checks if a command exists"
log_cmd "require_cmd git"
require_cmd git && log_success "git is available"

log_header "Demo Complete"

# Uncomment to test confirm:
# confirm "Do you want to continue?" && log_success "Confirmed!" || log_warn "Cancelled"
