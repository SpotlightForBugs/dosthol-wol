#!/bin/bash

# dosthol One-Line Installer
# Usage: wget -qO- https://raw.githubusercontent.com/SpotlightForBugs/dosthol-wol/master/install-oneline.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        print_error "Please run: sudo wget -qO- https://raw.githubusercontent.com/SpotlightForBugs/dosthol-wol/master/install-oneline.sh | bash"
        exit 1
    fi
}

# Check if running on Proxmox VE
check_proxmox() {
    if [[ ! -f /etc/pve/version ]]; then
        print_warning "This doesn't appear to be a Proxmox VE system"
        print_warning "dosthol is designed for Proxmox VE and may not work correctly"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Proxmox VE detected"
    fi
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Update package list
    apt update
    
    # Install required packages
    apt install -y socat gawk vim-common wget
    
    print_success "Dependencies installed"
}

# Download and install dosthol
download_and_install() {
    print_status "Downloading dosthol files..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download files from GitHub
    print_status "Downloading dosthold.sh..."
    wget -q -O dosthold.sh https://raw.githubusercontent.com/SpotlightForBugs/dosthol-wol/master/dosthold.sh
    
    print_status "Downloading dostholc.sh..."
    wget -q -O dostholc.sh https://raw.githubusercontent.com/SpotlightForBugs/dosthol-wol/master/dostholc.sh
    
    print_status "Downloading dosthol.service..."
    wget -q -O dosthol.service https://raw.githubusercontent.com/SpotlightForBugs/dosthol-wol/master/dosthol.service
    
    # Verify files were downloaded
    if [[ ! -f dosthold.sh ]] || [[ ! -f dostholc.sh ]] || [[ ! -f dosthol.service ]]; then
        print_error "Failed to download required files"
        exit 1
    fi
    
    print_success "Files downloaded successfully"
    
    # Install scripts
    print_status "Installing dosthol scripts..."
    cp dosthold.sh /usr/local/bin/
    cp dostholc.sh /usr/local/bin/
    chmod +x /usr/local/bin/dosthold.sh
    chmod +x /usr/local/bin/dostholc.sh
    
    # Install systemd service
    print_status "Installing systemd service..."
    cp dosthol.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable dosthol.service
    systemctl start dosthol.service
    
    # Clean up
    cd /
    rm -rf "$TEMP_DIR"
    
    print_success "dosthol installed successfully"
}

# Configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    # Check if UFW is active
    if ufw status | grep -q "Status: active"; then
        print_status "UFW detected, adding rule for UDP port 9"
        ufw allow 9/udp
        print_success "UFW rule added"
    else
        print_warning "UFW not active. If you're using a firewall, manually allow UDP port 9"
    fi
}

# Test installation
test_installation() {
    print_status "Testing installation..."
    
    # Check if service is running
    if systemctl is-active --quiet dosthol.service; then
        print_success "dosthol service is running"
    else
        print_error "dosthol service is not running"
        systemctl status dosthol.service
        exit 1
    fi
    
    # Check if scripts are executable
    if [[ -x /usr/local/bin/dosthold.sh ]] && [[ -x /usr/local/bin/dostholc.sh ]]; then
        print_success "Scripts are executable"
    else
        print_error "Scripts are not executable"
        exit 1
    fi
    
    # Test client help
    if /usr/local/bin/dostholc.sh 2>&1 | grep -q "dostholc - The dosthol client"; then
        print_success "Client script is working"
    else
        print_error "Client script is not working"
        exit 1
    fi
}

# Show post-installation information
show_post_install_info() {
    echo
    print_success "dosthol installation completed successfully!"
    echo
    echo "Post-installation information:"
    echo "=============================="
    echo
    echo "1. Service Status:"
    echo "   systemctl status dosthol.service"
    echo
    echo "2. View Logs:"
    echo "   journalctl -u dosthol.service -f"
    echo
    echo "3. Test the client:"
    echo "   dostholc.sh -f wakeup -m 00:11:22:33:44:55 -v 1"
    echo
    echo "4. Find VM MAC addresses:"
    echo "   grep -r 'net[0-9]:' /etc/pve/local/ | grep -ioE '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'"
    echo
    echo "5. Uninstall (if needed):"
    echo "   systemctl stop dosthol.service"
    echo "   systemctl disable dosthol.service"
    echo "   rm /etc/systemd/system/dosthol.service"
    echo "   rm /usr/local/bin/dostholc.sh"
    echo "   rm /usr/local/bin/dosthold.sh"
    echo
    echo "Repository: https://github.com/SpotlightForBugs/dosthol-wol"
    echo "Documentation: https://github.com/SpotlightForBugs/dosthol-wol/blob/master/README.md"
}

# Main installation function
main() {
    echo "dosthol One-Line Installer"
    echo "========================="
    echo
    
    check_root
    check_proxmox
    install_dependencies
    download_and_install
    configure_firewall
    test_installation
    show_post_install_info
}

# Run main function
main "$@"
