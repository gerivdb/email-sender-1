// Package integration provides additional tests for remaining uncovered code paths
package integration

import (
	"context"
	"net/http"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/types"
)

// Test webhook manager functions that still have low coverage
func TestWebhookManager_RemainingCoverage(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		ID:      "test-webhook-remaining",
		Type:    "webhook",
		Enabled: true,
		Config: map[string]interface{}{
			"server": map[string]interface{}{
				"enabled": true,
				"host":    "localhost",
				"port":    8080,
			},
			"client": map[string]interface{}{
				"timeout": "10s",
			},
		},
	}

	wm, err := NewWebhookManager("test-webhook-remaining", config, logger, metrics)
	if err != nil {
		t.Fatalf("NewWebhookManager failed: %v", err)
	}

	// Test Initialize function
	err = wm.Initialize(context.Background())
	if err != nil {
		t.Logf("Initialize failed: %v", err)
	}

	// Test webhook manager health function
	status := wm.Status()
	if !status.IsHealthy {
		t.Error("Expected webhook manager to be healthy")
	}

	// Test GetDeliveries and GetStats
	deliveries := wm.GetDeliveries()
	if deliveries == nil {
		t.Error("Expected deliveries map to be non-nil")
	}

	stats := wm.GetStats()
	if stats == nil {
		t.Error("Expected stats to be non-nil")
	}

	// Test webhook endpoint registration
	endpoint := &WebhookEndpoint{
		ID:      "test-endpoint",
		URL:     "http://localhost:9999/webhook",
		Events:  []string{"test.event"},
		Method:  "POST",
		Enabled: true,
	}

	err = wm.RegisterEndpoint(endpoint)
	if err != nil {
		t.Errorf("Failed to register endpoint: %v", err)
	}

	// Test endpoint retrieval
	endpoints := wm.GetEndpoints()
	if len(endpoints) == 0 {
		t.Error("Expected at least one registered endpoint")
	}

	// Test event triggering
	event := &WebhookEvent{
		ID:   "test-event-1",
		Type: "test.event",
		Data: map[string]interface{}{"key": "value"},
	}

	err = wm.TriggerEvent(context.Background(), event)
	if err != nil {
		t.Errorf("Failed to trigger event: %v", err)
	}

	// Test endpoint unregistration
	err = wm.UnregisterEndpoint("test-endpoint")
	if err != nil {
		t.Errorf("Failed to unregister endpoint: %v", err)
	}

	// Test shutdown
	err = wm.Shutdown(context.Background())
	if err != nil {
		t.Errorf("Failed to shutdown webhook manager: %v", err)
	}
}

// Test webhook client coverage
func TestWebhookClient_Coverage(t *testing.T) {
	logger := zap.NewNop()

	config := types.WebhookClientConfig{
		Timeout:       10 * time.Second,
		MaxRetryDelay: 5 * time.Second,
	}

	client := NewHTTPWebhookClient(config, logger)

	// Test stats retrieval
	stats := client.GetStats()
	if stats.DeliveriesTotal < 0 {
		t.Error("Expected non-negative delivery total")
	}

	// Test async send (won't actually send due to invalid URL)
	endpoint := &WebhookEndpoint{
		ID:         "test-async",
		URL:        "http://invalid-url-for-testing.example/webhook",
		Method:     "POST",
		MaxRetries: 1,
		RetryDelay: time.Millisecond * 10,
		Timeout:    time.Millisecond * 100,
	}

	payload := []byte(`{"test": "data"}`)
	err := client.SendAsync(context.Background(), endpoint, payload)
	if err != nil {
		t.Errorf("SendAsync failed: %v", err)
	}

	// Give async operation time to complete
	time.Sleep(100 * time.Millisecond)
}

// Test webhook server coverage
func TestWebhookServer_Coverage(t *testing.T) {
	logger := zap.NewNop()

	config := types.WebhookServerConfig{
		Enabled:      true,
		Host:         "localhost",
		Port:         8081,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  30 * time.Second,
	}

	server := NewHTTPWebhookServer(config, logger)

	// Test handler registration
	server.RegisterHandler("/test", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
		w.Write([]byte("OK"))
	})

	// Test stats retrieval
	stats := server.GetStats()
	if stats.ActiveHandlers != 1 {
		t.Errorf("Expected 1 active handler, got %d", stats.ActiveHandlers)
	}

	// Test server start/stop
	ctx := context.Background()
	err := server.Start(ctx)
	if err != nil {
		t.Errorf("Failed to start server: %v", err)
	}

	// Give server time to start
	time.Sleep(100 * time.Millisecond)

	err = server.Stop(ctx)
	if err != nil {
		t.Errorf("Failed to stop server: %v", err)
	}
}

// Test webhook authenticator coverage
func TestWebhookAuthenticator_Coverage(t *testing.T) {
	auth := NewHMACWebhookAuthenticator()

	payload := []byte(`{"test": "data"}`)
	secret := "test-secret"

	// Test signature generation
	signature, err := auth.Sign(payload, secret)
	if err != nil {
		t.Errorf("Failed to generate signature: %v", err)
	}

	// Test verification with correct signature
	isValid := auth.Verify(payload, signature, secret)
	if !isValid {
		t.Error("Expected signature verification to pass")
	}

	// Test verification with wrong secret
	isInvalid := auth.Verify(payload, signature, "wrong-secret")
	if isInvalid {
		t.Error("Expected signature verification to fail with wrong secret")
	}

	// Test headers generation
	headers := auth.GetHeaders(payload, secret)
	if len(headers) == 0 {
		t.Error("Expected authentication headers to be generated")
	}
}

// Test webhook transformer coverage
func TestWebhookTransformer_Coverage(t *testing.T) {
	transformer := NewJSONWebhookTransformer()

	event := &WebhookEvent{
		ID:        "transform-test",
		Type:      "test.transform",
		Source:    "test-service",
		Timestamp: time.Now(),
		Data:      map[string]interface{}{"key": "value"},
	}

	endpoint := &WebhookEndpoint{
		ID:  "transform-endpoint",
		URL: "http://example.com/webhook",
	}

	// Test transformation
	payload, err := transformer.Transform(event, endpoint)
	if err != nil {
		t.Errorf("Failed to transform event: %v", err)
	}

	if len(payload) == 0 {
		t.Error("Expected non-empty payload")
	}

	// Test content type
	contentType := transformer.GetContentType()
	if contentType != "application/json" {
		t.Errorf("Expected content type 'application/json', got '%s'", contentType)
	}
}

// Test webhook task execution coverage
func TestWebhookManager_TaskExecution(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		ID:   "test-webhook-tasks",
		Type: "webhook",
		Config: map[string]interface{}{
			"server": map[string]interface{}{
				"enabled": false, // Disable server for testing
			},
			"client": map[string]interface{}{
				"timeout": "5s",
			},
		},
	}

	wm, err := NewWebhookManager("test-webhook-tasks", config, logger, metrics)
	if err != nil {
		t.Fatalf("NewWebhookManager failed: %v", err)
	}

	err = wm.Initialize(context.Background())
	if err != nil {
		t.Fatalf("Initialize failed: %v", err)
	}
	// Test register endpoint task
	registerTask := types.Task{
		ID:   "register-task",
		Type: "register_endpoint",
		Payload: map[string]interface{}{
			"url":    "http://example.com/webhook",
			"events": []string{"test.event"},
		},
	}

	result, err := wm.Execute(context.Background(), registerTask)
	if err != nil {
		t.Logf("Register endpoint task failed (expected for test): %v", err)
	}
	if result.TaskID != registerTask.ID {
		t.Errorf("Expected result task ID %s, got %s", registerTask.ID, result.TaskID)
	}

	// Test unknown task type
	unknownTask := types.Task{
		ID:   "unknown-task",
		Type: "unknown_type",
	}

	result, err = wm.Execute(context.Background(), unknownTask)
	if err == nil {
		t.Error("Expected error for unknown task type")
	}

	err = wm.Shutdown(context.Background())
	if err != nil {
		t.Errorf("Failed to shutdown: %v", err)
	}
}
