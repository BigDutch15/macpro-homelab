#!/bin/bash

# Automatic Ripping Machine (ARM) Docker Container Setup
# This script prompts for container-specific settings and calls docker.sh with predefined ARM defaults

# Check for whiptail
if ! command -v whiptail &> /dev/null; then
    echo "Installing whiptail..."
    apt-get update && apt-get install -y whiptail
fi

# Function to wait for container to be running
wait_for_container() {
    local container_id=$1
    local timeout=${2:-60}
    local elapsed=0
    
    echo "Waiting for container $container_id to come online..."
    while ! pct status $container_id | grep -q "running"; do
        sleep 2
        elapsed=$((elapsed + 2))
        if [ $elapsed -ge $timeout ]; then
            echo "ERROR: Container $container_id did not come online within ${timeout}s"
            return 1
        fi
        echo "  Waiting... (${elapsed}s)"
    done
    echo "Container $container_id is running"
    return 0
}

# Function to validate NFS mount read/write access
validate_nfs_mount() {
    local container_id=$1
    local mount_path=$2
    local test_user=${3:-arm}
    
    echo "  Validating $mount_path..."
    
    # Check if mount point exists
    if ! pct exec $container_id -- bash -c "[ -d '$mount_path' ]" 2>/dev/null; then
        echo "    ERROR: Mount point $mount_path does not exist"
        return 1
    fi
    
    # Check if mount is actually mounted
    if ! pct exec $container_id -- bash -c "mountpoint -q '$mount_path'" 2>/dev/null; then
        echo "    WARNING: $mount_path is not a mounted filesystem"
    fi
    
    # Test write access
    if ! pct exec $container_id -- bash -c "sudo -u $test_user touch '$mount_path/test.txt'" 2>/dev/null; then
        echo "    ERROR: Cannot write to $mount_path as $test_user"
        return 1
    fi
    
    # Test delete access
    if ! pct exec $container_id -- bash -c "sudo -u $test_user rm '$mount_path/test.txt'" 2>/dev/null; then
        echo "    ERROR: Cannot delete from $mount_path as $test_user"
        return 1
    fi
    
    echo "    OK"
    return 0
}

TITLE="ARM Docker Container Setup"

# Prompt for container-specific settings
CONTAINER_ID=$(whiptail --title "$TITLE" --inputbox "Container ID:" 8 60 "910" 3>&1 1>&2 2>&3) || exit 1
CONTAINER_HOSTNAME=$(whiptail --title "$TITLE" --inputbox "Hostname:" 8 60 "lxc-arm" 3>&1 1>&2 2>&3) || exit 1

# Password entry with confirmation
while true; do
    CONTAINER_PASSWORD=$(whiptail --title "$TITLE" --passwordbox "Root Password:" 8 60 3>&1 1>&2 2>&3) || exit 1
    PASSWORD_CONFIRM=$(whiptail --title "$TITLE" --passwordbox "Confirm Root Password:" 8 60 3>&1 1>&2 2>&3) || exit 1
    
    if [ -z "$CONTAINER_PASSWORD" ] && [ -z "$PASSWORD_CONFIRM" ]; then
        CONTAINER_PASSWORD="changeme"
        break
    elif [ "$CONTAINER_PASSWORD" = "$PASSWORD_CONFIRM" ]; then
        break
    else
        whiptail --title "$TITLE" --msgbox "Passwords do not match. Please try again." 8 60
    fi
done

CONTAINER_VLAN=$(whiptail --title "$TITLE" --inputbox "VLAN Tag:" 8 60 "5" 3>&1 1>&2 2>&3) || exit 1

# IP Configuration - DHCP or Static
IP_TYPE=$(whiptail --title "$TITLE" --menu "IP Configuration:" 12 60 2 \
    "dhcp" "Use DHCP (automatic)" \
    "static" "Configure Static IP" \
    3>&1 1>&2 2>&3) || exit 1

if [ "$IP_TYPE" = "static" ]; then
    CONTAINER_IP=$(whiptail --title "$TITLE" --inputbox "Static IP Address (e.g., 192.168.1.100/24):" 8 60 "192.168.1.100/24" 3>&1 1>&2 2>&3) || exit 1
    CONTAINER_GW=$(whiptail --title "$TITLE" --inputbox "Gateway Address (e.g., 192.168.1.1):" 8 60 "192.168.1.1" 3>&1 1>&2 2>&3) || exit 1
else
    CONTAINER_IP="dhcp"
    CONTAINER_GW=""
fi

# Display configuration summary
if [ "$IP_TYPE" = "static" ]; then
    IP_SUMMARY="$CONTAINER_IP (Gateway: $CONTAINER_GW)"
else
    IP_SUMMARY="DHCP"
fi

SUMMARY="Container ID: $CONTAINER_ID
Hostname: $CONTAINER_HOSTNAME
VLAN: $CONTAINER_VLAN
IP: $IP_SUMMARY

ARM Defaults:
  CPU: 4 cores
  RAM: 4096 MB
  Swap: 1024 MB
  Storage: local-lvm
  Root FS: 100 GB
  Bridge: vmbr0
  Privileged: Yes
  GPU Passthrough: Yes
  Optical Passthrough: Yes"

if ! whiptail --title "$TITLE" --yesno "Configuration Summary:\n\n$SUMMARY\n\nProceed with this configuration?" 24 60; then
    echo "Configuration cancelled."
    exit 0
fi

clear
echo "Creating ARM Docker container..."
echo ""

# Download docker.sh script
wget -qO /tmp/docker-setup.sh https://raw.githubusercontent.com/BigDutch15/macpro-homelab/main/scripts/docker.sh
chmod +x /tmp/docker-setup.sh

# Build docker.sh command with parameters
CMD="/tmp/docker-setup.sh --silent --id \"$CONTAINER_ID\" --hostname \"$CONTAINER_HOSTNAME\" --password \"$CONTAINER_PASSWORD\" --cpu 4 --ram 2048 --swap 512 --storage local-lvm --rootfs 100 --bridge vmbr0 --vlan \"$CONTAINER_VLAN\" --ip \"$CONTAINER_IP\" --privileged 0 --gpu 1 --optical 1"

# Add gateway if static IP
if [ -n "$CONTAINER_GW" ]; then
    CMD="$CMD --gateway \"$CONTAINER_GW\""
fi

# Execute docker.sh with ARM-specific parameters
eval $CMD

# Cleanup
rm -f /tmp/docker-setup.sh

# Install nfs-common and sudo
echo "Installing nfs-common and sudo..."
pct exec $CONTAINER_ID -- bash -c "apt-get update && apt-get install -y nfs-common sudo"

# Create arm user
echo "Creating arm user..."
pct exec $CONTAINER_ID -- bash -c "useradd -u 1000 -m -s /bin/bash arm && usermod -aG sudo arm && passwd arm"

# Prompt for NFS server IP
echo "Configuring NFS mounts..."
read -p "Enter the NFS server IP: " NFS_SERVER

# Discover available NFS shares
echo "Discovering NFS shares from $NFS_SERVER..."
NFS_SHARES=$(pct exec $CONTAINER_ID -- bash -c "showmount -e $NFS_SERVER --no-headers 2>/dev/null" | awk '{print $1}')

if [ -z "$NFS_SHARES" ]; then
    echo "ERROR: No NFS shares found on $NFS_SERVER or showmount failed"
    echo "Please verify the NFS server is running and accessible"
    exit 1
fi

echo "Found NFS shares:"
echo "$NFS_SHARES" | while read share; do
    echo "  $share"
done

# Create mount points and add to fstab for each share
echo ""
echo "Creating mount points and configuring fstab..."
MOUNT_BASE="/mnt/nfs"

echo "$NFS_SHARES" | while read share; do
    if [ -n "$share" ]; then
        # Create local mount point based on share path
        local_mount="$MOUNT_BASE$share"
        
        echo "  Configuring: $share -> $local_mount"
        
        # Create mount directory
        pct exec $CONTAINER_ID -- bash -c "mkdir -p '$local_mount'"
        
        # Add to fstab
        fstab_entry="$NFS_SERVER:$share $local_mount nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0"
        pct exec $CONTAINER_ID -- bash -c "echo '$fstab_entry' >> /etc/fstab"
    fi
done

echo "NFS mounts configured"

# Restart the container
echo "Restarting the container..."
pct reboot $CONTAINER_ID

# Wait for container to come back online
wait_for_container $CONTAINER_ID || exit 1

# Validate NFS mounts as arm user
echo "Validating NFS mounts..."
NFS_VALIDATION_FAILED=0

# Get list of configured mount points from fstab
CONFIGURED_MOUNTS=$(pct exec $CONTAINER_ID -- bash -c "grep 'nfs' /etc/fstab | awk '{print \$2}'" 2>/dev/null)

for mount_point in $CONFIGURED_MOUNTS; do
    validate_nfs_mount $CONTAINER_ID "$mount_point" || NFS_VALIDATION_FAILED=1
done

if [ $NFS_VALIDATION_FAILED -eq 1 ]; then
    echo ""
    echo "WARNING: Some NFS mounts failed validation."
    echo "Please check NFS server permissions and mount configuration."
else
    echo "All NFS mounts validated successfully"
fi

# Install ARM (Automatic Ripping Machine) Docker
echo ""
echo "Installing ARM Docker..."

# Install prerequisites
echo "Installing ARM prerequisites..."
pct exec $CONTAINER_ID -- bash -c "apt-get install -y wget lsscsi"

# Download ARM docker-setup script
echo "Downloading ARM docker-setup script..."
pct exec $CONTAINER_ID -- bash -c "wget -q https://raw.githubusercontent.com/automatic-ripping-machine/automatic-ripping-machine/main/scripts/installers/docker-setup.sh -O /tmp/docker-setup.sh"
pct exec $CONTAINER_ID -- bash -c "chmod +x /tmp/docker-setup.sh"

# Run ARM docker-setup script
echo "Running ARM docker-setup script..."
pct exec $CONTAINER_ID -- bash -c "/tmp/docker-setup.sh"

# Create ARM directories
echo "Creating ARM directories..."
pct exec $CONTAINER_ID -- bash -c "mkdir -p /home/arm/{music,logs,media,config}"
pct exec $CONTAINER_ID -- bash -c "mkdir -p /home/arm/media/completed/{movies,shows}"
pct exec $CONTAINER_ID -- bash -c "chown -R arm:arm /home/arm"

# Get the NFS music mount path for ARM config
MUSIC_MOUNT=$(pct exec $CONTAINER_ID -- bash -c "grep 'music' /etc/fstab | awk '{print \$2}'" 2>/dev/null | head -1)
MOVIES_MOUNT=$(pct exec $CONTAINER_ID -- bash -c "grep 'movies' /etc/fstab | awk '{print \$2}'" 2>/dev/null | head -1)
SHOWS_MOUNT=$(pct exec $CONTAINER_ID -- bash -c "grep 'shows' /etc/fstab | awk '{print \$2}'" 2>/dev/null | head -1)

# Generate start_arm_container.sh with proper configuration
echo "Generating ARM container start script..."
pct exec $CONTAINER_ID -- bash -c "cat > /home/arm/start_arm_container.sh << 'ARMSCRIPT'
#!/bin/bash
docker run -d \\
    --name automatic-ripping-machine \\
    --restart unless-stopped \\
    -p 8080:8080 \\
    -e ARM_UID="1000" \\
    -e ARM_GID="1000" \\
    -e TZ=America/Chicago \\
    -e NVIDIA_DRIVER_CAPABILITIES=all \\
    -v \"/home/arm:/home/arm\" \\
    -v \"${MUSIC_MOUNT:-/home/arm/music}:/home/arm/music\" \\
    -v \"/home/arm/logs:/home/arm/logs\" \\
    -v \"/home/arm/media:/home/arm/media\" \\
    -v \"/home/arm/config:/etc/arm/config\" \\
    -v \"${MOVIES_MOUNT:-/home/arm/media/completed/movies}:/home/arm/media/completed/movies\" \\
    -v \"${SHOWS_MOUNT:-/home/arm/media/completed/shows}:/home/arm/media/completed/shows\" \\
    --gpus all \\
    --device=/dev/sr0:/dev/sr0 \\
    --privileged \\
    automaticrippingmachine/automatic-ripping-machine:latest
ARMSCRIPT"

pct exec $CONTAINER_ID -- bash -c "chmod +x /home/arm/start_arm_container.sh"
pct exec $CONTAINER_ID -- bash -c "chown arm:arm /home/arm/start_arm_container.sh"

# Start ARM container
echo "Starting ARM Docker container..."
pct exec $CONTAINER_ID -- bash -c "sudo -u arm /home/arm/start_arm_container.sh"

# Wait for ARM to start
echo "Waiting for ARM container to start..."
sleep 10

# Get container IP address
CONTAINER_IP=$(pct exec $CONTAINER_ID -- bash -c "hostname -I | awk '{print \$1}'" 2>/dev/null | tr -d '[:space:]')

# Verify ARM is running
if pct exec $CONTAINER_ID -- bash -c "docker ps | grep -q automatic-ripping-machine"; then
    echo "ARM Docker container is running"
    echo ""
    echo "ARM Web UI available at: http://${CONTAINER_IP}:8080"
    echo "Default credentials: admin / password"
else
    echo "WARNING: ARM Docker container may not have started correctly"
    echo "Check logs with: docker logs automatic-ripping-machine"
fi

# Cleanup
pct exec $CONTAINER_ID -- bash -c "rm -f /tmp/docker-setup.sh"

echo ""
echo "ARM container setup complete!"

