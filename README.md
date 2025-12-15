# amp-auto-update

Cubecoders AMP auto update script was designed to automatically update system packages and AMP components on Debian/Ubuntu servers. 
It Stops AMP instances, updates system and AMP software, restarts AMP instances, ensures permissions are correct, and logs results for unattended maintenance.

Tags: Cubecoders AMP, amp-auto-update, ampinstmgr, getamp, cron, apt, Debian, Ubuntu

What this does
- Runs apt update/upgrade for system packages.
- Stops AMP instances
- Updates AMP instance manager and instances (prefers getamp update, falls back to apt upgrade ampinstmgr).
- Restarts AMP instances
- Runs a permission check ensuring there are no permission issues caused by user error.
- Cleans up packages (apt autoremove/autoclean).
- Writes human-readable logs to /var/log/amp_auto_update.log.


Files

- `amp_auto_update.sh` — main update script. Must be run as root. (Can be run manually, or setup with a cron to run automatically on a schedule) 
- `setup_cron.sh` — helper script that sets up a cron job for the update script. Prompts  user to choose a schedule, and installs a cron job. Must be run as root.

Prerequisites

- Debian/Ubuntu (preferred) linux operating system
- sudo/root access
- Cubecoders/AMP must be installed.

Quick start (copy & paste)

1) Clone the repo

```
git clone https://github.com/tumeden/amp-auto-update.git
cd amp-auto-update
```

2) (Recommended) Move scripts to a stable location and switch to it (example: /opt/amp-auto-update)

```
sudo mkdir -p /opt/amp-auto-update
sudo cp amp_auto_update.sh setup_cron.sh /opt/amp-auto-update/
cd /opt/amp-auto-update
```

3) Make the scripts executable:

```
sudo chmod 755 amp_auto_update.sh setup_cron.sh
```

4) Run the setup script to create a cron job to automatically run the update script on a schedule (interactive):

```
sudo ./setup_cron.sh
```

What setup_cron.sh does:

- Verifies amp_auto_update.sh exists in the same directory.
- Makes amp_auto_update.sh executable.
- Creates /var/log/amp_auto_update.log (permissions 644).
- Lets you choose a recommended schedule or enter a custom cron expression.
- Adds a root crontab entry that runs the absolute path to amp_auto_update.sh.

Verify the cron (as root)

```
sudo crontab -l
```

Example cron lines you may see:

```
0 4 * * 0 /opt/amp-auto-update/amp_auto_update.sh    # Sunday 4:00 AM
0 4 * * * /opt/amp-auto-update/amp_auto_update.sh    # Daily 4:00 AM
```

Manual run (test immediately)

```
sudo /opt/amp-auto-update/amp_auto_update.sh
```

View logs

```
sudo tail -n 200 /var/log/amp_auto_update.log
sudo tail -f /var/log/amp_auto_update.log   # follow live output
```

Remove or edit the cron job

- Edit the root crontab and remove the line that runs amp_auto_update.sh:

```
sudo crontab -e
# Delete the line that contains /opt/amp-auto-update/amp_auto_update.sh, save and exit
```

- Or list root cron jobs:

```
sudo crontab -l
```

How the update script works (high level)

1. Confirms script is run as root.
2. Updates apt package lists and applies upgrades if they are available (apt update && apt upgrade -y).
3. Attempts to update AMP using getamp update if present; otherwise falls back to apt upgrade ampinstmgr -y (repairs and re-adds the AMP repository if the update fails).
4. Checks that permissions are correct (ampinstmgr fixperms)
5. Verifies AMP is running (pgrep -f ampinstmgr).
6. Runs apt autoremove -y and apt autoclean.
7. Logs each step to /var/log/amp_auto_update.log and prints a success message at the end.

Troubleshooting tips

- Both scripts exit if not run as root — always use sudo or run as root.
- If setup_cron.sh reports amp_auto_update.sh not found, ensure both scripts are in the same directory before running setup_cron.sh.
- If getamp or ampinstmgr are not available in PATH, this script will fail. Ensure AMP is installed correctly. 
- If updates fail, inspect /var/log/amp_auto_update.log for the timestamped error messages the script writes.
- If cron doesn’t run, check system cron service status (e.g., systemctl status cron) and root crontab for the entry.
