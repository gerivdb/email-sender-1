// Package integration provides tests for Phase 2 managers
package integration

import (
	"context"
	"fmt"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/interfaces"
	"email_sender/pkg/fmoua/types"
)

// TestManagerInterface tests that all Phase 2 managers implement the Manager interface
func TestManagerInterface(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()
		managers := []struct {
		name    string
		manager interfaces.Manager
	}{
		{
			name:    "EmailManager",
			manager: createEmailManager(t, logger, metrics),
		},
		{
			name:    "DatabaseManager", 
			manager: createDatabaseManager(t, logger, metrics),
		},
		{
			name:    "CacheManager",
			manager: createCacheManager(t, logger, metrics),
		},
		{
			name:    "WebhookManager",
			manager: createWebhookManager(t, logger, metrics),
		},
	}
	
	for _, tt := range managers {
		t.Run(tt.name, func(t *testing.T) {
			// Test Name() method
			if tt.manager.Name() == "" {
				t.Errorf("%s.Name() returned empty string", tt.name)
			}
			
			// Test Status() method
			status := tt.manager.Status()
			if status.LastCheck.IsZero() {
				t.Errorf("%s.Status() returned zero time for LastCheck", tt.name)
			}
			
			// Test Start() method
			ctx := context.Background()
			if err := tt.manager.Start(ctx); err != nil {
				t.Errorf("%s.Start() error = %v", tt.name, err)
			}
			
			// Test Health() method
			if err := tt.manager.Health(); err != nil {
				t.Errorf("%s.Health() error = %v", tt.name, err)
			}
			
			// Test Stop() method
			if err := tt.manager.Stop(); err != nil {
				t.Errorf("%s.Stop() error = %v", tt.name, err)
			}
		})
	}
}

// TestCacheManager tests CacheManager functionality
func TestCacheManager_Initialize(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()
	
	config := types.ManagerConfig{
		ID:   "cache-test",
		Type: "cache",
		Config: map[string]interface{}{
			"backends": map[string]interface{}{
				"memory": map[string]interface{}{
					"type": "memory",
				},
			},
		},
	}
	
	cm, err := NewCacheManager("test-cache", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create CacheManager: %v", err)
	}
	
	if err := cm.Initialize(config); err != nil {
		t.Errorf("CacheManager.Initialize() error = %v", err)
	}
	
	if cm.GetType() != "cache" {
		t.Errorf("CacheManager.GetType() = %v, want %v", cm.GetType(), "cache")
	}
}

// TestCacheManager_Execute tests CacheManager task execution
func TestCacheManager_Execute(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()
	
	config := types.ManagerConfig{
		ID:   "cache-test",
		Type: "cache",
		Config: map[string]interface{}{},
	}
	
	cm, err := NewCacheManager("test-cache", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create CacheManager: %v", err)
	}
	
	if err := cm.Initialize(config); err != nil {
		t.Fatalf("Failed to initialize CacheManager: %v", err)
	}
	
	tests := []struct {
		name       string
		task       types.Task
		wantResult bool
	}{
		{
			name: "set_cache_value",
			task: types.Task{
				ID:   "task-1",
				Type: "set",
				Payload: map[string]interface{}{
					"key":   "test-key",
					"value": "test-value",
					"ttl":   3600.0,
				},
			},
			wantResult: true,
		},
		{
			name: "get_cache_value",
			task: types.Task{
				ID:   "task-2",
				Type: "get",
				Payload: map[string]interface{}{
					"key": "test-key",
				},
			},
			wantResult: true,
		},
		{
			name: "invalid_task_type",
			task: types.Task{
				ID:   "task-3",
				Type: "invalid",
			},
			wantResult: false,
		},
	}
	
	ctx := context.Background()
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := cm.Execute(ctx, tt.task)
			if err != nil {
				t.Errorf("CacheManager.Execute() error = %v", err)
				return
			}
			
			if result.Success != tt.wantResult {
				t.Errorf("CacheManager.Execute() result.Success = %v, want %v", result.Success, tt.wantResult)
			}
		})
	}
}

// TestDatabaseManager tests DatabaseManager functionality  
func TestDatabaseManager_Initialize(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()
	
	config := types.ManagerConfig{
		ID:   "database-test",
		Type: "database",
		Config: map[string]interface{}{
			"connections": map[string]interface{}{
				"test": map[string]interface{}{
					"type":     "postgresql",
					"host":     "localhost",
					"port":     5432.0,
					"database": "test",
					"username": "test",
					"password": "test",
				},
			},
		},
	}
	
	dm, err := NewDatabaseManager("test-db", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create DatabaseManager: %v", err)
	}
	
	// Note: Initialize will fail because we don't have a real database
	// But we can test that the manager was created successfully
	if dm.GetType() != "database" {
		t.Errorf("DatabaseManager.GetType() = %v, want %v", dm.GetType(), "database")
	}
}

// TestMemoryCacheBackend tests the memory cache backend
func TestMemoryCacheBackend(t *testing.T) {
	backend := NewMemoryCacheBackend()
	
	// Test Set and Get
	err := backend.Set("key1", "value1", time.Hour)
	if err != nil {
		t.Errorf("MemoryCacheBackend.Set() error = %v", err)
	}
	
	value, found := backend.Get("key1")
	if !found {
		t.Errorf("MemoryCacheBackend.Get() not found")
	}
	
	if value != "value1" {
		t.Errorf("MemoryCacheBackend.Get() = %v, want %v", value, "value1")
	}
	
	// Test Delete
	err = backend.Delete("key1")
	if err != nil {
		t.Errorf("MemoryCacheBackend.Delete() error = %v", err)
	}
	
	_, found = backend.Get("key1")
	if found {
		t.Errorf("MemoryCacheBackend.Get() found deleted key")
	}
	
	// Test Clear
	backend.Set("key1", "value1", time.Hour)
	backend.Set("key2", "value2", time.Hour)
	
	err = backend.Clear()
	if err != nil {
		t.Errorf("MemoryCacheBackend.Clear() error = %v", err)
	}
	
	keys := backend.Keys()
	if len(keys) != 0 {
		t.Errorf("MemoryCacheBackend.Keys() after clear = %v, want empty", keys)
	}
	
	// Test Stats
	stats := backend.Stats()
	if stats.Keys != 0 {
		t.Errorf("MemoryCacheBackend.Stats().Keys = %v, want 0", stats.Keys)
	}
}

// TestMemoryCacheBackend_Expiration tests cache expiration
func TestMemoryCacheBackend_Expiration(t *testing.T) {
	backend := NewMemoryCacheBackend()
	
	// Set with short TTL
	err := backend.Set("expiring-key", "value", 50*time.Millisecond)
	if err != nil {
		t.Errorf("MemoryCacheBackend.Set() error = %v", err)
	}
	
	// Should be found immediately
	_, found := backend.Get("expiring-key")
	if !found {
		t.Errorf("MemoryCacheBackend.Get() should find non-expired key")
	}
	
	// Wait for expiration
	time.Sleep(100 * time.Millisecond)
	
	// Should not be found after expiration
	_, found = backend.Get("expiring-key")
	if found {
		t.Errorf("MemoryCacheBackend.Get() should not find expired key")
	}
}

// Helper functions to create managers for testing

func createEmailManager(t *testing.T, logger *zap.Logger, metrics MetricsCollector) interfaces.Manager {
	config := types.ManagerConfig{
		ID:   "email-test",
		Type: "email",
		Config: map[string]interface{}{
			"providers": map[string]interface{}{
				"test": map[string]interface{}{
					"type": "smtp",
					"host": "localhost",
					"port": 587,
				},
			},
		},
	}
	
	em, err := NewEmailManager("test-email", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create EmailManager: %v", err)
	}
	
	if err := em.Initialize(config); err != nil {
		t.Fatalf("Failed to initialize EmailManager: %v", err)
	}
	
	return &ManagerAdapter{
		BaseManager: em.BaseManager,
		manager:     em,
	}
}

func createDatabaseManager(t *testing.T, logger *zap.Logger, metrics MetricsCollector) interfaces.Manager {
	config := types.ManagerConfig{
		ID:   "database-test",
		Type: "database",
		Config: map[string]interface{}{},
	}
	
	dm, err := NewDatabaseManager("test-db", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create DatabaseManager: %v", err)
	}
	
	return &ManagerAdapter{
		BaseManager: dm.BaseManager,
		manager:     dm,
	}
}

func createCacheManager(t *testing.T, logger *zap.Logger, metrics MetricsCollector) interfaces.Manager {
	config := types.ManagerConfig{
		ID:   "cache-test",
		Type: "cache",
		Config: map[string]interface{}{},
	}
	
	cm, err := NewCacheManager("test-cache", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create CacheManager: %v", err)
	}
	
	if err := cm.Initialize(config); err != nil {
		t.Fatalf("Failed to initialize CacheManager: %v", err)
	}
	
	return &ManagerAdapter{
		BaseManager: cm.BaseManager,
		manager:     cm,
	}
}

func createWebhookManager(t *testing.T, logger *zap.Logger, metrics MetricsCollector) interfaces.Manager {
	config := types.ManagerConfig{
		ID:   "webhook-test",
		Type: "webhook",
		Config: map[string]interface{}{
			"server": map[string]interface{}{
				"enabled": false, // Disable server for testing
				"host":    "localhost",
				"port":    8080,
			},
			"client": map[string]interface{}{
				"timeout":     "30s",
				"max_retries": 3,
			},
		},
	}
	
	wm, err := NewWebhookManager("test-webhook", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create WebhookManager: %v", err)
	}
	
	return &ManagerAdapter{
		BaseManager: wm.BaseManager,
		manager:     wm,
	}
}

// ManagerAdapter adapts Phase 2 managers to the Manager interface
type ManagerAdapter struct {
	*BaseManager
	manager interface{}
}

// Name returns the manager name
func (ma *ManagerAdapter) Name() string {
	return ma.GetID()
}

// Status returns the manager status
func (ma *ManagerAdapter) Status() interfaces.HealthStatus {
	return interfaces.HealthStatus{
		IsHealthy:    ma.GetStatus() == types.ManagerStatusRunning,
		LastCheck:    time.Now(),
		ResponseTime: time.Millisecond * 10,
	}
}

// Start starts the manager
func (ma *ManagerAdapter) Start(ctx context.Context) error {
	switch m := ma.manager.(type) {
	case *EmailManager:
		return m.Start()
	case *DatabaseManager:
		return m.Start()
	case *CacheManager:
		return m.Start()
	case *WebhookManager:
		return m.Initialize(ctx)
	default:
		return ma.BaseManager.Start()
	}
}

// Stop stops the manager
func (ma *ManagerAdapter) Stop() error {
	switch m := ma.manager.(type) {
	case *EmailManager:
		return m.Stop()
	case *DatabaseManager:
		return m.Stop()
	case *CacheManager:
		return m.Stop()
	case *WebhookManager:
		return m.Shutdown(context.Background())
	default:
		return ma.BaseManager.Stop()
	}
}

// Health checks the manager health
func (ma *ManagerAdapter) Health() error {
	if ma.GetStatus() == types.ManagerStatusRunning {
		return nil
	}
	return fmt.Errorf("manager not running")
}
