package webhook

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"EMAIL_SENDER_1/managers/interfaces"
)

// WebhookConfig represents webhook configuration
type WebhookConfig struct {
	URL     string            `json:"url"`
	Events  []string          `json:"events"`
	Secret  string            `json:"secret"`
	Headers map[string]string `json:"headers"`
	Timeout time.Duration     `json:"timeout"`
	Retries int               `json:"retries"`
	Enabled bool              `json:"enabled"`
}

// Manager handles webhook operations
type Manager struct {
	config       map[string]interface{}
	webhooks     map[string]*WebhookConfig
	client       *http.Client
	errorManager interfaces.ErrorManager
}

// NewManager creates a new webhook manager
func NewManager(config map[string]interface{}, errorManager interfaces.ErrorManager) (*Manager, error) {
	if errorManager == nil {
		return nil, fmt.Errorf("error manager is required")
	}

	if config == nil {
		config = make(map[string]interface{})
	}

	// Create HTTP client with timeout
	timeout := 30 * time.Second
	if t, ok := config["timeout"].(time.Duration); ok {
		timeout = t
	}

	client := &http.Client{
		Timeout: timeout,
	}

	manager := &Manager{
		config:       config,
		webhooks:     make(map[string]*WebhookConfig),
		client:       client,
		errorManager: errorManager,
	}

	// Load existing webhooks from config
	if err := manager.loadWebhooksFromConfig(); err != nil {
		log.Printf("Warning: failed to load webhooks from config: %v", err)
	}

	log.Printf("Webhook manager initialized")
	return manager, nil
}

// loadWebhooksFromConfig loads webhook configurations from the config
func (m *Manager) loadWebhooksFromConfig() error {
	webhooksConfig, ok := m.config["webhooks"].(map[string]interface{})
	if !ok {
		return nil // No webhooks configured
	}

	for name, configData := range webhooksConfig {
		configMap, ok := configData.(map[string]interface{})
		if !ok {
			continue
		}

		webhook := &WebhookConfig{
			Enabled: true,
			Timeout: 30 * time.Second,
			Retries: 3,
			Headers: make(map[string]string),
		}

		if url, ok := configMap["url"].(string); ok {
			webhook.URL = url
		}

		if events, ok := configMap["events"].([]interface{}); ok {
			for _, event := range events {
				if eventStr, ok := event.(string); ok {
					webhook.Events = append(webhook.Events, eventStr)
				}
			}
		}

		if secret, ok := configMap["secret"].(string); ok {
			webhook.Secret = secret
		}

		if enabled, ok := configMap["enabled"].(bool); ok {
			webhook.Enabled = enabled
		}

		if headers, ok := configMap["headers"].(map[string]interface{}); ok {
			for k, v := range headers {
				if str, ok := v.(string); ok {
					webhook.Headers[k] = str
				}
			}
		}

		m.webhooks[name] = webhook
		log.Printf("Loaded webhook configuration: %s", name)
	}

	return nil
}

// SendWebhook sends a webhook payload to configured endpoints
func (m *Manager) SendWebhook(ctx context.Context, event string, payload *interfaces.WebhookPayload) error {
	if event == "" {
		return fmt.Errorf("event cannot be empty")
	}

	if payload == nil {
		payload = &interfaces.WebhookPayload{
			Event:     event,
			Timestamp: time.Now(),
			Data:      make(map[string]interface{}),
			Metadata:  make(map[string]string),
		}
	}

	// Set event and timestamp if not already set
	if payload.Event == "" {
		payload.Event = event
	}
	if payload.Timestamp.IsZero() {
		payload.Timestamp = time.Now()
	}

	var errors []string
	successCount := 0

	// Send to all configured webhooks that are interested in this event
	for name, webhook := range m.webhooks {
		if !webhook.Enabled {
			continue
		}

		// Check if this webhook is interested in this event
		if !m.isEventEnabled(webhook, event) {
			continue
		}

		if err := m.sendToWebhook(ctx, name, webhook, payload); err != nil {
			errors = append(errors, fmt.Sprintf("%s: %v", name, err))
		} else {
			successCount++
		}
	}

	log.Printf("Sent webhook for event '%s' to %d endpoints", event, successCount)

	if len(errors) > 0 {
		return fmt.Errorf("webhook delivery failures: %s", strings.Join(errors, "; "))
	}

	return nil
}

// sendToWebhook sends payload to a specific webhook
func (m *Manager) sendToWebhook(ctx context.Context, name string, webhook *WebhookConfig, payload *interfaces.WebhookPayload) error {
	if webhook.URL == "" {
		return fmt.Errorf("webhook URL not configured")
	}

	// Marshal payload to JSON
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	// Create request
	req, err := http.NewRequestWithContext(ctx, "POST", webhook.URL, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "GitWorkflowManager/1.0")

	// Add custom headers
	for key, value := range webhook.Headers {
		req.Header.Set(key, value)
	}

	// Add signature if secret is configured
	if webhook.Secret != "" {
		signature := m.generateSignature(jsonData, webhook.Secret)
		req.Header.Set("X-Hub-Signature-256", signature)
	}

	// Send with retries
	return m.sendWithRetries(req, webhook.Retries)
}

// sendWithRetries sends HTTP request with retry logic
func (m *Manager) sendWithRetries(req *http.Request, maxRetries int) error {
	var lastErr error

	for attempt := 0; attempt <= maxRetries; attempt++ {
		if attempt > 0 {
			// Exponential backoff
			backoff := time.Duration(attempt*attempt) * time.Second
			time.Sleep(backoff)
			log.Printf("Retrying webhook request (attempt %d/%d)", attempt+1, maxRetries+1)
		}

		resp, err := m.client.Do(req)
		if err != nil {
			lastErr = err
			continue
		}

		// Read response body for logging
		body, _ := io.ReadAll(resp.Body)
		resp.Body.Close()

		if resp.StatusCode >= 200 && resp.StatusCode < 300 {
			log.Printf("Webhook delivered successfully to %s (status: %d)", req.URL.String(), resp.StatusCode)
			return nil
		}

		lastErr = fmt.Errorf("webhook returned status %d: %s", resp.StatusCode, string(body))
	}

	return fmt.Errorf("webhook delivery failed after %d attempts: %w", maxRetries+1, lastErr)
}

// generateSignature generates HMAC-SHA256 signature for webhook payload
func (m *Manager) generateSignature(payload []byte, secret string) string {
	h := hmac.New(sha256.New, []byte(secret))
	h.Write(payload)
	return "sha256=" + hex.EncodeToString(h.Sum(nil))
}

// isEventEnabled checks if a webhook is configured to receive a specific event
func (m *Manager) isEventEnabled(webhook *WebhookConfig, event string) bool {
	if len(webhook.Events) == 0 {
		return true // No specific events configured, send all
	}

	for _, configuredEvent := range webhook.Events {
		if configuredEvent == event || configuredEvent == "*" {
			return true
		}
	}

	return false
}

// ConfigureWebhook adds or updates a webhook configuration
func (m *Manager) ConfigureWebhook(ctx context.Context, url string, events []string, secret string) error {
	if url == "" {
		return fmt.Errorf("webhook URL cannot be empty")
	}

	// Generate webhook name from URL
	name := m.generateWebhookName(url)

	webhook := &WebhookConfig{
		URL:     url,
		Events:  events,
		Secret:  secret,
		Enabled: true,
		Timeout: 30 * time.Second,
		Retries: 3,
		Headers: make(map[string]string),
	}

	m.webhooks[name] = webhook

	log.Printf("Configured webhook: %s -> %s", name, url)
	return nil
}

// generateWebhookName generates a unique name for a webhook based on its URL
func (m *Manager) generateWebhookName(url string) string {
	// Simple name generation - in practice you might want something more sophisticated
	parts := strings.Split(url, "/")
	if len(parts) > 2 {
		return fmt.Sprintf("webhook_%s_%d", parts[2], time.Now().Unix())
	}
	return fmt.Sprintf("webhook_%d", time.Now().Unix())
}

// ListWebhooks returns all configured webhooks
func (m *Manager) ListWebhooks(ctx context.Context) ([]map[string]interface{}, error) {
	var webhooks []map[string]interface{}

	for name, webhook := range m.webhooks {
		webhookInfo := map[string]interface{}{
			"name":    name,
			"url":     webhook.URL,
			"events":  webhook.Events,
			"enabled": webhook.Enabled,
			"timeout": webhook.Timeout.String(),
			"retries": webhook.Retries,
		}

		// Don't expose the secret
		if webhook.Secret != "" {
			webhookInfo["has_secret"] = true
		} else {
			webhookInfo["has_secret"] = false
		}

		webhooks = append(webhooks, webhookInfo)
	}

	return webhooks, nil
}

// UpdateWebhook updates an existing webhook configuration
func (m *Manager) UpdateWebhook(ctx context.Context, name string, updates map[string]interface{}) error {
	webhook, exists := m.webhooks[name]
	if !exists {
		return fmt.Errorf("webhook %s not found", name)
	}

	// Apply updates
	if url, ok := updates["url"].(string); ok {
		webhook.URL = url
	}

	if events, ok := updates["events"].([]string); ok {
		webhook.Events = events
	}

	if secret, ok := updates["secret"].(string); ok {
		webhook.Secret = secret
	}

	if enabled, ok := updates["enabled"].(bool); ok {
		webhook.Enabled = enabled
	}

	if timeout, ok := updates["timeout"].(time.Duration); ok {
		webhook.Timeout = timeout
	}

	if retries, ok := updates["retries"].(int); ok {
		webhook.Retries = retries
	}

	log.Printf("Updated webhook configuration: %s", name)
	return nil
}

// DeleteWebhook removes a webhook configuration
func (m *Manager) DeleteWebhook(ctx context.Context, name string) error {
	if _, exists := m.webhooks[name]; !exists {
		return fmt.Errorf("webhook %s not found", name)
	}

	delete(m.webhooks, name)
	log.Printf("Deleted webhook: %s", name)
	return nil
}

// TestWebhook sends a test payload to a specific webhook
func (m *Manager) TestWebhook(ctx context.Context, name string) error {
	webhook, exists := m.webhooks[name]
	if !exists {
		return fmt.Errorf("webhook %s not found", name)
	}

	testPayload := &interfaces.WebhookPayload{
		Event:     "test",
		Timestamp: time.Now(),
		Data: map[string]interface{}{
			"message": "This is a test webhook payload",
			"test":    true,
		},
		Metadata: map[string]string{
			"webhook_name": name,
			"source":       "GitWorkflowManager",
		},
	}

	err := m.sendToWebhook(ctx, name, webhook, testPayload)
	if err != nil {
		return fmt.Errorf("webhook test failed: %w", err)
	}

	log.Printf("Test webhook sent successfully to: %s", name)
	return nil
}

// EnableWebhook enables a webhook
func (m *Manager) EnableWebhook(ctx context.Context, name string) error {
	webhook, exists := m.webhooks[name]
	if !exists {
		return fmt.Errorf("webhook %s not found", name)
	}

	webhook.Enabled = true
	log.Printf("Enabled webhook: %s", name)
	return nil
}

// DisableWebhook disables a webhook
func (m *Manager) DisableWebhook(ctx context.Context, name string) error {
	webhook, exists := m.webhooks[name]
	if !exists {
		return fmt.Errorf("webhook %s not found", name)
	}

	webhook.Enabled = false
	log.Printf("Disabled webhook: %s", name)
	return nil
}

// GetWebhookStats returns statistics about webhook deliveries
func (m *Manager) GetWebhookStats(ctx context.Context) (map[string]interface{}, error) {
	stats := map[string]interface{}{
		"total_webhooks":    len(m.webhooks),
		"enabled_webhooks":  0,
		"disabled_webhooks": 0,
	}

	for _, webhook := range m.webhooks {
		if webhook.Enabled {
			stats["enabled_webhooks"] = stats["enabled_webhooks"].(int) + 1
		} else {
			stats["disabled_webhooks"] = stats["disabled_webhooks"].(int) + 1
		}
	}

	return stats, nil
}

// Health checks the health of the webhook manager
func (m *Manager) Health() error {
	// Basic health check - ensure we can create HTTP requests
	_, err := http.NewRequest("GET", "http://example.com", nil)
	if err != nil {
		return fmt.Errorf("webhook manager health check failed: %w", err)
	}

	return nil
}

// Shutdown gracefully shuts down the webhook manager
func (m *Manager) Shutdown(ctx context.Context) error {
	// Close HTTP client if needed
	if m.client != nil {
		m.client.CloseIdleConnections()
	}

	log.Printf("Webhook manager shutdown completed")
	return nil
}
