// Manager Toolkit - Tool Registry Test
// Version: 3.0.0
// Tests for the tool registry system

package registry

import (
	"context"
	"testing"

	"EMAIL_SENDER_1/tools/core/toolkit"
	_ "EMAIL_SENDER_1/tools/operations/analysis"   // Blank import for init()
	_ "EMAIL_SENDER_1/tools/operations/correction" // Blank import for init()
	_ "EMAIL_SENDER_1/tools/operations/migration"  // Blank import for init()
	_ "EMAIL_SENDER_1/tools/operations/validation" // Blank import for init()
)

// TestGlobalRegistry tests the global registry functionality
func TestGlobalRegistry(t *testing.T) {
	// Get the global registry
	registry := GetGlobalRegistry()
	if registry == nil {
		t.Fatal("Expected non-nil global registry")
	}
	// Test operations should be registered through init() functions
	operations := GetGlobalRegistry().ListOperations()
	if len(operations) == 0 {
		t.Error("Expected at least one registered operation")
	} // Check if we have all expected operations
	expectedOps := []toolkit.Operation{
		toolkit.ValidateStructs,
		toolkit.SyntaxCheck,
		toolkit.ResolveImports,
		toolkit.DetectDuplicates,
		toolkit.TypeDefGen,
		toolkit.NormalizeNaming,
		toolkit.AnalyzeDeps,
	}

	for _, expectedOp := range expectedOps {
		found := false
		for _, op := range operations {
			if op == expectedOp {
				found = true
				break
			}
		}

		if !found {
			t.Errorf("Expected operation %s to be registered", expectedOp)
		}
	}

	// Ensure we can retrieve tools
	for _, op := range operations {
		tool, err := registry.GetTool(op)
		if err != nil {
			t.Errorf("Failed to get tool for operation %s: %v", op, err)
			continue
		}

		// Check that the tool implements the required methods
		if tool.String() == "" {
			t.Errorf("Tool for operation %s has empty String() value", op)
		}

		if tool.GetDescription() == "" {
			t.Errorf("Tool for operation %s has empty GetDescription() value", op)
		}

		// Validate should not error with default values (since we're using default instances)
		ctx := context.Background()
		err = tool.HealthCheck(ctx)
		if err == nil {
			// This is expected to fail since default tools don't have valid BaseDir
			t.Errorf("Expected HealthCheck to fail for default instance of %s", op)
		}
	}
}

// TestRegisterGlobalTool tests the RegisterGlobalTool function
func TestRegisterGlobalTool(t *testing.T) {
	// Create a mock tool
	mockTool := &MockTool{name: "MockTool"}
	// Register the tool
	mockOp := toolkit.Operation("mock-op")
	err := RegisterGlobalTool(mockOp, mockTool)
	if err != nil {
		t.Fatalf("Failed to register mock tool: %v", err)
	}

	// Try to retrieve the tool
	registry := GetGlobalRegistry()
	tool, err := registry.GetTool(mockOp)
	if err != nil {
		t.Errorf("Failed to get registered mock tool: %v", err)
	}

	// Check that it's the same tool
	if tool.String() != "MockTool" {
		t.Errorf("Expected tool name 'MockTool', got '%s'", tool.String())
	}
}

// MockTool implements toolkit.ToolkitOperation for testing
type MockTool struct {
	name string
}

func (m *MockTool) Execute(ctx context.Context, options *toolkit.OperationOptions) error {
	return nil
}

func (m *MockTool) Validate(ctx context.Context) error {
	return nil
}

func (m *MockTool) CollectMetrics() map[string]interface{} {
	return map[string]interface{}{"tool": m.name}
}

func (m *MockTool) HealthCheck(ctx context.Context) error {
	return nil
}

func (m *MockTool) String() string {
	return m.name
}

func (m *MockTool) GetDescription() string {
	return "Mock tool for testing"
}

func (m *MockTool) Stop(ctx context.Context) error {
	return nil
}
