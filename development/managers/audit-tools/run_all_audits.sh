#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=== Audit Inventory ==="
go run audit-inventory/main.go || true
echo "=== Audit Gap Analysis ==="
go run audit-gap-analysis/main.go || true
echo "=== Standards Inventory ==="
go run standards-inventory/main.go || true
echo "=== Standards Duplication Check ==="
go run standards-duplication-check/main.go || true
echo "=== Roadmap Indexer ==="
go run roadmap-indexer/main.go || true
echo "=== Cross Doc Inventory ==="
go run cross-doc-inventory/main.go || true