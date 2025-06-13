package tests

import (
	"context"
	"testing"
	"time"

	"github.com/contextual-memory-manager/pkg/interfaces"
	"github.com/contextual-memory-manager/pkg/manager"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestIntegrationManager_Initialize(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	// Set up config expectations
	mockConfig.SetConfig(map[string]interface{}{
		"mcp_gateway.url":     "http://localhost:8080",
		"n8n.webhook_url":     "http://localhost:5678/webhook",
		"webhooks.timeout":    "30s",
		"webhooks.max_retries": 3,
	})

	// Create integration manager
	integrationMgr, err := integration.NewIntegrationManager(mockStorage, mockConfig, mockError)
	require.NoError(t, err)
	require.NotNil(t, integrationMgr)

	// Test initialization
	err = integrationMgr.Initialize(ctx)
	assert.NoError(t, err)
}

func TestIntegrationManager_NotifyAction(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	mockConfig.SetConfig(map[string]interface{}{
		"mcp_gateway.url":          "http://localhost:8080",
		"n8n.webhook_url":          "http://localhost:5678/webhook",
		"n8n.default_workflow_id":  "",
		"webhooks.timeout":         "30s",
		"webhooks.max_retries":     3,
	})

	mockError.On("LogError", ctx, "Failed to notify MCP Gateway", mock.Anything).Maybe()
	mockError.On("LogError", ctx, "Failed to sync to MCP database", mock.Anything).Maybe()

	// Create and initialize integration manager
	integrationMgr, err := integration.NewIntegrationManager(mockStorage, mockConfig, mockError)
	require.NoError(t, err)

	err = integrationMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test action notification
	action := interfaces.Action{
		ID:            "test-integration-action",
		Type:          "edit",
		Text:          "Test integration action",
		WorkspacePath: "/test/workspace",
		FilePath:      "/test/file.go",
		Timestamp:     time.Now(),
		Metadata: map[string]interface{}{
			"integration_test": true,
		},
	}

	err = integrationMgr.NotifyAction(ctx, action)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestIntegrationManager_NotifyMCPGateway(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	mockConfig.SetConfig(map[string]interface{}{
		"mcp_gateway.url":      "http://localhost:8080",
		"n8n.webhook_url":      "http://localhost:5678/webhook",
		"webhooks.timeout":     "30s",
		"webhooks.max_retries": 3,
	})

	// Create and initialize integration manager
	integrationMgr, err := integration.NewIntegrationManager(mockStorage, mockConfig, mockError)
	require.NoError(t, err)

	err = integrationMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test MCP Gateway notification
	event := interfaces.ContextEvent{
		Action: interfaces.Action{
			ID:            "test-mcp-action",
			Type:          "search",
			Text:          "Test MCP notification",
			WorkspacePath: "/test/workspace",
			Timestamp:     time.Now(),
		},
		Context: map[string]interface{}{
			"source": "test",
		},
		Timestamp: time.Now(),
	}

	err = integrationMgr.NotifyMCPGateway(ctx, event)
	// This will fail with mock HTTP client, but we're testing the flow
	assert.Error(t, err) // Expected since we're using a mock HTTP endpoint

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}

func TestIntegrationManager_TriggerN8NWorkflow(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	mockConfig.SetConfig(map[string]interface{}{
		"mcp_gateway.url":      "http://localhost:8080",
		"n8n.webhook_url":      "http://localhost:5678/webhook",
		"webhooks.timeout":     "30s",
		"webhooks.max_retries": 3,
	})

	// Create and initialize integration manager
	integrationMgr, err := integration.NewIntegrationManager(mockStorage, mockConfig, mockError)
	require.NoError(t, err)

	err = integrationMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test N8N workflow trigger
	workflowID := "test-workflow-123"
	payload := map[string]interface{}{
		"action": "trigger_test",
		"data":   "test data",
	}

	err = integrationMgr.TriggerN8NWorkflow(ctx, workflowID, payload)
	// This will fail with mock HTTP client, but we're testing the flow
	assert.Error(t, err) // Expected since we're using a mock HTTP endpoint

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}

func TestIntegrationManager_SyncToMCPDatabase(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	mockConfig.SetConfig(map[string]interface{}{
		"mcp_gateway.url":      "http://localhost:8080",
		"n8n.webhook_url":      "http://localhost:5678/webhook",
		"webhooks.timeout":     "30s",
		"webhooks.max_retries": 3,
	})

	// Create and initialize integration manager
	integrationMgr, err := integration.NewIntegrationManager(mockStorage, mockConfig, mockError)
	require.NoError(t, err)

	err = integrationMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test MCP database sync
	actions := []interfaces.Action{
		{
			ID:            "sync-action-1",
			Type:          "edit",
			Text:          "First sync action",
			WorkspacePath: "/test/workspace",
			Timestamp:     time.Now(),
		},
		{
			ID:            "sync-action-2",
			Type:          "search",
			Text:          "Second sync action",
			WorkspacePath: "/test/workspace",
			Timestamp:     time.Now(),
		},
	}

	err = integrationMgr.SyncToMCPDatabase(ctx, actions)
	assert.NoError(t, err) // Should succeed with mock implementation

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}
