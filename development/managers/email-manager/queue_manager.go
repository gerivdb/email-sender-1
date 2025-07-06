package email

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/gerivdb/email-sender-1/managers/interfaces"
	"github.com/google/uuid"
	"github.com/robfig/cron/v3"
	"go.uber.org/zap"
)

// QueueManagerImpl implémente l'interface QueueManager
type QueueManagerImpl struct {
	// Base manager fields
	id            string
	name          string
	version       string
	status        interfaces.ManagerStatus
	logger        *zap.Logger
	mu            sync.RWMutex
	isInitialized bool

	// Queue manager specific fields
	emailQueue     chan *interfaces.Email
	failedQueue    []*interfaces.Email
	scheduledQueue map[string]*ScheduledEmail
	queueSize      int
	maxRetries     int
	retryDelay     time.Duration
	isPaused       bool
	scheduler      *cron.Cron

	// Statistics
	totalProcessed int64
	totalFailed    int64
	totalRetries   int64
}

// ScheduledEmail représente un email programmé
type ScheduledEmail struct {
	Email    *interfaces.Email
	SendTime time.Time
	JobID    string
}

// NewQueueManager crée une nouvelle instance de QueueManager
func NewQueueManager(logger *zap.Logger, queueSize int) interfaces.QueueManager {
	return &QueueManagerImpl{
		id:             uuid.New().String(),
		name:           "QueueManager",
		version:        "1.0.0",
		status:         interfaces.ManagerStatusStopped,
		logger:         logger,
		emailQueue:     make(chan *interfaces.Email, queueSize),
		failedQueue:    make([]*interfaces.Email, 0),
		scheduledQueue: make(map[string]*ScheduledEmail),
		queueSize:      queueSize,
		maxRetries:     3,
		retryDelay:     time.Minute * 5,
		isPaused:       false,
		scheduler:      cron.New(),
	}
}

// Initialize implémente BaseManager.Initialize
func (qm *QueueManagerImpl) Initialize(ctx context.Context) error {
	qm.mu.Lock()
	defer qm.mu.Unlock()

	if qm.isInitialized {
		return fmt.Errorf("queue manager already initialized")
	}

	qm.status = interfaces.ManagerStatusStarting
	qm.logger.Info("Initializing queue manager", zap.String("id", qm.id))

	// Start scheduler
	qm.scheduler.Start()

	qm.status = interfaces.ManagerStatusRunning
	qm.isInitialized = true

	qm.logger.Info("Queue manager initialized successfully")
	return nil
}

// Shutdown implémente BaseManager.Shutdown
func (qm *QueueManagerImpl) Shutdown(ctx context.Context) error {
	qm.mu.Lock()
	defer qm.mu.Unlock()

	if !qm.isInitialized {
		return fmt.Errorf("queue manager not initialized")
	}

	qm.status = interfaces.ManagerStatusStopping
	qm.logger.Info("Shutting down queue manager")

	// Stop scheduler
	qm.scheduler.Stop()

	// Close email queue
	close(qm.emailQueue)

	// Clear queues
	qm.failedQueue = make([]*interfaces.Email, 0)
	qm.scheduledQueue = make(map[string]*ScheduledEmail)

	qm.status = interfaces.ManagerStatusStopped
	qm.isInitialized = false

	qm.logger.Info("Queue manager shut down successfully")
	return nil
}

// GetID implémente BaseManager.GetID
func (qm *QueueManagerImpl) GetID() string {
	qm.mu.RLock()
	defer qm.mu.RUnlock()
	return qm.id
}

// GetName implémente BaseManager.GetName
func (qm *QueueManagerImpl) GetName() string {
	qm.mu.RLock()
	defer qm.mu.RUnlock()
	return qm.name
}

// GetVersion implémente BaseManager.GetVersion
func (qm *QueueManagerImpl) GetVersion() string {
	qm.mu.RLock()
	defer qm.mu.RUnlock()
	return qm.version
}

// GetStatus implémente BaseManager.GetStatus
func (qm *QueueManagerImpl) GetStatus() interfaces.ManagerStatus {
	qm.mu.RLock()
	defer qm.mu.RUnlock()
	return qm.status
}

// IsHealthy implémente BaseManager.IsHealthy
func (qm *QueueManagerImpl) IsHealthy(ctx context.Context) bool {
	qm.mu.RLock()
	defer qm.mu.RUnlock()
	return qm.status == interfaces.ManagerStatusRunning && qm.isInitialized
}

// GetMetrics implémente BaseManager.GetMetrics
func (qm *QueueManagerImpl) GetMetrics() map[string]interface{} {
	qm.mu.RLock()
	defer qm.mu.RUnlock()

	return map[string]interface{}{
		"queue_size":       len(qm.emailQueue),
		"failed_emails":    len(qm.failedQueue),
		"scheduled_emails": len(qm.scheduledQueue),
		"total_processed":  qm.totalProcessed,
		"total_failed":     qm.totalFailed,
		"total_retries":    qm.totalRetries,
		"is_paused":        qm.isPaused,
		"status":           qm.status.String(),
	}
}

// EnqueueEmail implémente QueueManager.EnqueueEmail
func (qm *QueueManagerImpl) EnqueueEmail(ctx context.Context, email *interfaces.Email) error {
	qm.mu.Lock()
	defer qm.mu.Unlock()

	if !qm.isInitialized {
		return fmt.Errorf("queue manager not initialized")
	}

	if qm.isPaused {
		return fmt.Errorf("queue is paused")
	}

	select {
	case qm.emailQueue <- email:
		qm.logger.Debug("Email enqueued",
			zap.String("email_id", email.ID),
			zap.String("to", email.To))
		return nil
	default:
		return fmt.Errorf("queue is full")
	}
}

// DequeueEmail implémente QueueManager.DequeueEmail
func (qm *QueueManagerImpl) DequeueEmail(ctx context.Context) (*interfaces.Email, error) {
	qm.mu.RLock()
	defer qm.mu.RUnlock()

	if !qm.isInitialized {
		return nil, fmt.Errorf("queue manager not initialized")
	}

	if qm.isPaused {
		return nil, fmt.Errorf("queue is paused")
	}

	select {
	case email := <-qm.emailQueue:
		if email != nil {
			qm.logger.Debug("Email dequeued",
				zap.String("email_id", email.ID),
				zap.String("to", email.To))
		}
		return email, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

// GetQueueSize implémente QueueManager.GetQueueSize
func (qm *QueueManagerImpl) GetQueueSize(ctx context.Context) (int, error) {
	qm.mu.RLock()
	defer qm.mu.RUnlock()

	if !qm.isInitialized {
		return 0, fmt.Errorf("queue manager not initialized")
	}

	return len(qm.emailQueue), nil
}

// GetQueueStatus implémente QueueManager.GetQueueStatus
func (qm *QueueManagerImpl) GetQueueStatus(ctx context.Context) (*interfaces.QueueStatus, error) {
	qm.mu.RLock()
	defer qm.mu.RUnlock()

	if !qm.isInitialized {
		return nil, fmt.Errorf("queue manager not initialized")
	}

	return &interfaces.QueueStatus{
		Size:            len(qm.emailQueue),
		FailedEmails:    len(qm.failedQueue),
		ScheduledEmails: len(qm.scheduledQueue),
		IsPaused:        qm.isPaused,
		TotalProcessed:  qm.totalProcessed,
		TotalFailed:     qm.totalFailed,
		TotalRetries:    qm.totalRetries,
	}, nil
}

// PauseQueue implémente QueueManager.PauseQueue
func (qm *QueueManagerImpl) PauseQueue(ctx context.Context) error {
	qm.mu.Lock()
	defer qm.mu.Unlock()

	if !qm.isInitialized {
		return fmt.Errorf("queue manager not initialized")
	}

	qm.isPaused = true
	qm.logger.Info("Queue paused")
	return nil
}

// ResumeQueue implémente QueueManager.ResumeQueue
func (qm *QueueManagerImpl) ResumeQueue(ctx context.Context) error {
	qm.mu.Lock()
	defer qm.mu.Unlock()

	if !qm.isInitialized {
		return fmt.Errorf("queue manager not initialized")
	}

	qm.isPaused = false
	qm.logger.Info("Queue resumed")
	return nil
}

// FlushQueue implémente QueueManager.FlushQueue
func (qm *QueueManagerImpl) FlushQueue(ctx context.Context) error {
	qm.mu.Lock()
	defer qm.mu.Unlock()

	if !qm.isInitialized {
		return fmt.Errorf("queue manager not initialized")
	}

	// Drain the queue
	count := 0
	for {
		select {
		case <-qm.emailQueue:
			count++
		default:
			goto done
		}
	}

done:
	qm.logger.Info("Queue flushed", zap.Int("emails_removed", count))
	return nil
}

// RetryFailedEmails implémente QueueManager.RetryFailedEmails
func (qm *QueueManagerImpl) RetryFailedEmails(ctx context.Context) error {
	qm.mu.Lock()
	defer qm.mu.Unlock()

	if !qm.isInitialized {
		return fmt.Errorf("queue manager not initialized")
	}

	if qm.isPaused {
		return fmt.Errorf("queue is paused")
	}

	retryCount := 0
	for i := len(qm.failedQueue) - 1; i >= 0; i-- {
		email := qm.failedQueue[i]

		// Check if email has exceeded max retries
		if email.RetryCount < qm.maxRetries {
			select {
			case qm.emailQueue <- email:
				// Remove from failed queue
				qm.failedQueue = append(qm.failedQueue[:i], qm.failedQueue[i+1:]...)
				retryCount++
				qm.totalRetries++
			default:
				// Queue is full, stop retrying
				break
			}
		}
	}

	qm.logger.Info("Failed emails retried", zap.Int("retry_count", retryCount))
	return nil
}

// ScheduleEmail implémente QueueManager.ScheduleEmail
func (qm *QueueManagerImpl) ScheduleEmail(ctx context.Context, email *interfaces.Email, sendTime time.Time) error {
	qm.mu.Lock()
	defer qm.mu.Unlock()

	if !qm.isInitialized {
		return fmt.Errorf("queue manager not initialized")
	}

	jobID := uuid.New().String()
	scheduledEmail := &ScheduledEmail{
		Email:    email,
		SendTime: sendTime,
		JobID:    jobID,
	}

	// Add to scheduled queue
	qm.scheduledQueue[jobID] = scheduledEmail

	// Schedule with cron
	_, err := qm.scheduler.AddFunc(
		fmt.Sprintf("0 %d %d %d %d *",
			sendTime.Minute(),
			sendTime.Hour(),
			sendTime.Day(),
			int(sendTime.Month())),
		func() {
			qm.executeScheduledEmail(jobID)
		},
	)
	if err != nil {
		delete(qm.scheduledQueue, jobID)
		return fmt.Errorf("failed to schedule email: %w", err)
	}

	qm.logger.Info("Email scheduled",
		zap.String("email_id", email.ID),
		zap.Time("send_time", sendTime),
		zap.String("job_id", jobID))

	return nil
}

// executeScheduledEmail exécute un email programmé
func (qm *QueueManagerImpl) executeScheduledEmail(jobID string) {
	qm.mu.Lock()
	defer qm.mu.Unlock()

	scheduledEmail, exists := qm.scheduledQueue[jobID]
	if !exists {
		qm.logger.Warn("Scheduled email not found", zap.String("job_id", jobID))
		return
	}

	// Move to main queue
	select {
	case qm.emailQueue <- scheduledEmail.Email:
		delete(qm.scheduledQueue, jobID)
		qm.logger.Info("Scheduled email moved to queue",
			zap.String("email_id", scheduledEmail.Email.ID),
			zap.String("job_id", jobID))
	default:
		qm.logger.Warn("Queue is full, scheduled email failed",
			zap.String("job_id", jobID))
	}
}

// MarkEmailFailed marque un email comme échoué
func (qm *QueueManagerImpl) MarkEmailFailed(email *interfaces.Email) {
	qm.mu.Lock()
	defer qm.mu.Unlock()

	email.RetryCount++
	qm.failedQueue = append(qm.failedQueue, email)
	qm.totalFailed++

	qm.logger.Warn("Email marked as failed",
		zap.String("email_id", email.ID),
		zap.Int("retry_count", email.RetryCount))
}

// MarkEmailProcessed marque un email comme traité
func (qm *QueueManagerImpl) MarkEmailProcessed() {
	qm.mu.Lock()
	defer qm.mu.Unlock()
	qm.totalProcessed++
}
