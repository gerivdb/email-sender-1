// Package integration provides EmailManager implementation for FMOUA Phase 2
package integration

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/types"
)

// EmailProvider interface for email provider implementations
type EmailProvider interface {
	SendEmail(email *EmailMessage) error
	SendBulk(emails []*EmailMessage) error
	GetDeliveryStatus(messageID string) (*DeliveryStatus, error)
	ValidateConfig() error
	GetRateLimit() int
}

// TemplateEngine interface for email template processing
type TemplateEngine interface {
	LoadTemplate(name string) (*EmailTemplate, error)
	RenderTemplate(template *EmailTemplate, data map[string]interface{}) (*EmailMessage, error)
	CacheTemplate(name string, template *EmailTemplate) error
	GetCachedTemplate(name string) (*EmailTemplate, bool)
}

// DeliveryTracker interface for tracking email delivery
type DeliveryTracker interface {
	TrackSent(messageID string, recipient string) error
	TrackDelivered(messageID string) error
	TrackOpened(messageID string, timestamp time.Time) error
	TrackClicked(messageID string, url string, timestamp time.Time) error
	GetStatistics(since time.Time) (*DeliveryStatistics, error)
}

// EmailManager manages email operations with multiple providers
type EmailManager struct {
	*BaseManager
	config    types.EmailManagerConfig
	providers map[string]EmailProvider
	templates TemplateEngine
	tracker   DeliveryTracker
	queue     EmailQueue
	mu        sync.RWMutex
}

// EmailMessage represents an email message
type EmailMessage struct {
	ID          string            `json:"id"`
	From        string            `json:"from"`
	To          []string          `json:"to"`
	CC          []string          `json:"cc,omitempty"`
	BCC         []string          `json:"bcc,omitempty"`
	Subject     string            `json:"subject"`
	HTMLBody    string            `json:"html_body,omitempty"`
	TextBody    string            `json:"text_body,omitempty"`
	Attachments []EmailAttachment `json:"attachments,omitempty"`
	Headers     map[string]string `json:"headers,omitempty"`
	Priority    int               `json:"priority"`
	ScheduledAt time.Time         `json:"scheduled_at,omitempty"`
	CreatedAt   time.Time         `json:"created_at"`
}

// EmailAttachment represents an email attachment
type EmailAttachment struct {
	Filename    string `json:"filename"`
	ContentType string `json:"content_type"`
	Data        []byte `json:"data"`
}

// EmailTemplate represents an email template
type EmailTemplate struct {
	Name        string            `json:"name"`
	Subject     string            `json:"subject"`
	HTMLContent string            `json:"html_content"`
	TextContent string            `json:"text_content"`
	Variables   []string          `json:"variables"`
	Metadata    map[string]string `json:"metadata"`
}

// DeliveryStatus represents email delivery status
type DeliveryStatus struct {
	MessageID string            `json:"message_id"`
	Status    string            `json:"status"` // sent, delivered, opened, clicked, bounced, failed
	Timestamp time.Time         `json:"timestamp"`
	Details   string            `json:"details,omitempty"`
	Metadata  map[string]string `json:"metadata,omitempty"`
}

// DeliveryStatistics represents email delivery statistics
type DeliveryStatistics struct {
	TotalSent      int64   `json:"total_sent"`
	TotalDelivered int64   `json:"total_delivered"`
	TotalOpened    int64   `json:"total_opened"`
	TotalClicked   int64   `json:"total_clicked"`
	TotalBounced   int64   `json:"total_bounced"`
	TotalFailed    int64   `json:"total_failed"`
	DeliveryRate   float64 `json:"delivery_rate"`
	OpenRate       float64 `json:"open_rate"`
	ClickRate      float64 `json:"click_rate"`
	BounceRate     float64 `json:"bounce_rate"`
}

// EmailQueue interface for email queuing
type EmailQueue interface {
	Enqueue(email *EmailMessage) error
	Dequeue() (*EmailMessage, error)
	Size() int
	Clear() error
}

// NewEmailManager creates a new EmailManager instance
func NewEmailManager(id string, config types.ManagerConfig, logger *zap.Logger, metrics MetricsCollector) (*EmailManager, error) {
	baseManager := NewBaseManager(id, config, logger, metrics)

	// Parse email-specific config
	emailConfig, err := parseEmailManagerConfig(config.Config)
	if err != nil {
		return nil, fmt.Errorf("failed to parse email config: %w", err)
	}

	em := &EmailManager{
		BaseManager: baseManager,
		config:      emailConfig,
		providers:   make(map[string]EmailProvider),
		templates:   NewDefaultTemplateEngine(emailConfig.Templates),
		tracker:     NewDefaultDeliveryTracker(),
		queue:       NewMemoryEmailQueue(emailConfig.QueueConfig),
	}

	return em, nil
}

// Initialize initializes the email manager with providers
func (em *EmailManager) Initialize(config types.ManagerConfig) error {
	if err := em.BaseManager.Initialize(config); err != nil {
		return err
	}

	// Initialize email providers
	for name, providerConfig := range em.config.Providers {
		provider, err := em.createProvider(name, providerConfig)
		if err != nil {
			em.LogError("Failed to create email provider", err,
				zap.String("provider", name))
			continue
		}

		if err := provider.ValidateConfig(); err != nil {
			em.LogError("Email provider config validation failed", err,
				zap.String("provider", name))
			continue
		}

		em.mu.Lock()
		em.providers[name] = provider
		em.mu.Unlock()

		em.LogInfo("Email provider initialized",
			zap.String("provider", name))
	}

	if len(em.providers) == 0 {
		return fmt.Errorf("no valid email providers configured")
	}

	return nil
}

// Execute processes an email task
func (em *EmailManager) Execute(ctx context.Context, task types.Task) (types.Result, error) {
	startTime := time.Now()

	result := types.Result{
		TaskID:    task.ID,
		Timestamp: startTime,
	}

	em.LogInfo("Executing email task",
		zap.String("task_id", task.ID),
		zap.String("task_type", task.Type))

	switch task.Type {
	case "send_email":
		err := em.handleSendEmail(ctx, task)
		result.Success = err == nil
		if err != nil {
			result.Error = err.Error()
		}

	case "send_bulk":
		err := em.handleSendBulk(ctx, task)
		result.Success = err == nil
		if err != nil {
			result.Error = err.Error()
		}

	case "get_statistics":
		stats, err := em.handleGetStatistics(ctx, task)
		result.Success = err == nil
		if err != nil {
			result.Error = err.Error()
		} else {
			result.Data = map[string]interface{}{"statistics": stats}
		}

	default:
		err := fmt.Errorf("unsupported task type: %s", task.Type)
		result.Success = false
		result.Error = err.Error()
	}

	result.Duration = time.Since(startTime)

	// Update metrics
	em.metrics.Histogram("email_task_duration",
		float64(result.Duration.Milliseconds()),
		map[string]string{
			"task_type": task.Type,
			"success":   fmt.Sprintf("%t", result.Success),
		})

	return result, nil
}

// Start starts the email manager and its workers
func (em *EmailManager) Start() error {
	if err := em.BaseManager.Start(); err != nil {
		return err
	}

	// Start queue workers
	em.startQueueWorkers()

	em.LogInfo("Email manager started",
		zap.Int("providers", len(em.providers)),
		zap.Int("workers", em.config.QueueConfig.Workers))

	return nil
}

// Stop stops the email manager
func (em *EmailManager) Stop() error {
	em.LogInfo("Stopping email manager")

	// Stop queue processing
	// Implementation depends on queue type

	return em.BaseManager.Stop()
}

// GetType returns the manager type
func (em *EmailManager) GetType() string {
	return "email"
}

// createProvider creates an email provider based on configuration
func (em *EmailManager) createProvider(name string, config types.EmailProviderConfig) (EmailProvider, error) {
	switch config.Type {
	case "smtp":
		return NewSMTPProvider(config), nil
	case "sendgrid":
		return NewSendGridProvider(config), nil
	case "mailgun":
		return NewMailgunProvider(config), nil
	default:
		return nil, fmt.Errorf("unsupported provider type: %s", config.Type)
	}
}

// handleSendEmail handles single email sending
func (em *EmailManager) handleSendEmail(ctx context.Context, task types.Task) error {
	// Parse email data from task payload
	emailData, ok := task.Payload["email"].(map[string]interface{})
	if !ok {
		return fmt.Errorf("invalid email data in task payload")
	}

	email, err := em.parseEmailMessage(emailData)
	if err != nil {
		return fmt.Errorf("failed to parse email message: %w", err)
	}

	// Add to queue for processing
	if err := em.queue.Enqueue(email); err != nil {
		return fmt.Errorf("failed to queue email: %w", err)
	}

	em.LogInfo("Email queued for sending",
		zap.String("email_id", email.ID),
		zap.String("recipient", email.To[0]))

	return nil
}

// handleSendBulk handles bulk email sending
func (em *EmailManager) handleSendBulk(ctx context.Context, task types.Task) error {
	// Parse bulk email data from task payload
	bulkData, ok := task.Payload["emails"].([]interface{})
	if !ok {
		return fmt.Errorf("invalid bulk email data in task payload")
	}

	for i, emailData := range bulkData {
		emailMap, ok := emailData.(map[string]interface{})
		if !ok {
			em.LogError("Invalid email data in bulk", nil,
				zap.Int("index", i))
			continue
		}

		email, err := em.parseEmailMessage(emailMap)
		if err != nil {
			em.LogError("Failed to parse email in bulk", err,
				zap.Int("index", i))
			continue
		}

		if err := em.queue.Enqueue(email); err != nil {
			em.LogError("Failed to queue email in bulk", err,
				zap.String("email_id", email.ID),
				zap.Int("index", i))
		}
	}

	return nil
}

// handleGetStatistics handles statistics retrieval
func (em *EmailManager) handleGetStatistics(ctx context.Context, task types.Task) (*DeliveryStatistics, error) {
	since := time.Now().Add(-24 * time.Hour) // Default to last 24 hours

	if sinceStr, ok := task.Payload["since"].(string); ok {
		if parsedTime, err := time.Parse(time.RFC3339, sinceStr); err == nil {
			since = parsedTime
		}
	}

	return em.tracker.GetStatistics(since)
}

// parseEmailMessage parses email data into EmailMessage struct
func (em *EmailManager) parseEmailMessage(data map[string]interface{}) (*EmailMessage, error) {
	email := &EmailMessage{
		ID:        generateEmailID(),
		CreatedAt: time.Now(),
		Headers:   make(map[string]string),
	}

	// Parse required fields
	if from, ok := data["from"].(string); ok {
		email.From = from
	} else {
		return nil, fmt.Errorf("missing 'from' field")
	}

	if to, ok := data["to"].([]interface{}); ok {
		for _, recipient := range to {
			if recipientStr, ok := recipient.(string); ok {
				email.To = append(email.To, recipientStr)
			}
		}
	} else {
		return nil, fmt.Errorf("missing or invalid 'to' field")
	}

	if subject, ok := data["subject"].(string); ok {
		email.Subject = subject
	}

	if htmlBody, ok := data["html_body"].(string); ok {
		email.HTMLBody = htmlBody
	}

	if textBody, ok := data["text_body"].(string); ok {
		email.TextBody = textBody
	}

	// Parse optional fields
	if cc, ok := data["cc"].([]interface{}); ok {
		for _, recipient := range cc {
			if recipientStr, ok := recipient.(string); ok {
				email.CC = append(email.CC, recipientStr)
			}
		}
	}

	if priority, ok := data["priority"].(float64); ok {
		email.Priority = int(priority)
	}

	return email, nil
}

// startQueueWorkers starts background workers to process email queue
func (em *EmailManager) startQueueWorkers() {
	for i := 0; i < em.config.QueueConfig.Workers; i++ {
		go em.queueWorker(i)
	}
}

// queueWorker processes emails from the queue
func (em *EmailManager) queueWorker(workerID int) {
	em.LogInfo("Starting email queue worker", zap.Int("worker_id", workerID))

	for {
		select {
		case <-em.Context().Done():
			em.LogInfo("Email queue worker stopping", zap.Int("worker_id", workerID))
			return
		default:
			email, err := em.queue.Dequeue()
			if err != nil {
				time.Sleep(1 * time.Second)
				continue
			}

			if email == nil {
				time.Sleep(100 * time.Millisecond)
				continue
			}

			em.processEmail(email, workerID)
		}
	}
}

// processEmail processes a single email
func (em *EmailManager) processEmail(email *EmailMessage, workerID int) {
	startTime := time.Now()

	em.LogInfo("Processing email",
		zap.String("email_id", email.ID),
		zap.Int("worker_id", workerID))

	// Select provider (simple round-robin for now)
	provider := em.selectProvider()
	if provider == nil {
		em.LogError("No available email providers", nil,
			zap.String("email_id", email.ID))
		return
	}

	// Send email
	err := provider.SendEmail(email)
	if err != nil {
		em.LogError("Failed to send email", err,
			zap.String("email_id", email.ID))
		em.metrics.Increment("email_send_failed", map[string]string{
			"worker_id": fmt.Sprintf("%d", workerID),
		})
		return
	}

	// Track sending
	if err := em.tracker.TrackSent(email.ID, email.To[0]); err != nil {
		em.LogError("Failed to track email", err,
			zap.String("email_id", email.ID))
	}

	duration := time.Since(startTime)
	em.LogInfo("Email sent successfully",
		zap.String("email_id", email.ID),
		zap.Duration("duration", duration))

	em.metrics.Increment("email_sent", map[string]string{
		"worker_id": fmt.Sprintf("%d", workerID),
	})
	em.metrics.Histogram("email_send_duration",
		float64(duration.Milliseconds()),
		map[string]string{
			"worker_id": fmt.Sprintf("%d", workerID),
		})
}

// selectProvider selects an available email provider
func (em *EmailManager) selectProvider() EmailProvider {
	em.mu.RLock()
	defer em.mu.RUnlock()

	// Simple selection - return first available provider
	// In production, this could be more sophisticated (load balancing, health checks, etc.)
	for _, provider := range em.providers {
		return provider
	}

	return nil
}

// parseEmailManagerConfig parses email manager configuration
func parseEmailManagerConfig(config map[string]interface{}) (types.EmailManagerConfig, error) {
	// This is a simplified parser. In production, you'd use a proper YAML/JSON parser
	// or a configuration library like Viper

	emailConfig := types.EmailManagerConfig{
		Providers: make(map[string]types.EmailProviderConfig),
		QueueConfig: types.QueueConfig{
			Type:          "memory",
			MaxSize:       1000,
			Workers:       2,
			RetryAttempts: 3,
			RetryDelay:    time.Second * 5,
			BatchSize:     10,
		},
	}

	// Parse providers configuration
	if providersData, ok := config["providers"].(map[string]interface{}); ok {
		for name, providerData := range providersData {
			if providerMap, ok := providerData.(map[string]interface{}); ok {
				providerConfig := types.EmailProviderConfig{}

				if typ, ok := providerMap["type"].(string); ok {
					providerConfig.Type = typ
				}
				if host, ok := providerMap["host"].(string); ok {
					providerConfig.Host = host
				}
				if port, ok := providerMap["port"].(float64); ok {
					providerConfig.Port = int(port)
				}

				// Ensure we have required fields for SMTP
				if providerConfig.Type == "smtp" && providerConfig.Host != "" && providerConfig.Port > 0 {
					emailConfig.Providers[name] = providerConfig
				}
			}
		}
	}

	// If no providers configured, add a default test provider
	if len(emailConfig.Providers) == 0 {
		emailConfig.Providers["default"] = types.EmailProviderConfig{
			Type: "smtp",
			Host: "localhost",
			Port: 587,
		}
	}

	return emailConfig, nil
}

// generateEmailID generates a unique email ID
func generateEmailID() string {
	return fmt.Sprintf("email_%d_%d", time.Now().Unix(), time.Now().Nanosecond())
}
