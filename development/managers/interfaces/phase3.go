package interfaces

import (
	"context"
	"time"
)

// ===== EMAIL MANAGER INTERFACES =====

// EmailManager interface pour la gestion complète des emails
type EmailManager interface {
	BaseManager
	
	// Email operations
	SendEmail(ctx context.Context, email *Email) error
	SendBulkEmails(ctx context.Context, emails []*Email) error
	ScheduleEmail(ctx context.Context, email *Email, sendTime time.Time) error
	CancelScheduledEmail(ctx context.Context, emailID string) error
	
	// Template management
	CreateTemplate(ctx context.Context, template *EmailTemplate) error
	UpdateTemplate(ctx context.Context, templateID string, template *EmailTemplate) error
	DeleteTemplate(ctx context.Context, templateID string) error
	GetTemplate(ctx context.Context, templateID string) (*EmailTemplate, error)
	ListTemplates(ctx context.Context) ([]*EmailTemplate, error)
	RenderTemplate(ctx context.Context, templateID string, data map[string]interface{}) (string, error)
	
	// Queue management
	GetQueueStatus(ctx context.Context) (*QueueStatus, error)
	PauseQueue(ctx context.Context) error
	ResumeQueue(ctx context.Context) error
	FlushQueue(ctx context.Context) error
	RetryFailedEmails(ctx context.Context) error
	
	// Analytics
	GetEmailStats(ctx context.Context, dateRange DateRange) (*EmailStats, error)
	GetDeliveryReport(ctx context.Context, emailID string) (*DeliveryReport, error)
	TrackEmailOpens(ctx context.Context, emailID string) error
	TrackEmailClicks(ctx context.Context, emailID string, linkURL string) error
}

// TemplateManager interface pour la gestion des templates
type TemplateManager interface {
	BaseManager
	
	CreateTemplate(ctx context.Context, template *EmailTemplate) error
	UpdateTemplate(ctx context.Context, templateID string, template *EmailTemplate) error
	DeleteTemplate(ctx context.Context, templateID string) error
	GetTemplate(ctx context.Context, templateID string) (*EmailTemplate, error)
	ListTemplates(ctx context.Context) ([]*EmailTemplate, error)
	RenderTemplate(ctx context.Context, templateID string, data map[string]interface{}) (string, error)
	ValidateTemplate(ctx context.Context, templateContent string) error
	PreviewTemplate(ctx context.Context, templateID string, data map[string]interface{}) (string, error)
}

// QueueManager interface pour la gestion des files d'attente
type QueueManager interface {
	BaseManager
	
	EnqueueEmail(ctx context.Context, email *Email) error
	DequeueEmail(ctx context.Context) (*Email, error)
	GetQueueSize(ctx context.Context) (int, error)
	GetQueueStatus(ctx context.Context) (*QueueStatus, error)
	PauseQueue(ctx context.Context) error
	ResumeQueue(ctx context.Context) error
	FlushQueue(ctx context.Context) error
	RetryFailedEmails(ctx context.Context) error
	ScheduleEmail(ctx context.Context, email *Email, sendTime time.Time) error
}

// ===== NOTIFICATION MANAGER INTERFACES =====

// NotificationManager interface pour les notifications multi-canaux
type NotificationManager interface {
	BaseManager
	
	// Core notification operations
	SendNotification(ctx context.Context, notification *Notification) error
	SendBulkNotifications(ctx context.Context, notifications []*Notification) error
	ScheduleNotification(ctx context.Context, notification *Notification, sendTime time.Time) error
	CancelNotification(ctx context.Context, notificationID string) error
	
	// Channel management
	RegisterChannel(ctx context.Context, channel *NotificationChannel) error
	UpdateChannel(ctx context.Context, channelID string, channel *NotificationChannel) error
	DeactivateChannel(ctx context.Context, channelID string) error
	GetChannel(ctx context.Context, channelID string) (*NotificationChannel, error)
	ListChannels(ctx context.Context) ([]*NotificationChannel, error)
	TestChannel(ctx context.Context, channelID string) error
	
	// Alert management
	CreateAlert(ctx context.Context, alert *Alert) error
	UpdateAlert(ctx context.Context, alertID string, alert *Alert) error
	DeleteAlert(ctx context.Context, alertID string) error
	TriggerAlert(ctx context.Context, alertID string, data map[string]interface{}) error
	GetAlertHistory(ctx context.Context, alertID string) ([]*AlertEvent, error)
	
	// Analytics
	GetNotificationStats(ctx context.Context, dateRange DateRange) (*NotificationStats, error)
	GetChannelPerformance(ctx context.Context, channelID string) (*ChannelPerformance, error)
}

// ChannelManager interface pour la gestion des canaux
type ChannelManager interface {
	BaseManager
	
	RegisterChannel(ctx context.Context, channel *NotificationChannel) error
	UpdateChannel(ctx context.Context, channelID string, channel *NotificationChannel) error
	DeactivateChannel(ctx context.Context, channelID string) error
	GetChannel(ctx context.Context, channelID string) (*NotificationChannel, error)
	ListChannels(ctx context.Context) ([]*NotificationChannel, error)
	TestChannel(ctx context.Context, channelID string) error
	ValidateChannelConfig(ctx context.Context, channelType string, config map[string]interface{}) error
}

// AlertManager interface pour la gestion des alertes
type AlertManager interface {
	BaseManager
	
	CreateAlert(ctx context.Context, alert *Alert) error
	UpdateAlert(ctx context.Context, alertID string, alert *Alert) error
	DeleteAlert(ctx context.Context, alertID string) error
	GetAlert(ctx context.Context, alertID string) (*Alert, error)
	ListAlerts(ctx context.Context) ([]*Alert, error)
	TriggerAlert(ctx context.Context, alertID string, data map[string]interface{}) error
	GetAlertHistory(ctx context.Context, alertID string) ([]*AlertEvent, error)
	EvaluateAlertConditions(ctx context.Context) error
}

// ===== INTEGRATION MANAGER INTERFACES =====

// IntegrationManager interface pour les intégrations externes
type IntegrationManager interface {
	BaseManager
	
	// Integration management
	CreateIntegration(ctx context.Context, integration *Integration) error
	UpdateIntegration(ctx context.Context, integrationID string, integration *Integration) error
	DeleteIntegration(ctx context.Context, integrationID string) error
	GetIntegration(ctx context.Context, integrationID string) (*Integration, error)
	ListIntegrations(ctx context.Context) ([]*Integration, error)
	TestIntegration(ctx context.Context, integrationID string) error
	
	// API management
	RegisterAPI(ctx context.Context, api *APIEndpoint) error
	UpdateAPI(ctx context.Context, apiID string, api *APIEndpoint) error
	DeactivateAPI(ctx context.Context, apiID string) error
	CallAPI(ctx context.Context, apiID string, request *APIRequest) (*APIResponse, error)
	GetAPIStatus(ctx context.Context, apiID string) (*APIStatus, error)
	
	// Synchronization
	CreateSyncJob(ctx context.Context, syncJob *SyncJob) error
	StartSync(ctx context.Context, syncJobID string) error
	StopSync(ctx context.Context, syncJobID string) error
	GetSyncStatus(ctx context.Context, syncJobID string) (*SyncStatus, error)
	GetSyncHistory(ctx context.Context, syncJobID string) ([]*SyncEvent, error)
	
	// Webhooks
	RegisterWebhook(ctx context.Context, webhook *Webhook) error
	HandleWebhook(ctx context.Context, webhookID string, payload []byte) error
	GetWebhookLogs(ctx context.Context, webhookID string) ([]*WebhookLog, error)
	
	// Data transformation
	TransformData(ctx context.Context, data interface{}, transformationID string) (interface{}, error)
	RegisterTransformation(ctx context.Context, transformation *DataTransformation) error
}

// APIManager interface pour la gestion des APIs
type APIManager interface {
	BaseManager
	
	RegisterAPI(ctx context.Context, api *APIEndpoint) error
	UpdateAPI(ctx context.Context, apiID string, api *APIEndpoint) error
	DeactivateAPI(ctx context.Context, apiID string) error
	GetAPI(ctx context.Context, apiID string) (*APIEndpoint, error)
	ListAPIs(ctx context.Context) ([]*APIEndpoint, error)
	CallAPI(ctx context.Context, apiID string, request *APIRequest) (*APIResponse, error)
	GetAPIStatus(ctx context.Context, apiID string) (*APIStatus, error)
	ValidateAPIConfig(ctx context.Context, config *APIConfig) error
	MonitorAPIHealth(ctx context.Context) error
}

// SyncManager interface pour la synchronisation
type SyncManager interface {
	BaseManager
	
	CreateSyncJob(ctx context.Context, syncJob *SyncJob) error
	UpdateSyncJob(ctx context.Context, syncJobID string, syncJob *SyncJob) error
	DeleteSyncJob(ctx context.Context, syncJobID string) error
	StartSync(ctx context.Context, syncJobID string) error
	StopSync(ctx context.Context, syncJobID string) error
	GetSyncStatus(ctx context.Context, syncJobID string) (*SyncStatus, error)
	GetSyncHistory(ctx context.Context, syncJobID string) ([]*SyncEvent, error)
	ScheduleSync(ctx context.Context, syncJobID string, schedule string) error
}
