package integration_manager

import (
	"EMAIL_SENDER_1/development/managers/interfaces"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"sort"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

// RegisterWebhook registers a new webhook
func (im *IntegrationManagerImpl) RegisterWebhook(webhook *interfaces.Webhook) error {
	im.webhookMutex.Lock()
	defer im.webhookMutex.Unlock()

	im.logger.WithFields(logrus.Fields{
		"webhook_id": webhook.ID,
		"url":        webhook.URL,
		"events":     webhook.Events,
	}).Info("Registering webhook")

	// Validate webhook
	if err := im.validateWebhook(webhook); err != nil {
		im.logger.WithError(err).Error("Webhook validation failed")
		return fmt.Errorf("webhook validation failed: %w", err)
	}

	// Set webhook metadata
	webhook.CreatedAt = time.Now()
	webhook.UpdatedAt = time.Now()
	webhook.Status = "active"

	// Generate or validate secret
	if webhook.Secret == "" {
		webhook.Secret = im.generateWebhookSecret()
	}

	// Store webhook
	im.webhooks[webhook.ID] = webhook

	// Initialize webhook logs
	if im.webhookLogs[webhook.ID] == nil {
		im.webhookLogs[webhook.ID] = make([]*interfaces.WebhookLog, 0, 1000)
	}

	// Log registration event
	im.logWebhookEvent(webhook.ID, "webhook_registered", map[string]interface{}{
		"url":           webhook.URL,
		"events":        webhook.Events,
		"content_type":  webhook.ContentType,
		"timeout":       webhook.Timeout,
		"max_retries":   webhook.MaxRetries,
		"retry_backoff": webhook.RetryBackoff,
	})

	im.logger.WithField("webhook_id", webhook.ID).Info("Webhook registered successfully")
	return nil
}

// HandleWebhook processes incoming webhook requests
func (im *IntegrationManagerImpl) HandleWebhook(webhookID string, request *http.Request) error {
	im.webhookMutex.RLock()
	webhook, exists := im.webhooks[webhookID]
	im.webhookMutex.RUnlock()

	if !exists {
		return fmt.Errorf("webhook not found: %s", webhookID)
	}

	startTime := time.Now()
	im.logger.WithFields(logrus.Fields{
		"webhook_id": webhookID,
		"method":     request.Method,
		"url":        request.URL.String(),
		"user_agent": request.Header.Get("User-Agent"),
	}).Info("Handling webhook request")

	// Read request body
	body, err := io.ReadAll(request.Body)
	if err != nil {
		im.logWebhookEvent(webhookID, "request_read_error", map[string]interface{}{
			"error": err.Error(),
		})
		return fmt.Errorf("failed to read request body: %w", err)
	}

	// Verify webhook signature if secret is configured
	if webhook.Secret != "" {
		if err := im.verifyWebhookSignature(webhook, request, body); err != nil {
			im.logWebhookEvent(webhookID, "signature_verification_failed", map[string]interface{}{
				"error": err.Error(),
			})
			return fmt.Errorf("signature verification failed: %w", err)
		}
	}

	// Parse payload
	var payload map[string]interface{}
	if len(body) > 0 {
		if err := json.Unmarshal(body, &payload); err != nil {
			im.logWebhookEvent(webhookID, "payload_parse_error", map[string]interface{}{
				"error": err.Error(),
				"body":  string(body),
			})
			return fmt.Errorf("failed to parse JSON payload: %w", err)
		}
	}

	// Extract event type
	eventType := im.extractEventType(payload, request)

	// Check if webhook is configured for this event
	if !im.isEventAllowed(webhook, eventType) {
		im.logWebhookEvent(webhookID, "event_not_allowed", map[string]interface{}{
			"event_type":     eventType,
			"allowed_events": webhook.Events,
		})
		return fmt.Errorf("event type '%s' not allowed for webhook", eventType)
	}

	// Process webhook
	processingTime := time.Since(startTime)
	err = im.processWebhookPayload(webhook, eventType, payload, request)

	// Log webhook execution
	im.logWebhookExecution(webhookID, eventType, payload, request, err, processingTime)

	if err != nil {
		im.logger.WithError(err).WithField("webhook_id", webhookID).Error("Webhook processing failed")
		return fmt.Errorf("webhook processing failed: %w", err)
	}

	im.logger.WithFields(logrus.Fields{
		"webhook_id":      webhookID,
		"event_type":      eventType,
		"processing_time": processingTime,
	}).Info("Webhook processed successfully")

	return nil
}

// GetWebhookLogs retrieves webhook execution logs
func (im *IntegrationManagerImpl) GetWebhookLogs(webhookID string, limit int) ([]*interfaces.WebhookLog, error) {
	im.webhookMutex.RLock()
	defer im.webhookMutex.RUnlock()

	logs, exists := im.webhookLogs[webhookID]
	if !exists {
		return []*interfaces.WebhookLog{}, nil
	}

	// Sort logs by timestamp (newest first)
	sortedLogs := make([]*interfaces.WebhookLog, len(logs))
	copy(sortedLogs, logs)
	sort.Slice(sortedLogs, func(i, j int) bool {
		return sortedLogs[i].Timestamp.After(sortedLogs[j].Timestamp)
	})

	// Apply limit
	if limit > 0 && len(sortedLogs) > limit {
		sortedLogs = sortedLogs[:limit]
	}

	return sortedLogs, nil
}

// validateWebhook validates webhook configuration
func (im *IntegrationManagerImpl) validateWebhook(webhook *interfaces.Webhook) error {
	if webhook.ID == "" {
		return fmt.Errorf("webhook ID is required")
	}

	if webhook.URL == "" {
		return fmt.Errorf("webhook URL is required")
	}

	if !strings.HasPrefix(webhook.URL, "http://") && !strings.HasPrefix(webhook.URL, "https://") {
		return fmt.Errorf("webhook URL must be a valid HTTP/HTTPS URL")
	}

	if len(webhook.Events) == 0 {
		return fmt.Errorf("at least one event must be specified")
	}

	// Validate event types
	validEvents := map[string]bool{
		"integration.created": true,
		"integration.updated": true,
		"integration.deleted": true,
		"sync.started":        true,
		"sync.completed":      true,
		"sync.failed":         true,
		"api.called":          true,
		"api.failed":          true,
		"data.transformed":    true,
		"webhook.triggered":   true,
		"*":                   true, // Allow all events
	}

	for _, event := range webhook.Events {
		if !validEvents[event] {
			return fmt.Errorf("invalid event type: %s", event)
		}
	}

	// Set defaults
	if webhook.ContentType == "" {
		webhook.ContentType = "application/json"
	}

	if webhook.Timeout == 0 {
		webhook.Timeout = 30 * time.Second
	}

	if webhook.MaxRetries == 0 {
		webhook.MaxRetries = 3
	}

	if webhook.RetryBackoff == 0 {
		webhook.RetryBackoff = 2 * time.Second
	}

	return nil
}

// generateWebhookSecret generates a secure webhook secret
func (im *IntegrationManagerImpl) generateWebhookSecret() string {
	// Generate a random secret (in production, use crypto/rand)
	return fmt.Sprintf("webhook_secret_%d", time.Now().UnixNano())
}

// verifyWebhookSignature verifies webhook signature
func (im *IntegrationManagerImpl) verifyWebhookSignature(webhook *interfaces.Webhook, request *http.Request, body []byte) error {
	signature := request.Header.Get("X-Hub-Signature-256")
	if signature == "" {
		signature = request.Header.Get("X-Signature-256")
	}
	if signature == "" {
		return fmt.Errorf("missing webhook signature")
	}

	// Remove "sha256=" prefix if present
	signature = strings.TrimPrefix(signature, "sha256=")

	// Calculate expected signature
	mac := hmac.New(sha256.New, []byte(webhook.Secret))
	mac.Write(body)
	expectedSignature := hex.EncodeToString(mac.Sum(nil))

	// Compare signatures
	if !hmac.Equal([]byte(signature), []byte(expectedSignature)) {
		return fmt.Errorf("signature mismatch")
	}

	return nil
}

// extractEventType extracts event type from payload or headers
func (im *IntegrationManagerImpl) extractEventType(payload map[string]interface{}, request *http.Request) string {
	// Try to get event type from headers first
	if eventType := request.Header.Get("X-Event-Type"); eventType != "" {
		return eventType
	}
	if eventType := request.Header.Get("X-GitHub-Event"); eventType != "" {
		return "github." + eventType
	}
	if eventType := request.Header.Get("X-GitLab-Event"); eventType != "" {
		return "gitlab." + eventType
	}

	// Try to extract from payload
	if payload != nil {
		if eventType, ok := payload["event_type"].(string); ok {
			return eventType
		}
		if eventType, ok := payload["type"].(string); ok {
			return eventType
		}
		if action, ok := payload["action"].(string); ok {
			return action
		}
	}

	// Default event type
	return "webhook.received"
}

// isEventAllowed checks if webhook is configured for the event
func (im *IntegrationManagerImpl) isEventAllowed(webhook *interfaces.Webhook, eventType string) bool {
	for _, allowedEvent := range webhook.Events {
		if allowedEvent == "*" || allowedEvent == eventType {
			return true
		}
		// Support wildcard matching (e.g., "github.*")
		if strings.HasSuffix(allowedEvent, "*") {
			prefix := strings.TrimSuffix(allowedEvent, "*")
			if strings.HasPrefix(eventType, prefix) {
				return true
			}
		}
	}
	return false
}

// processWebhookPayload processes the webhook payload
func (im *IntegrationManagerImpl) processWebhookPayload(webhook *interfaces.Webhook, eventType string, payload map[string]interface{}, request *http.Request) error {
	// Create processing context
	context := map[string]interface{}{
		"webhook_id": webhook.ID,
		"event_type": eventType,
		"payload":    payload,
		"headers":    im.extractHeaders(request),
		"timestamp":  time.Now(),
		"source_ip":  im.extractSourceIP(request),
	}

	// Process based on event type
	switch {
	case strings.HasPrefix(eventType, "integration."):
		return im.processIntegrationEvent(webhook, eventType, context)
	case strings.HasPrefix(eventType, "sync."):
		return im.processSyncEvent(webhook, eventType, context)
	case strings.HasPrefix(eventType, "api."):
		return im.processAPIEvent(webhook, eventType, context)
	case strings.HasPrefix(eventType, "github."):
		return im.processGitHubEvent(webhook, eventType, context)
	case strings.HasPrefix(eventType, "gitlab."):
		return im.processGitLabEvent(webhook, eventType, context)
	default:
		return im.processGenericEvent(webhook, eventType, context)
	}
}

// processIntegrationEvent processes integration-related events
func (im *IntegrationManagerImpl) processIntegrationEvent(webhook *interfaces.Webhook, eventType string, context map[string]interface{}) error {
	im.logger.WithFields(logrus.Fields{
		"webhook_id": webhook.ID,
		"event_type": eventType,
	}).Info("Processing integration event")

	// Extract integration data from context
	payload, ok := context["payload"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("invalid payload format")
	}

	integrationID, _ := payload["integration_id"].(string)

	switch eventType {
	case "integration.created":
		// Handle integration creation
		im.logger.WithField("integration_id", integrationID).Info("Integration created via webhook")
	case "integration.updated":
		// Handle integration update
		im.logger.WithField("integration_id", integrationID).Info("Integration updated via webhook")
	case "integration.deleted":
		// Handle integration deletion
		im.logger.WithField("integration_id", integrationID).Info("Integration deleted via webhook")
	}

	return nil
}

// processSyncEvent processes sync-related events
func (im *IntegrationManagerImpl) processSyncEvent(webhook *interfaces.Webhook, eventType string, context map[string]interface{}) error {
	im.logger.WithFields(logrus.Fields{
		"webhook_id": webhook.ID,
		"event_type": eventType,
	}).Info("Processing sync event")

	payload, ok := context["payload"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("invalid payload format")
	}

	syncJobID, _ := payload["sync_job_id"].(string)

	switch eventType {
	case "sync.started":
		im.logger.WithField("sync_job_id", syncJobID).Info("Sync started via webhook")
	case "sync.completed":
		im.logger.WithField("sync_job_id", syncJobID).Info("Sync completed via webhook")
	case "sync.failed":
		im.logger.WithField("sync_job_id", syncJobID).Error("Sync failed via webhook")
	}

	return nil
}

// processAPIEvent processes API-related events
func (im *IntegrationManagerImpl) processAPIEvent(webhook *interfaces.Webhook, eventType string, context map[string]interface{}) error {
	im.logger.WithFields(logrus.Fields{
		"webhook_id": webhook.ID,
		"event_type": eventType,
	}).Info("Processing API event")

	payload, ok := context["payload"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("invalid payload format")
	}

	apiID, _ := payload["api_id"].(string)
	endpoint, _ := payload["endpoint"].(string)

	switch eventType {
	case "api.called":
		im.logger.WithFields(logrus.Fields{
			"api_id":   apiID,
			"endpoint": endpoint,
		}).Info("API called via webhook")
	case "api.failed":
		im.logger.WithFields(logrus.Fields{
			"api_id":   apiID,
			"endpoint": endpoint,
		}).Error("API call failed via webhook")
	}

	return nil
}

// processGitHubEvent processes GitHub webhook events
func (im *IntegrationManagerImpl) processGitHubEvent(webhook *interfaces.Webhook, eventType string, context map[string]interface{}) error {
	im.logger.WithFields(logrus.Fields{
		"webhook_id": webhook.ID,
		"event_type": eventType,
	}).Info("Processing GitHub event")

	payload, ok := context["payload"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("invalid payload format")
	}

	// Extract common GitHub fields
	repository := ""
	if repo, ok := payload["repository"].(map[string]interface{}); ok {
		if fullName, ok := repo["full_name"].(string); ok {
			repository = fullName
		}
	}

	action, _ := payload["action"].(string)

	im.logger.WithFields(logrus.Fields{
		"repository": repository,
		"action":     action,
	}).Info("GitHub webhook processed")

	return nil
}

// processGitLabEvent processes GitLab webhook events
func (im *IntegrationManagerImpl) processGitLabEvent(webhook *interfaces.Webhook, eventType string, context map[string]interface{}) error {
	im.logger.WithFields(logrus.Fields{
		"webhook_id": webhook.ID,
		"event_type": eventType,
	}).Info("Processing GitLab event")

	payload, ok := context["payload"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("invalid payload format")
	}

	// Extract common GitLab fields
	project := ""
	if proj, ok := payload["project"].(map[string]interface{}); ok {
		if pathWithNamespace, ok := proj["path_with_namespace"].(string); ok {
			project = pathWithNamespace
		}
	}

	objectKind, _ := payload["object_kind"].(string)

	im.logger.WithFields(logrus.Fields{
		"project":     project,
		"object_kind": objectKind,
	}).Info("GitLab webhook processed")

	return nil
}

// processGenericEvent processes generic webhook events
func (im *IntegrationManagerImpl) processGenericEvent(webhook *interfaces.Webhook, eventType string, context map[string]interface{}) error {
	im.logger.WithFields(logrus.Fields{
		"webhook_id": webhook.ID,
		"event_type": eventType,
	}).Info("Processing generic webhook event")

	// Log the event for debugging
	im.logger.WithField("context", context).Debug("Generic webhook context")

	return nil
}

// extractHeaders extracts relevant headers from request
func (im *IntegrationManagerImpl) extractHeaders(request *http.Request) map[string]string {
	headers := make(map[string]string)

	relevantHeaders := []string{
		"Content-Type",
		"User-Agent",
		"X-Forwarded-For",
		"X-Real-IP",
		"X-GitHub-Event",
		"X-GitLab-Event",
		"X-Event-Type",
		"Authorization",
	}

	for _, header := range relevantHeaders {
		if value := request.Header.Get(header); value != "" {
			headers[header] = value
		}
	}

	return headers
}

// extractSourceIP extracts the source IP from request
func (im *IntegrationManagerImpl) extractSourceIP(request *http.Request) string {
	// Check X-Forwarded-For header first
	if xff := request.Header.Get("X-Forwarded-For"); xff != "" {
		// Take the first IP in the chain
		ips := strings.Split(xff, ",")
		return strings.TrimSpace(ips[0])
	}

	// Check X-Real-IP header
	if xri := request.Header.Get("X-Real-IP"); xri != "" {
		return xri
	}

	// Fall back to RemoteAddr
	return request.RemoteAddr
}

// logWebhookEvent logs a webhook event
func (im *IntegrationManagerImpl) logWebhookEvent(webhookID, eventType string, data map[string]interface{}) {
	log := &interfaces.WebhookLog{
		ID:        fmt.Sprintf("%s_%d", webhookID, time.Now().UnixNano()),
		WebhookID: webhookID,
		EventType: eventType,
		Data:      data,
		Timestamp: time.Now(),
		Level:     "info",
	}

	im.webhookMutex.Lock()
	defer im.webhookMutex.Unlock()

	if im.webhookLogs[webhookID] == nil {
		im.webhookLogs[webhookID] = make([]*interfaces.WebhookLog, 0, 1000)
	}

	im.webhookLogs[webhookID] = append(im.webhookLogs[webhookID], log)

	// Keep only the last 1000 logs per webhook
	if len(im.webhookLogs[webhookID]) > 1000 {
		im.webhookLogs[webhookID] = im.webhookLogs[webhookID][len(im.webhookLogs[webhookID])-1000:]
	}
}

// logWebhookExecution logs webhook execution details
func (im *IntegrationManagerImpl) logWebhookExecution(webhookID, eventType string, payload map[string]interface{}, request *http.Request, err error, duration time.Duration) {
	data := map[string]interface{}{
		"event_type":      eventType,
		"processing_time": duration.String(),
		"payload_size":    len(fmt.Sprintf("%v", payload)),
		"method":          request.Method,
		"url":             request.URL.String(),
		"user_agent":      request.Header.Get("User-Agent"),
		"content_type":    request.Header.Get("Content-Type"),
		"source_ip":       im.extractSourceIP(request),
	}

	level := "info"
	if err != nil {
		data["error"] = err.Error()
		level = "error"
	}

	log := &interfaces.WebhookLog{
		ID:        fmt.Sprintf("%s_exec_%d", webhookID, time.Now().UnixNano()),
		WebhookID: webhookID,
		EventType: "webhook_execution",
		Data:      data,
		Timestamp: time.Now(),
		Level:     level,
	}

	im.webhookMutex.Lock()
	defer im.webhookMutex.Unlock()

	if im.webhookLogs[webhookID] == nil {
		im.webhookLogs[webhookID] = make([]*interfaces.WebhookLog, 0, 1000)
	}

	im.webhookLogs[webhookID] = append(im.webhookLogs[webhookID], log)

	// Keep only the last 1000 logs per webhook
	if len(im.webhookLogs[webhookID]) > 1000 {
		im.webhookLogs[webhookID] = im.webhookLogs[webhookID][len(im.webhookLogs[webhookID])-1000:]
	}
}
