# dosthol Makefile
# Provides easy installation and management commands

.PHONY: help install uninstall status logs test clean

# Default target
help:
	@echo "dosthol - Do Something on LAN"
	@echo "============================"
	@echo ""
	@echo "Available targets:"
	@echo "  install   - Install dosthol system"
	@echo "  uninstall - Remove dosthol system"
	@echo "  status    - Check service status"
	@echo "  logs      - View service logs"
	@echo "  test      - Test client functionality"
	@echo "  clean     - Clean temporary files"
	@echo "  check     - Check file integrity"
	@echo "  deps      - Check system dependencies"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make check     # Check if all files are present"
	@echo "  make install   # Install the system"
	@echo "  make status    # Check if service is running"
	@echo "  make logs      # View real-time logs"

# Install dosthol
install:
	@echo "Installing dosthol..."
	@if [ $$(id -u) -ne 0 ]; then \
		echo "Error: This target requires root privileges"; \
		echo "Please run: sudo make install"; \
		exit 1; \
	fi
	@if [ ! -f dosthold.sh ] || [ ! -f dostholc.sh ] || [ ! -f dosthol.service ]; then \
		echo "Error: Required files are missing"; \
		echo "Please ensure dosthold.sh, dostholc.sh, and dosthol.service are present"; \
		exit 1; \
	fi
	@chmod +x install.sh
	@./install.sh

# Uninstall dosthol
uninstall:
	@echo "Uninstalling dosthol..."
	@if [ $$(id -u) -ne 0 ]; then \
		echo "Error: This target requires root privileges"; \
		echo "Please run: sudo make uninstall"; \
		exit 1; \
	fi
	@if [ ! -f dosthold.sh ] || [ ! -f dostholc.sh ] || [ ! -f dosthol.service ]; then \
		echo "Warning: Some source files are missing"; \
		echo "The uninstaller will attempt to remove installed components anyway"; \
	fi
	@chmod +x uninstall.sh
	@./uninstall.sh

# Check service status
status:
	@echo "Checking dosthol service status..."
	@if [ $$(id -u) -ne 0 ]; then \
		echo "Error: This target requires root privileges"; \
		echo "Please run: sudo make status"; \
		exit 1; \
	fi
	@systemctl status dosthol.service --no-pager -l

# View service logs
logs:
	@echo "Viewing dosthol service logs..."
	@if [ $$(id -u) -ne 0 ]; then \
		echo "Error: This target requires root privileges"; \
		echo "Please run: sudo make logs"; \
		exit 1; \
	fi
	@journalctl -u dosthol.service -f

# Test client functionality
test:
	@echo "Testing dosthol client..."
	@if [ -f /usr/local/bin/dostholc.sh ]; then \
		echo "Client script found, testing help function..."; \
		/usr/local/bin/dostholc.sh 2>&1 | head -10; \
	else \
		echo "Client script not found. Please install dosthol first."; \
		echo "Run: sudo make install"; \
	fi

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find /tmp -name "dosthol*" -type f -delete 2>/dev/null || true
	@echo "Temporary files cleaned"

# Show VM MAC addresses
macs:
	@echo "Finding VM MAC addresses..."
	@if [ -d /etc/pve/local ]; then \
		echo "QEMU VMs:"; \
		grep -r "net[0-9]:" /etc/pve/local/qemu-server/ 2>/dev/null | grep -ioE "([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}" | sort -u || echo "No QEMU VMs found"; \
		echo ""; \
		echo "LXC Containers:"; \
		grep -r "net[0-9]:" /etc/pve/local/lxc/ 2>/dev/null | grep -ioE "([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}" | sort -u || echo "No LXC containers found"; \
	else \
		echo "Proxmox VE configuration not found"; \
	fi

# Restart service
restart:
	@echo "Restarting dosthol service..."
	@if [ $$(id -u) -ne 0 ]; then \
		echo "Error: This target requires root privileges"; \
		echo "Please run: sudo make restart"; \
		exit 1; \
	fi
	@systemctl restart dosthol.service
	@echo "Service restarted"

# Enable service
enable:
	@echo "Enabling dosthol service..."
	@if [ $$(id -u) -ne 0 ]; then \
		echo "Error: This target requires root privileges"; \
		echo "Please run: sudo make enable"; \
		exit 1; \
	fi
	@systemctl enable dosthol.service
	@echo "Service enabled"

# Disable service
disable:
	@echo "Disabling dosthol service..."
	@if [ $$(id -u) -ne 0 ]; then \
		echo "Error: This target requires root privileges"; \
		echo "Please run: sudo make disable"; \
		exit 1; \
	fi
	@systemctl disable dosthol.service
	@echo "Service disabled"

# Check dependencies
deps:
	@echo "Checking dosthol dependencies..."
	@echo "Checking socat..."
	@if command -v socat >/dev/null 2>&1; then \
		echo "✓ socat is installed"; \
	else \
		echo "✗ socat is not installed"; \
	fi
	@echo "Checking gawk..."
	@if command -v gawk >/dev/null 2>&1; then \
		echo "✓ gawk is installed"; \
	else \
		echo "✗ gawk is not installed"; \
	fi
	@echo "Checking xxd..."
	@if command -v xxd >/dev/null 2>&1; then \
		echo "✓ xxd is installed"; \
	else \
		echo "✗ xxd is not installed"; \
	fi

# Check file integrity
check:
	@echo "Checking dosthol file integrity..."
	@echo "Checking dosthold.sh..."
	@if [ -f dosthold.sh ]; then \
		echo "✓ dosthold.sh found"; \
	else \
		echo "✗ dosthold.sh missing"; \
	fi
	@echo "Checking dostholc.sh..."
	@if [ -f dostholc.sh ]; then \
		echo "✓ dostholc.sh found"; \
	else \
		echo "✗ dostholc.sh missing"; \
	fi
	@echo "Checking dosthol.service..."
	@if [ -f dosthol.service ]; then \
		echo "✓ dosthol.service found"; \
	else \
		echo "✗ dosthol.service missing"; \
	fi
	@echo "Checking install.sh..."
	@if [ -f install.sh ]; then \
		echo "✓ install.sh found"; \
	else \
		echo "✗ install.sh missing"; \
	fi
	@echo "Checking uninstall.sh..."
	@if [ -f uninstall.sh ]; then \
		echo "✓ uninstall.sh found"; \
	else \
		echo "✗ uninstall.sh missing"; \
	fi
