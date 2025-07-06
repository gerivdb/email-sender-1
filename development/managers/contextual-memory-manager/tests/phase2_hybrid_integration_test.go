package development

import (
	"context"
	"testing"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/interfaces"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockStorageManager pour les tests
type MockStorageManager struct {
	mock.Mock
}

func (m *MockStorageManager) Initialize(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockStorageManager) Cleanup() error {
	args := m.Called()
	return args.Error(0)
}

func (m *MockStorageManager) HealthCheck(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockStorageManager) Store(ctx context.Context, key string, value interface{}) error {
	args := m.Called(ctx, key, value)
	return args.Error(0)
}

func (m *MockStorageManager) Retrieve(ctx context.Context, key string) (interface{}, error) {
	args := m.Called(ctx, key)
	return args.Get(0), args.Error(1)
}

func (m *MockStorageManager) Delete(ctx context.Context, key string) error {
	args := m.Called(ctx, key)
	return args.Error(0)
}

func (m *MockStorageManager) List(ctx context.Context, prefix string) ([]string, error) {
	args := m.Called(ctx, prefix)
	return args.Get(0).([]string), args.Error(1)
}

// MockErrorManager pour les tests
type MockErrorManager struct {
	mock.Mock
}

func (m *MockErrorManager) Initialize(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockErrorManager) Cleanup() error {
	args := m.Called()
	return args.Error(0)
}

func (m *MockErrorManager) HealthCheck(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockErrorManager) LogError(ctx context.Context, component string, message string, err error) {
	m.Called(ctx, component, message, err)
}

func (m *MockErrorManager) LogWarning(ctx context.Context, component string, message string) {
	m.Called(ctx, component, message)
}

func (m *MockErrorManager) LogInfo(ctx context.Context, component string, message string) {
	m.Called(ctx, component, message)
}

func (m *MockErrorManager) GetErrors(ctx context.Context, component string) ([]interfaces.ErrorRecord, error) {
	args := m.Called(ctx, component)
	return args.Get(0).([]interfaces.ErrorRecord), args.Error(1)
}

// MockConfigManager pour les tests
type MockConfigManager struct {
	mock.Mock
	config map[string]interface{}
}

func (m *MockConfigManager) Initialize(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockConfigManager) Cleanup() error {
	args := m.Called()
	return args.Error(0)
}

func (m *MockConfigManager) HealthCheck(ctx context.Context) error {
	args := m.Called(ctx)
	return args.Error(0)
}

func (m *MockConfigManager) GetString(key string) string {
	if m.config == nil {
		m.config = make(map[string]interface{})
	}
	if val, ok := m.config[key]; ok {
		return val.(string)
	}
	return ""
}

func (m *MockConfigManager) GetInt(key string) int {
	if m.config == nil {
		m.config = make(map[string]interface{})
	}
	if val, ok := m.config[key]; ok {
		return val.(int)
	}
	return 0
}

func (m *MockConfigManager) GetBool(key string) bool {
	if m.config == nil {
		m.config = make(map[string]interface{})
	}
	if val, ok := m.config[key]; ok {
		return val.(bool)
	}
	return false
}

func (m *MockConfigManager) GetFloat64(key string) float64 {
	if m.config == nil {
		m.config = make(map[string]interface{})
	}
	if val, ok := m.config[key]; ok {
		return val.(float64)
	}
	return 0.0
}

func (m *MockConfigManager) Set(key string, value interface{}) {
	if m.config == nil {
		m.config = make(map[string]interface{})
	}
	m.config[key] = value
}

func (m *MockConfigManager) GetAll() map[string]interface{} {
	if m.config == nil {
		m.config = make(map[string]interface{})
	}
	return m.config
}

func TestNewContextualMemoryManager(t *testing.T) {
	// Arrange
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	// Act
	manager := NewContextualMemoryManager(mockStorage, mockError, mockConfig)

	// Assert
	assert.NotNil(t, manager)
	impl := manager.(*contextualMemoryManagerImpl)
	assert.Equal(t, mockStorage, impl.storageManager)
	assert.Equal(t, mockError, impl.errorManager)
	assert.Equal(t, mockConfig, impl.configManager)
	assert.False(t, impl.initialized)
}

func TestHybridConfigLoading(t *testing.T) {
	// Arrange
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	manager := NewContextualMemoryManager(mockStorage, mockError, mockConfig)
	impl := manager.(*contextualMemoryManagerImpl)

	// Act
	config := impl.loadHybridConfig()

	// Assert
	assert.NotNil(t, config)
	assert.Equal(t, 0.8, config.ASTThreshold)
	assert.True(t, config.RAGFallbackEnabled)
	assert.Equal(t, 0.7, config.QualityScoreMin)
	assert.Equal(t, 1*time.Hour, config.MaxFileAge)
	assert.True(t, config.ParallelAnalysis)
	assert.Equal(t, 1*time.Second, config.MaxAnalysisTime)

	// Vérifier les extensions préférées
	assert.Contains(t, config.PreferAST, ".go")
	assert.Contains(t, config.PreferAST, ".js")
	assert.Contains(t, config.PreferAST, ".ts")
	assert.Contains(t, config.PreferRAG, ".md")
	assert.Contains(t, config.PreferRAG, ".txt")
}

func TestGetSupportedModes(t *testing.T) {
	// Arrange
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	manager := NewContextualMemoryManager(mockStorage, mockError, mockConfig)
	ctx := context.Background()

	// Act
	modes, err := manager.GetSupportedModes(ctx)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, modes)
	assert.Len(t, modes, 6)
	assert.Contains(t, modes, "automatic")
	assert.Contains(t, modes, "ast_first")
	assert.Contains(t, modes, "rag_first")
	assert.Contains(t, modes, "parallel")
	assert.Contains(t, modes, "ast_only")
	assert.Contains(t, modes, "rag_only")
}

func TestSetHybridMode(t *testing.T) {
	// Arrange
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	manager := NewContextualMemoryManager(mockStorage, mockError, mockConfig)
	impl := manager.(*contextualMemoryManagerImpl)
	impl.initialized = true
	impl.hybridConfig = impl.loadHybridConfig()

	ctx := context.Background()

	// Test différents modes
	testCases := []struct {
		mode     interfaces.HybridMode
		expected interface{}
	}{
		{interfaces.HybridModeASTFirst, 0.6},
		{interfaces.HybridModeRAGFirst, 0.9},
		{interfaces.HybridModeParallel, true},
		{interfaces.HybridModeRAGOnly, 1.0},
	}

	for _, tc := range testCases {
		t.Run(string(tc.mode), func(t *testing.T) {
			// Act
			err := manager.SetHybridMode(ctx, tc.mode)

			// Assert
			assert.NoError(t, err)

			switch tc.mode {
			case interfaces.HybridModeASTFirst:
				assert.Equal(t, tc.expected, impl.hybridConfig.ASTThreshold)
			case interfaces.HybridModeRAGFirst:
				assert.Equal(t, tc.expected, impl.hybridConfig.ASTThreshold)
			case interfaces.HybridModeParallel:
				assert.Equal(t, tc.expected, impl.hybridConfig.ParallelAnalysis)
			case interfaces.HybridModeRAGOnly:
				assert.Equal(t, tc.expected, impl.hybridConfig.ASTThreshold)
			}
		})
	}
}

func TestUpdateHybridConfig(t *testing.T) {
	// Arrange
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	manager := NewContextualMemoryManager(mockStorage, mockError, mockConfig)
	impl := manager.(*contextualMemoryManagerImpl)
	impl.initialized = true

	ctx := context.Background()

	newConfig := interfaces.HybridConfig{
		ASTThreshold:       0.5,
		RAGFallbackEnabled: false,
		QualityScoreMin:    0.8,
		MaxFileAge:         2 * time.Hour,
		PreferAST:          []string{".go", ".rs"},
		PreferRAG:          []string{".md"},
		ParallelAnalysis:   false,
		MaxAnalysisTime:    2 * time.Second,
	}

	// Act
	err := manager.UpdateHybridConfig(ctx, newConfig)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, impl.hybridConfig)
	assert.Equal(t, 0.5, impl.hybridConfig.ASTThreshold)
	assert.False(t, impl.hybridConfig.RAGFallbackEnabled)
	assert.Equal(t, 0.8, impl.hybridConfig.QualityScoreMin)
	assert.Equal(t, 2*time.Hour, impl.hybridConfig.MaxFileAge)
}

func TestUtilityFunctions(t *testing.T) {
	// Arrange
	mockStorage := &MockStorageManager{}
	mockError := &MockErrorManager{}
	mockConfig := &MockConfigManager{}

	manager := NewContextualMemoryManager(mockStorage, mockError, mockConfig)
	impl := manager.(*contextualMemoryManagerImpl)

	// Test extractNameFromQuery
	t.Run("extractNameFromQuery", func(t *testing.T) {
		result := impl.extractNameFromQuery("function getUserData")
		assert.Equal(t, "function getUserData", result)
	})

	// Test extractPackageFromQuery
	t.Run("extractPackageFromQuery", func(t *testing.T) {
		result := impl.extractPackageFromQuery("import package.module")
		assert.Equal(t, "", result) // Implementation simple retourne ""
	})

	// Test intersectStrings
	t.Run("intersectStrings", func(t *testing.T) {
		a := []string{"func1", "func2", "func3"}
		b := []string{"func2", "func3", "func4"}
		result := impl.intersectStrings(a, b)
		assert.Len(t, result, 2)
		assert.Contains(t, result, "func2")
		assert.Contains(t, result, "func3")
	})

	// Test diffStrings
	t.Run("diffStrings", func(t *testing.T) {
		a := []string{"func1", "func2", "func3"}
		b := []string{"func2", "func4"}
		result := impl.diffStrings(a, b)
		assert.Len(t, result, 2)
		assert.Contains(t, result, "func1")
		assert.Contains(t, result, "func3")
	})

	// Test max
	t.Run("max", func(t *testing.T) {
		assert.Equal(t, 5, max(3, 5))
		assert.Equal(t, 7, max(7, 2))
		assert.Equal(t, 4, max(4, 4))
	})
}
