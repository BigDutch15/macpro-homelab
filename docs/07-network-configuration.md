# Network Configuration

This guide covers the network configuration for the Mac Pro home lab, including interface bonding, VLANs, firewall setup, and network optimization.

## Prerequisites

- Debian 13 system installed and running
- Multiple network interfaces available
- Understanding of network topology requirements
- Administrative access to network equipment

## Basic Network Configuration

### 1. Static IP Configuration

Edit `/etc/network/interfaces` for static IP configuration:

```bash
sudo cp /etc/network/interfaces /etc/network/interfaces.backup
sudo nano /etc/network/interfaces
```

```ini
   # This file describes the network interfaces available on your system
   # and how to activate them. For more information, see interfaces(5).

   # The loopback network interface
   auto lo
   iface lo inet loopback

   # The primary network interface
   iface enp7s0f0 inet manual

   # The other ethernet port
   iface enp7s0f1 inet manual

   # The bridge interface
   auto vmbr0
   iface vmbr0 inet static
            address 192.168.1.10/24
            gateway 192.168.1.1
            bridge-ports enp7s0f0
            bridge-stp off
            bridge-fd 0

   source /etc/network/interfaces.d/*
```

```bash
# Restart networking
sudo systemctl restart networking
```

## VLAN Configuration (optional)

COMING SOON

## Next Steps

With networking properly configured and optimized, the next step is to install video drivers and tools for graphics support. See [Video Drivers and Tools](06-video-drivers.md) for detailed instructions.

## Additional Resources

- [Debian Networking Documentation](https://wiki.debian.org/NetworkConfiguration)
- [Proxmox Network Documentation](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_network_configuration)
- [Linux Advanced Routing & Traffic Control](http://lartc.org/)
