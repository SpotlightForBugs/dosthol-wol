# dosthol - Do Something on LAN

A Wake-on-LAN system for remote management of Proxmox VE virtual machines and containers.

## Overview

dosthol consists of two main components:
- **dostholc.sh** - Client script for sending remote commands
- **dosthold.sh** - Daemon script that runs on the Proxmox host to receive and process commands

## Features

- Wake up virtual machines and containers
- Shutdown, power off, suspend, resume, and reset VMs
- Support for both QEMU VMs and LXC containers
- Broadcast and unicast packet support
- Verbose logging and debugging options

## Installation

### Prerequisites

- Proxmox VE 4.x or later
- `socat` package installed
- `gawk` (GNU awk) installed
- `xxd` utility (usually part of vim-common)

### Install Dependencies

```bash
apt update
apt install socat gawk vim-common
```

### Install dosthol

1. Copy the scripts to the appropriate locations:
```bash
cp dosthold.sh /usr/local/bin/
cp dostholc.sh /usr/local/bin/
chmod +x /usr/local/bin/dosthold.sh
chmod +x /usr/local/bin/dostholc.sh
```

2. Install the systemd service:
```bash
cp dosthol.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable dosthol.service
systemctl start dosthol.service
```

3. Verify installation:
```bash
systemctl status dosthol.service
```

## Usage

### Client Usage (dostholc.sh)

```bash
dostholc.sh -f FUNCTION -m MAC_ADDRESS [OPTIONS]
```

#### Parameters:
- `-f, --function`: Command to execute
  - `wakeup` - Start the VM/container
  - `shutdown` - Gracefully shutdown the VM/container
  - `poweroff` - Force power off the VM/container
  - `suspend` - Suspend the VM/container
  - `resume` - Resume the VM/container
  - `reset` - Reset the VM/container (QEMU only)

- `-m, --mac`: Target MAC address (format: 11:22:33:44:55:66)
- `-v, --verbose`: Verbose output (0=quiet, 1=verbose, default=0)
- `-i, --ip`: Target IP address or subnet (default: 255.255.255.255 for broadcast)

#### Examples:

```bash
# Wake up a VM with MAC 00:11:22:33:44:55
dostholc.sh -f wakeup -m 00:11:22:33:44:55

# Shutdown a VM with verbose output
dostholc.sh -f shutdown -m 00:11:22:33:44:55 -v 1

# Send command to specific subnet
dostholc.sh -f resume -m 00:11:22:33:44:55 -i 192.168.1.255
```

### Finding MAC Addresses

To find the MAC addresses of your VMs:

```bash
# For QEMU VMs
grep -r "net[0-9]:" /etc/pve/local/qemu-server/ | grep -ioE "([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}"

# For LXC containers
grep -r "net[0-9]:" /etc/pve/local/lxc/ | grep -ioE "([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}"
```

## Configuration

### Network Configuration

The daemon listens on UDP port 9. Ensure this port is accessible from your client machines.

### Firewall Configuration

If using a firewall, allow UDP port 9:

```bash
# UFW
ufw allow 9/udp

# iptables
iptables -A INPUT -p udp --dport 9 -j ACCEPT
```

### Logging

The daemon logs to syslog. View logs with:

```bash
journalctl -u dosthol.service -f
```

## Troubleshooting

### Common Issues

1. **Service not starting**: Check if socat is installed
2. **Commands not working**: Verify MAC address format and VM existence
3. **Network issues**: Ensure UDP port 9 is not blocked by firewall

### Debug Mode

Enable verbose output on the client:
```bash
dostholc.sh -f wakeup -m 00:11:22:33:44:55 -v 1
```

### Check Service Status

```bash
systemctl status dosthol.service
journalctl -u dosthol.service --no-pager -l
```

## Security Considerations

- The system uses UDP broadcast packets which are not encrypted
- MAC addresses can be spoofed
- Consider network segmentation for production use
- Restrict access to the Proxmox host network

## License

Distributed under the terms of the GNU General Public License v2

## Author

Oliver Jaksch <proxmox-forum@com-in.de>

## Changelog

### Client (dostholc.sh)
- v0.5 - nothing changed
- v0.4 - nothing changed
- v0.3 (2016-03-11) - Parameter parsing, help extended, some beautifyings
- v0.2 (2016-03-07) - Renamed dosthol to dosthold, created client dostholc, finished more commands, turned to socat
- v0.1 (2016-03-06) - Initial work; starting virtual machines per wake-on-lan works

### Daemon (dosthold.sh)
- v0.5 (2019-03-17) - Beautify shell execs, limit grep to find only one result (thanks cheffe)
- v0.4 (2017-01-03) - Expanded Resume: Send a key before resume (Windows Standby)
- v0.3 (2016-03-11) - Fixed typo in dosthol.service
- v0.2 (2016-03-07) - Renamed dosthol to dosthold, created client dostholc, finished more commands, turned to socat
- v0.1 (2016-03-06) - Initial work; starting virtual machines per wake-on-lan works
