#!/bin/bash

# Container name
CONTAINER_NAME="S1"

# Record the initial start time of the current interval
interval_start_time=$(date +%s)

# Counter for how many times we've rebooted in the current interval
reboot_count=0

# Print when script starts
start_datetime=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$start_datetime] Script started."

while true; do
    # Calculate elapsed time since interval_start_time
    current_time=$(date +%s)
    elapsed_seconds=$(( current_time - interval_start_time ))
    elapsed_hours=$(( elapsed_seconds / 3600 ))
    elapsed_minutes=$(( (elapsed_seconds % 3600) / 60 ))

    # Get the last 10 lines of the logs
    LOG_OUTPUT=$(docker logs "$CONTAINER_NAME" --tail 10 2>&1)

    # Count how many times the specific message appears
    count=$(grep -c "Sqlite3: Sleeping for 200ms to retry busy DB" <<< "$LOG_OUTPUT")

    # If the message appears more than 3 times, restart the container
    if [ "$count" -gt 3 ]; then
        reboot_count=$(( reboot_count + 1 ))
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Issue detected: Found $count occurrences."
        echo "Reboot #$reboot_count in this interval. The interval lasted $elapsed_hours hours, $elapsed_minutes minutes before this reboot."
        echo "Restarting $CONTAINER_NAME container..."
        docker restart "$CONTAINER_NAME"

        # Reset the interval start time and reboot count after a reboot
        interval_start_time=$(date +%s)
        reboot_count=0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] No issues detected. Found $count occurrences."
        echo "Script has been running for $elapsed_hours hours, $elapsed_minutes minutes since last start/reset."
    fi

    echo "Sleeping 5 seconds..."
    sleep 5
done
