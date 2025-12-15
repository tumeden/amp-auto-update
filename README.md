# amp-auto-update

This repository provides two shell scripts to automate updates for system packages and AMP instances on Debian/Ubuntu systems.

Files

- amp_auto_update.sh — main update script. Must be run as root (it checks for root and exits if not). Logs to /var/log/amp_auto_update.log.
- setup_cron.sh — helper that makes amp_auto_update.sh executable, creates the log file, and installs a root cron job. Must be run as root.

Quick summary

1) Keep both scripts in the same directory. The setup_cron.sh script uses the amp_auto_update.sh path relative to itself.
2) Run setup_cron.sh as root to create the cron job and log file.
3) You can manually run amp_auto_update.sh with sudo to test or trigger an immediate update.

Step-by-step setup (recommended)

1. Clone the repo (or copy the scripts to the machine where AMP runs):

   git clone https://github.com/tumeden/amp-auto-update.git
   cd amp-auto-update

2. (Optional) Move scripts to a stable location. Keeping both scripts together is required. Recommended location: /opt/amp-auto-update

   sudo mkdir -p /opt/amp-auto-update
   sudo cp amp_auto_update.sh setup_cron.sh /opt/amp-auto-update/
   cd /opt/amp-auto-update

3. Make the scripts executable (setup_cron will also ensure amp_auto_update.sh is executable):

   sudo chmod 755 amp_auto_update.sh setup_cron.sh

4. Run the setup script to create the log file and add the cron job (it will prompt for a schedule):

   sudo ./setup_cron.sh

   - The script will:
     • Verify amp_auto_update.sh exists in the same directory.
     • Make amp_auto_update.sh executable.
     • Create /var/log/amp_auto_update.log with permissions 644.
     • Prompt you to choose a maintenance window (or enter a custom cron schedule).
     • Add a root cron entry for the chosen schedule that runs the absolute path to amp_auto_update.sh.

5. Verify the cron job was added:

   sudo crontab -l

   You should see a line similar to:

   0 4 * * 0 /opt/amp-auto-update/amp_auto_update.sh

   (The exact schedule depends on the selection you made.)

Manual run and testing

- To run the update script immediately:

  sudo /opt/amp-auto-update/amp_auto_update.sh

- To view the log output created by the script:

  sudo tail -n 200 /var/log/amp_auto_update.log
  sudo tail -f /var/log/amp_auto_update.log  # follow live output

- To check whether AMP instance manager is running (the script uses pgrep -f "ampinstmgr"):

  pgrep -f ampinstmgr || echo "ampinstmgr not running"

Removing or editing the cron job

- To remove the cron job installed by setup_cron.sh, edit the root crontab and delete the line referencing amp_auto_update.sh:

  sudo crontab -e

  Then remove the line that contains the full path to amp_auto_update.sh, save and exit.

- To list cron jobs (as root):

  sudo crontab -l

Notes and quick troubleshooting

- Both scripts must be run as root. They check for this and will exit with an error if not run with sudo/root.
- setup_cron.sh expects amp_auto_update.sh to be in the same directory and will fail if it is not found.
- The primary log file is /var/log/amp_auto_update.log — check it first if something fails.
- The update script uses apt for system updates and either getamp or apt to update ampinstmgr. Ensure these commands are available in PATH on the server.

If you want different locations or to run the cron as a non-root user, reply with the desired user and location and I will update these instructions.
