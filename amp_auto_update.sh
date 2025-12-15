#!/bin/bash

# AMP Auto Update Script
# This script automatically updates the system and AMP components
# Run with: sudo ./amp_auto_update.sh

# Configuration
LOG_FILE="/var/log/amp_auto_update.log"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Colors for output
RED='\033[0;31m'       # Errors
GREEN='\033[0;32m'     # Success
YELLOW='\033[1;33m'    # Warnings
BLUE='\033[0;34m'      # Steps/Info
MAGENTA='\033[0;35m'   # Sub-info / minor highlights
CYAN='\033[0;36m'      # Actions / commands
NC='\033[0m'           # No Color

# Logging function
log() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root (use sudo)"
fi

echo -e "${BLUE}=== Starting AMP Auto Update Process ===${NC}"
log "=== Starting AMP Auto Update Process ==="

# Function to check if AMP is running
check_amp_status() {
    if pgrep -f "ampinstmgr" > /dev/null; then
        log "${GREEN}AMP instance manager is running${NC}"
        return 0
    else
        log "${YELLOW}AMP instance manager is not running${NC}"
        return 1
    fi
}

# Function to stop AMP instances
stop_amp_instances() {
    log "${BLUE}Stopping all AMP instances...${NC}"
    if command -v ampinstmgr &> /dev/null; then
        su -l amp -c "ampinstmgr stopall"
        sleep 5
        log "${GREEN}AMP instances stopped${NC}"
    else
        log "${YELLOW}WARNING: ampinstmgr not found in PATH${NC}"
    fi
}

# Function to start AMP instances
start_amp_instances() {
    log "${BLUE}Starting AMP instances...${NC}"
    if command -v ampinstmgr &> /dev/null; then
        su -l amp -c "ampinstmgr startall"
        sleep 10
        log "${GREEN}AMP instances started${NC}"
    else
        log "${YELLOW}WARNING: ampinstmgr not found in PATH${NC}"
    fi
}

# Ensure AMP permissions are correct
ensure_amp_perms() {
    log "${MAGENTA}Ensuring AMP permissions are correct...${NC}"
    if command -v ampinstmgr &> /dev/null; then
        ampinstmgr fixperms
        log "${GREEN}AMP permissions verified and corrected if needed${NC}"
    else
        log "${YELLOW}WARNING: ampinstmgr not found in PATH${NC}"
    fi
}

# Repair AMP repository (only if updates fail)
repair_amp_repo() {
    log "${MAGENTA}Attempting to repair CubeCoders AMP repository...${NC}"

    if command -v getamp &> /dev/null; then
        log "${CYAN}Using getamp addRepo...${NC}"
        getamp addRepo
    else
        log "${CYAN}Using legacy getamp.sh repo method...${NC}"
        bash <(wget -qO- https://cubecoders.com/getamp.sh) addRepo
    fi
}

# Step 1: System Update
log "${BLUE}Step 1: Updating system packages...${NC}"
apt update || error_exit "Failed to update package list"

UPGRADES=$(apt list --upgradable 2>/dev/null | grep -v "WARNING" | grep -v "Listing" | wc -l)
if [[ $UPGRADES -gt 0 ]]; then
    log "${YELLOW}Found $UPGRADES packages to upgrade${NC}"
    apt upgrade -y || error_exit "Failed to upgrade system packages"
    log "${GREEN}System packages upgraded successfully${NC}"
else
    log "${GREEN}No system packages need upgrading${NC}"
fi

# Step 2: Stop AMP instances before update
log "${BLUE}Step 2: Preparing AMP for update...${NC}"
stop_amp_instances

# Step 3: Update AMP Instance Manager and Instances
log "${BLUE}Step 3: Updating AMP instance manager and instances...${NC}"

UPDATE_SUCCESS=false

if command -v getamp &> /dev/null; then
    log "${CYAN}Using getamp update method...${NC}"
    if getamp update; then
        UPDATE_SUCCESS=true
        log "${GREEN}AMP instance manager and instances updated successfully${NC}"
    else
        log "${YELLOW}WARNING: getamp update failed${NC}"
    fi
fi

if [[ "$UPDATE_SUCCESS" = false ]]; then
    log "${CYAN}Attempting AMP update via package manager...${NC}"
    if apt upgrade ampinstmgr -y; then
        UPDATE_SUCCESS=true
        log "${GREEN}AMP instance manager updated via package manager${NC}"
    else
        log "${YELLOW}WARNING: AMP update via package manager failed${NC}"
    fi
fi

if [[ "$UPDATE_SUCCESS" = false ]]; then
    log "${RED}AMP update failed — repairing repo and retrying...${NC}"
    repair_amp_repo
    apt update

    if command -v getamp &> /dev/null; then
        getamp update || error_exit "AMP update failed even after repo repair"
    else
        apt upgrade ampinstmgr -y || error_exit "AMP update failed after repo repair"
    fi
fi

# Ensure permissions after update
ensure_amp_perms

# Step 4: Start AMP instances
log "${BLUE}Step 4: Starting AMP instances...${NC}"
start_amp_instances

# Step 5: Cleanup and verification
log "${BLUE}Step 5: Verifying update...${NC}"
if check_amp_status; then
    log "${GREEN}AMP is running successfully after update${NC}"
else
    log "${YELLOW}WARNING: AMP may not be running properly${NC}"
fi

# Clean up old packages
log "${MAGENTA}Cleaning up old packages...${NC}"
apt autoremove -y
apt autoclean

log "${GREEN}=== AMP Auto Update Process Completed ===${NC}"
echo -e "${GREEN}AMP Auto Update completed successfully!${NC}"
log "Update process completed at $(date)"
