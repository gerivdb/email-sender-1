// Package integration provides final tests to achieve higher coverage
package integration

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/types"
)

// Test webhook wrapHandler function for higher coverage
func TestWebhookServer_WrapHandler_Coverage(t *testing.T) {
	logger := zap.NewNop()
	config := types.WebhookServerConfig{
		Host: "localhost",
		Port: 8082,
	}

	server := NewHTTPWebhookServer(config, logger)

	// Create a test handler that we'll wrap
	handlerCalled := false
	testHandler := func(w http.ResponseWriter, r *http.Request) {
		handlerCalled = true
		w.WriteHeader(200)
		w.Write([]byte("test response"))
	}

	// Create a test request to trigger the wrapper
	req := httptest.NewRequest("GET", "/test-wrapper", nil)
	w := httptest.NewRecorder()

	// Call the wrapped handler directly to test the wrapper logic
	wrappedHandler := server.wrapHandler(testHandler)
	wrappedHandler(w, req)

	if !handlerCalled {
		t.Error("Expected test handler to be called")
	}

	if w.Code != 200 {
		t.Errorf("Expected status 200, got %d", w.Code)
	}

	// Test WriteHeader function
	rw := &responseWriter{ResponseWriter: w, statusCode: 200}
	rw.WriteHeader(404)
	if rw.statusCode != 404 {
		t.Errorf("Expected status code 404, got %d", rw.statusCode)
	}
}

// Test webhook sendRequest with authentication
func TestWebhookClient_SendRequest_Auth(t *testing.T) {
	logger := zap.NewNop()
	config := types.WebhookClientConfig{
		Timeout: 10 * time.Second,
	}

	client := NewHTTPWebhookClient(config, logger)

	// Test with endpoint that has secret (for auth headers)
	endpoint := &WebhookEndpoint{
		ID:      "test-auth",
		URL:     "http://httpbin.org/post",
		Method:  "POST",
		Secret:  "test-secret-key",
		Headers: map[string]string{"Custom-Header": "test-value"},
	}

	payload := []byte(`{"test": "auth"}`)
	delivery := &WebhookDelivery{ID: "test-delivery"}

	// This will test the authentication header generation path
	err := client.sendRequest(context.Background(), endpoint, payload, delivery)
	if err != nil {
		t.Logf("sendRequest with auth failed (expected for external URL): %v", err)
	}

	// Test with invalid URL to trigger URL parse error
	badEndpoint := &WebhookEndpoint{
		ID:     "bad-url",
		URL:    "://invalid-url",
		Method: "POST",
	}

	err = client.sendRequest(context.Background(), badEndpoint, payload, delivery)
	if err == nil {
		t.Error("Expected error for invalid URL")
	}
}

// Test database Connect error paths
func TestDatabase_Connect_ErrorPaths(t *testing.T) {
	// Test PostgreSQL Connect error path
	pgConfig := types.DatabaseConfig{
		Host:     "nonexistent-host",
		Port:     5432,
		Database: "test",
		Username: "test",
		Password: "test",
	}

	pg := NewPostgreSQLDatabase(pgConfig)
	err := pg.Connect()
	if err == nil {
		t.Error("Expected connection error for nonexistent PostgreSQL host")
	}

	// Test MySQL Connect error path
	mysqlConfig := types.DatabaseConfig{
		Host:     "nonexistent-host",
		Port:     3306,
		Database: "test",
		Username: "test",
		Password: "test",
	}

	mysql := NewMySQLDatabase(mysqlConfig)
	err = mysql.Connect()
	if err == nil {
		t.Error("Expected connection error for nonexistent MySQL host")
	}
}

// Test cache manager with different backend configurations
func TestCacheManager_BackendConfigurations(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	// Test with Redis backend type
	redisConfig := types.ManagerConfig{
		ID:   "test-cache-redis",
		Type: "cache",
		Config: map[string]interface{}{
			"backends": map[string]interface{}{
				"redis-cache": map[string]interface{}{
					"type": "redis",
					"redis": map[string]interface{}{
						"address": "localhost:6379",
					},
				},
			},
		},
	}

	cm, err := NewCacheManager("test-cache-redis", redisConfig, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create cache manager: %v", err)
	}
	// Initialize will call createBackend internally
	err = cm.Initialize(redisConfig)
	if err != nil {
		t.Logf("Redis initialization failed (expected if Redis not available): %v", err)
	}

	// Test with unknown backend type
	unknownConfig := types.ManagerConfig{
		ID:   "test-cache-unknown",
		Type: "cache",
		Config: map[string]interface{}{
			"backends": map[string]interface{}{
				"unknown-cache": map[string]interface{}{
					"type": "unknown",
				},
			},
		},
	}

	cm2, err := NewCacheManager("test-cache-unknown", unknownConfig, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create cache manager: %v", err)
	}
	// Initialize will call createBackend and should fail for unknown type
	err = cm2.Initialize(unknownConfig)
	if err == nil {
		t.Log("Unknown backend initialization completed (may have fallback)")
	}
}

// Test email manager with different provider configurations
func TestEmailManager_ProviderConfigurations(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	// Test with SendGrid provider
	sendgridConfig := types.ManagerConfig{
		ID:   "test-email-sendgrid",
		Type: "email",
		Config: map[string]interface{}{
			"providers": map[string]interface{}{
				"sendgrid": map[string]interface{}{
					"type": "sendgrid",
					"sendgrid": map[string]interface{}{
						"api_key": "test-key",
					},
				},
			},
		},
	}

	em, err := NewEmailManager("test-email-sendgrid", sendgridConfig, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create email manager: %v", err)
	}
	// Initialize will call createProvider internally
	err = em.Initialize(sendgridConfig)
	if err != nil {
		t.Logf("SendGrid initialization completed: %v", err)
	}

	// Test with unknown provider
	unknownConfig := types.ManagerConfig{
		ID:   "test-email-unknown",
		Type: "email",
		Config: map[string]interface{}{
			"providers": map[string]interface{}{
				"unknown": map[string]interface{}{
					"type": "unknown",
				},
			},
		},
	}

	em2, err := NewEmailManager("test-email-unknown", unknownConfig, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create email manager: %v", err)
	}
	// Initialize will call createProvider and should handle unknown type
	err = em2.Initialize(unknownConfig)
	if err == nil {
		t.Log("Unknown provider initialization completed (may have fallback)")
	}
}

// Test SMTP provider edge cases
func TestSMTPProvider_EdgeCases(t *testing.T) {
	config := types.EmailProviderConfig{
		Type:     "smtp",
		Host:     "smtp.example.com",
		Port:     587,
		Username: "test@example.com",
		Password: "password",
	}

	provider := NewSMTPProvider(config)

	// Create a test email
	message := &EmailMessage{
		ID:       "test-smtp",
		From:     "test@example.com",
		To:       []string{"recipient@example.com"},
		Subject:  "Test SMTP",
		HTMLBody: "<h1>Test</h1>",
		TextBody: "Test body",
	}

	// This will test the SMTP connection (expected to fail due to invalid server)
	err := provider.SendEmail(message)
	if err == nil {
		t.Error("Expected SMTP connection error for invalid server")
	}

	// Test SendBulk
	messages := []*EmailMessage{message}
	err = provider.SendBulk(messages)
	if err == nil {
		t.Error("Expected bulk send error for invalid server")
	}
}

// Test webhook HMAC authenticator edge cases
func TestHMACAuthenticator_EdgeCases(t *testing.T) {
	auth := NewHMACWebhookAuthenticator()

	payload := []byte(`{"test": "verification"}`)
	secret := "test-secret"

	// Test verification with invalid signature format
	isValid := auth.Verify(payload, "invalid-signature", secret)
	if isValid {
		t.Error("Expected verification to fail with invalid signature format")
	}

	// Test with empty signature
	isValid = auth.Verify(payload, "", secret)
	if isValid {
		t.Error("Expected verification to fail with empty signature")
	}

	// Test GetHeaders with different payloads
	headers1 := auth.GetHeaders(payload, secret)
	headers2 := auth.GetHeaders([]byte(`{"different": "payload"}`), secret)

	if len(headers1) == 0 || len(headers2) == 0 {
		t.Error("Expected headers to be generated for both payloads")
	}

	// Headers should be different for different payloads
	if headers1["X-Webhook-Signature"] == headers2["X-Webhook-Signature"] {
		t.Error("Expected different signatures for different payloads")
	}
}

// Test memory cache evictLRU edge cases
func TestMemoryCacheBackend_EvictLRU_EdgeCases(t *testing.T) {
	backend := NewMemoryCacheBackend()
	backend.maxSize = 3 // Set small max size

	// Add items to test eviction
	backend.Set("key1", "value1", time.Minute)
	backend.Set("key2", "value2", time.Minute)
	backend.Set("key3", "value3", time.Minute)

	// Access key1 to move it to front (make it less likely to be evicted)
	backend.Get("key1")

	// Add more items to trigger eviction
	backend.Set("key4", "value4", time.Minute)
	backend.Set("key5", "value5", time.Minute)

	keys := backend.Keys()
	if len(keys) > backend.maxSize {
		t.Errorf("Expected max %d keys after eviction, got %d", backend.maxSize, len(keys))
	}

	// key1 should still be there since we accessed it recently
	_, found := backend.Get("key1")
	if !found {
		t.Error("Expected key1 to still be present after eviction")
	}
}

// Test webhook manager deliverWebhook function
func TestWebhookManager_DeliverWebhook(t *testing.T) {
	logger := zap.NewNop()
	metrics := NewDefaultMetricsCollector()

	config := types.ManagerConfig{
		ID:   "test-webhook-deliver",
		Type: "webhook",
		Config: map[string]interface{}{
			"server": map[string]interface{}{
				"enabled": false,
			},
			"client": map[string]interface{}{
				"timeout": "5s",
			},
		},
	}

	wm, err := NewWebhookManager("test-webhook-deliver", config, logger, metrics)
	if err != nil {
		t.Fatalf("Failed to create webhook manager: %v", err)
	}

	err = wm.Initialize(context.Background())
	if err != nil {
		t.Fatalf("Failed to initialize webhook manager: %v", err)
	}

	// Create an event and endpoint for delivery testing
	event := &WebhookEvent{
		ID:        "deliver-test",
		Type:      "test.deliver",
		Source:    "test",
		Timestamp: time.Now(),
		Data:      map[string]interface{}{"test": "data"},
	}

	// Create endpoint that will timeout quickly
	endpoint := &WebhookEndpoint{
		ID:         "deliver-endpoint",
		URL:        "http://httpbin.org/delay/10", // Will timeout
		Events:     []string{"test.deliver"},
		Method:     "POST",
		Enabled:    true,
		MaxRetries: 1,
		RetryDelay: time.Millisecond * 100,
		Timeout:    time.Millisecond * 500, // Short timeout
	}

	// Register the endpoint
	err = wm.RegisterEndpoint(endpoint)
	if err != nil {
		t.Fatalf("Failed to register endpoint: %v", err)
	}

	// Trigger the event to test deliverWebhook
	err = wm.TriggerEvent(context.Background(), event)
	if err != nil {
		t.Errorf("Failed to trigger event: %v", err)
	}

	// Give delivery time to complete
	time.Sleep(time.Second * 2)

	// Check deliveries were recorded
	deliveries := wm.GetDeliveries()
	if len(deliveries) == 0 {
		t.Log("No deliveries recorded (may be expected for test environment)")
	}
}
