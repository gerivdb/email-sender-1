#!/bin/bash

BACKUP_DIR=$1

if [ -z "$BACKUP_DIR" ]; then
  echo "Usage: ./restore.sh <backup_directory>"
  exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
  echo "Error: Backup directory $BACKUP_DIR not found."
  exit 1
fi

echo "Restoring from $BACKUP_DIR..."

# Remove current Go source files and go.mod/go.sum
find . -name "*.go" -not -path "./vendor/*" -delete
rm -f go.mod go.sum

# Copy backup files
cp -r "$BACKUP_DIR"/* .

echo "Restore completed successfully."
