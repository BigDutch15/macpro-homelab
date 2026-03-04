# Proxmox Installation

This guide covers the installation and configuration of Proxmox Virtual Environment (VE) on the Mac Pro (Early 2008) running Debian 13.

## Prerequisites

- Debian 13 "Trixie" system fully installed and configured
- SSH access established
- 16GB+ RAM (recommended for virtualization)
- Dedicated storage for VMs (300GB+ recommended)
- Static IP address configured
- Internet connectivity for package installation
- **Important**: Hostname must resolve to a non-loopback IP address

## System Preparation

### 1. Network Configuration

Ensure you have a static IP address configured. Edit `/etc/network/interfaces`:

```bash
# Backup original
sudo cp /etc/network/interfaces /etc/network/interfaces.backup

# Edit
sudo nano /etc/network/interfaces
```

**Example Configuration**:

```ini
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug enp7s0f0
iface enp7s0f0 inet static
   address 192.168.1.10
   netmask 255.255.255.0
   gateway 192.168.1.1
   dns-nameservers 8.8.8.8 8.8.4.4
```

restart network service:

```bash
sudo systemctl restart networking
```

### 4. Configure DNS Resolution

Update `/etc/resolv.conf` to ensure proper DNS resolution:

```bash
# Backup original resolv.conf
sudo cp /etc/resolv.conf /etc/resolv.conf.backup

# Edit resolv.conf
sudo nano /etc/resolv.conf
```

**Add to /etc/resolv.conf**:

```ini
# DNS configuration for Proxmox
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 8.8.4.4
search localdomain
```

**Verify DNS configuration**:

```bash
# Test DNS resolution
nslookup google.com
ping -c 3 8.8.8.8
```

### 5. Hostname Configuration

**Important**: Your hostname must resolve to a non-loopback IP address (not 127.0.0.1).

```bash
# Set hostname
sudo hostnamectl set-hostname pve-macpro

# Edit /etc/hosts
sudo nano /etc/hosts
```

**Add to /etc/hosts** (replace with your actual IP):

```ini
127.0.0.1 localhost
192.168.1.10 pve-macpro.localdomain pve-macpro

# The following lines are desirable for IPv6 capable hosts
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

**Test hostname resolution**:

```bash
hostname --ip-address
# Should return at least one non-loopback IP address
192.168.1.10
```

## Proxmox VE Installation

### 1. Add Proxmox VE Repository

Add the Proxmox VE repository using the modern deb822 format:

```bash
# Note: This command must be run as root, not with sudo
# Switch to root user first:
sudo su

# Create repository configuration
cat > /etc/apt/sources.list.d/pve-install-repo.sources << 'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# Add the Proxmox VE repository key
wget https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg -O /usr/share/keyrings/proxmox-archive-keyring.gpg

# Verify the key (optional but recommended)
sha256sum /usr/share/keyrings/proxmox-archive-keyring.gpg
# Should match: 136673be77aba35dcce385b28737689ad64fd785a797e57897589aed08db6e45

# Exit root user
exit
```

**Note**: To migrate pre-existing repository sources to the recommended deb822 format, you can run:

```bash
sudo apt modernize-sources -y
```

### 2. Update System and Repository

```bash
# Update package lists and upgrade system
sudo apt update && sudo apt full-upgrade -y
```

### 3. Install Proxmox VE Kernel

First install and boot the Proxmox VE kernel:

```bash
# Install Proxmox default kernel
sudo apt install -y proxmox-default-kernel

# Reboot into the new kernel
sudo systemctl reboot
```

### 4. Install Proxmox VE Packages

After rebooting into the Proxmox kernel:

```bash
# Install Proxmox VE packages
sudo apt install -y proxmox-ve postfix open-iscsi chrony
```

**Note**: You can replace `chrony` with any other NTP daemon, but it's recommended over `systemd-timesyncd` on server systems.

**Postfix Configuration**:

- If you have a mail server in your network, configure postfix as a satellite system
- If unsure, choose "local only" and leave the system name as is

### 5. Remove Debian Kernel

Proxmox VE ships its own kernel. Remove the default Debian kernel to avoid upgrade conflicts:

```bash
# Remove Debian kernel packages
sudo apt remove -y linux-image-amd64 'linux-image-6.12*'

# Update GRUB configuration
sudo update-grub
```

### 6. Remove os-prober Package

Remove os-prober to prevent it from scanning VM partitions for boot entries:

```bash
sudo apt remove -y os-prober
```

## Post-Installation Configuration

### 1. Verify Installation

```bash
# Check Proxmox kernel
uname -r
# Should show something like: 6.17.13-1-pve

# Check Proxmox services
sudo systemctl status pveproxy
sudo systemctl status pvedaemon
sudo systemctl status pvestatd
```

### 2. Access Proxmox Web Interface

Open your web browser and navigate to:

```
https://192.168.1.10:8006
```

- **Username**: root
- **Password**: your root password
- **Realm**: PAM authentication (for fresh installs)

## Mac Pro Specific Considerations

### 1. Hardware Compatibility

#### CPU Virtualization Support

```bash
# Check CPU virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo

# Check IOMMU support
sudo dmesg | grep -i "iommu"
```

#### Enable IOMMU for Device Passthrough

Edit `/etc/default/grub`:

```bash
sudo nano /etc/default/grub
```

**Add to GRUB_CMDLINE_LINUX_DEFAULT**:

```ini
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
```

Update GRUB:

```bash
sudo update-grub
sudo systemctl reboot
```

## Performance Optimization

### 1. CPU Performance

```bash
# Enable CPU scaling governor
sudo echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Make permanent
sudo echo "performance" | sudo tee /etc/default/cpufrequtils
```

### 2. Memory Optimization

```bash
# Configure kernel parameters for KVM
sudo echo "vm.nr_hugepages=1024" | sudo tee -a /etc/sysctl.conf
```

### 3. Storage Performance

```bash
# Enable I/O scheduler for SSD
sudo echo "deadline" | sudo tee /sys/block/sda/queue/scheduler

# Configure for VM storage
sudo echo "vm.dirty_ratio=15" | sudo tee -a /etc/sysctl.conf
sudo echo "vm.dirty_background_ratio=5" | sudo tee -a /etc/sysctl.conf
```

## Next Steps

With Proxmox VE installed and configured, you now have a powerful virtualization platform. The next step is to install video drivers and graphics tools. See [Video Drivers and Tools](06-video-drivers.md) for detailed instructions.

## Additional Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox Forums](https://forum.proxmox.com/)
- [Proxmox Wiki](https://pve.proxmox.com/wiki/Main_Page)
- [Official Installation Guide for Debian 13 Trixie](https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_13_Trixie)
