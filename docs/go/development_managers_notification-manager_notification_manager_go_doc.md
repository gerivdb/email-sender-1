# Package notification

## Types

### AlertConditionProcessor

AlertConditionProcessor handles condition evaluation logic


#### Methods

##### AlertConditionProcessor.EvaluateConditions

EvaluateConditions evaluates alert conditions and returns whether to trigger


```go
func (acp *AlertConditionProcessor) EvaluateConditions(conditions []*interfaces.AlertCondition) (bool, map[string]interface{}, error)
```

### AlertConfig

AlertConfig represents alert manager configuration


### AlertManagerImpl

AlertManagerImpl implémente l'interface AlertManager


#### Methods

##### AlertManagerImpl.CreateAlert

CreateAlert implémente AlertManager.CreateAlert


```go
func (am *AlertManagerImpl) CreateAlert(ctx context.Context, alert *interfaces.Alert) error
```

##### AlertManagerImpl.DeleteAlert

DeleteAlert implémente AlertManager.DeleteAlert


```go
func (am *AlertManagerImpl) DeleteAlert(ctx context.Context, alertID string) error
```

##### AlertManagerImpl.EvaluateAlertConditions

EvaluateAlertConditions implémente AlertManager.EvaluateAlertConditions


```go
func (am *AlertManagerImpl) EvaluateAlertConditions(ctx context.Context) error
```

##### AlertManagerImpl.GetAlert

GetAlert implémente AlertManager.GetAlert


```go
func (am *AlertManagerImpl) GetAlert(ctx context.Context, alertID string) (*interfaces.Alert, error)
```

##### AlertManagerImpl.GetAlertHistory

GetAlertHistory implémente AlertManager.GetAlertHistory


```go
func (am *AlertManagerImpl) GetAlertHistory(ctx context.Context, alertID string) ([]*interfaces.AlertEvent, error)
```

##### AlertManagerImpl.GetID

GetID implémente BaseManager.GetID


```go
func (am *AlertManagerImpl) GetID() string
```

##### AlertManagerImpl.GetMetrics

GetMetrics implémente BaseManager.GetMetrics


```go
func (am *AlertManagerImpl) GetMetrics() map[string]interface{}
```

##### AlertManagerImpl.GetName

GetName implémente BaseManager.GetName


```go
func (am *AlertManagerImpl) GetName() string
```

##### AlertManagerImpl.GetStatus

GetStatus implémente BaseManager.GetStatus


```go
func (am *AlertManagerImpl) GetStatus() interfaces.ManagerStatus
```

##### AlertManagerImpl.GetVersion

GetVersion implémente BaseManager.GetVersion


```go
func (am *AlertManagerImpl) GetVersion() string
```

##### AlertManagerImpl.Initialize

Initialize implémente BaseManager.Initialize


```go
func (am *AlertManagerImpl) Initialize(ctx context.Context) error
```

##### AlertManagerImpl.IsHealthy

IsHealthy implémente BaseManager.IsHealthy


```go
func (am *AlertManagerImpl) IsHealthy(ctx context.Context) bool
```

##### AlertManagerImpl.ListAlerts

ListAlerts implémente AlertManager.ListAlerts


```go
func (am *AlertManagerImpl) ListAlerts(ctx context.Context) ([]*interfaces.Alert, error)
```

##### AlertManagerImpl.Shutdown

Shutdown implémente BaseManager.Shutdown


```go
func (am *AlertManagerImpl) Shutdown(ctx context.Context) error
```

##### AlertManagerImpl.TriggerAlert

TriggerAlert implémente AlertManager.TriggerAlert


```go
func (am *AlertManagerImpl) TriggerAlert(ctx context.Context, alertID string, data map[string]interface{}) error
```

##### AlertManagerImpl.UpdateAlert

UpdateAlert implémente AlertManager.UpdateAlert


```go
func (am *AlertManagerImpl) UpdateAlert(ctx context.Context, alertID string, alert *interfaces.Alert) error
```

### ChannelManagerImpl

ChannelManagerImpl implémente l'interface ChannelManager


#### Methods

##### ChannelManagerImpl.DeactivateChannel

DeactivateChannel implémente ChannelManager.DeactivateChannel


```go
func (cm *ChannelManagerImpl) DeactivateChannel(ctx context.Context, channelID string) error
```

##### ChannelManagerImpl.GetChannel

GetChannel implémente ChannelManager.GetChannel


```go
func (cm *ChannelManagerImpl) GetChannel(ctx context.Context, channelID string) (*interfaces.NotificationChannel, error)
```

##### ChannelManagerImpl.GetID

GetID implémente BaseManager.GetID


```go
func (cm *ChannelManagerImpl) GetID() string
```

##### ChannelManagerImpl.GetMetrics

GetMetrics implémente BaseManager.GetMetrics


```go
func (cm *ChannelManagerImpl) GetMetrics() map[string]interface{}
```

##### ChannelManagerImpl.GetName

GetName implémente BaseManager.GetName


```go
func (cm *ChannelManagerImpl) GetName() string
```

##### ChannelManagerImpl.GetStatus

GetStatus implémente BaseManager.GetStatus


```go
func (cm *ChannelManagerImpl) GetStatus() interfaces.ManagerStatus
```

##### ChannelManagerImpl.GetVersion

GetVersion implémente BaseManager.GetVersion


```go
func (cm *ChannelManagerImpl) GetVersion() string
```

##### ChannelManagerImpl.Initialize

Initialize implémente BaseManager.Initialize


```go
func (cm *ChannelManagerImpl) Initialize(ctx context.Context) error
```

##### ChannelManagerImpl.IsHealthy

IsHealthy implémente BaseManager.IsHealthy


```go
func (cm *ChannelManagerImpl) IsHealthy(ctx context.Context) bool
```

##### ChannelManagerImpl.ListChannels

ListChannels implémente ChannelManager.ListChannels


```go
func (cm *ChannelManagerImpl) ListChannels(ctx context.Context) ([]*interfaces.NotificationChannel, error)
```

##### ChannelManagerImpl.RegisterChannel

RegisterChannel implémente ChannelManager.RegisterChannel


```go
func (cm *ChannelManagerImpl) RegisterChannel(ctx context.Context, channel *interfaces.NotificationChannel) error
```

##### ChannelManagerImpl.Shutdown

Shutdown implémente BaseManager.Shutdown


```go
func (cm *ChannelManagerImpl) Shutdown(ctx context.Context) error
```

##### ChannelManagerImpl.TestChannel

TestChannel implémente ChannelManager.TestChannel


```go
func (cm *ChannelManagerImpl) TestChannel(ctx context.Context, channelID string) error
```

##### ChannelManagerImpl.UpdateChannel

UpdateChannel implémente ChannelManager.UpdateChannel


```go
func (cm *ChannelManagerImpl) UpdateChannel(ctx context.Context, channelID string, channel *interfaces.NotificationChannel) error
```

##### ChannelManagerImpl.ValidateChannelConfig

ValidateChannelConfig implémente ChannelManager.ValidateChannelConfig


```go
func (cm *ChannelManagerImpl) ValidateChannelConfig(ctx context.Context, channelType string, config map[string]interface{}) error
```

### ChannelStats

ChannelStats statistiques par canal


### DiscordConfig

DiscordConfig configuration pour Discord


### NotificationConfig

NotificationConfig représente la configuration du Notification Manager


### NotificationManagerImpl

NotificationManagerImpl implémente l'interface NotificationManager


#### Methods

##### NotificationManagerImpl.CancelNotification

CancelNotification implémente NotificationManager.CancelNotification


```go
func (nm *NotificationManagerImpl) CancelNotification(ctx context.Context, notificationID string) error
```

##### NotificationManagerImpl.CreateAlert

Alert management methods


```go
func (nm *NotificationManagerImpl) CreateAlert(ctx context.Context, alert *interfaces.Alert) error
```

##### NotificationManagerImpl.DeactivateChannel

```go
func (nm *NotificationManagerImpl) DeactivateChannel(ctx context.Context, channelID string) error
```

##### NotificationManagerImpl.DeleteAlert

```go
func (nm *NotificationManagerImpl) DeleteAlert(ctx context.Context, alertID string) error
```

##### NotificationManagerImpl.GetAlertHistory

```go
func (nm *NotificationManagerImpl) GetAlertHistory(ctx context.Context, alertID string) ([]*interfaces.AlertEvent, error)
```

##### NotificationManagerImpl.GetChannel

```go
func (nm *NotificationManagerImpl) GetChannel(ctx context.Context, channelID string) (*interfaces.NotificationChannel, error)
```

##### NotificationManagerImpl.GetChannelPerformance

```go
func (nm *NotificationManagerImpl) GetChannelPerformance(ctx context.Context, channelID string) (*interfaces.ChannelPerformance, error)
```

##### NotificationManagerImpl.GetID

GetID implémente BaseManager.GetID


```go
func (nm *NotificationManagerImpl) GetID() string
```

##### NotificationManagerImpl.GetMetrics

GetMetrics implémente BaseManager.GetMetrics


```go
func (nm *NotificationManagerImpl) GetMetrics() map[string]interface{}
```

##### NotificationManagerImpl.GetName

GetName implémente BaseManager.GetName


```go
func (nm *NotificationManagerImpl) GetName() string
```

##### NotificationManagerImpl.GetNotificationStats

Analytics methods


```go
func (nm *NotificationManagerImpl) GetNotificationStats(ctx context.Context, dateRange interfaces.DateRange) (*interfaces.NotificationStats, error)
```

##### NotificationManagerImpl.GetStatus

GetStatus implémente BaseManager.GetStatus


```go
func (nm *NotificationManagerImpl) GetStatus() interfaces.ManagerStatus
```

##### NotificationManagerImpl.GetVersion

GetVersion implémente BaseManager.GetVersion


```go
func (nm *NotificationManagerImpl) GetVersion() string
```

##### NotificationManagerImpl.Initialize

Initialize implémente BaseManager.Initialize


```go
func (nm *NotificationManagerImpl) Initialize(ctx context.Context) error
```

##### NotificationManagerImpl.IsHealthy

IsHealthy implémente BaseManager.IsHealthy


```go
func (nm *NotificationManagerImpl) IsHealthy(ctx context.Context) bool
```

##### NotificationManagerImpl.ListChannels

```go
func (nm *NotificationManagerImpl) ListChannels(ctx context.Context) ([]*interfaces.NotificationChannel, error)
```

##### NotificationManagerImpl.RegisterChannel

Channel management methods


```go
func (nm *NotificationManagerImpl) RegisterChannel(ctx context.Context, channel *interfaces.NotificationChannel) error
```

##### NotificationManagerImpl.ScheduleNotification

ScheduleNotification implémente NotificationManager.ScheduleNotification


```go
func (nm *NotificationManagerImpl) ScheduleNotification(ctx context.Context, notification *interfaces.Notification, sendTime time.Time) error
```

##### NotificationManagerImpl.SendBulkNotifications

SendBulkNotifications implémente NotificationManager.SendBulkNotifications


```go
func (nm *NotificationManagerImpl) SendBulkNotifications(ctx context.Context, notifications []*interfaces.Notification) error
```

##### NotificationManagerImpl.SendNotification

SendNotification implémente NotificationManager.SendNotification


```go
func (nm *NotificationManagerImpl) SendNotification(ctx context.Context, notification *interfaces.Notification) error
```

##### NotificationManagerImpl.Shutdown

Shutdown implémente BaseManager.Shutdown


```go
func (nm *NotificationManagerImpl) Shutdown(ctx context.Context) error
```

##### NotificationManagerImpl.TestChannel

```go
func (nm *NotificationManagerImpl) TestChannel(ctx context.Context, channelID string) error
```

##### NotificationManagerImpl.TriggerAlert

```go
func (nm *NotificationManagerImpl) TriggerAlert(ctx context.Context, alertID string, data map[string]interface{}) error
```

##### NotificationManagerImpl.UpdateAlert

```go
func (nm *NotificationManagerImpl) UpdateAlert(ctx context.Context, alertID string, alert *interfaces.Alert) error
```

##### NotificationManagerImpl.UpdateChannel

```go
func (nm *NotificationManagerImpl) UpdateChannel(ctx context.Context, channelID string, channel *interfaces.NotificationChannel) error
```

### SlackConfig

SlackConfig configuration pour Slack


### WebhookConfig

WebhookConfig configuration pour les webhooks


## Functions

### NewAlertManager

NewAlertManager creates a new AlertManager instance


```go
func NewAlertManager(logger *zap.Logger) interfaces.AlertManager
```

### NewChannelManager

NewChannelManager crée une nouvelle instance de ChannelManager


```go
func NewChannelManager(logger *zap.Logger) interfaces.ChannelManager
```

### NewNotificationManager

NewNotificationManager crée une nouvelle instance de NotificationManager


```go
func NewNotificationManager(config *NotificationConfig, logger *zap.Logger) interfaces.NotificationManager
```

