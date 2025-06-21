// internal/monitoring/hybrid_metrics.go
package monitoring

import (
	"context"
	"sync"
	"time"

	"go.uber.org/zap"
)

type HybridMetricsCollector struct {
	stats          *HybridStatistics
	mu             sync.RWMutex
	logger         *zap.Logger
	updateInterval time.Duration
	stopChan       chan struct{}
}

type HybridStatistics struct {
	// Compteurs de requêtes
	TotalQueries    int64 `json:"total_queries"`
	ASTQueries      int64 `json:"ast_queries"`
	RAGQueries      int64 `json:"rag_queries"`
	HybridQueries   int64 `json:"hybrid_queries"`
	ParallelQueries int64 `json:"parallel_queries"`

	// Métriques de performance
	AverageLatency map[string]time.Duration `json:"average_latency"`
	SuccessRates   map[string]float64       `json:"success_rates"`
	QualityScores  map[string]float64       `json:"quality_scores"`

	// Cache et optimisations
	CacheHitRates map[string]float64 `json:"cache_hit_rates"`
	MemoryUsage   map[string]int64   `json:"memory_usage"`

	// Erreurs et problèmes
	ErrorCounts map[string]int64 `json:"error_counts"`
	LastErrors  []ErrorInfo      `json:"last_errors"`

	// Adaptation du mode
	ModeSelections map[string]int64   `json:"mode_selections"`
	ModeAccuracy   map[string]float64 `json:"mode_accuracy"`

	LastUpdated time.Time `json:"last_updated"`
}

type ErrorInfo struct {
	Mode      string    `json:"mode"`
	Message   string    `json:"message"`
	Timestamp time.Time `json:"timestamp"`
}

func NewHybridMetricsCollector(logger *zap.Logger) *HybridMetricsCollector {
	return &HybridMetricsCollector{
		stats: &HybridStatistics{
			AverageLatency: make(map[string]time.Duration),
			SuccessRates:   make(map[string]float64),
			QualityScores:  make(map[string]float64),
			CacheHitRates:  make(map[string]float64),
			MemoryUsage:    make(map[string]int64),
			ErrorCounts:    make(map[string]int64),
			ModeSelections: make(map[string]int64),
			ModeAccuracy:   make(map[string]float64),
			LastErrors:     make([]ErrorInfo, 0),
		},
		logger:         logger,
		updateInterval: 30 * time.Second,
		stopChan:       make(chan struct{}),
	}
}

func (hmc *HybridMetricsCollector) RecordQuery(mode string, duration time.Duration, success bool, qualityScore float64) {
	hmc.mu.Lock()
	defer hmc.mu.Unlock()

	hmc.stats.TotalQueries++

	switch mode {
	case "ast":
		hmc.stats.ASTQueries++
	case "rag":
		hmc.stats.RAGQueries++
	case "hybrid":
		hmc.stats.HybridQueries++
	case "parallel":
		hmc.stats.ParallelQueries++
	}

	// Mettre à jour la latence moyenne
	if current, exists := hmc.stats.AverageLatency[mode]; exists {
		hmc.stats.AverageLatency[mode] = (current + duration) / 2
	} else {
		hmc.stats.AverageLatency[mode] = duration
	}

	// Mettre à jour le taux de succès
	if current, exists := hmc.stats.SuccessRates[mode]; exists {
		total := hmc.getModeQueryCount(mode)
		successCount := int64(current * float64(total-1))
		if success {
			successCount++
		}
		hmc.stats.SuccessRates[mode] = float64(successCount) / float64(total)
	} else {
		if success {
			hmc.stats.SuccessRates[mode] = 1.0
		} else {
			hmc.stats.SuccessRates[mode] = 0.0
		}
	}

	// Mettre à jour le score de qualité
	if current, exists := hmc.stats.QualityScores[mode]; exists {
		hmc.stats.QualityScores[mode] = (current + qualityScore) / 2
	} else {
		hmc.stats.QualityScores[mode] = qualityScore
	}

	hmc.stats.LastUpdated = time.Now()
}

func (hmc *HybridMetricsCollector) GetStatistics() *HybridStatistics {
	hmc.mu.RLock()
	defer hmc.mu.RUnlock()

	// Copie profonde des statistiques
	statsCopy := &HybridStatistics{
		TotalQueries:    hmc.stats.TotalQueries,
		ASTQueries:      hmc.stats.ASTQueries,
		RAGQueries:      hmc.stats.RAGQueries,
		HybridQueries:   hmc.stats.HybridQueries,
		ParallelQueries: hmc.stats.ParallelQueries,
		LastUpdated:     hmc.stats.LastUpdated,

		AverageLatency: make(map[string]time.Duration),
		SuccessRates:   make(map[string]float64),
		QualityScores:  make(map[string]float64),
		CacheHitRates:  make(map[string]float64),
		MemoryUsage:    make(map[string]int64),
		ErrorCounts:    make(map[string]int64),
		ModeSelections: make(map[string]int64),
		ModeAccuracy:   make(map[string]float64),
	}

	// Copier les maps
	for k, v := range hmc.stats.AverageLatency {
		statsCopy.AverageLatency[k] = v
	}
	for k, v := range hmc.stats.SuccessRates {
		statsCopy.SuccessRates[k] = v
	}
	for k, v := range hmc.stats.QualityScores {
		statsCopy.QualityScores[k] = v
	}
	for k, v := range hmc.stats.CacheHitRates {
		statsCopy.CacheHitRates[k] = v
	}
	for k, v := range hmc.stats.MemoryUsage {
		statsCopy.MemoryUsage[k] = v
	}
	for k, v := range hmc.stats.ErrorCounts {
		statsCopy.ErrorCounts[k] = v
	}
	for k, v := range hmc.stats.ModeSelections {
		statsCopy.ModeSelections[k] = v
	}
	for k, v := range hmc.stats.ModeAccuracy {
		statsCopy.ModeAccuracy[k] = v
	}

	// Copier les erreurs récentes
	statsCopy.LastErrors = make([]ErrorInfo, len(hmc.stats.LastErrors))
	copy(statsCopy.LastErrors, hmc.stats.LastErrors)

	return statsCopy
}

func (hmc *HybridMetricsCollector) RecordModeSelection(selectedMode string, actualBest string, confidence float64) {
	hmc.mu.Lock()
	defer hmc.mu.Unlock()

	hmc.stats.ModeSelections[selectedMode]++

	// Calculer la précision de la sélection
	wasAccurate := selectedMode == actualBest
	if current, exists := hmc.stats.ModeAccuracy[selectedMode]; exists {
		total := hmc.stats.ModeSelections[selectedMode]
		accurateCount := int64(current * float64(total-1))
		if wasAccurate {
			accurateCount++
		}
		hmc.stats.ModeAccuracy[selectedMode] = float64(accurateCount) / float64(total)
	} else {
		if wasAccurate {
			hmc.stats.ModeAccuracy[selectedMode] = 1.0
		} else {
			hmc.stats.ModeAccuracy[selectedMode] = 0.0
		}
	}
}

func (hmc *HybridMetricsCollector) RecordError(mode string, err error) {
	hmc.mu.Lock()
	defer hmc.mu.Unlock()

	hmc.stats.ErrorCounts[mode]++

	// Ajouter à la liste des erreurs récentes
	errorInfo := ErrorInfo{
		Mode:      mode,
		Message:   err.Error(),
		Timestamp: time.Now(),
	}

	hmc.stats.LastErrors = append(hmc.stats.LastErrors, errorInfo)

	// Limiter la taille de la liste d'erreurs
	if len(hmc.stats.LastErrors) > 100 {
		hmc.stats.LastErrors = hmc.stats.LastErrors[1:]
	}
}

func (hmc *HybridMetricsCollector) RecordCacheHit(mode string, hit bool) {
	hmc.mu.Lock()
	defer hmc.mu.Unlock()

	cacheKey := mode + "_cache"

	if current, exists := hmc.stats.CacheHitRates[cacheKey]; exists {
		// Moyenne mobile sur les 1000 dernières requêtes
		weight := 0.999
		if hit {
			hmc.stats.CacheHitRates[cacheKey] = current*weight + (1.0)*(1-weight)
		} else {
			hmc.stats.CacheHitRates[cacheKey] = current*weight + (0.0)*(1-weight)
		}
	} else {
		if hit {
			hmc.stats.CacheHitRates[cacheKey] = 1.0
		} else {
			hmc.stats.CacheHitRates[cacheKey] = 0.0
		}
	}
}

func (hmc *HybridMetricsCollector) StartPeriodicReporting(ctx context.Context) {
	go func() {
		ticker := time.NewTicker(hmc.updateInterval)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				hmc.generatePeriodicReport()
			case <-hmc.stopChan:
				return
			case <-ctx.Done():
				return
			}
		}
	}()
}

func (hmc *HybridMetricsCollector) Stop() {
	close(hmc.stopChan)
}

func (hmc *HybridMetricsCollector) generatePeriodicReport() {
	stats := hmc.GetStatistics()

	hmc.logger.Info("Hybrid System Performance Report",
		zap.Int64("total_queries", stats.TotalQueries),
		zap.Int64("ast_queries", stats.ASTQueries),
		zap.Int64("rag_queries", stats.RAGQueries),
		zap.Int64("hybrid_queries", stats.HybridQueries),
		zap.Int64("parallel_queries", stats.ParallelQueries),
		zap.Any("average_latency", stats.AverageLatency),
		zap.Any("success_rates", stats.SuccessRates),
		zap.Any("quality_scores", stats.QualityScores),
		zap.Any("cache_hit_rates", stats.CacheHitRates),
	)
}

func (hmc *HybridMetricsCollector) getModeQueryCount(mode string) int64 {
	switch mode {
	case "ast":
		return hmc.stats.ASTQueries
	case "rag":
		return hmc.stats.RAGQueries
	case "hybrid":
		return hmc.stats.HybridQueries
	case "parallel":
		return hmc.stats.ParallelQueries
	default:
		return 1
	}
}

// RecordMemoryUsage enregistre l'utilisation mémoire d'un mode
func (hmc *HybridMetricsCollector) RecordMemoryUsage(mode string, bytes int64) {
	hmc.mu.Lock()
	defer hmc.mu.Unlock()

	hmc.stats.MemoryUsage[mode] = bytes
}

// GetMetricsSummary retourne un résumé des métriques principales
func (hmc *HybridMetricsCollector) GetMetricsSummary() map[string]interface{} {
	stats := hmc.GetStatistics()

	summary := map[string]interface{}{
		"total_queries":    stats.TotalQueries,
		"mode_distribution": map[string]int64{
			"ast":      stats.ASTQueries,
			"rag":      stats.RAGQueries,
			"hybrid":   stats.HybridQueries,
			"parallel": stats.ParallelQueries,
		},
		"performance": map[string]interface{}{
			"average_latency": stats.AverageLatency,
			"success_rates":   stats.SuccessRates,
			"quality_scores":  stats.QualityScores,
		},
		"optimization": map[string]interface{}{
			"cache_hit_rates": stats.CacheHitRates,
			"memory_usage":    stats.MemoryUsage,
		},
		"reliability": map[string]interface{}{
			"error_counts":    stats.ErrorCounts,
			"mode_accuracy":   stats.ModeAccuracy,
		},
		"last_updated": stats.LastUpdated,
	}

	return summary
}

// Reset remet à zéro toutes les métriques
func (hmc *HybridMetricsCollector) Reset() {
	hmc.mu.Lock()
	defer hmc.mu.Unlock()

	hmc.stats = &HybridStatistics{
		AverageLatency: make(map[string]time.Duration),
		SuccessRates:   make(map[string]float64),
		QualityScores:  make(map[string]float64),
		CacheHitRates:  make(map[string]float64),
		MemoryUsage:    make(map[string]int64),
		ErrorCounts:    make(map[string]int64),
		ModeSelections: make(map[string]int64),
		ModeAccuracy:   make(map[string]float64),
		LastErrors:     make([]ErrorInfo, 0),
		LastUpdated:    time.Now(),
	}
}
