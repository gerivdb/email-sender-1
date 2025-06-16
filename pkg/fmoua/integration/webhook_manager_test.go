// Package integration provides tests for WebhookManager
package integration

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/interfaces"
	"email_sender/pkg/fmoua/types"
)

func TestWebhookManager_Implementation(t *testing.T) {
	// Test that WebhookManager implements the Manager interface
	var _ interfaces.Manager = (*WebhookManager)(nil)
}

func TestNewWebhookManager(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		Type:    "webhook",
		Enabled: true,
		Config: map[string]interface{}{
			"server": map[string]interface{}{
				"enabled": true,
				"host":    "localhost",
				"port":    8080,
			},
			"client": map[string]interface{}{
				"timeout":     "30s",
				"max_retries": 3,
			},
		},
	}

	manager, err := NewWebhookManager("test-webhook", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create WebhookManager: %v", err)
	}

	if manager == nil {
		t.Fatal("WebhookManager is nil")
	}

	if manager.GetID() != "test-webhook" {
		t.Errorf("Expected ID 'test-webhook', got '%s'", manager.GetID())
	}

	if manager.GetType() != "webhook" {
		t.Errorf("Expected type 'webhook', got '%s'", manager.GetType())
	}

	status := manager.GetStatus()
	if status != types.ManagerStatusStopped {
		t.Errorf("Expected status 'stopped', got '%s'", status)
	}
}

func TestWebhookManager_Lifecycle(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		Type:    "webhook",
		Enabled: true,
		Config: map[string]interface{}{
			"server": map[string]interface{}{
				"enabled": false, // Disable server for testing
				"host":    "localhost",
				"port":    8081,
			},
			"client": map[string]interface{}{
				"timeout":     "30s",
				"max_retries": 3,
			},
		},
	}

	manager, err := NewWebhookManager("test-webhook", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create WebhookManager: %v", err)
	}

	ctx := context.Background()

	// Test initialization
	err = manager.Initialize(ctx)
	if err != nil {
		t.Fatalf("Failed to initialize WebhookManager: %v", err)
	}

	status := manager.GetStatus()
	if status != types.ManagerStatusRunning {
		t.Errorf("Expected status 'running' after initialization, got '%s'", status)
	}

	// Test health check
	err = manager.Health()
	if err != nil {
		t.Fatalf("Health check failed: %v", err)
	}

	// Test shutdown
	err = manager.Shutdown(ctx)
	if err != nil {
		t.Fatalf("Failed to shutdown WebhookManager: %v", err)
	}

	status = manager.GetStatus()
	if status != types.ManagerStatusStopped {
		t.Errorf("Expected status 'stopped' after shutdown, got '%s'", status)
	}
}

func TestWebhookManager_RegisterEndpoint(t *testing.T) {
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

	// Test registering an endpoint
	endpoint := &WebhookEndpoint{
		URL:    "https://example.com/webhook",
		Events: []string{"user.created", "user.updated"},
		Secret: "test-secret",
	}

	err = manager.RegisterEndpoint(endpoint)
	if err != nil {
		t.Fatalf("Failed to register endpoint: %v", err)
	}

	if endpoint.ID == "" {
		t.Error("Endpoint ID was not generated")
	}

	if endpoint.CreatedAt.IsZero() {
		t.Error("Endpoint CreatedAt was not set")
	}

	if endpoint.Method != "POST" {
		t.Errorf("Expected default method 'POST', got '%s'", endpoint.Method)
	}

	// Test getting endpoints
	endpoints := manager.GetEndpoints()
	if len(endpoints) != 1 {
		t.Errorf("Expected 1 endpoint, got %d", len(endpoints))
	}

	storedEndpoint, exists := endpoints[endpoint.ID]
	if !exists {
		t.Error("Registered endpoint not found")
	}

	if storedEndpoint.URL != endpoint.URL {
		t.Errorf("Expected URL '%s', got '%s'", endpoint.URL, storedEndpoint.URL)
	}
}

func TestWebhookManager_UnregisterEndpoint(t *testing.T) {
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

	// Register an endpoint first
	endpoint := &WebhookEndpoint{
		URL:    "https://example.com/webhook",
		Events: []string{"test"},
	}

	err = manager.RegisterEndpoint(endpoint)
	if err != nil {
		t.Fatalf("Failed to register endpoint: %v", err)
	}

	// Test unregistering the endpoint
	err = manager.UnregisterEndpoint(endpoint.ID)
	if err != nil {
		t.Fatalf("Failed to unregister endpoint: %v", err)
	}

	// Verify endpoint is removed
	endpoints := manager.GetEndpoints()
	if len(endpoints) != 0 {
		t.Errorf("Expected 0 endpoints after unregistering, got %d", len(endpoints))
	}

	// Test unregistering non-existent endpoint
	err = manager.UnregisterEndpoint("non-existent")
	if err == nil {
		t.Error("Expected error when unregistering non-existent endpoint")
	}
}

func TestWebhookManager_TriggerEvent(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	// Create a test server to receive webhooks
	receivedPayloads := make([]map[string]interface{}, 0)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var payload map[string]interface{}
		json.NewDecoder(r.Body).Decode(&payload)
		receivedPayloads = append(receivedPayloads, payload)
		w.WriteHeader(http.StatusOK)
	}))
	defer server.Close()

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

	// Register an endpoint
	endpoint := &WebhookEndpoint{
		URL:     server.URL,
		Events:  []string{"user.created"},
		Enabled: true,
	}

	err = manager.RegisterEndpoint(endpoint)
	if err != nil {
		t.Fatalf("Failed to register endpoint: %v", err)
	}

	// Trigger an event
	event := &WebhookEvent{
		ID:     "test-event-1",
		Type:   "user.created",
		Source: "test",
		Data: map[string]interface{}{
			"user_id": "12345",
			"email":   "test@example.com",
		},
	}

	ctx := context.Background()
	err = manager.TriggerEvent(ctx, event)
	if err != nil {
		t.Fatalf("Failed to trigger event: %v", err)
	}

	// Wait for webhook delivery
	time.Sleep(100 * time.Millisecond)

	// Verify webhook was delivered
	if len(receivedPayloads) != 1 {
		t.Errorf("Expected 1 webhook delivery, got %d", len(receivedPayloads))
	}

	if len(receivedPayloads) > 0 {
		payload := receivedPayloads[0]
		if payload["id"] != event.ID {
			t.Errorf("Expected event ID '%s', got '%v'", event.ID, payload["id"])
		}
		if payload["type"] != event.Type {
			t.Errorf("Expected event type '%s', got '%v'", event.Type, payload["type"])
		}
	}
}

func TestWebhookManager_Execute(t *testing.T) {
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

	ctx := context.Background()

	// Test register_endpoint task
	registerTask := types.Task{
		ID:   "task-1",
		Type: "register_endpoint",
		Payload: map[string]interface{}{
			"endpoint": map[string]interface{}{
				"url":    "https://example.com/webhook",
				"events": []interface{}{"test.event"},
				"secret": "test-secret",
			},
		},
	}

	result, err := manager.Execute(ctx, registerTask)
	if err != nil {
		t.Fatalf("Failed to execute register_endpoint task: %v", err)
	}

	if !result.Success {
		t.Errorf("Expected task to succeed, got error: %s", result.Error)
	}

	endpointID, ok := result.Data["endpoint_id"].(string)
	if !ok || endpointID == "" {
		t.Error("Expected endpoint_id in result data")
	}

	// Test unregister_endpoint task
	unregisterTask := types.Task{
		ID:   "task-2",
		Type: "unregister_endpoint",
		Payload: map[string]interface{}{
			"endpoint_id": endpointID,
		},
	}

	result, err = manager.Execute(ctx, unregisterTask)
	if err != nil {
		t.Fatalf("Failed to execute unregister_endpoint task: %v", err)
	}

	if !result.Success {
		t.Errorf("Expected task to succeed, got error: %s", result.Error)
	}

	// Test trigger_event task
	triggerTask := types.Task{
		ID:   "task-3",
		Type: "trigger_event",
		Payload: map[string]interface{}{
			"event": map[string]interface{}{
				"type":   "test.event",
				"source": "test",
				"data": map[string]interface{}{
					"message": "test event",
				},
			},
		},
	}

	result, err = manager.Execute(ctx, triggerTask)
	if err != nil {
		t.Fatalf("Failed to execute trigger_event task: %v", err)
	}

	if !result.Success {
		t.Errorf("Expected task to succeed, got error: %s", result.Error)
	}

	// Test unknown task type
	unknownTask := types.Task{
		ID:      "task-4",
		Type:    "unknown_task",
		Payload: map[string]interface{}{},
	}

	result, err = manager.Execute(ctx, unknownTask)
	if err == nil {
		t.Error("Expected error for unknown task type")
	}

	if result.Success {
		t.Error("Expected task to fail for unknown task type")
	}
}

func TestWebhookManager_GetStats(t *testing.T) {
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

	// Register an endpoint
	endpoint := &WebhookEndpoint{
		URL:    "https://example.com/webhook",
		Events: []string{"test"},
	}

	err = manager.RegisterEndpoint(endpoint)
	if err != nil {
		t.Fatalf("Failed to register endpoint: %v", err)
	}

	stats := manager.GetStats()

	expectedEndpoints := 1
	if endpoints, ok := stats["endpoints"].(int); !ok || endpoints != expectedEndpoints {
		t.Errorf("Expected %d endpoints in stats, got %v", expectedEndpoints, stats["endpoints"])
	}

	if _, ok := stats["client_stats"].(WebhookClientStats); !ok {
		t.Error("Expected client_stats in stats")
	}

	if serverEnabled, ok := stats["server_enabled"].(bool); !ok || serverEnabled {
		t.Error("Expected server_enabled to be false")
	}
}

func TestJSONWebhookTransformer(t *testing.T) {
	transformer := NewJSONWebhookTransformer()

	event := &WebhookEvent{
		ID:     "test-event",
		Type:   "user.created",
		Source: "test",
		Data: map[string]interface{}{
			"user_id": "12345",
			"email":   "test@example.com",
		},
		Headers: map[string]string{
			"X-Custom-Header": "test",
		},
	}

	endpoint := &WebhookEndpoint{
		ID:  "test-endpoint",
		URL: "https://example.com/webhook",
	}

	payload, err := transformer.Transform(event, endpoint)
	if err != nil {
		t.Fatalf("Failed to transform event: %v", err)
	}

	var result map[string]interface{}
	err = json.Unmarshal(payload, &result)
	if err != nil {
		t.Fatalf("Failed to unmarshal transformed payload: %v", err)
	}

	if result["id"] != event.ID {
		t.Errorf("Expected ID '%s', got '%v'", event.ID, result["id"])
	}

	if result["type"] != event.Type {
		t.Errorf("Expected type '%s', got '%v'", event.Type, result["type"])
	}

	if transformer.GetContentType() != "application/json" {
		t.Errorf("Expected content type 'application/json', got '%s'", transformer.GetContentType())
	}
}

func TestHMACWebhookAuthenticator(t *testing.T) {
	auth := NewHMACWebhookAuthenticator()
	payload := []byte(`{"test": "data"}`)
	secret := "test-secret"

	// Test signing
	signature, err := auth.Sign(payload, secret)
	if err != nil {
		t.Fatalf("Failed to sign payload: %v", err)
	}

	if signature == "" {
		t.Error("Expected non-empty signature")
	}

	// Test verification
	isValid := auth.Verify(payload, signature, secret)
	if !isValid {
		t.Error("Expected signature to be valid")
	}

	// Test verification with wrong secret
	isValid = auth.Verify(payload, signature, "wrong-secret")
	if isValid {
		t.Error("Expected signature to be invalid with wrong secret")
	}

	// Test getting headers
	headers := auth.GetHeaders(payload, secret)
	if _, ok := headers["X-Webhook-Signature"]; !ok {
		t.Error("Expected X-Webhook-Signature header")
	}

	if _, ok := headers["X-Webhook-Timestamp"]; !ok {
		t.Error("Expected X-Webhook-Timestamp header")
	}
}

func TestHTTPWebhookClient_Send(t *testing.T) {
	// Create a test server
	receivedPayloads := make([][]byte, 0)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		receivedPayloads = append(receivedPayloads, body)
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	}))
	defer server.Close()

	logger := zap.NewNop()
	config := types.WebhookClientConfig{
		Timeout:    10 * time.Second,
		MaxRetries: 1,
	}

	client := NewHTTPWebhookClient(config, logger)

	endpoint := &WebhookEndpoint{
		ID:         "test-endpoint",
		URL:        server.URL,
		Method:     "POST",
		MaxRetries: 1,
		RetryDelay: 1 * time.Second,
		Timeout:    5 * time.Second,
	}

	payload := []byte(`{"test": "data"}`)
	ctx := context.Background()

	delivery, err := client.Send(ctx, endpoint, payload)
	if err != nil {
		t.Fatalf("Failed to send webhook: %v", err)
	}

	if delivery.Status != "success" {
		t.Errorf("Expected delivery status 'success', got '%s'", delivery.Status)
	}

	if delivery.StatusCode != 200 {
		t.Errorf("Expected status code 200, got %d", delivery.StatusCode)
	}

	if len(receivedPayloads) != 1 {
		t.Errorf("Expected 1 received payload, got %d", len(receivedPayloads))
	}
}

func TestHTTPWebhookClient_SendWithRetry(t *testing.T) {
	// Create a test server that fails first request
	attempts := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		attempts++
		if attempts == 1 {
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	}))
	defer server.Close()

	logger := zap.NewNop()
	config := types.WebhookClientConfig{
		Timeout:       10 * time.Second,
		MaxRetries:    2,
		RetryDelay:    100 * time.Millisecond,
		MaxRetryDelay: 1 * time.Second,
	}

	client := NewHTTPWebhookClient(config, logger)

	endpoint := &WebhookEndpoint{
		ID:         "test-endpoint",
		URL:        server.URL,
		Method:     "POST",
		MaxRetries: 2,
		RetryDelay: 100 * time.Millisecond,
		Timeout:    5 * time.Second,
	}

	payload := []byte(`{"test": "data"}`)
	ctx := context.Background()

	delivery, err := client.Send(ctx, endpoint, payload)
	if err != nil {
		t.Fatalf("Failed to send webhook: %v", err)
	}

	if delivery.Status != "success" {
		t.Errorf("Expected delivery status 'success', got '%s'", delivery.Status)
	}

	if delivery.Attempts != 2 {
		t.Errorf("Expected 2 attempts, got %d", delivery.Attempts)
	}

	if attempts != 2 {
		t.Errorf("Expected 2 server attempts, got %d", attempts)
	}
}
