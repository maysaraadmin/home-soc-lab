#!/bin/sh
set -e

# Load environment variables
if [ -f /etc/restic/env.sh ]; then
    . /etc/restic/env.sh
fi

# Initialize the repository if it doesn't exist
if ! restic -r $RESTIC_REPOSITORY snapshots 2>&1 >/dev/null; then
    echo "Initializing restic repository..."
    restic init
fi

# Function to perform backup
perform_backup() {
    echo "Starting backup at $(date)"
    
    # Backup Docker volumes
    for volume in $(docker volume ls -q); do
        echo "Backing up volume: $volume"
        docker run --rm -v $volume:/data -v /backup:/backup alpine tar czf /backup/$volume-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
    done

    # Backup using restic
    restic backup \
        --exclude-file=/etc/restic/excludes.txt \
        /source/
    
    # Clean up old backups
    restic forget \
        --prune \
        --keep-daily 7 \
        --keep-weekly 4 \
        --keep-monthly 12 \
        --keep-yearly 3
    
    # Check repository integrity
    restic check
    
    echo "Backup completed at $(date)"
}

# If CRON_TIME is set, run in cron mode
if [ -n "$BACKUP_CRON" ]; then
    LOGFIFO='/var/log/cron.fifo'
    if [[ ! -e "$LOGFIFO" ]]; then
        mkfifo "$LOGFIFO"
    fi
    
    CRON_ENV=""
    if [ -n "$RESTIC_REPOSITORY" ]; then
        CRON_ENV="$CRON_ENV\nRESTIC_REPOSITORY=$RESTIC_REPOSITORY"
    fi
    
    if [ -n "$RESTIC_PASSWORD" ]; then
        CRON_ENV="$CRON_ENV\nRESTIC_PASSWORD=$RESTIC_PASSWORD"
    fi
    
    echo -e "$BACKUP_CRON /scripts/backup.sh >> $LOGFIFO 2>&1\n$CRON_ENV\n" > /etc/cron.d/backup-cron
    chmod 0644 /etc/cron.d/backup-cron
    
    # Start cron in the background
    cron
    
    # Tail the output to the container logs
    tail -f "$LOGFIFO"
else
    # Run backup once
    perform_backup
fi
