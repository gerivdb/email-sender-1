// Package manager implements webhook-based integration management
package manager

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/pkg/interfaces"
)

// WebhookIntegrationManager implements IntegrationManager using webhooks
type WebhookIntegrationManager struct {
	config      map[string]interface{}
	httpClient  *http.Client
	webhooks    map[string]WebhookConfig
	initialized bool
}

// WebhookConfig represents configuration for a webhook endpoint
type WebhookConfig struct {
	URL        string            `json:"url"`
	Method     string            `json:"method"`
	Headers    map[string]string `json:"headers"`
	Timeout    time.Duration     `json:"timeout"`
	RetryCount int               `json:"retry_count"`
	Enabled    bool              `json:"enabled"`
}

// WebhookPayload represents the payload sent to webhooks
type WebhookPayload struct {
	Event     string                 `json:"event"`
	Timestamp time.Time              `json:"timestamp"`
	Data      map[string]interface{} `json:"data"`
	Source    string                 `json:"source"`
	Version   string                 `json:"version"`
}

// WebhookResponse represents the response from a webhook
type WebhookResponse struct {
	StatusCode int                 `json:"status_code"`
	Body       string              `json:"body"`
	Headers    map[string][]string `json:"headers"`
	Duration   time.Duration       `json:"duration"`
	Error      string              `json:"error,omitempty"`
}

// NewWebhookIntegrationManager creates a new webhook-based integration manager
func NewWebhookIntegrationManager(config map[string]interface{}) (*WebhookIntegrationManager, error) {
	log.Printf("Creating Webhook IntegrationManager with config: %+v", config)

	manager := &WebhookIntegrationManager{
		config: config,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		webhooks:    make(map[string]WebhookConfig),
		initialized: false,
	}

	// Parse webhook configurations
	if err := manager.parseWebhookConfigs(); err != nil {
		return nil, fmt.Errorf("failed to parse webhook configs: %w", err)
	}

	return manager, nil
}

// Initialize sets up the webhook integration manager
func (w *WebhookIntegrationManager) Initialize(ctx context.Context) error {
	log.Println("Initializing Webhook IntegrationManager...")

	// Test webhook endpoints
	if err := w.testWebhookEndpoints(ctx); err != nil {
		log.Printf("Warning: some webhook endpoints failed tests: %v", err)
	}

	w.initialized = true
	log.Printf("Webhook IntegrationManager initialized with %d webhooks", len(w.webhooks))
	return nil
}

// NotifyDocumentAdded sends notification when a document is added
func (w *WebhookIntegrationManager) NotifyDocumentAdded(ctx context.Context, doc interfaces.Document) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Notifying document added: %s", doc.ID)

	payload := WebhookPayload{
		Event:     "document.added",
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"document_id": doc.ID,
			"content":     doc.Content,
			"metadata":    doc.Metadata,
		},
		Source:  "contextual-memory-manager",
		Version: "1.0.0",
	}

	return w.sendWebhookNotifications(ctx, payload)
}

// NotifyDocumentUpdated sends notification when a document is updated
func (w *WebhookIntegrationManager) NotifyDocumentUpdated(ctx context.Context, doc interfaces.Document) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Notifying document updated: %s", doc.ID)

	payload := WebhookPayload{
		Event:     "document.updated",
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"document_id": doc.ID,
			"content":     doc.Content,
			"metadata":    doc.Metadata,
		},
		Source:  "contextual-memory-manager",
		Version: "1.0.0",
	}

	return w.sendWebhookNotifications(ctx, payload)
}

// NotifyDocumentDeleted sends notification when a document is deleted
func (w *WebhookIntegrationManager) NotifyDocumentDeleted(ctx context.Context, documentID string) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Notifying document deleted: %s", documentID)

	payload := WebhookPayload{
		Event:     "document.deleted",
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"document_id": documentID,
		},
		Source:  "contextual-memory-manager",
		Version: "1.0.0",
	}

	return w.sendWebhookNotifications(ctx, payload)
}

// NotifySearchPerformed sends notification when a search is performed
func (w *WebhookIntegrationManager) NotifySearchPerformed(ctx context.Context, query string, results []interfaces.SearchResult) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Notifying search performed: '%s' (%d results)", query, len(results))
	// Convert results to simple format for webhook
	searchResults := make([]map[string]interface{}, len(results))
	for i, result := range results {
		searchResults[i] = map[string]interface{}{
			"document_id": result.Document.ID,
			"score":       result.Score,
			"content":     result.Document.Content,
		}
	}

	payload := WebhookPayload{
		Event:     "search.performed",
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"query":        query,
			"result_count": len(results),
			"results":      searchResults,
		},
		Source:  "contextual-memory-manager",
		Version: "1.0.0",
	}

	return w.sendWebhookNotifications(ctx, payload)
}

// GetIntegrationStatus returns the status of all integrations
func (w *WebhookIntegrationManager) GetIntegrationStatus(ctx context.Context) (map[string]interface{}, error) {
	if !w.initialized {
		return nil, fmt.Errorf("integration manager not initialized")
	}

	status := make(map[string]interface{})

	// Test each webhook
	webhookStatuses := make(map[string]interface{})
	for name, config := range w.webhooks {
		webhookStatus := map[string]interface{}{
			"url":     config.URL,
			"enabled": config.Enabled,
			"method":  config.Method,
		}

		// Test webhook health
		if config.Enabled {
			healthStatus, err := w.testWebhookHealth(ctx, name, config)
			if err != nil {
				webhookStatus["health"] = "unhealthy"
				webhookStatus["error"] = err.Error()
			} else {
				webhookStatus["health"] = "healthy"
				webhookStatus["response"] = healthStatus
			}
		} else {
			webhookStatus["health"] = "disabled"
		}

		webhookStatuses[name] = webhookStatus
	}

	status["webhooks"] = webhookStatuses
	status["total_webhooks"] = len(w.webhooks)
	status["enabled_webhooks"] = w.countEnabledWebhooks()
	status["initialized"] = w.initialized
	status["last_checked"] = time.Now().UTC()

	return status, nil
}

// Close closes the integration manager
func (w *WebhookIntegrationManager) Close() error {
	log.Println("Closing Webhook IntegrationManager...")

	// Close HTTP client
	if w.httpClient != nil {
		w.httpClient.CloseIdleConnections()
	}

	w.initialized = false
	log.Println("Webhook IntegrationManager closed successfully")
	return nil
}

// Helper methods

func (w *WebhookIntegrationManager) parseWebhookConfigs() error {
	// Check if webhooks config exists
	webhooksData, exists := w.config["webhooks"]
	if !exists {
		log.Println("No webhooks configuration found")
		return nil
	}

	// Convert to map[string]interface{}
	webhooksMap, ok := webhooksData.(map[string]interface{})
	if !ok {
		return fmt.Errorf("webhooks configuration is not a valid map")
	}

	for name, webhookData := range webhooksMap {
		var config WebhookConfig

		// Convert interface{} to WebhookConfig
		jsonData, err := json.Marshal(webhookData)
		if err != nil {
			return fmt.Errorf("failed to marshal webhook config for %s: %w", name, err)
		}

		if err := json.Unmarshal(jsonData, &config); err != nil {
			return fmt.Errorf("failed to unmarshal webhook config for %s: %w", name, err)
		}

		// Set defaults
		if config.Method == "" {
			config.Method = "POST"
		}
		if config.Timeout == 0 {
			config.Timeout = 30 * time.Second
		}
		if config.RetryCount == 0 {
			config.RetryCount = 3
		}
		if config.Headers == nil {
			config.Headers = make(map[string]string)
		}

		// Set default headers
		if config.Headers["Content-Type"] == "" {
			config.Headers["Content-Type"] = "application/json"
		}

		w.webhooks[name] = config
		log.Printf("Parsed webhook config: %s -> %s", name, config.URL)
	}

	return nil
}

func (w *WebhookIntegrationManager) testWebhookEndpoints(ctx context.Context) error {
	for name, config := range w.webhooks {
		if !config.Enabled {
			continue
		}

		log.Printf("Testing webhook endpoint: %s", name)

		_, err := w.testWebhookHealth(ctx, name, config)
		if err != nil {
			log.Printf("Warning: webhook %s failed health check: %v", name, err)
		} else {
			log.Printf("Webhook %s health check passed", name)
		}
	}

	return nil
}

func (w *WebhookIntegrationManager) testWebhookHealth(ctx context.Context, name string, config WebhookConfig) (WebhookResponse, error) {
	// Create health check payload
	payload := WebhookPayload{
		Event:     "health.check",
		Timestamp: time.Now().UTC(),
		Data: map[string]interface{}{
			"webhook_name": name,
		},
		Source:  "contextual-memory-manager",
		Version: "1.0.0",
	}

	return w.sendWebhook(ctx, config, payload)
}

func (w *WebhookIntegrationManager) sendWebhookNotifications(ctx context.Context, payload WebhookPayload) error {
	var lastError error
	successCount := 0

	for name, config := range w.webhooks {
		if !config.Enabled {
			continue
		}

		log.Printf("Sending webhook notification to %s", name)

		response, err := w.sendWebhook(ctx, config, payload)
		if err != nil {
			log.Printf("Failed to send webhook to %s: %v", name, err)
			lastError = err
		} else {
			log.Printf("Webhook sent successfully to %s (status: %d, duration: %v)",
				name, response.StatusCode, response.Duration)
			successCount++
		}
	}

	if successCount == 0 && lastError != nil {
		return fmt.Errorf("all webhook notifications failed, last error: %w", lastError)
	}

	log.Printf("Webhook notifications sent: %d/%d successful", successCount, w.countEnabledWebhooks())
	return nil
}

func (w *WebhookIntegrationManager) sendWebhook(ctx context.Context, config WebhookConfig, payload WebhookPayload) (WebhookResponse, error) {
	var response WebhookResponse
	startTime := time.Now()

	// Marshal payload
	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return response, fmt.Errorf("failed to marshal payload: %w", err)
	}

	// Create request with retry logic
	var lastErr error
	for attempt := 0; attempt < config.RetryCount; attempt++ {
		if attempt > 0 {
			// Wait before retry
			select {
			case <-ctx.Done():
				return response, ctx.Err()
			case <-time.After(time.Duration(attempt) * time.Second):
			}
		}

		// Create HTTP request
		req, err := http.NewRequestWithContext(ctx, config.Method, config.URL, bytes.NewBuffer(jsonPayload))
		if err != nil {
			lastErr = fmt.Errorf("failed to create request: %w", err)
			continue
		}

		// Set headers
		for key, value := range config.Headers {
			req.Header.Set(key, value)
		}

		// Create client with timeout
		client := &http.Client{
			Timeout: config.Timeout,
		}

		// Send request
		resp, err := client.Do(req)
		if err != nil {
			lastErr = fmt.Errorf("failed to send request: %w", err)
			continue
		}

		// Read response body
		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			lastErr = fmt.Errorf("failed to read response body: %w", err)
			continue
		}

		// Build response
		response = WebhookResponse{
			StatusCode: resp.StatusCode,
			Body:       string(body),
			Headers:    resp.Header,
			Duration:   time.Since(startTime),
		}

		// Check if successful
		if resp.StatusCode >= 200 && resp.StatusCode < 300 {
			return response, nil
		}

		lastErr = fmt.Errorf("webhook returned status %d: %s", resp.StatusCode, string(body))
	}

	response.Error = lastErr.Error()
	response.Duration = time.Since(startTime)
	return response, lastErr
}

func (w *WebhookIntegrationManager) countEnabledWebhooks() int {
	count := 0
	for _, config := range w.webhooks {
		if config.Enabled {
			count++
		}
	}
	return count
}

// Advanced webhook features

// SendCustomEvent sends a custom event to webhooks
func (w *WebhookIntegrationManager) SendCustomEvent(ctx context.Context, event string, data map[string]interface{}) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Sending custom event: %s", event)

	payload := WebhookPayload{
		Event:     event,
		Timestamp: time.Now().UTC(),
		Data:      data,
		Source:    "contextual-memory-manager",
		Version:   "1.0.0",
	}

	return w.sendWebhookNotifications(ctx, payload)
}

// UpdateWebhookConfig updates configuration for a specific webhook
func (w *WebhookIntegrationManager) UpdateWebhookConfig(name string, config WebhookConfig) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Updating webhook config: %s", name)

	w.webhooks[name] = config
	return nil
}

// RemoveWebhook removes a webhook configuration
func (w *WebhookIntegrationManager) RemoveWebhook(name string) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Removing webhook: %s", name)

	delete(w.webhooks, name)
	return nil
}

// GetWebhookLogs returns recent webhook activity logs (mock implementation)
func (w *WebhookIntegrationManager) GetWebhookLogs(ctx context.Context, limit int) ([]map[string]interface{}, error) {
	if !w.initialized {
		return nil, fmt.Errorf("integration manager not initialized")
	}

	// Mock webhook logs (in real implementation, store in database)
	logs := []map[string]interface{}{
		{
			"timestamp":   time.Now().UTC(),
			"event":       "document.added",
			"webhook":     "example-webhook",
			"status_code": 200,
			"duration_ms": 150,
		},
		{
			"timestamp":   time.Now().UTC().Add(-5 * time.Minute),
			"event":       "search.performed",
			"webhook":     "analytics-webhook",
			"status_code": 201,
			"duration_ms": 85,
		},
	}

	if len(logs) > limit {
		logs = logs[:limit]
	}

	log.Printf("Webhook logs retrieved: %d entries", len(logs))
	return logs, nil
}

// RegisterWebhook registers a webhook for document updates
func (w *WebhookIntegrationManager) RegisterWebhook(ctx context.Context, url string, events []string) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Registering webhook: %s for events: %v", url, events)

	// Create webhook config
	config := WebhookConfig{
		URL:        url,
		Method:     "POST",
		Headers:    map[string]string{"Content-Type": "application/json"},
		Timeout:    30 * time.Second,
		RetryCount: 3,
		Enabled:    true,
	}

	// Generate a name for the webhook
	name := fmt.Sprintf("webhook_%d", len(w.webhooks)+1)
	w.webhooks[name] = config

	log.Printf("Webhook registered successfully: %s", name)
	return nil
}

// UnregisterWebhook removes a webhook
func (w *WebhookIntegrationManager) UnregisterWebhook(ctx context.Context, url string) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Unregistering webhook: %s", url)

	// Find and remove webhook by URL
	for name, config := range w.webhooks {
		if config.URL == url {
			delete(w.webhooks, name)
			log.Printf("Webhook unregistered successfully: %s", name)
			return nil
		}
	}

	return fmt.Errorf("webhook not found: %s", url)
}

// NotifyUpdate sends notifications about document updates
func (w *WebhookIntegrationManager) NotifyUpdate(ctx context.Context, event interfaces.UpdateEvent) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Notifying update event: %s for document: %s", event.Type, event.DocumentID)

	payload := WebhookPayload{
		Event:     "document." + event.Type,
		Timestamp: event.Timestamp,
		Data: map[string]interface{}{
			"document_id": event.DocumentID,
			"type":        event.Type,
			"metadata":    event.Metadata,
		},
		Source:  "contextual-memory-manager",
		Version: "1.0.0",
	}

	return w.sendWebhookNotifications(ctx, payload)
}

// ExportDocuments exports documents in various formats
func (w *WebhookIntegrationManager) ExportDocuments(ctx context.Context, format string, filters map[string]string) ([]byte, error) {
	if !w.initialized {
		return nil, fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Exporting documents in format: %s with filters: %v", format, filters)

	// Mock export implementation
	export := map[string]interface{}{
		"format":    format,
		"filters":   filters,
		"timestamp": time.Now().UTC(),
		"documents": []map[string]interface{}{
			{
				"id":      "doc1",
				"content": "Sample document content",
				"metadata": map[string]string{
					"type": "text",
				},
			},
		},
	}

	data, err := json.Marshal(export)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal export data: %w", err)
	}

	log.Printf("Documents exported successfully: %d bytes", len(data))
	return data, nil
}

// ImportDocuments imports documents from external sources
func (w *WebhookIntegrationManager) ImportDocuments(ctx context.Context, source string, config map[string]interface{}) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Importing documents from source: %s with config: %v", source, config)

	// Mock import implementation
	log.Printf("Mock import: processing documents from %s", source)

	// Simulate importing documents
	importedCount := 0

	// In real implementation, this would:
	// 1. Connect to the external source
	// 2. Fetch documents based on config
	// 3. Process and store them
	// 4. Send notifications

	log.Printf("Documents imported successfully: %d documents from %s", importedCount, source)
	return nil
}

// SyncWithExternal synchronizes with external data sources
func (w *WebhookIntegrationManager) SyncWithExternal(ctx context.Context, source string) error {
	if !w.initialized {
		return fmt.Errorf("integration manager not initialized")
	}

	log.Printf("Synchronizing with external source: %s", source)

	// Mock sync implementation
	log.Printf("Mock sync: checking for updates from %s", source)

	// In real implementation, this would:
	// 1. Connect to the external source
	// 2. Check for new/updated/deleted documents
	// 3. Apply changes to local store
	// 4. Send notifications

	log.Printf("Synchronization completed with %s", source)
	return nil
}
