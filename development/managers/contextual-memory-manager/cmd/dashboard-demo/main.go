// cmd/dashboard-demo/main.go
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"math/rand"
	"os"
	"os/signal"
	"syscall"
	"time"

	"go.uber.org/zap"

	"github.com/contextual-memory-manager/internal/monitoring"
)

func main() {
	// Flags de ligne de commande
	var (
		port         = flag.Int("port", 8080, "Port pour le dashboard")
		generateData = flag.Bool("generate", true, "Générer des données de test")
		duration     = flag.Duration("duration", 0, "Durée de fonctionnement (0 = infini)")
	)
	flag.Parse()

	// Configuration du logger
	logger, err := zap.NewProduction()
	if err != nil {
		log.Fatal("Failed to create logger:", err)
	}
	defer logger.Sync()

	logger.Info("Starting Hybrid Memory Manager Dashboard Demo",
		zap.Int("port", *port),
		zap.Bool("generate_data", *generateData),
		zap.Duration("duration", *duration),
	)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Créer le collecteur de métriques
	metricsCollector := monitoring.NewHybridMetricsCollector(logger)

	// Créer le dashboard
	dashboard := monitoring.NewRealTimeDashboard(metricsCollector, logger, *port)

	// Démarrer le dashboard
	if err := dashboard.Start(ctx); err != nil {
		logger.Fatal("Failed to start dashboard", zap.Error(err))
	}

	// Démarrer la génération de données de test si demandée
	if *generateData {
		go generateTestData(ctx, metricsCollector, logger)
	}

	// Démarrer le reporting périodique
	metricsCollector.StartPeriodicReporting(ctx)

	logger.Info("Dashboard started successfully",
		zap.String("url", fmt.Sprintf("http://localhost:%d", *port)),
		zap.String("metrics_api", fmt.Sprintf("http://localhost:%d/api/metrics", *port)),
		zap.String("stream_api", fmt.Sprintf("http://localhost:%d/api/stream", *port)),
	)

	// Configuration des signaux d'arrêt
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Attendre l'arrêt ou la durée spécifiée
	if *duration > 0 {
		timer := time.NewTimer(*duration)
		select {
		case <-sigChan:
			logger.Info("Received shutdown signal")
		case <-timer.C:
			logger.Info("Duration elapsed, shutting down")
		}
		timer.Stop()
	} else {
		<-sigChan
		logger.Info("Received shutdown signal")
	}

	// Arrêt gracieux
	logger.Info("Shutting down dashboard...")
	
	metricsCollector.Stop()
	
	if err := dashboard.Stop(); err != nil {
		logger.Error("Error stopping dashboard", zap.Error(err))
	}

	logger.Info("Dashboard stopped successfully")
}

// generateTestData génère des données de test réalistes
func generateTestData(ctx context.Context, collector *monitoring.HybridMetricsCollector, logger *zap.Logger) {
	logger.Info("Starting test data generation")

	modes := []string{"ast", "rag", "hybrid", "parallel"}
	scenarios := []testScenario{
		{
			name:        "normal_operations",
			weight:      60,
			successRate: 0.95,
			latencyBase: 100 * time.Millisecond,
			qualityBase: 0.8,
		},
		{
			name:        "heavy_load",
			weight:      20,
			successRate: 0.85,
			latencyBase: 300 * time.Millisecond,
			qualityBase: 0.7,
		},
		{
			name:        "optimization_phase",
			weight:      15,
			successRate: 0.98,
			latencyBase: 50 * time.Millisecond,
			qualityBase: 0.9,
		},
		{
			name:        "error_prone",
			weight:      5,
			successRate: 0.6,
			latencyBase: 500 * time.Millisecond,
			qualityBase: 0.5,
		},
	}

	ticker := time.NewTicker(200 * time.Millisecond) // Générer des données toutes les 200ms
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			logger.Info("Stopping test data generation")
			return
		case <-ticker.C:
			// Sélectionner un scénario
			scenario := selectScenario(scenarios)
			
			// Sélectionner un mode
			mode := modes[rand.Intn(len(modes))]
			
			// Générer des métriques basées sur le scénario
			generateScenarioMetrics(collector, mode, scenario)
			
			// Simuler occasionnellement des erreurs
			if rand.Float64() < (1.0 - scenario.successRate) {
				collector.RecordError(mode, fmt.Errorf("simulated error in %s mode during %s", mode, scenario.name))
			}
			
			// Simuler l'utilisation mémoire
			if rand.Intn(10) == 0 { // 10% du temps
				memoryUsage := int64(rand.Intn(50)+10) * 1024 * 1024 // 10-60 MB
				collector.RecordMemoryUsage(mode, memoryUsage)
			}
			
			// Simuler la sélection de mode
			if rand.Intn(5) == 0 { // 20% du temps
				selectedMode := mode
				actualBest := modes[rand.Intn(len(modes))]
				confidence := rand.Float64()*0.4 + 0.6 // 0.6-1.0
				
				collector.RecordModeSelection(selectedMode, actualBest, confidence)
			}
		}
	}
}

type testScenario struct {
	name        string
	weight      int
	successRate float64
	latencyBase time.Duration
	qualityBase float64
}

func selectScenario(scenarios []testScenario) testScenario {
	totalWeight := 0
	for _, s := range scenarios {
		totalWeight += s.weight
	}
	
	r := rand.Intn(totalWeight)
	currentWeight := 0
	
	for _, s := range scenarios {
		currentWeight += s.weight
		if r < currentWeight {
			return s
		}
	}
	
	return scenarios[0] // Fallback
}

func generateScenarioMetrics(collector *monitoring.HybridMetricsCollector, mode string, scenario testScenario) {
	// Générer la latence avec variation
	latencyVariation := time.Duration(rand.Intn(100)-50) * time.Millisecond // ±50ms
	latency := scenario.latencyBase + latencyVariation
	if latency < 10*time.Millisecond {
		latency = 10 * time.Millisecond
	}
	
	// Générer le succès/échec
	success := rand.Float64() < scenario.successRate
	
	// Générer le score de qualité avec variation
	qualityVariation := (rand.Float64() - 0.5) * 0.4 // ±0.2
	quality := scenario.qualityBase + qualityVariation
	if quality < 0 {
		quality = 0
	}
	if quality > 1 {
		quality = 1
	}
	
	// Enregistrer la requête
	collector.RecordQuery(mode, latency, success, quality)
	
	// Simuler les hits de cache avec des taux différents selon le mode
	var cacheHitRate float64
	switch mode {
	case "ast":
		cacheHitRate = 0.85 // AST cache bien
	case "rag":
		cacheHitRate = 0.70 // RAG cache moyennement
	case "hybrid":
		cacheHitRate = 0.75 // Hybride cache bien
	case "parallel":
		cacheHitRate = 0.60 // Parallèle cache moins bien
	}
	
	// Ajuster selon le scénario
	if scenario.name == "optimization_phase" {
		cacheHitRate += 0.1
	} else if scenario.name == "heavy_load" {
		cacheHitRate -= 0.1
	}
	
	cacheHit := rand.Float64() < cacheHitRate
	collector.RecordCacheHit(mode, cacheHit)
}
