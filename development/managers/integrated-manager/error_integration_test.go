package integratedmanager

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"
)

// MockErrorManager implémente ErrorManager pour les tests
type MockErrorManager struct {
	loggedErrors     []LoggedError
	catalogedErrors  []ErrorEntry
	validationErrors []ErrorEntry
	mu              sync.Mutex
}

type LoggedError struct {
	Err    error
	Module string
	Code   string
}

func NewMockErrorManager() *MockErrorManager {
	return &MockErrorManager{
		loggedErrors:     make([]LoggedError, 0),
		catalogedErrors:  make([]ErrorEntry, 0),
		validationErrors: make([]ErrorEntry, 0),
	}
}

func (m *MockErrorManager) LogError(err error, module string, code string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.loggedErrors = append(m.loggedErrors, LoggedError{
		Err:    err,
		Module: module,
		Code:   code,
	})
}

func (m *MockErrorManager) CatalogError(entry ErrorEntry) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.catalogedErrors = append(m.catalogedErrors, entry)
	return nil
}

func (m *MockErrorManager) ValidateError(entry ErrorEntry) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.validationErrors = append(m.validationErrors, entry)
	return nil
}

func (m *MockErrorManager) GetLoggedErrors() []LoggedError {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]LoggedError{}, m.loggedErrors...)
}

func (m *MockErrorManager) GetCatalogedErrors() []ErrorEntry {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]ErrorEntry{}, m.catalogedErrors...)
}

func (m *MockErrorManager) GetValidationErrors() []ErrorEntry {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]ErrorEntry{}, m.validationErrors...)
}

func TestPropagateError(t *testing.T) {
	// Reset singleton pour le test
	integratedManager = nil
	once = sync.Once{}

	mockEM := NewMockErrorManager()
	iem := GetIntegratedErrorManager()
	iem.SetErrorManager(mockEM)

	testErr := errors.New("Test error")
	PropagateError("test-module", testErr)

	// Attendre que le traitement asynchrone se termine
	time.Sleep(100 * time.Millisecond)

	catalogedErrors := mockEM.GetCatalogedErrors()
	if len(catalogedErrors) != 1 {
		t.Errorf("Expected 1 cataloged error, got %d", len(catalogedErrors))
	}

	if catalogedErrors[0].Module != "test-module" {
		t.Errorf("Expected module 'test-module', got '%s'", catalogedErrors[0].Module)
	}

	iem.Shutdown()
}

func TestCentralizeError(t *testing.T) {
	// Reset singleton pour le test
	integratedManager = nil
	once = sync.Once{}

	mockEM := NewMockErrorManager()
	iem := GetIntegratedErrorManager()
	iem.SetErrorManager(mockEM)

	testErr := errors.New("Test centralized error")
	centralizedErr := CentralizeError("test-module", testErr)

	if centralizedErr == nil {
		t.Errorf("Expected centralized error, got nil")
	}

	// Attendre que le traitement asynchrone se termine
	time.Sleep(100 * time.Millisecond)

	catalogedErrors := mockEM.GetCatalogedErrors()
	if len(catalogedErrors) != 1 {
		t.Errorf("Expected 1 cataloged error, got %d", len(catalogedErrors))
	}

	iem.Shutdown()
}

func TestPropagateErrorWithContext(t *testing.T) {
	// Reset singleton pour le test
	integratedManager = nil
	once = sync.Once{}

	mockEM := NewMockErrorManager()
	iem := GetIntegratedErrorManager()
	iem.SetErrorManager(mockEM)

	testErr := errors.New("Test error with context")
	context := map[string]interface{}{
		"user_id":    "12345",
		"request_id": "req-abc-123",
		"operation":  "send_email",
	}

	PropagateErrorWithContext("email-manager", testErr, context)

	// Attendre que le traitement asynchrone se termine
	time.Sleep(100 * time.Millisecond)

	catalogedErrors := mockEM.GetCatalogedErrors()
	if len(catalogedErrors) != 1 {
		t.Errorf("Expected 1 cataloged error, got %d", len(catalogedErrors))
	}

	if catalogedErrors[0].ManagerContext["user_id"] != "12345" {
		t.Errorf("Expected user_id '12345', got '%v'", catalogedErrors[0].ManagerContext["user_id"])
	}

	iem.Shutdown()
}

func TestErrorHooks(t *testing.T) {
	// Reset singleton pour le test
	integratedManager = nil
	once = sync.Once{}

	mockEM := NewMockErrorManager()
	iem := GetIntegratedErrorManager()
	iem.SetErrorManager(mockEM)

	// Variable pour capturer les appels de hook
	var hookCalled bool
	var hookModule string
	var hookError error

	// Ajouter un hook
	AddErrorHook("test-module", func(module string, err error, context map[string]interface{}) {
		hookCalled = true
		hookModule = module
		hookError = err
	})

	testErr := errors.New("Test hook error")
	PropagateError("test-module", testErr)

	// Attendre que le hook soit exécuté
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

	iem.Shutdown()
}

func TestDetermineErrorCode(t *testing.T) {
	tests := []struct {
		err      error
		expected string
	}{
		{context.DeadlineExceeded, "TIMEOUT_ERROR"},
		{context.Canceled, "CANCELED_ERROR"},
		{errors.New("generic error"), "GENERAL_ERROR"},
	}

	for _, test := range tests {
		result := determineErrorCode(test.err)
		if result != test.expected {
			t.Errorf("For error %v, expected %s, got %s", test.err, test.expected, result)
		}
	}
}

func TestDetermineSeverity(t *testing.T) {
	tests := []struct {
		err      error
		expected string
	}{
		{errors.New("critical system failure"), "CRITICAL"},
		{errors.New("fatal error occurred"), "CRITICAL"},
		{errors.New("panic in function"), "CRITICAL"},
		{errors.New("error processing request"), "ERROR"},
		{errors.New("failed to connect"), "ERROR"},
		{errors.New("warning: deprecated function"), "WARNING"},
		{errors.New("info: operation completed"), "INFO"},
	}

	for _, test := range tests {
		result := determineSeverity(test.err)
		if result != test.expected {
			t.Errorf("For error '%s', expected %s, got %s", test.err.Error(), test.expected, result)
		}
	}
}

func TestIntegratedErrorManagerSingleton(t *testing.T) {
	// Reset singleton pour le test
	integratedManager = nil
	once = sync.Once{}

	iem1 := GetIntegratedErrorManager()
	iem2 := GetIntegratedErrorManager()

	if iem1 != iem2 {
		t.Error("Expected singleton pattern, got different instances")
	}

	iem1.Shutdown()
}

func TestErrorQueueOverflow(t *testing.T) {
	// Reset singleton pour le test
	integratedManager = nil
	once = sync.Once{}

	mockEM := NewMockErrorManager()
	iem := GetIntegratedErrorManager()
	iem.SetErrorManager(mockEM)

	// Remplir la queue au-delà de sa capacité
	for i := 0; i < 150; i++ {
		testErr := errors.New("Queue overflow test")
		PropagateError("test-module", testErr)
	}

	// Attendre que le traitement se termine
	time.Sleep(200 * time.Millisecond)

	catalogedErrors := mockEM.GetCatalogedErrors()
	if len(catalogedErrors) != 150 {
		t.Errorf("Expected 150 cataloged errors, got %d", len(catalogedErrors))
	}

	iem.Shutdown()
}

func TestNilErrorHandling(t *testing.T) {
	// Test que les erreurs nil ne sont pas traitées
	PropagateError("test-module", nil)
	
	centralizedErr := CentralizeError("test-module", nil)
	if centralizedErr != nil {
		t.Errorf("Expected nil for nil error, got %v", centralizedErr)
	}
}

// Benchmark pour mesurer les performances
func BenchmarkPropagateError(b *testing.B) {
	// Reset singleton pour le benchmark
	integratedManager = nil
	once = sync.Once{}

	mockEM := NewMockErrorManager()
	iem := GetIntegratedErrorManager()
	iem.SetErrorManager(mockEM)

	testErr := errors.New("Benchmark error")

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		PropagateError("benchmark-module", testErr)
	}

	iem.Shutdown()
}
