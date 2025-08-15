#!/bin/bash

# dosthol Installation Script
# This script installs the dosthol Wake-on-LAN system for Proxmox VE

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

# Check if required files exist
check_required_files() {
    print_status "Checking required files..."
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    MISSING_FILES=()
    
    # Check for dosthold.sh
    if [[ ! -f "${SCRIPT_DIR}/dosthold.sh" ]]; then
        MISSING_FILES+=("dosthold.sh")
    fi
    
    # Check for dostholc.sh
    if [[ ! -f "${SCRIPT_DIR}/dostholc.sh" ]]; then
        MISSING_FILES+=("dostholc.sh")
    fi
    
    # Check for dosthol.service
    if [[ ! -f "${SCRIPT_DIR}/dosthol.service" ]]; then
        MISSING_FILES+=("dosthol.service")
    fi
    
    # If any files are missing, show error and exit
    if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
        print_error "The following required files are missing:"
        for file in "${MISSING_FILES[@]}"; do
            echo "  - ${file}"
        done
        echo
        print_error "Please ensure all required files are present in the same directory as this installer."
        print_error "Current directory: ${SCRIPT_DIR}"
        exit 1
    fi
    
    print_success "All required files found"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Update package list
    apt update
    
    # Install required packages
    apt install -y socat gawk vim-common
    
    print_success "Dependencies installed"
}

# Install dosthol scripts
install_scripts() {
    print_status "Installing dosthol scripts..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy scripts to /usr/local/bin
    cp "${SCRIPT_DIR}/dosthold.sh" /usr/local/bin/
    cp "${SCRIPT_DIR}/dostholc.sh" /usr/local/bin/
    
    # Make scripts executable
    chmod +x /usr/local/bin/dosthold.sh
    chmod +x /usr/local/bin/dostholc.sh
    
    print_success "Scripts installed to /usr/local/bin/"
}

# Install systemd service
install_service() {
    print_status "Installing systemd service..."
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy service file
    cp "${SCRIPT_DIR}/dosthol.service" /etc/systemd/system/
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable and start service
    systemctl enable dosthol.service
    systemctl start dosthol.service
    
    print_success "Systemd service installed and started"
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
    echo "For more information, see README.md"
}

# Main installation function
main() {
    echo "dosthol Installation Script"
    echo "=========================="
    echo
    
    check_root
    check_proxmox
    check_required_files
    install_dependencies
    install_scripts
    install_service
    configure_firewall
    test_installation
    show_post_install_info
}

# Run main function
main "$@"
