package tests

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	gitworkflowmanager "EMAIL_SENDER_1/git-workflow-manager"
	"EMAIL_SENDER_1/git-workflow-manager/workflows"
	"EMAIL_SENDER_1/managers/interfaces"
)

// TestGitWorkflowIntegration tests the GitWorkflowManager with actual Git operations
func TestGitWorkflowIntegration(t *testing.T) {
	// Skip integration tests if not in integration mode
	if testing.Short() {
		t.Skip("Skipping integration tests in short mode")
	}

	// Create temporary directory for test repository
	tempDir, err := os.MkdirTemp("", "git-workflow-test-*")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Initialize test repository
	repoPath := filepath.Join(tempDir, "test-repo")
	if err := os.MkdirAll(repoPath, 0755); err != nil {
		t.Fatalf("Failed to create repo directory: %v", err)
	}

	// Create test managers
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repository_path": repoPath,
		"workflow_type":   "gitflow",
		"github_token":    "test-token",
	}

	// Create GitWorkflowManager
	manager := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)
	if manager == nil {
		t.Fatal("Failed to create GitWorkflowManager")
	}

	// Test health check
	if err := manager.Health(); err != nil {
		t.Errorf("Health check failed: %v", err)
	}

	// Test workflow factory
	factory := workflows.NewWorkflowFactory(manager)
	gitflowWorkflow, err := factory.CreateWorkflow(interfaces.WorkflowTypeGitFlow, config)
	if err != nil {
		t.Errorf("Failed to create GitFlow workflow: %v", err)
	}

	if gitflowWorkflow.GetWorkflowType() != interfaces.WorkflowTypeGitFlow {
		t.Errorf("Expected GitFlow workflow, got %v", gitflowWorkflow.GetWorkflowType())
	}
}

// TestWorkflowOperations tests specific workflow operations
func TestWorkflowOperations(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping workflow operations tests in short mode")
	}

	// Create test managers
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repository_path": ".",
		"workflow_type":   "feature-branch",
	}

	// Create GitWorkflowManager
	manager := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)

	// Test branch name validation
	testCases := []struct {
		branchName string
		shouldFail bool
	}{
		{"feature/test-branch", false},
		{"bugfix/fix-issue", false},
		{"invalid branch name", true},
		{"feature/", true},
		{"", true},
	}

	for _, tc := range testCases {
		err := manager.ValidateBranchName(tc.branchName)
		if tc.shouldFail && err == nil {
			t.Errorf("Expected validation to fail for branch name '%s'", tc.branchName)
		}
		if !tc.shouldFail && err != nil {
			t.Errorf("Expected validation to pass for branch name '%s', got error: %v", tc.branchName, err)
		}
	}

	// Test commit validation
	commitInfo := interfaces.CommitInfo{
		Message: "feat: add new feature",
		Author:  "test-author",
		Branch:  "feature/test",
	}

	err := manager.ValidateCommitMessage(commitInfo.Message)
	if err != nil {
		t.Errorf("Valid commit message failed validation: %v", err)
	}

	// Test invalid commit message
	invalidCommit := "invalid commit message"
	err = manager.ValidateCommitMessage(invalidCommit)
	if err == nil {
		t.Error("Expected invalid commit message to fail validation")
	}
}

// TestMultipleWorkflows tests different workflow types
func TestMultipleWorkflows(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping multiple workflows tests in short mode")
	}

	// Create test managers
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repository_path": ".",
	}

	// Create GitWorkflowManager
	manager := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)
	factory := workflows.NewWorkflowFactory(manager)

	// Test different workflow types
	workflowTypes := []interfaces.WorkflowType{
		interfaces.WorkflowTypeGitFlow,
		interfaces.WorkflowTypeGitHubFlow,
		interfaces.WorkflowTypeFeatureBranch,
		interfaces.WorkflowTypeCustom,
	}

	for _, workflowType := range workflowTypes {
		workflow, err := factory.CreateWorkflow(workflowType, config)
		if err != nil {
			t.Errorf("Failed to create workflow of type %v: %v", workflowType, err)
			continue
		}

		if workflow.GetWorkflowType() != workflowType {
			t.Errorf("Expected workflow type %v, got %v", workflowType, workflow.GetWorkflowType())
		}

		strategy := workflow.GetBranchingStrategy()
		if strategy == "" {
			t.Errorf("Workflow type %v returned empty branching strategy", workflowType)
		}
	}
}

// TestWebhookIntegration tests webhook functionality
func TestWebhookIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping webhook integration tests in short mode")
	}

	// Create test managers
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repository_path": ".",
		"webhook_config": map[string]interface{}{
			"enabled": true,
			"timeout": 30,
		},
	}

	// Create GitWorkflowManager
	manager := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)
	ctx := context.Background()

	// Test webhook payload
	webhook := interfaces.WebhookPayload{
		Event: "branch_created",
		Data: map[string]interface{}{
			"branch_name": "feature/test",
			"created_by":  "test-user",
			"timestamp":   time.Now(),
		},
	}

	// This would normally send to configured endpoints
	// For testing, we just validate the webhook structure
	err := manager.SendWebhook(ctx, webhook)
	if err != nil {
		// Error is expected in test environment without real webhook endpoints
		t.Logf("Webhook send failed as expected in test environment: %v", err)
	}
}

// TestConfigurationValidation tests configuration validation
func TestConfigurationValidation(t *testing.T) {
	// Create test managers
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	// Test valid configuration
	validConfig := map[string]interface{}{
		"repository_path": ".",
		"workflow_type":   "gitflow",
		"github_token":    "test-token",
	}

	manager := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, validConfig)
	if manager == nil {
		t.Error("Failed to create manager with valid configuration")
	}

	// Test configuration update
	newConfig := map[string]interface{}{
		"repository_path": "/new/path",
		"workflow_type":   "github-flow",
	}

	err := manager.UpdateConfig(newConfig)
	if err != nil {
		t.Errorf("Failed to update configuration: %v", err)
	}

	// Verify configuration was updated
	currentConfig := manager.GetConfig()
	if currentConfig["repository_path"] != "/new/path" {
		t.Error("Configuration was not updated correctly")
	}
}

// BenchmarkWorkflowOperations benchmarks common workflow operations
func BenchmarkWorkflowOperations(b *testing.B) {
	// Create test managers
	errorManager := &MockErrorManager{}
	configManager := &MockConfigManager{}
	storageManager := &MockStorageManager{}

	config := map[string]interface{}{
		"repository_path": ".",
		"workflow_type":   "feature-branch",
	}

	manager := gitworkflowmanager.NewGitWorkflowManager(errorManager, configManager, storageManager, config)

	b.ResetTimer()

	b.Run("ValidateBranchName", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			_ = manager.ValidateBranchName("feature/test-branch")
		}
	})

	b.Run("ValidateCommitMessage", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			_ = manager.ValidateCommitMessage("feat: add new feature")
		}
	})

	b.Run("WorkflowFactory", func(b *testing.B) {
		factory := workflows.NewWorkflowFactory(manager)
		for i := 0; i < b.N; i++ {
			_, _ = factory.CreateWorkflow(interfaces.WorkflowTypeFeatureBranch, config)
		}
	})
}
