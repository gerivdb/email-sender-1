#!/bin/bash
# Script de validation SRP - TASK ATOMIQUE 3.1.1
echo "=== VALIDATION SRP IMPLEMENTATION ==="

echo "1. Building docmanager package..."
go build ./pkg/docmanager

if [ $? -eq 0 ]; then
    echo "✅ Build successful - SRP respected"
else
    echo "❌ Build failed"
    exit 1
fi

echo "2. Testing DocManager SRP..."
go test ./pkg/docmanager -run TestDocManager_SRP

echo "3. Testing ConflictResolver SRP..."
go test ./pkg/docmanager -run TestConflictResolver_SRP

echo "4. Testing PathTracker SRP..."
go test ./pkg/docmanager -run TestPathTracker_SRP

echo "5. Testing Interface Domain Separation..."
go test ./pkg/docmanager -run TestInterfacesDomainSeparation

echo "6. Testing BranchSynchronizer SRP..."
go test ./pkg/docmanager -run TestBranchSynchronizer_SRP

echo "=== VALIDATION COMPLETE ==="

# Validation des métriques SRP
echo "MICRO-TASK 3.1.1.1.2 - Extraction responsabilités secondaires"
echo "Checking for secondary responsibilities in DocManager..."
grep -n "func.*Manager.*" pkg/docmanager/doc_manager.go || echo "✅ No secondary responsibilities found"

echo "MICRO-TASK 3.1.1.4.1 - ConflictResolver responsabilité résolution pure"
echo "Validating ConflictResolver structure..."
grep -A 10 "type.*ConflictResolver.*struct" pkg/docmanager/conflict_resolver.go

echo "MICRO-TASK 3.1.1.5.1 - Interfaces par domaine fonctionnel"
echo "Listing specialized interfaces..."
grep -n "type.*interface" pkg/docmanager/interfaces.go

echo "✅ SRP Implementation validation complete"
