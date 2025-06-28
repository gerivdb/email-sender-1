#!/bin/bash
mkdir -p archive
cp specs/read_file_spec.md archive/read_file_spec_$(date +%F).bak
echo "Spec archivée."
