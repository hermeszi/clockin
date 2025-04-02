# Clockin ⏱️

bash script for automatic time tracking that logs the time the script is running to monthly CSV files.

## Installation

1. Clone this repository:
   ```bash
   git clone
   cd clockin
   ```

2. Make the script executable:
   ```bash
   chmod +x clockin.sh
   ```

## Usage

```bash
# Start tracking time
./clockin.sh start

# Check today's status
./clockin.sh status

# View monthly report
./clockin.sh report

# Show help
./clockin.sh help
```

## Configuration

Edit the following variables at the top of the script to customize behavior:

```bash
# Configuration
LOG_DIR="$HOME/clockin"    # Location of log files
INTERVAL=300               # Check interval in seconds (5 minutes)
```

## CSV Format

The generated CSV files follow this simple format:

```
Date,Login Time (minutes)
2025-04-01,480
2025-04-02,520
```
