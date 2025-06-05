package configmanager

import (
	"testing"
	"time"
)

func TestConfigManagerErrorManagerIntegration(t *testing.T) {
	// Create new config manager with ErrorManager integration
	cm, err := New()
	if err != nil {
		t.Fatalf("Failed to create config manager: %v", err)
	}

	// Cast to implementation to access internal methods
	impl, ok := cm.(*configManagerImpl)
	if !ok {
		t.Fatal("Failed to cast to configManagerImpl")
	}

	// Test ErrorManager integration
	if impl.errorManager == nil {
		t.Error("ErrorManager should not be nil")
	}

	if impl.logger == nil {
		t.Error("Logger should not be nil")
	}

	// Test error handling in GetString with non-existent key
	_, err = cm.GetString("nonexistent.key")
	if err == nil {
		t.Error("Expected error for non-existent key")
	}

	// Test error handling in GetInt with non-existent key
	_, err = cm.GetInt("nonexistent.int.key")
	if err == nil {
		t.Error("Expected error for non-existent key")
	}

	// Test error handling in GetBool with non-existent key
	_, err = cm.GetBool("nonexistent.bool.key")
	if err == nil {
		t.Error("Expected error for non-existent key")
	}

	// Test validation with required keys
	cm.SetRequiredKeys([]string{"required.key1", "required.key2"})
	err = cm.Validate()
	if err == nil {
		t.Error("Expected validation error for missing required keys")
	}

	// Test ErrorManager ProcessError method directly
	testErr := ErrKeyNotFound
	processErr := impl.errorManager.ProcessError(nil, testErr, "test-component", "test-operation", nil)
	if processErr == nil {
		t.Error("ProcessError should return the original error")
	}

	// Test ErrorEntry creation and validation
	entry := ErrorEntry{
		ID:             "test-id-123",
		Timestamp:      time.Now(),
		Message:        "Test error message",
		StackTrace:     "test stack trace",
		Module:         "config-manager-test",
		ErrorCode:      "CFG_TEST_001",
		ManagerContext: "test context",
		Severity:       "medium",
	}

	// Test ValidateErrorEntry
	err = impl.errorManager.ValidateErrorEntry(entry)
	if err != nil {
		t.Errorf("Valid error entry should not return error: %v", err)
	}

	// Test CatalogError
	err = impl.errorManager.CatalogError(entry)
	if err != nil {
		t.Errorf("CatalogError should not return error: %v", err)
	}

	// Test invalid error entry
	invalidEntry := ErrorEntry{
		ID: "", // Empty ID should cause validation error
	}
	err = impl.errorManager.ValidateErrorEntry(invalidEntry)
	if err == nil {
		t.Error("Invalid error entry should return validation error")
	}

	// Test cleanup
	err = impl.Cleanup()
	if err != nil {
		t.Errorf("Cleanup should not return error: %v", err)
	}
}

func TestConfigManagerErrorManagerComponents(t *testing.T) {
	cm, err := New()
	if err != nil {
		t.Fatalf("Failed to create config manager: %v", err)
	}

	impl := cm.(*configManagerImpl)

	// Test ErrorManager access
	errorManager := impl.GetErrorManager()
	if errorManager == nil {
		t.Error("GetErrorManager should not return nil")
	}

	// Test Logger access
	logger := impl.GetLogger()
	if logger == nil {
		t.Error("GetLogger should not return nil")
	}

	// Test helper functions
	if !isValidSeverity("low") {
		t.Error("'low' should be a valid severity")
	}

	if !isValidSeverity("medium") {
		t.Error("'medium' should be a valid severity")
	}

	if !isValidSeverity("high") {
		t.Error("'high' should be a valid severity")
	}

	if !isValidSeverity("critical") {
		t.Error("'critical' should be a valid severity")
	}

	if isValidSeverity("invalid") {
		t.Error("'invalid' should not be a valid severity")
	}

	// Test severity determination
	if determineSeverity(ErrKeyNotFound) != "medium" {
		t.Error("ErrKeyNotFound should have medium severity")
	}

	// Test error code generation
	errorCode := generateErrorCode("test-component", "test-operation")
	expected := "CFG_TEST_COMPONENT_TEST_OPERATION_001"
	if errorCode != expected {
		t.Errorf("Expected error code '%s', got '%s'", expected, errorCode)
	}
}
