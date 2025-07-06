package tests

import (
	"context"
	"testing"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/development"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/interfaces"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
)

// Mock implementations for testing
type MockStorageManager struct {
	mock.Mock
}

func (m *MockStorageManager) Initialize(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockStorageManager) Shutdown(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockStorageManager) GetStatus() string {
	args := m.Called()
	return args.String(0)
}

func (m *MockStorageManager) GetPostgreSQLConnection() (interface{}, error) {
	args := m.Called()
	return args.Get(0), args.Error(1)
}

func (m *MockStorageManager) GetSQLiteConnection(dbPath string) (interface{}, error) {
	args := m.Called(dbPath)
	return args.Get(0), args.Error(1)
}

type MockErrorManager struct {
	mock.Mock
}

func (m *MockErrorManager) Initialize(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockErrorManager) Shutdown(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockErrorManager) GetStatus() string {
	args := m.Called()
	return args.String(0)
}

func (m *MockErrorManager) LogError(ctx context.Context, message string, err error) {
	m.Called(ctx, message, err)
}

func (m *MockErrorManager) ProcessError(ctx context.Context, err error) error {
	args := m.Called(ctx, err)
	return args.Error(0)
}

type MockConfigManager struct {
	mock.Mock
	config map[string]interface{}
}

func (m *MockConfigManager) Initialize(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockConfigManager) Shutdown(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockConfigManager) GetStatus() string {
	args := m.Called()
	return args.String(0)
}

func (m *MockConfigManager) GetString(key string) string {
	if m.config == nil {
		return ""
	}
	if val, ok := m.config[key].(string); ok {
		return val
	}
	return ""
}

func (m *MockConfigManager) GetInt(key string) int {
	if m.config == nil {
		return 0
	}
	if val, ok := m.config[key].(int); ok {
		return val
	}
	return 0
}

func (m *MockConfigManager) GetBool(key string) bool {
	if m.config == nil {
		return false
	}
	if val, ok := m.config[key].(bool); ok {
		return val
	}
	return false
}

func (m *MockConfigManager) SetConfig(config map[string]interface{}) {
	m.config = config
}

// Test suite for ContextualMemoryManager
func TestContextualMemoryManager_Initialize(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	// Setup expectations
	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)
	mockStorage.On("GetSQLiteConnection", mock.AnythingOfType("string")).Return(&MockDB{}, nil)
	mockError.On("LogError", mock.Anything, mock.Anything, mock.Anything).Maybe()
	mockConfig.SetConfig(map[string]interface{}{
		"n8n.default_workflow_id": "",
	})

	// Create manager
	manager := development.NewContextualMemoryManager(mockStorage, mockError, mockConfig)
	require.NotNil(t, manager)

	// Test initialization
	err := manager.Initialize(ctx)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestContextualMemoryManager_CaptureAction(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)
	mockStorage.On("GetSQLiteConnection", mock.AnythingOfType("string")).Return(&MockDB{}, nil)
	mockError.On("LogError", mock.Anything, mock.Anything, mock.Anything).Maybe()
	mockConfig.SetConfig(map[string]interface{}{
		"n8n.default_workflow_id": "",
	})

	// Create and initialize manager
	manager := development.NewContextualMemoryManager(mockStorage, mockError, mockConfig)
	require.NotNil(t, manager)

	err := manager.Initialize(ctx)
	require.NoError(t, err)

	// Test action capture
	action := interfaces.Action{
		ID:            "test-action-1",
		Type:          "edit",
		Text:          "Test action text",
		WorkspacePath: "/test/workspace",
		FilePath:      "/test/file.go",
		LineNumber:    42,
		Timestamp:     time.Now(),
		Metadata: map[string]interface{}{
			"test_meta": "test_value",
		},
	}

	err = manager.CaptureAction(ctx, action)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestContextualMemoryManager_SearchContext(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)
	mockStorage.On("GetSQLiteConnection", mock.AnythingOfType("string")).Return(&MockDB{}, nil)
	mockError.On("LogError", mock.Anything, mock.Anything, mock.Anything).Maybe()
	mockConfig.SetConfig(map[string]interface{}{
		"n8n.default_workflow_id": "",
	})

	// Create and initialize manager
	manager := development.NewContextualMemoryManager(mockStorage, mockError, mockConfig)
	require.NotNil(t, manager)

	err := manager.Initialize(ctx)
	require.NoError(t, err)

	// Test context search
	query := interfaces.ContextQuery{
		Text:                "test search",
		WorkspacePath:       "/test/workspace",
		ActionTypes:         []string{"edit", "search"},
		Limit:               10,
		SimilarityThreshold: 0.7,
	}

	results, err := manager.SearchContext(ctx, query)
	assert.NoError(t, err)
	assert.NotNil(t, results)
	// Results can be empty for a mock implementation

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestContextualMemoryManager_SessionManagement(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)
	mockStorage.On("GetSQLiteConnection", mock.AnythingOfType("string")).Return(&MockDB{}, nil)
	mockError.On("LogError", mock.Anything, mock.Anything, mock.Anything).Maybe()
	mockConfig.SetConfig(map[string]interface{}{
		"n8n.default_workflow_id": "",
	})

	// Create and initialize manager
	manager := development.NewContextualMemoryManager(mockStorage, mockError, mockConfig)
	require.NotNil(t, manager)

	err := manager.Initialize(ctx)
	require.NoError(t, err)

	// Test session start
	sessionID, err := manager.StartSession(ctx, "/test/workspace")
	assert.NoError(t, err)
	assert.NotEmpty(t, sessionID)

	// Test getting session actions
	actions, err := manager.GetSessionActions(ctx, sessionID)
	assert.NoError(t, err)
	assert.NotNil(t, actions)

	// Test session end
	err = manager.EndSession(ctx, sessionID)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestContextualMemoryManager_BatchCaptureActions(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)
	mockStorage.On("GetSQLiteConnection", mock.AnythingOfType("string")).Return(&MockDB{}, nil)
	mockError.On("LogError", mock.Anything, mock.Anything, mock.Anything).Maybe()
	mockConfig.SetConfig(map[string]interface{}{
		"n8n.default_workflow_id": "",
	})

	// Create and initialize manager
	manager := development.NewContextualMemoryManager(mockStorage, mockError, mockConfig)
	require.NotNil(t, manager)

	err := manager.Initialize(ctx)
	require.NoError(t, err)

	// Test batch capture
	actions := []interfaces.Action{
		{
			ID:            "batch-action-1",
			Type:          "edit",
			Text:          "First batch action",
			WorkspacePath: "/test/workspace",
			Timestamp:     time.Now(),
		},
		{
			ID:            "batch-action-2",
			Type:          "search",
			Text:          "Second batch action",
			WorkspacePath: "/test/workspace",
			Timestamp:     time.Now(),
		},
	}

	err = manager.BatchCaptureActions(ctx, actions)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestContextualMemoryManager_GetMetrics(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)
	mockStorage.On("GetSQLiteConnection", mock.AnythingOfType("string")).Return(&MockDB{}, nil)
	mockError.On("LogError", mock.Anything, mock.Anything, mock.Anything).Maybe()
	mockConfig.SetConfig(map[string]interface{}{
		"n8n.default_workflow_id": "",
	})

	// Create and initialize manager
	manager := development.NewContextualMemoryManager(mockStorage, mockError, mockConfig)
	require.NotNil(t, manager)

	err := manager.Initialize(ctx)
	require.NoError(t, err)

	// Test metrics retrieval
	metrics, err := manager.GetMetrics(ctx)
	assert.NoError(t, err)
	assert.NotNil(t, metrics)
	assert.GreaterOrEqual(t, metrics.TotalActions, int64(0))
	assert.GreaterOrEqual(t, metrics.CacheHitRatio, 0.0)
	assert.LessOrEqual(t, metrics.CacheHitRatio, 1.0)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

// Mock database for testing
type MockDB struct{}

func (m *MockDB) Close() error { return nil }
func (m *MockDB) Ping() error  { return nil }
