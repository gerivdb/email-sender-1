package tests

import (
	"context"
	"testing"
	"time"

	"github.com/email-sender/development/managers/contextual-memory-manager/interfaces"
	"github.com/email-sender/development/managers/contextual-memory-manager/internal/retrieval"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRetrievalManager_Initialize(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockIndex := &MockIndexManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)

	// Create retrieval manager
	retrievalMgr, err := retrieval.NewRetrievalManager(mockStorage, mockError, mockConfig, mockIndex, mockMonitoring)
	require.NoError(t, err)
	require.NotNil(t, retrievalMgr)

	// Test initialization
	err = retrievalMgr.Initialize(ctx)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}

func TestRetrievalManager_SearchContext(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockIndex := &MockIndexManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)

	// Create and initialize retrieval manager
	retrievalMgr, err := retrieval.NewRetrievalManager(mockStorage, mockError, mockConfig, mockIndex, mockMonitoring)
	require.NoError(t, err)

	err = retrievalMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test context search
	query := interfaces.ContextQuery{
		Text:          "test search query",
		WorkspacePath: "/test/workspace",
		ActionTypes:   []string{"edit", "search"},
		TimeRange: interfaces.TimeRange{
			Start: time.Now().Add(-24 * time.Hour),
			End:   time.Now(),
		},
		Limit:               10,
		SimilarityThreshold: 0.7,
	}

	results, err := retrievalMgr.SearchContext(ctx, query)
	assert.NoError(t, err)
	assert.NotNil(t, results)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}

func TestRetrievalManager_UpdateContext(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockIndex := &MockIndexManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)

	// Create and initialize retrieval manager
	retrievalMgr, err := retrieval.NewRetrievalManager(mockStorage, mockError, mockConfig, mockIndex, mockMonitoring)
	require.NoError(t, err)

	err = retrievalMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test context update
	contextID := "test-context-id"
	updates := interfaces.ContextUpdate{
		Text: "Updated context text",
		Metadata: map[string]interface{}{
			"updated_at": time.Now().Unix(),
			"version":    2,
		},
	}

	err = retrievalMgr.UpdateContext(ctx, contextID, updates)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}

func TestRetrievalManager_DeleteContext(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockIndex := &MockIndexManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)
	mockError.On("LogError", ctx, "Deleted 0 contextual actions for context ID: test-context-id", nil).Maybe()

	// Create and initialize retrieval manager
	retrievalMgr, err := retrieval.NewRetrievalManager(mockStorage, mockError, mockConfig, mockIndex, mockMonitoring)
	require.NoError(t, err)

	err = retrievalMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test context deletion
	contextID := "test-context-id"
	err = retrievalMgr.DeleteContext(ctx, contextID)
	assert.NoError(t, err)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
	mockError.AssertExpectations(t)
}

func TestRetrievalManager_GetContextHistory(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockIndex := &MockIndexManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)

	// Create and initialize retrieval manager
	retrievalMgr, err := retrieval.NewRetrievalManager(mockStorage, mockError, mockConfig, mockIndex, mockMonitoring)
	require.NoError(t, err)

	err = retrievalMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test context history retrieval
	userID := "test-user-id"
	limit := 20

	history, err := retrievalMgr.GetContextHistory(ctx, userID, limit)
	assert.NoError(t, err)
	assert.NotNil(t, history)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}

func TestRetrievalManager_SearchByText(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockIndex := &MockIndexManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)

	// Create and initialize retrieval manager
	retrievalMgr, err := retrieval.NewRetrievalManager(mockStorage, mockError, mockConfig, mockIndex, mockMonitoring)
	require.NoError(t, err)

	err = retrievalMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test text search
	text := "search text"
	workspacePath := "/test/workspace"
	limit := 15

	results, err := retrievalMgr.SearchByText(ctx, text, workspacePath, limit)
	assert.NoError(t, err)
	assert.NotNil(t, results)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}

func TestRetrievalManager_GetActionsBySession(t *testing.T) {
	ctx := context.Background()

	// Setup mocks
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}
	mockIndex := &MockIndexManager{}
	mockMonitoring := &MockMonitoringManager{}

	mockStorage.On("GetPostgreSQLConnection").Return(&MockDB{}, nil)

	// Create and initialize retrieval manager
	retrievalMgr, err := retrieval.NewRetrievalManager(mockStorage, mockError, mockConfig, mockIndex, mockMonitoring)
	require.NoError(t, err)

	err = retrievalMgr.Initialize(ctx)
	require.NoError(t, err)

	// Test session actions retrieval
	sessionID := "test-session-id"

	actions, err := retrievalMgr.GetActionsBySession(ctx, sessionID)
	assert.NoError(t, err)
	assert.NotNil(t, actions)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}

// Mock IndexManager for testing
type MockIndexManager struct {
	baseInterfaces.BaseManager
}

func (m *MockIndexManager) IndexAction(ctx context.Context, action interfaces.Action) error {
	return nil
}

func (m *MockIndexManager) SearchSimilar(ctx context.Context, vector []float64, limit int) ([]interfaces.SimilarResult, error) {
	return []interfaces.SimilarResult{}, nil
}

func (m *MockIndexManager) CacheEmbedding(ctx context.Context, text string, vector []float64) error {
	return nil
}

func (m *MockIndexManager) GetCacheStats(ctx context.Context) (map[string]interface{}, error) {
	return map[string]interface{}{}, nil
}

func (m *MockIndexManager) DeleteFromIndex(ctx context.Context, contextID string) error {
	return nil
}
