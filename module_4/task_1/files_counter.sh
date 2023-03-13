#!/bin/bash
DIRECTORIES_TO_CHECK=("$@")

for DIRECTORY in "${DIRECTORIES_TO_CHECK[@]}"
do
    FILES_COUNT=$(find "$DIRECTORY" -type f | wc -l)
    echo "$CURRENT_PATH: $FILES_COUNT"
done
