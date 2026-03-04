# Debian 13 Installation

This guide covers the installation of Debian 13 (Trixie) on the Mac Pro (Early 2008) hardware platform.

## Prerequisites

### Hardware Requirements

- Mac Pro (Early 2008) with hardware specifications as documented
- USB boot drive (8GB+)

### Software Requirements

- Debian 13 installation media
- Internet connection for package installation
- Another computer for creating boot media

## Preparation

### Create Bootable USB Media

1. **Download Debian 13 ISO**

   ```bash
   wget https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-13.3.0-amd64-DVD-1.iso
   ```

2. **Create bootable USB Media**

   **Option 1: Using balenaEtcher (Recommended - Cross-platform)**
   1. Download and install balenaEtcher from https://etcher-docs.balena.io/
   2. Open balenaEtcher
   3. Select the Debian ISO file
   4. Insert your USB drive (8GB+)
   5. Select the USB drive as target
   6. Click "Flash!" to create bootable USB

   **Option 2: Using macOS Command Line**

   ```bash
   # Convert ISO to IMG
   hdiutil convert -format UDRW -o debian-13.3.0.img debian-13.3.0-amd64-DVD-1.iso

   # Identify USB drive
   diskutil list

   # Unmount USB drive (replace /dev/diskX)
   diskutil unmountDisk /dev/diskX

   # Write to USB drive
   sudo dd if=debian-13.3.0.img.dmg of=/dev/rdiskX bs=1m
   diskutil eject /dev/diskX
   ```

   **Option 3: Using Windows**
   1. Download and install Rufus from https://rufus.ie/
   2. Insert your USB drive (8GB+)
   3. Open Rufus
   4. Select the USB drive as Device
   5. Select the Debian ISO file
   6. Partition scheme: GPT (for UEFI)
   7. File system: FAT32
   8. Click "START" to create bootable USB

   **Option 4: Using Linux**

   ```bash
   # Insert USB drive and identify it
   lsblk
   # Note your USB device (e.g., /dev/sdb)

   # Download Debian ISO if not already downloaded
   wget https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-13.3.0-amd64-DVD-1.iso

   # Write ISO to USB drive (replace /dev/sdX with your USB device)
   sudo dd if=debian-13.3.0-amd64-DVD-1.iso of=/dev/sdX bs=4M status=progress conv=fdatasync

   # Sync to ensure all data is written
   sync
   ```

### BIOS Configuration

The Mac Pro uses a custom EFI implementation. Before installation:

1. **Reset NVRAM/PRAM**
   - Boot holding Command+Option+P+R
   - Wait for two chimes, then release

2. **Set Boot Priority**
   - Insert USB drive
   - Boot holding Option key to access boot picker
   - Select the USB drive with Debian installer

## Installation Process

### Boot from USB Media

1. Insert the bootable USB drive
2. Power on the Mac Pro
3. Hold the Option key to access the boot picker
4. Select "EFI Boot" or "Debian Installer" from the menu
5. Press Enter to begin installation

### Installation Steps

#### 1. Language and Region Selection

- **Language**: English
- **Country**: United States (or your location)
- **Locale**: en_US.UTF-8

#### 2. Keyboard Configuration

- **Layout**: American English
- Test keyboard layout and confirm

#### 3. Network Configuration

- **Hostname**: pve-macpro
- **Domain**: local (or your domain)
- **Network Interface**: Configure both Ethernet interfaces
  - enp7s0f0: Primary network (DHCP)
  - enp7s0f1: Secondary network (DHCP)

#### 4. User Accounts

- **Root Password**: Set strong root password
- **User Account**: Create regular user
  - Username: your preferred username
  - Password: strong user password

#### 5. Partitioning Scheme

**Recommended Partition Layout** (for 1TB SSD):

PLACEHOLDER: Add partitioning scheme here

#### 5. Software Selection

**Base System**:

- Standard system utilities
- SSH server
- Basic system tools

## Next Steps

With Debian 13 successfully installed, the next step is:

1. **Debian Post-Installation** - Complete system configuration and optimization

See the respective documentation file for detailed instructions:

- [Debian Post-Installation](03-debian-post-installation.md)
