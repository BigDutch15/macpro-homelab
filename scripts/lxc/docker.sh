#!/bin/bash

# Docker LXC Container Setup
# This script creates a Debian LXC container using debian-lxc.sh and installs Docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

This script creates a Debian LXC container with Docker installed.
It uses debian-lxc.sh for base container creation.

OPTIONS:
    --silent                    Run in silent mode (no interactive prompts)
    --id <container_id>         Container ID (default: 900)
    --hostname <hostname>       Container hostname (default: lxc-docker-900)
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
    $0 --silent --id 901 --hostname lxc-docker-901 --password mypass --gpu 0

EOF
    exit 0
}

# Set defaults
VAR_PVE_ID="900"
VAR_HOSTNAME="lxc-docker-900"
VAR_GPU_PASSTHROUGH=1

# Parse arguments to extract values we need for Docker installation
ARGS=("$@")
while [[ $# -gt 0 ]]; do
    case $1 in
        --id)
            VAR_PVE_ID="$2"
            shift 2
            ;;
        --hostname)
            VAR_HOSTNAME="$2"
            shift 2
            ;;
        --gpu)
            VAR_GPU_PASSTHROUGH="$2"
            shift 2
            ;;
        --help)
            show_usage
            ;;
        *)
            shift
            ;;
    esac
done

# Check if debian-lxc.sh exists
if [ ! -f "$SCRIPT_DIR/debian-lxc.sh" ]; then
    echo "ERROR: debian-lxc.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Run debian-lxc.sh with all original arguments (override hostname for docker naming)
echo "Creating base Debian LXC container..."
if ! bash "$SCRIPT_DIR/debian-lxc.sh" "${ARGS[@]}"; then
    echo "ERROR: Failed to create base container"
    exit 1
fi

echo ""
echo "Base container created. Installing Docker components..."
echo ""

install_docker() {
    local container_id=$1
    
    echo "Installing Docker Engine in container $container_id..."
    
    # Install prerequisites
    echo "Installing prerequisites..."
    pct exec $container_id -- bash -c "apt update"
    pct exec $container_id -- bash -c "apt install -y ca-certificates curl"
    
    # Add Docker's official GPG key
    echo "Adding Docker's official GPG key..."
    pct exec $container_id -- bash -c "install -m 0755 -d /etc/apt/keyrings"
    pct exec $container_id -- bash -c "curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc"
    pct exec $container_id -- bash -c "chmod a+r /etc/apt/keyrings/docker.asc"
    
    # Add the repository to Apt sources
    echo "Adding Docker repository to Apt sources..."
    pct exec $container_id -- bash -c 'tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF'
    
    # Update package index
    echo "Updating package index..."
    pct exec $container_id -- bash -c "apt update"
    
    # Install Docker packages
    echo "Installing Docker packages..."
    pct exec $container_id -- bash -c "apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    
    # Verify Docker installation
    echo "Verifying Docker installation..."
    if pct exec $container_id -- bash -c "docker --version" 2>&1; then
        echo "Docker installed successfully"
    else
        echo "Docker installation verification failed"
        return 1
    fi
    
    # Verify Docker service is running
    echo "Checking Docker service status..."
    pct exec $container_id -- bash -c "systemctl status docker --no-pager" || true
    
    # Run hello-world test
    echo "Running Docker hello-world test..."
    if pct exec $container_id -- bash -c "docker run hello-world" 2>&1; then
        echo "Docker is working correctly"
    else
        echo "Docker hello-world test failed"
    fi
    
    echo "Docker Engine installation complete"
}

install_nvidia_container_toolkit() {
    local container_id=$1
    
    echo "Installing NVIDIA Container Toolkit in container $container_id..."
    
    # Install prerequisites
    echo "Installing prerequisites..."
    pct exec $container_id -- bash -c "apt-get update && apt-get install -y --no-install-recommends ca-certificates curl gnupg2"
    
    # Configure the production repository
    echo "Configuring NVIDIA Container Toolkit repository..."
    pct exec $container_id -- bash -c "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
    pct exec $container_id -- bash -c "curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list"
    
    # Update package list
    echo "Updating package list..."
    pct exec $container_id -- bash -c "apt-get update"
    
    # Install NVIDIA Container Toolkit
    echo "Installing NVIDIA Container Toolkit packages..."
    pct exec $container_id -- bash -c "apt-get install -y nvidia-container-toolkit"
    
    # Configure Docker to use NVIDIA runtime
    echo "Configuring Docker to use NVIDIA runtime..."
    pct exec $container_id -- bash -c "nvidia-ctk runtime configure --runtime=docker"
    
    # Restart Docker daemon
    echo "Restarting Docker daemon..."
    pct exec $container_id -- bash -c "systemctl restart docker"
    
    # Verify installation
    echo "Verifying NVIDIA Container Toolkit installation..."
    if pct exec $container_id -- bash -c "nvidia-ctk --version" 2>&1; then
        echo "NVIDIA Container Toolkit installed successfully"
    else
        echo "NVIDIA Container Toolkit installation verification failed"
        return 1
    fi
    
    # Test GPU access in Docker
    echo "Testing GPU access in Docker container..."
    if pct exec $container_id -- bash -c "docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi" 2>&1; then
        echo "GPU is accessible in Docker containers"
    else
        echo "GPU access test failed - this may be expected in LXC containers"
        echo "You may need to use --runtime=nvidia or configure CDI"
    fi
    
    echo "NVIDIA Container Toolkit installation complete"
}

# Install Docker
install_docker "$VAR_PVE_ID"

# Install NVIDIA Container Toolkit if GPU passthrough is enabled and NVIDIA GPU is detected
if [ "$VAR_GPU_PASSTHROUGH" -eq 1 ]; then
    if lspci | grep -i nvidia > /dev/null; then
        install_nvidia_container_toolkit "$VAR_PVE_ID"
    fi
fi

# Install Portainer
echo "Installing Portainer..."
pct exec $VAR_PVE_ID -- bash -c "docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer-ce:lts"

echo ""
echo "Docker LXC container $VAR_PVE_ID setup complete!"
echo "  - Docker Engine: Installed"
echo "  - Portainer: http://<container-ip>:9000"
if [ "$VAR_GPU_PASSTHROUGH" -eq 1 ] && lspci | grep -i nvidia > /dev/null 2>&1; then
    echo "  - NVIDIA Container Toolkit: Installed"
fi
