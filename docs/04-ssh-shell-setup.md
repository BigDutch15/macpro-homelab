# SSH and Shell Setup

This guide covers setting up secure remote access and configuring the shell environment for efficient management of the Mac Pro home lab server.

## Prerequisites

- Debian 13 system installed and running
- Network connectivity established
- User account with sudo privileges
- Another computer for SSH access

## SSH Configuration

### 1. SSH Key Authentication

#### Generate SSH Keys (Client Side)

```bash
# Generate ed25519 key pair (recommended)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Or RSA 4096 if needed for compatibility
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

#### Copy Public Key to Server

```bash
# Method 1: ssh-copy-id (recommended)
ssh-copy-id -f -i ~/.ssh/id_ed25519.pub -o PreferredAuthentications=password -o PubkeyAuthentication=no username@server-ip

# Method 2: Manual copy
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no username@server-ip "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

scp -o PreferredAuthentications=password -o PubkeyAuthentication=no ~/.ssh/id_ed25519.pub username@server-ip:~/.ssh/authorized_keys

ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no username@server-ip "chmod 600 ~/.ssh/authorized_keys"
```

### 2. SSH Security Hardening

Edit `/etc/ssh/sshd_config`:

```bash
# Backup the existing config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
# Make the changes
sudo nano /etc/ssh/sshd_config
```

**Recommended Security Settings Overrides**:

```ini
PermitRootLogin no
MaxAuthTries 3
MaxSessions 2
PubkeyAuthentication yes
PasswordAuthentication no
ClientAliveInterval 300
ClientAliveCountMax 2
TCPKeepAlive yes
X11Forwarding no
Banner /etc/ssh/banner
```

#### SSH Banner

Create `/etc/ssh/banner`:

```bash
sudo nano /etc/ssh/banner
```

**Banner Content**:

```
***************************************************************************
                            AUTHORIZED ACCESS ONLY
***************************************************************************

This system is for authorized users only. Individual use of this system
and/or network without authority, or in excess of your authority, is
strictly prohibited and may be punishable under applicable federal,
state, or local law.

***************************************************************************
```

#### Test SSH Key Authentication

```bash
# Test connection (should not prompt for password)
ssh username@server-ip
```

### 3. SSH Configuration Files

#### Client Configuration (`~/.ssh/config`)

```bash
# Create SSH config file
nano ~/.ssh/config
```

**Example Configuration**:

```ini
# Mac Pro Home Lab
Host macpro
    HostName 192.168.1.10
    User username
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### 5. SSH Service Restart

```bash
# Test configuration first
sudo sshd -t

# Restart SSH service
sudo systemctl restart ssh

# Verify service is running
sudo systemctl status ssh
```

## Shell Environment Setup

### 1. Shell Selection and Installation

```bash
# Install Zsh (recommended)
sudo apt install -y zsh

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Or install Fish Shell (alternative)
sudo apt install -y fish
```

### 2. Zsh Configuration

#### .zshrc Configuration

```bash
# Backup original config
cp ~/.zshrc ~/.zshrc.backup

# Edit configuration
nano ~/.zshrc
```

**Recommended .zshrc Settings**:

```bash
# Theme
ZSH_THEME="agnoster"  # or "powerlevel10k"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# History settings
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias top='htop'

# Environment variables
export EDITOR='nano'
export TERM='xterm-256color'
```

### 3. Install Additional Plugins

```bash
# Install Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
```

### 4. Powerlevel10k Configuration

```bash
# Set theme in .zshrc
ZSH_THEME="powerlevel10k/powerlevel10k"

# Configure Powerlevel10k
p10k configure
```

### 1. SSH Connection Speed

```bash
# Add to ~/.ssh/config
Host *
    Compression yes
    CompressionLevel 6
    ServerAliveInterval 60
    ControlMaster auto
    ControlPath ~/.ssh/master-%r@%h:%p
    ControlPersist 4h
```

### 2. Shell Performance

```bash
# Add to .zshrc for faster startup
skip_global_compinit=1
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
```

## Next Steps

With SSH and shell environment properly configured, you now have secure remote access to your Mac Pro server. The next step is to install Proxmox VE for virtualization. See [Proxmox Installation](04-proxmox-installation.md) for detailed instructions.

## Additional Resources

- [OpenSSH Manual](https://man.openbsd.org/sshd)
- [Oh My Zsh Documentation](https://ohmyz.sh/)
