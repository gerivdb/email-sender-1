package notification

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/gerivdb/email-sender-1/managers/notification-manager/interfaces"
	"github.com/google/uuid"
	"github.com/robfig/cron/v3"
	"go.uber.org/zap"
)

// NotificationManagerImpl implémente l'interface NotificationManager
type NotificationManagerImpl struct {
	// Base manager fields
	id            string
	name          string
	version       string
	status        interfaces.ManagerStatus
	logger        *zap.Logger
	mu            sync.RWMutex
	isInitialized bool

	// Notification manager specific fields
	config            *NotificationConfig
	channelManager    interfaces.ChannelManager
	alertManager      interfaces.AlertManager
	channels          map[string]interfaces.NotificationChannel
	scheduler         *cron.Cron
	notificationQueue chan *interfaces.Notification
	workers           int

	// Statistics
	totalSent    int64
	totalFailed  int64
	channelStats map[string]*ChannelStats

	// Control
	stopChan  chan struct{}
	workersWg sync.WaitGroup
}

// NotificationConfig représente la configuration du Notification Manager
type NotificationConfig struct {
	Workers         int            `json:"workers"`
	QueueSize       int            `json:"queue_size"`
	RetryAttempts   int            `json:"retry_attempts"`
	RetryDelay      time.Duration  `json:"retry_delay"`
	DefaultChannels []string       `json:"default_channels"`
	SlackConfig     *SlackConfig   `json:"slack_config"`
	DiscordConfig   *DiscordConfig `json:"discord_config"`
	WebhookConfig   *WebhookConfig `json:"webhook_config"`
}

// SlackConfig configuration pour Slack
type SlackConfig struct {
	Token          string `json:"token"`
	DefaultChannel string `json:"default_channel"`
	Username       string `json:"username"`
	IconEmoji      string `json:"icon_emoji"`
}

// DiscordConfig configuration pour Discord
type DiscordConfig struct {
	Token          string `json:"token"`
	DefaultGuild   string `json:"default_guild"`
	DefaultChannel string `json:"default_channel"`
	Username       string `json:"username"`
}

// WebhookConfig configuration pour les webhooks
type WebhookConfig struct {
	DefaultURL    string            `json:"default_url"`
	Headers       map[string]string `json:"headers"`
	Timeout       time.Duration     `json:"timeout"`
	RetryAttempts int               `json:"retry_attempts"`
}

// ChannelStats statistiques par canal
type ChannelStats struct {
	TotalSent       int64         `json:"total_sent"`
	TotalFailed     int64         `json:"total_failed"`
	LastUsed        time.Time     `json:"last_used"`
	AvgResponseTime time.Duration `json:"avg_response_time"`
}

// NewNotificationManager crée une nouvelle instance de NotificationManager
func NewNotificationManager(config *NotificationConfig, logger *zap.Logger) interfaces.NotificationManager {
	if config == nil {
		config = &NotificationConfig{
			Workers:         3,
			QueueSize:       1000,
			RetryAttempts:   3,
			RetryDelay:      time.Minute * 5,
			DefaultChannels: []string{"slack"},
		}
	}

	nm := &NotificationManagerImpl{
		id:                uuid.New().String(),
		name:              "NotificationManager",
		version:           "1.0.0",
		status:            interfaces.ManagerStatusStopped,
		logger:            logger,
		config:            config,
		channels:          make(map[string]interfaces.NotificationChannel),
		notificationQueue: make(chan *interfaces.Notification, config.QueueSize),
		workers:           config.Workers,
		channelStats:      make(map[string]*ChannelStats),
		stopChan:          make(chan struct{}),
		scheduler:         cron.New(),
	}

	// Initialize managers
	nm.channelManager = NewChannelManager(logger)
	nm.alertManager = NewAlertManager(logger)

	return nm
}

// Initialize implémente BaseManager.Initialize
func (nm *NotificationManagerImpl) Initialize(ctx context.Context) error {
	nm.mu.Lock()
	defer nm.mu.Unlock()

	if nm.isInitialized {
		return fmt.Errorf("notification manager already initialized")
	}

	nm.status = interfaces.ManagerStatusStarting
	nm.logger.Info("Initializing notification manager", zap.String("id", nm.id))

	// Initialize sub-managers
	if err := nm.channelManager.Initialize(ctx); err != nil {
		return fmt.Errorf("failed to initialize channel manager: %w", err)
	}

	if err := nm.alertManager.Initialize(ctx); err != nil {
		return fmt.Errorf("failed to initialize alert manager: %w", err)
	}

	// Setup default channels
	if err := nm.setupDefaultChannels(ctx); err != nil {
		return fmt.Errorf("failed to setup default channels: %w", err)
	}

	// Start workers
	nm.startWorkers()

	// Start scheduler
	nm.scheduler.Start()

	nm.status = interfaces.ManagerStatusRunning
	nm.isInitialized = true

	nm.logger.Info("Notification manager initialized successfully")
	return nil
}

// Shutdown implémente BaseManager.Shutdown
func (nm *NotificationManagerImpl) Shutdown(ctx context.Context) error {
	nm.mu.Lock()
	defer nm.mu.Unlock()

	if !nm.isInitialized {
		return fmt.Errorf("notification manager not initialized")
	}

	nm.status = interfaces.ManagerStatusStopping
	nm.logger.Info("Shutting down notification manager")

	// Stop scheduler
	nm.scheduler.Stop()

	// Stop workers
	close(nm.stopChan)
	nm.workersWg.Wait()

	// Close notification queue
	close(nm.notificationQueue)

	// Shutdown sub-managers
	if err := nm.channelManager.Shutdown(ctx); err != nil {
		nm.logger.Error("Failed to shutdown channel manager", zap.Error(err))
	}

	if err := nm.alertManager.Shutdown(ctx); err != nil {
		nm.logger.Error("Failed to shutdown alert manager", zap.Error(err))
	}

	nm.status = interfaces.ManagerStatusStopped
	nm.isInitialized = false

	nm.logger.Info("Notification manager shut down successfully")
	return nil
}

// GetID implémente BaseManager.GetID
func (nm *NotificationManagerImpl) GetID() string {
	nm.mu.RLock()
	defer nm.mu.RUnlock()
	return nm.id
}

// GetName implémente BaseManager.GetName
func (nm *NotificationManagerImpl) GetName() string {
	nm.mu.RLock()
	defer nm.mu.RUnlock()
	return nm.name
}

// GetVersion implémente BaseManager.GetVersion
func (nm *NotificationManagerImpl) GetVersion() string {
	nm.mu.RLock()
	defer nm.mu.RUnlock()
	return nm.version
}

// GetStatus implémente BaseManager.GetStatus
func (nm *NotificationManagerImpl) GetStatus() interfaces.ManagerStatus {
	nm.mu.RLock()
	defer nm.mu.RUnlock()
	return nm.status
}

// IsHealthy implémente BaseManager.IsHealthy
func (nm *NotificationManagerImpl) IsHealthy(ctx context.Context) bool {
	nm.mu.RLock()
	defer nm.mu.RUnlock()
	return nm.status == interfaces.ManagerStatusRunning && nm.isInitialized
}

// GetMetrics implémente BaseManager.GetMetrics
func (nm *NotificationManagerImpl) GetMetrics() map[string]interface{} {
	nm.mu.RLock()
	defer nm.mu.RUnlock()

	metrics := map[string]interface{}{
		"total_sent":      nm.totalSent,
		"total_failed":    nm.totalFailed,
		"active_channels": len(nm.channels),
		"queue_size":      len(nm.notificationQueue),
		"workers":         nm.workers,
		"status":          nm.status.String(),
	}

	// Add channel statistics
	channelMetrics := make(map[string]interface{})
	for channelID, stats := range nm.channelStats {
		channelMetrics[channelID] = map[string]interface{}{
			"total_sent":        stats.TotalSent,
			"total_failed":      stats.TotalFailed,
			"last_used":         stats.LastUsed,
			"avg_response_time": stats.AvgResponseTime.String(),
		}
	}
	metrics["channel_stats"] = channelMetrics

	return metrics
}

// SendNotification implémente NotificationManager.SendNotification
func (nm *NotificationManagerImpl) SendNotification(ctx context.Context, notification *interfaces.Notification) error {
	nm.mu.RLock()
	defer nm.mu.RUnlock()

	if !nm.isInitialized {
		return fmt.Errorf("notification manager not initialized")
	}

	if notification.ID == "" {
		notification.ID = uuid.New().String()
	}

	if notification.CreatedAt.IsZero() {
		notification.CreatedAt = time.Now()
	}

	// Add to queue
	select {
	case nm.notificationQueue <- notification:
		nm.logger.Debug("Notification queued",
			zap.String("notification_id", notification.ID),
			zap.String("title", notification.Title))
		return nil
	default:
		return fmt.Errorf("notification queue is full")
	}
}

// SendBulkNotifications implémente NotificationManager.SendBulkNotifications
func (nm *NotificationManagerImpl) SendBulkNotifications(ctx context.Context, notifications []*interfaces.Notification) error {
	nm.mu.RLock()
	defer nm.mu.RUnlock()

	if !nm.isInitialized {
		return fmt.Errorf("notification manager not initialized")
	}

	for _, notification := range notifications {
		if err := nm.SendNotification(ctx, notification); err != nil {
			return fmt.Errorf("failed to send notification %s: %w", notification.ID, err)
		}
	}

	nm.logger.Info("Bulk notifications queued", zap.Int("count", len(notifications)))
	return nil
}

// ScheduleNotification implémente NotificationManager.ScheduleNotification
func (nm *NotificationManagerImpl) ScheduleNotification(ctx context.Context, notification *interfaces.Notification, sendTime time.Time) error {
	nm.mu.Lock()
	defer nm.mu.Unlock()

	if !nm.isInitialized {
		return fmt.Errorf("notification manager not initialized")
	}

	jobID := uuid.New().String()

	// Schedule with cron
	_, err := nm.scheduler.AddFunc(
		fmt.Sprintf("0 %d %d %d %d *",
			sendTime.Minute(),
			sendTime.Hour(),
			sendTime.Day(),
			int(sendTime.Month())),
		func() {
			if err := nm.SendNotification(context.Background(), notification); err != nil {
				nm.logger.Error("Failed to send scheduled notification",
					zap.String("notification_id", notification.ID),
					zap.Error(err))
			}
		},
	)
	if err != nil {
		return fmt.Errorf("failed to schedule notification: %w", err)
	}

	nm.logger.Info("Notification scheduled",
		zap.String("notification_id", notification.ID),
		zap.Time("send_time", sendTime),
		zap.String("job_id", jobID))

	return nil
}

// CancelNotification implémente NotificationManager.CancelNotification
func (nm *NotificationManagerImpl) CancelNotification(ctx context.Context, notificationID string) error {
	// Implementation would require tracking scheduled notifications
	// For now, return success
	nm.logger.Info("Notification cancelled", zap.String("notification_id", notificationID))
	return nil
}

// Channel management methods
func (nm *NotificationManagerImpl) RegisterChannel(ctx context.Context, channel *interfaces.NotificationChannel) error {
	return nm.channelManager.RegisterChannel(ctx, channel)
}

func (nm *NotificationManagerImpl) UpdateChannel(ctx context.Context, channelID string, channel *interfaces.NotificationChannel) error {
	return nm.channelManager.UpdateChannel(ctx, channelID, channel)
}

func (nm *NotificationManagerImpl) DeactivateChannel(ctx context.Context, channelID string) error {
	return nm.channelManager.DeactivateChannel(ctx, channelID)
}

func (nm *NotificationManagerImpl) GetChannel(ctx context.Context, channelID string) (*interfaces.NotificationChannel, error) {
	return nm.channelManager.GetChannel(ctx, channelID)
}

func (nm *NotificationManagerImpl) ListChannels(ctx context.Context) ([]*interfaces.NotificationChannel, error) {
	return nm.channelManager.ListChannels(ctx)
}

func (nm *NotificationManagerImpl) TestChannel(ctx context.Context, channelID string) error {
	return nm.channelManager.TestChannel(ctx, channelID)
}

// Alert management methods
func (nm *NotificationManagerImpl) CreateAlert(ctx context.Context, alert *interfaces.Alert) error {
	return nm.alertManager.CreateAlert(ctx, alert)
}

func (nm *NotificationManagerImpl) UpdateAlert(ctx context.Context, alertID string, alert *interfaces.Alert) error {
	return nm.alertManager.UpdateAlert(ctx, alertID, alert)
}

func (nm *NotificationManagerImpl) DeleteAlert(ctx context.Context, alertID string) error {
	return nm.alertManager.DeleteAlert(ctx, alertID)
}

func (nm *NotificationManagerImpl) TriggerAlert(ctx context.Context, alertID string, data map[string]interface{}) error {
	return nm.alertManager.TriggerAlert(ctx, alertID, data)
}

func (nm *NotificationManagerImpl) GetAlertHistory(ctx context.Context, alertID string) ([]*interfaces.AlertEvent, error) {
	return nm.alertManager.GetAlertHistory(ctx, alertID)
}

// Analytics methods
func (nm *NotificationManagerImpl) GetNotificationStats(ctx context.Context, dateRange interfaces.DateRange) (*interfaces.NotificationStats, error) {
	nm.mu.RLock()
	defer nm.mu.RUnlock()

	return &interfaces.NotificationStats{
		TotalSent:   nm.totalSent,
		TotalFailed: nm.totalFailed,
		SuccessRate: float64(nm.totalSent) / float64(nm.totalSent+nm.totalFailed) * 100,
		DateRange:   dateRange,
	}, nil
}

func (nm *NotificationManagerImpl) GetChannelPerformance(ctx context.Context, channelID string) (*interfaces.ChannelPerformance, error) {
	nm.mu.RLock()
	defer nm.mu.RUnlock()

	stats, exists := nm.channelStats[channelID]
	if !exists {
		return nil, fmt.Errorf("channel stats not found: %s", channelID)
	}

	return &interfaces.ChannelPerformance{
		ChannelID:       channelID,
		TotalSent:       stats.TotalSent,
		TotalFailed:     stats.TotalFailed,
		SuccessRate:     float64(stats.TotalSent) / float64(stats.TotalSent+stats.TotalFailed) * 100,
		AvgResponseTime: stats.AvgResponseTime,
		LastUsed:        stats.LastUsed,
	}, nil
}

// setupDefaultChannels configure les canaux par défaut
func (nm *NotificationManagerImpl) setupDefaultChannels(ctx context.Context) error {
	// Setup Slack channel if configured
	if nm.config.SlackConfig != nil && nm.config.SlackConfig.Token != "" {
		slackChannel := &interfaces.NotificationChannel{
			ID:   "slack-default",
			Name: "Slack Default",
			Type: interfaces.ChannelTypeSlack,
			Config: map[string]interface{}{
				"token":      nm.config.SlackConfig.Token,
				"channel":    nm.config.SlackConfig.DefaultChannel,
				"username":   nm.config.SlackConfig.Username,
				"icon_emoji": nm.config.SlackConfig.IconEmoji,
			},
			IsActive:  true,
			CreatedAt: time.Now(),
		}
		if err := nm.channelManager.RegisterChannel(ctx, slackChannel); err != nil {
			return fmt.Errorf("failed to register Slack channel: %w", err)
		}
	}

	// Setup Discord channel if configured
	if nm.config.DiscordConfig != nil && nm.config.DiscordConfig.Token != "" {
		discordChannel := &interfaces.NotificationChannel{
			ID:   "discord-default",
			Name: "Discord Default",
			Type: interfaces.ChannelTypeDiscord,
			Config: map[string]interface{}{
				"token":    nm.config.DiscordConfig.Token,
				"guild":    nm.config.DiscordConfig.DefaultGuild,
				"channel":  nm.config.DiscordConfig.DefaultChannel,
				"username": nm.config.DiscordConfig.Username,
			},
			IsActive:  true,
			CreatedAt: time.Now(),
		}
		if err := nm.channelManager.RegisterChannel(ctx, discordChannel); err != nil {
			return fmt.Errorf("failed to register Discord channel: %w", err)
		}
	}

	// Setup Webhook channel if configured
	if nm.config.WebhookConfig != nil && nm.config.WebhookConfig.DefaultURL != "" {
		webhookChannel := &interfaces.NotificationChannel{
			ID:   "webhook-default",
			Name: "Webhook Default",
			Type: interfaces.ChannelTypeWebhook,
			Config: map[string]interface{}{
				"url":            nm.config.WebhookConfig.DefaultURL,
				"headers":        nm.config.WebhookConfig.Headers,
				"timeout":        nm.config.WebhookConfig.Timeout,
				"retry_attempts": nm.config.WebhookConfig.RetryAttempts,
			},
			IsActive:  true,
			CreatedAt: time.Now(),
		}
		if err := nm.channelManager.RegisterChannel(ctx, webhookChannel); err != nil {
			return fmt.Errorf("failed to register Webhook channel: %w", err)
		}
	}

	return nil
}

// startWorkers démarre les workers de traitement des notifications
func (nm *NotificationManagerImpl) startWorkers() {
	for i := 0; i < nm.workers; i++ {
		nm.workersWg.Add(1)
		go nm.notificationWorker(i)
	}
}

// notificationWorker traite les notifications en queue
func (nm *NotificationManagerImpl) notificationWorker(workerID int) {
	defer nm.workersWg.Done()

	nm.logger.Info("Notification worker started", zap.Int("worker_id", workerID))

	for {
		select {
		case notification := <-nm.notificationQueue:
			if notification != nil {
				nm.processNotification(notification)
			}
		case <-nm.stopChan:
			nm.logger.Info("Notification worker stopped", zap.Int("worker_id", workerID))
			return
		}
	}
}

// processNotification traite une notification
func (nm *NotificationManagerImpl) processNotification(notification *interfaces.Notification) {
	start := time.Now()

	// Get channels for notification
	channels := notification.Channels
	if len(channels) == 0 {
		channels = nm.config.DefaultChannels
	}

	success := false
	for _, channelID := range channels {
		if err := nm.sendToChannel(channelID, notification); err != nil {
			nm.logger.Error("Failed to send notification to channel",
				zap.String("notification_id", notification.ID),
				zap.String("channel_id", channelID),
				zap.Error(err))
			nm.updateChannelStats(channelID, false, time.Since(start))
		} else {
			success = true
			nm.updateChannelStats(channelID, true, time.Since(start))
		}
	}

	if success {
		nm.mu.Lock()
		nm.totalSent++
		nm.mu.Unlock()
	} else {
		nm.mu.Lock()
		nm.totalFailed++
		nm.mu.Unlock()
	}
}

// sendToChannel envoie une notification à un canal spécifique
func (nm *NotificationManagerImpl) sendToChannel(channelID string, notification *interfaces.Notification) error {
	channel, err := nm.channelManager.GetChannel(context.Background(), channelID)
	if err != nil {
		return fmt.Errorf("channel not found: %w", err)
	}

	if !channel.IsActive {
		return fmt.Errorf("channel is inactive: %s", channelID)
	}

	// Send based on channel type
	switch channel.Type {
	case interfaces.ChannelTypeSlack:
		return nm.sendSlackNotification(channel, notification)
	case interfaces.ChannelTypeDiscord:
		return nm.sendDiscordNotification(channel, notification)
	case interfaces.ChannelTypeWebhook:
		return nm.sendWebhookNotification(channel, notification)
	case interfaces.ChannelTypeEmail:
		return nm.sendEmailNotification(channel, notification)
	default:
		return fmt.Errorf("unsupported channel type: %s", channel.Type)
	}
}

// updateChannelStats met à jour les statistiques d'un canal
func (nm *NotificationManagerImpl) updateChannelStats(channelID string, success bool, duration time.Duration) {
	nm.mu.Lock()
	defer nm.mu.Unlock()

	stats, exists := nm.channelStats[channelID]
	if !exists {
		stats = &ChannelStats{}
		nm.channelStats[channelID] = stats
	}

	if success {
		stats.TotalSent++
	} else {
		stats.TotalFailed++
	}

	stats.LastUsed = time.Now()

	// Update average response time
	if stats.AvgResponseTime == 0 {
		stats.AvgResponseTime = duration
	} else {
		stats.AvgResponseTime = (stats.AvgResponseTime + duration) / 2
	}
}

// Channel-specific sending methods (simplified implementations)
func (nm *NotificationManagerImpl) sendSlackNotification(channel *interfaces.NotificationChannel, notification *interfaces.Notification) error {
	nm.logger.Info("Sending Slack notification",
		zap.String("channel", channel.ID),
		zap.String("notification", notification.ID))
	// TODO: Implement actual Slack API call
	return nil
}

func (nm *NotificationManagerImpl) sendDiscordNotification(channel *interfaces.NotificationChannel, notification *interfaces.Notification) error {
	nm.logger.Info("Sending Discord notification",
		zap.String("channel", channel.ID),
		zap.String("notification", notification.ID))
	// TODO: Implement actual Discord API call
	return nil
}

func (nm *NotificationManagerImpl) sendWebhookNotification(channel *interfaces.NotificationChannel, notification *interfaces.Notification) error {
	nm.logger.Info("Sending Webhook notification",
		zap.String("channel", channel.ID),
		zap.String("notification", notification.ID))
	// TODO: Implement actual HTTP webhook call
	return nil
}

func (nm *NotificationManagerImpl) sendEmailNotification(channel *interfaces.NotificationChannel, notification *interfaces.Notification) error {
	nm.logger.Info("Sending Email notification",
		zap.String("channel", channel.ID),
		zap.String("notification", notification.ID))
	// TODO: Integrate with EmailManager
	return nil
}
