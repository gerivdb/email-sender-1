#!/bin/bash

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="./backups/dependency-manager_$TIMESTAMP"

echo "Creating backup in $BACKUP_DIR..."

mkdir -p "$BACKUP_DIR"

# Copy Go source files
find . -name "*.go" -not -path "./vendor/*" -exec cp --parents {} "$BACKUP_DIR" \;

# Copy go.mod and go.sum
cp go.mod "$BACKUP_DIR"/go.mod
cp go.sum "$BACKUP_DIR"/go.sum

echo "Backup created successfully."
echo "To restore, run: cp -r $BACKUP_DIR/* ./"
