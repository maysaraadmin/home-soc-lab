#!/bin/sh

# Load environment variables
. /app/env.sh

# Check if restic is installed
if ! command -v restic &> /dev/null; then
    echo "ERROR: restic is not installed"
    exit 1
fi

# Function to send alerts
send_alert() {
    local subject="$1"
    local message="$2"
    
    echo "ALERT: $subject - $message"
    
    # Send webhook if configured
    if [ -n "$WEBHOOK_URL" ]; then
        curl -s -X POST -H "Content-Type: application/json" \
             -d "{\"text\":\"*$subject*\n$message\"}" "$WEBHOOK_URL" || true
    fi
}

# Check latest backup age
check_backup_age() {
    local max_age_hours=${MAX_BACKUP_AGE_HOURS:-48}
    local latest_snapshot
    
    latest_snapshot=$(restic -r "$RESTIC_REPOSITORY" snapshots --latest 1 --json 2>/dev/null)
    
    if [ -z "$latest_snapshot" ]; then
        send_alert "Backup Check Failed" "No backup snapshots found!"
        return 1
    fi
    
    local snapshot_time
    snapshot_time=$(echo "$latest_snapshot" | jq -r '.[0].time' | cut -d. -f1)
    local snapshot_ts
    snapshot_ts=$(date -d "$snapshot_time" +%s)
    local current_ts
    current_ts=$(date +%s)
    local age_hours
    age_hours=$(( (current_ts - snapshot_ts) / 3600 ))
    
    if [ "$age_hours" -gt "$max_age_hours" ]; then
        send_alert "Backup Stale" "Latest backup is $age_hours hours old (max $max_age_hours)"
        return 1
    fi
    
    echo "Backup check passed: $age_hours hours old"
    return 0
}

# Check repository integrity
check_integrity() {
    if ! restic -r "$RESTIC_REPOSITORY" check --read-data-subset=2% > /dev/null 2>&1; then
        send_alert "Backup Integrity Check Failed" "Repository integrity check failed"
        return 1
    fi
    
    echo "Integrity check passed"
    return 0
}

# Main execution
main() {
    echo "=== Starting backup check at $(date) ==="
    
    # Check if repository is accessible
    if ! restic -r "$RESTIC_REPOSITORY" snapshots > /dev/null 2>&1; then
        send_alert "Backup Check Failed" "Cannot access backup repository"
        exit 1
    fi
    
    # Run checks
    check_backup_age
    check_integrity
    
    echo "=== Backup check completed at $(date) ==="
}

# Run main function
main "$@"
