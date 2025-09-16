# ION DTN Watchdog (ionwd)

A monitoring and recovery script for ION DTN (Delay-Tolerant Networking) that automatically detects and resolves unresponsive or locked ION instances.

## Features

- **Health Monitoring**: Continuously monitors ION DTN health using `bpadmin` commands
- **Automatic Recovery**: Detects unresponsive states and automatically restarts ION
- **Simple Logging**: Logs restart events with timestamps and reasons
- **Signal Handling**: Graceful shutdown on SIGINT/SIGTERM

## How It Works

The watchdog performs periodic health checks by sending a `list` command to `bpadmin` and expecting the "List what?:" prompt. If ION doesn't respond within the timeout period or behaves unexpectedly, the watchdog:

1. Logs the restart event with timestamp and reason
2. Stops ION using `killm`
3. Restarts ION using `ionstart`
4. Verifies the restart was successful
5. Logs the restart result

## Configuration

Edit the configuration section at the top of `ionwd.sh`:

```bash
ION_CONFIG_FILE="/home/samo/dtn/host268484800.rc"  # ION config file
LOG_DIR="/home/samo/dtn"                          # Base directory for ionwd.log
START_SLEEP=5                                     # Seconds to wait after stop/start
WATCH_INTERVAL=15                                 # Seconds between health checks
TIMEOUT=2                                         # Timeout for bpadmin responses
```

## Installation

### Download from GitHub:
```bash
git clone https://github.com/samograsic/ionwd.git
cd ionwd
```

### Or download directly:
```bash
wget https://raw.githubusercontent.com/samograsic/ionwd/master/ionwd.sh
wget https://raw.githubusercontent.com/samograsic/ionwd/master/README.md
```

## Usage

### Make the script executable:
```bash
chmod +x ionwd.sh
```

### Run manually:
```bash
./ionwd.sh
```

### Run as a background service:
```bash
nohup ./ionwd.sh > /dev/null 2>&1 &
```

### Stop the watchdog:
```bash
pkill -f ionwd.sh
```

### Run as a systemd service:

1. **Create a systemd service file:**
   ```bash
   sudo nano /etc/systemd/system/ionwd.service
   ```

2. **Add the following content (adjust paths and user as needed):**
   ```ini
   [Unit]
   Description=ION DTN Watchdog
   After=network.target
   Wants=network.target

   [Service]
   Type=simple
   User=samo
   Group=samo
   WorkingDirectory=/home/samo/dtn/ionwd
   ExecStart=/home/samo/dtn/ionwd/ionwd.sh
   Restart=always
   RestartSec=10
   StandardOutput=null
   StandardError=null

   [Install]
   WantedBy=multi-user.target
   ```
   
   **Note:** Replace `samo` with your actual username and adjust paths to match your installation.

3. **Enable and start the service:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable ionwd.service
   sudo systemctl start ionwd.service
   ```

4. **Check service status:**
   ```bash
   sudo systemctl status ionwd.service
   ```

5. **View service logs:**
   ```bash
   sudo journalctl -u ionwd.service -f
   ```

6. **Stop/disable the service:**
   ```bash
   sudo systemctl stop ionwd.service
   sudo systemctl disable ionwd.service
   ```

## Logging

- **Main log**: `$LOG_DIR/ionwd.log` - Contains timestamped watchdog activities and restart events

Example log entries:
```
2025-09-16 10:30:45 - Ion watchdog started. Monitoring every 15s (timeout 2s).
2025-09-16 10:35:20 - ION RESTART: timeout
2025-09-16 10:35:25 - Ion restart successful. Health check passed.
2025-09-16 11:42:10 - ION RESTART: unresponsive-or-not-running
2025-09-16 11:42:15 - Ion restart attempted but health check FAILED.
```

## Requirements

- ION DTN software installed and configured
- `bpadmin`, `ionstart`, and `killm` commands available in PATH
- Bash shell
- Write permissions to the configured log directory

## Troubleshooting

- **"bpadmin not found"**: Ensure ION DTN is properly installed and in PATH
- **Permission errors**: Check write permissions to log directory
- **Frequent restarts**: Review ION configuration and system resources
- **Health check failures**: Verify ION configuration file exists and is valid
- **Log file growth**: Monitor `ionwd.log` size and rotate if necessary

## License

This script is provided as-is for ION DTN monitoring and recovery purposes.