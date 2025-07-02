package main

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"sync"
	"sync/atomic"
	"time"

	gatewaymanager "email_sender/development/managers/gateway-manager"
	"email_sender/internal/core" // Importer les mocks
)

const (
	numWorkers  = 10
	numRequests = 1000
)

func main() {
	fmt.Println("Démarrage des tests de performance et de charge pour Gateway-Manager...")

	// Initialiser le GatewayManager avec des mocks
	mockCache := &core.MockCacheManager{}
	mockLWM := &core.MockLWM{}
	mockRAG := &core.MockRAG{}
	mockMemoryBank := &core.MockMemoryBank{}

	gm := gatewaymanager.NewGatewayManager("PerformanceTestGateway", mockCache, mockLWM, mockRAG, mockMemoryBank)

	var successCount atomic.Int64
	var errorCount atomic.Int64
	var totalLatency atomic.Int64 // en nanosecondes

	var wg sync.WaitGroup
	startTime := time.Now()

	fmt.Printf("Lancement de %d workers pour %d requêtes...\n", numWorkers, numRequests)

	for i := 0; i < numWorkers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for j := 0; j < numRequests/numWorkers; j++ {
				requestID := fmt.Sprintf("perf-req-%d-%d", i, j)
				data := map[string]interface{}{"payload": rand.Intn(1000)} // Données aléatoires

				reqStartTime := time.Now()
				_, err := gm.ProcessRequest(context.Background(), requestID, data)
				latency := time.Since(reqStartTime)
				totalLatency.Add(latency.Nanoseconds())

				if err != nil {
					errorCount.Add(1)
				} else {
					successCount.Add(1)
				}
			}
		}()
	}

	wg.Wait()
	duration := time.Since(startTime)

	fmt.Println("\n--- Résultats des tests de performance ---")
	fmt.Printf("Durée totale: %v\n", duration)
	fmt.Printf("Requêtes réussies: %d\n", successCount.Load())
	fmt.Printf("Requêtes échouées: %d\n", errorCount.Load())
	fmt.Printf("Débit (Req/sec): %.2f\n", float64(successCount.Load())/duration.Seconds())

	avgLatencyMs := float64(totalLatency.Load()) / float64(successCount.Load()) / float64(time.Millisecond)
	fmt.Printf("Latence moyenne par requête: %.2f ms\n", avgLatencyMs)

	if errorCount.Load() > 0 {
		fmt.Println("Les tests de performance ont détecté des erreurs.")
		os.Exit(1)
	}
	fmt.Println("Tests de performance terminés avec succès.")
}
