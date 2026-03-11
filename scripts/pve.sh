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

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --branch)
            REPO_BRANCH="$2"
            shift 2
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

# Build repository URL
REPO_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/scripts"

echo "=== Repository Configuration ==="
echo "  Owner:  $REPO_OWNER"
echo "  Repo:   $REPO_NAME"
echo "  Branch: $REPO_BRANCH"
echo "  URL:    $REPO_URL"
echo ""

