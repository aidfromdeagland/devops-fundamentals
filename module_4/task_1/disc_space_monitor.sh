#!/bin/bash

WARNING_LEVEL=${1:-80}
CHECK_INTERVAL=${2:-10s}

while true
do
    DISK_USED_PERCENT=$(df --output=pcent | tail -1 | tr -d '%')
	DISK_FREE_PERCENT=$((100 - "$DISK_USED_PERCENT" ))

	if [  "$DISK_FREE_PERCENT" -lt "$WARNING_LEVEL" ]; then
  	echo "free disk space $DISK_FREE_PERCENT% is below than warning level $WARNING_LEVEL%"
fi
sleep "$CHECK_INTERVAL"

done