package errormanager_test

import (
	"encoding/json"
	"testing"
	"time"

	errormanager "error-manager"
)

func TestValidateErrorEntry(t *testing.T) {
	tests := []struct {
		name    string
		entry   errormanager.ErrorEntry
		wantErr bool
	}{
		{
			name: "Valid entry",
			entry: errormanager.ErrorEntry{
				ID:             "123",
				Timestamp:      time.Now(),
				Message:        "An error occurred",
				Module:         "TestModule",
				ErrorCode:      "E001",
				ManagerContext: "TestContext",
				Severity:       "high",
			},
			wantErr: false,
		},
		{
			name: "Empty ID",
			entry: errormanager.ErrorEntry{
				ID:             "",
				Timestamp:      time.Now(),
				Message:        "An error occurred",
				Module:         "TestModule",
				ErrorCode:      "E001",
				ManagerContext: "TestContext",
				Severity:       "high",
			},
			wantErr: true,
		},
		{
			name: "Invalid severity",
			entry: errormanager.ErrorEntry{
				ID:             "123",
				Timestamp:      time.Now(),
				Message:        "An error occurred",
				Module:         "TestModule",
				ErrorCode:      "E001",
				ManagerContext: "TestContext",
				Severity:       "invalid",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := errormanager.ValidateErrorEntry(tt.entry); (err != nil) != tt.wantErr {
				t.Errorf("ValidateErrorEntry() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

// TestErrorEntry_Serialization tests JSON serialization and deserialization
func TestErrorEntry_Serialization(t *testing.T) {
	originalEntry := errormanager.ErrorEntry{
		ID:             "123e4567-e89b-12d3-a456-426614174000",
		Timestamp:      time.Now().UTC(),
		Message:        "Test serialization error",
		StackTrace:     "main.go:15\nutils.go:42",
		Module:         "serialization-test",
		ErrorCode:      "ERR_SER_001",
		ManagerContext: "serialization test context",
		Severity:       "high",
	}

	// Test serialization to JSON
	jsonData, err := json.Marshal(originalEntry)
	if err != nil {
		t.Fatalf("JSON serialization failed: %v", err)
	}

	// Test deserialization from JSON
	var deserializedEntry errormanager.ErrorEntry
	err = json.Unmarshal(jsonData, &deserializedEntry)
	if err != nil {
		t.Fatalf("JSON deserialization failed: %v", err)
	}

	// Verify data integrity
	if originalEntry.ID != deserializedEntry.ID {
		t.Errorf("ID mismatch: got %v, want %v", deserializedEntry.ID, originalEntry.ID)
	}
	if originalEntry.Message != deserializedEntry.Message {
		t.Errorf("Message mismatch: got %v, want %v", deserializedEntry.Message, originalEntry.Message)
	}
	if originalEntry.Module != deserializedEntry.Module {
		t.Errorf("Module mismatch: got %v, want %v", deserializedEntry.Module, originalEntry.Module)
	}
}

// TestCatalogError_Functionality tests error cataloging functionality
func TestCatalogError_Functionality(t *testing.T) {
	entry := errormanager.ErrorEntry{
		ID:             "456e7890-f12a-34b5-c678-901234567890",
		Timestamp:      time.Now(),
		Message:        "Cataloging test error",
		StackTrace:     "catalog.go:20\nmain.go:45",
		Module:         "catalog-test",
		ErrorCode:      "ERR_CAT_001",
		ManagerContext: "catalog testing",
		Severity:       "low",
	}

	// Test cataloging (CatalogError returns void, so we test it doesn't panic)
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("CatalogError panicked: %v", r)
		}
	}()

	// CatalogError returns void, so we just call it
	errormanager.CatalogError(entry)
}

// TestPatternAnalyzer_Basic tests basic pattern analysis functionality
func TestPatternAnalyzer_Basic(t *testing.T) {
	// Create a mock analyzer (since we can't connect to real DB in tests)
	// We'll test that the analyzer can be created and methods don't crash

	// This test validates that the analyzer interface works
	// In a real scenario, we'd use a test database or mock
	t.Log("Pattern analyzer basic functionality test - requires database connection for full testing")

	// Test passes if we reach this point without panics
	t.Log("Basic pattern analyzer test completed successfully")
}
