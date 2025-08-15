#!/bin/bash

# dosthol One-Line Uninstaller
# Usage: wget -qO- https://raw.githubusercontent.com/SpotlightForBugs/dosthol-wol/master/uninstall-oneline.sh | bash

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
        print_error "Please run: sudo wget -qO- https://raw.githubusercontent.com/SpotlightForBugs/dosthol-wol/master/uninstall-oneline.sh | bash"
        exit 1
    fi
}

# Stop and disable service
stop_service() {
    print_status "Stopping dosthol service..."
    
    if systemctl is-active --quiet dosthol.service; then
        systemctl stop dosthol.service
        print_success "Service stopped"
    else
        print_warning "Service was not running"
    fi
    
    if systemctl is-enabled --quiet dosthol.service; then
        systemctl disable dosthol.service
        print_success "Service disabled"
    else
        print_warning "Service was not enabled"
    fi
}

# Remove systemd service file
remove_service_file() {
    print_status "Removing systemd service file..."
    
    if [[ -f /etc/systemd/system/dosthol.service ]]; then
        rm /etc/systemd/system/dosthol.service
        systemctl daemon-reload
        print_success "Service file removed"
    else
        print_warning "Service file not found"
    fi
}

# Remove scripts
remove_scripts() {
    print_status "Removing dosthol scripts..."
    
    if [[ -f /usr/local/bin/dosthold.sh ]]; then
        rm /usr/local/bin/dosthold.sh
        print_success "dosthold.sh removed"
    else
        print_warning "dosthold.sh not found"
    fi
    
    if [[ -f /usr/local/bin/dostholc.sh ]]; then
        rm /usr/local/bin/dostholc.sh
        print_success "dostholc.sh removed"
    else
        print_warning "dostholc.sh not found"
    fi
}

# Remove firewall rules (optional)
remove_firewall_rules() {
    print_status "Checking for firewall rules to remove..."
    
    read -p "Remove UDP port 9 firewall rule? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ufw status | grep -q "9/udp"; then
            ufw delete allow 9/udp
            print_success "UFW rule removed"
        else
            print_warning "No UFW rule found for UDP port 9"
        fi
    else
        print_status "Skipping firewall rule removal"
    fi
}

# Clean up any temporary files
cleanup_temp_files() {
    print_status "Cleaning up temporary files..."
    
    # Remove any temporary files created by dosthold.sh
    find /tmp -name "dosthol*" -type f -delete 2>/dev/null || true
    
    print_success "Temporary files cleaned up"
}

# Show uninstall summary
show_uninstall_summary() {
    echo
    print_success "dosthol uninstallation completed!"
    echo
    echo "The following components were removed:"
    echo "====================================="
    echo "✓ dosthol systemd service"
    echo "✓ dosthold.sh daemon script"
    echo "✓ dostholc.sh client script"
    echo "✓ Temporary files"
    echo
    echo "Note: Dependencies (socat, gawk, vim-common) were not removed."
    echo "If you want to remove them, run:"
    echo "  apt remove socat gawk vim-common"
    echo
    echo "To reinstall dosthol, run:"
    echo "  wget -qO- https://raw.githubusercontent.com/SpotlightForBugs/dosthol-wol/master/install-oneline.sh | bash"
}

# Main uninstall function
main() {
    echo "dosthol One-Line Uninstaller"
    echo "============================"
    echo
    
    check_root
    
    echo "This will completely remove dosthol from your system."
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Uninstallation cancelled"
        exit 0
    fi
    
    stop_service
    remove_service_file
    remove_scripts
    remove_firewall_rules
    cleanup_temp_files
    show_uninstall_summary
}

# Run main function
main "$@"
