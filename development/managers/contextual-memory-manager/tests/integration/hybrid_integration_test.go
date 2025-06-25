// tests/integration/hybrid_integration_test.go
package integration

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/development"
	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/interfaces"
)

type HybridIntegrationSuite struct {
	suite.Suite
	manager  interfaces.ContextualMemoryManager
	ctx      context.Context
	testData *TestDataManager
}

func (suite *HybridIntegrationSuite) SetupSuite() {
	suite.ctx = context.Background()
	suite.testData = NewTestDataManager()

	// Initialiser le manager avec configuration de test
	config := LoadTestConfig()
	suite.manager = CreateTestManager(config)

	err := suite.manager.Initialize(suite.ctx)
	require.NoError(suite.T(), err)

	// Préparer les données de test
	err = suite.testData.SetupTestProject()
	require.NoError(suite.T(), err)
}

func (suite *HybridIntegrationSuite) TearDownSuite() {
	suite.testData.Cleanup()
	if cleaner, ok := suite.manager.(interface{ Cleanup() }); ok {
		cleaner.Cleanup()
	}
}

func (suite *HybridIntegrationSuite) TestFullWorkflow() {
	// 1. Capturer des actions sur du code
	actions := suite.testData.GenerateCodeActions()
	for _, action := range actions {
		err := suite.manager.CaptureAction(suite.ctx, action)
		require.NoError(suite.T(), err)
	}

	// 2. Recherche hybride
	query := interfaces.ContextQuery{
		Text:          "database connection initialization",
		WorkspacePath: suite.testData.GetProjectPath(),
		Limit:         10,
	}

	results, err := suite.manager.SearchContextHybrid(suite.ctx, query)
	require.NoError(suite.T(), err)
	assert.NotEmpty(suite.T(), results)

	// 3. Vérifier l'enrichissement AST
	for _, result := range results {
		if result.Context != nil {
			astContext, hasAST := result.Context["ast_context"]
			if hasAST {
				assert.NotNil(suite.T(), astContext)
			}
		}
	}

	// 4. Analyser la structure du code
	astResult, err := suite.manager.AnalyzeCodeStructure(suite.ctx, suite.testData.GetSampleFile())
	require.NoError(suite.T(), err)
	assert.NotEmpty(suite.T(), astResult.Functions)

	// 5. Obtenir le contexte temps réel
	realTimeCtx, err := suite.manager.GetRealTimeContext(suite.ctx, suite.testData.GetSampleFile(), 15)
	require.NoError(suite.T(), err)
	assert.NotNil(suite.T(), realTimeCtx)
}

func (suite *HybridIntegrationSuite) TestPerformanceTargets() {
	query := interfaces.ContextQuery{
		Text:          "func NewManager",
		WorkspacePath: suite.testData.GetProjectPath(),
		Limit:         5,
	}

	// Test cible de performance
	start := time.Now()
	results, err := suite.manager.SearchContextHybrid(suite.ctx, query)
	duration := time.Since(start)

	require.NoError(suite.T(), err)
	assert.NotEmpty(suite.T(), results)

	// Vérifier les objectifs de performance
	assert.LessOrEqual(suite.T(), duration, 500*time.Millisecond, "Search should complete within 500ms")

	// Vérifier la qualité des résultats
	avgScore := calculateAverageScore(results)
	assert.GreaterOrEqual(suite.T(), avgScore, 0.7, "Average result quality should be >= 0.7")
}

func (suite *HybridIntegrationSuite) TestModeAdaptation() {
	// Test adaptation automatique du mode selon le contexte

	scenarios := []struct {
		name         string
		query        interfaces.ContextQuery
		expectedMode string
	}{
		{
			name: "code_structure_query",
			query: interfaces.ContextQuery{
				Text:          "type UserManager struct",
				WorkspacePath: suite.testData.GetProjectPath(),
			},
			expectedMode: "ast",
		},
		{
			name: "semantic_search_query",
			query: interfaces.ContextQuery{
				Text:          "find code that handles user authentication",
				WorkspacePath: suite.testData.GetProjectPath(),
			},
			expectedMode: "hybrid",
		},
	}

	for _, scenario := range scenarios {
		suite.T().Run(scenario.name, func(t *testing.T) {
			results, err := suite.manager.SearchContextHybrid(suite.ctx, scenario.query)
			require.NoError(t, err)

			// Vérifier que le mode approprié a été utilisé
			for _, result := range results {
				if result.Context != nil {
					if searchMode, exists := result.Context["search_mode"]; exists {
						switch scenario.expectedMode {
						case "ast":
							assert.Contains(t, searchMode, "ast")
						case "hybrid":
							assert.Contains(t, []string{"hybrid", "parallel"}, searchMode)
						}
					}
				}
			}
		})
	}
}

func TestHybridIntegration(t *testing.T) {
	suite.Run(t, new(HybridIntegrationSuite))
}

// TestDataManager gère les données de test
type TestDataManager struct {
	projectPath string
	sampleFile  string
}

func NewTestDataManager() *TestDataManager {
	return &TestDataManager{
		projectPath: "./testdata/sample_project",
		sampleFile:  "./testdata/sample_project/main.go",
	}
}

func (tdm *TestDataManager) SetupTestProject() error {
	// Créer la structure de test si nécessaire
	return nil
}

func (tdm *TestDataManager) Cleanup() {
	// Nettoyer les données de test
}

func (tdm *TestDataManager) GetProjectPath() string {
	return tdm.projectPath
}

func (tdm *TestDataManager) GetSampleFile() string {
	return tdm.sampleFile
}

func (tdm *TestDataManager) GenerateCodeActions() []interfaces.Action {
	return []interfaces.Action{
		{
			Type:      "edit",
			FilePath:  tdm.sampleFile,
			Line:      1,
			Content:   "package main",
			Timestamp: time.Now(),
		},
		{
			Type:      "navigate",
			FilePath:  tdm.sampleFile,
			Line:      10,
			Content:   "func main() {",
			Timestamp: time.Now(),
		},
	}
}

// LoadTestConfig charge la configuration de test
func LoadTestConfig() *interfaces.Config {
	return &interfaces.Config{
		VectorDBPath:     "./testdata/vector_db",
		WorkspacePath:    "./testdata/sample_project",
		CacheSize:        100,
		EnableHybridMode: true,
		ASTCacheTimeout:  300,
		HybridConfig: &interfaces.HybridConfig{
			DefaultMode:      interfaces.ModeHybridParallel,
			ASTWeight:        0.6,
			RAGWeight:        0.4,
			QualityThreshold: 0.7,
			MaxConcurrency:   4,
		},
	}
}

// CreateTestManager crée un manager de test
func CreateTestManager(config *interfaces.Config) interfaces.ContextualMemoryManager {
	return development.NewContextualMemoryManager(config)
}

// calculateAverageScore calcule le score moyen des résultats
func calculateAverageScore(results []interfaces.ContextResult) float64 {
	if len(results) == 0 {
		return 0
	}

	total := 0.0
	for _, result := range results {
		total += result.Score
	}

	return total / float64(len(results))
}
