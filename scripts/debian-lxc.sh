#!/bin/bash

# Parse command-line arguments for silent mode
SILENT_MODE=0

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    --silent                    Run in silent mode (no interactive prompts)
    --id <container_id>         Container ID (default: 900)
    --hostname <hostname>       Container hostname (default: lxc-debian-900)
    --password <password>       Root password (default: changeme)
    --version <version>         Debian version: 13, 12, or 11 (default: 13)
    --cpu <cores>               CPU cores (default: 4)
    --ram <mb>                  Memory in MB (default: 4096)
    --swap <mb>                 Swap in MB (default: 1024)
    --storage <location>        Storage location (default: local-lvm)
    --rootfs <gb>               Root filesystem size in GB (default: 32)
    --bridge <bridge>           Network bridge (default: vmbr0)
    --vlan <tag>                VLAN tag (default: 5)
    --ip <address>              IP address or dhcp (default: dhcp)
    --gateway <address>         Gateway address for static IP (e.g., 192.168.1.1)
    --privileged <0|1>          Privileged container: 0=yes, 1=no (default: 0)
    --gpu <0|1>                 GPU passthrough: 0=no, 1=yes (default: 1)
    --optical <0|1>             Optical passthrough: 0=no, 1=yes (default: 1)
    --help                      Show this help message

EXAMPLES:
    # Interactive mode (default)
    $0

    # Silent mode with defaults
    $0 --silent

    # Silent mode with custom values
    $0 --silent --id 901 --hostname lxc-debian-901 --password mypass --gpu 0

EOF
    exit 0
}

# Set defaults
VAR_PVE_ID="900"
VAR_HOSTNAME="lxc-debian-900"
VAR_PASSWORD="changeme"
VAR_OS="debian"
VAR_OS_VERSION="13"
VAR_OSTYPE="debian"
VAR_ARCH="amd64"
VAR_CPU="4"
VAR_RAM="4096"
VAR_SWAP="1024"
VAR_STORAGE="local-lvm"
VAR_ROOTFS_SIZE="32"
VAR_NETWORK="eth0"
VAR_TYPE="veth"
VAR_BRIDGE="vmbr0"
VAR_VLAN="5"
VAR_IP="dhcp"
VAR_GATEWAY=""
VAR_FIREWALL=1
VAR_UNPRIVILEGED=0
VAR_GPU_PASSTHROUGH=1
VAR_OPTICAL_PASSTHROUGH=1
VAR_START=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --silent)
            SILENT_MODE=1
            shift
            ;;
        --id)
            VAR_PVE_ID="$2"
            shift 2
            ;;
        --hostname)
            VAR_HOSTNAME="$2"
            shift 2
            ;;
        --password)
            VAR_PASSWORD="$2"
            shift 2
            ;;
        --version)
            VAR_OS_VERSION="$2"
            shift 2
            ;;
        --cpu)
            VAR_CPU="$2"
            shift 2
            ;;
        --ram)
            VAR_RAM="$2"
            shift 2
            ;;
        --swap)
            VAR_SWAP="$2"
            shift 2
            ;;
        --storage)
            VAR_STORAGE="$2"
            shift 2
            ;;
        --rootfs)
            VAR_ROOTFS_SIZE="$2"
            shift 2
            ;;
        --bridge)
            VAR_BRIDGE="$2"
            shift 2
            ;;
        --vlan)
            VAR_VLAN="$2"
            shift 2
            ;;
        --ip)
            VAR_IP="$2"
            shift 2
            ;;
        --gateway)
            VAR_GATEWAY="$2"
            shift 2
            ;;
        --privileged)
            VAR_UNPRIVILEGED="$2"
            shift 2
            ;;
        --gpu)
            VAR_GPU_PASSTHROUGH="$2"
            shift 2
            ;;
        --optical)
            VAR_OPTICAL_PASSTHROUGH="$2"
            shift 2
            ;;
        --help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Interactive mode
if [ "$SILENT_MODE" -eq 0 ]; then
    # Check for whiptail
    if ! command -v whiptail &> /dev/null; then
        echo "Installing whiptail..."
        apt-get update && apt-get install -y whiptail
    fi

    TITLE="LXC Debian Container Setup"

    # Container Settings
    VAR_PVE_ID=$(whiptail --title "$TITLE" --inputbox "Container ID:" 8 60 "$VAR_PVE_ID" 3>&1 1>&2 2>&3) || exit 1
    VAR_HOSTNAME=$(whiptail --title "$TITLE" --inputbox "Hostname:" 8 60 "$VAR_HOSTNAME" 3>&1 1>&2 2>&3) || exit 1
    # Password entry with confirmation
    while true; do
        VAR_PASSWORD=$(whiptail --title "$TITLE" --passwordbox "Root Password:" 8 60 3>&1 1>&2 2>&3) || exit 1
        VAR_PASSWORD_CONFIRM=$(whiptail --title "$TITLE" --passwordbox "Confirm Root Password:" 8 60 3>&1 1>&2 2>&3) || exit 1
        
        if [ -z "$VAR_PASSWORD" ] && [ -z "$VAR_PASSWORD_CONFIRM" ]; then
            VAR_PASSWORD="changeme"
            break
        elif [ "$VAR_PASSWORD" = "$VAR_PASSWORD_CONFIRM" ]; then
            break
        else
            whiptail --title "$TITLE" --msgbox "Passwords do not match. Please try again." 8 60
        fi
    done

    # Operating System Selection
    VAR_OS_VERSION=$(whiptail --title "$TITLE" --menu "Select Debian Version:" 12 60 3 \
        "13" "Debian 13 (Trixie)" \
        "12" "Debian 12 (Bookworm)" \
        "11" "Debian 11 (Bullseye)" \
        3>&1 1>&2 2>&3)
    # Default to Debian 13 if cancelled or no selection
    [ -z "$VAR_OS_VERSION" ] && VAR_OS_VERSION="13"

    # Hardware Resources
    VAR_CPU=$(whiptail --title "$TITLE" --inputbox "CPU Cores:" 8 60 "$VAR_CPU" 3>&1 1>&2 2>&3) || exit 1
    VAR_RAM=$(whiptail --title "$TITLE" --inputbox "Memory (MB):" 8 60 "$VAR_RAM" 3>&1 1>&2 2>&3) || exit 1
    VAR_SWAP=$(whiptail --title "$TITLE" --inputbox "Swap (MB):" 8 60 "$VAR_SWAP" 3>&1 1>&2 2>&3) || exit 1

    # Storage Settings
    VAR_STORAGE=$(whiptail --title "$TITLE" --inputbox "Storage Location:" 8 60 "$VAR_STORAGE" 3>&1 1>&2 2>&3) || exit 1
    VAR_ROOTFS_SIZE=$(whiptail --title "$TITLE" --inputbox "Root Filesystem Size (GB):" 8 60 "$VAR_ROOTFS_SIZE" 3>&1 1>&2 2>&3) || exit 1

    # Network Settings
    VAR_BRIDGE=$(whiptail --title "$TITLE" --inputbox "Network Bridge:" 8 60 "$VAR_BRIDGE" 3>&1 1>&2 2>&3) || exit 1
    VAR_VLAN=$(whiptail --title "$TITLE" --inputbox "VLAN Tag (0 for none):" 8 60 "$VAR_VLAN" 3>&1 1>&2 2>&3) || exit 1
    # IP Configuration - DHCP or Static selection
    IP_MODE=$(whiptail --title "$TITLE" --menu "IP Configuration:" 12 60 2 \
        "dhcp" "Automatic IP via DHCP" \
        "static" "Static IP Address" \
        3>&1 1>&2 2>&3)
    [ -z "$IP_MODE" ] && IP_MODE="dhcp"

    if [ "$IP_MODE" = "static" ]; then
        VAR_IP=$(whiptail --title "$TITLE" --inputbox "Static IP Address (CIDR format, e.g. 192.168.1.100/24):" 8 70 "" 3>&1 1>&2 2>&3) || exit 1
        VAR_GATEWAY=$(whiptail --title "$TITLE" --inputbox "Gateway Address (e.g. 192.168.1.1):" 8 60 "" 3>&1 1>&2 2>&3) || exit 1
    else
        VAR_IP="dhcp"
    fi

    # Container Type
    if whiptail --title "$TITLE" --yesno "Create as Privileged Container?\n\nPrivileged containers have full access to host resources.\nRequired for GPU passthrough.\n\nSelect Yes for privileged, No for unprivileged." 12 60; then
        VAR_UNPRIVILEGED=0
    else
        VAR_UNPRIVILEGED=1
    fi

    # Passthrough Options
    PASSTHROUGH_OPTIONS=$(whiptail --title "$TITLE" --checklist "Select Passthrough Options:" 12 60 2 \
        "GPU" "NVIDIA GPU Passthrough" ON \
        "OPTICAL" "Optical Drive Passthrough" ON \
        3>&1 1>&2 2>&3) || exit 1

    VAR_GPU_PASSTHROUGH=0
    VAR_OPTICAL_PASSTHROUGH=0
    [[ "$PASSTHROUGH_OPTIONS" == *"GPU"* ]] && VAR_GPU_PASSTHROUGH=1
    [[ "$PASSTHROUGH_OPTIONS" == *"OPTICAL"* ]] && VAR_OPTICAL_PASSTHROUGH=1

    # Validate privileged requirement for GPU passthrough
    if [ "$VAR_GPU_PASSTHROUGH" -eq 1 ] && [ "$VAR_UNPRIVILEGED" -eq 1 ]; then
        whiptail --title "$TITLE" --msgbox "Warning: GPU passthrough requires a privileged container.\nSwitching to privileged mode." 10 60
        VAR_UNPRIVILEGED=0
    fi

    # Display summary and confirm
    SUMMARY="Container ID: $VAR_PVE_ID
Hostname: $VAR_HOSTNAME
OS: $VAR_OS-$VAR_OS_VERSION
CPU Cores: $VAR_CPU
Memory: ${VAR_RAM}MB
Swap: ${VAR_SWAP}MB
Storage: ${VAR_ROOTFS_SIZE}GB on $VAR_STORAGE
Network: $VAR_BRIDGE (VLAN $VAR_VLAN)
IP: $VAR_IP$([ -n "$VAR_GATEWAY" ] && echo " (Gateway: $VAR_GATEWAY)")
Container Type: $([ $VAR_UNPRIVILEGED -eq 0 ] && echo 'Privileged' || echo 'Unprivileged')
GPU Passthrough: $([ $VAR_GPU_PASSTHROUGH -eq 1 ] && echo 'Yes' || echo 'No')
Optical Passthrough: $([ $VAR_OPTICAL_PASSTHROUGH -eq 1 ] && echo 'Yes' || echo 'No')"

    if ! whiptail --title "$TITLE" --yesno "Configuration Summary:\n\n$SUMMARY\n\nProceed with this configuration?" 20 60; then
        echo "Configuration cancelled."
        exit 0
    fi

    clear
fi

# Silent mode summary
if [ "$SILENT_MODE" -eq 1 ]; then
    echo "Running in silent mode with the following configuration:"
    echo "  Container ID: $VAR_PVE_ID"
    echo "  Hostname: $VAR_HOSTNAME"
    echo "  OS: $VAR_OS-$VAR_OS_VERSION"
    echo "  CPU Cores: $VAR_CPU"
    echo "  Memory: ${VAR_RAM}MB"
    echo "  Swap: ${VAR_SWAP}MB"
    echo "  Storage: ${VAR_ROOTFS_SIZE}GB on $VAR_STORAGE"
    echo "  Network: $VAR_BRIDGE (VLAN $VAR_VLAN)"
    echo "  IP: $VAR_IP"
    [ -n "$VAR_GATEWAY" ] && echo "  Gateway: $VAR_GATEWAY"
    echo "  Container Type: $([ $VAR_UNPRIVILEGED -eq 0 ] && echo 'Privileged' || echo 'Unprivileged')"
    echo "  GPU Passthrough: $([ $VAR_GPU_PASSTHROUGH -eq 1 ] && echo 'Yes' || echo 'No')"
    echo "  Optical Passthrough: $([ $VAR_OPTICAL_PASSTHROUGH -eq 1 ] && echo 'Yes' || echo 'No')"
    echo ""
fi

echo "Starting container creation..."
echo ""

# Check if container already exists
if pct status $VAR_PVE_ID &>/dev/null; then
    echo "ERROR: Container $VAR_PVE_ID already exists!"
    echo "Please destroy it first with: pct destroy $VAR_PVE_ID"
    exit 1
fi

pveam update

# List available templates and storage locations
pveam available --section system

# Extract OS image name
pveam available --section system | grep -i "${VAR_OS}-${VAR_OS_VERSION}" 

# Set the image name variable dynamically
OS_IMAGE=$(pveam available --section system | grep -i "${VAR_OS}-${VAR_OS_VERSION}" | awk '{print $2}')

if [ -z "$OS_IMAGE" ]; then
    echo "ERROR: Could not find OS template for ${VAR_OS}-${VAR_OS_VERSION}"
    exit 1
fi

echo "Using OS template: $OS_IMAGE"

# Download the OS template
pveam download local $OS_IMAGE

# Build network configuration string
NET_CONFIG="name=$VAR_NETWORK,bridge=$VAR_BRIDGE,firewall=$VAR_FIREWALL,type=$VAR_TYPE"

# Add VLAN tag if specified and not 0
if [ "$VAR_VLAN" != "0" ] && [ -n "$VAR_VLAN" ]; then
    NET_CONFIG="$NET_CONFIG,tag=$VAR_VLAN"
fi

# Handle IP configuration (dhcp vs static)
if [ "$VAR_IP" = "dhcp" ]; then
    NET_CONFIG="$NET_CONFIG,ip=dhcp"
else
    # Static IP - user should provide in CIDR format (e.g., 192.168.1.100/24)
    # If no subnet mask provided, assume /24
    if [[ "$VAR_IP" != *"/"* ]]; then
        VAR_IP="$VAR_IP/24"
    fi
    NET_CONFIG="$NET_CONFIG,ip=$VAR_IP"
    
    # Add gateway if provided
    if [ -n "$VAR_GATEWAY" ]; then
        NET_CONFIG="$NET_CONFIG,gw=$VAR_GATEWAY"
    fi
fi

echo "Network configuration: $NET_CONFIG"

# Create the container
echo "Creating container $VAR_PVE_ID..."
if ! pct create $VAR_PVE_ID local:vztmpl/$OS_IMAGE \
 --arch $VAR_ARCH \
 --cores $VAR_CPU \
 --memory $VAR_RAM \
 --swap $VAR_SWAP \
 --hostname $VAR_HOSTNAME \
 --net0 "$NET_CONFIG" \
 --storage $VAR_STORAGE \
 --rootfs $VAR_STORAGE:$VAR_ROOTFS_SIZE \
 --password "$VAR_PASSWORD" \
 --ostype $VAR_OSTYPE \
 --features nesting=1 \
 --unprivileged $VAR_UNPRIVILEGED \
 --start 0; then
    echo "ERROR: Failed to create container $VAR_PVE_ID"
    exit 1
fi

echo "Container $VAR_PVE_ID created successfully"

configure_security_settings() {
    local container_id=$1
    local conf_file="/etc/pve/lxc/${container_id}.conf"
    
    # - unconfined: Disables AppArmor restrictions for hardware access
    # - cap.drop: Empty value retains all Linux capabilities
    # - mount.auto sys:rw: Allows read-write access to /sys for device management
    # - autodev: Automatically populate /dev with devices
    echo "Configuring container security settings for hardware passthrough..."
    
    local apparmor_line="lxc.apparmor.profile: unconfined"
    local cap_drop_line="lxc.cap.drop:"
    local autodev_line="lxc.autodev: 1"
    local mount_auto_line="lxc.mount.auto: sys:rw"
    
    grep -qxF "$apparmor_line" "$conf_file" || echo "$apparmor_line" >> "$conf_file"
    grep -qxF "$cap_drop_line" "$conf_file" || echo "$cap_drop_line" >> "$conf_file"
    grep -qxF "$autodev_line" "$conf_file" || echo "$autodev_line" >> "$conf_file"
    grep -qxF "$mount_auto_line" "$conf_file" || echo "$mount_auto_line" >> "$conf_file"

    echo "Container security settings configured"
}

configure_optical_passthrough() {
    local container_id=$1
    local conf_file="/etc/pve/lxc/${container_id}.conf"
    
    echo "Configuring optical drive passthrough for container $container_id"
    echo "Configuration file: $conf_file"
    
    # Find optical drives and their corresponding sg devices
    declare -A OPTICAL_DRIVES
    while read -r line; do
        SR_DEV="$(echo "$line" | grep -o '/dev/sr[0-9]*')"
        SG_DEV="$(echo "$line" | grep -o '/dev/sg[0-9]*')"
        OPTICAL_DRIVES["$SR_DEV"]="$SG_DEV"
    done < <(lsscsi -g | grep -i "cd/dvd")

    # Display the device pairs
    echo "Found ${#OPTICAL_DRIVES[@]} optical drive(s)"
    echo "Optical drive mappings:"
    for sr in "${!OPTICAL_DRIVES[@]}"; do
        echo "  $sr -> ${OPTICAL_DRIVES[$sr]}"
    done

    # Configure optical drive passthrough
    for sr in "${!OPTICAL_DRIVES[@]}"; do
        echo "Configuring passthrough for $sr..."
        
        # Get device type and major:minor for sr device
        SR_TYPE=$(ls -l $sr | awk '{print substr($1,1,1)}')
        SR_MAJ_MIN=$(ls -l $sr | awk '{gsub(/,/, ""); print $5":"$6}')
        echo "  SR device: type=$SR_TYPE, major:minor=$SR_MAJ_MIN"
        
        # Get device type and major:minor for sg device
        SG_TYPE=$(ls -l ${OPTICAL_DRIVES[$sr]} | awk '{print substr($1,1,1)}')
        SG_MAJ_MIN=$(ls -l ${OPTICAL_DRIVES[$sr]} | awk '{gsub(/,/, ""); print $5":"$6}')
        echo "  SG device: type=$SG_TYPE, major:minor=$SG_MAJ_MIN"

        # Add configuration lines only if they don't already exist
        local sr_device_line="lxc.cgroup2.devices.allow: $SR_TYPE $SR_MAJ_MIN rwm"
        local sr_mount_line="lxc.mount.entry: $sr dev/$(basename $sr) none bind,create=file,optional 0 0"
        local sg_device_line="lxc.cgroup2.devices.allow: $SG_TYPE $SG_MAJ_MIN rwm"
        local sg_mount_line="lxc.mount.entry: ${OPTICAL_DRIVES[$sr]} dev/$(basename ${OPTICAL_DRIVES[$sr]}) none bind,create=file,optional 0 0"
        
        if grep -qxF "$sr_device_line" "$conf_file"; then
            echo "  SR device permission already configured"
        else
            echo "  Adding SR device permission"
            echo "$sr_device_line" >> "$conf_file"
        fi
        
        if grep -qxF "$sr_mount_line" "$conf_file"; then
            echo "  SR mount entry already exists"
        else
            echo "  Adding SR mount entry"
            echo "$sr_mount_line" >> "$conf_file"
        fi
        
        if grep -qxF "$sg_device_line" "$conf_file"; then
            echo "  SG device permission already configured"
        else
            echo "  Adding SG device permission"
            echo "$sg_device_line" >> "$conf_file"
        fi
        
        if grep -qxF "$sg_mount_line" "$conf_file"; then
            echo "  SG mount entry already exists"
        else
            echo "  Adding SG mount entry"
            echo "$sg_mount_line" >> "$conf_file"
        fi
    done

    echo "Optical drive passthrough configured"
}

configure_nvidia_gpu_passthrough() {
    local container_id=$1
    local conf_file="/etc/pve/lxc/${container_id}.conf"
    
    echo "Configuring NVIDIA GPU passthrough for container $container_id"
    echo "Configuration file: $conf_file"
    
    # Extract unique major device numbers from NVIDIA devices
    NVIDIA_MAJOR_NUMS=($(ls -l /dev/nvidia* /dev/nvidia-caps/* 2>/dev/null | grep "^c" | awk '{print $5}' | sed 's/,//' | sort -u))
    
    echo "Found ${#NVIDIA_MAJOR_NUMS[@]} unique NVIDIA device major numbers: ${NVIDIA_MAJOR_NUMS[*]}"
    
    # Add GPU passthrough configuration to LXC conf file
    for major in "${NVIDIA_MAJOR_NUMS[@]}"; do
        local device_line="lxc.cgroup2.devices.allow: c $major:* rwm"
        if grep -qxF "$device_line" "$conf_file"; then
            echo "  Device major $major already configured"
        else
            echo "  Adding device major $major"
            echo "$device_line" >> "$conf_file"
        fi
    done
    
    # Extract unique major device numbers from DRI devices (for VA-API support)
    echo "Scanning for DRI devices in /dev/dri/..."
    if [ -d "/dev/dri" ]; then
        DRI_MAJOR_NUMS=($(ls -l /dev/dri/* 2>/dev/null | grep "^c" | awk '{print $5}' | sed 's/,//' | sort -u))
        
        echo "Found ${#DRI_MAJOR_NUMS[@]} unique DRI device major numbers: ${DRI_MAJOR_NUMS[*]}"
        
        # Add DRI cgroup permissions
        for major in "${DRI_MAJOR_NUMS[@]}"; do
            local device_line="lxc.cgroup2.devices.allow: c $major:* rwm"
            if grep -qxF "$device_line" "$conf_file"; then
                echo "  DRI device major $major already configured"
            else
                echo "  Adding DRI device major $major"
                echo "$device_line" >> "$conf_file"
            fi
        done
        
        # Add DRI directory mount
        local dri_dir_line="lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir"
        if grep -qxF "$dri_dir_line" "$conf_file"; then
            echo "  DRI directory mount already configured"
        else
            echo "  Adding DRI directory mount"
            echo "$dri_dir_line" >> "$conf_file"
        fi
        
        # Add individual DRI device mounts
        for device in $(ls -1 /dev/dri/* 2>/dev/null); do
            if [ -c "$device" ] || [ -b "$device" ]; then
                echo "  Found DRI device: $device"
                local mount_line="lxc.mount.entry: $device dev/dri/$(basename $device) none bind,optional,create=file"
                if grep -qxF "$mount_line" "$conf_file"; then
                    echo "    Already mounted"
                else
                    echo "    Adding mount entry"
                    echo "$mount_line" >> "$conf_file"
                fi
            fi
        done
    else
        echo "  /dev/dri directory not found, skipping DRI passthrough"
    fi
    
    # Dynamically detect and add device mount entries for NVIDIA devices
    # Get all NVIDIA devices in /dev (excluding directories)
    echo "Scanning for NVIDIA devices in /dev..."
    for device in $(ls -1 /dev/nvidia* 2>/dev/null | grep -v "/$"); do
        if [ -c "$device" ] || [ -b "$device" ]; then
            echo "  Found device: $device"
            local mount_line="lxc.mount.entry: $device dev/$(basename $device) none bind,optional,create=file"
            if grep -qxF "$mount_line" "$conf_file"; then
                echo "    Already mounted"
            else
                echo "    Adding mount entry"
                echo "$mount_line" >> "$conf_file"
            fi
        fi
    done
    
    # Get all NVIDIA cap devices
    echo "Scanning for NVIDIA capability devices..."
    for device in $(ls -1 /dev/nvidia-caps/* 2>/dev/null); do
        if [ -c "$device" ] || [ -b "$device" ]; then
            echo "  Found device: $device"
            local mount_line="lxc.mount.entry: $device dev/nvidia-caps/$(basename $device) none bind,optional,create=file"
            if grep -qxF "$mount_line" "$conf_file"; then
                echo "    Already mounted"
            else
                echo "    Adding mount entry"
                echo "$mount_line" >> "$conf_file"
            fi
        fi
    done
    
    echo "NVIDIA GPU passthrough configured"
}

install_nvidia_driver() {
    local container_id=$1
    
    # Check if nvidia-smi is available on the host
    if ! command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA driver not found on host, skipping driver installation"
        return 0
    fi
    
    echo "Installing NVIDIA driver in container..."
    
    # Get host NVIDIA driver version
    HOST_NVIDIA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | xargs)
    echo "Host NVIDIA driver version: $HOST_NVIDIA_VERSION"
    
    # Download NVIDIA driver installer to container
    echo "Downloading NVIDIA driver installer..."
    pct exec $container_id -- bash -c "wget https://us.download.nvidia.com/XFree86/Linux-x86_64/$HOST_NVIDIA_VERSION/NVIDIA-Linux-x86_64-$HOST_NVIDIA_VERSION.run -O /tmp/NVIDIA-Linux-x86_64-$HOST_NVIDIA_VERSION.run"
    
    # Make installer executable
    pct exec $container_id -- bash -c "chmod +x /tmp/NVIDIA-Linux-x86_64-$HOST_NVIDIA_VERSION.run"
    
    echo "NVIDIA driver installer downloaded to /tmp/NVIDIA-Linux-x86_64-$HOST_NVIDIA_VERSION.run"
    
    # Install NVIDIA driver in unattended mode
    echo "Installing NVIDIA driver (unattended)..."
    pct exec $container_id -- bash -c "/tmp/NVIDIA-Linux-x86_64-$HOST_NVIDIA_VERSION.run --no-kernel-module --silent --accept-license --no-questions > /tmp/nvidia-install.log 2>&1 || true"
    
    echo "NVIDIA driver binaries installed, restarting container to initialize GPU devices..."
    pct stop $container_id
    sleep 2
    pct start $container_id
    sleep 3
    
    # Check if installation was successful
    echo "Verifying NVIDIA driver installation..."
    if pct exec $container_id -- bash -c "nvidia-smi" 2>&1; then
        echo "NVIDIA driver installation complete and GPU is accessible"
    else
        echo "NVIDIA driver installation completed but GPU verification failed."
        echo "Check /tmp/nvidia-install.log in the container for details."
        echo "You may need to verify device passthrough configuration."
    fi

    # Install VA-API driver
    echo "Installing VA-API driver..."
    pct exec $container_id -- bash -c "apt install -y nvidia-vaapi-driver"
    pct exec $container_id -- bash -c "apt install -y vainfo"
}

configure_locale() {
    local container_id=$1
    
    echo "Configuring locale in container $container_id..."
    pct exec $container_id -- bash -c "apt update && apt install -y locales"
    pct exec $container_id -- bash -c "sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen"
    pct exec $container_id -- bash -c "locale-gen en_US.UTF-8"
    pct exec $container_id -- bash -c "update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8"
    echo "Locale configured"
}

# Configure container security and capabilities if hardware passthrough is enabled
if [ "$VAR_GPU_PASSTHROUGH" -eq 1 ] || [ "$VAR_OPTICAL_PASSTHROUGH" -eq 1 ]; then
    configure_security_settings "$VAR_PVE_ID"
else
    echo "Hardware passthrough disabled, skipping security configuration"
fi



if [ "$VAR_OPTICAL_PASSTHROUGH" -eq 1 ]; then
    configure_optical_passthrough "$VAR_PVE_ID"
fi

# Check if VAR_GPU_PASSTHROUGH is enabled
if [ "$VAR_GPU_PASSTHROUGH" -eq 1 ]; then
    echo "GPU passthrough enabled"
    # Check if GPU is nvidia
    if lspci | grep -i nvidia > /dev/null; then
        echo "NVIDIA GPU detected"
        configure_nvidia_gpu_passthrough "$VAR_PVE_ID"
    else
        echo "No NVIDIA GPU detected"
    fi
fi

# Display the final configuration
echo "Final container configuration:"
cat /etc/pve/lxc/$VAR_PVE_ID.conf

# Validate container configuration before starting
CONF_FILE="/etc/pve/lxc/$VAR_PVE_ID.conf"
echo ""
echo "Validating container configuration..."

# Check that essential settings exist in config
VALIDATION_FAILED=0

if ! grep -q "^arch:" "$CONF_FILE"; then
    echo "ERROR: Missing 'arch' in container configuration"
    VALIDATION_FAILED=1
fi

if ! grep -q "^cores:" "$CONF_FILE"; then
    echo "ERROR: Missing 'cores' in container configuration"
    VALIDATION_FAILED=1
fi

if ! grep -q "^memory:" "$CONF_FILE"; then
    echo "ERROR: Missing 'memory' in container configuration"
    VALIDATION_FAILED=1
fi

if ! grep -q "^rootfs:" "$CONF_FILE"; then
    echo "ERROR: Missing 'rootfs' in container configuration"
    VALIDATION_FAILED=1
fi

if ! grep -q "^net0:" "$CONF_FILE"; then
    echo "ERROR: Missing 'net0' in container configuration"
    VALIDATION_FAILED=1
fi

if [ "$VALIDATION_FAILED" -eq 1 ]; then
    echo ""
    echo "ERROR: Container configuration validation failed!"
    echo "The container was not created properly. Please check the errors above."
    echo "You may need to destroy the container and try again: pct destroy $VAR_PVE_ID"
    exit 1
fi

echo "Container configuration validated successfully"

# Start the container
echo ""
echo "Starting container $VAR_PVE_ID..."
if ! pct start $VAR_PVE_ID; then
    echo "ERROR: Failed to start container $VAR_PVE_ID"
    echo "Check the container configuration and Proxmox logs for details."
    echo "You can view logs with: journalctl -xe"
    exit 1
fi

# Wait for container to be fully running
echo "Waiting for container to initialize..."
sleep 5

# Verify container is running
if ! pct status $VAR_PVE_ID | grep -q "running"; then
    echo "ERROR: Container $VAR_PVE_ID is not running after start"
    echo "Container status: $(pct status $VAR_PVE_ID)"
    exit 1
fi

echo "Container $VAR_PVE_ID started successfully"

# Configure locale to prevent warnings
configure_locale "$VAR_PVE_ID"

# Update package lists
echo "Updating Package Lists..."
pct exec $VAR_PVE_ID -- bash -c "apt update && apt upgrade -y"

# Install NVIDIA driver if GPU passthrough is enabled and NVIDIA GPU is detected
if [ "$VAR_GPU_PASSTHROUGH" -eq 1 ]; then
    if lspci | grep -i nvidia > /dev/null; then
        install_nvidia_driver "$VAR_PVE_ID"
    fi
fi

echo ""
echo "Debian LXC container $VAR_PVE_ID setup complete!"
echo "Container is running and ready for use."
