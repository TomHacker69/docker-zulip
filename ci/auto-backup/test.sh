#!/bin/bash

set -eux
set -o pipefail

# Verify supervisor is running cron
"${docker[@]:?}" exec zulip supervisorctl status cron | grep -q RUNNING

# Verify the autobackup crontab exists and specifies the root user
"${docker[@]}" exec zulip grep -qE "^\* \* \* \* \* root " /etc/cron.d/autobackup

# Wait for an automated backup to be created by cron (runs every minute)
for _ in $(seq 1 70); do
    if [ "$("${docker[@]}" exec zulip ls /data/backups/ 2>/dev/null | wc -l)" -ge 1 ]; then
        break
    fi
    sleep 1
done

if [ "$("${docker[@]}" exec zulip ls /data/backups/ | wc -l)" -lt 1 ]; then
    echo "FAIL: No auto backup created in /data/backups/"
    exit 1
fi
