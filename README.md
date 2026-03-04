# Mac Pro (Early 2008) Home Lab Setup

This repository documents the complete setup of a home lab using a Mac Pro (Early 2008) as the foundation. The documentation covers hardware specifications, OS installation, virtualization, storage, and various services.

## Table of Contents

1. [Hardware Specifications](docs/01-hardware-specs.md)
2. [Debian 13 Installation](docs/02-debian-installation.md)
3. [Debian Post-Installation](docs/03-debian-post-installation.md)
4. [Network Configuration](docs/04-network-configuration.md)
5. [SSH and Shell Setup](docs/05-ssh-shell-setup.md)
6. [Proxmox Installation](docs/06-proxmox-installation.md)
7. [Video Drivers and Tools](docs/07-video-drivers.md)
8. [TrueNAS Setup](docs/08-truenas-setup.md)
9. [Docker Installation](docs/09-docker-setup.md)
10. [Automatic Ripping Machine](docs/10-automatic-ripping-machine.md)
11. [n8n Installation](docs/11-n8n-setup.md)

## Project Structure

```
macpro-homelab/
├── README.md                 # This file
├── docs/                     # All documentation
│   ├── 01-hardware-specs.md
│   ├── 02-debian-installation.md
│   ├── 03-debian-post-installation.md
│   ├── 04-network-configuration.md
│   ├── 05-ssh-shell-setup.md
│   ├── 06-proxmox-installation.md
│   ├── 07-video-drivers.md
│   ├── 08-truenas-setup.md
│   ├── 09-docker-setup.md
│   ├── 10-automatic-ripping-machine.md
│   └── 11-n8n-setup.md
├── assets/                   # Screenshots and images
├── scripts/                  # Useful scripts
└── config-files/             # Configuration file examples
```

## About This Project

This home lab setup transforms a vintage Mac Pro (Early 2008) into a powerful virtualization and storage server. The Mac Pro's robust hardware and expandability make it an excellent platform for running multiple services and virtual machines.

### Key Features

- **Virtualization**: Proxmox VE for running multiple VMs and containers
- **Storage**: TrueNAS for network-attached storage with ZFS
- **Automation**: Docker containers for various services
- **Media Management**: Automatic Ripping Machine for digitizing media
- **Workflow Automation**: n8n for connecting services and automating tasks

## Getting Started

Start with the [Hardware Specifications](docs/01-hardware-specs.md) to understand the base system, then follow each section in order for a complete setup.

## Contributing

This is a personal project documentation. Feel free to open issues or submit pull requests if you have suggestions or improvements.
