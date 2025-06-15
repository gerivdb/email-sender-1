package integration

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"testing"
	"time"

	"email_sender/internal/api"
	"email_sender/internal/infrastructure"
	"email_sender/internal/monitoring"
)

// TestAdvancedMonitoringIntegration teste l'intégration complète du monitoring avancé
func TestAdvancedMonitoringIntegration(t *testing.T) {
	// Créer un gestionnaire d'infrastructure pour les tests
	orchestrator, err := infrastructure.NewSmartInfrastructureManager()
	if err != nil {
		t.Fatalf("Failed to create infrastructure manager: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	t.Run("StartAdvancedMonitoring", func(t *testing.T) {
		err := orchestrator.StartAdvancedMonitoring(ctx)
		if err != nil {
			t.Errorf("Failed to start advanced monitoring: %v", err)
		}

		// Vérifier que le monitoring est actif
		if smartManager, ok := orchestrator.(*infrastructure.SmartInfrastructureManager); ok {
			status := smartManager.GetMonitoringStatus()
			if !status.Active {
				t.Error("Monitoring should be active after starting")
			}
		}
	})

	t.Run("GetAdvancedHealthStatus", func(t *testing.T) {
		healthStatus, err := orchestrator.GetAdvancedHealthStatus(ctx)
		if err != nil {
			t.Errorf("Failed to get advanced health status: %v", err)
		}

		if len(healthStatus) == 0 {
			t.Error("Health status should contain at least one service")
		}

		// Vérifier que chaque service a un statut valide
		for service, status := range healthStatus {
			if status.ServiceName == "" {
				t.Errorf("Service %s should have a name", service)
			}
			if status.Timestamp.IsZero() {
				t.Errorf("Service %s should have a timestamp", service)
			}
		}
	})

	t.Run("EnableAutoHealing", func(t *testing.T) {
		err := orchestrator.EnableAutoHealing(true)
		if err != nil {
			t.Errorf("Failed to enable auto-healing: %v", err)
		}

		// Vérifier que l'auto-healing est activé
		if smartManager, ok := orchestrator.(*infrastructure.SmartInfrastructureManager); ok {
			status := smartManager.GetMonitoringStatus()
			if !status.AutoHealingEnabled {
				t.Error("Auto-healing should be enabled")
			}
		}
	})

	t.Run("DisableAutoHealing", func(t *testing.T) {
		err := orchestrator.EnableAutoHealing(false)
		if err != nil {
			t.Errorf("Failed to disable auto-healing: %v", err)
		}

		// Vérifier que l'auto-healing est désactivé
		if smartManager, ok := orchestrator.(*infrastructure.SmartInfrastructureManager); ok {
			status := smartManager.GetMonitoringStatus()
			if status.AutoHealingEnabled {
				t.Error("Auto-healing should be disabled")
			}
		}
	})

	t.Run("StopAdvancedMonitoring", func(t *testing.T) {
		err := orchestrator.StopAdvancedMonitoring()
		if err != nil {
			t.Errorf("Failed to stop advanced monitoring: %v", err)
		}

		// Vérifier que le monitoring est inactif
		if smartManager, ok := orchestrator.(*infrastructure.SmartInfrastructureManager); ok {
			status := smartManager.GetMonitoringStatus()
			if status.Active {
				t.Error("Monitoring should be inactive after stopping")
			}
		}
	})
}

// TestAPIEndpointsIntegration teste l'intégration des endpoints API
func TestAPIEndpointsIntegration(t *testing.T) {
	// Créer un gestionnaire d'infrastructure pour les tests
	orchestrator, err := infrastructure.NewSmartInfrastructureManager()
	if err != nil {
		t.Fatalf("Failed to create infrastructure manager: %v", err)
	}

	// Créer le handler API
	apiHandler := api.NewInfrastructureAPIHandler(orchestrator)

	// Démarrer le serveur de test
	serverPort := 18080 // Port de test
	go func() {
		err := apiHandler.StartServer(serverPort)
		if err != nil && err != http.ErrServerClosed {
			t.Errorf("Failed to start test server: %v", err)
		}
	}()

	// Attendre que le serveur démarre
	time.Sleep(2 * time.Second)

	baseURL := fmt.Sprintf("http://localhost:%d", serverPort)

	t.Run("GetInfrastructureStatus", func(t *testing.T) {
		resp, err := http.Get(baseURL + "/api/v1/infrastructure/status")
		if err != nil {
			t.Fatalf("Failed to get infrastructure status: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("Expected status 200, got %d", resp.StatusCode)
		}

		var apiResp api.APIResponse
		if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
			t.Fatalf("Failed to decode response: %v", err)
		}

		if !apiResp.Success {
			t.Errorf("API response should be successful: %s", apiResp.Error)
		}
	})

	t.Run("StartAdvancedMonitoring", func(t *testing.T) {
		resp, err := http.Post(baseURL+"/api/v1/monitoring/start", "application/json", nil)
		if err != nil {
			t.Fatalf("Failed to start monitoring: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("Expected status 200, got %d", resp.StatusCode)
		}
	})

	t.Run("GetMonitoringStatus", func(t *testing.T) {
		resp, err := http.Get(baseURL + "/api/v1/monitoring/status")
		if err != nil {
			t.Fatalf("Failed to get monitoring status: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("Expected status 200, got %d", resp.StatusCode)
		}

		var apiResp api.APIResponse
		if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
			t.Fatalf("Failed to decode response: %v", err)
		}

		if !apiResp.Success {
			t.Errorf("API response should be successful: %s", apiResp.Error)
		}

		// Vérifier la structure des données
		if data, ok := apiResp.Data.(map[string]interface{}); ok {
			if active, exists := data["active"]; !exists || active != true {
				t.Error("Monitoring should be active")
			}
		}
	})

	t.Run("GetAdvancedHealthStatus", func(t *testing.T) {
		resp, err := http.Get(baseURL + "/api/v1/monitoring/health-advanced")
		if err != nil {
			t.Fatalf("Failed to get advanced health status: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("Expected status 200, got %d", resp.StatusCode)
		}
	})

	t.Run("EnableAutoHealing", func(t *testing.T) {
		resp, err := http.Post(baseURL+"/api/v1/auto-healing/enable", "application/json", nil)
		if err != nil {
			t.Fatalf("Failed to enable auto-healing: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("Expected status 200, got %d", resp.StatusCode)
		}
	})

	t.Run("DisableAutoHealing", func(t *testing.T) {
		resp, err := http.Post(baseURL+"/api/v1/auto-healing/disable", "application/json", nil)
		if err != nil {
			t.Fatalf("Failed to disable auto-healing: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("Expected status 200, got %d", resp.StatusCode)
		}
	})

	t.Run("StopAdvancedMonitoring", func(t *testing.T) {
		resp, err := http.Post(baseURL+"/api/v1/monitoring/stop", "application/json", nil)
		if err != nil {
			t.Fatalf("Failed to stop monitoring: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Errorf("Expected status 200, got %d", resp.StatusCode)
		}
	})

	// Nettoyer - arrêter le serveur de test
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	apiHandler.StopServer(ctx)
}

// TestAutoHealingScenario teste un scénario complet d'auto-healing
func TestAutoHealingScenario(t *testing.T) {
	orchestrator, err := infrastructure.NewSmartInfrastructureManager()
	if err != nil {
		t.Fatalf("Failed to create infrastructure manager: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	// Démarrer le monitoring avancé
	if err := orchestrator.StartAdvancedMonitoring(ctx); err != nil {
		t.Fatalf("Failed to start advanced monitoring: %v", err)
	}
	defer orchestrator.StopAdvancedMonitoring()

	// Activer l'auto-healing
	if err := orchestrator.EnableAutoHealing(true); err != nil {
		t.Fatalf("Failed to enable auto-healing: %v", err)
	}

	// Laisser le système tourner quelques secondes pour collecter des métriques
	time.Sleep(10 * time.Second)

	// Obtenir le statut de santé avancé
	healthStatus, err := orchestrator.GetAdvancedHealthStatus(ctx)
	if err != nil {
		t.Fatalf("Failed to get health status: %v", err)
	}

	// Vérifier qu'on a des métriques pour tous les services
	expectedServices := []string{"qdrant", "redis", "prometheus", "grafana", "rag_server"}
	for _, service := range expectedServices {
		if _, exists := healthStatus[service]; !exists {
			t.Errorf("Expected health status for service %s", service)
		}
	}

	// Tester la récupération automatique
	if err := orchestrator.AutoRecover(ctx); err != nil {
		t.Errorf("Auto-recovery failed: %v", err)
	}

	t.Log("✅ Auto-healing scenario completed successfully")
}

// BenchmarkMonitoringPerformance benchmark la performance du monitoring
func BenchmarkMonitoringPerformance(b *testing.B) {
	orchestrator, err := infrastructure.NewSmartInfrastructureManager()
	if err != nil {
		b.Fatalf("Failed to create infrastructure manager: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Minute)
	defer cancel()

	// Démarrer le monitoring
	if err := orchestrator.StartAdvancedMonitoring(ctx); err != nil {
		b.Fatalf("Failed to start monitoring: %v", err)
	}
	defer orchestrator.StopAdvancedMonitoring()

	b.ResetTimer()

	b.Run("GetAdvancedHealthStatus", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			_, err := orchestrator.GetAdvancedHealthStatus(ctx)
			if err != nil {
				b.Errorf("Failed to get health status: %v", err)
			}
		}
	})

	b.Run("EnableDisableAutoHealing", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			_ = orchestrator.EnableAutoHealing(true)
			_ = orchestrator.EnableAutoHealing(false)
		}
	})
}
