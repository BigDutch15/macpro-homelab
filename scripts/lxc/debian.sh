#!/bin/bash

# Debian LXC Container Creation
# Uses common scripts for prompts and functions

# Dynamic repo URL - supports branch testing via environment variable
REPO_OWNER="${REPO_OWNER:-BigDutch15}"
REPO_NAME="${REPO_NAME:-macpro-homelab}"
REPO_BRANCH="${REPO_BRANCH:-main}"
REPO_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/scripts"

# Source common scripts (supports both local and remote execution)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/../common/debug.sh" ]]; then
    # Local execution
    COMMON_DIR="$SCRIPT_DIR/../common"
    source "$COMMON_DIR/debug.sh"
    source "$COMMON_DIR/config.sh"
    source "$COMMON_DIR/prompts.sh"
    source "$COMMON_DIR/functions.sh"
else
    # Remote execution - source each file with error handling
    for script in debug.sh config.sh prompts.sh functions.sh; do
        CONTENT=$(curl -fsSL "$REPO_URL/common/$script" 2>&1)
        if [[ $? -eq 0 && -n "$CONTENT" ]]; then
            source <(echo "$CONTENT")
        else
            echo "[ERROR] Failed to load $script from $REPO_URL/common/$script" >&2
            echo "[ERROR] Response: $CONTENT" >&2
            exit 1
        fi
    done
fi

# =============================================================================
# Debian LXC Container Creation
# =============================================================================
debug_section "Debian LXC Container Creation"
debug_var REPO_OWNER
debug_var REPO_NAME
debug_var REPO_BRANCH
debug_var REPO_URL

info "Debian LXC Container Creation Script Initiated"

# Step 1: Ensure template is available
step "Checking Debian 13 template..."
TEMPLATE=$(ensureTemplate "debian" "13")
if [[ -z "$TEMPLATE" ]]; then
    error "Failed to get template"
    exit 1
fi
debug_var TEMPLATE
success "Template ready: $TEMPLATE"

# Step 2: Get PVE ID
step "Getting next available PVE ID..."
DEFAULT_ID=$(getNextPveId)
debug_var DEFAULT_ID
PVE_ID=$(getContainerId "$DEFAULT_ID")
debug_var PVE_ID

# Validate ID doesn't already exist
if idExists "$PVE_ID"; then
    error "Container/VM $PVE_ID already exists!"
    exit 1
fi
success "PVE ID: $PVE_ID"

# Step 3: Get Privileged/Unprivileged selection
step "Container privilege selection..."
UNPRIVILEGED=$(getPrivileged)
debug_var UNPRIVILEGED

# Step 4: Get Root Password
PASSWORD=$(getRootPassword)
# Note: Password is stored securely and never displayed

# Step 5: Get Hostname
HOSTNAME=$(getHostname "lxc-debian")
debug_var HOSTNAME

# Step 6: Get CPU Cores
CPU_CORES=$(getCpuCores "2")
debug_var CPU_CORES

# Step 7: Get Memory
MEMORY=$(getMemory "2048")
debug_var MEMORY

# Step 8: Get Swap (default to 50% of memory)
SWAP_DEFAULT=$((MEMORY / 2))
SWAP=$(getSwap "$SWAP_DEFAULT")
debug_var SWAP

# Step 9: Get Storage Location
STORAGE=$(getStorage "local-lvm")
debug_var STORAGE

# Step 10: Get Root Filesystem Size
ROOTFS_SIZE=$(getRootfsSize "16")
debug_var ROOTFS_SIZE

# Step 11: Get Network Bridge
BRIDGE=$(getNetworkBridge "vmbr0")
debug_var BRIDGE

# Step 12: Get VLAN (default derived from ID: digits before last 3)
VLAN_DEFAULT=$((PVE_ID / 1000))
[[ "$VLAN_DEFAULT" -eq 0 ]] && VLAN_DEFAULT=1
VLAN=$(getVlanTag "$VLAN_DEFAULT")
debug_var VLAN

# Step 13: Get IP Configuration
IP_MODE=$(getIpMode)
debug_var IP_MODE

if [[ "$IP_MODE" == "static" ]]; then
    # Derive default IP from host IP, VLAN, and container ID
    DEFAULT_IP=$(deriveDefaultIp "$VLAN" "$PVE_ID")
    debug_var DEFAULT_IP
    IP_ADDRESS=$(getStaticIp "${DEFAULT_IP}/24")
    debug_var IP_ADDRESS
    
    # Derive default gateway from host IP and VLAN
    DEFAULT_GATEWAY=$(deriveDefaultGateway "$VLAN")
    debug_var DEFAULT_GATEWAY
    GATEWAY=$(getGateway "$DEFAULT_GATEWAY")
    debug_var GATEWAY
    MAC_ADDRESS=""
else
    IP_ADDRESS="dhcp"
    debug_var IP_ADDRESS
    GATEWAY=""
    debug_var GATEWAY
    
    # Prompt for MAC address (optional)
    MAC_ADDRESS=$(getMacAddress)
    debug_var MAC_ADDRESS
fi

# Step 14: Confirm configuration
step "Review Configuration"
CONFIRM_MSG="Please review the container configuration:


ID: $PVE_ID
Hostname: $HOSTNAME
Template: $TEMPLATE
Privileged: $([ "$UNPRIVILEGED" -eq 0 ] && echo "Yes" || echo "No")
CPU Cores: $CPU_CORES
Memory: ${MEMORY}MB
Swap: ${SWAP}MB
Storage: $STORAGE
Root FS: ${ROOTFS_SIZE}GB
Bridge: $BRIDGE
VLAN: $VLAN
IP: $IP_ADDRESS"

if [[ "$IP_MODE" == "static" ]]; then
    CONFIRM_MSG="$CONFIRM_MSG
Gateway: $GATEWAY"
fi

if [[ -n "$MAC_ADDRESS" ]]; then
    CONFIRM_MSG="$CONFIRM_MSG
MAC: $MAC_ADDRESS"
fi

CONFIRM_MSG="$CONFIRM_MSG

Proceed with container creation?"

if ! whiptail --title "Confirm Configuration" --yesno "$CONFIRM_MSG" 20 70; then
    warn "Container creation cancelled by user"
    exit 0
fi
success "Configuration confirmed"

# Step 15: Build and display container creation command
step "Building container creation command..."

# Build the pct create command
CREATE_CMD="pct create $PVE_ID $TEMPLATE"
CREATE_CMD="$CREATE_CMD --hostname $HOSTNAME"
CREATE_CMD="$CREATE_CMD --arch amd64"
CREATE_CMD="$CREATE_CMD --ostype debian"
CREATE_CMD="$CREATE_CMD --cores $CPU_CORES"
CREATE_CMD="$CREATE_CMD --memory $MEMORY"
CREATE_CMD="$CREATE_CMD --swap $SWAP"
CREATE_CMD="$CREATE_CMD --storage $STORAGE"
CREATE_CMD="$CREATE_CMD --rootfs $STORAGE:$ROOTFS_SIZE"

# Build network configuration
NET_CONFIG="name=eth0,bridge=$BRIDGE,tag=$VLAN,firewall=1,type=veth"

# Add IP configuration
if [[ "$IP_MODE" == "static" ]]; then
    NET_CONFIG="$NET_CONFIG,ip=$IP_ADDRESS,gw=$GATEWAY"
else
    NET_CONFIG="$NET_CONFIG,ip=dhcp"
fi

# Add MAC if specified
if [[ -n "$MAC_ADDRESS" ]]; then
    NET_CONFIG="$NET_CONFIG,hwaddr=$MAC_ADDRESS"
fi

CREATE_CMD="$CREATE_CMD --net0 $NET_CONFIG"

# Add unprivileged flag
CREATE_CMD="$CREATE_CMD --unprivileged $UNPRIVILEGED"

# Add start flag
CREATE_CMD="$CREATE_CMD --start 0"

# Display the command (with password redacted)
debug_section "Container Creation Command"
echo "[DEBUG] Command to execute:" >&2
echo "[DEBUG] pct create $PVE_ID $TEMPLATE \\" >&2
echo "[DEBUG]   --hostname $HOSTNAME \\" >&2
echo "[DEBUG]   --arch amd64 \\" >&2
echo "[DEBUG]   --ostype debian \\" >&2
echo "[DEBUG]   --cores $CPU_CORES \\" >&2
echo "[DEBUG]   --memory $MEMORY \\" >&2
echo "[DEBUG]   --swap $SWAP \\" >&2
echo "[DEBUG]   --storage $STORAGE \\" >&2
echo "[DEBUG]   --rootfs $STORAGE:$ROOTFS_SIZE \\" >&2
echo "[DEBUG]   --net0 $NET_CONFIG \\" >&2
echo "[DEBUG]   --unprivileged $UNPRIVILEGED \\" >&2
echo "[DEBUG]   --password <REDACTED> \\" >&2
echo "[DEBUG]   --start 0" >&2
echo "" >&2

# Step 16: Execute container creation
step "Creating container..."
info "Executing: pct create $PVE_ID..."

# Execute the actual command (append password at execution time)
if eval "$CREATE_CMD --password \"$PASSWORD\""; then
    success "Container $PVE_ID created successfully"
else
    error "Failed to create container $PVE_ID"
    exit 1
fi

# Step 17: Start the container
step "Starting container..."
if pct start "$PVE_ID"; then
    success "Container $PVE_ID started successfully"
else
    warn "Container created but failed to start"
    exit 1
fi

# Step 18: Display completion message
success "Container creation complete!"
info "Container ID: $PVE_ID"
info "Hostname: $HOSTNAME"
info "IP: $IP_ADDRESS"
if [[ "$IP_MODE" == "static" ]]; then
    info "Gateway: $GATEWAY"
fi
info ""
info "You can access the container with:"
info "  pct enter $PVE_ID"

exit 0