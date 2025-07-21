#!/bin/sh
set -e

# Load environment variables
if [ -f /etc/restic/env.sh ]; then
    . /etc/restic/env.sh
fi

# Function to verify backup integrity
verify_backup() {
    echo "Starting backup verification at $(date)"
    
    # Check repository integrity
    if ! restic check; then
        echo "ERROR: Backup verification failed!"
        send_alert "Backup verification failed!"
        return 1
    fi
    
    # Verify the latest snapshot
    LATEST_SNAPSHOT=$(restic snapshots --latest 1 --json | jq -r '.[0].id')
    if [ -z "$LATEST_SNAPSHOT" ]; then
        echo "ERROR: No snapshots found!"
        send_alert "No backup snapshots found!"
        return 1
    fi
    
    echo "Verifying snapshot: $LATEST_SNAPSHOT"
    if ! restic check --with-cache --read-data-subset=5%; then
        echo "ERROR: Data verification failed for snapshot $LATEST_SNAPSHOT"
        send_alert "Data verification failed for snapshot $LATEST_SNAPSHOT"
        return 1
    fi
    
    echo "Backup verification completed successfully at $(date)"
    return 0
}

# Function to send alerts
send_alert() {
    local message="$1"
    echo "ALERT: $message"
    
    # Send alert via webhook if configured
    if [ -f "/app/alert-webhook.txt" ]; then
        WEBHOOK_URL=$(cat /app/alert-webhook.txt)
        if [ -n "$WEBHOOK_URL" ]; then
            curl -s -X POST -H "Content-Type: application/json" -d "{\"text\":\"$message\"}" "$WEBHOOK_URL" || true
        fi
    fi
}

# Main execution
if [ -n "$VERIFY_CRON" ]; then
    # Run in cron mode
    LOGFIFO='/var/log/verify-cron.fifo'
    if [[ ! -e "$LOGFIFO" ]]; then
        mkfifo "$LOGFIFO"
    fi
    
    echo -e "$VERIFY_CRON /scripts/verify-backup.sh >> $LOGFIFO 2>&1\n" > /etc/cron.d/verify-cron
    chmod 0644 /etc/cron.d/verify-cron
    
    # Start cron in the background
    cron
    
    # Tail the output to the container logs
    tail -f "$LOGFIFO"
else
    # Run verification once
    verify_backup
fi
