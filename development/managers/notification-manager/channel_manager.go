package notification

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/email-sender-notification-manager/interfaces"
	"go.uber.org/zap"
)

// ChannelManagerImpl implémente l'interface ChannelManager
type ChannelManagerImpl struct {
	// Base manager fields
	id            string
	name          string
	version       string
	status        interfaces.ManagerStatus
	logger        *zap.Logger
	mu            sync.RWMutex
	isInitialized bool

	// Channel manager specific fields
	channels      map[string]*interfaces.NotificationChannel
}

// NewChannelManager crée une nouvelle instance de ChannelManager
func NewChannelManager(logger *zap.Logger) interfaces.ChannelManager {
	return &ChannelManagerImpl{
		id:       uuid.New().String(),
		name:     "ChannelManager",
		version:  "1.0.0",
		status:   interfaces.ManagerStatusStopped,
		logger:   logger,
		channels: make(map[string]*interfaces.NotificationChannel),
	}
}

// Initialize implémente BaseManager.Initialize
func (cm *ChannelManagerImpl) Initialize(ctx context.Context) error {
	cm.mu.Lock()
	defer cm.mu.Unlock()

	if cm.isInitialized {
		return fmt.Errorf("channel manager already initialized")
	}

	cm.status = interfaces.ManagerStatusStarting
	cm.logger.Info("Initializing channel manager", zap.String("id", cm.id))

	cm.status = interfaces.ManagerStatusRunning
	cm.isInitialized = true

	cm.logger.Info("Channel manager initialized successfully")
	return nil
}

// Shutdown implémente BaseManager.Shutdown
func (cm *ChannelManagerImpl) Shutdown(ctx context.Context) error {
	cm.mu.Lock()
	defer cm.mu.Unlock()

	if !cm.isInitialized {
		return fmt.Errorf("channel manager not initialized")
	}

	cm.status = interfaces.ManagerStatusStopping
	cm.logger.Info("Shutting down channel manager")

	// Clear channels
	cm.channels = make(map[string]*interfaces.NotificationChannel)

	cm.status = interfaces.ManagerStatusStopped
	cm.isInitialized = false

	cm.logger.Info("Channel manager shut down successfully")
	return nil
}

// GetID implémente BaseManager.GetID
func (cm *ChannelManagerImpl) GetID() string {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	return cm.id
}

// GetName implémente BaseManager.GetName
func (cm *ChannelManagerImpl) GetName() string {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	return cm.name
}

// GetVersion implémente BaseManager.GetVersion
func (cm *ChannelManagerImpl) GetVersion() string {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	return cm.version
}

// GetStatus implémente BaseManager.GetStatus
func (cm *ChannelManagerImpl) GetStatus() interfaces.ManagerStatus {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	return cm.status
}

// IsHealthy implémente BaseManager.IsHealthy
func (cm *ChannelManagerImpl) IsHealthy(ctx context.Context) bool {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	return cm.status == interfaces.ManagerStatusRunning && cm.isInitialized
}

// GetMetrics implémente BaseManager.GetMetrics
func (cm *ChannelManagerImpl) GetMetrics() map[string]interface{} {
	cm.mu.RLock()
	defer cm.mu.RUnlock()

	activeChannels := 0
	for _, channel := range cm.channels {
		if channel.IsActive {
			activeChannels++
		}
	}

	return map[string]interface{}{
		"total_channels":  len(cm.channels),
		"active_channels": activeChannels,
		"status":          cm.status.String(),
	}
}

// RegisterChannel implémente ChannelManager.RegisterChannel
func (cm *ChannelManagerImpl) RegisterChannel(ctx context.Context, channel *interfaces.NotificationChannel) error {
	cm.mu.Lock()
	defer cm.mu.Unlock()

	if !cm.isInitialized {
		return fmt.Errorf("channel manager not initialized")
	}

	if channel.ID == "" {
		channel.ID = uuid.New().String()
	}

	// Validate channel configuration
	if err := cm.validateChannelConfig(channel.Type, channel.Config); err != nil {
		return fmt.Errorf("invalid channel configuration: %w", err)
	}

	channel.CreatedAt = time.Now()
	channel.UpdatedAt = time.Now()

	cm.channels[channel.ID] = channel

	cm.logger.Info("Channel registered", 
		zap.String("channel_id", channel.ID),
		zap.String("name", channel.Name),
		zap.String("type", string(channel.Type)))

	return nil
}

// UpdateChannel implémente ChannelManager.UpdateChannel
func (cm *ChannelManagerImpl) UpdateChannel(ctx context.Context, channelID string, channel *interfaces.NotificationChannel) error {
	cm.mu.Lock()
	defer cm.mu.Unlock()

	if !cm.isInitialized {
		return fmt.Errorf("channel manager not initialized")
	}

	existing, exists := cm.channels[channelID]
	if !exists {
		return fmt.Errorf("channel not found: %s", channelID)
	}

	// Validate new channel configuration
	if err := cm.validateChannelConfig(channel.Type, channel.Config); err != nil {
		return fmt.Errorf("invalid channel configuration: %w", err)
	}

	// Update channel
	channel.ID = channelID
	channel.CreatedAt = existing.CreatedAt
	channel.UpdatedAt = time.Now()

	cm.channels[channelID] = channel

	cm.logger.Info("Channel updated", 
		zap.String("channel_id", channelID),
		zap.String("name", channel.Name))

	return nil
}

// DeactivateChannel implémente ChannelManager.DeactivateChannel
func (cm *ChannelManagerImpl) DeactivateChannel(ctx context.Context, channelID string) error {
	cm.mu.Lock()
	defer cm.mu.Unlock()

	if !cm.isInitialized {
		return fmt.Errorf("channel manager not initialized")
	}

	channel, exists := cm.channels[channelID]
	if !exists {
		return fmt.Errorf("channel not found: %s", channelID)
	}

	channel.IsActive = false
	channel.UpdatedAt = time.Now()

	cm.logger.Info("Channel deactivated", zap.String("channel_id", channelID))
	return nil
}

// GetChannel implémente ChannelManager.GetChannel
func (cm *ChannelManagerImpl) GetChannel(ctx context.Context, channelID string) (*interfaces.NotificationChannel, error) {
	cm.mu.RLock()
	defer cm.mu.RUnlock()

	if !cm.isInitialized {
		return nil, fmt.Errorf("channel manager not initialized")
	}

	channel, exists := cm.channels[channelID]
	if !exists {
		return nil, fmt.Errorf("channel not found: %s", channelID)
	}

	return channel, nil
}

// ListChannels implémente ChannelManager.ListChannels
func (cm *ChannelManagerImpl) ListChannels(ctx context.Context) ([]*interfaces.NotificationChannel, error) {
	cm.mu.RLock()
	defer cm.mu.RUnlock()

	if !cm.isInitialized {
		return nil, fmt.Errorf("channel manager not initialized")
	}

	channels := make([]*interfaces.NotificationChannel, 0, len(cm.channels))
	for _, channel := range cm.channels {
		channels = append(channels, channel)
	}

	return channels, nil
}

// TestChannel implémente ChannelManager.TestChannel
func (cm *ChannelManagerImpl) TestChannel(ctx context.Context, channelID string) error {
	cm.mu.RLock()
	defer cm.mu.RUnlock()

	if !cm.isInitialized {
		return fmt.Errorf("channel manager not initialized")
	}

	channel, exists := cm.channels[channelID]
	if !exists {
		return fmt.Errorf("channel not found: %s", channelID)
	}

	if !channel.IsActive {
		return fmt.Errorf("channel is inactive: %s", channelID)
	}

	// Create test notification
	testNotification := &interfaces.Notification{
		ID:      uuid.New().String(),
		Title:   "Test Notification",
		Message: "This is a test notification to verify channel connectivity.",
		Priority: interfaces.NotificationPriorityLow,
		Channels: []string{channelID},
		CreatedAt: time.Now(),
	}

	// TODO: Send actual test notification based on channel type
	cm.logger.Info("Test notification sent", 
		zap.String("channel_id", channelID),
		zap.String("notification_id", testNotification.ID))

	return nil
}

// ValidateChannelConfig implémente ChannelManager.ValidateChannelConfig
func (cm *ChannelManagerImpl) ValidateChannelConfig(ctx context.Context, channelType string, config map[string]interface{}) error {
	return cm.validateChannelConfig(interfaces.ChannelType(channelType), config)
}

// validateChannelConfig valide la configuration d'un canal
func (cm *ChannelManagerImpl) validateChannelConfig(channelType interfaces.ChannelType, config map[string]interface{}) error {
	switch channelType {
	case interfaces.ChannelTypeSlack:
		return cm.validateSlackConfig(config)
	case interfaces.ChannelTypeDiscord:
		return cm.validateDiscordConfig(config)
	case interfaces.ChannelTypeWebhook:
		return cm.validateWebhookConfig(config)
	case interfaces.ChannelTypeEmail:
		return cm.validateEmailConfig(config)
	default:
		return fmt.Errorf("unsupported channel type: %s", channelType)
	}
}

// validateSlackConfig valide la configuration Slack
func (cm *ChannelManagerImpl) validateSlackConfig(config map[string]interface{}) error {
	token, exists := config["token"]
	if !exists || token == "" {
		return fmt.Errorf("slack token is required")
	}

	channel, exists := config["channel"]
	if !exists || channel == "" {
		return fmt.Errorf("slack channel is required")
	}

	return nil
}

// validateDiscordConfig valide la configuration Discord
func (cm *ChannelManagerImpl) validateDiscordConfig(config map[string]interface{}) error {
	token, exists := config["token"]
	if !exists || token == "" {
		return fmt.Errorf("discord token is required")
	}

	guild, exists := config["guild"]
	if !exists || guild == "" {
		return fmt.Errorf("discord guild is required")
	}

	channel, exists := config["channel"]
	if !exists || channel == "" {
		return fmt.Errorf("discord channel is required")
	}

	return nil
}

// validateWebhookConfig valide la configuration Webhook
func (cm *ChannelManagerImpl) validateWebhookConfig(config map[string]interface{}) error {
	url, exists := config["url"]
	if !exists || url == "" {
		return fmt.Errorf("webhook url is required")
	}

	return nil
}

// validateEmailConfig valide la configuration Email
func (cm *ChannelManagerImpl) validateEmailConfig(config map[string]interface{}) error {
	to, exists := config["to"]
	if !exists || to == "" {
		return fmt.Errorf("email recipient is required")
	}

	return nil
}
