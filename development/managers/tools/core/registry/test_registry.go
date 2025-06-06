// Manager Toolkit - Registry Testing Utility
// Tests tool registration and interface compliance

package registry

import (
	"github.com/email-sender/tools/core/registry"
	"github.com/email-sender/tools/core/toolkit"
	"context"
	"fmt"
)

// TestAllTools verifies that all tools implement the toolkit.ToolkitOperation interface correctly
func TestAllTools() {
	fmt.Println("Testing all tools for interface compliance...")
	
	// Create instances of all tools for testing
	validator := &StructValidator{
		BaseDir: ".",
		FileSet: nil,
		Logger:  nil,
		Stats:   &ToolkitStats{},
		DryRun:  true,
	}
	
	syntaxChecker := &SyntaxChecker{
		BaseDir: ".",
		FileSet: nil,
		Logger:  nil,
		Stats:   &ToolkitStats{},
		DryRun:  true,
	}
	
	importResolver := &ImportConflictResolver{
		BaseDir: ".",
		FileSet: nil,
		Logger:  nil,
		Stats:   &ToolkitStats{},
		DryRun:  true,
	}
	
	duplicateDetector := &DuplicateTypeDetector{
		BaseDir: ".",
		FileSet: nil,
		Logger:  nil,
		Stats:   &ToolkitStats{},
		DryRun:  true,
	}
	
	typeDefGenerator := &TypeDefGenerator{
		BaseDir: ".",
		FileSet: nil,
		Logger:  nil,
		Stats:   &ToolkitStats{},
		DryRun:  true,
	}
	
	namingNormalizer := &NamingNormalizer{
		BaseDir: ".",
		FileSet: nil,
		Logger:  nil,
		Stats:   &ToolkitStats{},
		DryRun:  true,
	}
	
	dependencyAnalyzer := &DependencyAnalyzer{
		BaseDir: ".",
		Logger:  nil,
		Stats:   &ToolkitStats{},
		DryRun:  true,
	}
	
	// Test all tools
	tools := []ToolkitOperation{
		validator,
		syntaxChecker,
		importResolver,
		duplicateDetector,
		typeDefGenerator,
		namingNormalizer,
		dependencyAnalyzer,
	}
	
	for _, tool := range tools {
		fmt.Printf("\nTesting tool: %s\n", tool.String())
		fmt.Printf("Description: %s\n", tool.GetDescription())
		
		// Test metrics
		metrics := tool.CollectMetrics()
		fmt.Printf("Metrics keys: %v\n", getKeys(metrics))
		
		// Test validation (expected to fail with these instances)
		err := tool.Validate(context.Background())
		fmt.Printf("Validation error (expected): %v\n", err)
	}
	
	// Test registry
	registry := GetGlobalRegistry()
	if registry == nil {
		fmt.Println("\nERROR: Global registry is nil")
		return
	}
	
	operations := registry.ListOperations()
	fmt.Printf("\nRegistered operations: %d\n", len(operations))
	
	for i, op := range operations {
		tool, err := registry.GetTool(op)
		if err != nil {
			fmt.Printf("%d. %s - ERROR: %v\n", i+1, op, err)
		} else {
			fmt.Printf("%d. %s - Tool: %s\n", i+1, op, tool.String())
		}
	}
}

// getKeys extracts the keys from a map
func getKeys(m map[string]interface{}) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	return keys
}

// TestRegistryFunction is a main-callable function to test all tools
func TestRegistryFunction() {
	fmt.Println("Running tool registry test...")
	TestAllTools()
}


