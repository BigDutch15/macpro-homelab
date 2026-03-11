#!/bin/bash

# PVE Default Configuration Values
# Source this file to get default values for LXC/VM creation

# Container/VM Defaults
DEFAULT_PVE_ID="900"
DEFAULT_HOSTNAME="pve-entity"
DEFAULT_PASSWORD="changeme"

# OS Defaults
DEFAULT_OS="debian"
DEFAULT_OS_VERSION="13"
DEFAULT_OSTYPE="debian"
DEFAULT_ARCH="amd64"

# Hardware Defaults
DEFAULT_CPU="4"
DEFAULT_RAM="4096"
DEFAULT_SWAP="1024"
DEFAULT_ROOTFS_SIZE="32"

# Storage Defaults
DEFAULT_STORAGE="local-lvm"

# Network Defaults
DEFAULT_NETWORK="eth0"
DEFAULT_TYPE="veth"
DEFAULT_BRIDGE="vmbr0"
DEFAULT_VLAN="5"
DEFAULT_IP="dhcp"
DEFAULT_FIREWALL="1"

# Container Type (0=privileged, 1=unprivileged)
DEFAULT_UNPRIVILEGED="0"

# Passthrough Defaults (0=off, 1=on)
DEFAULT_GPU_PASSTHROUGH="1"
DEFAULT_OPTICAL_PASSTHROUGH="1"
DEFAULT_NFS="0"
