#!/bin/bash

# PVE Shared Functions
# Source this file for common utility functions
# NOTE: config.sh must be sourced BEFORE this file

# Check if running on Proxmox
checkProxmox() {
    if ! command -v pct &> /dev/null; then
        echo "ERROR: This script must be run on a Proxmox VE host"
        exit 1
    fi
}

# Get available network bridges (excludes firewall bridges)
# Usage: getAvailableBridges
# Returns: newline-separated list of bridge names
getAvailableBridges() {
    ip -o link show type bridge 2>/dev/null | awk -F': ' '{print $2}' | grep '^vmbr' | sort
}

# Check if container/VM ID exists
idExists() {
    local id=$1
    pct status $id &>/dev/null || qm status $id &>/dev/null
}

# Get the next available PVE ID (highest current ID + 1)
# Usage: getNextPveId
# Returns: next available ID number
getNextPveId() {
    local max_id=99
    
    # Get highest container ID
    local max_ct=$(pct list 2>/dev/null | tail -n +2 | awk '{print $1}' | sort -n | tail -1)
    [[ -n "$max_ct" && "$max_ct" -gt "$max_id" ]] && max_id=$max_ct
    
    # Get highest VM ID
    local max_vm=$(qm list 2>/dev/null | tail -n +2 | awk '{print $1}' | sort -n | tail -1)
    [[ -n "$max_vm" && "$max_vm" -gt "$max_id" ]] && max_id=$max_vm
    
    echo $((max_id + 1))
}

# Check if template exists locally
# Usage: templateExists "debian-13-standard_13.0-1_amd64.tar.zst"
# Returns: 0 if exists, 1 if not
templateExists() {
    local template=$1
    pveam list local 2>/dev/null | grep -q "$template"
}

# Get template name for OS/version
# Usage: getTemplateName "debian" "13"
# Returns: template filename or empty if not found
getTemplateName() {
    local os=$1
    local version=$2
    
    # Update available templates list
    pveam update >/dev/null 2>&1
    
    # Find matching template
    pveam available --section system | grep -i "${os}-${version}" | awk '{print $2}' | head -1
}

# Ensure template is available (download if needed)
# Usage: ensureTemplate "debian" "13"
# Returns: template filename, exits on failure
ensureTemplate() {
    local os=$1
    local version=$2
    
    debug "Checking template for ${os}-${version}"
    
    # Get template name
    local template
    template=$(getTemplateName "$os" "$version")
    
    if [[ -z "$template" ]]; then
        error "Could not find template for ${os}-${version}"
        return 1
    fi
    
    debug "Template name: $template"
    
    # Check if already downloaded
    if templateExists "$template"; then
        debug "Template already exists locally"
        echo "$template"
        return 0
    fi
    
    # Download template
    info "Downloading template: $template"
    if pveam download local "$template"; then
        success "Template downloaded"
        echo "$template"
        return 0
    else
        error "Failed to download template"
        return 1
    fi
}

# Build network configuration string for LXC
buildNetConfig() {
    local network="${1:-$DEFAULT_NETWORK}"
    local bridge="${2:-$DEFAULT_BRIDGE}"
    local vlan="${3:-$DEFAULT_VLAN}"
    local ip="${4:-$DEFAULT_IP}"
    local gateway="$5"
    local firewall="${6:-$DEFAULT_FIREWALL}"
    
    local config="name=$network,bridge=$bridge,firewall=$firewall,type=veth"
    
    if [ "$vlan" != "0" ] && [ -n "$vlan" ]; then
        config="$config,tag=$vlan"
    fi
    
    if [ "$ip" = "dhcp" ]; then
        config="$config,ip=dhcp"
    else
        # Add /24 if no CIDR provided
        if [[ "$ip" != *"/"* ]]; then
            ip="$ip/24"
        fi
        config="$config,ip=$ip"
        if [ -n "$gateway" ]; then
            config="$config,gw=$gateway"
        fi
    fi
    
    echo "$config"
}

# Build features string for LXC
buildFeatures() {
    local nfs="${1:-0}"
    
    local features="nesting=1"
    if [ "$nfs" -eq 1 ]; then
        features="mount=nfs,$features"
    fi
    
    echo "$features"
}

# Configure locale in container
configureLocale() {
    local container_id=$1
    
    echo "Configuring locale in container $container_id..."
    pct exec $container_id -- bash -c "apt update && apt install -y locales"
    pct exec $container_id -- bash -c "sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen"
    pct exec $container_id -- bash -c "locale-gen en_US.UTF-8"
    pct exec $container_id -- bash -c "update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8"
    echo "Locale configured"
}

# Configure security settings for hardware passthrough
configureSecuritySettings() {
    local container_id=$1
    local conf_file="/etc/pve/lxc/${container_id}.conf"
    
    echo "Configuring container security settings..."
    
    local apparmor_line="lxc.apparmor.profile: unconfined"
    local cap_drop_line="lxc.cap.drop:"
    local autodev_line="lxc.autodev: 1"
    local mount_auto_line="lxc.mount.auto: sys:rw"
    
    grep -qxF "$apparmor_line" "$conf_file" || echo "$apparmor_line" >> "$conf_file"
    grep -qxF "$cap_drop_line" "$conf_file" || echo "$cap_drop_line" >> "$conf_file"
    grep -qxF "$autodev_line" "$conf_file" || echo "$autodev_line" >> "$conf_file"
    grep -qxF "$mount_auto_line" "$conf_file" || echo "$mount_auto_line" >> "$conf_file"

    echo "Security settings configured"
}

# Configure optical drive passthrough
configureOpticalPassthrough() {
    local container_id=$1
    local conf_file="/etc/pve/lxc/${container_id}.conf"
    
    echo "Configuring optical drive passthrough for container $container_id..."
    
    # Find optical drives using lsscsi
    if ! command -v lsscsi &> /dev/null; then
        echo "Installing lsscsi..."
        apt-get install -y lsscsi
    fi
    
    declare -A OPTICAL_DRIVES
    while read -r line; do
        SR_DEV="$(echo "$line" | grep -o '/dev/sr[0-9]*')"
        SG_DEV="$(echo "$line" | grep -o '/dev/sg[0-9]*')"
        [ -n "$SR_DEV" ] && OPTICAL_DRIVES["$SR_DEV"]="$SG_DEV"
    done < <(lsscsi -g | grep -i "cd/dvd")

    if [ ${#OPTICAL_DRIVES[@]} -eq 0 ]; then
        echo "No optical drives found"
        return 0
    fi
    
    echo "Found ${#OPTICAL_DRIVES[@]} optical drive(s)"

    for sr in "${!OPTICAL_DRIVES[@]}"; do
        local SR_TYPE=$(ls -l $sr | awk '{print substr($1,1,1)}')
        local SR_MAJ_MIN=$(ls -l $sr | awk '{gsub(/,/, ""); print $5":"$6}')
        local SG_TYPE=$(ls -l ${OPTICAL_DRIVES[$sr]} | awk '{print substr($1,1,1)}')
        local SG_MAJ_MIN=$(ls -l ${OPTICAL_DRIVES[$sr]} | awk '{gsub(/,/, ""); print $5":"$6}')

        local sr_device_line="lxc.cgroup2.devices.allow: $SR_TYPE $SR_MAJ_MIN rwm"
        local sr_mount_line="lxc.mount.entry: $sr dev/$(basename $sr) none bind,create=file,optional 0 0"
        local sg_device_line="lxc.cgroup2.devices.allow: $SG_TYPE $SG_MAJ_MIN rwm"
        local sg_mount_line="lxc.mount.entry: ${OPTICAL_DRIVES[$sr]} dev/$(basename ${OPTICAL_DRIVES[$sr]}) none bind,create=file,optional 0 0"
        
        grep -qxF "$sr_device_line" "$conf_file" || echo "$sr_device_line" >> "$conf_file"
        grep -qxF "$sr_mount_line" "$conf_file" || echo "$sr_mount_line" >> "$conf_file"
        grep -qxF "$sg_device_line" "$conf_file" || echo "$sg_device_line" >> "$conf_file"
        grep -qxF "$sg_mount_line" "$conf_file" || echo "$sg_mount_line" >> "$conf_file"
        
        echo "  Configured: $sr -> ${OPTICAL_DRIVES[$sr]}"
    done

    echo "Optical drive passthrough configured"
}

# Wait for container to be running
waitForContainer() {
    local container_id=$1
    local max_wait=${2:-30}
    local waited=0
    
    while [ $waited -lt $max_wait ]; do
        if pct status $container_id | grep -q "running"; then
            return 0
        fi
        sleep 1
        ((waited++))
    done
    
    return 1
}

# Get container IP address
getContainerIp() {
    local container_id=$1
    pct exec $container_id -- bash -c "hostname -I | awk '{print \$1}'" 2>/dev/null
}

# Install NFS client in container
installNfsClient() {
    local container_id=$1
    echo "Installing NFS client..."
    pct exec $container_id -- bash -c "apt install -y nfs-common"
    echo "NFS client installed"
}

# Create LXC container
# Usage: createLxcContainer id template hostname password cpu ram swap storage rootfs net_config features unprivileged
createLxcContainer() {
    local id=$1
    local template=$2
    local hostname=$3
    local password=$4
    local cpu=$5
    local ram=$6
    local swap=$7
    local storage=$8
    local rootfs=$9
    local net_config=${10}
    local features=${11}
    local unprivileged=${12}
    local arch="${13:-$DEFAULT_ARCH}"
    local ostype="${14:-$DEFAULT_OSTYPE}"
    
    echo "Creating container $id..."
    if ! pct create $id local:vztmpl/$template \
        --arch $arch \
        --cores $cpu \
        --memory $ram \
        --swap $swap \
        --hostname $hostname \
        --net0 "$net_config" \
        --storage $storage \
        --rootfs $storage:$rootfs \
        --password "$password" \
        --ostype $ostype \
        --features $features \
        --unprivileged $unprivileged \
        --start 0; then
        echo "ERROR: Failed to create container"
        return 1
    fi
    
    echo "Container $id created successfully"
    return 0
}
