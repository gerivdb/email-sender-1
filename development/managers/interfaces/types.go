package interfaces

import (
	"time"
)

// Status constants pour les managers
const (
	StatusStarting = "starting"
	StatusError    = "error"
	StatusRunning  = "running"
	StatusStopping = "stopping"
	StatusStopped  = "stopped"
)

// ManagerStatus représente l'état d'un manager
type ManagerStatus string

// DependencyConflict représente un conflit de dépendance
type DependencyConflict struct {
	Type             string   `json:"type"`
	Description      string   `json:"description"`
	ConflictType     string   `json:"conflict_type"`
	AffectedPackages []string `json:"affected_packages"`
	Source           string   `json:"source"`
	PackageManager   string   `json:"package_manager"`
}

// DependencyMetadata représente les métadonnées d'une dépendance
type DependencyMetadata struct {
	Name            string            `json:"name"`
	Version         string            `json:"version"`
	Repository      string            `json:"repository"`
	License         string            `json:"license"`
	Vulnerabilities []Vulnerability   `json:"vulnerabilities"`
	LastUpdated     time.Time         `json:"last_updated"`
	Dependencies    []string          `json:"dependencies"`
	Tags            map[string]string `json:"tags"`
	Attributes      map[string]string `json:"attributes,omitempty"`
	UpdatedAt       time.Time         `json:"updated_at"`
	// Nouveaux champs requis
	Type           string `json:"type"`
	Direct         bool   `json:"direct"`
	Required       bool   `json:"required"`
	Source         string `json:"source"`
	PackageManager string `json:"package_manager"`
}

// Vulnerability représente une vulnérabilité de sécurité
type Vulnerability struct {
	Severity    string   `json:"severity"`
	Description string   `json:"description"`
	CVEIDs      []string `json:"cve_ids,omitempty"`
}

// SystemMetrics pour le monitoring
type SystemMetrics struct {
	Timestamp    time.Time `json:"timestamp"`
	CPUUsage     float64   `json:"cpu_usage"`
	MemoryUsage  float64   `json:"memory_usage"`
	DiskUsage    float64   `json:"disk_usage"`
	NetworkIn    int64     `json:"network_in"`
	NetworkOut   int64     `json:"network_out"`
	ErrorCount   int64     `json:"error_count"`
	RequestCount int64     `json:"request_count"`
}

// VulnerabilityReport pour les analyses de sécurité
type VulnerabilityReport struct {
	TotalScanned         int                           `json:"total_scanned"`
	VulnerabilitiesFound int                           `json:"vulnerabilities_found"`
	Timestamp            time.Time                     `json:"timestamp"`
	Details              map[string]*VulnerabilityInfo `json:"details"`
}

// VulnerabilityInfo détails d'une vulnérabilité
type VulnerabilityInfo struct {
	Severity    string   `json:"severity"`
	Description string   `json:"description"`
	CVEIDs      []string `json:"cve_ids,omitempty"`
}

// OperationMetrics pour le monitoring des opérations
type OperationMetrics struct {
	OperationName string        `json:"operation_name"`
	StartTime     time.Time     `json:"start_time"`
	Duration      time.Duration `json:"duration"`
	Status        string        `json:"status"`
	ErrorMessage  string        `json:"error_message,omitempty"`
}

// DependencyAnalysis résultat de l'analyse des dépendances
type DependencyAnalysis struct {
	ProjectPath         string                  `json:"project_path"`
	TotalDependencies    int                    `json:"total_dependencies"`
	DirectDependencies   []DependencyMetadata    `json:"direct_dependencies"`
	TransitiveDependencies []DependencyMetadata  `json:"transitive_dependencies"`
	Conflicts           []DependencyConflict    `json:"conflicts"`
	Vulnerabilities     []Vulnerability         `json:"vulnerabilities"`
	AnalyzedAt          time.Time               `json:"analyzed_at"`
}

// ResolutionResult résultat de la résolution de dépendances
type ResolutionResult struct {
	Success           bool                   `json:"success"`
	ResolvedPackages  []ResolvedPackage      `json:"resolved_packages"`
	Conflicts         []DependencyConflict   `json:"conflicts"`
	Errors            []string               `json:"errors"`
	ResolutionTime    time.Duration          `json:"resolution_time"`
}

// ResolvedPackage package résolu
type ResolvedPackage struct {
	Name             string                 `json:"name"`
	Version          string                 `json:"version"`
	Source           string                 `json:"source"`
	Dependencies     []string               `json:"dependencies"`
	Metadata         map[string]interface{} `json:"metadata"`
}

// DependencyUpdate mise à jour de dépendance disponible
type DependencyUpdate struct {
	Name            string `json:"name"`
	CurrentVersion  string `json:"current_version"`
	LatestVersion   string `json:"latest_version"`
	UpdateType      string `json:"update_type"` // major, minor, patch
	BreakingChange  bool   `json:"breaking_change"`
}

// ValidationResult résultat de validation des dépendances
type ValidationResult struct {
	Valid            bool     `json:"valid"`
	Errors           []string `json:"errors"`
	Warnings         []string `json:"warnings"`
	MissingPackages  []string `json:"missing_packages"`
	ValidatedAt      time.Time `json:"validated_at"`
}

// ===== PHASE 3 TYPES =====

// ===== EMAIL MANAGER TYPES =====

// Email représente un email à envoyer
type Email struct {
	ID          string            `json:"id"`
	From        string            `json:"from"`
	To          []string          `json:"to"`
	CC          []string          `json:"cc,omitempty"`
	BCC         []string          `json:"bcc,omitempty"`
	Subject     string            `json:"subject"`
	Body        string            `json:"body"`
	HTMLBody    string            `json:"html_body,omitempty"`
	Attachments []*Attachment     `json:"attachments,omitempty"`
	Headers     map[string]string `json:"headers,omitempty"`
	Priority    EmailPriority     `json:"priority"`
	TemplateID  string            `json:"template_id,omitempty"`
	TemplateData map[string]interface{} `json:"template_data,omitempty"`
	ScheduledAt time.Time         `json:"scheduled_at,omitempty"`
	Status      EmailStatus       `json:"status"`
	CreatedAt   time.Time         `json:"created_at"`
	SentAt      *time.Time        `json:"sent_at,omitempty"`
	RetryCount  int               `json:"retry_count"`
	LastError   string            `json:"last_error,omitempty"`
}

// EmailTemplate représente un template d'email
type EmailTemplate struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	Subject     string            `json:"subject"`
	Body        string            `json:"body"`
	HTMLBody    string            `json:"html_body,omitempty"`
	Variables   []string          `json:"variables"`
	Category    string            `json:"category"`
	Description string            `json:"description"`
	IsActive    bool              `json:"is_active"`
	CreatedAt   time.Time         `json:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at"`
}

// Attachment représente une pièce jointe
type Attachment struct {
	Filename    string `json:"filename"`
	Content     []byte `json:"content"`
	ContentType string `json:"content_type"`
	Size        int64  `json:"size"`
}

// QueueStatus représente le statut de la file d'attente
type QueueStatus struct {
	Size      int                `json:"size"`
	Status    QueueState         `json:"status"`
	Processing int               `json:"processing"`
	Failed    int                `json:"failed"`
	Retries   int                `json:"retries"`
	LastProcessed *time.Time     `json:"last_processed,omitempty"`
	Stats     *QueueStats        `json:"stats,omitempty"`
}

// QueueStats représente les statistiques de la file
type QueueStats struct {
	TotalProcessed int     `json:"total_processed"`
	TotalFailed    int     `json:"total_failed"`
	AverageProcessingTime float64 `json:"average_processing_time"`
	SuccessRate    float64 `json:"success_rate"`
}

// EmailStats représente les statistiques d'emails
type EmailStats struct {
	TotalSent     int     `json:"total_sent"`
	TotalFailed   int     `json:"total_failed"`
	TotalOpened   int     `json:"total_opened"`
	TotalClicked  int     `json:"total_clicked"`
	OpenRate      float64 `json:"open_rate"`
	ClickRate     float64 `json:"click_rate"`
	BounceRate    float64 `json:"bounce_rate"`
	DeliveryRate  float64 `json:"delivery_rate"`
	DateRange     DateRange `json:"date_range"`
}

// DeliveryReport représente un rapport de livraison
type DeliveryReport struct {
	EmailID     string      `json:"email_id"`
	Status      EmailStatus `json:"status"`
	DeliveredAt *time.Time  `json:"delivered_at,omitempty"`
	OpenedAt    *time.Time  `json:"opened_at,omitempty"`
	ClickedAt   *time.Time  `json:"clicked_at,omitempty"`
	BouncedAt   *time.Time  `json:"bounced_at,omitempty"`
	BounceReason string     `json:"bounce_reason,omitempty"`
	Events      []*EmailEvent `json:"events"`
}

// EmailEvent représente un événement d'email
type EmailEvent struct {
	Type      EmailEventType `json:"type"`
	Timestamp time.Time      `json:"timestamp"`
	Data      map[string]interface{} `json:"data,omitempty"`
}

// ===== NOTIFICATION MANAGER TYPES =====

// Notification représente une notification
type Notification struct {
	ID          string                 `json:"id"`
	Title       string                 `json:"title"`
	Message     string                 `json:"message"`
	Channels    []string               `json:"channels"`
	Priority    NotificationPriority   `json:"priority"`
	Type        NotificationType       `json:"type"`
	Data        map[string]interface{} `json:"data,omitempty"`
	Recipients  []string               `json:"recipients"`
	ScheduledAt *time.Time             `json:"scheduled_at,omitempty"`
	Status      NotificationStatus     `json:"status"`
	CreatedAt   time.Time              `json:"created_at"`
	SentAt      *time.Time             `json:"sent_at,omitempty"`
	RetryCount  int                    `json:"retry_count"`
	LastError   string                 `json:"last_error,omitempty"`
}

// NotificationChannel représente un canal de notification
type NotificationChannel struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Type        ChannelType            `json:"type"`
	Config      map[string]interface{} `json:"config"`
	IsActive    bool                   `json:"is_active"`
	Description string                 `json:"description"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`
	LastUsed    *time.Time             `json:"last_used,omitempty"`
}

// Alert représente une alerte
type Alert struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Description string                 `json:"description"`
	Conditions  []*AlertCondition      `json:"conditions"`
	Actions     []*AlertAction         `json:"actions"`
	IsActive    bool                   `json:"is_active"`
	Severity    AlertSeverity          `json:"severity"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`
	LastTriggered *time.Time           `json:"last_triggered,omitempty"`
}

// AlertCondition représente une condition d'alerte
type AlertCondition struct {
	Type      string      `json:"type"`
	Operator  string      `json:"operator"`
	Value     interface{} `json:"value"`
	Threshold interface{} `json:"threshold,omitempty"`
}

// AlertAction représente une action d'alerte
type AlertAction struct {
	Type     string                 `json:"type"`
	Channels []string               `json:"channels"`
	Template string                 `json:"template,omitempty"`
	Data     map[string]interface{} `json:"data,omitempty"`
}

// AlertEvent représente un événement d'alerte
type AlertEvent struct {
	ID          string                 `json:"id"`
	AlertID     string                 `json:"alert_id"`
	Type        AlertEventType         `json:"type"`
	Timestamp   time.Time              `json:"timestamp"`
	Data        map[string]interface{} `json:"data,omitempty"`
	Resolved    bool                   `json:"resolved"`
	ResolvedAt  *time.Time             `json:"resolved_at,omitempty"`
}

// NotificationStats représente les statistiques de notifications
type NotificationStats struct {
	TotalSent     int       `json:"total_sent"`
	TotalFailed   int       `json:"total_failed"`
	TotalDelivered int      `json:"total_delivered"`
	SuccessRate   float64   `json:"success_rate"`
	ByChannel     map[string]int `json:"by_channel"`
	ByType        map[string]int `json:"by_type"`
	DateRange     DateRange `json:"date_range"`
}

// ChannelPerformance représente les performances d'un canal
type ChannelPerformance struct {
	ChannelID     string    `json:"channel_id"`
	TotalSent     int       `json:"total_sent"`
	TotalFailed   int       `json:"total_failed"`
	SuccessRate   float64   `json:"success_rate"`
	AverageDelay  float64   `json:"average_delay"`
	LastUsed      *time.Time `json:"last_used,omitempty"`
}

// ===== INTEGRATION MANAGER TYPES =====

// Integration représente une intégration externe
type Integration struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Type        IntegrationType        `json:"type"`
	Config      map[string]interface{} `json:"config"`
	Status      IntegrationStatus      `json:"status"`
	Description string                 `json:"description"`
	IsActive    bool                   `json:"is_active"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`
	LastSync    *time.Time             `json:"last_sync,omitempty"`
}

// APIEndpoint représente un endpoint d'API
type APIEndpoint struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	URL         string                 `json:"url"`
	Method      string                 `json:"method"`
	Headers     map[string]string      `json:"headers,omitempty"`
	Auth        *APIAuth               `json:"auth,omitempty"`
	Timeout     time.Duration          `json:"timeout"`
	RetryCount  int                    `json:"retry_count"`
	IsActive    bool                   `json:"is_active"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`
	LastCalled  *time.Time             `json:"last_called,omitempty"`
}

// APIAuth représente l'authentification d'API
type APIAuth struct {
	Type   string                 `json:"type"`
	Config map[string]interface{} `json:"config"`
}

// APIRequest représente une requête d'API
type APIRequest struct {
	Body    interface{}       `json:"body,omitempty"`
	Headers map[string]string `json:"headers,omitempty"`
	Params  map[string]string `json:"params,omitempty"`
}

// APIResponse représente une réponse d'API
type APIResponse struct {
	StatusCode int                    `json:"status_code"`
	Body       interface{}            `json:"body"`
	Headers    map[string]string      `json:"headers"`
	Duration   time.Duration          `json:"duration"`
	Timestamp  time.Time              `json:"timestamp"`
}

// APIStatus représente le statut d'une API
type APIStatus struct {
	IsAvailable   bool          `json:"is_available"`
	LastCheck     time.Time     `json:"last_check"`
	ResponseTime  time.Duration `json:"response_time"`
	ErrorCount    int           `json:"error_count"`
	SuccessCount  int           `json:"success_count"`
	SuccessRate   float64       `json:"success_rate"`
}

// APIConfig représente la configuration d'une API
type APIConfig struct {
	BaseURL     string                 `json:"base_url"`
	Auth        *APIAuth               `json:"auth,omitempty"`
	Headers     map[string]string      `json:"headers,omitempty"`
	Timeout     time.Duration          `json:"timeout"`
	RetryCount  int                    `json:"retry_count"`
	RateLimit   *RateLimit             `json:"rate_limit,omitempty"`
}

// RateLimit représente les limites de taux
type RateLimit struct {
	RequestsPerSecond int           `json:"requests_per_second"`
	BurstSize         int           `json:"burst_size"`
	Period            time.Duration `json:"period"`
}

// SyncJob représente un travail de synchronisation
type SyncJob struct {
	ID            string                 `json:"id"`
	Name          string                 `json:"name"`
	SourceID      string                 `json:"source_id"`
	TargetID      string                 `json:"target_id"`
	Type          SyncType               `json:"type"`
	Schedule      string                 `json:"schedule,omitempty"`
	Config        map[string]interface{} `json:"config"`
	Status        SyncStatus             `json:"status"`
	IsActive      bool                   `json:"is_active"`
	CreatedAt     time.Time              `json:"created_at"`
	UpdatedAt     time.Time              `json:"updated_at"`
	LastRun       *time.Time             `json:"last_run,omitempty"`
	NextRun       *time.Time             `json:"next_run,omitempty"`
}

// SyncStatus représente le statut de synchronisation
type SyncStatus struct {
	Status        SyncState             `json:"status"`
	Progress      float64               `json:"progress"`
	StartedAt     *time.Time            `json:"started_at,omitempty"`
	CompletedAt   *time.Time            `json:"completed_at,omitempty"`
	RecordsTotal  int                   `json:"records_total"`
	RecordsSync   int                   `json:"records_synced"`
	RecordsFailed int                   `json:"records_failed"`
	LastError     string                `json:"last_error,omitempty"`
	Metrics       map[string]interface{} `json:"metrics,omitempty"`
}

// SyncEvent représente un événement de synchronisation
type SyncEvent struct {
	ID        string                 `json:"id"`
	SyncJobID string                 `json:"sync_job_id"`
	Type      SyncEventType          `json:"type"`
	Timestamp time.Time              `json:"timestamp"`
	Data      map[string]interface{} `json:"data,omitempty"`
	Status    string                 `json:"status"`
	Message   string                 `json:"message,omitempty"`
}

// Webhook représente un webhook
type Webhook struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	URL         string                 `json:"url"`
	Secret      string                 `json:"secret,omitempty"`
	Events      []string               `json:"events"`
	Headers     map[string]string      `json:"headers,omitempty"`
	IsActive    bool                   `json:"is_active"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`
	LastCalled  *time.Time             `json:"last_called,omitempty"`
}

// WebhookLog représente un log de webhook
type WebhookLog struct {
	ID           string    `json:"id"`
	WebhookID    string    `json:"webhook_id"`
	Event        string    `json:"event"`
	Payload      []byte    `json:"payload"`
	Response     string    `json:"response,omitempty"`
	StatusCode   int       `json:"status_code"`
	Duration     time.Duration `json:"duration"`
	Timestamp    time.Time `json:"timestamp"`
	Success      bool      `json:"success"`
	ErrorMessage string    `json:"error_message,omitempty"`
}

// DataTransformation représente une transformation de données
type DataTransformation struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	Type        TransformationType     `json:"type"`
	Config      map[string]interface{} `json:"config"`
	Script      string                 `json:"script,omitempty"`
	IsActive    bool                   `json:"is_active"`
	CreatedAt   time.Time              `json:"created_at"`
	UpdatedAt   time.Time              `json:"updated_at"`
}

// DateRange représente une plage de dates
type DateRange struct {
	From time.Time `json:"from"`
	To   time.Time `json:"to"`
}

// ===== ENUMS =====

// EmailPriority représente la priorité d'un email
type EmailPriority string

const (
	EmailPriorityLow    EmailPriority = "low"
	EmailPriorityNormal EmailPriority = "normal"
	EmailPriorityHigh   EmailPriority = "high"
	EmailPriorityUrgent EmailPriority = "urgent"
)

// EmailStatus représente le statut d'un email
type EmailStatus string

const (
	EmailStatusPending   EmailStatus = "pending"
	EmailStatusSending   EmailStatus = "sending"
	EmailStatusSent      EmailStatus = "sent"
	EmailStatusDelivered EmailStatus = "delivered"
	EmailStatusFailed    EmailStatus = "failed"
	EmailStatusBounced   EmailStatus = "bounced"
	EmailStatusOpened    EmailStatus = "opened"
	EmailStatusClicked   EmailStatus = "clicked"
)

// EmailEventType représente le type d'événement d'email
type EmailEventType string

const (
	EmailEventSent      EmailEventType = "sent"
	EmailEventDelivered EmailEventType = "delivered"
	EmailEventOpened    EmailEventType = "opened"
	EmailEventClicked   EmailEventType = "clicked"
	EmailEventBounced   EmailEventType = "bounced"
	EmailEventFailed    EmailEventType = "failed"
)

// QueueState représente l'état de la file d'attente
type QueueState string

const (
	QueueStateActive  QueueState = "active"
	QueueStatePaused  QueueState = "paused"
	QueueStateStopped QueueState = "stopped"
)

// NotificationPriority représente la priorité d'une notification
type NotificationPriority string

const (
	NotificationPriorityLow      NotificationPriority = "low"
	NotificationPriorityNormal   NotificationPriority = "normal"
	NotificationPriorityHigh     NotificationPriority = "high"
	NotificationPriorityCritical NotificationPriority = "critical"
)

// NotificationType représente le type de notification
type NotificationType string

const (
	NotificationTypeInfo    NotificationType = "info"
	NotificationTypeWarning NotificationType = "warning"
	NotificationTypeError   NotificationType = "error"
	NotificationTypeSuccess NotificationType = "success"
	NotificationTypeAlert   NotificationType = "alert"
)

// NotificationStatus représente le statut d'une notification
type NotificationStatus string

const (
	NotificationStatusPending   NotificationStatus = "pending"
	NotificationStatusSending   NotificationStatus = "sending"
	NotificationStatusSent      NotificationStatus = "sent"
	NotificationStatusDelivered NotificationStatus = "delivered"
	NotificationStatusFailed    NotificationStatus = "failed"
)

// ChannelType représente le type de canal
type ChannelType string

const (
	ChannelTypeSlack    ChannelType = "slack"
	ChannelTypeDiscord  ChannelType = "discord"
	ChannelTypeWebhook  ChannelType = "webhook"
	ChannelTypeEmail    ChannelType = "email"
	ChannelTypeSMS      ChannelType = "sms"
	ChannelTypePush     ChannelType = "push"
	ChannelTypeTeams    ChannelType = "teams"
)

// AlertSeverity représente la sévérité d'une alerte
type AlertSeverity string

const (
	AlertSeverityInfo     AlertSeverity = "info"
	AlertSeverityWarning  AlertSeverity = "warning"
	AlertSeverityError    AlertSeverity = "error"
	AlertSeverityCritical AlertSeverity = "critical"
)

// AlertEventType représente le type d'événement d'alerte
type AlertEventType string

const (
	AlertEventTriggered AlertEventType = "triggered"
	AlertEventResolved  AlertEventType = "resolved"
	AlertEventEscalated AlertEventType = "escalated"
)

// IntegrationType représente le type d'intégration
type IntegrationType string

const (
	IntegrationTypeAPI      IntegrationType = "api"
	IntegrationTypeDatabase IntegrationType = "database"
	IntegrationTypeFile     IntegrationType = "file"
	IntegrationTypeWebhook  IntegrationType = "webhook"
	IntegrationTypeQueue    IntegrationType = "queue"
	IntegrationTypeStream   IntegrationType = "stream"
)

// IntegrationStatus représente le statut d'intégration
type IntegrationStatus string

const (
	IntegrationStatusActive    IntegrationStatus = "active"
	IntegrationStatusInactive  IntegrationStatus = "inactive"
	IntegrationStatusError     IntegrationStatus = "error"
	IntegrationStatusSyncing   IntegrationStatus = "syncing"
)

// SyncType représente le type de synchronisation
type SyncType string

const (
	SyncTypeOneWay    SyncType = "one_way"
	SyncTypeTwoWay    SyncType = "two_way"
	SyncTypeBidirect  SyncType = "bidirectional"
	SyncTypeIncremental SyncType = "incremental"
	SyncTypeFull      SyncType = "full"
)

// SyncState représente l'état de synchronisation
type SyncState string

const (
	SyncStateIdle       SyncState = "idle"
	SyncStateRunning    SyncState = "running"
	SyncStateCompleted  SyncState = "completed"
	SyncStateFailed     SyncState = "failed"
	SyncStatePaused     SyncState = "paused"
	SyncStateCancelled  SyncState = "cancelled"
)

// SyncEventType représente le type d'événement de synchronisation
type SyncEventType string

const (
	SyncEventStarted   SyncEventType = "started"
	SyncEventProgress  SyncEventType = "progress"
	SyncEventCompleted SyncEventType = "completed"
	SyncEventFailed    SyncEventType = "failed"
	SyncEventPaused    SyncEventType = "paused"
	SyncEventResumed   SyncEventType = "resumed"
)

// TransformationType représente le type de transformation
type TransformationType string

const (
	TransformationTypeScript TransformationType = "script"
	TransformationTypeMapping TransformationType = "mapping"
	TransformationTypeFilter TransformationType = "filter"
	TransformationTypeAggregate TransformationType = "aggregate"
	TransformationTypeCustom TransformationType = "custom"
)
