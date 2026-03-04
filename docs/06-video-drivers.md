# Video Drivers and Tools

This guide covers the installation and configuration of video drivers and graphics tools for the Mac Pro (Early 2008) running Debian 13 with Proxmox VE.

## Prerequisites

- Debian 13 with Proxmox VE installed
- SSH access to the system
- Internet connectivity for package installation
- Understanding of GPU passthrough requirements

## Hardware Overview

### Current Graphics

- **GPU**: NVIDIA GeForce GTX 750 Ti
- **VRAM**: 2 GB GDDR5
- **Interface**: PCIe 3.0 x16
- **Outputs**: 1x DVI, 1x HDMI, 1x DisplayPort
- **Power Consumption**: 60W

### Stock Graphics

- **GPU**: ATI Radeon HD 2600 XT
- **VRAM**: 256 MB GDDR3
- **Interface**: PCIe 2.0 x16
- **Outputs**: 2x Dual-Link DVI
- **Architecture**: R600 (pre-GCN)

## NVIDIA Proprietary Drivers (GTX 750 Ti)

### 1. Install NVIDIA Driver

**_First, blacklist the Nouveau driver to prevent conflicts_**

```bash
sudo echo "blacklist nouveau" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
sudo echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf

# Update initramfs to apply blacklist
sudo update-initramfs -u

# Check if nouveau is enabled
sudo lsmod | grep nouveau

# Disable nouveau and verify:
sudo rmmod nouveau
sudo lsmod | grep nouveau

# Ensure the video card is visible to the system
lspci | grep NVIDIA

# Reboot to disable Nouveau before installing NVIDIA driver
sudo systemctl reboot
```

**_After reboot, continue with NVIDIA driver installation_**

```bash
# Use the tmp dir
cd /tmp
```

```bash
# Download NVIDIA driver
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/580.126.09/NVIDIA-Linux-x86_64-580.126.09.run
```

```bash
# Make the installer executable
chmod +x NVIDIA-Linux-x86_64-580.126.09.run
```

```bash
# Install build tools required for driver compilation
sudo apt install -y build-essential pkg-config libglvnd-dev pve-headers-$(uname -r)
```

```bash
# Run the NVIDIA installer
sudo ./NVIDIA-Linux-x86_64-580.126.09.run

# Follow the on-screen prompts:
# - NO to run the nvidia-xconfig utility ( we don't use X)
```

```bash
# Check the driver was installed successfully
nvidia-smi
```

### 2. Enable Persistence Mode

**_ Turn on [persistence mode](https://docs.nvidia.com/deploy/driver-persistence/index.html) (lowers IDLE power consumption): _**

```bash
# only for current session
sudo nvidia-smi --persistence-mode=1

# enable moving forward
sudo nvidia-persistenced

# reboot
sudo systemctl reboot
```

### 3. Verify Installation

```bash
# Check if NVIDIA driver is loaded
nvidia-smi
# The output should show your GTX 750 Ti with driver version 580.126.09 and display GPU temperature, memory usage, and other system information.

# Check GPU information
lspci -vnn | grep -i nvidia
```

### 3. Install VAAPI Driver

```bash
# Install VAAPI driver
sudo apt install -y vainfo nvidia-vaapi-driver
```

### 4. Add NVIDIA DRM modeset to GRUB

```bash
# Add "nvidia-drm.modeset=1" to GRUB
sudo nano /etc/default/grub
```

Locate the line starting with GRUB_CMDLINE_LINUX_DEFAULT. Add nvidia-drm.modeset=1 inside the quotes, ensuring there is a space between existing parameters. It should look similar to:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on nvidia-drm.modeset=1"
```

Update the grub

```bash
sudo update-grub
```

Reboot

```bash
sudo systemctl reboot
```

### 5. Test Graphics

```bash
# Check NVIDIA driver status
nvidia-smi

# Verify VAAPI is working
vainfo
```

## Graphics Tools and Utilities

### 1. System Monitoring Tools

```bash
# Install GPU monitoring and Python dependencies
sudo apt install -y nvtop pipx

# Install additional monitoring tools
pipx install gpustat

# Ensure the path is set (you might need to restart your terminal after this)
pipx ensurepath
```

## Next Steps

With video drivers and graphics tools properly installed, you now have a fully functional graphics system. The next step is to configure networking for optimal performance and security. See [Network Configuration](07-network-configuration.md) for detailed instructions.

## Additional Resources

- [NVIDIA Driver Documentation](https://docs.nvidia.com/datacenter/tesla/)
- [Nouveau Documentation](https://nouveau.freedesktop.org/)
- [Proxmox GPU Passthrough](https://pve.proxmox.com/wiki/Pci_passthrough)
- [NVIDIA GTX 750 Ti Specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/geforce-gtx-750-ti/)
