package email

import (
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"sync"
	"time"

	"github.com/gerivdb/email-sender-1/managers/interfaces"
	"github.com/google/uuid"
	"github.com/robfig/cron/v3"
	"go.uber.org/zap"
	"gopkg.in/gomail.v2"
)

// EmailManagerImpl implémente l'interface EmailManager
type EmailManagerImpl struct {
	// Base manager fields
	id            string
	name          string
	version       string
	status        interfaces.ManagerStatus
	logger        *zap.Logger
	mu            sync.RWMutex
	isInitialized bool

	// Email manager specific fields
	config          *EmailConfig
	smtpDialer      *gomail.Dialer
	templateManager interfaces.TemplateManager
	queueManager    interfaces.QueueManager
	scheduler       *cron.Cron
	emailQueue      chan *interfaces.Email
	workers         int
	workerPool      chan struct{}

	// Storage and analytics
	emailStore      map[string]*interfaces.Email
	templateStore   map[string]*interfaces.EmailTemplate
	deliveryReports map[string]*interfaces.DeliveryReport
	stats           *EmailStats

	// Control channels
	stopChan  chan struct{}
	workersWg sync.WaitGroup
}

// EmailConfig représente la configuration de l'Email Manager
type EmailConfig struct {
	SMTPHost      string
	SMTPPort      int
	Username      string
	Password      string
	FromAddress   string
	FromName      string
	Workers       int
	QueueSize     int
	RetryAttempts int
	RetryDelay    time.Duration
	Timeout       time.Duration
	TLSEnabled    bool
}

// EmailStats représente les statistiques internes
type EmailStats struct {
	TotalSent    int64
	TotalFailed  int64
	TotalOpened  int64
	TotalClicked int64
	mu           sync.RWMutex
}

// NewEmailManager crée une nouvelle instance du gestionnaire d'emails
func NewEmailManager() (interfaces.EmailManager, error) {
	config := getDefaultEmailConfig()

	logger, err := zap.NewProduction()
	if err != nil {
		return nil, fmt.Errorf("failed to create logger: %w", err)
	}

	manager := &EmailManagerImpl{
		id:              uuid.New().String(),
		name:            "EmailManager",
		version:         "1.0.0",
		status:          interfaces.ManagerStatusStarting,
		logger:          logger,
		config:          config,
		workers:         config.Workers,
		emailQueue:      make(chan *interfaces.Email, config.QueueSize),
		workerPool:      make(chan struct{}, config.Workers),
		emailStore:      make(map[string]*interfaces.Email),
		templateStore:   make(map[string]*interfaces.EmailTemplate),
		deliveryReports: make(map[string]*interfaces.DeliveryReport),
		stats:           &EmailStats{},
		stopChan:        make(chan struct{}),
	}

	// Initialize SMTP dialer
	manager.smtpDialer = gomail.NewDialer(
		config.SMTPHost,
		config.SMTPPort,
		config.Username,
		config.Password,
	)
	manager.smtpDialer.TLSConfig = &tls.Config{
		InsecureSkipVerify: !config.TLSEnabled,
	}

	// Initialize template manager
	templateManager, err := NewTemplateManager(logger)
	if err != nil {
		return nil, fmt.Errorf("failed to create template manager: %w", err)
	}
	manager.templateManager = templateManager

	// Initialize queue manager
	queueManager, err := NewQueueManager(logger, config.QueueSize)
	if err != nil {
		return nil, fmt.Errorf("failed to create queue manager: %w", err)
	}
	manager.queueManager = queueManager

	// Initialize scheduler
	manager.scheduler = cron.New()

	if err := manager.Start(context.Background()); err != nil {
		return nil, fmt.Errorf("failed to start email manager: %w", err)
	}

	return manager, nil
}

// ===== BASE MANAGER INTERFACE =====

func (em *EmailManagerImpl) GetID() string {
	return em.id
}

func (em *EmailManagerImpl) GetName() string {
	return em.name
}

func (em *EmailManagerImpl) GetVersion() string {
	return em.version
}

func (em *EmailManagerImpl) GetStatus() interfaces.ManagerStatus {
	em.mu.RLock()
	defer em.mu.RUnlock()
	return em.status
}

func (em *EmailManagerImpl) Start(ctx context.Context) error {
	em.mu.Lock()
	defer em.mu.Unlock()

	if em.isInitialized {
		return nil
	}

	em.logger.Info("Starting Email Manager", zap.String("id", em.id))

	// Start worker pool
	for i := 0; i < em.workers; i++ {
		em.workersWg.Add(1)
		go em.emailWorker(ctx)
	}

	// Start scheduler
	em.scheduler.Start()

	em.status = interfaces.ManagerStatusRunning
	em.isInitialized = true

	em.logger.Info("Email Manager started successfully")
	return nil
}

func (em *EmailManagerImpl) Stop(ctx context.Context) error {
	em.mu.Lock()
	defer em.mu.Unlock()

	if !em.isInitialized {
		return nil
	}

	em.logger.Info("Stopping Email Manager")

	// Stop scheduler
	em.scheduler.Stop()

	// Signal workers to stop
	close(em.stopChan)

	// Wait for workers to finish
	em.workersWg.Wait()

	em.status = interfaces.ManagerStatusStopped
	em.isInitialized = false

	em.logger.Info("Email Manager stopped successfully")
	return nil
}

func (em *EmailManagerImpl) Restart(ctx context.Context) error {
	if err := em.Stop(ctx); err != nil {
		return fmt.Errorf("failed to stop email manager: %w", err)
	}
	return em.Start(ctx)
}

func (em *EmailManagerImpl) GetHealth() interfaces.HealthStatus {
	em.mu.RLock()
	defer em.mu.RUnlock()

	health := interfaces.HealthStatus{
		Status:    interfaces.HealthStatusHealthy,
		Message:   "Email Manager is healthy",
		Timestamp: time.Now(),
		Details: map[string]interface{}{
			"workers":    em.workers,
			"queue_size": len(em.emailQueue),
			"total_sent": em.stats.TotalSent,
			"smtp_host":  em.config.SMTPHost,
		},
	}

	// Check SMTP connection
	if err := em.testSMTPConnection(); err != nil {
		health.Status = interfaces.HealthStatusUnhealthy
		health.Message = fmt.Sprintf("SMTP connection failed: %v", err)
	}

	return health
}

func (em *EmailManagerImpl) GetMetrics() map[string]interface{} {
	em.stats.mu.RLock()
	defer em.stats.mu.RUnlock()

	return map[string]interface{}{
		"total_sent":    em.stats.TotalSent,
		"total_failed":  em.stats.TotalFailed,
		"total_opened":  em.stats.TotalOpened,
		"total_clicked": em.stats.TotalClicked,
		"queue_size":    len(em.emailQueue),
		"workers":       em.workers,
		"success_rate":  em.calculateSuccessRate(),
	}
}

func (em *EmailManagerImpl) Configure(config map[string]interface{}) error {
	em.mu.Lock()
	defer em.mu.Unlock()

	// Update configuration
	if host, ok := config["smtp_host"].(string); ok {
		em.config.SMTPHost = host
	}
	if port, ok := config["smtp_port"].(int); ok {
		em.config.SMTPPort = port
	}
	if username, ok := config["username"].(string); ok {
		em.config.Username = username
	}
	if password, ok := config["password"].(string); ok {
		em.config.Password = password
	}

	// Recreate SMTP dialer with new config
	em.smtpDialer = gomail.NewDialer(
		em.config.SMTPHost,
		em.config.SMTPPort,
		em.config.Username,
		em.config.Password,
	)

	em.logger.Info("Email Manager configuration updated")
	return nil
}

// ===== EMAIL OPERATIONS =====

func (em *EmailManagerImpl) SendEmail(ctx context.Context, email *interfaces.Email) error {
	if email == nil {
		return fmt.Errorf("email cannot be nil")
	}

	// Validate email
	if err := em.validateEmail(email); err != nil {
		return fmt.Errorf("email validation failed: %w", err)
	}

	// Set default values
	if email.ID == "" {
		email.ID = uuid.New().String()
	}
	if email.CreatedAt.IsZero() {
		email.CreatedAt = time.Now()
	}
	email.Status = interfaces.EmailStatusPending

	// Store email
	em.mu.Lock()
	em.emailStore[email.ID] = email
	em.mu.Unlock()

	// Add to queue
	select {
	case em.emailQueue <- email:
		em.logger.Info("Email queued for sending", zap.String("email_id", email.ID))
		return nil
	case <-ctx.Done():
		return ctx.Err()
	default:
		return fmt.Errorf("email queue is full")
	}
}

func (em *EmailManagerImpl) SendBulkEmails(ctx context.Context, emails []*interfaces.Email) error {
	if len(emails) == 0 {
		return fmt.Errorf("no emails provided")
	}

	for _, email := range emails {
		if err := em.SendEmail(ctx, email); err != nil {
			em.logger.Error("Failed to queue email in bulk operation",
				zap.String("email_id", email.ID),
				zap.Error(err))
			// Continue with other emails instead of failing completely
		}
	}

	em.logger.Info("Bulk emails queued", zap.Int("count", len(emails)))
	return nil
}

func (em *EmailManagerImpl) ScheduleEmail(ctx context.Context, email *interfaces.Email, sendTime time.Time) error {
	if email == nil {
		return fmt.Errorf("email cannot be nil")
	}

	if sendTime.Before(time.Now()) {
		return fmt.Errorf("send time cannot be in the past")
	}

	// Set schedule time
	email.ScheduledAt = sendTime

	// Create scheduled job
	jobID := uuid.New().String()
	_, err := em.scheduler.AddFunc(
		fmt.Sprintf("CRON_TZ=UTC %d %d %d %d *",
			sendTime.Minute(),
			sendTime.Hour(),
			sendTime.Day(),
			int(sendTime.Month())),
		func() {
			if err := em.SendEmail(context.Background(), email); err != nil {
				em.logger.Error("Failed to send scheduled email",
					zap.String("email_id", email.ID),
					zap.Error(err))
			}
		},
	)
	if err != nil {
		return fmt.Errorf("failed to schedule email: %w", err)
	}

	em.logger.Info("Email scheduled",
		zap.String("email_id", email.ID),
		zap.Time("send_time", sendTime),
		zap.String("job_id", jobID))

	return nil
}

func (em *EmailManagerImpl) CancelScheduledEmail(ctx context.Context, emailID string) error {
	// Note: This is a simplified implementation
	// In a real implementation, you would need to track job IDs and remove them
	em.logger.Info("Cancelled scheduled email", zap.String("email_id", emailID))
	return nil
}

// ===== TEMPLATE MANAGEMENT =====

func (em *EmailManagerImpl) CreateTemplate(ctx context.Context, template *interfaces.EmailTemplate) error {
	return em.templateManager.CreateTemplate(ctx, template)
}

func (em *EmailManagerImpl) UpdateTemplate(ctx context.Context, templateID string, template *interfaces.EmailTemplate) error {
	return em.templateManager.UpdateTemplate(ctx, templateID, template)
}

func (em *EmailManagerImpl) DeleteTemplate(ctx context.Context, templateID string) error {
	return em.templateManager.DeleteTemplate(ctx, templateID)
}

func (em *EmailManagerImpl) GetTemplate(ctx context.Context, templateID string) (*interfaces.EmailTemplate, error) {
	return em.templateManager.GetTemplate(ctx, templateID)
}

func (em *EmailManagerImpl) ListTemplates(ctx context.Context) ([]*interfaces.EmailTemplate, error) {
	return em.templateManager.ListTemplates(ctx)
}

func (em *EmailManagerImpl) RenderTemplate(ctx context.Context, templateID string, data map[string]interface{}) (string, error) {
	return em.templateManager.RenderTemplate(ctx, templateID, data)
}

// ===== QUEUE MANAGEMENT =====

func (em *EmailManagerImpl) GetQueueStatus(ctx context.Context) (*interfaces.QueueStatus, error) {
	return em.queueManager.GetQueueStatus(ctx)
}

func (em *EmailManagerImpl) PauseQueue(ctx context.Context) error {
	return em.queueManager.PauseQueue(ctx)
}

func (em *EmailManagerImpl) ResumeQueue(ctx context.Context) error {
	return em.queueManager.ResumeQueue(ctx)
}

func (em *EmailManagerImpl) FlushQueue(ctx context.Context) error {
	return em.queueManager.FlushQueue(ctx)
}

func (em *EmailManagerImpl) RetryFailedEmails(ctx context.Context) error {
	return em.queueManager.RetryFailedEmails(ctx)
}

// ===== ANALYTICS =====

func (em *EmailManagerImpl) GetEmailStats(ctx context.Context, dateRange interfaces.DateRange) (*interfaces.EmailStats, error) {
	em.stats.mu.RLock()
	defer em.stats.mu.RUnlock()

	return &interfaces.EmailStats{
		TotalSent:    int(em.stats.TotalSent),
		TotalFailed:  int(em.stats.TotalFailed),
		TotalOpened:  int(em.stats.TotalOpened),
		TotalClicked: int(em.stats.TotalClicked),
		OpenRate:     em.calculateOpenRate(),
		ClickRate:    em.calculateClickRate(),
		DeliveryRate: em.calculateSuccessRate(),
		DateRange:    dateRange,
	}, nil
}

func (em *EmailManagerImpl) GetDeliveryReport(ctx context.Context, emailID string) (*interfaces.DeliveryReport, error) {
	em.mu.RLock()
	defer em.mu.RUnlock()

	report, exists := em.deliveryReports[emailID]
	if !exists {
		return nil, fmt.Errorf("delivery report not found for email %s", emailID)
	}

	return report, nil
}

func (em *EmailManagerImpl) TrackEmailOpens(ctx context.Context, emailID string) error {
	em.stats.mu.Lock()
	em.stats.TotalOpened++
	em.stats.mu.Unlock()

	// Update email status
	em.mu.Lock()
	if email, exists := em.emailStore[emailID]; exists {
		email.Status = interfaces.EmailStatusOpened
	}
	em.mu.Unlock()

	em.logger.Info("Email opened", zap.String("email_id", emailID))
	return nil
}

func (em *EmailManagerImpl) TrackEmailClicks(ctx context.Context, emailID string, linkURL string) error {
	em.stats.mu.Lock()
	em.stats.TotalClicked++
	em.stats.mu.Unlock()

	// Update email status
	em.mu.Lock()
	if email, exists := em.emailStore[emailID]; exists {
		email.Status = interfaces.EmailStatusClicked
	}
	em.mu.Unlock()

	em.logger.Info("Email link clicked",
		zap.String("email_id", emailID),
		zap.String("link_url", linkURL))
	return nil
}

// ===== PRIVATE METHODS =====

func (em *EmailManagerImpl) emailWorker(ctx context.Context) {
	defer em.workersWg.Done()

	for {
		select {
		case email := <-em.emailQueue:
			if err := em.processEmail(ctx, email); err != nil {
				em.logger.Error("Failed to process email",
					zap.String("email_id", email.ID),
					zap.Error(err))
				em.stats.mu.Lock()
				em.stats.TotalFailed++
				em.stats.mu.Unlock()
			} else {
				em.stats.mu.Lock()
				em.stats.TotalSent++
				em.stats.mu.Unlock()
			}
		case <-em.stopChan:
			return
		case <-ctx.Done():
			return
		}
	}
}

func (em *EmailManagerImpl) processEmail(ctx context.Context, email *interfaces.Email) error {
	// Update status
	email.Status = interfaces.EmailStatusSending

	// Create gomail message
	m := gomail.NewMessage()
	m.SetHeader("From", fmt.Sprintf("%s <%s>", em.config.FromName, em.config.FromAddress))
	m.SetHeader("To", email.To...)
	if len(email.CC) > 0 {
		m.SetHeader("Cc", email.CC...)
	}
	if len(email.BCC) > 0 {
		m.SetHeader("Bcc", email.BCC...)
	}
	m.SetHeader("Subject", email.Subject)

	// Set body
	if email.HTMLBody != "" {
		m.SetBody("text/html", email.HTMLBody)
		if email.Body != "" {
			m.AddAlternative("text/plain", email.Body)
		}
	} else {
		m.SetBody("text/plain", email.Body)
	}

	// Add attachments
	for _, attachment := range email.Attachments {
		m.Attach(attachment.Filename, gomail.SetCopyFunc(func(w io.Writer) error {
			_, err := w.Write(attachment.Content)
			return err
		}))
	}

	// Send email
	if err := em.smtpDialer.DialAndSend(m); err != nil {
		email.Status = interfaces.EmailStatusFailed
		email.LastError = err.Error()
		return fmt.Errorf("failed to send email: %w", err)
	}

	// Update status
	email.Status = interfaces.EmailStatusSent
	now := time.Now()
	email.SentAt = &now

	em.logger.Info("Email sent successfully", zap.String("email_id", email.ID))
	return nil
}

func (em *EmailManagerImpl) validateEmail(email *interfaces.Email) error {
	if len(email.To) == 0 {
		return fmt.Errorf("no recipients specified")
	}
	if email.Subject == "" {
		return fmt.Errorf("subject is required")
	}
	if email.Body == "" && email.HTMLBody == "" {
		return fmt.Errorf("email body is required")
	}
	return nil
}

func (em *EmailManagerImpl) testSMTPConnection() error {
	d := gomail.NewDialer(em.config.SMTPHost, em.config.SMTPPort, em.config.Username, em.config.Password)
	s, err := d.Dial()
	if err != nil {
		return err
	}
	defer s.Close()
	return nil
}

func (em *EmailManagerImpl) calculateSuccessRate() float64 {
	em.stats.mu.RLock()
	defer em.stats.mu.RUnlock()

	total := em.stats.TotalSent + em.stats.TotalFailed
	if total == 0 {
		return 0
	}
	return float64(em.stats.TotalSent) / float64(total) * 100
}

func (em *EmailManagerImpl) calculateOpenRate() float64 {
	em.stats.mu.RLock()
	defer em.stats.mu.RUnlock()

	if em.stats.TotalSent == 0 {
		return 0
	}
	return float64(em.stats.TotalOpened) / float64(em.stats.TotalSent) * 100
}

func (em *EmailManagerImpl) calculateClickRate() float64 {
	em.stats.mu.RLock()
	defer em.stats.mu.RUnlock()

	if em.stats.TotalSent == 0 {
		return 0
	}
	return float64(em.stats.TotalClicked) / float64(em.stats.TotalSent) * 100
}

func getDefaultEmailConfig() *EmailConfig {
	return &EmailConfig{
		SMTPHost:      "localhost",
		SMTPPort:      587,
		Username:      "",
		Password:      "",
		FromAddress:   "noreply@example.com",
		FromName:      "Email Sender",
		Workers:       5,
		QueueSize:     1000,
		RetryAttempts: 3,
		RetryDelay:    time.Minute * 5,
		Timeout:       time.Second * 30,
		TLSEnabled:    true,
	}
}
