package validation_test

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

// Simple standalone test runner for validation
func main() {
	fmt.Printf("🧪 VALIDATION TEST RUNNER - Phase 1.1\n")
	fmt.Printf("=====================================\n\n")

	// Create temp directory for tests
	tempDir, err := os.MkdirTemp("", "validation_test_v49")
	if err != nil {
		fmt.Printf("❌ ERROR: Cannot create temp directory: %v\n", err)
		os.Exit(1)
	}
	defer os.RemoveAll(tempDir)

	totalTests := 0
	passedTests := 0

	// Test 1: StructValidator creation
	fmt.Printf("1️⃣ TEST: StructValidator Creation\n")
	fmt.Printf("----------------------------------\n")
	totalTests++

	validator, err := validation.NewStructValidator(tempDir, nil, false)
	if err != nil {
		fmt.Printf("❌ FAILED: StructValidator creation failed: %v\n", err)
	} else {
		fmt.Printf("✅ PASSED: StructValidator created successfully\n")
		passedTests++
	}

	// Test 2: Validate method
	fmt.Printf("\n2️⃣ TEST: StructValidator.Validate()\n")
	fmt.Printf("-----------------------------------\n")
	totalTests++

	if validator != nil {
		if err := validator.Validate(context.Background()); err != nil {
			fmt.Printf("❌ FAILED: Validate method failed: %v\n", err)
		} else {
			fmt.Printf("✅ PASSED: Validate method successful\n")
			passedTests++
		}
	}

	// Test 3: CollectMetrics method
	fmt.Printf("\n3️⃣ TEST: StructValidator.CollectMetrics()\n")
	fmt.Printf("------------------------------------------\n")
	totalTests++

	if validator != nil {
		metrics := validator.CollectMetrics()
		if metrics == nil {
			fmt.Printf("❌ FAILED: CollectMetrics returned nil\n")
		} else {
			fmt.Printf("✅ PASSED: CollectMetrics returned data\n")
			passedTests++
		}
	}

	// Test 4: HealthCheck method
	fmt.Printf("\n4️⃣ TEST: StructValidator.HealthCheck()\n")
	fmt.Printf("---------------------------------------\n")
	totalTests++

	if validator != nil {
		if err := validator.HealthCheck(context.Background()); err != nil {
			fmt.Printf("❌ FAILED: HealthCheck failed: %v\n", err)
		} else {
			fmt.Printf("✅ PASSED: HealthCheck successful\n")
			passedTests++
		}
	}

	// Test 5: ManagerToolkit creation
	fmt.Printf("\n5️⃣ TEST: ManagerToolkit Creation\n")
	fmt.Printf("---------------------------------\n")
	totalTests++

	mtk, err := toolkitpkg.NewManagerToolkit(tempDir, "", false)
	if err != nil {
		fmt.Printf("❌ FAILED: ManagerToolkit creation failed: %v\n", err)
	} else {
		fmt.Printf("✅ PASSED: ManagerToolkit created successfully\n")
		passedTests++
	}

	// Test 6-9: ExecuteOperation tests
	if mtk != nil {
		operations := []toolkit.Operation{
			toolkit.ValidateStructs,
			toolkit.ResolveImports,
			toolkit.AnalyzeDeps,
			toolkit.DetectDuplicates,
		}

		operationNames := map[toolkit.Operation]string{
			toolkit.ValidateStructs:  "ValidateStructs",
			toolkit.ResolveImports:   "ResolveImports",
			toolkit.AnalyzeDeps:      "AnalyzeDeps",
			toolkit.DetectDuplicates: "DetectDuplicates",
		}

		ctx := context.Background()
		opts := &toolkit.OperationOptions{
			Target: tempDir,
			Output: filepath.Join(tempDir, "test_report.json"),
			Force:  false,
		}

		for i, op := range operations {
			testNum := i + 6
			fmt.Printf("\n%d️⃣ TEST: ExecuteOperation - %s\n", testNum, operationNames[op])
			fmt.Printf("---------------------------------------------------\n")
			totalTests++

			startTime := time.Now()
			err := mtk.ExecuteOperation(ctx, op, opts)
			duration := time.Since(startTime)

			if err != nil {
				fmt.Printf("❌ FAILED: ExecuteOperation %s failed: %v\n", operationNames[op], err)
			} else {
				fmt.Printf("✅ PASSED: ExecuteOperation %s successful in %v\n", operationNames[op], duration)
				passedTests++
			}
		}

		// Test 10: Metrics verification
		fmt.Printf("\n🔟 TEST: Metrics Verification\n")
		fmt.Printf("-----------------------------\n")
		totalTests++

		fmt.Printf("- Operations executed: %d\n", mtk.Stats.OperationsExecuted)
		fmt.Printf("- Files analyzed: %d\n", mtk.Stats.FilesAnalyzed)
		fmt.Printf("- Files processed: %d\n", mtk.Stats.FilesProcessed)
		fmt.Printf("- Execution time: %v\n", mtk.Stats.ExecutionTime)

		if mtk.Stats.OperationsExecuted > 0 {
			fmt.Printf("✅ PASSED: Metrics collected successfully\n")
			passedTests++
		} else {
			fmt.Printf("❌ FAILED: No operations recorded in metrics\n")
		}
	}

	// Final report
	fmt.Printf("\n📋 FINAL REPORT\n")
	fmt.Printf("===============\n")
	fmt.Printf("Tests passed: %d/%d (%.1f%%)\n", passedTests, totalTests, float64(passedTests)/float64(totalTests)*100)

	if passedTests == totalTests {
		fmt.Printf("✅ ALL TESTS PASSED! 🎉\n")
		fmt.Printf("🚀 System is ready for Phase 2!\n")
		os.Exit(0)
	} else {
		fmt.Printf("⚠️ Some tests failed. Success rate: %d/%d\n", passedTests, totalTests)
		os.Exit(1)
	}
}
