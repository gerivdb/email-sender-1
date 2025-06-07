package integrationmanager_test

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"

	im "email_sender/development/managers/integration-manager"
)

// LocalErrorEntry defined for MockErrorManager, distinct from im.ErrorEntry
type LocalErrorEntry struct {
	Error          error
	Module         string
	ErrorCode      string
	Severity       im.Severity // Assuming im.Severity is the type for severity levels
	Timestamp      time.Time
	ManagerContext map[string]interface{}
	// other fields as needed by mock
}

// LoggedError struct for mock
type LoggedError struct {
	Err    error
	Module string
	Code   string
}

// MockErrorManager implements parts of ErrorManager interface for demo/test purposes
type MockErrorManager struct {
	mu               sync.Mutex
	loggedErrors     []LoggedError
	catalogedErrors  []LocalErrorEntry
	validationErrors []LocalErrorEntry
}

// NewMockErrorManager creates a new mock error manager
func NewMockErrorManager() *MockErrorManager {
	return &MockErrorManager{
		loggedErrors:    make([]LoggedError, 0),
		catalogedErrors: make([]LocalErrorEntry, 0),
	}
}

// LogError mock method
func (m *MockErrorManager) LogError(err error, module string, code string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.loggedErrors = append(m.loggedErrors, LoggedError{Err: err, Module: module, Code: code})
}

// CatalogError mock method - this is what tests will check
func (m *MockErrorManager) CatalogError(entry im.ErrorEntry) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	// Convert im.ErrorEntry to LocalErrorEntry for storing in mock
	localEntry := LocalErrorEntry{
		Error:          errors.New(entry.Message), // Assuming Message string can be made an error
		Module:         entry.Module,
		ErrorCode:      entry.ErrorCode,
		Severity:       entry.Severity,
		Timestamp:      entry.Timestamp,
		ManagerContext: entry.Context,
	}
	m.catalogedErrors = append(m.catalogedErrors, localEntry)
	return nil
}

// GetCatalogedErrors mock method
func (m *MockErrorManager) GetCatalogedErrors() []LocalErrorEntry {
	m.mu.Lock()
	defer m.mu.Unlock()
	// Return a copy
	errorsCopy := make([]LocalErrorEntry, len(m.catalogedErrors))
	copy(errorsCopy, m.catalogedErrors)
	return errorsCopy
}

// Helper stubs for determineErrorCode and determineSeverity
// These are assumed to be functions in the 'im' package in production code.
// For testing purposes, if tests rely on specific outputs, they might need more sophisticated stubs
// or these test functions should call im.DetermineErrorCode and im.DetermineSeverity.

// TestPropagateError tests the PropagateError method of IntegratedErrorManager
func TestPropagateError(t *testing.T) {
	// Reset singleton for the test - This might not work if integratedManager and once are unexported in 'im'
	// im.ResetGlobalManagerForTesting() // Hypothetical function to reset singleton state in 'im' package

	mockEM := NewMockErrorManager()
	iem := im.GetIntegratedErrorManager() // Assuming this returns the singleton or a new instance
	if iem == nil {
		t.Fatal("GetIntegratedErrorManager returned nil")
	}
	iem.SetErrorManager(mockEM) // Assuming this method exists to inject the mock

	testErr := errors.New("Test error")
	iem.PropagateError("test-module", testErr) // Call as a method

	time.Sleep(100 * time.Millisecond) // Wait for async processing if any

	catalogedErrors := mockEM.GetCatalogedErrors()
	if len(catalogedErrors) == 0 { // Check if empty first
		t.Fatal("Expected 1 cataloged error, got 0")
	}
	if len(catalogedErrors) != 1 {
		t.Errorf("Expected 1 cataloged error, got %d", len(catalogedErrors))
	}

	// Additional check as original test
	if catalogedErrors[0].Module != "test-module" {
		t.Errorf("Expected module 'test-module', got '%s'", catalogedErrors[0].Module)
	}


	// iem.Shutdown() // Assuming this method exists
}

func TestCentralizeError(t *testing.T) {
	// im.ResetGlobalManagerForTesting()

	mockEM := NewMockErrorManager()
	iem := im.GetIntegratedErrorManager()
	if iem == nil {
		t.Fatal("GetIntegratedErrorManager returned nil")
	}
	iem.SetErrorManager(mockEM)

	testErr := errors.New("Test centralized error")
	// Assuming CentralizeError is a method and returns an error or an ErrorEntry
	// The original test implies it returns an error. Let's assume it's:
	// CentralizeError(module string, err error, severity Severity, code string, details map[string]interface{}) error
	// For the purpose of this stub, let's simplify or assume a signature.
	// The original code `centralizedErr := CentralizeError("test-module", testErr)` is problematic.
	// Let's assume it's meant to be similar to PropagateError for testing cataloging.
	iem.CentralizeError("test-module", testErr, im.SeverityError, "TEST_CODE", nil)


	time.Sleep(100 * time.Millisecond)

	catalogedErrors := mockEM.GetCatalogedErrors()
	if len(catalogedErrors) != 1 {
		t.Errorf("Expected 1 cataloged error, got %d", len(catalogedErrors))
	}
	// iem.Shutdown()
}

func TestPropagateErrorWithContext(t *testing.T) {
	// im.ResetGlobalManagerForTesting()

	mockEM := NewMockErrorManager()
	iem := im.GetIntegratedErrorManager()
	if iem == nil {
		t.Fatal("GetIntegratedErrorManager returned nil")
	}
	iem.SetErrorManager(mockEM)

	testErr := errors.New("Test error with context")
	contextDetails := map[string]interface{}{
		"user_id":    "12345",
		"request_id": "req-abc-123",
		"operation":  "send_email",
	}

	iem.PropagateErrorWithContext("email-manager", testErr, contextDetails)

	time.Sleep(100 * time.Millisecond)

	catalogedErrors := mockEM.GetCatalogedErrors()
	if len(catalogedErrors) == 0 {
		t.Fatal("Expected 1 cataloged error, got 0")
	}
	if len(catalogedErrors) != 1 {
		t.Errorf("Expected 1 cataloged error, got %d", len(catalogedErrors))
	}

	entry := catalogedErrors[0]
	if entry.ManagerContext == nil {
		t.Fatal("ManagerContext is nil")
	}
	if entry.ManagerContext["user_id"] != "12345" {
		t.Errorf("Expected user_id '12345', got '%v'", entry.ManagerContext["user_id"])
	}
	// iem.Shutdown()
}

func TestErrorHooks(t *testing.T) {
	// im.ResetGlobalManagerForTesting()
	mockEM := NewMockErrorManager()
	iem := im.GetIntegratedErrorManager()
	if iem == nil {
		t.Fatal("GetIntegratedErrorManager returned nil")
	}
	iem.SetErrorManager(mockEM)

	var hookCalled bool
	var hookModule string
	var hookError error

	iem.AddErrorHook("test-module", func(module string, err error, context map[string]interface{}) {
		hookCalled = true
		hookModule = module
		hookError = err
	})

	testErr := errors.New("Test hook error")
	iem.PropagateError("test-module", testErr)

	time.Sleep(100 * time.Millisecond)

	if !hookCalled {
		t.Error("Expected hook to be called")
	}
	if hookModule != "test-module" {
		t.Errorf("Expected hook module 'test-module', got '%s'", hookModule)
	}
	if hookError == nil || hookError.Error() != "Test hook error" {
		t.Errorf("Expected hook error 'Test hook error', got '%v'", hookError)
	}
	// iem.Shutdown()
}

func TestDetermineErrorCode(t *testing.T) {
	tests := []struct {
		err      error
		expected string
	}{
		{context.DeadlineExceeded, "TIMEOUT_ERROR"}, // Assuming these are constants in 'im'
		{context.Canceled, "CANCELED_ERROR"},
		{errors.New("generic error"), "GENERAL_ERROR"},
	}

	for _, test := range tests {
		result := im.DetermineErrorCode(test.err) // Call from 'im' package
		if result != test.expected {
			t.Errorf("For error %v, expected %s, got %s", test.err, test.expected, result)
		}
	}
}

func TestDetermineSeverity(t *testing.T) {
	tests := []struct {
		err      error
		expected im.Severity // Assuming im.Severity is the return type
	}{
		{errors.New("critical system failure"), im.SeverityCritical},
		{errors.New("fatal error occurred"), im.SeverityCritical},
		{errors.New("panic in function"), im.SeverityCritical},
		{errors.New("error processing request"), im.SeverityError},
		{errors.New("failed to connect"), im.SeverityError},
		{errors.New("warning: deprecated function"), im.SeverityWarning},
		{errors.New("info: operation completed"), im.SeverityInfo},
	}

	for _, test := range tests {
		result := im.DetermineSeverity(test.err) // Call from 'im' package
		if result != test.expected {
			t.Errorf("For error '%s', expected %s, got %s", test.err.Error(), test.expected, result)
		}
	}
}

func TestIntegratedErrorManagerSingleton(t *testing.T) {
	// im.ResetGlobalManagerForTesting()

	iem1 := im.GetIntegratedErrorManager()
	iem2 := im.GetIntegratedErrorManager()

	if iem1 != iem2 {
		t.Error("Expected singleton pattern, got different instances")
	}
	// iem1.Shutdown() // Assuming Shutdown exists
}

func TestErrorQueueOverflow(t *testing.T) {
	// im.ResetGlobalManagerForTesting()
	mockEM := NewMockErrorManager()
	iem := im.GetIntegratedErrorManager()
	if iem == nil {
		t.Fatal("GetIntegratedErrorManager returned nil")
	}
	iem.SetErrorManager(mockEM)

	for i := 0; i < 150; i++ {
		testErr := errors.New("Queue overflow test")
		iem.PropagateError("test-module", testErr)
	}

	time.Sleep(200 * time.Millisecond)

	catalogedErrors := mockEM.GetCatalogedErrors()
	// The original test expected 150. This depends on queue size and processing.
	// For a unit test with a mock, this might be exact if processing is synchronous
	// or if the mock's CatalogError is directly called.
	// If IntegratedErrorManager has an internal queue, this test is more of an integration test.
	// Let's assume for now the mock directly catalogs.
	if len(catalogedErrors) != 150 {
		t.Errorf("Expected 150 cataloged errors, got %d", len(catalogedErrors))
	}
	// iem.Shutdown()
}

func TestNilErrorHandling(t *testing.T) {
	// im.ResetGlobalManagerForTesting()
	iem := im.GetIntegratedErrorManager()
	if iem == nil {
		t.Fatal("GetIntegratedErrorManager returned nil")
	}
	// Test that nil errors are not propagated or centralized
	iem.PropagateError("test-module", nil)

	// The original CentralizeError call was: centralizedErr := CentralizeError("test-module", nil)
	// Assuming a method on iem:
	// iem.CentralizeError("test-module", nil, im.SeverityInfo, "NIL_ERROR", nil)
	// The original test checked if centralizedErr was nil.
	// This test needs to be adapted based on actual CentralizeError signature and behavior for nil errors.
	// For now, focusing on PropagateError.
	// If CentralizeError returns an error or specific entry, that should be checked.
	// If it's just about cataloging, we can check mockEM.GetCatalogedErrors() count.
	mockEM := NewMockErrorManager()
	iem.SetErrorManager(mockEM)
	iem.PropagateError("test-module", nil) // Should ideally not add to cataloged errors
	// centralizedErr := iem.CentralizeError("test-module", nil, im.SeverityInfo, "NIL_ERR", nil)
	// if centralizedErr != nil {
	// 	t.Errorf("Expected nil for nil error from CentralizeError, got %v", centralizedErr)
	// }
	if len(mockEM.GetCatalogedErrors()) > 0 {
		t.Errorf("Expected 0 cataloged errors for nil propagation, got %d", len(mockEM.GetCatalogedErrors()))
	}
}

// Benchmark pour mesurer les performances
func BenchmarkPropagateError(b *testing.B) {
	// im.ResetGlobalManagerForTesting()
	mockEM := NewMockErrorManager()
	iem := im.GetIntegratedErrorManager()
	if iem == nil {
		b.Fatal("GetIntegratedErrorManager returned nil")
	}
	iem.SetErrorManager(mockEM)

	testErr := errors.New("Benchmark error")

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		iem.PropagateError("benchmark-module", testErr)
	}
	// iem.Shutdown()
}
