#!/bin/bash
mkdir -p archive
cp docs/read_file_user_needs.md archive/read_file_user_needs_$(date +%F).bak
echo "Validation et archivage terminés."
