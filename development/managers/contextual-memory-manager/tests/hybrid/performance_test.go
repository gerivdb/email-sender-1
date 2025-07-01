// tests/hybrid/performance_test.go
package hybrid

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"EMAIL_SENDER_1/development/managers/contextual-memory-manager/development"
	"EMAIL_SENDER_1/development/managers/contextual-memory-manager/interfaces"
)

func BenchmarkASTSearch(b *testing.B) {
	ctx := context.Background()
	manager := setupTestManager(b)

	query := interfaces.ContextQuery{
		Text:          "function main",
		WorkspacePath: "./testdata/sample_project",
		Limit:         10,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := manager.executeASTSearch(ctx, query)
		require.NoError(b, err)
	}
}

func BenchmarkRAGSearch(b *testing.B) {
	ctx := context.Background()
	manager := setupTestManager(b)

	query := interfaces.ContextQuery{
		Text:          "function main",
		WorkspacePath: "./testdata/sample_project",
		Limit:         10,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := manager.SearchContext(ctx, query)
		require.NoError(b, err)
	}
}

func BenchmarkHybridSearch(b *testing.B) {
	ctx := context.Background()
	manager := setupTestManager(b)

	query := interfaces.ContextQuery{
		Text:          "function main",
		WorkspacePath: "./testdata/sample_project",
		Limit:         10,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := manager.SearchContextHybrid(ctx, query)
		require.NoError(b, err)
	}
}

func TestSearchQualityComparison(t *testing.T) {
	ctx := context.Background()
	manager := setupTestManager(t)

	testCases := []struct {
		name        string
		query       interfaces.ContextQuery
		expectedAST int // Nombre de résultats AST attendus
		expectedRAG int // Nombre de résultats RAG attendus
		minQuality  float64
	}{
		{
			name: "structural_query",
			query: interfaces.ContextQuery{
				Text:          "func NewManager",
				WorkspacePath: "./testdata/sample_project",
				Limit:         5,
			},
			expectedAST: 3,
			expectedRAG: 2,
			minQuality:  0.8,
		},
		{
			name: "semantic_query",
			query: interfaces.ContextQuery{
				Text:          "initialize database connection",
				WorkspacePath: "./testdata/sample_project",
				Limit:         5,
			},
			expectedAST: 1,
			expectedRAG: 4,
			minQuality:  0.7,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Test AST
			astResults, err := manager.executeASTSearch(ctx, tc.query)
			require.NoError(t, err)

			// Test RAG
			ragResults, err := manager.SearchContext(ctx, tc.query)
			require.NoError(t, err)

			// Test Hybride
			hybridResults, err := manager.SearchContextHybrid(ctx, tc.query)
			require.NoError(t, err)

			// Vérifications
			assert.GreaterOrEqual(t, len(astResults), tc.expectedAST-1, "AST results count")
			assert.GreaterOrEqual(t, len(ragResults), tc.expectedRAG-1, "RAG results count")
			assert.LessOrEqual(t, len(hybridResults), tc.query.Limit, "Hybrid results within limit")

			// Vérifier la qualité
			for _, result := range hybridResults {
				assert.GreaterOrEqual(t, result.Score, tc.minQuality, "Result quality score")
			}
		})
	}
}

func TestModeSelection(t *testing.T) {
	ctx := context.Background()
	selector := setupTestModeSelector(t)

	testCases := []struct {
		name          string
		query         interfaces.ContextQuery
		expectedMode  interfaces.HybridMode
		minConfidence float64
	}{
		{
			name: "go_code_query",
			query: interfaces.ContextQuery{
				Text:          "func main() {",
				WorkspacePath: "./testdata/sample.go",
			},
			expectedMode:  interfaces.ModePureAST,
			minConfidence: 0.8,
		},
		{
			name: "documentation_query",
			query: interfaces.ContextQuery{
				Text:          "how to use this library",
				WorkspacePath: "./testdata/",
			},
			expectedMode:  interfaces.ModePureRAG,
			minConfidence: 0.7,
		},
		{
			name: "mixed_query",
			query: interfaces.ContextQuery{
				Text:          "function that handles user authentication",
				WorkspacePath: "./testdata/sample_project",
			},
			expectedMode:  interfaces.ModeHybridASTFirst,
			minConfidence: 0.6,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			decision, err := selector.SelectOptimalMode(ctx, tc.query)
			require.NoError(t, err)

			assert.Equal(t, tc.expectedMode, decision.SelectedMode)
			assert.GreaterOrEqual(t, decision.Confidence, tc.minConfidence)
			assert.NotEmpty(t, decision.Reasoning)
		})
	}
}

// setupTestManager initialise un manager de test
func setupTestManager(tb testing.TB) interfaces.ContextualMemoryManager {
	config := &interfaces.Config{
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

	manager := development.NewContextualMemoryManager(config)
	ctx := context.Background()
	err := manager.Initialize(ctx)
	require.NoError(tb, err)

	return manager
}

// setupTestModeSelector initialise un sélecteur de mode de test
func setupTestModeSelector(tb testing.TB) interfaces.HybridModeSelector {
	// Implémentation pour les tests
	// Retourner un mock ou une instance de test
	return nil // À implémenter selon l'architecture
}
