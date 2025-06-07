package tests

import (
	"context"
	"testing"
	"time"

	gitworkflowmanager "github.com/email-sender/git-workflow-manager"
	"github.com/email-sender/managers/interfaces"
)

// MockErrorManager implements a mock ErrorManager for testing
type MockErrorManager struct{}

func (m *MockErrorManager) GetID() string                                    { return "mock-error-manager" }
func (m *MockErrorManager) GetName() string                                  { return "MockErrorManager" }
func (m *MockErrorManager) GetStatus() string                                { return "ready" }
func (m *MockErrorManager) GetConfig() map[string]interface{}                { return make(map[string]interface{}) }
func (m *MockErrorManager) UpdateConfig(config map[string]interface{}) error { return nil }
func (m *MockErrorManager) GetMetadata() map[string]interface{}              { return make(map[string]interface{}) }
func (m *MockErrorManager) SetMetadata(key string, value interface{}) error  { return nil }
func (m *MockErrorManager) Health() error                                    { return nil }
func (m *MockErrorManager) Shutdown(ctx context.Context) error               { return nil }

// MockConfigManager implements a mock ConfigManager for testing
type MockConfigManager struct{}

func (m *MockConfigManager) GetID() string                                    { return "mock-config-manager" }
func (m *MockConfigManager) GetName() string                                  { return "MockConfigManager" }
func (m *MockConfigManager) GetStatus() string                                { return "ready" }
func (m *MockConfigManager) GetConfig() map[string]interface{}                { return make(map[string]interface{}) }
func (m *MockConfigManager) UpdateConfig(config map[string]interface{}) error { return nil }
func (m *MockConfigManager) GetMetadata() map[string]interface{}              { return make(map[string]interface{}) }
func (m *MockConfigManager) SetMetadata(key string, value interface{}) error  { return nil }
func (m *MockConfigManager) Health() error                                    { return nil }
func (m *MockConfigManager) Shutdown(ctx context.Context) error               { return nil }

// MockStorageManager implements a mock StorageManager for testing
type MockStorageManager struct{}

func (m *MockStorageManager) GetID() string                                    { return "mock-storage-manager" }
func (m *MockStorageManager) GetName() string                                  { return "MockStorageManager" }
func (m *MockStorageManager) GetStatus() string                                { return "ready" }
func (m *MockStorageManager) GetConfig() map[string]interface{}                { return make(map[string]interface{}) }
func (m *MockStorageManager) UpdateConfig(config map[string]interface{}) error { return nil }
func (m *MockStorageManager) GetMetadata() map[string]interface{} {
	return make(map[string]interface{})
}
func (m *MockStorageManager) SetMetadata(key string, value interface{}) error { return nil }
func (m *MockStorageManager) Health() error                                   { return nil }
func (m *MockStorageManager) Shutdown(ctx context.Context) error              { return nil }

// TestGitWorkflowManagerCreation tests the creation of GitWorkflowManager
func TestGitWorkflowManagerCreation(t *testing.T) {
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repo_path":     ".",
		"workflow_type": string(interfaces.WorkflowTypeGitFlow),
		"github_token":  "",
	}

	manager, err := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)
	if err != nil {
		t.Fatalf("Failed to create GitWorkflowManager: %v", err)
	}

	if manager == nil {
		t.Fatal("GitWorkflowManager is nil")
	}

	// Test BaseManager interface
	if manager.GetID() == "" {
		t.Error("Manager ID should not be empty")
	}

	if manager.GetName() != "GitWorkflowManager" {
		t.Errorf("Expected name 'GitWorkflowManager', got '%s'", manager.GetName())
	}

	if manager.GetStatus() != "ready" {
		t.Errorf("Expected status 'ready', got '%s'", manager.GetStatus())
	}

	// Test health check
	if err := manager.Health(); err != nil {
		t.Errorf("Health check failed: %v", err)
	}

	// Test shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := manager.Shutdown(ctx); err != nil {
		t.Errorf("Shutdown failed: %v", err)
	}
}

// TestGitWorkflowManagerWithMissingDependencies tests error handling for missing dependencies
func TestGitWorkflowManagerWithMissingDependencies(t *testing.T) {
	config := map[string]interface{}{
		"repo_path": ".",
	}

	// Test with nil errorManager
	_, err := gitworkflowmanager.NewGitWorkflowManager(nil, &MockConfigManager{}, &MockStorageManager{}, config)
	if err == nil {
		t.Error("Expected error when errorManager is nil")
	}

	// Test with nil configManager
	_, err = gitworkflowmanager.NewGitWorkflowManager(&MockErrorManager{}, nil, &MockStorageManager{}, config)
	if err == nil {
		t.Error("Expected error when configManager is nil")
	}

	// Test with nil storageManager
	_, err = gitworkflowmanager.NewGitWorkflowManager(&MockErrorManager{}, &MockConfigManager{}, nil, config)
	if err == nil {
		t.Error("Expected error when storageManager is nil")
	}
}

// TestCommitMessageValidation tests commit message validation
func TestCommitMessageValidation(t *testing.T) {
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repo_path": ".",
	}

	manager, err := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)
	if err != nil {
		t.Fatalf("Failed to create GitWorkflowManager: %v", err)
	}
	defer manager.Shutdown(context.Background())

	// Test valid commit messages
	validMessages := []string{
		"feat: add new feature",
		"fix: resolve bug in authentication",
		"docs: update API documentation",
		"feat(auth): implement OAuth2 flow",
		"chore: update dependencies",
	}

	for _, message := range validMessages {
		if err := manager.ValidateCommitMessage(message); err != nil {
			t.Errorf("Valid message '%s' was rejected: %v", message, err)
		}
	}

	// Test invalid commit messages
	invalidMessages := []string{
		"",                            // empty
		"short",                       // too short
		"invalid format without type", // wrong format
		"feat: this message is way too long for a commit message and exceeds the maximum length limit", // too long
		"feat: message ending with period.", // ends with period
		"feat: lowercase message",           // starts with lowercase
	}

	for _, message := range invalidMessages {
		if err := manager.ValidateCommitMessage(message); err == nil {
			t.Errorf("Invalid message '%s' was accepted", message)
		}
	}
}

// TestWorkflowValidation tests workflow type validation
func TestWorkflowValidation(t *testing.T) {
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repo_path": ".",
	}

	manager, err := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)
	if err != nil {
		t.Fatalf("Failed to create GitWorkflowManager: %v", err)
	}
	defer manager.Shutdown(context.Background())

	ctx := context.Background()

	// Test valid workflow types
	validWorkflows := []interfaces.WorkflowType{
		interfaces.WorkflowTypeGitFlow,
		interfaces.WorkflowTypeGitHubFlow,
		interfaces.WorkflowTypeFeatureBranch,
	}

	for _, workflow := range validWorkflows {
		if err := manager.ValidateWorkflow(ctx, workflow); err != nil {
			t.Errorf("Valid workflow type '%s' was rejected: %v", workflow, err)
		}
	}

	// Test invalid workflow type
	invalidWorkflow := interfaces.WorkflowType("invalid-workflow")
	if err := manager.ValidateWorkflow(ctx, invalidWorkflow); err == nil {
		t.Error("Invalid workflow type was accepted")
	}
}

// TestConfigurationManagement tests configuration management
func TestConfigurationManagement(t *testing.T) {
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repo_path":     ".",
		"workflow_type": string(interfaces.WorkflowTypeGitFlow),
	}

	manager, err := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)
	if err != nil {
		t.Fatalf("Failed to create GitWorkflowManager: %v", err)
	}
	defer manager.Shutdown(context.Background())

	ctx := context.Background()

	// Test getting initial configuration
	initialConfig, err := manager.GetWorkflowConfiguration(ctx)
	if err != nil {
		t.Errorf("Failed to get workflow configuration: %v", err)
	}

	if initialConfig["repo_path"] != "." {
		t.Error("Initial configuration not properly set")
	}

	// Test updating configuration
	newConfig := map[string]interface{}{
		"workflow_type": string(interfaces.WorkflowTypeGitHubFlow),
		"github_token":  "test-token",
	}

	if err := manager.SetWorkflowConfiguration(ctx, newConfig); err != nil {
		t.Errorf("Failed to set workflow configuration: %v", err)
	}

	// Test getting updated configuration
	updatedConfig, err := manager.GetWorkflowConfiguration(ctx)
	if err != nil {
		t.Errorf("Failed to get updated workflow configuration: %v", err)
	}

	if updatedConfig["workflow_type"] != string(interfaces.WorkflowTypeGitHubFlow) {
		t.Error("Configuration update failed")
	}

	// Test resetting configuration
	if err := manager.ResetWorkflowConfiguration(ctx); err != nil {
		t.Errorf("Failed to reset workflow configuration: %v", err)
	}

	resetConfig, err := manager.GetWorkflowConfiguration(ctx)
	if err != nil {
		t.Errorf("Failed to get reset workflow configuration: %v", err)
	}

	if resetConfig["workflow_type"] != string(interfaces.WorkflowTypeGitFlow) {
		t.Error("Configuration reset failed")
	}
}

// TestFactoryCreation tests the factory creation
func TestFactoryCreation(t *testing.T) {
	factory := gitworkflowmanager.NewGitWorkflowManagerFactory()
	if factory == nil {
		t.Fatal("Factory is nil")
	}

	// Test default configuration
	defaultConfig := factory.GetDefaultConfiguration()
	if defaultConfig == nil {
		t.Error("Default configuration is nil")
	}

	if defaultConfig["repo_path"] != "." {
		t.Error("Default repo_path is incorrect")
	}

	if defaultConfig["workflow_type"] != string(interfaces.WorkflowTypeGitFlow) {
		t.Error("Default workflow_type is incorrect")
	}

	// Test configuration validation
	validConfig := map[string]interface{}{
		"repo_path":     ".",
		"workflow_type": string(interfaces.WorkflowTypeGitFlow),
	}

	if err := factory.ValidateConfiguration(validConfig); err != nil {
		t.Errorf("Valid configuration was rejected: %v", err)
	}

	// Test invalid configuration
	invalidConfig := map[string]interface{}{
		"workflow_type": "invalid-workflow",
	}

	if err := factory.ValidateConfiguration(invalidConfig); err == nil {
		t.Error("Invalid configuration was accepted")
	}

	// Test missing required fields
	missingConfig := map[string]interface{}{
		"workflow_type": string(interfaces.WorkflowTypeGitFlow),
	}

	if err := factory.ValidateConfiguration(missingConfig); err == nil {
		t.Error("Configuration with missing required fields was accepted")
	}
}

// TestManagerIntegration tests integration between different components
func TestManagerIntegration(t *testing.T) {
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repo_path":     ".",
		"workflow_type": string(interfaces.WorkflowTypeGitFlow),
	}

	manager, err := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)
	if err != nil {
		t.Fatalf("Failed to create GitWorkflowManager: %v", err)
	}
	defer manager.Shutdown(context.Background())

	ctx := context.Background()

	// Test workflow status
	status, err := manager.GetWorkflowStatus(ctx)
	if err != nil {
		t.Errorf("Failed to get workflow status: %v", err)
	}

	if status["workflow_type"] != string(interfaces.WorkflowTypeGitFlow) {
		t.Error("Workflow status does not match configuration")
	}

	if status["repo_path"] != "." {
		t.Error("Repository path in status is incorrect")
	}

	if status["status"] != "ready" {
		t.Error("Manager status is not ready")
	}
}

// BenchmarkGitWorkflowManagerCreation benchmarks manager creation
func BenchmarkGitWorkflowManagerCreation(b *testing.B) {
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repo_path":     ".",
		"workflow_type": string(interfaces.WorkflowTypeGitFlow),
	}

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		manager, err := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)
		if err != nil {
			b.Fatalf("Failed to create GitWorkflowManager: %v", err)
		}
		manager.Shutdown(context.Background())
	}
}

// BenchmarkCommitMessageValidation benchmarks commit message validation
func BenchmarkCommitMessageValidation(b *testing.B) {
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repo_path": ".",
	}

	manager, err := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)
	if err != nil {
		b.Fatalf("Failed to create GitWorkflowManager: %v", err)
	}
	defer manager.Shutdown(context.Background())

	message := "feat: add new feature for user authentication"

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		manager.ValidateCommitMessage(message)
	}
}
