// SPDX-License-Identifier: MIT
// Package docmanager - Test d'interface enhancement minimal
package docmanager

import (
	"context"
	"testing"
	"time"
)

// TestManagerTypeInterfaceBasic teste l'interface ManagerType de base
func TestManagerTypeInterfaceBasic(t *testing.T) {
	// Test simple d'implémentation
	var _ ManagerType = &SimpleTestManager{}
}

// SimpleTestManager implémentation simple pour test
type SimpleTestManager struct {
	initialized bool
	shutdown    bool
}

// Initialize initialise le manager
func (stm *SimpleTestManager) Initialize(ctx context.Context) error {
	stm.initialized = true
	return nil
}

// Process traite des données
func (stm *SimpleTestManager) Process(ctx context.Context, data interface{}) (interface{}, error) {
	if !stm.initialized {
		return nil, ErrRepositoryUnavailable
	}
	return map[string]interface{}{"processed": true, "data": data}, nil
}

// Shutdown arrête le manager
func (stm *SimpleTestManager) Shutdown() error {
	stm.shutdown = true
	stm.initialized = false
	return nil
}

// Health retourne le statut de santé
func (stm *SimpleTestManager) Health() HealthStatus {
	status := "healthy"
	var issues []string

	if !stm.initialized {
		status = "not_initialized"
		issues = append(issues, "Manager not initialized")
	}

	if stm.shutdown {
		status = "shutdown"
		issues = append(issues, "Manager is shutdown")
	}

	return HealthStatus{
		Status:    status,
		LastCheck: time.Now(),
		Issues:    issues,
		Details: map[string]interface{}{
			"initialized": stm.initialized,
			"shutdown":    stm.shutdown,
		},
	}
}

// Metrics retourne les métriques du manager
func (stm *SimpleTestManager) Metrics() ManagerMetrics {
	status := "active"
	if !stm.initialized {
		status = "inactive"
	}
	if stm.shutdown {
		status = "shutdown"
	}

	return ManagerMetrics{
		RequestCount:        0,
		AverageResponseTime: time.Duration(0),
		ErrorCount:          0,
		LastProcessedAt:     time.Time{},
		ResourceUsage: map[string]interface{}{
			"memory_mb": 10.0,
		},
		Status: status,
	}
}

// TestManagerTypeLifecycle teste le cycle de vie complet
func TestManagerTypeLifecycle(t *testing.T) {
	manager := &SimpleTestManager{}
	ctx := context.Background()

	// Test Initialize
	err := manager.Initialize(ctx)
	if err != nil {
		t.Fatalf("Initialize failed: %v", err)
	}

	// Test Health après initialisation
	health := manager.Health()
	if health.Status != "healthy" {
		t.Errorf("Expected status 'healthy', got %s", health.Status)
	}

	// Test Process
	result, err := manager.Process(ctx, "test data")
	if err != nil {
		t.Fatalf("Process failed: %v", err)
	}

	if result == nil {
		t.Error("Process should return result")
	}

	// Test Metrics
	metrics := manager.Metrics()
	if metrics.Status != "active" {
		t.Errorf("Expected status 'active', got %s", metrics.Status)
	}

	// Test Shutdown
	err = manager.Shutdown()
	if err != nil {
		t.Fatalf("Shutdown failed: %v", err)
	}

	// Verify shutdown state
	health = manager.Health()
	if health.Status != "shutdown" {
		t.Errorf("Expected shutdown status, got %s", health.Status)
	}
}