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

# Step 4: Get Hostname
HOSTNAME=$(getHostname "lxc-debian")
debug_var HOSTNAME

# Step 5: Get CPU Cores
CPU_CORES=$(getCpuCores "2")
debug_var CPU_CORES

# Step 6: Get Memory
MEMORY=$(getMemory "2048")
debug_var MEMORY

# Step 7: Get Swap (default to 50% of memory)
SWAP_DEFAULT=$((MEMORY / 2))
SWAP=$(getSwap "$SWAP_DEFAULT")
debug_var SWAP

# Step 8: Get Root Filesystem Size
ROOTFS_SIZE=$(getRootfsSize "16")
debug_var ROOTFS_SIZE

# Step 9: Get Network Bridge
BRIDGE=$(getNetworkBridge "vmbr0")
debug_var BRIDGE

# Step 10: Get VLAN (default derived from ID: digits before last 3)
VLAN_DEFAULT=$((PVE_ID / 1000))
[[ "$VLAN_DEFAULT" -eq 0 ]] && VLAN_DEFAULT=1
VLAN=$(getVlanTag "$VLAN_DEFAULT")
debug_var VLAN

# Step 11: Get IP Configuration
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

# Step 12: Confirm configuration
step "Review Configuration"
CONFIRM_MSG="Please review the container configuration:


ID: $PVE_ID
Hostname: $HOSTNAME
Template: $TEMPLATE
Privileged: $([ "$UNPRIVILEGED" -eq 0 ] && echo "Yes" || echo "No")
CPU Cores: $CPU_CORES
Memory: ${MEMORY}MB
Swap: ${SWAP}MB
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

# TODO: Implement remaining container creation steps

exit 0

# =============================================================================
# COMMENTED OUT - Original Implementation
# =============================================================================
: <<'COMMENTED'

# Set defaults for Debian LXC
VAR_PVE_ID="$DEFAULT_PVE_ID"
VAR_HOSTNAME="lxc-debian"
VAR_PASSWORD="$DEFAULT_PASSWORD"
VAR_OS="$DEFAULT_OS"
VAR_OS_VERSION="$DEFAULT_OS_VERSION"
VAR_CPU="$DEFAULT_CPU"
VAR_RAM="$DEFAULT_RAM"
VAR_SWAP="$DEFAULT_SWAP"
VAR_STORAGE="$DEFAULT_STORAGE"
VAR_ROOTFS_SIZE="$DEFAULT_ROOTFS_SIZE"
VAR_BRIDGE="$DEFAULT_BRIDGE"
VAR_VLAN="$DEFAULT_VLAN"
VAR_IP="$DEFAULT_IP"
VAR_GATEWAY=""
VAR_UNPRIVILEGED="$DEFAULT_UNPRIVILEGED"
VAR_GPU_PASSTHROUGH="$DEFAULT_GPU_PASSTHROUGH"
VAR_OPTICAL_PASSTHROUGH="$DEFAULT_OPTICAL_PASSTHROUGH"
VAR_NFS="$DEFAULT_NFS"

SILENT_MODE=0

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    --silent                    Run in silent mode (no interactive prompts)
    --id <container_id>         Container ID (default: $DEFAULT_PVE_ID)
    --hostname <hostname>       Container hostname (default: lxc-debian)
    --password <password>       Root password (default: $DEFAULT_PASSWORD)
    --version <version>         Debian version: 13, 12, or 11 (default: $DEFAULT_OS_VERSION)
    --cpu <cores>               CPU cores (default: $DEFAULT_CPU)
    --ram <mb>                  Memory in MB (default: $DEFAULT_RAM)
    --swap <mb>                 Swap in MB (default: $DEFAULT_SWAP)
    --storage <location>        Storage location (default: $DEFAULT_STORAGE)
    --rootfs <gb>               Root filesystem size in GB (default: $DEFAULT_ROOTFS_SIZE)
    --bridge <bridge>           Network bridge (default: $DEFAULT_BRIDGE)
    --vlan <tag>                VLAN tag (default: $DEFAULT_VLAN)
    --ip <address>              IP address or dhcp (default: $DEFAULT_IP)
    --gateway <address>         Gateway address for static IP
    --privileged <0|1>          Privileged container: 0=yes, 1=no (default: $DEFAULT_UNPRIVILEGED)
    --gpu <0|1>                 GPU passthrough: 0=no, 1=yes (default: $DEFAULT_GPU_PASSTHROUGH)
    --optical <0|1>             Optical passthrough: 0=no, 1=yes (default: $DEFAULT_OPTICAL_PASSTHROUGH)
    --nfs <0|1>                 NFS support: 0=no, 1=yes (default: $DEFAULT_NFS)
    --help                      Show this help message

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --silent) SILENT_MODE=1; shift ;;
        --id) VAR_PVE_ID="$2"; shift 2 ;;
        --hostname) VAR_HOSTNAME="$2"; shift 2 ;;
        --password) VAR_PASSWORD="$2"; shift 2 ;;
        --version) VAR_OS_VERSION="$2"; shift 2 ;;
        --cpu) VAR_CPU="$2"; shift 2 ;;
        --ram) VAR_RAM="$2"; shift 2 ;;
        --swap) VAR_SWAP="$2"; shift 2 ;;
        --storage) VAR_STORAGE="$2"; shift 2 ;;
        --rootfs) VAR_ROOTFS_SIZE="$2"; shift 2 ;;
        --bridge) VAR_BRIDGE="$2"; shift 2 ;;
        --vlan) VAR_VLAN="$2"; shift 2 ;;
        --ip) VAR_IP="$2"; shift 2 ;;
        --gateway) VAR_GATEWAY="$2"; shift 2 ;;
        --privileged) VAR_UNPRIVILEGED="$2"; shift 2 ;;
        --gpu) VAR_GPU_PASSTHROUGH="$2"; shift 2 ;;
        --optical) VAR_OPTICAL_PASSTHROUGH="$2"; shift 2 ;;
        --nfs) VAR_NFS="$2"; shift 2 ;;
        --help) show_usage ;;
        *) echo "Unknown option: $1"; show_usage ;;
    esac
done

# Interactive mode - collect configuration via prompts
if [ "$SILENT_MODE" -eq 0 ]; then
    setPromptTitle "Debian LXC Container Setup"
    
    VAR_PVE_ID=$(getContainerId "$VAR_PVE_ID")
    VAR_HOSTNAME=$(getHostname "$VAR_HOSTNAME")
    VAR_PASSWORD=$(getPassword "$VAR_PASSWORD")
    VAR_OS_VERSION=$(getDebianVersion "$VAR_OS_VERSION")
    VAR_CPU=$(getCpuCores "$VAR_CPU")
    VAR_RAM=$(getMemory "$VAR_RAM")
    VAR_SWAP=$(getSwap "$VAR_SWAP")
    VAR_STORAGE=$(getStorage "$VAR_STORAGE")
    VAR_ROOTFS_SIZE=$(getRootfsSize "$VAR_ROOTFS_SIZE")
    VAR_BRIDGE=$(getNetworkBridge "$VAR_BRIDGE")
    VAR_VLAN=$(getVlanTag "$VAR_VLAN")
    
    VAR_IP_MODE=$(getIpMode)
    if [ "$VAR_IP_MODE" = "static" ]; then
        VAR_IP=$(getStaticIp)
        VAR_GATEWAY=$(getGateway)
    else
        VAR_IP="dhcp"
    fi
    
    VAR_UNPRIVILEGED=$(getPrivileged)
    read VAR_GPU_PASSTHROUGH VAR_OPTICAL_PASSTHROUGH VAR_NFS <<< $(getPassthroughOptions)
    
    # Validate privileged requirements
    if [ "$VAR_GPU_PASSTHROUGH" -eq 1 ] && [ "$VAR_UNPRIVILEGED" -eq 1 ]; then
        showMessage "GPU passthrough requires privileged container.\nSwitching to privileged mode."
        VAR_UNPRIVILEGED=0
    fi
    if [ "$VAR_NFS" -eq 1 ] && [ "$VAR_UNPRIVILEGED" -eq 1 ]; then
        showMessage "NFS support requires privileged container.\nSwitching to privileged mode."
        VAR_UNPRIVILEGED=0
    fi
fi

# Print configuration summary
echo ""
echo "Configuration:"
echo "  Container ID: $VAR_PVE_ID"
echo "  Hostname: $VAR_HOSTNAME"
echo "  OS: debian-$VAR_OS_VERSION"
echo "  CPU: $VAR_CPU cores"
echo "  RAM: ${VAR_RAM}MB"
echo "  Swap: ${VAR_SWAP}MB"
echo "  Storage: ${VAR_ROOTFS_SIZE}GB on $VAR_STORAGE"
echo "  Network: $VAR_BRIDGE (VLAN $VAR_VLAN)"
echo "  IP: $VAR_IP"
[ -n "$VAR_GATEWAY" ] && echo "  Gateway: $VAR_GATEWAY"
echo "  Type: $([ $VAR_UNPRIVILEGED -eq 0 ] && echo 'Privileged' || echo 'Unprivileged')"
echo "  GPU: $([ $VAR_GPU_PASSTHROUGH -eq 1 ] && echo 'Yes' || echo 'No')"
echo "  Optical: $([ $VAR_OPTICAL_PASSTHROUGH -eq 1 ] && echo 'Yes' || echo 'No')"
echo "  NFS: $([ $VAR_NFS -eq 1 ] && echo 'Yes' || echo 'No')"
echo ""

# Check if container already exists
if idExists "$VAR_PVE_ID"; then
    echo "ERROR: Container/VM $VAR_PVE_ID already exists!"
    exit 1
fi

# Download template
echo "Downloading OS template..."
OS_IMAGE=$(downloadTemplate "$VAR_OS" "$VAR_OS_VERSION")
if [ -z "$OS_IMAGE" ]; then
    echo "ERROR: Failed to download template"
    exit 1
fi

# Build configurations
NET_CONFIG=$(buildNetConfig "$DEFAULT_NETWORK" "$VAR_BRIDGE" "$VAR_VLAN" "$VAR_IP" "$VAR_GATEWAY" "$DEFAULT_FIREWALL")
FEATURES=$(buildFeatures "$VAR_NFS")

echo "Network config: $NET_CONFIG"
echo "Features: $FEATURES"

# Create container
if ! createLxcContainer "$VAR_PVE_ID" "$OS_IMAGE" "$VAR_HOSTNAME" "$VAR_PASSWORD" \
    "$VAR_CPU" "$VAR_RAM" "$VAR_SWAP" "$VAR_STORAGE" "$VAR_ROOTFS_SIZE" \
    "$NET_CONFIG" "$FEATURES" "$VAR_UNPRIVILEGED"; then
    exit 1
fi

# Configure security for passthrough
if [ "$VAR_GPU_PASSTHROUGH" -eq 1 ] || [ "$VAR_OPTICAL_PASSTHROUGH" -eq 1 ]; then
    configureSecuritySettings "$VAR_PVE_ID"
fi

# Configure optical passthrough
if [ "$VAR_OPTICAL_PASSTHROUGH" -eq 1 ]; then
    configureOpticalPassthrough "$VAR_PVE_ID"
fi

# Start container
echo "Starting container..."
if ! pct start $VAR_PVE_ID; then
    echo "ERROR: Failed to start container"
    exit 1
fi

if ! waitForContainer "$VAR_PVE_ID" 30; then
    echo "ERROR: Container did not start in time"
    exit 1
fi

echo "Container running"

# Configure locale
configureLocale "$VAR_PVE_ID"

# Update packages
echo "Updating packages..."
pct exec $VAR_PVE_ID -- bash -c "apt update && apt upgrade -y"

# Install NFS if enabled
if [ "$VAR_NFS" -eq 1 ]; then
    installNfsClient "$VAR_PVE_ID"
fi

echo ""
echo "Debian LXC container $VAR_PVE_ID setup complete!"
COMMENTED
