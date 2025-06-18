package main

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"
)

// EmailManager handles email operations
type EmailManager struct {
	config    *EmailConfig
	processor *EmailProcessor
	queue     *EmailQueue
	templates *TemplateManager
	analytics *AnalyticsCollector
	logger    *zap.Logger
	eventBus  *EventBus
	running   bool
	mu        sync.RWMutex
}

// EmailRequest represents an email to be sent
type EmailRequest struct {
	To           []string               `json:"to"`
	CC           []string               `json:"cc,omitempty"`
	BCC          []string               `json:"bcc,omitempty"`
	Subject      string                 `json:"subject"`
	Body         string                 `json:"body"`
	HTML         string                 `json:"html,omitempty"`
	Template     string                 `json:"template,omitempty"`
	TemplateData map[string]interface{} `json:"template_data,omitempty"`
	Priority     int                    `json:"priority"`
	ScheduledAt  *time.Time             `json:"scheduled_at,omitempty"`
	Attachments  []Attachment           `json:"attachments,omitempty"`
}

type Attachment struct {
	Filename string `json:"filename"`
	Content  []byte `json:"content"`
	MimeType string `json:"mime_type"`
}

// EmailProcessor handles the actual email sending
type EmailProcessor struct {
	config *EmailConfig
	logger *zap.Logger
}

// EmailQueue manages email queuing and processing
type EmailQueue struct {
	queue   chan EmailRequest
	workers []*EmailWorker
	logger  *zap.Logger
}

type EmailWorker struct {
	id        int
	processor *EmailProcessor
	logger    *zap.Logger
}

// TemplateManager handles email templates
type TemplateManager struct {
	templateDir string
	templates   map[string]*EmailTemplate
	logger      *zap.Logger
}

type EmailTemplate struct {
	Name    string
	Subject string
	Body    string
	HTML    string
}

// AnalyticsCollector tracks email metrics
type AnalyticsCollector struct {
	metrics map[string]interface{}
	logger  *zap.Logger
	mu      sync.RWMutex
}

// NewEmailManager creates a new email manager instance
func NewEmailManager(config *EmailConfig, logger *zap.Logger, eventBus *EventBus) *EmailManager {
	return &EmailManager{
		config:    config,
		processor: NewEmailProcessor(config, logger),
		queue:     NewEmailQueue(config, logger),
		templates: NewTemplateManager(config.TemplateDir, logger),
		analytics: NewAnalyticsCollector(logger),
		logger:    logger,
		eventBus:  eventBus,
	}
}

// Start initializes and starts the email manager
func (em *EmailManager) Start(ctx context.Context) error {
	em.mu.Lock()
	defer em.mu.Unlock()

	if em.running {
		return nil
	}

	em.logger.Info("Starting Email Manager")

	// Initialize templates
	if err := em.templates.LoadTemplates(); err != nil {
		return fmt.Errorf("failed to load templates: %w", err)
	}

	// Start email queue workers
	if err := em.queue.Start(ctx, em.processor); err != nil {
		return fmt.Errorf("failed to start email queue: %w", err)
	}

	em.running = true

	// Publish manager started event
	em.eventBus.Publish(Event{
		Type:   EventManagerStarted,
		Source: "email_manager",
		Payload: map[string]interface{}{
			"status": "started",
			"config": em.config,
		},
	})

	em.logger.Info("Email Manager started successfully")
	return nil
}

// Stop gracefully shuts down the email manager
func (em *EmailManager) Stop(ctx context.Context) error {
	em.mu.Lock()
	defer em.mu.Unlock()

	if !em.running {
		return nil
	}

	em.logger.Info("Stopping Email Manager")

	// Stop email queue
	em.queue.Stop(ctx)

	em.running = false

	// Publish manager stopped event
	em.eventBus.Publish(Event{
		Type:   EventManagerStopped,
		Source: "email_manager",
		Payload: map[string]interface{}{
			"status": "stopped",
		},
	})

	em.logger.Info("Email Manager stopped successfully")
	return nil
}

// ProcessEmailBatch processes multiple emails in parallel
func (em *EmailManager) ProcessEmailBatch(emails []EmailRequest) error {
	if !em.running {
		return fmt.Errorf("email manager is not running")
	}

	em.logger.Info("Processing email batch", zap.Int("count", len(emails)))

	// Traitement parallèle optimisé
	semaphore := make(chan struct{}, em.config.MaxConcurrency)
	var wg sync.WaitGroup
	var errors []error
	var errorMu sync.Mutex

	for _, email := range emails {
		wg.Add(1)
		go func(e EmailRequest) {
			defer wg.Done()
			semaphore <- struct{}{}
			defer func() { <-semaphore }()

			if err := em.processEmail(e); err != nil {
				errorMu.Lock()
				errors = append(errors, err)
				errorMu.Unlock()
			}
		}(email)
	}

	wg.Wait()

	if len(errors) > 0 {
		return fmt.Errorf("batch processing failed with %d errors: %v", len(errors), errors[0])
	}

	return nil
}

// processEmail processes a single email
func (em *EmailManager) processEmail(email EmailRequest) error {
	start := time.Now()

	// Apply template if specified
	if email.Template != "" {
		if err := em.templates.ApplyTemplate(&email); err != nil {
			em.logger.Error("Failed to apply template",
				zap.String("template", email.Template),
				zap.Error(err))
			return err
		}
	}

	// Queue email for processing
	select {
	case em.queue.queue <- email:
		// Email queued successfully
		em.analytics.RecordEmailQueued(email, time.Since(start))
		return nil
	default:
		// Queue is full
		err := fmt.Errorf("email queue is full")
		em.logger.Error("Failed to queue email", zap.Error(err))
		return err
	}
}

// Health returns the health status of the email manager
func (em *EmailManager) Health() HealthStatus {
	em.mu.RLock()
	defer em.mu.RUnlock()

	status := "healthy"
	message := "Email manager is operating normally"

	if !em.running {
		status = "unhealthy"
		message = "Email manager is not running"
	}

	return HealthStatus{
		Status:    status,
		Message:   message,
		Timestamp: time.Now(),
		Details: map[string]interface{}{
			"running":        em.running,
			"queue_length":   len(em.queue.queue),
			"queue_capacity": cap(em.queue.queue),
			"worker_count":   len(em.queue.workers),
			"template_count": len(em.templates.templates),
		},
	}
}

// Metrics returns current email manager metrics
func (em *EmailManager) Metrics() map[string]interface{} {
	return em.analytics.GetMetrics()
}

// GetName returns the manager name
func (em *EmailManager) GetName() string {
	return "email_manager"
}

// EmailProcessor methods

func NewEmailProcessor(config *EmailConfig, logger *zap.Logger) *EmailProcessor {
	return &EmailProcessor{
		config: config,
		logger: logger,
	}
}

func (ep *EmailProcessor) SendEmail(email EmailRequest) error {
	// TODO: Implement actual email sending using SMTP
	ep.logger.Info("Sending email",
		zap.Strings("to", email.To),
		zap.String("subject", email.Subject))

	// Simulate email sending
	time.Sleep(time.Millisecond * 100)

	return nil
}

// EmailQueue methods

func NewEmailQueue(config *EmailConfig, logger *zap.Logger) *EmailQueue {
	return &EmailQueue{
		queue:  make(chan EmailRequest, config.QueueSize),
		logger: logger,
	}
}

func (eq *EmailQueue) Start(ctx context.Context, processor *EmailProcessor) error {
	workerCount := 4
	eq.workers = make([]*EmailWorker, workerCount)

	for i := 0; i < workerCount; i++ {
		worker := &EmailWorker{
			id:        i,
			processor: processor,
			logger:    eq.logger.With(zap.Int("worker_id", i)),
		}
		eq.workers[i] = worker
		go worker.start(ctx, eq.queue)
	}

	eq.logger.Info("Email queue started", zap.Int("workers", workerCount))
	return nil
}

func (eq *EmailQueue) Stop(ctx context.Context) {
	close(eq.queue)
	eq.logger.Info("Email queue stopped")
}

// EmailWorker methods

func (ew *EmailWorker) start(ctx context.Context, queue <-chan EmailRequest) {
	ew.logger.Info("Email worker started")

	for {
		select {
		case email, ok := <-queue:
			if !ok {
				ew.logger.Info("Email worker stopping - queue closed")
				return
			}

			if err := ew.processor.SendEmail(email); err != nil {
				ew.logger.Error("Failed to send email", zap.Error(err))
			}

		case <-ctx.Done():
			ew.logger.Info("Email worker stopping - context cancelled")
			return
		}
	}
}

// TemplateManager methods

func NewTemplateManager(templateDir string, logger *zap.Logger) *TemplateManager {
	return &TemplateManager{
		templateDir: templateDir,
		templates:   make(map[string]*EmailTemplate),
		logger:      logger,
	}
}

func (tm *TemplateManager) LoadTemplates() error {
	// TODO: Implement template loading from filesystem
	tm.logger.Info("Loading email templates", zap.String("dir", tm.templateDir))

	// For now, add some default templates
	tm.templates["welcome"] = &EmailTemplate{
		Name:    "welcome",
		Subject: "Welcome to {{.AppName}}",
		Body:    "Welcome {{.UserName}}, thank you for joining us!",
		HTML:    "<h1>Welcome {{.UserName}}</h1><p>Thank you for joining us!</p>",
	}

	return nil
}

func (tm *TemplateManager) ApplyTemplate(email *EmailRequest) error {
	template, exists := tm.templates[email.Template]
	if !exists {
		return fmt.Errorf("template %s not found", email.Template)
	}

	// TODO: Implement proper template rendering
	email.Subject = template.Subject
	email.Body = template.Body
	email.HTML = template.HTML

	return nil
}

// AnalyticsCollector methods

func NewAnalyticsCollector(logger *zap.Logger) *AnalyticsCollector {
	return &AnalyticsCollector{
		metrics: make(map[string]interface{}),
		logger:  logger,
	}
}

func (ac *AnalyticsCollector) RecordEmailQueued(email EmailRequest, duration time.Duration) {
	ac.mu.Lock()
	defer ac.mu.Unlock()

	// Update metrics
	if count, exists := ac.metrics["emails_queued"]; exists {
		ac.metrics["emails_queued"] = count.(int64) + 1
	} else {
		ac.metrics["emails_queued"] = int64(1)
	}

	ac.metrics["last_queue_time"] = time.Now()
	ac.metrics["avg_queue_duration_ms"] = duration.Milliseconds()
}

func (ac *AnalyticsCollector) GetMetrics() map[string]interface{} {
	ac.mu.RLock()
	defer ac.mu.RUnlock()

	// Return a copy of metrics
	result := make(map[string]interface{})
	for k, v := range ac.metrics {
		result[k] = v
	}

	return result
}
