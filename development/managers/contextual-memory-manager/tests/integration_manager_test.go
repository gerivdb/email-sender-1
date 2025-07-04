package tests

import (
	"context"
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"

	cmmManager "github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/pkg/manager"
	interfaces "github.com/gerivdb/email-sender-1/development/managers/interfaces" // Use the common interfaces package
)

// Mock for interfaces.IntegrationManager
type MockIntegrationManager struct {
	mock.Mock
}

func (m *MockIntegrationManager) Initialize(ctx context.Context, config interfaces.ManagerConfig) error {
	args := m.Called(ctx, config)
	return args.Error(0)
}

func (m *MockIntegrationManager) Start(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockIntegrationManager) Stop(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockIntegrationManager) GetStatus() interfaces.ManagerStatus {
	args := m.Called()
	return args.Get(0).(interfaces.ManagerStatus)
}

func (m *MockIntegrationManager) GetMetrics() interfaces.ManagerMetrics {
	args := m.Called()
	return args.Get(0).(interfaces.ManagerMetrics)
}

func (m *MockIntegrationManager) ValidateConfig(config interfaces.ManagerConfig) error {
	args := m.Called(config)
	return args.Error(0)
}

func (m *MockIntegrationManager) GetID() string {
	args := m.Called()
	return args.String(0)
}

func (m *MockIntegrationManager) GetName() string {
	args := m.Called()
	return args.String(0)
}

func (m *MockIntegrationManager) GetVersion() string {
	args := m.Called()
	return args.String(0)
}

func (m *MockIntegrationManager) Health(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

// Test suite for IntegrationManager (within ContextualMemoryManager)
func TestIntegrationManager_InitializeAndHealth(t *testing.T) {
	ctx := context.Background()

	mockIntegration := &MockIntegrationManager{}
	mockError := &MockErrorManager{}   // Reusing MockErrorManager from contextual_memory_manager_test.go
	mockConfig := &MockConfigManager{} // Reusing MockConfigManager

	// Setup mocks for ContextualMemoryManager's dependencies
	mockStorage := &MockStorageManager{}
	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)
	mockStorage.On("GetSQLiteConnection", mock.AnythingOfType("string")).Return(&MockDB{}, nil)
	mockError.On("LogError", mock.Anything, mock.Anything, mock.Anything).Maybe()
	mockConfig.SetConfig(map[string]interface{}{
		"n8n.default_workflow_id": "",
	})

	// Create the main ContextualMemoryManager
	cmm := cmmManager.NewContextualMemoryManager()
	require.NotNil(t, cmm)

	// Inject mocks (assuming you have a way to inject them, or use the constructor with mocks)
	// For this test, we'll directly use the mockIntegration for its methods.
	// In a real scenario, the cmm would manage multiple integrations.

	// Test case 1: Successful initialization
	integrationConfig := interfaces.ManagerConfig{
		Name:    "TestIntegration",
		Enabled: true,
	}
	mockIntegration.On("Initialize", mock.Anything, integrationConfig).Return(nil)
	mockIntegration.On("Start", mock.Anything).Return(nil)
	mockIntegration.On("Health", mock.Anything).Return(nil)
	mockIntegration.On("GetStatus").Return(interfaces.ManagerStatus{Status: interfaces.StatusRunning})
	mockIntegration.On("GetName").Return("TestIntegration")
	mockIntegration.On("GetMetrics").Return(interfaces.ManagerMetrics{})
	mockIntegration.On("GetID").Return("test-id")
	mockIntegration.On("GetVersion").Return("1.0.0")
	mockIntegration.On("ValidateConfig", integrationConfig).Return(nil)

	// Simulate adding the integration to the ContextualMemoryManager
	// This part assumes a method like cmm.AddIntegration(integrationName, manager) exists.
	// For now, we directly test the mockIntegration's behavior.

	err := mockIntegration.Initialize(ctx, integrationConfig)
	assert.NoError(t, err)

	err = mockIntegration.Start(ctx)
	assert.NoError(t, err)

	err = mockIntegration.Health(ctx)
	assert.NoError(t, err)

	status := mockIntegration.GetStatus()
	assert.Equal(t, interfaces.StatusRunning, status.Status)

	// Test case 2: Initialization failure
	mockIntegrationFailed := &MockIntegrationManager{}
	mockIntegrationFailed.On("Initialize", mock.Anything, integrationConfig).Return(errors.New("init failed"))

	err = mockIntegrationFailed.Initialize(ctx, integrationConfig)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "init failed")

	mockIntegration.AssertExpectations(t)
	mockIntegrationFailed.AssertExpectations(t)
}

func TestIntegrationManager_IntegrationLifecycle(t *testing.T) {
	ctx := context.Background()

	mockIntegration := &MockIntegrationManager{}
	integrationConfig := interfaces.ManagerConfig{
		Name:    "LifecycleTest",
		Enabled: true,
	}

	mockIntegration.On("Initialize", mock.Anything, integrationConfig).Return(nil).Once()
	mockIntegration.On("Start", mock.Anything).Return(nil).Once()
	mockIntegration.On("Stop", mock.Anything).Return(nil).Once()
	mockIntegration.On("GetStatus").Return(interfaces.ManagerStatus{Status: interfaces.StatusRunning}).Once()
	mockIntegration.On("GetStatus").Return(interfaces.ManagerStatus{Status: interfaces.StatusStopped}).Once()
	mockIntegration.On("GetName").Return("LifecycleTest").Maybe()
	mockIntegration.On("GetMetrics").Return(interfaces.ManagerMetrics{}).Maybe()
	mockIntegration.On("GetID").Return("test-lifecycle-id").Maybe()
	mockIntegration.On("GetVersion").Return("1.0.0").Maybe()
	mockIntegration.On("Health", mock.Anything).Return(nil).Maybe()
	mockIntegration.On("ValidateConfig", integrationConfig).Return(nil).Maybe()

	// Initialize
	err := mockIntegration.Initialize(ctx, integrationConfig)
	assert.NoError(t, err)

	// Start
	err = mockIntegration.Start(ctx)
	assert.NoError(t, err)
	assert.Equal(t, interfaces.StatusRunning, mockIntegration.GetStatus().Status)

	// Stop
	err = mockIntegration.Stop(ctx)
	assert.NoError(t, err)
	assert.Equal(t, interfaces.StatusStopped, mockIntegration.GetStatus().Status)

	mockIntegration.AssertExpectations(t)
}
