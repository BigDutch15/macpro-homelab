#!/bin/bash

# =============================================================================
# Debug and Logging Framework
# =============================================================================
# Source this file to enable consistent logging across all scripts
#
# USAGE:
#   source debug.sh
#   DEBUG=1  # Enable debug output
#
#   debug "This only shows in debug mode"
#   info "Informational message"
#   warn "Warning message"
#   error "Error message"
#
# =============================================================================

# Default debug off unless already set
DEBUG="${DEBUG:-0}"

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
else
    RED=''
    YELLOW=''
    GREEN=''
    BLUE=''
    CYAN=''
    NC=''
fi

# Debug message - only shows when DEBUG=1
debug() {
    [[ $DEBUG -eq 1 ]] && echo -e "${CYAN}[DEBUG]${NC} $*" >&2
}

# Info message - always shows
info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

# Warning message - shows to stderr
warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

# Error message - shows to stderr
error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Print variable name and value (debug mode only)
debug_var() {
    [[ $DEBUG -eq 1 ]] && echo -e "${CYAN}[DEBUG]${NC} $1 = ${!1}" >&2
}

# Print section header (debug mode only)
debug_section() {
    if [[ $DEBUG -eq 1 ]]; then
        echo "" >&2
        echo -e "${CYAN}[DEBUG] === $1 ===${NC}" >&2
    fi
}

# Print a step/progress message
step() {
    echo -e "${BLUE}[STEP]${NC} $*"
}

# Print success message
success() {
    echo -e "${GREEN}[OK]${NC} $*"
}
