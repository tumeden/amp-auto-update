# amp-auto-update

Short description

Cubecoders AMP auto update scripts to automatically update system packages and AMP (ampinstmgr/getamp) components on Debian/Ubuntu servers. Stops AMP instances, updates system and AMP software, restarts AMP instances, and logs results for unattended maintenance.

Tags: Cubecoders AMP, amp-auto-update, ampinstmgr, getamp, cron, apt, Debian, Ubuntu

What this does

- Runs apt update/upgrade for system packages.
- Stops AMP instances (uses ampinstmgr stopall when available).
- Updates AMP instance manager and instances (prefers getamp update, falls back to apt upgrade ampinstmgr).
- Restarts AMP instances (ampinstmgr startall when available).
- Cleans up packages (apt autoremove/autoclean).
- Writes human-readable logs to /var/log/amp_auto_update.log.
- Intended to be run as root (script checks for root and exits if not).

Files

- amp_auto_update.sh — main update script. Must be run as root. Logs to /var/log/amp_auto_update.log.
- setup_cron.sh — helper script that prepares the log file, ensures amp_auto_update.sh is executable, prompts for a schedule, and installs a root cron job pointing to the absolute script path. Must be run as root.

Prerequisites

- Debian/Ubuntu family (uses apt)
- sudo/root access
- Optional but recommended: ampinstmgr or getamp in PATH for AMP updates

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

3) Make the scripts executable (setup_cron.sh will also make amp_auto_update.sh executable):

```
sudo chmod 755 amp_auto_update.sh setup_cron.sh
```

4) Run the setup script to create the log file and add the cron job (interactive):

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
2. Updates apt package lists and applies upgrades (apt update && apt upgrade -y).
3. Stops AMP instances (ampinstmgr stopall) if ampinstmgr is available.
4. Attempts to update AMP via getamp update if present; otherwise uses apt upgrade ampinstmgr -y.
5. Starts AMP instances (ampinstmgr startall) if available.
6. Verifies AMP is running (pgrep -f ampinstmgr).
7. Runs apt autoremove -y and apt autoclean.
8. Logs each step to /var/log/amp_auto_update.log and prints a success message at the end.

Troubleshooting tips

- Both scripts exit if not run as root — always use sudo or run as root.
- If setup_cron.sh reports amp_auto_update.sh not found, ensure both scripts are in the same directory before running setup_cron.sh.
- If getamp or ampinstmgr are not available in PATH, amp updates will fall back to package manager behavior or log warnings. Ensure ampinstmgr/getamp are installed and reachable.
- If updates fail, inspect /var/log/amp_auto_update.log for the timestamped error messages the script writes.
- If cron doesn’t run, check system cron service status (e.g., systemctl status cron) and root crontab for the entry.
