#!/bin/bash

# AMP Auto Update Script
# This script automatically updates the system and AMP components
# Run with: sudo ./amp_auto_update.sh

# Configuration
LOG_FILE="/var/log/amp_auto_update.log"
AMP_USER="amp"  # Change this to your AMP user if different
BACKUP_DIR="/opt/amp_backups"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    echo -e "${RED}ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root (use sudo)"
fi

log "=== Starting AMP Auto Update Process ==="

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to check if AMP is running
check_amp_status() {
    if pgrep -f "ampinstmgr" > /dev/null; then
        log "AMP instance manager is running"
        return 0
    else
        log "AMP instance manager is not running"
        return 1
    fi
}

# Function to stop AMP instances
stop_amp_instances() {
    log "Stopping all AMP instances..."
    if command -v ampinstmgr &> /dev/null; then
        ampinstmgr stopall
        sleep 5
        log "AMP instances stopped"
    else
        log "WARNING: ampinstmgr not found in PATH"
    fi
}

# Function to start AMP instances
start_amp_instances() {
    log "Starting AMP instances..."
    if command -v ampinstmgr &> /dev/null; then
        ampinstmgr startall
        sleep 10
        log "AMP instances started"
    else
        log "WARNING: ampinstmgr not found in PATH"
    fi
}

# Step 1: System Update
log "Step 1: Updating system packages..."
apt update
if [[ $? -eq 0 ]]; then
    log "Package list updated successfully"
else
    error_exit "Failed to update package list"
fi

# Check for available updates
UPGRADES=$(apt list --upgradable 2>/dev/null | grep -v "WARNING" | wc -l)
if [[ $UPGRADES -gt 0 ]]; then
    log "Found $UPGRADES packages to upgrade"
    
    # Perform system upgrade
    apt upgrade -y
    if [[ $? -eq 0 ]]; then
        log "System packages upgraded successfully"
    else
        error_exit "Failed to upgrade system packages"
    fi
else
    log "No system packages need upgrading"
fi

# Step 2: Stop AMP instances before update
log "Step 2: Preparing AMP for update..."
stop_amp_instances

# Step 3: Update AMP Instance Manager and Instances
log "Step 3: Updating AMP instance manager and instances..."
if command -v getamp &> /dev/null; then
    # Use getamp update for recent versions - this updates everything automatically
    log "Using getamp update method..."
    getamp update
    if [[ $? -eq 0 ]]; then
        log "AMP instance manager and instances updated successfully"
    else
        log "WARNING: getamp update failed, trying alternative method..."
        # Fallback to package manager update
        apt upgrade ampinstmgr -y
        if [[ $? -eq 0 ]]; then
            log "AMP instance manager updated via package manager"
        else
            error_exit "Failed to update AMP instance manager"
        fi
    fi
else
    log "getamp not found, using package manager update..."
    apt upgrade ampinstmgr -y
    if [[ $? -eq 0 ]]; then
        log "AMP instance manager updated via package manager"
    else
        error_exit "Failed to update AMP instance manager"
    fi
fi

# Step 4: Start AMP instances
log "Step 4: Starting AMP instances..."
start_amp_instances

# Step 5: Cleanup and verification
log "Step 5: Verifying update..."
if check_amp_status; then
    log "AMP is running successfully after update"
else
    log "WARNING: AMP may not be running properly"
fi

# Clean up old packages
log "Cleaning up old packages..."
apt autoremove -y
apt autoclean

log "=== AMP Auto Update Process Completed ==="
echo -e "${GREEN}AMP Auto Update completed successfully!${NC}"
log "Update process completed at $(date)"

# Optional: Send notification (uncomment and configure if needed)
# if command -v mail &> /dev/null; then
#     echo "AMP Auto Update completed successfully at $(date)" | mail -s "AMP Update Complete" your-email@example.com
# fi 