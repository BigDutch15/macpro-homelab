# TrueNAS Scale Setup

This guide covers the installation and configuration of TrueNAS Scale as a VM on Proxmox VE using the community helper script, including setting up a RAID-Z1 storage pool with 4x 1TB drives.

## Prerequisites

### Hardware Requirements

- Proxmox VE 8.0+ installed and configured
- **LVM-thin storage configured** (see [Proxmox Installation - Storage Configuration](05-proxmox-installation.md#storage-configuration))
- 4x 1TB drives available for passthrough to TrueNAS VM
- Minimum 8GB RAM allocated to VM (16GB+ recommended for production)
- **ECC RAM strongly recommended** for data integrity (ZFS checksumming can be compromised by bad data in RAM)
- 2+ CPU cores allocated to VM

### Software Requirements

- Internet connection for downloading ISO (script handles this automatically)
- Access to Proxmox shell or SSH

### Storage Setup

Before creating the TrueNAS VM, ensure you have configured LVM-thin storage on your Proxmox host:

- **Recommended**: Use a dedicated SSD (e.g., `/dev/sde`) for VM storage
- Follow the [Storage Configuration](05-proxmox-installation.md#storage-configuration) section in the Proxmox Installation guide
- This will create `local-lvm` storage for VM disks with better performance and snapshot support
- The 4x 1TB HDDs (`/dev/sda`, `/dev/sdb`, `/dev/sdc`, `/dev/sdd`) will be passed through to TrueNAS

## VM Creation Using Helper Script

### Run the TrueNAS VM Script

1. **Access Proxmox Shell**

   Log into your Proxmox web interface and open the Shell (Datacenter → Node → Shell), or SSH into your Proxmox host.

2. **Execute the Helper Script**

   ```bash
   bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/vm/truenas-vm.sh)"
   ```

   The script will display the TrueNAS banner and begin the setup process.

### Script Prompts - Advanced Settings

When prompted, select **Advanced** settings to have full control over the VM configuration.

#### 1. Initial Confirmation

**Prompt**: "This will create a New TrueNAS VM. Proceed?"

- **Action**: Select **Yes** to continue

#### 2. Settings Mode Selection

**Prompt**: "Use Default Settings?"

- **Action**: Select **Advanced** (not "Yes")
- This allows you to customize all VM parameters

#### 3. Virtual Machine ID

**Prompt**: "Set Virtual Machine ID"

- **Default**: Auto-generated next available ID
- **Recommended**: `4001` (or your preferred ID)
- **Action**: Enter your desired VM ID or press Enter to accept default
- **Note**: The script validates that the ID is not already in use

#### 4. ISO Selection

**Prompt**: "SELECT ISO TO INSTALL - Select version (BETA/RC/Latest stable)"

- **Options**: The script automatically scrapes https://download.truenas.com/ for available ISOs
  - Latest stable releases for each major version
  - Beta and RC pre-releases (if available)
- **Default**: Latest stable release (pre-selected)
- **Recommended**: Select the latest stable version (default selection)
- **Action**: Use arrow keys to navigate, Space to select, Enter to confirm
- **Example**: `TrueNAS-SCALE-25.10.2.1.iso`

#### 5. Disk Size

**Prompt**: "Set Disk Size in GiB (e.g., 10, 20)"

- **Default**: `16` GB
- **Recommended**: `16` GB minimum, `32` GB for more headroom
- **Action**: Enter disk size in GB (numbers only)
- **Note**: This is the boot disk, not the data disks

#### 6. Hostname

**Prompt**: "Set Hostname"

- **Default**: `truenas`
- **Recommended**: `truenas` or `vm-truenas`
- **Action**: Enter your desired hostname
- **Note**: Hostname will be converted to lowercase with spaces removed

#### 7. CPU Model

**Prompt**: "Choose CPU Model"

- **Options**:
  - `KVM64` - Default, safe for migration/compatibility
  - `Host` - Use host CPU features (faster, no migration) **[Recommended]**
- **Default**: `Host` (pre-selected)
- **Recommended**: Select **Host** for better performance
- **Action**: Use arrow keys to select, Enter to confirm

#### 8. CPU Cores

**Prompt**: "Allocate CPU Cores"

- **Default**: `2`
- **Recommended**: `4` cores for better performance
- **Action**: Enter number of CPU cores
- **Note**: More cores improve performance for concurrent operations

#### 9. RAM Size

**Prompt**: "Allocate RAM in MiB"

- **Default**: `8192` (8 GB)
- **Recommended**: `16384` (16 GB) or higher for production use
- **Action**: Enter RAM size in MiB
- **Note**: ZFS is memory-intensive; more RAM = better performance and caching

#### 10. Bridge

**Prompt**: "Set a Bridge"

- **Default**: `vmbr0`
- **Recommended**: `vmbr0` (default bridge)
- **Action**: Enter bridge name or press Enter for default
- **Note**: Use the bridge configured in your Proxmox network setup

#### 11. MAC Address

**Prompt**: "Set a MAC Address"

- **Default**: Auto-generated MAC address (e.g., `02:XX:XX:XX:XX:XX`)
- **Recommended**: Accept the auto-generated MAC
- **Action**: Press Enter to accept default, or enter custom MAC address
- **Note**: Custom MAC useful for static DHCP reservations

#### 12. VLAN Tag

**Prompt**: "Set a Vlan (leave blank for default)"

- **Default**: No VLAN (blank)
- **Recommended**: `5` (if using VLAN segmentation per your network setup)
- **Action**: Enter VLAN ID or leave blank for no VLAN
- **Note**: Must match your network VLAN configuration

#### 13. MTU Size

**Prompt**: "Set Interface MTU Size (leave blank for default)"

- **Default**: Default MTU (1500)
- **Recommended**: Leave blank unless you have specific jumbo frame requirements
- **Action**: Press Enter for default, or enter custom MTU (e.g., 9000 for jumbo frames)

#### 14. Import Onboard Disks

**Prompt**: "Would you like to import onboard disks?"

- **Options**: Yes / No
- **Recommended**: **Yes** - This allows you to select physical disks to pass through
- **Action**: Select **Yes**
- **Note**: ⚠️ Selected disks will be formatted when you create a pool in TrueNAS

#### 15. Disk Selection (if Import Onboard Disks = Yes)

**Prompt**: "SELECT DISKS TO IMPORT - Select disk IDs to import"

- **Options**: List of available disks from `/dev/disk/by-id/` (ata-, nvme-, usb- devices)
- **Display**: Shows disk IDs (truncated to 45 characters for readability)
- **Recommended**: Select your 4x 1TB Seagate drives:
  - `ata-ST1000DM003-XXXXX` (or similar, based on your disk model)

- **Action**: Use Space to select multiple disks, Enter to confirm
- **Important**:
  - Do NOT select the Proxmox boot disk
  - Do NOT select the SSD used for LVM-thin storage (`/dev/sde`)
  - Only select disks you want to use exclusively for TrueNAS storage

**Example disk selection:**

```
[X] ata-ST1000DM003-XXXXX
[X] ata-ST1000DM003-XXXXX
[X] ata-ST1000DM003-XXXXX
[X] ata-ST1000DM003-XXXXX
[ ] ata-Crucial_CT1000MX500SSD1_XXXXX  (DO NOT SELECT - Proxmox storage)
```

#### 16. Start VM When Completed

**Prompt**: "Start VM when completed?"

- **Options**: Yes / No
- **Recommended**: **Yes** - Automatically start the VM after creation
- **Action**: Select **Yes**

#### 17. Final Confirmation

**Prompt**: "Ready to create a TrueNAS VM?"

- **Options**: Yes / Do-Over
- **Action**: Select **Yes** to proceed, or **Do-Over** to restart advanced settings
- **Note**: Review all settings displayed before confirming

### Script Execution

After confirming, the script will:

1. **Validate Storage** - Prompt you to select a storage pool for the VM boot disk
   - **Recommended**: Select `local-lvm` (your LVM-thin storage)
2. **Download ISO** - Automatically download the selected TrueNAS ISO to `/var/lib/vz/template/iso/`
   - If already cached, it will use the existing file
3. **Create VM Shell** - Create the VM with all specified settings
   - Machine type: q35
   - BIOS: OVMF (UEFI)
   - QEMU agent enabled
   - Network configured with VirtIO
4. **Import Disks** - Attach selected physical disks to the VM as SCSI devices
   - Disks are attached with their serial numbers preserved
   - Assigned to scsi1, scsi2, scsi3, scsi4, etc.
5. **Start VM** - Boot the VM (if you selected "Yes" to start)

### Verify VM Creation

After the script completes, verify the VM configuration:

```bash
qm config 4001
```

Expected output should include:

```
agent: enabled=1
balloon: 0
bios: ovmf
boot: order=sata0;ide2;net0
cores: 4
cpu: host
efidisk0: local-lvm:vm-4001-disk-0,efitype=4m,pre-enrolled-keys=0,size=1M
ide2: local:iso/TrueNAS-SCALE-25.10.2.1.iso,media=cdrom,size=1234567K
localtime: 1
machine: q35
memory: 16384
name: truenas
net0: virtio=XX:XX:XX:XX:XX:XX,bridge=vmbr0,tag=5
onboot: 1
ostype: l26
sata0: local-lvm:vm-4001-disk-1,size=16G,ssd=1
scsi1: /dev/disk/by-id/ata-ST1000DM003-1ER162_XXXXXXXX,serial=XXXXXXXX,size=976762584K
scsi2: /dev/disk/by-id/ata-ST1000DM003-1ER162_XXXXXXXX,serial=XXXXXXXX,size=976762584K
scsi3: /dev/disk/by-id/ata-ST1000DM003-1ER162_XXXXXXXX,serial=XXXXXXXX,size=976762584K
scsi4: /dev/disk/by-id/ata-ST1000DM003-1ER162_XXXXXXXX,serial=XXXXXXXX,size=976762584K
scsihw: virtio-scsi-single
smbios1: uuid=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
tablet: 0
vga: virtio
```

## TrueNAS Installation

The VM should now be running (if you selected "Yes" to start). If not, start it manually.

### Access VM Console

1. **Open Console in Proxmox Web Interface**
   - Navigate to your Proxmox web interface
   - Select the TrueNAS VM (ID: 4001)
   - Click **Console** to access the VM display

2. **Boot from ISO**
   - VM will automatically boot from the TrueNAS Scale ISO
   - Wait for the installer to load (30-60 seconds)

### Installation Steps

1. **Welcome Screen**
   - Press **Enter** to select "Install/Upgrade"

2. **Select Installation Disk**
   - Use arrow keys to navigate the disk list
   - Select the **16GB boot disk** (sata0) - should be the smallest disk shown
   - **DO NOT** select any of the 1TB data disks (scsi1-4)
   - Press **Space** to select the disk
   - Press **Enter** to continue

3. **Installation Warning**
   - Confirm that you want to install TrueNAS on the selected disk
   - Select **Yes** and press **Enter**
   - All data on the boot disk will be erased

4. **Set Root Password** (TrueNAS Scale 24.04+)
   - Enter a strong root password
   - Confirm the password
   - Press **Enter** to continue
   - **Note**: Save this password securely - you'll need it to access the web interface

5. **Installation Progress**
   - Wait for installation to complete (5-10 minutes)
   - System will extract files and configure the boot loader
   - Progress bar will show installation status

6. **Installation Complete**
   - When prompted, select **Reboot System**

   The script recommends unmounting the ISO after installation. To do this:
   - In Proxmox web interface: VM → **Hardware**
   - Select **CD/DVD Drive (ide2)**
   - Click **Edit**
   - Change to **Do not use any media**
   - Click **OK**

7. Return to the VM console and press **Enter** to continue.

8. **Reboot and First Boot**
   - VM will reboot into TrueNAS Scale
   - First boot may take 2-3 minutes as TrueNAS initializes
   - You'll see the TrueNAS console menu when ready

## Initial TrueNAS Configuration

### Access Web Interface

1. **Get IP Address from Console**

   In the VM console, you'll see the TrueNAS console menu with the IP address displayed:

   ```
   TrueNAS Console Setup Menu

   The web user interface is at:
   http://192.168.5.100

   1) Configure Network Interfaces
   2) Configure Link Aggregation
   3) Configure VLAN Interface
   4) Configure Default Route
   5) Configure Static Routes
   6) Configure DNS
   7) Reset Root Password
   8) Reset Configuration to Defaults
   9) Shell
   10) Reboot
   11) Shutdown
   ```

2. **Access Web UI**
   - Open a web browser on your network
   - Navigate to `http://<truenas-ip>` (e.g., `http://192.168.5.100`)
   - You may see a certificate warning (self-signed certificate) - this is normal
   - Click "Advanced" → "Proceed" to continue

3. **Login**
   - **Username**: `root`
   - **Password**: The password you set during installation
   - Click **Sign In**

### Initial Setup Wizard

TrueNAS Scale may present a setup wizard on first login:

1. **Welcome Screen**
   - Review the welcome message
   - Click **Next** to continue

2. **EULA** (if prompted)
   - Read and accept the End User License Agreement
   - Click **I Agree** or **Next**

3. **Set Up Storage** (Optional)
   - You can skip this and configure storage manually (recommended)
   - Click **Skip** to proceed

4. **Complete Setup**
   - Click **Finish** to access the main dashboard

## Storage Pool Configuration

### Create RAID-Z1 Pool

1. **Navigate to Storage**
   - Click "Storage" in the left sidebar
   - Click "Create Pool"

2. **Pool Manager**
   - **Name**: `tank`
   - **Encryption**: Leave unchecked (unless you need encryption)

3. **Data VDevs**
   - **Layout**: RAID-Z1
   - In the "Available Disks" section, you should see your 4x 1TB disks
   - Select all 4 disks (they should be labeled as sdb, sdc, sdd, sde or similar)
   - Click the arrow to move them to "Data VDevs"
   - Verify the layout shows "RAID-Z1" with 4 disks

4. **Review Configuration**
   - **Total Raw Capacity**: ~4 TB
   - **Usable Capacity**: ~3 TB (RAID-Z1 uses 1 disk for parity)
   - **Redundancy**: Can tolerate 1 disk failure

5. **Create Pool**
   - Review warnings about data loss
   - Check "Confirm" checkbox
   - Click "Create"
   - Wait for pool creation to complete

### Verify Pool Status

1. **Check Pool Health**
   - Navigate to "Storage" → "Pools"
   - Pool "tank" should show status: "ONLINE"
   - All 4 disks should show status: "ONLINE"

2. **View Pool Details**
   - Click on "tank" pool
   - Verify:
     - **Status**: Healthy
     - **Used**: Minimal (just metadata)
     - **Available**: ~3 TB
     - **VDev Type**: RAIDZ1

### Verify Disk Serial Numbers

The helper script automatically preserves disk serial numbers when importing disks. You can verify this worked correctly:

1. **Check VM Configuration**

   ```bash
   qm config 4001 | grep scsi
   ```

   You should see entries with serial numbers:

   ```
   scsi1: /dev/disk/by-id/ata-ST1000DM003-1ER162_XXXXXXXX,serial=XXXXXXXX,size=976762584K
   scsi2: /dev/disk/by-id/ata-ST1000DM003-1ER162_XXXXXXXX,serial=XXXXXXXX,size=976762584K
   scsi3: /dev/disk/by-id/ata-ST1000DM003-1ER162_XXXXXXXX,serial=XXXXXXXX,size=976762584K
   scsi4: /dev/disk/by-id/ata-ST1000DM003-1ER162_XXXXXXXX,serial=XXXXXXXX,size=976762584K
   ```

2. **Verify in TrueNAS**

   In the TrueNAS web interface, when creating a pool, each disk should show a unique serial number. If you see "None" or duplicate serials, the disk passthrough may not have worked correctly.

## Post-Installation Configuration

### Enable Services

1. **SMB/CIFS Sharing** (for Windows/macOS file sharing)
   - Navigate to "Shares" → "Windows (SMB) Shares"
   - Configure as needed for your network

2. **NFS Sharing** (for Linux/Unix file sharing)
   - Navigate to "Shares" → "Unix (NFS) Shares"
   - Configure as needed for your network

3. **iSCSI** (for block-level storage)
   - Navigate to "Shares" → "Block (iSCSI) Shares"
   - Configure as needed for your use case

### Create Datasets

Datasets are like folders within your pool with configurable properties:

1. **Navigate to Datasets**
   - Click "Datasets" in the left sidebar
   - Select "tank" pool

2. **Add Dataset**
   - Click "Add Dataset"
   - **Name**: (e.g., "media", "backups", "vms")
   - **Share Type**: SMB, NFS, or Generic
   - **Compression**: lz4 (recommended)
   - **Deduplication**: Off (unless you have specific needs)
   - Click "Save"

### Configure Network Settings

1. **Set Static IP** (recommended)
   - Navigate to "Network" → "Interfaces"
   - Edit the primary interface
   - Change from DHCP to Static
   - Set IP address, netmask, and gateway
   - Click "Save"
   - Click "Test Changes" → "Save Changes"

2. **Configure DNS**
   - Navigate to "Network" → "Global Configuration"
   - Set DNS servers (e.g., 8.8.8.8, 1.1.1.1)
   - Set default gateway
   - Click "Save"

### System Updates

1. **Check for Updates**
   - Navigate to "System" → "Update"
   - Click "Check for Updates"
   - If updates are available, click "Download" then "Apply"

### Configure Alerts

1. **Email Alerts** (optional)
   - Navigate to "System" → "Alert Settings"
   - Configure email settings for system alerts
   - Test email functionality

## Configure NFS Media Shares (optional)

This section covers setting up NFS shares for media content (music, movies, and TV shows) with proper permissions and access control.

### Create Media Dataset

1. **Navigate to Datasets**
   - Click **Datasets** in the left sidebar
   - Select the **tank** pool

2. **Create Parent Media Dataset**
   - Click **Add Dataset**
   - **Name**: `media`
   - **Share Type**: Generic
   - **Compression**: lz4 (recommended)
   - **Deduplication**: Off
   - Click **Save**

3. **Create Music Dataset**
   - Select the **tank/media** dataset
   - Click **Add Dataset**
   - **Name**: `music`
   - **Share Type**: NFS
   - **Compression**: lz4
   - Click **Save**

**Result**: You should now have a dataset at `/mnt/tank/media/music`

**Note**: Repeat steps 3 for additional media types (e.g., `movies`, `shows`) as needed.

### Create Group for Media Access Control

1. **Navigate to Groups**
   - Click **Credentials** in the left sidebar
   - Click **Local Groups**

2. **Create Music Group**
   - Click **Add**
   - **GID**: Leave blank (auto-assign) or use `3001`
   - **Name**: `media-music-full-control`
   - **Permit Sudo**: Unchecked
   - Click **Save**

**Note**: Repeat step 2 for additional media types with appropriate group names (e.g., `media-movies-full-control`, `media-shows-full-control`).

### Configure ACL for Dataset

1. **Navigate to Datasets**
   - Click **Datasets** → Select **tank/media/music**

2. **Edit Permissions**
   - Click the three dots (⋮) next to the dataset
   - Select **Edit Permissions**

3. **Set ACL Type**
   - **ACL Type**: NFSv4
   - Click **Continue** if prompted about changing ACL type

4. **Change Owner Group**
   - **Owner**: Leave as `root` (or current owner)
   - **Group**: Select `media-music-full-control`
   - This sets the primary group ownership of the dataset

5. **Configure ACL Entries**
   - Click **Add Item** to add a new ACL entry
   - **Who**: Group
   - **Group**: `media-music-full-control`
   - **ACL Type**: Allow
   - **Permissions Type**: Basic
   - **Permissions**: Full Control
   - **Flags**:
     - Check **File Inherit**
     - Check **Directory Inherit**
   - Click **Save**

6. **Apply Permissions**
   - Check **Apply permissions recursively**
   - Click **Save**

**Note**: Repeat these steps for any additional media datasets, using the corresponding full-control group for each.

### Enable NFS Service

1. **Navigate to Services**
   - Click **System Settings** → **Services**

2. **Configure NFS Service**
   - Find **NFS** in the services list
   - Click the pencil icon (✏️) to configure
   - **Number of servers**: 4 (or adjust based on expected load)
   - **Bind IP Addresses**: Leave blank for all interfaces, or select specific interface
   - **Enable NFSv4**: Checked (recommended)
   - **NFSv3 ownership model for NFSv4**: Unchecked
   - Click **Save**

3. **Start NFS Service**
   - Toggle the switch to **Start Automatically**
   - Click **Start** to start the service immediately

### Create NFS Share

1. **Navigate to Shares**
   - Click **Shares** → **Unix (NFS) Shares**

2. **Add NFS Share**
   - Click **Add**
   - **Path**: `/mnt/tank/media/music`
   - **Description**: `Media Music Share`
   - Click **Save**

3. **Configure Share Settings** (click the share to edit)
   - **Authorized Networks**: Add your network (e.g., `192.168.5.0/24`)
   - **Maproot User**: Leave blank or set to `root`
   - **Maproot Group**: Leave blank or set to `wheel`
   - **Mapall User**: Leave blank (optional - can map all NFS users to a specific user)
   - **Mapall Group**: `media-music-full-control` (optional - maps all NFS users to this group)
   - Click **Save**

**Note**: Repeat these steps for additional media datasets (e.g., movies, shows) with the appropriate paths and group mappings.

### Verify NFS Share

1. **Check NFS Service Status**
   - Navigate to **System Settings** → **Services**
   - Verify **NFS** service is **Running**

2. **Test NFS Mount from Client**

   From a Linux client on your network, test mounting the share:

   ```bash
   # Install NFS client (if not already installed)
   sudo apt install nfs-common

   # Create mount point
   sudo mkdir -p /mnt/music

   # Test mount
   sudo mount -t nfs 192.168.5.100:/mnt/tank/media/music /mnt/music

   # Verify mount
   df -h | grep music

   # Test write permissions
   sudo touch /mnt/music/test.txt
   ls -l /mnt/music/test.txt

   # Cleanup
   sudo rm /mnt/music/test.txt
   sudo umount /mnt/music
   ```

3. **Mount Share Permanently** (optional)

   To mount the NFS share permanently, add an entry to `/etc/fstab` on your client:

   ```bash
   # Add to /etc/fstab
   192.168.5.100:/mnt/tank/media/music  /mnt/music  nfs  defaults,_netdev  0  0
   ```

   Then mount it:

   ```bash
   sudo mount -a
   ```

### Security Considerations

- **Network Restriction**: Always restrict NFS shares to specific networks using **Authorized Networks**
- **Firewall**: Ensure your firewall allows NFS traffic (ports 111, 2049)
- **NFSv4**: Use NFSv4 for better security and performance
- **No Root Squash**: Be cautious with `maproot` settings - only use when necessary
- **Regular Audits**: Periodically review NFS share permissions and access logs

## Maintenance and Monitoring

### Regular Tasks

1. **Monitor Pool Health**
   - Check "Storage" → "Pools" regularly
   - All disks should show "ONLINE"

2. **SMART Tests**
   - Navigate to "Data Protection" → "SMART Tests"
   - Schedule regular short and long tests
   - Recommended: Short test weekly, Long test monthly

3. **Scrub Tasks**
   - Navigate to "Data Protection" → "Scrub Tasks"
   - Schedule monthly scrubs to verify data integrity
   - Recommended: Run on first Sunday of each month

4. **Snapshots**
   - Navigate to "Data Protection" → "Periodic Snapshot Tasks"
   - Configure automatic snapshots for important datasets
   - Recommended: Hourly, daily, and weekly snapshots with retention

### Backup Strategy

1. **Replication**
   - Use TrueNAS replication features to backup to another TrueNAS system
   - Navigate to "Data Protection" → "Replication Tasks"

2. **Cloud Sync**
   - Backup to cloud storage providers
   - Navigate to "Data Protection" → "Cloud Sync Tasks"

## Troubleshooting

### VM Won't Boot

- Verify boot order in Proxmox (Hardware → Options → Boot Order)
- Ensure CD/DVD drive is empty or set to "Do not use any media"
- Check VM logs in Proxmox

### Disks Not Visible in TrueNAS

- Verify disk passthrough in Proxmox: `qm config <vmid>`
- Check that disks are not in use by Proxmox
- Ensure you're using `/dev/disk/by-id/` paths

### Pool Creation Failed

- Verify all 4 disks are visible and not in use
- Check that disks are the same size
- Review TrueNAS logs: "System" → "Advanced" → "System Logs"

### Network Issues

- Verify network bridge configuration in Proxmox
- Check TrueNAS network settings: "Network" → "Interfaces"
- Ensure no IP conflicts on your network

### Performance Issues

- Increase VM RAM allocation (16GB+ recommended)
- Increase CPU cores (4+ recommended)
- Enable CPU host passthrough in Proxmox
- Disable memory ballooning in Proxmox

## Best Practices

1. **Regular Backups**: Always maintain backups of critical data
2. **Monitor SMART Data**: Check disk health regularly
3. **Keep Updated**: Apply TrueNAS updates regularly
4. **Document Changes**: Keep notes of configuration changes
5. **Test Restores**: Periodically test your backup/restore procedures
6. **Capacity Planning**: Keep pool usage below 80% for optimal performance
7. **Snapshot Management**: Don't let snapshots consume too much space
8. **Security**: Use strong passwords and enable 2FA if available

## Next Steps

With TrueNAS Scale successfully configured, you can:

1. **Create Shares** - Set up SMB/NFS shares for network storage
2. **Configure Applications** - Install TrueNAS Scale apps (Docker containers)
3. **Set Up Replication** - Configure backup replication to another system
4. **Integrate with Proxmox** - Use TrueNAS for VM storage via NFS/iSCSI

## Updating TrueNAS

To update TrueNAS Scale to a newer version:

1. **Access Update Interface**
   - Navigate to **System** → **Update**
   - Click **Check for Updates**

2. **Review Available Updates**
   - TrueNAS will display available updates
   - Review the changelog and release notes

3. **Apply Update**
   - Click **Download** to download the update
   - Once downloaded, click **Apply**
   - System will reboot automatically

4. **Verify Update**
   - After reboot, check **System** → **General** to verify the new version

**Note**: Always backup critical data before updating. TrueNAS updates are generally safe but it's best practice to have backups.

## References

- [TrueNAS Scale Documentation](https://www.truenas.com/docs/scale/)
- [TrueNAS Community Forums](https://forums.truenas.com/)
- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [Proxmox VE Helper Scripts](https://community-scripts.github.io/ProxmoxVE/)
- [Community Scripts Repository](https://github.com/community-scripts/ProxmoxVE)
- [TrueNAS VM Script Discussion](https://github.com/community-scripts/ProxmoxVE/discussions/11344)
