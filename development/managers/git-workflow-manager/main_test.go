package main

import (
	"testing"
	"context"
)

// MockErrorManager implements a simple mock for testing
type MockErrorManager struct{}

func (m *MockErrorManager) GetID() string { return "mock-error" }
func (m *MockErrorManager) GetName() string { return "MockError" }
func (m *MockErrorManager) GetStatus() string { return "ready" }
func (m *MockErrorManager) GetConfig() map[string]interface{} { return make(map[string]interface{}) }
func (m *MockErrorManager) UpdateConfig(config map[string]interface{}) error { return nil }
func (m *MockErrorManager) GetMetadata() map[string]interface{} { return make(map[string]interface{}) }
func (m *MockErrorManager) SetMetadata(key string, value interface{}) error { return nil }
func (m *MockErrorManager) Health() error { return nil }
func (m *MockErrorManager) Shutdown(ctx context.Context) error { return nil }

// MockConfigManager implements a simple mock for testing
type MockConfigManager struct{}

func (m *MockConfigManager) GetID() string { return "mock-config" }
func (m *MockConfigManager) GetName() string { return "MockConfig" }
func (m *MockConfigManager) GetStatus() string { return "ready" }
func (m *MockConfigManager) GetConfig() map[string]interface{} { return make(map[string]interface{}) }
func (m *MockConfigManager) UpdateConfig(config map[string]interface{}) error { return nil }
func (m *MockConfigManager) GetMetadata() map[string]interface{} { return make(map[string]interface{}) }
func (m *MockConfigManager) SetMetadata(key string, value interface{}) error { return nil }
func (m *MockConfigManager) Health() error { return nil }
func (m *MockConfigManager) Shutdown(ctx context.Context) error { return nil }

// MockStorageManager implements a simple mock for testing
type MockStorageManager struct{}

func (m *MockStorageManager) GetID() string { return "mock-storage" }
func (m *MockStorageManager) GetName() string { return "MockStorage" }
func (m *MockStorageManager) GetStatus() string { return "ready" }
func (m *MockStorageManager) GetConfig() map[string]interface{} { return make(map[string]interface{}) }
func (m *MockStorageManager) UpdateConfig(config map[string]interface{}) error { return nil }
func (m *MockStorageManager) GetMetadata() map[string]interface{} { return make(map[string]interface{}) }
func (m *MockStorageManager) SetMetadata(key string, value interface{}) error { return nil }
func (m *MockStorageManager) Health() error { return nil }
func (m *MockStorageManager) Shutdown(ctx context.Context) error { return nil }

func TestGitWorkflowManagerCreation(t *testing.T) {
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repository_path": ".",
		"workflow_type":   "gitflow",
		"github_token":    "test-token",
	}

	manager := NewGitWorkflowManager(errorManager, configManager, storageManager, config)
	if manager == nil {
		t.Fatal("GitWorkflowManager should not be nil")
	}

	if manager.GetName() != "GitWorkflowManager" {
		t.Errorf("Expected name 'GitWorkflowManager', got '%s'", manager.GetName())
	}

	if manager.GetStatus() != "ready" {
		t.Errorf("Expected status 'ready', got '%s'", manager.GetStatus())
	}
}

func TestGitWorkflowManagerBasicOperations(t *testing.T) {
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repository_path": ".",
		"workflow_type":   "gitflow",
	}

	manager := NewGitWorkflowManager(errorManager, configManager, storageManager, config)

	// Test Health
	if err := manager.Health(); err != nil {
		t.Errorf("Health check failed: %v", err)
	}

	// Test Config Update
	newConfig := map[string]interface{}{
		"repository_path": "/new/path",
	}
	if err := manager.UpdateConfig(newConfig); err != nil {
		t.Errorf("Config update failed: %v", err)
	}

	// Test Metadata
	if err := manager.SetMetadata("test-key", "test-value"); err != nil {
		t.Errorf("Set metadata failed: %v", err)
	}

	metadata := manager.GetMetadata()
	if metadata["test-key"] != "test-value" {
		t.Errorf("Expected metadata value 'test-value', got '%v'", metadata["test-key"])
	}
}
