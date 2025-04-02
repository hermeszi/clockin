#!/bin/bash

# Configuration
LOG_DIR="$HOME/clockin"
INTERVAL=300  # Check every 5 minutes (300 seconds)
LOCK_FILE="/tmp/clockin.lock"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to get current month's file
get_monthly_file() {
    local year_month=$(date +"%Y-%m")
    echo "$LOG_DIR/clockin_$year_month.csv"
}

# Function to check if file exists, create if not
ensure_file_exists() {
    local file_path=$1
    if [ ! -f "$file_path" ]; then
        echo "Date,Login Time (minutes)" > "$file_path"
        echo "Created new monthly log file: $file_path"
    fi
}

# Function to check if today's entry exists
has_todays_entry() {
    local file_path=$1
    local today=$(date +"%Y-%m-%d")
    grep -q "^$today," "$file_path"
    return $?
}

# Function to add today's entry
add_todays_entry() {
    local file_path=$1
    local today=$(date +"%Y-%m-%d")
    echo "$today,0" >> "$file_path"
    echo "Added new entry for today: $today"
}

# Function to update today's entry
update_login_time() {
    local file_path=$1
    local today=$(date +"%Y-%m-%d")
    local minutes=$2
    
    # Get current minutes and add new minutes
    local current_minutes=$(grep "^$today," "$file_path" | cut -d',' -f2)
    local new_minutes=$((current_minutes + minutes))
    
    # Update the file
    sed -i "s/^$today,.*/$today,$new_minutes/" "$file_path"
    echo "Updated login time for $today to $new_minutes minutes"
}

# Check if another instance is running
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null; then
            return 1  # Process is still running
        else
            # Stale lock file (process no longer exists)
            rm -f "$LOCK_FILE"
        fi
    fi
    return 0  # No lock or stale lock removed
}

# Create lock file
create_lock() {
    echo $$ > "$LOCK_FILE"
    trap 'rm -f "$LOCK_FILE"; exit' EXIT HUP INT TERM
}

# Start tracking
start_tracking() {
    # Check if another instance is already running
    if ! check_lock; then
        echo "Error: Another instance of the login tracker is already running."
        echo "PID: $(cat "$LOCK_FILE")"
        exit 1
    fi
    
    # Create lock file
    create_lock
    
    local monthly_file=$(get_monthly_file)
    local last_update=$(date +%s)
    
    # Ensure the monthly file exists
    ensure_file_exists "$monthly_file"
    
    # Check if today's entry exists, create if not
    if ! has_todays_entry "$monthly_file"; then
        add_todays_entry "$monthly_file"
    fi
    
    echo ""
    echo "================================="
    echo "⏱️  CLOCKIN started at $(date) ⏱️"
    echo "Checking every $INTERVAL seconds. Press Ctrl+C to stop tracking." 
    echo ""
    echo "🐟     just keep swimming      🐡"
    echo "================================="
    echo ""
    
    # Continuous tracking loop
    while true; do
        sleep $INTERVAL
        
        # Calculate elapsed time since last update
        current_time=$(date +%s)
        elapsed_seconds=$((current_time - last_update))
        elapsed_minutes=$((elapsed_seconds / 60))
        
        # Only update if at least 1 minute has passed
        if [ $elapsed_minutes -ge 1 ]; then
            # Check if we've rolled over to a new month
            new_monthly_file=$(get_monthly_file)
            if [ "$new_monthly_file" != "$monthly_file" ]; then
                monthly_file=$new_monthly_file
                ensure_file_exists "$monthly_file"
                if ! has_todays_entry "$monthly_file"; then
                    add_todays_entry "$monthly_file"
                fi
            fi
            
            # Update login time
            update_login_time "$monthly_file" $elapsed_minutes
            last_update=$current_time
        fi
    done
}

# Function to display usage instructions
show_usage() {
    echo "Login Time Tracker"
    echo "Usage: $0 [command]"
    echo "Commands:"
    echo "  start    - Start tracking login time"
    echo "  status   - Show today's login time"
    echo "  report   - Show current month's report"
    echo "  help     - Show this help message"
}

# Function to show today's status
show_status() {
    local monthly_file=$(get_monthly_file)
    local today=$(date +"%Y-%m-%d")
    
    echo "⏱️  CLOCKIN Status ⏱️"
    
    if [ -f "$monthly_file" ] && has_todays_entry "$monthly_file"; then
        local minutes=$(grep "^$today," "$monthly_file" | cut -d',' -f2)
        local hours=$((minutes / 60))
        local remaining_minutes=$((minutes % 60))
        
        echo "⌛ Today's login time: $hours hours and $remaining_minutes minutes"
    else
        echo "❌ No login time recorded for today."
    fi
}

# Function to show monthly report
show_report() {
    local monthly_file=$(get_monthly_file)
    
    echo "📊 CLOCKIN Monthly Report 📊"
    
    if [ -f "$monthly_file" ]; then
        echo "Month: $(date +"%B %Y")"
        echo "================================"
        
        # Calculate total
        local total=0
        while IFS=, read -r date minutes; do
            if [ "$date" != "Date" ]; then  # Skip header
                total=$((total + minutes))
                
                # Format for display
                local hours=$((minutes / 60))
                local remaining_minutes=$((minutes % 60))
                
                printf "🗓️  %-12s %2d hours and %2d minutes\n" "$date:" $hours $remaining_minutes
            fi
        done < "$monthly_file"
        
        # Display total
        local total_hours=$((total / 60))
        local total_remaining_minutes=$((total % 60))
        echo "================================"
        echo "📈 TOTAL:       $total_hours hours and $total_remaining_minutes minutes"
    else
        echo "❌ No log file found for the current month."
    fi
}

# Main script logic
case "$1" in
    start|"")
        start_tracking
        ;;
    status)
        show_status
        ;;
    report)
        show_report
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Invalid command."
        show_usage
        exit 1
        ;;
esac

exit 0