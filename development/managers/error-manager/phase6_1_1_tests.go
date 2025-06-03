// Phase 6.1.1 - Tests unitaires pour ErrorEntry, validation, catalogage
// Tests complets pour les composants du gestionnaire d'erreurs

package errormanager

import (
	"encoding/json"
	"strings"
	"testing"
	"time"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestErrorEntry_Creation tests basic ErrorEntry creation
func TestErrorEntry_Creation(t *testing.T) {
	tests := []struct {
		name     string
		entry    ErrorEntry
		valid    bool
		errorMsg string
	}{
		{
			name: "Valid ErrorEntry",
			entry: ErrorEntry{
				ID:             "123e4567-e89b-12d3-a456-426614174000",
				Timestamp:      time.Now(),
				Message:        "Test error message",
				StackTrace:     "main.go:10\nhandler.go:25",
				Module:         "test-module",
				ErrorCode:      "ERR_TEST_001",
				ManagerContext: "test context",
				Severity:       "medium",
			},
			valid: true,
		},
		{
			name: "Empty ID",
			entry: ErrorEntry{
				ID:             "",
				Timestamp:      time.Now(),
				Message:        "Test error",
				Module:         "test-module",
				ErrorCode:      "ERR_001",
				Severity:       "low",
			},
			valid:    false,
			errorMsg: "ID cannot be empty",
		},
		{
			name: "Zero Timestamp",
			entry: ErrorEntry{
				ID:        "123e4567-e89b-12d3-a456-426614174000",
				Timestamp: time.Time{},
				Message:   "Test error",
				Module:    "test-module",
				ErrorCode: "ERR_001",
				Severity:  "low",
			},
			valid:    false,
			errorMsg: "Timestamp cannot be zero",
		},
		{
			name: "Empty Message",
			entry: ErrorEntry{
				ID:        "123e4567-e89b-12d3-a456-426614174000",
				Timestamp: time.Now(),
				Message:   "",
				Module:    "test-module",
				ErrorCode: "ERR_001",
				Severity:  "low",
			},
			valid:    false,
			errorMsg: "Message cannot be empty",
		},
		{
			name: "Empty Module",
			entry: ErrorEntry{
				ID:        "123e4567-e89b-12d3-a456-426614174000",
				Timestamp: time.Now(),
				Message:   "Test error",
				Module:    "",
				ErrorCode: "ERR_001",
				Severity:  "low",
			},
			valid:    false,
			errorMsg: "Module cannot be empty",
		},
		{
			name: "Empty ErrorCode",
			entry: ErrorEntry{
				ID:        "123e4567-e89b-12d3-a456-426614174000",
				Timestamp: time.Now(),
				Message:   "Test error",
				Module:    "test-module",
				ErrorCode: "",
				Severity:  "low",
			},
			valid:    false,
			errorMsg: "ErrorCode cannot be empty",
		},
		{
			name: "Invalid Severity",
			entry: ErrorEntry{
				ID:        "123e4567-e89b-12d3-a456-426614174000",
				Timestamp: time.Now(),
				Message:   "Test error",
				Module:    "test-module",
				ErrorCode: "ERR_001",
				Severity:  "invalid",
			},
			valid:    false,
			errorMsg: "Invalid severity level",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateErrorEntry(tt.entry)
			
			if tt.valid {
				assert.NoError(t, err, "Expected valid ErrorEntry")
			} else {
				assert.Error(t, err, "Expected invalid ErrorEntry")
				assert.Contains(t, err.Error(), tt.errorMsg, "Error message should match")
			}
		})
	}
}

// TestErrorEntry_JSONSerialization tests JSON serialization/deserialization
func TestErrorEntry_JSONSerialization(t *testing.T) {
	originalEntry := ErrorEntry{
		ID:             "123e4567-e89b-12d3-a456-426614174000",
		Timestamp:      time.Date(2025, 6, 4, 12, 0, 0, 0, time.UTC),
		Message:        "Test error message",
		StackTrace:     "main.go:10\nhandler.go:25",
		Module:         "dependency-manager",
		ErrorCode:      "ERR_DEP_001",
		ManagerContext: `{"operation": "install", "package": "testpkg"}`,
		Severity:       "high",
	}

	// Test serialization
	jsonData, err := json.Marshal(originalEntry)
	require.NoError(t, err, "JSON serialization should succeed")

	// Verify JSON contains expected fields
	jsonStr := string(jsonData)
	assert.Contains(t, jsonStr, "123e4567-e89b-12d3-a456-426614174000")
	assert.Contains(t, jsonStr, "Test error message")
	assert.Contains(t, jsonStr, "dependency-manager")
	assert.Contains(t, jsonStr, "ERR_DEP_001")
	assert.Contains(t, jsonStr, "high")

	// Test deserialization
	var deserializedEntry ErrorEntry
	err = json.Unmarshal(jsonData, &deserializedEntry)
	require.NoError(t, err, "JSON deserialization should succeed")

	// Verify fields match
	assert.Equal(t, originalEntry.ID, deserializedEntry.ID)
	assert.Equal(t, originalEntry.Message, deserializedEntry.Message)
	assert.Equal(t, originalEntry.Module, deserializedEntry.Module)
	assert.Equal(t, originalEntry.ErrorCode, deserializedEntry.ErrorCode)
	assert.Equal(t, originalEntry.Severity, deserializedEntry.Severity)
	assert.Equal(t, originalEntry.ManagerContext, deserializedEntry.ManagerContext)
	
	// Time comparison with proper formatting
	assert.True(t, originalEntry.Timestamp.Equal(deserializedEntry.Timestamp))
}

// TestValidateErrorEntry_ComprehensiveSeverityTests tests all severity levels
func TestValidateErrorEntry_ComprehensiveSeverityTests(t *testing.T) {
	baseEntry := ErrorEntry{
		ID:             "123e4567-e89b-12d3-a456-426614174000",
		Timestamp:      time.Now(),
		Message:        "Test error",
		Module:         "test-module",
		ErrorCode:      "ERR_001",
		ManagerContext: "test context",
	}

	validSeverities := []string{"low", "medium", "high", "critical"}
	for _, severity := range validSeverities {
		t.Run("Valid_"+severity, func(t *testing.T) {
			entry := baseEntry
			entry.Severity = severity
			err := ValidateErrorEntry(entry)
			assert.NoError(t, err, "Severity '%s' should be valid", severity)
		})
	}

	invalidSeverities := []string{"", "invalid", "LOW", "MEDIUM", "error", "warning", "info"}
	for _, severity := range invalidSeverities {
		t.Run("Invalid_"+severity, func(t *testing.T) {
			entry := baseEntry
			entry.Severity = severity
			err := ValidateErrorEntry(entry)
			assert.Error(t, err, "Severity '%s' should be invalid", severity)
			assert.Contains(t, err.Error(), "Invalid severity level")
		})
	}
}

// TestValidateErrorEntry_EdgeCases tests edge cases and boundary conditions
func TestValidateErrorEntry_EdgeCases(t *testing.T) {
	tests := []struct {
		name     string
		entry    ErrorEntry
		valid    bool
		errorMsg string
	}{
		{
			name: "Whitespace only fields",
			entry: ErrorEntry{
				ID:        "   ",
				Timestamp: time.Now(),
				Message:   "   ",
				Module:    "   ",
				ErrorCode: "   ",
				Severity:  "low",
			},
			valid:    false,
			errorMsg: "ID cannot be empty", // Should be caught by validation
		},
		{
			name: "Very long message",
			entry: ErrorEntry{
				ID:        "123e4567-e89b-12d3-a456-426614174000",
				Timestamp: time.Now(),
				Message:   strings.Repeat("A", 10000),
				Module:    "test-module",
				ErrorCode: "ERR_001",
				Severity:  "low",
			},
			valid: true,
		},
		{
			name: "Unicode characters",
			entry: ErrorEntry{
				ID:        "123e4567-e89b-12d3-a456-426614174000",
				Timestamp: time.Now(),
				Message:   "错误消息 with émojis 🚨",
				Module:    "测试模块",
				ErrorCode: "ERR_测试_001",
				Severity:  "medium",
			},
			valid: true,
		},
		{
			name: "Special characters in context",
			entry: ErrorEntry{
				ID:             "123e4567-e89b-12d3-a456-426614174000",
				Timestamp:      time.Now(),
				Message:        "Error with special chars",
				Module:         "test-module",
				ErrorCode:      "ERR_001",
				ManagerContext: `{"key": "value with \"quotes\" and \n newlines"}`,
				Severity:       "high",
			},
			valid: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateErrorEntry(tt.entry)
			
			if tt.valid {
				assert.NoError(t, err, "Expected valid ErrorEntry")
			} else {
				assert.Error(t, err, "Expected invalid ErrorEntry")
				if tt.errorMsg != "" {
					assert.Contains(t, err.Error(), tt.errorMsg, "Error message should match")
				}
			}
		})
	}
}

// TestCatalogError_FunctionalityTest tests the CatalogError function
func TestCatalogError_FunctionalityTest(t *testing.T) {
	// Create a valid error entry
	entry := ErrorEntry{
		ID:             "test-catalog-id",
		Timestamp:      time.Now(),
		Message:        "Test catalog error",
		StackTrace:     "test.go:100",
		Module:         "catalog-test-module",
		ErrorCode:      "ERR_CATALOG_001",
		ManagerContext: "catalog test context",
		Severity:       "medium",
	}

	// This should not panic or error
	assert.NotPanics(t, func() {
		CatalogError(entry)
	}, "CatalogError should not panic with valid entry")
}

// TestErrorEntry_ManagerSpecificContexts tests different manager contexts
func TestErrorEntry_ManagerSpecificContexts(t *testing.T) {
	managerContexts := map[string]string{
		"dependency-manager": `{"operation": "install", "package": "go.uber.org/zap", "version": "v1.27.0"}`,
		"mcp-manager":       `{"server": "localhost:8080", "protocol": "mcp", "status": "connecting"}`,
		"n8n-manager":       `{"workflow": "email-sender", "node": "email-node", "execution_id": "123"}`,
		"process-manager":   `{"pid": 1234, "command": "go run main.go", "status": "running"}`,
		"script-manager":    `{"script": "deploy.sh", "args": ["--env", "prod"], "exit_code": 1}`,
		"roadmap-manager":   `{"phase": "5.1", "task": "integration", "progress": 100}`,
	}

	for manager, context := range managerContexts {
		t.Run("Manager_"+manager, func(t *testing.T) {
			entry := ErrorEntry{
				ID:             "mgr-test-" + manager,
				Timestamp:      time.Now(),
				Message:        "Manager specific error for " + manager,
				Module:         manager,
				ErrorCode:      "ERR_" + strings.ToUpper(strings.ReplaceAll(manager, "-", "_")) + "_001",
				ManagerContext: context,
				Severity:       "medium",
			}

			// Validate the entry
			err := ValidateErrorEntry(entry)
			assert.NoError(t, err, "Manager-specific error entry should be valid")

			// Test JSON serialization of context
			jsonData, err := json.Marshal(entry)
			assert.NoError(t, err, "Should serialize manager context correctly")
			
			// Verify context is preserved
			var deserializedEntry ErrorEntry
			err = json.Unmarshal(jsonData, &deserializedEntry)
			assert.NoError(t, err, "Should deserialize correctly")
			assert.Equal(t, context, deserializedEntry.ManagerContext, "Manager context should be preserved")
		})
	}
}

// BenchmarkValidateErrorEntry benchmarks the validation function
func BenchmarkValidateErrorEntry(b *testing.B) {
	entry := ErrorEntry{
		ID:             "123e4567-e89b-12d3-a456-426614174000",
		Timestamp:      time.Now(),
		Message:        "Benchmark test error",
		Module:         "benchmark-module",
		ErrorCode:      "ERR_BENCH_001",
		ManagerContext: "benchmark context",
		Severity:       "medium",
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		ValidateErrorEntry(entry)
	}
}

// BenchmarkErrorEntryJSONMarshal benchmarks JSON serialization
func BenchmarkErrorEntryJSONMarshal(b *testing.B) {
	entry := ErrorEntry{
		ID:             "123e4567-e89b-12d3-a456-426614174000",
		Timestamp:      time.Now(),
		Message:        "Benchmark JSON marshal test",
		StackTrace:     "main.go:10\nhandler.go:25\nvalidator.go:30",
		Module:         "benchmark-module",
		ErrorCode:      "ERR_BENCH_JSON_001",
		ManagerContext: `{"operation": "marshal", "size": "large", "iterations": 1000}`,
		Severity:       "low",
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		json.Marshal(entry)
	}
}

// TestErrorEntry_Integration tests integration between validation and cataloging
func TestErrorEntry_Integration(t *testing.T) {
	// Create multiple error entries from different managers
	entries := []ErrorEntry{
		{
			ID:             "integration-dep-001",
			Timestamp:      time.Now(),
			Message:        "Dependency installation failed",
			Module:         "dependency-manager",
			ErrorCode:      "ERR_DEP_INSTALL_001",
			ManagerContext: `{"package": "github.com/pkg/errors", "operation": "install"}`,
			Severity:       "high",
		},
		{
			ID:             "integration-mcp-001",
			Timestamp:      time.Now(),
			Message:        "MCP server connection timeout",
			Module:         "mcp-manager",
			ErrorCode:      "ERR_MCP_TIMEOUT_001",
			ManagerContext: `{"server": "localhost:8080", "timeout": "30s"}`,
			Severity:       "critical",
		},
		{
			ID:             "integration-n8n-001",
			Timestamp:      time.Now(),
			Message:        "N8N workflow execution failed",
			Module:         "n8n-manager",
			ErrorCode:      "ERR_N8N_EXEC_001",
			ManagerContext: `{"workflow": "email-sender", "step": "send-email"}`,
			Severity:       "medium",
		},
	}

	// Validate and catalog each entry
	for _, entry := range entries {
		t.Run("Integration_"+entry.Module, func(t *testing.T) {
			// Validate the entry
			err := ValidateErrorEntry(entry)
			assert.NoError(t, err, "Entry should be valid")

			// Catalog the entry (should not panic)
			assert.NotPanics(t, func() {
				CatalogError(entry)
			}, "Cataloging should not panic")

			// Verify JSON serialization works
			jsonData, err := json.Marshal(entry)
			assert.NoError(t, err, "JSON serialization should work")
			assert.NotEmpty(t, jsonData, "JSON data should not be empty")
		})
	}
}
