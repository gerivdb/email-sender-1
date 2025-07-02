package main_test

import (
	"context"
	"fmt"
	"testing"

	"email_sender/development/managers/tools/core/registry"
	"email_sender/development/managers/tools/core/toolkit"
	"email_sender/development/managers/tools/operations/analysis"
	"email_sender/development/managers/tools/operations/correction"
	"email_sender/development/managers/tools/operations/migration"
	"email_sender/development/managers/tools/operations/validation"
)

func TestToolkitOperationsIntegration(t *testing.T) {
	fmt.Println("Testing all tools for interface compliance and registry integration...")
	baseDirForTest := "." // Or t.TempDir() if files are created

	// Logger and Stats for tools that need them in constructor (or use nil if handled)
	testLogger, errLog := toolkit.NewLogger(false) // verbose false for tests
	if errLog != nil {
		t.Fatalf("Failed to create test logger: %v", errLog)
	}
	testStats := &toolkit.ToolkitStats{}

	// Tool Instances using Constructors
	validator, errVal := validation.NewStructValidator(baseDirForTest, testLogger, true) // dryRun true
	if errVal != nil {
		t.Fatalf("Failed to create StructValidator: %v", errVal)
	}

	// SyntaxChecker's constructor takes Stats
	syntaxChecker := analysis.NewSyntaxChecker(baseDirForTest, testLogger, testStats, true)

	importResolver, errImp := correction.NewImportConflictResolver(baseDirForTest, testLogger, true)
	if errImp != nil {
		t.Fatalf("Failed to create ImportConflictResolver: %v", errImp)
	}

	duplicateDetector, errDup := analysis.NewDuplicateTypeDetector(baseDirForTest, testLogger, true)
	if errDup != nil {
		t.Fatalf("Failed to create DuplicateTypeDetector: %v", errDup)
	}

	// TypeDefGenerator's constructor takes Stats
	typeDefGenerator := migration.NewTypeDefGenerator(baseDirForTest, testLogger, testStats, true)

	// NamingNormalizer's constructor takes Stats
	namingNormalizer := correction.NewNamingNormalizer(baseDirForTest, testLogger, testStats, true)

	dependencyAnalyzer, errDep := analysis.NewDependencyAnalyzer(baseDirForTest, testLogger, true)
	if errDep != nil {
		t.Fatalf("Failed to create DependencyAnalyzer: %v", errDep)
	}

	tools := []toolkit.ToolkitOperation{
		validator,
		syntaxChecker,
		importResolver,
		duplicateDetector,
		typeDefGenerator,
		namingNormalizer,
		dependencyAnalyzer,
	}

	for _, toolInstance := range tools {
		t.Run(toolInstance.String(), func(t *testing.T) {
			fmt.Printf("\nTesting tool: %s\n", toolInstance.String())
			fmt.Printf("Description: %s\n", toolInstance.GetDescription())

			metrics := toolInstance.CollectMetrics()
			fmt.Printf("Metrics keys: %v\n", getKeys(metrics))
			if metrics == nil {
				t.Errorf("CollectMetrics() returned nil for %s", toolInstance.String())
			}

			// Validate might expect a more complete setup (e.g. non-nil FileSet if used internally)
			// For tools created via constructors, they should initialize internal FileSet if needed.
			err := toolInstance.Validate(context.Background())
			fmt.Printf("Validate() error/status: %v\n", err)
			// Original test expected errors for some, so not failing test here.
		})
	}

	globalReg := registry.GetGlobalRegistry()
	if globalReg == nil {
		t.Fatal("\nERROR: Global registry is nil")
	}

	operations := globalReg.ListOperations()
	fmt.Printf("\nRegistered operations: %d\n", len(operations))

	for i, op := range operations {
		toolInstance, err := globalReg.GetTool(op)
		if err != nil {
			t.Errorf("%d. %s - ERROR getting tool from registry: %v", i+1, op, err)
		} else {
			fmt.Printf("%d. %s - Tool: %s\n", i+1, op, toolInstance.String())
		}
	}
}

// getKeys extracts the keys from a map
func getKeys(m map[string]interface{}) []string {
	if m == nil {
		return []string{}
	}
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	return keys
}
