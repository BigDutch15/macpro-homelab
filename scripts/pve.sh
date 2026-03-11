#!/bin/bash

# =============================================================================
# PVE Entity Creation - Main Entry Point
# =============================================================================
#
# USAGE:
#   Remote execution (production):
#     bash <(curl -fsSL https://raw.githubusercontent.com/BigDutch15/macpro-homelab/main/scripts/pve.sh)
#
#   Remote execution (branch testing):
#     bash <(curl -fsSL https://raw.githubusercontent.com/BigDutch15/macpro-homelab/BRANCH/scripts/pve.sh) --branch BRANCH
#
#   Local execution:
#     bash pve.sh
#     bash pve.sh --branch feature/my-branch
#
# OPTIONS:
#   --branch <name>    Git branch to use for sourcing scripts (default: main)
#   --debug            Enable debug output
#   --help             Show this help message
#
# EXAMPLES:
#   bash <(curl -fsSL https://raw.githubusercontent.com/BigDutch15/macpro-homelab/main/scripts/pve.sh)
#   bash <(curl -fsSL https://raw.githubusercontent.com/BigDutch15/macpro-homelab/feature/test/scripts/pve.sh) --branch feature/test
#
# =============================================================================

# Repository configuration defaults
REPO_OWNER="BigDutch15"
REPO_NAME="macpro-homelab"
REPO_BRANCH="main"
DEBUG=0

# =============================================================================
# Parse Arguments (before sourcing debug.sh so --debug works)
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --branch)
            REPO_BRANCH="$2"
            DEBUG=1  # Enable debug by default when testing branches
            shift 2
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        --help)
            head -28 "$0" | tail -24
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# =============================================================================
# Build Repository URL
# =============================================================================
REPO_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/scripts"

# =============================================================================
# Source Debug Framework
# =============================================================================
if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common/debug.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common/debug.sh"
else
    source <(curl -fsSL "$REPO_URL/common/debug.sh")
fi

# =============================================================================
# Display Configuration
# =============================================================================
debug_section "Repository Configuration"
debug_var REPO_OWNER
debug_var REPO_NAME
debug_var REPO_BRANCH
debug_var REPO_URL

info "Repository Configuration"
echo "  Owner:  $REPO_OWNER"
echo "  Repo:   $REPO_NAME"
echo "  Branch: $REPO_BRANCH"
echo "  URL:    $REPO_URL"
echo ""

# =============================================================================
# Source Prompts
# =============================================================================
debug_section "Loading Prompts"

if [[ -f "$(dirname "${BASH_SOURCE[0]}")/common/prompts.sh" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common/prompts.sh"
    debug "Loaded prompts from local file"
else
    PROMPTS_CONTENT=$(curl -fsSL "$REPO_URL/common/prompts.sh" 2>&1)
    if [[ $? -eq 0 && -n "$PROMPTS_CONTENT" ]]; then
        source <(echo "$PROMPTS_CONTENT")
        debug "Loaded prompts from remote URL"
    else
        error "Failed to load prompts.sh from $REPO_URL/common/prompts.sh"
        error "Response: $PROMPTS_CONTENT"
        exit 1
    fi
fi

# =============================================================================
# Main Menu
# =============================================================================
debug_section "Main Menu"

setPromptTitle "PVE Entity Creation"

show_main_menu() {
    ensureWhiptail
    
    local choice
    choice=$(whiptail --title "PVE Entity Creation" --menu "Select entity to create:" 12 60 3 \
        "1" "LXC - Debian 13" \
        "2" "Exit" \
        3>&1 1>&2 2>&3)
    
    case $choice in
        1)
            info "Selected: Debian 13 LXC"
            debug "Would run lxc/debian.sh here"
            # TODO: source and run debian.sh
            ;;
        2|"")
            info "Exiting"
            exit 0
            ;;
    esac
}

show_main_menu
