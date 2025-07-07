// advanced_classifier_test.go - Tests pour Classification Intelligente Multi-Critères
// Phase 2.2 du Framework de Branchement Automatique
package commitinterceptor_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	commitinterceptor "github.com/gerivdb/email-sender-1/development/hooks/commit-interceptor"
)

func TestMultiCriteriaClassifier_HybridClassification(t *testing.T) {
	// Setup
	semanticManager := setupMockSemanticManagerForClassifier(t)
	fallbackAnalyzer := commitinterceptor.NewCommitAnalyzer(getTestConfig())
	classifier := commitinterceptor.NewMultiCriteriaClassifier(semanticManager, fallbackAnalyzer)

	hybridTestCases := []struct {
		name              string
		commitData        *commitinterceptor.CommitData
		expectedType      string
		expectedConfidence float64
		expectedFactors   map[string]float64
		description       string
	}{
		{
			name: "Clear feature - high semantic + traditional agreement",
			commitData: &commitinterceptor.CommitData{
				Message: "feat: implement advanced user authentication with OAuth2",
				Files:   []string{"auth.go", "oauth.go", "user_service.go"},
				Hash:    "abc123",
				Author:  "test-user",
			},
			expectedType:       "feature",
			expectedConfidence: 0.90,
			expectedFactors: map[string]float64{
				"semantic_score":     0.85,
				"message_patterns":   0.95,
				"file_analysis":      0.80,
				"impact_detection":   0.70,
			},
			description: "Clear feature with strong multi-criteria consensus",
		},
		{
			name: "Ambiguous message - semantic resolves uncertainty",
			commitData: &commitinterceptor.CommitData{
				Message: "update code for better handling",
				Files:   []string{"handler.go", "utils.go"},
				Hash:    "def456",
				Author:  "test-user",
			},
			expectedType:       "refactor", // Résolu par analyse sémantique
			expectedConfidence: 0.70,
			expectedFactors: map[string]float64{
				"semantic_score":     0.75, // IA détecte refactoring
				"message_patterns":   0.50, // Message ambigu
				"file_analysis":      0.80,
				"impact_detection":   0.60,
			},
			description: "Message ambigu résolu par analyse sémantique",
		},
		{
			name: "Conflicting signals - weighted decision",
			commitData: &commitinterceptor.CommitData{
				Message: "fix: add new dashboard feature",
				Files:   []string{"dashboard.go", "main.go", "config.yml"},
				Hash:    "ghi789",
				Author:  "test-user",
			},
			expectedType:       "feature", // Contenu > prefix
			expectedConfidence: 0.75,
			expectedFactors: map[string]float64{
				"semantic_score":     0.80, // IA détecte feature malgré "fix:"
				"message_patterns":   0.70, // Conflits prefix vs contenu
				"file_analysis":      0.75, // Fichiers suggèrent feature
				"impact_detection":   0.70, // Impact modéré
			},
			description: "Signaux conflictuels résolus par pondération",
		},
		{
			name: "Documentation update - consensus low impact",
			commitData: &commitinterceptor.CommitData{
				Message: "docs: update API documentation with examples",
				Files:   []string{"README.md", "api-guide.md"},
				Hash:    "jkl012",
				Author:  "test-user",
			},
			expectedType:       "docs",
			expectedConfidence: 0.85,
			expectedFactors: map[string]float64{
				"semantic_score":     0.80,
				"message_patterns":   0.90,
				"file_analysis":      0.60, // Documentation files
				"impact_detection":   0.50, // Low impact
			},
			description: "Documentation avec consensus multi-critères",
		},
		{
			name: "Critical security fix - high priority detection",
			commitData: &commitinterceptor.CommitData{
				Message: "fix: critical security vulnerability in authentication",
				Files:   []string{"auth.go", "security.go", "middleware.go"},
				Hash:    "mno345",
				Author:  "test-user",
			},
			expectedType:       "fix",
			expectedConfidence: 0.95,
			expectedFactors: map[string]float64{
				"semantic_score":     0.90, // IA détecte criticité
				"message_patterns":   0.95, // Pattern "fix:" + "critical"
				"file_analysis":      0.85, // Fichiers de sécurité
				"impact_detection":   0.90, // High impact détecté
			},
			description: "Fix critique avec détection haute priorité",
		},
	}

	for _, tc := range hybridTestCases {
		t.Run(tc.name, func(t *testing.T) {
			// Mesure performance
			start := time.Now()

			// Classification avancée
			result, err := classifier.ClassifyCommitAdvanced(context.Background(), tc.commitData)

			duration := time.Since(start)

			// Validations principales
			require.NoError(t, err)
			assert.Equal(t, tc.expectedType, result.PredictedType)
			assert.GreaterOrEqual(t, result.Confidence, tc.expectedConfidence-0.10)
			assert.Less(t, duration, 100*time.Millisecond, "Classification trop lente")

			// Validation facteurs de décision
			for factor, expectedScore := range tc.expectedFactors {
				if actualScore, exists := result.DecisionFactors[factor]; exists {
					assert.InDelta(t, expectedScore, actualScore, 0.15,
						"Factor %s score incorrect: expected %.2f, got %.2f",
						factor, expectedScore, actualScore)
				}
			}

			// Validation insights sémantiques
			assert.NotNil(t, result.SemanticInsights)
			assert.NotEmpty(t, result.SemanticInsights.TopKeywords)
			assert.GreaterOrEqual(t, result.CompositeScore, 0.0)
			assert.LessOrEqual(t, result.CompositeScore, 1.0)

			// Validation alternatives
			assert.NotEmpty(t, result.AlternativeTypes)

			// Validation prédiction de conflits
			assert.NotNil(t, result.ConflictPrediction)
			assert.GreaterOrEqual(t, result.ConflictPrediction.Probability, 0.0)
			assert.LessOrEqual(t, result.ConflictPrediction.Probability, 1.0)

			t.Logf("✅ %s: Type=%s, Confidence=%.2f, CompositeScore=%.2f, ProcessingTime=%v",
				tc.description, result.PredictedType, result.Confidence, result.CompositeScore, duration)
		})
	}
}

func TestMultiCriteriaClassifier_CachePerformance(t *testing.T) {
	classifier := setupClassifierForTesting(t)

	commitData := &commitinterceptor.CommitData{
		Message: "feat: implement user dashboard",
		Files:   []string{"dashboard.go", "user.go"},
		Hash:    "cache123",
		Author:  "test-user",
	}

	// Premier appel - mise en cache
	start := time.Now()
	result1, err := classifier.ClassifyCommitAdvanced(context.Background(), commitData)
	firstCallDuration := time.Since(start)

	require.NoError(t, err)
	assert.False(t, result1.CacheHit, "Premier appel ne devrait pas être un cache hit")

	// Deuxième appel - depuis le cache
	start = time.Now()
	result2, err := classifier.ClassifyCommitAdvanced(context.Background(), commitData)
	secondCallDuration := time.Since(start)

	require.NoError(t, err)
	assert.True(t, result2.CacheHit, "Deuxième appel devrait être un cache hit")
	assert.Less(t, secondCallDuration, firstCallDuration, "Cache devrait être plus rapide")

	// Validation que les résultats sont identiques
	assert.Equal(t, result1.PredictedType, result2.PredictedType)
	assert.Equal(t, result1.CompositeScore, result2.CompositeScore)

	t.Logf("✅ Cache performance: First=%.2fms, Cached=%.2fms, Speedup=%.1fx",
		float64(firstCallDuration.Nanoseconds())/1000000,
		float64(secondCallDuration.Nanoseconds())/1000000,
		float64(firstCallDuration)/float64(secondCallDuration))
}

func TestMultiCriteriaClassifier_ConflictPrediction(t *testing.T) {
	classifier := setupClassifierForTesting(t)

	conflictTestCases := []struct {
		name                string
		commitData          *commitinterceptor.CommitData
		expectedProbability float64
		expectedStrategy    string
		expectedRiskFactors int
		description         string
	}{
		{
			name: "Low risk - single file change",
			commitData: &commitinterceptor.CommitData{
				Message: "docs: update README",
				Files:   []string{"README.md"},
				Hash:    "low123",
				Author:  "test-user",
			},
			expectedProbability: 0.1,
			expectedStrategy:    "auto",
			expectedRiskFactors: 0,
			description:         "Changement simple sans risque",
		},
		{
			name: "Medium risk - multiple files",
			commitData: &commitinterceptor.CommitData{
				Message: "feat: add new API endpoints",
				Files:   []string{"api.go", "handler.go", "model.go", "test.go"},
				Hash:    "med456",
				Author:  "test-user",
			},
			expectedProbability: 0.4,
			expectedStrategy:    "careful-merge",
			expectedRiskFactors: 1,
			description:         "Changements multiples avec risque modéré",
		},
		{
			name: "High risk - critical files + many changes",
			commitData: &commitinterceptor.CommitData{
				Message: "refactor: major architectural changes",
				Files:   []string{"main.go", "config.yml", "Dockerfile", "go.mod", "api.go", "db.go"},
				Hash:    "high789",
				Author:  "test-user",
			},
			expectedProbability: 0.8,
			expectedStrategy:    "manual-review",
			expectedRiskFactors: 3,
			description:         "Changements critiques nécessitant revue manuelle",
		},
	}

	for _, tc := range conflictTestCases {
		t.Run(tc.name, func(t *testing.T) {
			result, err := classifier.ClassifyCommitAdvanced(context.Background(), tc.commitData)

			require.NoError(t, err)
			assert.NotNil(t, result.ConflictPrediction)

			prediction := result.ConflictPrediction
			assert.InDelta(t, tc.expectedProbability, prediction.Probability, 0.2,
				"Probabilité de conflit incorrecte")
			assert.Equal(t, tc.expectedStrategy, prediction.SuggestedStrategy)
			assert.GreaterOrEqual(t, len(prediction.RiskFactors), tc.expectedRiskFactors)

			t.Logf("✅ %s: Probability=%.2f, Strategy=%s, RiskFactors=%d",
				tc.description, prediction.Probability, prediction.SuggestedStrategy, len(prediction.RiskFactors))
		})
	}
}

func TestMultiCriteriaClassifier_AlternativeTypes(t *testing.T) {
	classifier := setupClassifierForTesting(t)

	// Cas avec message ambigu pour tester les alternatives
	commitData := &commitinterceptor.CommitData{
		Message: "improve authentication flow",
		Files:   []string{"auth.go", "login.go"},
		Hash:    "alt123",
		Author:  "test-user",
	}

	result, err := classifier.ClassifyCommitAdvanced(context.Background(), commitData)

	require.NoError(t, err)
	assert.NotEmpty(t, result.AlternativeTypes, "Devrait avoir des types alternatifs")

	// Vérifier que les alternatives sont triées par score
	if len(result.AlternativeTypes) > 1 {
		for i := 0; i < len(result.AlternativeTypes)-1; i++ {
			assert.GreaterOrEqual(t, result.AlternativeTypes[i].Score, result.AlternativeTypes[i+1].Score,
				"Les alternatives devraient être triées par score décroissant")
		}
	}

	// Vérifier que chaque alternative a un reasoning
	for _, alt := range result.AlternativeTypes {
		assert.NotEmpty(t, alt.Type)
		assert.NotEmpty(t, alt.Reasoning)
		assert.GreaterOrEqual(t, alt.Score, 0.0)
		assert.LessOrEqual(t, alt.Score, 1.0)
	}

	t.Logf("✅ Generated %d alternatives for ambiguous commit", len(result.AlternativeTypes))
}

func TestMultiCriteriaClassifier_SemanticInsights(t *testing.T) {
	classifier := setupClassifierForTesting(t)

	commitData := &commitinterceptor.CommitData{
		Message: "feat: implement OAuth2 authentication with JWT tokens",
		Files:   []string{"auth.go", "oauth.go", "jwt.go", "middleware.go"},
		Hash:    "insight123",
		Author:  "test-user",
	}

	result, err := classifier.ClassifyCommitAdvanced(context.Background(), commitData)

	require.NoError(t, err)
	assert.NotNil(t, result.SemanticInsights)

	insights := result.SemanticInsights
	assert.NotEmpty(t, insights.TopKeywords, "Devrait avoir des mots-clés extraits")
	assert.GreaterOrEqual(t, insights.NoveltyScore, 0.0)
	assert.LessOrEqual(t, insights.NoveltyScore, 1.0)
	assert.GreaterOrEqual(t, insights.ContextualRelevance, 0.0)
	assert.LessOrEqual(t, insights.ContextualRelevance, 1.0)

	// Vérifier que les clusters sémantiques sont pertinents
	if len(insights.SemanticClusters) > 0 {
		assert.Contains(t, insights.SemanticClusters, "feature", "Devrait contenir le type prédit")
	}

	t.Logf("✅ Semantic insights: Keywords=%v, Clusters=%v, Novelty=%.2f",
		insights.TopKeywords, insights.SemanticClusters, insights.NoveltyScore)
}

func TestMultiCriteriaClassifier_BranchSuggestion(t *testing.T) {
	classifier := setupClassifierForTesting(t)

	branchTestCases := []struct {
		name         string
		commitData   *commitinterceptor.CommitData
		expectedPattern string
		description  string
	}{
		{
			name: "Feature branch suggestion",
			commitData: &commitinterceptor.CommitData{
				Message: "feat: add user profile management",
				Files:   []string{"user.go", "profile.go"},
				Hash:    "branch123",
				Author:  "test-user",
			},
			expectedPattern: "feature/",
			description:     "Devrait suggérer une branche feature",
		},
		{
			name: "Bugfix branch suggestion",
			commitData: &commitinterceptor.CommitData{
				Message: "fix: resolve memory leak in cache",
				Files:   []string{"cache.go"},
				Hash:    "branch456",
				Author:  "test-user",
			},
			expectedPattern: "bugfix/",
			description:     "Devrait suggérer une branche bugfix",
		},
		{
			name: "Documentation to develop",
			commitData: &commitinterceptor.CommitData{
				Message: "docs: update installation guide",
				Files:   []string{"INSTALL.md"},
				Hash:    "branch789",
				Author:  "test-user",
			},
			expectedPattern: "develop",
			description:     "Documentation devrait aller sur develop",
		},
	}

	for _, tc := range branchTestCases {
		t.Run(tc.name, func(t *testing.T) {
			result, err := classifier.ClassifyCommitAdvanced(context.Background(), tc.commitData)

			require.NoError(t, err)
			assert.NotEmpty(t, result.RecommendedBranch)

			if tc.expectedPattern == "develop" {
				assert.Equal(t, "develop", result.RecommendedBranch)
			} else {
				assert.Contains(t, result.RecommendedBranch, tc.expectedPattern)
			}

			t.Logf("✅ %s: Suggested branch=%s", tc.description, result.RecommendedBranch)
		})
	}
}

func TestMultiCriteriaClassifier_WeightingSystem(t *testing.T) {
	classifier := setupClassifierForTesting(t)

	// Tester l'influence des poids sur la classification
	originalWeights := classifier.weights

	// Test 1: Priorité à l'analyse sémantique
	classifier.weights.SemanticScore = 0.8
	classifier.weights.MessagePatterns = 0.1
	classifier.weights.FileAnalysis = 0.05
	classifier.weights.ImpactDetection = 0.03
	classifier.weights.HistoricalContext = 0.02

	commitData := &commitinterceptor.CommitData{
		Message: "update configuration", // Message ambigu
		Files:   []string{"config.go"},
		Hash:    "weight123",
		Author:  "test-user",
	}

	result1, err := classifier.ClassifyCommitAdvanced(context.Background(), commitData)
	require.NoError(t, err)

	// Test 2: Priorité aux patterns traditionnels
	classifier.weights.SemanticScore = 0.1
	classifier.weights.MessagePatterns = 0.8
	classifier.weights.FileAnalysis = 0.05
	classifier.weights.ImpactDetection = 0.03
	classifier.weights.HistoricalContext = 0.02

	// Vider le cache pour forcer une nouvelle classification
	delete(classifier.performanceCache, classifier.generateCacheKey(commitData))

	result2, err := classifier.ClassifyCommitAdvanced(context.Background(), commitData)
	require.NoError(t, err)

	// Les résultats peuvent différer selon la pondération
	t.Logf("✅ Weighting impact: Semantic-heavy=%s, Traditional-heavy=%s",
		result1.PredictedType, result2.PredictedType)

	// Restaurer les poids originaux
	classifier.weights = originalWeights

	assert.NotEqual(t, result1.CompositeScore, result2.CompositeScore,
		"Les scores composites devraient différer avec des pondérations différentes")
}

// Fonctions utilitaires pour les tests

func setupClassifierForTesting(t *testing.T) *commitinterceptor.MultiCriteriaClassifier {
	semanticManager := setupMockSemanticManagerForClassifier(t)
	fallbackAnalyzer := commitinterceptor.NewCommitAnalyzer(getTestConfig())
	return commitinterceptor.NewMultiCriteriaClassifier(semanticManager, fallbackAnalyzer)
}

func setupMockSemanticManagerForClassifier(t *testing.T) *commitinterceptor.SemanticEmbeddingManager {
	// Utiliser le mock existant avec quelques adaptations pour le classificateur
	mockAutonomy := commitinterceptor.NewMockAdvancedAutonomyManager()
	mockMemory := commitinterceptor.NewMockContextualMemory()
	
	config := &commitinterceptor.Config{
		Server: commitinterceptor.ServerConfig{
			Port: 8080,
			Host: "localhost",
		},
		Git: commitinterceptor.GitConfig{
			DefaultBranch: "main",
			RemoteName:    "origin",
		},
		Routing: commitinterceptor.RoutingConfig{
			DefaultStrategy: "type-based",
		},
		Logging: commitinterceptor.LoggingConfig{
			Level: "info",
		},
	}
	
	return &commitinterceptor.SemanticEmbeddingManager{
		autonomyManager:    mockAutonomy,
		contextualMemory:   mockMemory,
		config:             config,
		embeddingCache:     make(map[string][]float64),
		commitHistoryCache: make(map[string]*commitinterceptor.CommitContext),
		semanticThreshold:  0.7,
		maxHistorySize:     1000,
	}
}

func TestMultiCriteriaClassifier_PerformanceMetrics(t *testing.T) {
	classifier := setupClassifierForTesting(t)

	// Exécuter plusieurs classifications pour tester les métriques
	for i := 0; i < 5; i++ {
		commitData := &commitinterceptor.CommitData{
			Message: fmt.Sprintf("feat: test classification %d", i),
			Files:   []string{"test.go"},
			Hash:    fmt.Sprintf("perf%d", i),
			Author:  "test-user",
		}

		_, err := classifier.ClassifyCommitAdvanced(context.Background(), commitData)
		require.NoError(t, err)
	}

	// Vérifier les métriques
	metrics := classifier.metricsCollector
	assert.Equal(t, int64(5), metrics.TotalClassifications)
	assert.Greater(t, metrics.AverageProcessingTime, time.Duration(0))
	assert.NotZero(t, metrics.LastUpdated)

	t.Logf("✅ Performance metrics: Total=%d, AvgTime=%v",
		metrics.TotalClassifications, metrics.AverageProcessingTime)
}