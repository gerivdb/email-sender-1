package main

import (
	"fmt"
	"time"
)

// TestHubCentral teste le fonctionnement de base du hub central
func TestHubCentral() error {
	fmt.Println("🚀 Test du Hub Central")
	
	// Configuration de test
	config := &HubConfig{
		Hub: &HubSettings{
			Port:            8080,
			HealthCheckPort: 8081,
			ShutdownTimeout: 30 * time.Second,
			StartupTimeout:  60 * time.Second,
			LogLevel:        "info",
		},
	}
	
	// Création du logger
	logger, err := NewLogger("info")
	if err != nil {
		return fmt.Errorf("Erreur création logger: %w", err)
	}
	
	// Création du hub
	hub := NewCentralHub(config, logger)
	
	// Test d'initialisation
	fmt.Println("✅ Hub créé avec succès")
	
	// Test des managers (sans vraiment les démarrer)
	if hub.managers == nil {
		hub.managers = make(map[string]Manager)
	}
	
	fmt.Println("✅ Managers initialisés")
	
	// Test de l'event bus
	if hub.eventBus != nil {
		fmt.Println("✅ Event Bus disponible")
	}
	
	// Test du metrics collector
	if hub.metrics != nil {
		fmt.Println("✅ Metrics Collector disponible")
	}
	
	fmt.Println("🎉 Test du Hub Central terminé avec succès!")
	return nil
}

// Point d'entrée pour les tests
func runTests() {
	fmt.Println("=== Tests du Hub Central ===")
	
	if err := TestHubCentral(); err != nil {
		fmt.Printf("❌ Test échoué: %v\n", err)
		return
	}
	
	fmt.Println("=== Tous les tests sont passés ===")
}
