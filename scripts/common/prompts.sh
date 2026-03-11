#!/bin/bash

# LXC Prompt Functions
# Source this script and use functions to get prompted values
#
# Usage:
#   source lxc-prompts.sh
#   VAR_CONTAINER_ID=$(getContainerId "900")
#   VAR_HOSTNAME=$(getHostname "lxc-debian")

# Ensure whiptail is available
ensureWhiptail() {
    if ! command -v whiptail &> /dev/null; then
        apt-get update && apt-get install -y whiptail >&2
    fi
}

# Set the dialog title (call before using prompts)
PROMPT_TITLE="${PROMPT_TITLE:-LXC Container Setup}"

setPromptTitle() {
    PROMPT_TITLE="$1"
}

# Get Container ID
# Usage: VAR_ID=$(getContainerId "default_value")
getContainerId() {
    local default="${1:-900}"
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --inputbox "Container ID:" 8 60 "$default" 3>&1 1>&2 2>&3) || exit 1
    echo "$result"
}

# Get Hostname
# Usage: VAR_HOSTNAME=$(getHostname "default_value")
getHostname() {
    local default="${1:-lxc-debian}"
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --inputbox "Hostname:" 8 60 "$default" 3>&1 1>&2 2>&3) || exit 1
    echo "$result"
}

# Get Password with confirmation
# Usage: VAR_PASSWORD=$(getPassword "default_value")
getPassword() {
    local default="${1:-changeme}"
    ensureWhiptail
    local password password_confirm
    
    while true; do
        password=$(whiptail --title "$PROMPT_TITLE" --passwordbox "Root Password:" 8 60 3>&1 1>&2 2>&3) || exit 1
        password_confirm=$(whiptail --title "$PROMPT_TITLE" --passwordbox "Confirm Root Password:" 8 60 3>&1 1>&2 2>&3) || exit 1
        
        if [ -z "$password" ] && [ -z "$password_confirm" ]; then
            echo "$default"
            return
        elif [ "$password" = "$password_confirm" ]; then
            echo "$password"
            return
        else
            whiptail --title "$PROMPT_TITLE" --msgbox "Passwords do not match. Please try again." 8 60
        fi
    done
}

# Get Debian Version
# Usage: VAR_VERSION=$(getDebianVersion "13")
getDebianVersion() {
    local default="${1:-13}"
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --menu "Select Debian Version:" 12 60 3 \
        "13" "Debian 13 (Trixie)" \
        "12" "Debian 12 (Bookworm)" \
        "11" "Debian 11 (Bullseye)" \
        3>&1 1>&2 2>&3)
    [ -z "$result" ] && result="$default"
    echo "$result"
}

# Get CPU Cores
# Usage: VAR_CPU=$(getCpuCores "4")
getCpuCores() {
    local default="${1:-4}"
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --inputbox "CPU Cores:" 8 60 "$default" 3>&1 1>&2 2>&3) || exit 1
    echo "$result"
}

# Get Memory (MB)
# Usage: VAR_RAM=$(getMemory "4096")
getMemory() {
    local default="${1:-4096}"
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --inputbox "Memory (MB):" 8 60 "$default" 3>&1 1>&2 2>&3) || exit 1
    echo "$result"
}

# Get Swap (MB)
# Usage: VAR_SWAP=$(getSwap "1024")
getSwap() {
    local default="${1:-1024}"
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --inputbox "Swap (MB):" 8 60 "$default" 3>&1 1>&2 2>&3) || exit 1
    echo "$result"
}

# Get Storage Location
# Usage: VAR_STORAGE=$(getStorage "local-lvm")
getStorage() {
    local default="${1:-local-lvm}"
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --inputbox "Storage Location:" 8 60 "$default" 3>&1 1>&2 2>&3) || exit 1
    echo "$result"
}

# Get Root Filesystem Size (GB)
# Usage: VAR_ROOTFS=$(getRootfsSize "32")
getRootfsSize() {
    local default="${1:-32}"
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --inputbox "Root Filesystem Size (GB):" 8 60 "$default" 3>&1 1>&2 2>&3) || exit 1
    echo "$result"
}

# Get Network Bridge
# Usage: VAR_BRIDGE=$(getNetworkBridge "vmbr0")
getNetworkBridge() {
    local default="${1:-vmbr0}"
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --inputbox "Network Bridge:" 8 60 "$default" 3>&1 1>&2 2>&3) || exit 1
    echo "$result"
}

# Get VLAN Tag
# Usage: VAR_VLAN=$(getVlanTag "5")
getVlanTag() {
    local default="${1:-5}"
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --inputbox "VLAN Tag (0 for none):" 8 60 "$default" 3>&1 1>&2 2>&3) || exit 1
    echo "$result"
}

# Get IP Mode (dhcp or static)
# Usage: VAR_IP_MODE=$(getIpMode)
# Returns: "dhcp" or "static"
getIpMode() {
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --menu "IP Configuration:" 12 60 2 \
        "dhcp" "Automatic IP via DHCP" \
        "static" "Static IP Address" \
        3>&1 1>&2 2>&3)
    [ -z "$result" ] && result="dhcp"
    echo "$result"
}

# Get Static IP Address
# Usage: VAR_IP=$(getStaticIp)
getStaticIp() {
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --inputbox "Static IP Address (CIDR format, e.g. 192.168.1.100/24):" 8 70 "" 3>&1 1>&2 2>&3) || exit 1
    echo "$result"
}

# Get Gateway Address
# Usage: VAR_GATEWAY=$(getGateway)
getGateway() {
    ensureWhiptail
    local result
    result=$(whiptail --title "$PROMPT_TITLE" --inputbox "Gateway Address (e.g. 192.168.1.1):" 8 60 "" 3>&1 1>&2 2>&3) || exit 1
    echo "$result"
}

# Get Privileged Container selection
# Usage: VAR_UNPRIVILEGED=$(getPrivileged)
# Returns: 0 for privileged, 1 for unprivileged
getPrivileged() {
    ensureWhiptail
    if whiptail --title "$PROMPT_TITLE" --yesno "Create as Privileged Container?\n\nPrivileged containers have full access to host resources.\nRequired for GPU passthrough and NFS mounts.\n\nSelect Yes for privileged, No for unprivileged." 12 60; then
        echo "0"
    else
        echo "1"
    fi
}

# Get Passthrough Options
# Usage: read GPU OPTICAL NFS <<< $(getPassthroughOptions)
# Returns: space-separated "1 1 0" for GPU=on, OPTICAL=on, NFS=off
getPassthroughOptions() {
    ensureWhiptail
    local options
    options=$(whiptail --title "$PROMPT_TITLE" --checklist "Select Passthrough Options:" 14 60 3 \
        "GPU" "NVIDIA GPU Passthrough" ON \
        "OPTICAL" "Optical Drive Passthrough" ON \
        "NFS" "NFS Client Support" OFF \
        3>&1 1>&2 2>&3) || exit 1

    local gpu=0 optical=0 nfs=0
    [[ "$options" == *"GPU"* ]] && gpu=1
    [[ "$options" == *"OPTICAL"* ]] && optical=1
    [[ "$options" == *"NFS"* ]] && nfs=1
    
    echo "$gpu $optical $nfs"
}

# Show Yes/No confirmation
# Usage: if confirmDialog "Proceed with setup?"; then ...
confirmDialog() {
    local message="$1"
    ensureWhiptail
    whiptail --title "$PROMPT_TITLE" --yesno "$message" 10 60
}

# Show message box
# Usage: showMessage "Setup complete!"
showMessage() {
    local message="$1"
    ensureWhiptail
    whiptail --title "$PROMPT_TITLE" --msgbox "$message" 10 60
}
