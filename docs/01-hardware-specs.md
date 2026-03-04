# Hardware Specifications

This document details the hardware specifications of the Mac Pro (Early 2008) used for this home lab setup.

## System Overview

**Model**: Mac Pro (Early 2008)  
**Model Identifier**: MacPro3,1  
**Release Date**: January 2008  
**Architecture**: 64-bit Intel

## Processor

- **CPU**: Intel Xeon E5462 (Quad-Core)
- **Speed**: 2.8 GHz
- **Cores**: 4 cores, 8 threads with Hyper-Threading
- **L2 Cache**: 12 MB
- **Front Side Bus**: 1600 MHz
- **Socket**: LGA 771

## Memory

- **Type**: FB-DIMM (Fully Buffered DIMM)
- **Speed**: 800 MHz
- **Configuration**: 8x 4GB modules = 32 GB total
- **Slots**: 8 DIMM slots (2 per processor)
- **Max Supported**: 32 GB (fully populated)

## Storage

### Primary Storage

- **Type**: 1TB 3D NAND SATA 2.5-Inch Internal SSD
- **Capacity**: 1 TB
- **Interface**: SATA II (3.0 Gb/s)
- **Form Factor**: 2.5-inch
- **Purpose**: Operating system and virtualization host

### Secondary Storage

- **Type**: 1TB 2.5" SATA SSD
- **Capacity**: 1 TB
- **Interface**: SATA II (3.0 Gb/s)
- **Form Factor**: 2.5-inch
- **Purpose**: VM storage and applications

### Data Storage Bays

- **Total Bays**: 4 internal 3.5" drive bays
- **Configuration**: 4x Seagate 1TB Desktop HDD Hard Drives
- **Total Capacity**: 4 TB
- **Purpose**: TrueNAS ZFS pool setup
- **Planned Usage**: RAID-Z2 configuration with double parity

## Graphics

- **GPU**: NVIDIA GeForce GTX 750 Ti
- **VRAM**: 2 GB GDDR5
- **Interface**: PCIe 3.0 x16
- **Outputs**: 1x DVI, 1x HDMI, 1x DisplayPort
- **Power Consumption**: 60W
- **Notes**: Excellent GPU for server use, supports GPU passthrough, low power consumption

## Network

- **Built-in Ethernet**: 2x Gigabit Ethernet ports
- **Chipset**: Broadcom BCM5761
- **Speed**: 10/100/1000 Mbps
- **Configuration**: Bonding available for redundancy

## Expansion Slots

- **Total PCIe Slots**: 4
  - 1 x PCIe 2.0 x16 (double-wide)
  - 1 x PCIe 2.0 x16 (single-wide)
  - 2 x PCIe 2.0 x4 (single-wide)
- **Current Usage**:
  - PCIe x16 (double-wide): NVIDIA GeForce GTX 750 Ti
  - PCIe x16 (single-wide): Available
  - PCIe x4 (single-wide): Available (2 slots)

## Power Supply

- **Type**: 980W Power Supply Unit
- **Efficiency**: 80 Plus Bronze
- **Connectors**: Sufficient for multiple drives and expansion cards
- **Redundancy**: Single unit (no redundant power supply option)

## Chassis and Cooling

- **Form Factor**: Tower
- **Material**: Aluminum
- **Dimensions**: 20.1" × 8.1" × 18.7" (51.1 × 20.6 × 47.5 cm)
- **Weight**: ~40 lbs (18.1 kg)
- **Cooling**: Multiple fans with thermal management
- **Noise**: Moderate, acceptable for server environment

## I/O Ports

### Front Panel

- 2x USB 2.0 ports
- 1x FireWire 400 port
- 1x Headphone jack
- 1x Line-in jack

### Rear Panel

- 5x USB 2.0 ports
- 2x FireWire 800 ports
- 2x Gigabit Ethernet ports
- 2x Dual-Link DVI ports
- 1x Optical audio out
- 1x Optical audio in
- 1x Line-out jack
- 1x Line-in jack

## Hardware Modifications and Upgrades

### Completed Upgrades

1. **Memory**: Upgraded from 2GB to 16GB FB-DIMM
2. **Primary Storage**: Replaced original HDD with 500GB SSD
3. **Secondary Storage**: Added 2TB HDD for data storage

### Planned Upgrades

1. **Additional Storage**: More 2TB+ drives for ZFS pool
2. **GPU**: Consider upgrade for GPU passthrough capabilities
3. **Network**: 10GbE network card if needed
4. **USB**: PCIe USB 3.0 card for faster external storage

## Compatibility Considerations

### Linux Compatibility

- **CPU**: Excellent support in modern kernels
- **Chipset**: Intel 5000X chipset well supported
- **Network**: Broadcom drivers included in mainline kernel
- **Storage**: Standard SATA controllers supported
- **Audio**: Intel HD Audio supported

### Virtualization Support

- **VT-x**: Supported and enabled
- **VT-d**: Supported for IOMMU (device passthrough)
- **64-bit**: Full 64-bit support required for modern virtualization

## Performance Benchmarks

### Baseline Performance

- **CPU PassMark**: ~4000 (per processor)
- **Memory Bandwidth**: ~25 GB/s
- **Disk Performance (SSD)**: ~250 MB/s read/write
- **Network**: ~950 Mbps practical throughput

## Troubleshooting Hardware Issues

### Common Issues and Solutions

1. **FB-DIMM Errors**
   - Heat-related failures common
   - Regular memory testing recommended
   - Replace in matched pairs

2. **GPU Compatibility**
   - Limited GPU upgrade options due to power constraints
   - Consider low-power professional GPUs

3. **Storage Limitations**
   - SATA II interface limits SSD performance
   - Consider PCIe storage controllers for better performance

## Hardware Inventory

| Component     | Model                     | Quantity | Status  |
| ------------- | ------------------------- | -------- | ------- |
| CPU           | Intel Xeon E5462          | 2        | Working |
| Memory        | 4GB FB-DIMM 800MHz        | 8        | Working |
| Primary SSD   | 1TB 3D NAND SATA 2.5"     | 1        | Working |
| Secondary SSD | 1TB 2.5" SATA             | 1        | Working |
| Data HDD      | Seagate 1TB Desktop HDD   | 4        | Working |
| GPU           | NVIDIA GeForce GTX 750 Ti | 1        | Working |
| PSU           | 980W                      | 1        | Working |

## Next Steps

With the hardware documented and verified, the next step is to install Debian 13 as the base operating system. See [Debian 13 Installation](02-debian-installation.md) for detailed instructions.
