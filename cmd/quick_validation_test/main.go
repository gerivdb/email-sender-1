package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/email-sender/tools/core/toolkit"
	"github.com/email-sender/tools/operations/validation"
	toolkitpkg "github.com/email-sender/tools/pkg/manager"
)

func main() {
	fmt.Printf("🧪 QUICK VALIDATION TEST - Phase 1.1 - Plan v49\n")
	fmt.Printf("===============================================\n\n")

	// Create temporary directory
	tempDir, err := os.MkdirTemp("", "validation_test_v49")
	if err != nil {
		fmt.Printf("❌ ERROR: Cannot create temp directory: %v\n", err)
		os.Exit(1)
	}
	defer os.RemoveAll(tempDir)

	// Test 1: StructValidator creation
	fmt.Printf("1️⃣ Testing StructValidator creation...\n")
	validator, err := validation.NewStructValidator(tempDir, nil, false)
	if err != nil {
		fmt.Printf("❌ ERROR: StructValidator creation failed: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("✅ StructValidator created successfully\n")

	// Test 2: ManagerToolkit creation
	fmt.Printf("\n2️⃣ Testing ManagerToolkit creation...\n")
	mtk, err := toolkitpkg.NewManagerToolkit(tempDir, "", false)
	if err != nil {
		fmt.Printf("❌ ERROR: ManagerToolkit creation failed: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("✅ ManagerToolkit created successfully\n")

	// Test 3: Basic operations
	fmt.Printf("\n3️⃣ Testing basic operations...\n")
	ctx := context.Background()
	opts := &toolkit.OperationOptions{
		Target: tempDir,
		Output: filepath.Join(tempDir, "test_report.json"),
		Force:  false,
	}

	operations := []toolkit.Operation{
		toolkit.ValidateStructs,
		toolkit.ResolveImports,
		toolkit.AnalyzeDeps,
		toolkit.DetectDuplicates,
	}

	successCount := 0
	for i, op := range operations {
		fmt.Printf("   Testing operation %d/%d...", i+1, len(operations))
		start := time.Now()
		err := mtk.ExecuteOperation(ctx, op, opts)
		duration := time.Since(start)

		if err != nil {
			fmt.Printf(" ❌ FAILED (%v): %v\n", duration, err)
		} else {
			fmt.Printf(" ✅ SUCCESS (%v)\n", duration)
			successCount++
		}
	}

	// Final report
	fmt.Printf("\n📋 FINAL REPORT:\n")
	fmt.Printf("----------------\n")
	fmt.Printf("Operations tested: %d\n", len(operations))
	fmt.Printf("Operations successful: %d\n", successCount)
	fmt.Printf("Success rate: %.1f%%\n", float64(successCount)/float64(len(operations))*100)

	if successCount == len(operations) {
		fmt.Printf("\n🎉 ALL TESTS PASSED! Phase 1.1 validation is 100% successful!\n")
		os.Exit(0)
	} else {
		fmt.Printf("\n⚠️ Some tests failed. Need to investigate.\n")
		os.Exit(1)
	}
}
