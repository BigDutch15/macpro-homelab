#!/bin/bash

# Automatic Ripping Machine (ARM) Docker Container Setup
# This script prompts for container-specific settings and calls docker.sh with predefined ARM defaults

# Check for whiptail
if ! command -v whiptail &> /dev/null; then
    echo "Installing whiptail..."
    apt-get update && apt-get install -y whiptail
fi

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