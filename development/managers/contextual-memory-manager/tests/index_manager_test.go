package tests

import (
	"context"
	"testing"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/internal/indexing"
	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/pkg/interfaces"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestIndexManager_Initialize(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetSQLiteConnection", "./data/contextual_embedding_cache.db").Return(&MockDB{}, nil)
	mockError.On("LogError", ctx, "index_manager", "Initialized IndexManager successfully", nil).Maybe()

	// Create index manager
	indexMgr, err := indexing.NewIndexManager(mockStorage, mockError, mockConfig, mockMonitoring)
	require.NoError(t, err)
	require.NotNil(t, indexMgr)

	// Test initialization
	err = indexMgr.Initialize(ctx)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestIndexManager_IndexAction(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetSQLiteConnection", "./data/contextual_embedding_cache.db").Return(&MockDB{}, nil)
	mockError.On("LogError", ctx, "index_manager", "Initialized IndexManager successfully", nil).Maybe()

	// Create and initialize index manager
	indexMgr, err := indexing.NewIndexManager(mockStorage, mockError, mockConfig, mockMonitoring)
	require.NoError(t, err)

	err = indexMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test action indexing
	action := interfaces.Action{
		ID:            "test-index-action",
		Type:          "edit",
		Text:          "Test indexing action",
		WorkspacePath: "/test/workspace",
		FilePath:      "/test/file.go",
	}

	err = indexMgr.IndexAction(ctx, action)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestIndexManager_SearchSimilar(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetSQLiteConnection", "./data/contextual_embedding_cache.db").Return(&MockDB{}, nil)
	mockError.On("LogError", ctx, "index_manager", "Initialized IndexManager successfully", nil).Maybe()

	// Create and initialize index manager
	indexMgr, err := indexing.NewIndexManager(mockStorage, mockError, mockConfig, mockMonitoring)
	require.NoError(t, err)

	err = indexMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test similarity search
	vector := make([]float64, 384)
	for i := range vector {
		vector[i] = 0.1 // Simple test vector
	}

	results, err := indexMgr.SearchSimilar(ctx, vector, 5)
	assert.NoError(t, err)
	assert.NotNil(t, results)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestIndexManager_CacheEmbedding(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetSQLiteConnection", "./data/contextual_embedding_cache.db").Return(&MockDB{}, nil)
	mockError.On("LogError", ctx, "index_manager", "Initialized IndexManager successfully", nil).Maybe()

	// Create and initialize index manager
	indexMgr, err := indexing.NewIndexManager(mockStorage, mockError, mockConfig, mockMonitoring)
	require.NoError(t, err)

	err = indexMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test embedding caching
	text := "Test text for embedding"
	vector := make([]float64, 384)
	for i := range vector {
		vector[i] = float64(i) * 0.01
	}

	err = indexMgr.CacheEmbedding(ctx, text, vector)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestIndexManager_DeleteFromIndex(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetSQLiteConnection", "./data/contextual_embedding_cache.db").Return(&MockDB{}, nil)
	mockError.On("LogError", ctx, "index_manager", "Initialized IndexManager successfully", nil).Maybe()

	// Create and initialize index manager
	indexMgr, err := indexing.NewIndexManager(mockStorage, mockError, mockConfig, mockMonitoring)
	require.NoError(t, err)

	err = indexMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test deletion from index
	contextID := "test-context-id"
	err = indexMgr.DeleteFromIndex(ctx, contextID)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestIndexManager_GetCacheStats(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetSQLiteConnection", "./data/contextual_embedding_cache.db").Return(&MockDB{}, nil)
	mockError.On("LogError", ctx, "index_manager", "Initialized IndexManager successfully", nil).Maybe()

	// Create and initialize index manager
	indexMgr, err := indexing.NewIndexManager(mockStorage, mockError, mockConfig, mockMonitoring)
	require.NoError(t, err)

	err = indexMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test cache stats retrieval
	stats, err := indexMgr.GetCacheStats(ctx)
	assert.NoError(t, err)
	assert.NotNil(t, stats)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

// Mock MonitoringManager for testing
type MockMonitoringManager struct {
	baseInterfaces.BaseManager
}

func (m *MockMonitoringManager) RecordOperation(ctx context.Context, operation string, duration interface{}, err error) error {
	return nil
}

func (m *MockMonitoringManager) GetMetrics(ctx context.Context) (interfaces.ManagerMetrics, error) {
	return interfaces.ManagerMetrics{}, nil
}

func (m *MockMonitoringManager) RecordCacheHit(ctx context.Context, hit bool) error {
	return nil
}

func (m *MockMonitoringManager) IncrementActiveSession(ctx context.Context) error {
	return nil
}

func (m *MockMonitoringManager) DecrementActiveSession(ctx context.Context) error {
	return nil
}
