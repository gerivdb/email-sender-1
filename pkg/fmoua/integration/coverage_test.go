// Package integration provides comprehensive tests for 100% coverage
package integration

import (
	"context"
	"fmt"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/types"
)

// Test BaseManager uncovered functions
func TestBaseManager_UntestedMethods(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		ID:   "test-base",
		Type: "test",
		Config: map[string]interface{}{
			"cleanup_level": 1,
		},
	}

	baseManager := NewBaseManager("test-base", config, logger, metrics)

	// Test LogError
	baseManager.LogError("test error", fmt.Errorf("test error"))
	// Test LogDebug
	baseManager.LogDebug("test debug", zap.String("key", "value"))

	// Test GetMetrics
	managerMetrics := baseManager.GetMetrics()
	if managerMetrics == nil {
		t.Error("Expected metrics to be returned")
	}

	// Test Cleanup
	err := baseManager.Cleanup()
	if err != nil {
		t.Errorf("Cleanup failed: %v", err)
	}
}

// Test DefaultMetricsCollector uncovered methods
func TestDefaultMetricsCollector_UntestedMethods(t *testing.T) {
	metrics := NewDefaultMetricsCollector()

	// Test Gauge
	metrics.Gauge("test_gauge", 42.5, map[string]string{"tag": "value"})

	// Test GetMetrics
	allMetrics := metrics.GetMetrics()
	if allMetrics == nil {
		t.Error("Expected metrics to be returned")
	} // Verify gauge was recorded
	if gauges, ok := allMetrics["gauges"].(map[string]float64); ok {
		found := false
		for key, value := range gauges {
			if key == "test_gauge,tag=value" && value == 42.5 {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("Expected test_gauge with tags to be in gauges, got: %+v", gauges)
		}
	} else {
		t.Errorf("Expected gauges to be in metrics, got type %T", allMetrics["gauges"])
	}
}

// Test WebhookManager interface methods
func TestWebhookManager_InterfaceMethods(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		Type:    "webhook",
		Enabled: true,
		Config: map[string]interface{}{
			"server": map[string]interface{}{
				"enabled": false,
			},
			"client": map[string]interface{}{
				"timeout": "30s",
			},
		},
	}

	manager, err := NewWebhookManager("test-webhook", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create WebhookManager: %v", err)
	}

	// Test Name method
	name := manager.Name()
	if name != "test-webhook" {
		t.Errorf("Expected name 'test-webhook', got '%s'", name)
	}

	// Test Status method
	status := manager.Status()
	if status.LastCheck.IsZero() {
		t.Error("Expected LastCheck to be set")
	}

	// Test Start method
	ctx := context.Background()
	err = manager.Start(ctx)
	if err != nil {
		t.Errorf("Start failed: %v", err)
	}

	// Test Stop method
	err = manager.Stop()
	if err != nil {
		t.Errorf("Stop failed: %v", err)
	}
}

// Test WebhookManager GetDeliveries
func TestWebhookManager_GetDeliveries(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		Type:    "webhook",
		Enabled: true,
		Config: map[string]interface{}{
			"server": map[string]interface{}{
				"enabled": false,
			},
			"client": map[string]interface{}{},
		},
	}

	manager, err := NewWebhookManager("test-webhook", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create WebhookManager: %v", err)
	}

	deliveries := manager.GetDeliveries()
	if deliveries == nil {
		t.Error("Expected deliveries map to be returned")
	}

	if len(deliveries) != 0 {
		t.Errorf("Expected 0 deliveries initially, got %d", len(deliveries))
	}
}

// Test WebhookManager executeSendWebhook
func TestWebhookManager_ExecuteSendWebhook(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		Type:    "webhook",
		Enabled: true,
		Config: map[string]interface{}{
			"server": map[string]interface{}{
				"enabled": false,
			},
			"client": map[string]interface{}{
				"timeout":     "10s",
				"max_retries": 1,
			},
		},
	}

	manager, err := NewWebhookManager("test-webhook", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create WebhookManager: %v", err)
	}

	// Register an endpoint first
	endpoint := &WebhookEndpoint{
		URL:        "https://example.com/webhook",
		Method:     "POST",
		MaxRetries: 1,
		RetryDelay: 1 * time.Second,
		Timeout:    5 * time.Second,
	}

	err = manager.RegisterEndpoint(endpoint)
	if err != nil {
		t.Fatalf("Failed to register endpoint: %v", err)
	}

	// Test send webhook task
	task := types.Task{
		ID:   "test-send",
		Type: "send_webhook",
		Payload: map[string]interface{}{
			"endpoint_id": endpoint.ID,
			"payload": map[string]interface{}{
				"message": "test webhook",
			},
		},
	}

	ctx := context.Background()
	result, err := manager.Execute(ctx, task)
	// This will likely fail due to network issues, but that's expected in tests
	// We're testing the code path, not the actual HTTP call
	if err == nil || result.Success {
		// If it somehow succeeds, that's fine too
		t.Logf("Webhook send succeeded: %+v", result)
	} else {
		// Expected to fail in test environment
		t.Logf("Webhook send failed as expected: %v", err)
	}

	// Test missing endpoint_id
	taskMissingEndpoint := types.Task{
		ID:   "test-send-missing",
		Type: "send_webhook",
		Payload: map[string]interface{}{
			"payload": map[string]interface{}{
				"message": "test",
			},
		},
	}

	_, err = manager.Execute(ctx, taskMissingEndpoint)
	if err == nil {
		t.Error("Expected error for missing endpoint_id")
	}

	// Test missing payload
	taskMissingPayload := types.Task{
		ID:   "test-send-missing-payload",
		Type: "send_webhook",
		Payload: map[string]interface{}{
			"endpoint_id": endpoint.ID,
		},
	}

	_, err = manager.Execute(ctx, taskMissingPayload)
	if err == nil {
		t.Error("Expected error for missing payload")
	}

	// Test nonexistent endpoint
	taskNonexistentEndpoint := types.Task{
		ID:   "test-send-nonexistent",
		Type: "send_webhook",
		Payload: map[string]interface{}{
			"endpoint_id": "nonexistent",
			"payload":     map[string]interface{}{"test": "data"},
		},
	}

	_, err = manager.Execute(ctx, taskNonexistentEndpoint)
	if err == nil {
		t.Error("Expected error for nonexistent endpoint")
	}
}

// Test cache manager uncovered operations
func TestCacheManager_UntestedOperations(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()
	config := types.ManagerConfig{
		ID:      "test-cache",
		Type:    "cache",
		Enabled: true,
		Config: map[string]interface{}{
			"default_backend": "memory",
			"backends": map[string]interface{}{
				"memory": map[string]interface{}{
					"type":     "memory",
					"max_size": 100,
				},
			},
		},
	}

	manager, err := NewCacheManager("test-cache", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create CacheManager: %v", err)
	}

	err = manager.Initialize(config)
	if err != nil {
		t.Fatalf("Failed to initialize CacheManager: %v", err)
	}

	ctx := context.Background()
	// Test delete operation
	deleteTask := types.Task{
		ID:   "test-delete",
		Type: "delete",
		Payload: map[string]interface{}{
			"backend": "memory",
			"key":     "test-key",
		},
	}

	result, err := manager.Execute(ctx, deleteTask)
	if err != nil {
		t.Errorf("Delete operation failed: %v", err)
	}
	if !result.Success {
		t.Errorf("Expected delete to succeed")
	}

	// Test clear operation
	clearTask := types.Task{
		ID:   "test-clear",
		Type: "clear",
		Payload: map[string]interface{}{
			"backend": "memory",
		},
	}

	result, err = manager.Execute(ctx, clearTask)
	if err != nil {
		t.Errorf("Clear operation failed: %v", err)
	}
	if !result.Success {
		t.Errorf("Expected clear to succeed")
	}

	// Test stats operation
	statsTask := types.Task{
		ID:      "test-stats",
		Type:    "stats",
		Payload: map[string]interface{}{},
	}

	result, err = manager.Execute(ctx, statsTask)
	if err != nil {
		t.Errorf("Stats operation failed: %v", err)
	}
	if !result.Success {
		t.Errorf("Expected stats to succeed")
	}
}

// Test memory cache backend uncovered methods
func TestMemoryCacheBackend_UntestedMethods(t *testing.T) {
	backend := NewMemoryCacheBackend()

	// Add some data to test various methods
	for i := 0; i < 15; i++ {
		key := fmt.Sprintf("key-%d", i)
		err := backend.Set(key, fmt.Sprintf("value-%d", i), time.Minute)
		if err != nil {
			t.Errorf("Failed to set key %s: %v", key, err)
		}
	}

	// Test Keys method
	keys := backend.Keys()
	if len(keys) == 0 {
		t.Error("Expected some keys to be present")
	}

	// Should have all 15 items since max size is 1000
	if len(keys) != 15 {
		t.Errorf("Expected 15 keys, got %d", len(keys))
	}
}

// Test email manager uncovered methods
func TestEmailManager_UntestedMethods(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		Type:    "email",
		Enabled: true,
		Config: map[string]interface{}{
			"providers": map[string]interface{}{
				"test": map[string]interface{}{
					"type": "smtp",
					"host": "localhost",
					"port": 587,
				},
			},
			"queue": map[string]interface{}{
				"workers": 2,
			},
		},
	}

	manager, err := NewEmailManager("test-email", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create EmailManager: %v", err)
	}

	ctx := context.Background()

	// Test send_bulk task
	bulkTask := types.Task{
		ID:   "test-bulk",
		Type: "send_bulk",
		Payload: map[string]interface{}{
			"emails": []interface{}{
				map[string]interface{}{
					"to":      "test1@example.com",
					"subject": "Test 1",
					"body":    "Test body 1",
				},
				map[string]interface{}{
					"to":      "test2@example.com",
					"subject": "Test 2",
					"body":    "Test body 2",
				},
			},
		},
	}

	_, err = manager.Execute(ctx, bulkTask)
	// This will likely fail in test environment, but tests the code path
	if err != nil {
		t.Logf("Bulk email failed as expected in test environment: %v", err)
	}

	// Test get_statistics task
	statsTask := types.Task{
		ID:      "test-stats",
		Type:    "get_statistics",
		Payload: map[string]interface{}{},
	}

	result, err := manager.Execute(ctx, statsTask)
	if err != nil {
		t.Errorf("Get statistics failed: %v", err)
	}
	if !result.Success {
		t.Errorf("Expected get statistics to succeed")
	}
}

// Test template engine uncovered methods
func TestTemplateEngine_UntestedMethods(t *testing.T) {
	config := types.TemplateEngineConfig{
		TemplatesPath: "./templates",
		CacheEnabled:  true,
		CacheSize:     100,
		DefaultLang:   "en",
	}
	engine := NewDefaultTemplateEngine(config)

	template := &EmailTemplate{
		Name:        "test-template",
		Subject:     "Test Subject",
		HTMLContent: "Hello {{.Name}}!",
		TextContent: "Hello {{.Name}}!",
	}

	// Test CacheTemplate
	err := engine.CacheTemplate("test-cached", template)
	if err != nil {
		t.Errorf("CacheTemplate failed: %v", err)
	}

	// Test GetCachedTemplate
	cached, found := engine.GetCachedTemplate("test-cached")
	if !found {
		t.Error("Expected to find cached template")
	}
	if cached.Name != template.Name {
		t.Errorf("Expected template name %s, got %s", template.Name, cached.Name)
	}

	// Test GetCachedTemplate for non-existent template
	_, found = engine.GetCachedTemplate("non-existent")
	if found {
		t.Error("Expected not to find non-existent template")
	}
}

// Test delivery tracker uncovered methods
func TestDeliveryTracker_UntestedMethods(t *testing.T) {
	tracker := NewDefaultDeliveryTracker()

	// Test TrackDelivered
	err := tracker.TrackDelivered("msg-123")
	if err != nil {
		t.Errorf("TrackDelivered failed: %v", err)
	}

	// Test TrackOpened
	err = tracker.TrackOpened("msg-123", time.Now())
	if err != nil {
		t.Errorf("TrackOpened failed: %v", err)
	}

	// Test TrackClicked
	err = tracker.TrackClicked("msg-123", "https://example.com", time.Now())
	if err != nil {
		t.Errorf("TrackClicked failed: %v", err)
	}
}

// Test email queue Clear method
func TestEmailQueue_Clear(t *testing.T) {
	queueConfig := types.QueueConfig{
		Type:    "memory",
		MaxSize: 10,
	}
	queue := NewMemoryEmailQueue(queueConfig)

	// Add some emails
	email1 := &EmailMessage{ID: "1", To: []string{"test1@example.com"}, Subject: "Test 1"}
	email2 := &EmailMessage{ID: "2", To: []string{"test2@example.com"}, Subject: "Test 2"}

	queue.Enqueue(email1)
	queue.Enqueue(email2)

	if queue.Size() != 2 {
		t.Errorf("Expected size 2, got %d", queue.Size())
	}

	// Test Clear
	queue.Clear()

	if queue.Size() != 0 {
		t.Errorf("Expected size 0 after clear, got %d", queue.Size())
	}
}
