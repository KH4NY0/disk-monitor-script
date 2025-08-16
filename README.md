# Disk Space Monitor Script

A simple Bash script that checks your system's disk space usage and alerts if it goes above a defined threshold.

## Overview
Running out of disk space can break deployments, stop services, and cause data loss.  
This script checks your system’s disk usage, compares it to a configurable threshold, and triggers alerts or backups, so you can act before it’s too late.


## Features
-  Monitors specific partitions or directories
-  Customizable usage threshold
-  Automatable via cron or systemd timers
-  Optional backup before cleanup
-  Detailed logging


## Prerequisites / Requirements
- OS compatibility (Linux, macOS, WSL)
- Bash
- Required tools: tar, du, find, cron (if automating)

## Installation

```bash
git clone https://github.com/KH4NY0/disk-space-monitor.git
cd disk-space-monitor
chmod +x check_disk.sh
```

## Usage
### Run once manually
```bash
./backup.sh
```

### Dry run (no backup created)
```bash
./backup.sh --dry-run
```

### Automate via cron (daily at 2AM)
```bash
0 2 * * * /path/to/backup.sh >> /var/log/backup_cron.log 2>&1
```

