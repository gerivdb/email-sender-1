// Package integration provides WebhookManager implementation for FMOUA Phase 2
package integration

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/interfaces"
	"email_sender/pkg/fmoua/types"
)

// WebhookEvent represents a webhook event
type WebhookEvent struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"`
	Source    string                 `json:"source"`
	Timestamp time.Time              `json:"timestamp"`
	Data      map[string]interface{} `json:"data"`
	Headers   map[string]string      `json:"headers"`
}

// WebhookEndpoint represents a webhook endpoint configuration
type WebhookEndpoint struct {
	ID         string            `json:"id"`
	URL        string            `json:"url"`
	Events     []string          `json:"events"`
	Method     string            `json:"method"`
	Headers    map[string]string `json:"headers"`
	Secret     string            `json:"secret"`
	Enabled    bool              `json:"enabled"`
	MaxRetries int               `json:"max_retries"`
	RetryDelay time.Duration     `json:"retry_delay"`
	Timeout    time.Duration     `json:"timeout"`
	CreatedAt  time.Time         `json:"created_at"`
	UpdatedAt  time.Time         `json:"updated_at"`
}

// WebhookDelivery represents a webhook delivery attempt
type WebhookDelivery struct {
	ID          string        `json:"id"`
	EventID     string        `json:"event_id"`
	EndpointID  string        `json:"endpoint_id"`
	Status      string        `json:"status"` // pending, success, failed, retrying
	Attempts    int           `json:"attempts"`
	LastAttempt time.Time     `json:"last_attempt"`
	NextAttempt time.Time     `json:"next_attempt"`
	Response    string        `json:"response"`
	StatusCode  int           `json:"status_code"`
	Duration    time.Duration `json:"duration"`
	Error       string        `json:"error,omitempty"`
}

// WebhookTransformer interface for transforming webhook payloads
type WebhookTransformer interface {
	Transform(event *WebhookEvent, endpoint *WebhookEndpoint) ([]byte, error)
	GetContentType() string
}

// WebhookAuthenticator interface for webhook authentication
type WebhookAuthenticator interface {
	Sign(payload []byte, secret string) (string, error)
	Verify(payload []byte, signature string, secret string) bool
	GetHeaders(payload []byte, secret string) map[string]string
}

// WebhookServer interface for handling incoming webhooks
type WebhookServer interface {
	Start(ctx context.Context) error
	Stop(ctx context.Context) error
	RegisterHandler(path string, handler http.HandlerFunc)
	GetStats() WebhookServerStats
}

// WebhookClient interface for sending outgoing webhooks
type WebhookClient interface {
	Send(ctx context.Context, endpoint *WebhookEndpoint, payload []byte) (*WebhookDelivery, error)
	SendAsync(ctx context.Context, endpoint *WebhookEndpoint, payload []byte) error
	GetStats() WebhookClientStats
}

// WebhookServerStats represents webhook server statistics
type WebhookServerStats struct {
	RequestsTotal   int64     `json:"requests_total"`
	RequestsSuccess int64     `json:"requests_success"`
	RequestsError   int64     `json:"requests_error"`
	AverageLatency  float64   `json:"average_latency_ms"`
	ActiveHandlers  int       `json:"active_handlers"`
	LastRequest     time.Time `json:"last_request"`
}

// WebhookClientStats represents webhook client statistics
type WebhookClientStats struct {
	DeliveriesTotal   int64     `json:"deliveries_total"`
	DeliveriesSuccess int64     `json:"deliveries_success"`
	DeliveriesFailed  int64     `json:"deliveries_failed"`
	DeliveriesRetry   int64     `json:"deliveries_retry"`
	AverageLatency    float64   `json:"average_latency_ms"`
	LastDelivery      time.Time `json:"last_delivery"`
}

// WebhookManager manages webhook operations (incoming and outgoing)
type WebhookManager struct {
	*BaseManager
	config        types.WebhookManagerConfig
	server        WebhookServer
	client        WebhookClient
	endpoints     map[string]*WebhookEndpoint
	deliveries    map[string]*WebhookDelivery
	transformer   WebhookTransformer
	authenticator WebhookAuthenticator
	mu            sync.RWMutex
}

// NewWebhookManager creates a new WebhookManager instance
func NewWebhookManager(id string, config types.ManagerConfig, logger *zap.Logger, metrics MetricsCollector) (*WebhookManager, error) {
	baseManager := NewBaseManager(id, config, logger, metrics)

	// Parse webhook-specific config
	webhookConfig, err := parseWebhookManagerConfig(config.Config)
	if err != nil {
		return nil, fmt.Errorf("failed to parse webhook config: %w", err)
	}

	// Create webhook server and client
	server := NewHTTPWebhookServer(webhookConfig.Server, logger)
	client := NewHTTPWebhookClient(webhookConfig.Client, logger)

	// Create transformer and authenticator
	transformer := NewJSONWebhookTransformer()
	authenticator := NewHMACWebhookAuthenticator()

	manager := &WebhookManager{
		BaseManager:   baseManager,
		config:        webhookConfig,
		server:        server,
		client:        client,
		endpoints:     make(map[string]*WebhookEndpoint),
		deliveries:    make(map[string]*WebhookDelivery),
		transformer:   transformer,
		authenticator: authenticator,
	}

	return manager, nil
}

// Initialize initializes the webhook manager
func (w *WebhookManager) Initialize(ctx context.Context) error {
	w.mu.Lock()
	defer w.mu.Unlock()

	w.logger.Info("Initializing WebhookManager", zap.String("manager_id", w.id))

	// Start webhook server if enabled
	if w.config.Server.Enabled {
		if err := w.server.Start(ctx); err != nil {
			return fmt.Errorf("failed to start webhook server: %w", err)
		}
		w.logger.Info("Webhook server started", zap.String("host", w.config.Server.Host), zap.Int("port", w.config.Server.Port))
	}

	w.SetStatus(types.ManagerStatusRunning)
	w.logger.Info("WebhookManager initialized successfully")
	return nil
}

// Shutdown gracefully shuts down the webhook manager
func (w *WebhookManager) Shutdown(ctx context.Context) error {
	w.mu.Lock()
	defer w.mu.Unlock()

	w.logger.Info("Shutting down WebhookManager", zap.String("manager_id", w.id))

	// Stop webhook server
	if w.config.Server.Enabled {
		if err := w.server.Stop(ctx); err != nil {
			w.logger.Error("Failed to stop webhook server", zap.Error(err))
			return err
		}
	}

	w.SetStatus(types.ManagerStatusStopped)
	w.logger.Info("WebhookManager shutdown completed")
	return nil
}

// Start starts the webhook manager
func (w *WebhookManager) Start(ctx context.Context) error {
	return w.Initialize(ctx)
}

// Stop stops the webhook manager
func (w *WebhookManager) Stop() error {
	return w.Shutdown(context.Background())
}

// Status returns the manager status in the expected format
func (w *WebhookManager) Status() interfaces.HealthStatus {
	isHealthy := w.GetStatus() == types.ManagerStatusRunning
	return interfaces.HealthStatus{
		IsHealthy:    isHealthy,
		LastCheck:    time.Now(),
		ResponseTime: time.Millisecond * 10,
	}
}

// Execute executes a webhook task
func (w *WebhookManager) Execute(ctx context.Context, task types.Task) (types.Result, error) {
	start := time.Now()
	w.logger.Info("Executing webhook task", zap.String("task_id", task.ID), zap.String("task_type", task.Type))

	var result types.Result
	var err error

	switch task.Type {
	case "send_webhook":
		result, err = w.executeSendWebhook(ctx, task)
	case "register_endpoint":
		result, err = w.executeRegisterEndpoint(ctx, task)
	case "unregister_endpoint":
		result, err = w.executeUnregisterEndpoint(ctx, task)
	case "trigger_event":
		result, err = w.executeTriggerEvent(ctx, task)
	default:
		err = fmt.Errorf("unknown task type: %s", task.Type)
	}

	duration := time.Since(start)
	w.recordMetrics(task.Type, err == nil, duration)

	if err != nil {
		w.logger.Error("Failed to execute webhook task", zap.String("task_id", task.ID), zap.Error(err))
		return types.Result{
			TaskID:    task.ID,
			Success:   false,
			Error:     err.Error(),
			Duration:  duration,
			Timestamp: time.Now(),
		}, err
	}

	result.Duration = duration
	result.Timestamp = time.Now()
	w.logger.Info("Webhook task executed successfully", zap.String("task_id", task.ID), zap.Duration("duration", duration))
	return result, nil
}

// RegisterEndpoint registers a new webhook endpoint
func (w *WebhookManager) RegisterEndpoint(endpoint *WebhookEndpoint) error {
	w.mu.Lock()
	defer w.mu.Unlock()

	if endpoint.ID == "" {
		endpoint.ID = generateWebhookID()
	}

	endpoint.CreatedAt = time.Now()
	endpoint.UpdatedAt = time.Now()

	if endpoint.MaxRetries == 0 {
		endpoint.MaxRetries = 3
	}

	if endpoint.RetryDelay == 0 {
		endpoint.RetryDelay = 5 * time.Second
	}

	if endpoint.Timeout == 0 {
		endpoint.Timeout = 30 * time.Second
	}

	if endpoint.Method == "" {
		endpoint.Method = "POST"
	}

	w.endpoints[endpoint.ID] = endpoint
	w.logger.Info("Webhook endpoint registered", zap.String("endpoint_id", endpoint.ID), zap.String("url", endpoint.URL))
	return nil
}

// UnregisterEndpoint removes a webhook endpoint
func (w *WebhookManager) UnregisterEndpoint(endpointID string) error {
	w.mu.Lock()
	defer w.mu.Unlock()

	if _, exists := w.endpoints[endpointID]; !exists {
		return fmt.Errorf("endpoint not found: %s", endpointID)
	}

	delete(w.endpoints, endpointID)
	w.logger.Info("Webhook endpoint unregistered", zap.String("endpoint_id", endpointID))
	return nil
}

// TriggerEvent triggers a webhook event to all matching endpoints
func (w *WebhookManager) TriggerEvent(ctx context.Context, event *WebhookEvent) error {
	w.mu.RLock()
	matchingEndpoints := make([]*WebhookEndpoint, 0)
	for _, endpoint := range w.endpoints {
		if endpoint.Enabled && w.matchesEventType(endpoint, event.Type) {
			matchingEndpoints = append(matchingEndpoints, endpoint)
		}
	}
	w.mu.RUnlock()

	for _, endpoint := range matchingEndpoints {
		go w.deliverWebhook(ctx, event, endpoint)
	}

	w.logger.Info("Webhook event triggered", zap.String("event_id", event.ID), zap.String("event_type", event.Type), zap.Int("endpoints", len(matchingEndpoints)))
	return nil
}

// GetEndpoints returns all registered endpoints
func (w *WebhookManager) GetEndpoints() map[string]*WebhookEndpoint {
	w.mu.RLock()
	defer w.mu.RUnlock()

	endpoints := make(map[string]*WebhookEndpoint)
	for id, endpoint := range w.endpoints {
		endpoints[id] = endpoint
	}
	return endpoints
}

// GetDeliveries returns all webhook deliveries
func (w *WebhookManager) GetDeliveries() map[string]*WebhookDelivery {
	w.mu.RLock()
	defer w.mu.RUnlock()

	deliveries := make(map[string]*WebhookDelivery)
	for id, delivery := range w.deliveries {
		deliveries[id] = delivery
	}
	return deliveries
}

// GetStats returns webhook manager statistics
func (w *WebhookManager) GetStats() map[string]interface{} {
	w.mu.RLock()
	defer w.mu.RUnlock()

	stats := map[string]interface{}{
		"endpoints":      len(w.endpoints),
		"deliveries":     len(w.deliveries),
		"server_enabled": w.config.Server.Enabled,
		"client_stats":   w.client.GetStats(),
	}

	if w.config.Server.Enabled {
		stats["server_stats"] = w.server.GetStats()
	}

	return stats
}

// Name returns the manager name
func (w *WebhookManager) Name() string {
	return w.GetID()
}

// Health checks the webhook manager health
func (w *WebhookManager) Health() error {
	w.mu.RLock()
	defer w.mu.RUnlock()

	status := w.GetStatus()
	if status != types.ManagerStatusRunning {
		return fmt.Errorf("webhook manager not running, status: %s", status)
	}

	return nil
}

// Helper methods

func (w *WebhookManager) executeSendWebhook(ctx context.Context, task types.Task) (types.Result, error) {
	endpointID, ok := task.Payload["endpoint_id"].(string)
	if !ok {
		return types.Result{}, fmt.Errorf("missing endpoint_id in task payload")
	}

	payload, ok := task.Payload["payload"]
	if !ok {
		return types.Result{}, fmt.Errorf("missing payload in task payload")
	}

	w.mu.RLock()
	endpoint, exists := w.endpoints[endpointID]
	w.mu.RUnlock()

	if !exists {
		return types.Result{}, fmt.Errorf("endpoint not found: %s", endpointID)
	}

	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return types.Result{}, fmt.Errorf("failed to marshal payload: %w", err)
	}

	delivery, err := w.client.Send(ctx, endpoint, payloadBytes)
	if err != nil {
		return types.Result{}, fmt.Errorf("failed to send webhook: %w", err)
	}

	w.mu.Lock()
	w.deliveries[delivery.ID] = delivery
	w.mu.Unlock()

	return types.Result{
		TaskID:  task.ID,
		Success: delivery.Status == "success",
		Data: map[string]interface{}{
			"delivery_id": delivery.ID,
			"status":      delivery.Status,
			"attempts":    delivery.Attempts,
		},
	}, nil
}

func (w *WebhookManager) executeRegisterEndpoint(ctx context.Context, task types.Task) (types.Result, error) {
	endpointData, ok := task.Payload["endpoint"].(map[string]interface{})
	if !ok {
		return types.Result{}, fmt.Errorf("missing endpoint data in task payload")
	}

	endpoint := &WebhookEndpoint{
		URL:     endpointData["url"].(string),
		Events:  convertToStringSlice(endpointData["events"]),
		Enabled: true,
	}

	if method, ok := endpointData["method"].(string); ok {
		endpoint.Method = method
	}

	if secret, ok := endpointData["secret"].(string); ok {
		endpoint.Secret = secret
	}

	err := w.RegisterEndpoint(endpoint)
	if err != nil {
		return types.Result{}, err
	}

	return types.Result{
		TaskID:  task.ID,
		Success: true,
		Data: map[string]interface{}{
			"endpoint_id": endpoint.ID,
		},
	}, nil
}

func (w *WebhookManager) executeUnregisterEndpoint(ctx context.Context, task types.Task) (types.Result, error) {
	endpointID, ok := task.Payload["endpoint_id"].(string)
	if !ok {
		return types.Result{}, fmt.Errorf("missing endpoint_id in task payload")
	}

	err := w.UnregisterEndpoint(endpointID)
	if err != nil {
		return types.Result{}, err
	}

	return types.Result{
		TaskID:  task.ID,
		Success: true,
		Data: map[string]interface{}{
			"endpoint_id": endpointID,
		},
	}, nil
}

func (w *WebhookManager) executeTriggerEvent(ctx context.Context, task types.Task) (types.Result, error) {
	eventData, ok := task.Payload["event"].(map[string]interface{})
	if !ok {
		return types.Result{}, fmt.Errorf("missing event data in task payload")
	}

	event := &WebhookEvent{
		ID:        generateWebhookID(),
		Type:      eventData["type"].(string),
		Source:    eventData["source"].(string),
		Timestamp: time.Now(),
		Data:      eventData["data"].(map[string]interface{}),
	}

	err := w.TriggerEvent(ctx, event)
	if err != nil {
		return types.Result{}, err
	}

	return types.Result{
		TaskID:  task.ID,
		Success: true,
		Data: map[string]interface{}{
			"event_id": event.ID,
		},
	}, nil
}

func (w *WebhookManager) deliverWebhook(ctx context.Context, event *WebhookEvent, endpoint *WebhookEndpoint) {
	delivery := &WebhookDelivery{
		ID:          generateWebhookID(),
		EventID:     event.ID,
		EndpointID:  endpoint.ID,
		Status:      "pending",
		Attempts:    0,
		LastAttempt: time.Now(),
	}

	payload, err := w.transformer.Transform(event, endpoint)
	if err != nil {
		delivery.Status = "failed"
		delivery.Error = err.Error()
		w.mu.Lock()
		w.deliveries[delivery.ID] = delivery
		w.mu.Unlock()
		return
	}

	deliveryResult, err := w.client.Send(ctx, endpoint, payload)
	if err != nil {
		delivery.Status = "failed"
		delivery.Error = err.Error()
	} else {
		delivery = deliveryResult
	}

	w.mu.Lock()
	w.deliveries[delivery.ID] = delivery
	w.mu.Unlock()
}

func (w *WebhookManager) matchesEventType(endpoint *WebhookEndpoint, eventType string) bool {
	if len(endpoint.Events) == 0 {
		return true // Match all events if no specific events configured
	}

	for _, event := range endpoint.Events {
		if event == eventType || event == "*" {
			return true
		}
	}
	return false
}

func (w *WebhookManager) recordMetrics(operation string, success bool, duration time.Duration) {
	if w.metrics != nil {
		metric := fmt.Sprintf("webhook_%s", operation)
		w.metrics.Histogram(metric+"_duration", duration.Seconds(), nil)
		if success {
			w.metrics.Increment(metric+"_success", nil)
		} else {
			w.metrics.Increment(metric+"_error", nil)
		}
	}
}

// Helper functions

func parseWebhookManagerConfig(config interface{}) (types.WebhookManagerConfig, error) {
	configBytes, err := json.Marshal(config)
	if err != nil {
		return types.WebhookManagerConfig{}, err
	}

	// First parse into a generic map to handle duration strings
	var configMap map[string]interface{}
	if err := json.Unmarshal(configBytes, &configMap); err != nil {
		return types.WebhookManagerConfig{}, err
	}

	// Convert duration strings to actual durations
	if clientMap, ok := configMap["client"].(map[string]interface{}); ok {
		if timeoutStr, ok := clientMap["timeout"].(string); ok {
			if timeout, err := time.ParseDuration(timeoutStr); err == nil {
				clientMap["timeout"] = timeout.Nanoseconds()
			}
		}
		if retryDelayStr, ok := clientMap["retry_delay"].(string); ok {
			if retryDelay, err := time.ParseDuration(retryDelayStr); err == nil {
				clientMap["retry_delay"] = retryDelay.Nanoseconds()
			}
		}
		if maxRetryDelayStr, ok := clientMap["max_retry_delay"].(string); ok {
			if maxRetryDelay, err := time.ParseDuration(maxRetryDelayStr); err == nil {
				clientMap["max_retry_delay"] = maxRetryDelay.Nanoseconds()
			}
		}
	}

	if serverMap, ok := configMap["server"].(map[string]interface{}); ok {
		if readTimeoutStr, ok := serverMap["read_timeout"].(string); ok {
			if readTimeout, err := time.ParseDuration(readTimeoutStr); err == nil {
				serverMap["read_timeout"] = readTimeout.Nanoseconds()
			}
		}
		if writeTimeoutStr, ok := serverMap["write_timeout"].(string); ok {
			if writeTimeout, err := time.ParseDuration(writeTimeoutStr); err == nil {
				serverMap["write_timeout"] = writeTimeout.Nanoseconds()
			}
		}
		if idleTimeoutStr, ok := serverMap["idle_timeout"].(string); ok {
			if idleTimeout, err := time.ParseDuration(idleTimeoutStr); err == nil {
				serverMap["idle_timeout"] = idleTimeout.Nanoseconds()
			}
		}
	}

	// Convert back to JSON and unmarshal into the struct
	configBytes, err = json.Marshal(configMap)
	if err != nil {
		return types.WebhookManagerConfig{}, err
	}

	var webhookConfig types.WebhookManagerConfig
	if err := json.Unmarshal(configBytes, &webhookConfig); err != nil {
		return types.WebhookManagerConfig{}, err
	}

	// Set defaults
	if webhookConfig.Server.Host == "" {
		webhookConfig.Server.Host = "localhost"
	}
	if webhookConfig.Server.Port == 0 {
		webhookConfig.Server.Port = 8080
	}
	if webhookConfig.Client.Timeout == 0 {
		webhookConfig.Client.Timeout = 30 * time.Second
	}
	if webhookConfig.Client.MaxRetries == 0 {
		webhookConfig.Client.MaxRetries = 3
	}

	return webhookConfig, nil
}

func generateWebhookID() string {
	return fmt.Sprintf("wh_%d", time.Now().UnixNano())
}

func convertToStringSlice(input interface{}) []string {
	if slice, ok := input.([]interface{}); ok {
		result := make([]string, len(slice))
		for i, v := range slice {
			if str, ok := v.(string); ok {
				result[i] = str
			}
		}
		return result
	}
	return []string{}
}
