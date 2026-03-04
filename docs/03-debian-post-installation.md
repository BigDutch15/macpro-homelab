# Debian Post-Installation

This guide covers the post-installation configuration steps after installing Debian 13 on the Mac Pro (Early 2008) hardware platform.

## Prerequisites

- Debian 13 successfully installed
- System booted and accessible
- Internet connectivity available

### Post-Installation Configuration

#### 1. System Updates

```bash
apt update && apt upgrade -y
```

#### 2. Install and Configure sudo

```bash
apt install -y sudo

# Add user to sudo group
usermod -aG sudo username

# logout and login as username
```

#### 3. Install Essential Tools

```bash
sudo apt install -y lshw htop net-tools curl git
```

- `lshw` for hardware information
- `htop` for system monitoring
- `net-tools` for network utilities
- `curl` for web requests and API calls
- `git` for version control and repository management

#### 3. System Optimization

Edit `/etc/sysctl.conf` for performance tuning

```bash
sudo nano /etc/sysctl.conf
```

```ini
# Sets the system's "swappiness" value to 10
# Value of 10: Uses swap only when RAM is about 90% full, keeping frequently accessed data in fast memory
vm.swappiness=10

# Allows the system to act as a router between network interfaces
net.ipv4.ip_forward=1
```

# Apply changes

```bash
sudo sysctl -p
```

### Network Drivers

Both Broadcom network interfaces are supported by the `tg3` driver:

```bash
# Verify network interfaces
ip link show
# Should show enp7s0f0 and enp7s0f1
```

## Verification

### System Information

```bash
# Verify system details
uname -a
lsb_release -a
lscpu
free -h
df -h
ip addr show
```

### Hardware Detection

```bash
# Check all hardware components
lspci
lsusb
lshw -short
```

## Next Steps

With Debian post-installation configuration complete, the next steps are:

1. **Network Configuration** - Set up static IP and network interfaces
1. **SSH and Shell Setup** - Configure remote access and shell environment
1. **Proxmox Installation** - Install and configure virtualization platform

See the respective documentation files for detailed instructions:

- [Network Configuration](04-network-configuration.md)
- [SSH and Shell Setup](05-ssh-shell-setup.md)
- [Proxmox Installation](06-proxmox-installation.md)
