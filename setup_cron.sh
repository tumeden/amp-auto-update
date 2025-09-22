#!/bin/bash

# AMP Auto Update Cron Setup Script
# This script helps you set up automatic AMP updates via cron

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== AMP Auto Update Cron Setup ===${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SCRIPT="$SCRIPT_DIR/amp_auto_update.sh"

# Check if update script exists
if [[ ! -f "$UPDATE_SCRIPT" ]]; then
    echo -e "${RED}Error: amp_auto_update.sh not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Make script executable
chmod +x "$UPDATE_SCRIPT"
echo -e "${GREEN}Made amp_auto_update.sh executable${NC}"

# Create log directory
mkdir -p /var/log
touch /var/log/amp_auto_update.log
chmod 644 /var/log/amp_auto_update.log
echo -e "${GREEN}Created log file: /var/log/amp_auto_update.log${NC}"

echo ""
echo -e "${YELLOW}Choose your maintenance window:${NC}"
echo ""
echo -e "${BLUE}Recommended (4:00 AM - Best for gaming servers):${NC}"
echo "1. Sunday at 4:00 AM (Lowest user activity)"
echo "2. Monday at 4:00 AM (Start of work week)"
echo "3. Tuesday at 4:00 AM (Mid-week maintenance)"
echo ""
echo -e "${BLUE}Alternative Times:${NC}"
echo "4. Wednesday at 4:00 AM (Mid-week maintenance)"
echo "5. Thursday at 4:00 AM (Before weekend gaming)"
echo "6. Sunday at 2:00 AM (Early Sunday)"
echo ""
echo -e "${BLUE}Other Options:${NC}"
echo "7. Daily at 4:00 AM (Frequent updates)"
echo "8. Monthly on 1st at 4:00 AM (Infrequent updates)"
echo "9. Custom schedule"
echo "10. Just show me the cron command"
echo ""

read -p "Enter your choice (1-10): " choice

case $choice in
    1)
        CRON_SCHEDULE="0 4 * * 0"
        SCHEDULE_DESC="Weekly on Sunday at 4:00 AM (Best for gaming servers)"
        ;;
    2)
        CRON_SCHEDULE="0 4 * * 1"
        SCHEDULE_DESC="Weekly on Monday at 4:00 AM (Start of work week)"
        ;;
    3)
        CRON_SCHEDULE="0 4 * * 2"
        SCHEDULE_DESC="Weekly on Tuesday at 4:00 AM (Mid-week maintenance)"
        ;;
    4)
        CRON_SCHEDULE="0 4 * * 3"
        SCHEDULE_DESC="Weekly on Wednesday at 4:00 AM (Mid-week)"
        ;;
    5)
        CRON_SCHEDULE="0 4 * * 4"
        SCHEDULE_DESC="Weekly on Thursday at 4:00 AM (Before weekend)"
        ;;
    6)
        CRON_SCHEDULE="0 2 * * 0"
        SCHEDULE_DESC="Weekly on Sunday at 2:00 AM (Early Sunday)"
        ;;
    7)
        CRON_SCHEDULE="0 4 * * *"
        SCHEDULE_DESC="Daily at 4:00 AM (Frequent updates)"
        ;;
    8)
        CRON_SCHEDULE="0 4 1 * *"
        SCHEDULE_DESC="Monthly on the 1st at 4:00 AM (Infrequent)"
        ;;
    9)
        echo ""
        echo -e "${YELLOW}Enter custom cron schedule:${NC}"
        echo -e "${BLUE}Format: minute hour day month weekday${NC}"
        echo -e "${BLUE}Examples:${NC}"
        echo "  0 4 * * 0    # Sunday 4:00 AM"
        echo "  0 4 * * 1    # Monday 4:00 AM"
        echo "  30 4 15 * *  # 15th of month at 4:30 AM"
        echo ""
        read -p "Cron schedule: " CRON_SCHEDULE
        SCHEDULE_DESC="Custom schedule: $CRON_SCHEDULE"
        ;;
    10)
        echo ""
        echo -e "${BLUE}To manually add the cron job, run:${NC}"
        echo "sudo crontab -e"
        echo ""
        echo -e "${BLUE}Then add one of these lines:${NC}"
        echo ""
        echo -e "${GREEN}Recommended 4:00 AM schedules:${NC}"
        echo "0 4 * * 0 $UPDATE_SCRIPT    # Sunday 4:00 AM (Best for gaming)"
        echo "0 4 * * 1 $UPDATE_SCRIPT    # Monday 4:00 AM (Start of work week)"
        echo "0 4 * * 2 $UPDATE_SCRIPT    # Tuesday 4:00 AM (Mid-week)"
        echo ""
        echo -e "${YELLOW}Alternative schedules:${NC}"
        echo "0 4 * * 3 $UPDATE_SCRIPT    # Wednesday 4:00 AM"
        echo "0 4 * * 4 $UPDATE_SCRIPT    # Thursday 4:00 AM"
        echo "0 2 * * 0 $UPDATE_SCRIPT    # Sunday 2:00 AM"
        echo ""
        echo -e "${BLUE}Other options:${NC}"
        echo "0 4 * * * $UPDATE_SCRIPT    # Daily at 4:00 AM"
        echo "0 4 1 * * $UPDATE_SCRIPT    # Monthly on 1st at 4:00 AM"
        echo ""
        echo -e "${BLUE}Cron format: minute hour day month weekday${NC}"
        echo "0 = Sunday, 1 = Monday, ..., 6 = Saturday"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Create the cron job
(crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $UPDATE_SCRIPT") | crontab -

echo ""
echo -e "${GREEN}✓ Cron job added successfully!${NC}"
echo -e "${BLUE}Schedule:${NC} $SCHEDULE_DESC"
echo -e "${BLUE}Script:${NC} $UPDATE_SCRIPT"
echo -e "${BLUE}Log file:${NC} /var/log/amp_auto_update.log"
echo ""

# Show current cron jobs
echo -e "${YELLOW}Current cron jobs:${NC}"
crontab -l | grep -v "^#" | grep -v "^$" || echo "No cron jobs found"

echo ""
echo -e "${BLUE}Maintenance Window Tips:${NC}"
echo "• 4:00 AM: Excellent choice - very low user activity"
echo "• Sunday 4:00 AM: Lowest impact, most users asleep"
echo "• Monday 4:00 AM: After weekend, before work week"
echo "• Tuesday/Wednesday 4:00 AM: Mid-week maintenance"
echo "• Thursday 4:00 AM: Before weekend gaming starts"
echo "• Avoid Friday/Saturday: Peak gaming times"

echo ""
echo -e "${BLUE}To remove the cron job later, run:${NC}"
echo "sudo crontab -e"
echo "Then delete the line with: $UPDATE_SCRIPT"

echo ""
echo -e "${BLUE}To test the script manually, run:${NC}"
echo "sudo $UPDATE_SCRIPT"

echo ""
echo -e "${GREEN}Setup complete! AMP will now update automatically.${NC}" 