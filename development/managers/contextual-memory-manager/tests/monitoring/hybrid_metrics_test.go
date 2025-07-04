// tests/monitoring/hybrid_metrics_test.go
package monitoring

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"go.uber.org/zap/zaptest"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/internal/monitoring"
)

func TestHybridMetricsCollector(t *testing.T) {
	logger := zaptest.NewLogger(t)
	collector := monitoring.NewHybridMetricsCollector(logger)

	t.Run("RecordQuery", func(t *testing.T) {
		// Enregistrer quelques requêtes
		collector.RecordQuery("ast", 100*time.Millisecond, true, 0.8)
		collector.RecordQuery("rag", 200*time.Millisecond, true, 0.7)
		collector.RecordQuery("hybrid", 150*time.Millisecond, false, 0.6)

		stats := collector.GetStatistics()

		// Vérifier les compteurs
		assert.Equal(t, int64(3), stats.TotalQueries)
		assert.Equal(t, int64(1), stats.ASTQueries)
		assert.Equal(t, int64(1), stats.RAGQueries)
		assert.Equal(t, int64(1), stats.HybridQueries)

		// Vérifier les métriques de performance
		assert.Contains(t, stats.AverageLatency, "ast")
		assert.Contains(t, stats.SuccessRates, "ast")
		assert.Contains(t, stats.QualityScores, "ast")

		// Vérifier les valeurs
		assert.Equal(t, 1.0, stats.SuccessRates["ast"])
		assert.Equal(t, 1.0, stats.SuccessRates["rag"])
		assert.Equal(t, 0.0, stats.SuccessRates["hybrid"])

		assert.Equal(t, 0.8, stats.QualityScores["ast"])
		assert.Equal(t, 0.7, stats.QualityScores["rag"])
		assert.Equal(t, 0.6, stats.QualityScores["hybrid"])
	})

	t.Run("RecordModeSelection", func(t *testing.T) {
		collector.Reset()

		// Enregistrer des sélections de mode
		collector.RecordModeSelection("ast", "ast", 0.9) // Correct
		collector.RecordModeSelection("rag", "ast", 0.7) // Incorrect
		collector.RecordModeSelection("ast", "ast", 0.8) // Correct

		stats := collector.GetStatistics()

		assert.Equal(t, int64(2), stats.ModeSelections["ast"])
		assert.Equal(t, int64(1), stats.ModeSelections["rag"])

		// Vérifier la précision
		assert.Equal(t, 1.0, stats.ModeAccuracy["ast"]) // 2/2 correct
		assert.Equal(t, 0.0, stats.ModeAccuracy["rag"]) // 0/1 correct
	})

	t.Run("RecordError", func(t *testing.T) {
		collector.Reset()

		err1 := assert.AnError
		err2 := assert.AnError

		collector.RecordError("ast", err1)
		collector.RecordError("rag", err2)
		collector.RecordError("ast", err1)

		stats := collector.GetStatistics()

		assert.Equal(t, int64(2), stats.ErrorCounts["ast"])
		assert.Equal(t, int64(1), stats.ErrorCounts["rag"])
		assert.Len(t, stats.LastErrors, 3)

		// Vérifier le dernier erreur
		lastError := stats.LastErrors[len(stats.LastErrors)-1]
		assert.Equal(t, "ast", lastError.Mode)
		assert.Equal(t, err1.Error(), lastError.Message)
	})

	t.Run("RecordCacheHit", func(t *testing.T) {
		collector.Reset()

		// Simuler des hits et misses de cache
		collector.RecordCacheHit("ast", true)
		collector.RecordCacheHit("ast", true)
		collector.RecordCacheHit("ast", false)
		collector.RecordCacheHit("rag", true)

		stats := collector.GetStatistics()

		// Les taux de cache doivent être calculés
		assert.Contains(t, stats.CacheHitRates, "ast_cache")
		assert.Contains(t, stats.CacheHitRates, "rag_cache")

		// Le taux pour RAG devrait être 1.0 (un seul hit)
		assert.Equal(t, 1.0, stats.CacheHitRates["rag_cache"])
	})

	t.Run("RecordMemoryUsage", func(t *testing.T) {
		collector.Reset()

		collector.RecordMemoryUsage("ast", 1024*1024) // 1MB
		collector.RecordMemoryUsage("rag", 2048*1024) // 2MB

		stats := collector.GetStatistics()

		assert.Equal(t, int64(1024*1024), stats.MemoryUsage["ast"])
		assert.Equal(t, int64(2048*1024), stats.MemoryUsage["rag"])
	})

	t.Run("GetMetricsSummary", func(t *testing.T) {
		collector.Reset()

		// Ajouter quelques données
		collector.RecordQuery("ast", 100*time.Millisecond, true, 0.8)
		collector.RecordQuery("rag", 200*time.Millisecond, true, 0.7)
		collector.RecordMemoryUsage("ast", 1024*1024)

		summary := collector.GetMetricsSummary()

		// Vérifier la structure
		assert.Contains(t, summary, "total_queries")
		assert.Contains(t, summary, "mode_distribution")
		assert.Contains(t, summary, "performance")
		assert.Contains(t, summary, "optimization")
		assert.Contains(t, summary, "reliability")

		// Vérifier les valeurs
		assert.Equal(t, int64(2), summary["total_queries"])

		modeDistribution := summary["mode_distribution"].(map[string]int64)
		assert.Equal(t, int64(1), modeDistribution["ast"])
		assert.Equal(t, int64(1), modeDistribution["rag"])
	})

	t.Run("PeriodicReporting", func(t *testing.T) {
		collector.Reset()

		ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
		defer cancel()

		// Démarrer le reporting périodique
		collector.StartPeriodicReporting(ctx)

		// Ajouter quelques métriques
		collector.RecordQuery("ast", 100*time.Millisecond, true, 0.8)

		// Attendre un peu pour que le reporting se déclenche
		time.Sleep(50 * time.Millisecond)

		// Arrêter le collector
		collector.Stop()

		// Pas d'assertion spécifique, juste vérifier qu'il n'y a pas de panic
	})

	t.Run("ConcurrentAccess", func(t *testing.T) {
		collector.Reset()

		// Test d'accès concurrent
		done := make(chan bool)
		numGoroutines := 10

		for i := 0; i < numGoroutines; i++ {
			go func(id int) {
				defer func() { done <- true }()

				for j := 0; j < 100; j++ {
					mode := "ast"
					if j%2 == 0 {
						mode = "rag"
					}

					collector.RecordQuery(mode, time.Duration(j)*time.Millisecond, j%3 == 0, float64(j)/100.0)
					collector.RecordCacheHit(mode, j%2 == 0)
					collector.RecordMemoryUsage(mode, int64(j*1024))

					// Lire les statistiques périodiquement
					if j%10 == 0 {
						_ = collector.GetStatistics()
						_ = collector.GetMetricsSummary()
					}
				}
			}(i)
		}

		// Attendre que toutes les goroutines se terminent
		for i := 0; i < numGoroutines; i++ {
			<-done
		}

		stats := collector.GetStatistics()

		// Vérifier que nous avons bien enregistré toutes les requêtes
		expectedTotal := int64(numGoroutines * 100)
		assert.Equal(t, expectedTotal, stats.TotalQueries)

		// Vérifier que nous avons des données dans toutes les catégories
		assert.NotEmpty(t, stats.AverageLatency)
		assert.NotEmpty(t, stats.SuccessRates)
		assert.NotEmpty(t, stats.QualityScores)
		assert.NotEmpty(t, stats.CacheHitRates)
		assert.NotEmpty(t, stats.MemoryUsage)
	})
}

func TestErrorHandling(t *testing.T) {
	logger := zaptest.NewLogger(t)
	collector := monitoring.NewHybridMetricsCollector(logger)

	t.Run("ErrorListLimit", func(t *testing.T) {
		collector.Reset()

		// Ajouter plus de 100 erreurs pour tester la limite
		for i := 0; i < 150; i++ {
			collector.RecordError("test", assert.AnError)
		}

		stats := collector.GetStatistics()

		// Vérifier que la liste est limitée à 100
		assert.LessOrEqual(t, len(stats.LastErrors), 100)
		assert.Equal(t, int64(150), stats.ErrorCounts["test"])
	})
}

func BenchmarkHybridMetricsCollector(b *testing.B) {
	logger := zaptest.NewLogger(b)
	collector := monitoring.NewHybridMetricsCollector(logger)

	b.Run("RecordQuery", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			collector.RecordQuery("ast", 100*time.Millisecond, true, 0.8)
		}
	})

	b.Run("GetStatistics", func(b *testing.B) {
		// Ajouter quelques données d'abord
		for i := 0; i < 1000; i++ {
			collector.RecordQuery("ast", 100*time.Millisecond, true, 0.8)
		}

		b.ResetTimer()
		for i := 0; i < b.N; i++ {
			_ = collector.GetStatistics()
		}
	})

	b.Run("ConcurrentRecordQuery", func(b *testing.B) {
		b.RunParallel(func(pb *testing.PB) {
			for pb.Next() {
				collector.RecordQuery("ast", 100*time.Millisecond, true, 0.8)
			}
		})
	})
}
