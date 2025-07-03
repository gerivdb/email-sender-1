# Package email

## Types

### EmailConfig

EmailConfig représente la configuration de l'Email Manager


### EmailManagerImpl

EmailManagerImpl implémente l'interface EmailManager


#### Methods

##### EmailManagerImpl.CancelScheduledEmail

```go
func (em *EmailManagerImpl) CancelScheduledEmail(ctx context.Context, emailID string) error
```

##### EmailManagerImpl.Configure

```go
func (em *EmailManagerImpl) Configure(config map[string]interface{}) error
```

##### EmailManagerImpl.CreateTemplate

```go
func (em *EmailManagerImpl) CreateTemplate(ctx context.Context, template *interfaces.EmailTemplate) error
```

##### EmailManagerImpl.DeleteTemplate

```go
func (em *EmailManagerImpl) DeleteTemplate(ctx context.Context, templateID string) error
```

##### EmailManagerImpl.FlushQueue

```go
func (em *EmailManagerImpl) FlushQueue(ctx context.Context) error
```

##### EmailManagerImpl.GetDeliveryReport

```go
func (em *EmailManagerImpl) GetDeliveryReport(ctx context.Context, emailID string) (*interfaces.DeliveryReport, error)
```

##### EmailManagerImpl.GetEmailStats

```go
func (em *EmailManagerImpl) GetEmailStats(ctx context.Context, dateRange interfaces.DateRange) (*interfaces.EmailStats, error)
```

##### EmailManagerImpl.GetHealth

```go
func (em *EmailManagerImpl) GetHealth() interfaces.HealthStatus
```

##### EmailManagerImpl.GetID

```go
func (em *EmailManagerImpl) GetID() string
```

##### EmailManagerImpl.GetMetrics

```go
func (em *EmailManagerImpl) GetMetrics() map[string]interface{}
```

##### EmailManagerImpl.GetName

```go
func (em *EmailManagerImpl) GetName() string
```

##### EmailManagerImpl.GetQueueStatus

```go
func (em *EmailManagerImpl) GetQueueStatus(ctx context.Context) (*interfaces.QueueStatus, error)
```

##### EmailManagerImpl.GetStatus

```go
func (em *EmailManagerImpl) GetStatus() interfaces.ManagerStatus
```

##### EmailManagerImpl.GetTemplate

```go
func (em *EmailManagerImpl) GetTemplate(ctx context.Context, templateID string) (*interfaces.EmailTemplate, error)
```

##### EmailManagerImpl.GetVersion

```go
func (em *EmailManagerImpl) GetVersion() string
```

##### EmailManagerImpl.ListTemplates

```go
func (em *EmailManagerImpl) ListTemplates(ctx context.Context) ([]*interfaces.EmailTemplate, error)
```

##### EmailManagerImpl.PauseQueue

```go
func (em *EmailManagerImpl) PauseQueue(ctx context.Context) error
```

##### EmailManagerImpl.RenderTemplate

```go
func (em *EmailManagerImpl) RenderTemplate(ctx context.Context, templateID string, data map[string]interface{}) (string, error)
```

##### EmailManagerImpl.Restart

```go
func (em *EmailManagerImpl) Restart(ctx context.Context) error
```

##### EmailManagerImpl.ResumeQueue

```go
func (em *EmailManagerImpl) ResumeQueue(ctx context.Context) error
```

##### EmailManagerImpl.RetryFailedEmails

```go
func (em *EmailManagerImpl) RetryFailedEmails(ctx context.Context) error
```

##### EmailManagerImpl.ScheduleEmail

```go
func (em *EmailManagerImpl) ScheduleEmail(ctx context.Context, email *interfaces.Email, sendTime time.Time) error
```

##### EmailManagerImpl.SendBulkEmails

```go
func (em *EmailManagerImpl) SendBulkEmails(ctx context.Context, emails []*interfaces.Email) error
```

##### EmailManagerImpl.SendEmail

```go
func (em *EmailManagerImpl) SendEmail(ctx context.Context, email *interfaces.Email) error
```

##### EmailManagerImpl.Start

```go
func (em *EmailManagerImpl) Start(ctx context.Context) error
```

##### EmailManagerImpl.Stop

```go
func (em *EmailManagerImpl) Stop(ctx context.Context) error
```

##### EmailManagerImpl.TrackEmailClicks

```go
func (em *EmailManagerImpl) TrackEmailClicks(ctx context.Context, emailID string, linkURL string) error
```

##### EmailManagerImpl.TrackEmailOpens

```go
func (em *EmailManagerImpl) TrackEmailOpens(ctx context.Context, emailID string) error
```

##### EmailManagerImpl.UpdateTemplate

```go
func (em *EmailManagerImpl) UpdateTemplate(ctx context.Context, templateID string, template *interfaces.EmailTemplate) error
```

### EmailStats

EmailStats représente les statistiques internes


### QueueManagerImpl

QueueManagerImpl implémente l'interface QueueManager


#### Methods

##### QueueManagerImpl.DequeueEmail

DequeueEmail implémente QueueManager.DequeueEmail


```go
func (qm *QueueManagerImpl) DequeueEmail(ctx context.Context) (*interfaces.Email, error)
```

##### QueueManagerImpl.EnqueueEmail

EnqueueEmail implémente QueueManager.EnqueueEmail


```go
func (qm *QueueManagerImpl) EnqueueEmail(ctx context.Context, email *interfaces.Email) error
```

##### QueueManagerImpl.FlushQueue

FlushQueue implémente QueueManager.FlushQueue


```go
func (qm *QueueManagerImpl) FlushQueue(ctx context.Context) error
```

##### QueueManagerImpl.GetID

GetID implémente BaseManager.GetID


```go
func (qm *QueueManagerImpl) GetID() string
```

##### QueueManagerImpl.GetMetrics

GetMetrics implémente BaseManager.GetMetrics


```go
func (qm *QueueManagerImpl) GetMetrics() map[string]interface{}
```

##### QueueManagerImpl.GetName

GetName implémente BaseManager.GetName


```go
func (qm *QueueManagerImpl) GetName() string
```

##### QueueManagerImpl.GetQueueSize

GetQueueSize implémente QueueManager.GetQueueSize


```go
func (qm *QueueManagerImpl) GetQueueSize(ctx context.Context) (int, error)
```

##### QueueManagerImpl.GetQueueStatus

GetQueueStatus implémente QueueManager.GetQueueStatus


```go
func (qm *QueueManagerImpl) GetQueueStatus(ctx context.Context) (*interfaces.QueueStatus, error)
```

##### QueueManagerImpl.GetStatus

GetStatus implémente BaseManager.GetStatus


```go
func (qm *QueueManagerImpl) GetStatus() interfaces.ManagerStatus
```

##### QueueManagerImpl.GetVersion

GetVersion implémente BaseManager.GetVersion


```go
func (qm *QueueManagerImpl) GetVersion() string
```

##### QueueManagerImpl.Initialize

Initialize implémente BaseManager.Initialize


```go
func (qm *QueueManagerImpl) Initialize(ctx context.Context) error
```

##### QueueManagerImpl.IsHealthy

IsHealthy implémente BaseManager.IsHealthy


```go
func (qm *QueueManagerImpl) IsHealthy(ctx context.Context) bool
```

##### QueueManagerImpl.MarkEmailFailed

MarkEmailFailed marque un email comme échoué


```go
func (qm *QueueManagerImpl) MarkEmailFailed(email *interfaces.Email)
```

##### QueueManagerImpl.MarkEmailProcessed

MarkEmailProcessed marque un email comme traité


```go
func (qm *QueueManagerImpl) MarkEmailProcessed()
```

##### QueueManagerImpl.PauseQueue

PauseQueue implémente QueueManager.PauseQueue


```go
func (qm *QueueManagerImpl) PauseQueue(ctx context.Context) error
```

##### QueueManagerImpl.ResumeQueue

ResumeQueue implémente QueueManager.ResumeQueue


```go
func (qm *QueueManagerImpl) ResumeQueue(ctx context.Context) error
```

##### QueueManagerImpl.RetryFailedEmails

RetryFailedEmails implémente QueueManager.RetryFailedEmails


```go
func (qm *QueueManagerImpl) RetryFailedEmails(ctx context.Context) error
```

##### QueueManagerImpl.ScheduleEmail

ScheduleEmail implémente QueueManager.ScheduleEmail


```go
func (qm *QueueManagerImpl) ScheduleEmail(ctx context.Context, email *interfaces.Email, sendTime time.Time) error
```

##### QueueManagerImpl.Shutdown

Shutdown implémente BaseManager.Shutdown


```go
func (qm *QueueManagerImpl) Shutdown(ctx context.Context) error
```

### ScheduledEmail

ScheduledEmail représente un email programmé


### TemplateManagerImpl

TemplateManagerImpl implémente l'interface TemplateManager


#### Methods

##### TemplateManagerImpl.CreateTemplate

CreateTemplate implémente TemplateManager.CreateTemplate


```go
func (tm *TemplateManagerImpl) CreateTemplate(ctx context.Context, emailTemplate *interfaces.EmailTemplate) error
```

##### TemplateManagerImpl.DeleteTemplate

DeleteTemplate implémente TemplateManager.DeleteTemplate


```go
func (tm *TemplateManagerImpl) DeleteTemplate(ctx context.Context, templateID string) error
```

##### TemplateManagerImpl.GetID

GetID implémente BaseManager.GetID


```go
func (tm *TemplateManagerImpl) GetID() string
```

##### TemplateManagerImpl.GetMetrics

GetMetrics implémente BaseManager.GetMetrics


```go
func (tm *TemplateManagerImpl) GetMetrics() map[string]interface{}
```

##### TemplateManagerImpl.GetName

GetName implémente BaseManager.GetName


```go
func (tm *TemplateManagerImpl) GetName() string
```

##### TemplateManagerImpl.GetStatus

GetStatus implémente BaseManager.GetStatus


```go
func (tm *TemplateManagerImpl) GetStatus() interfaces.ManagerStatus
```

##### TemplateManagerImpl.GetTemplate

GetTemplate implémente TemplateManager.GetTemplate


```go
func (tm *TemplateManagerImpl) GetTemplate(ctx context.Context, templateID string) (*interfaces.EmailTemplate, error)
```

##### TemplateManagerImpl.GetVersion

GetVersion implémente BaseManager.GetVersion


```go
func (tm *TemplateManagerImpl) GetVersion() string
```

##### TemplateManagerImpl.Initialize

Initialize implémente BaseManager.Initialize


```go
func (tm *TemplateManagerImpl) Initialize(ctx context.Context) error
```

##### TemplateManagerImpl.IsHealthy

IsHealthy implémente BaseManager.IsHealthy


```go
func (tm *TemplateManagerImpl) IsHealthy(ctx context.Context) bool
```

##### TemplateManagerImpl.ListTemplates

ListTemplates implémente TemplateManager.ListTemplates


```go
func (tm *TemplateManagerImpl) ListTemplates(ctx context.Context) ([]*interfaces.EmailTemplate, error)
```

##### TemplateManagerImpl.PreviewTemplate

PreviewTemplate implémente TemplateManager.PreviewTemplate


```go
func (tm *TemplateManagerImpl) PreviewTemplate(ctx context.Context, templateID string, data map[string]interface{}) (string, error)
```

##### TemplateManagerImpl.RenderTemplate

RenderTemplate implémente TemplateManager.RenderTemplate


```go
func (tm *TemplateManagerImpl) RenderTemplate(ctx context.Context, templateID string, data map[string]interface{}) (string, error)
```

##### TemplateManagerImpl.Shutdown

Shutdown implémente BaseManager.Shutdown


```go
func (tm *TemplateManagerImpl) Shutdown(ctx context.Context) error
```

##### TemplateManagerImpl.UpdateTemplate

UpdateTemplate implémente TemplateManager.UpdateTemplate


```go
func (tm *TemplateManagerImpl) UpdateTemplate(ctx context.Context, templateID string, emailTemplate *interfaces.EmailTemplate) error
```

##### TemplateManagerImpl.ValidateTemplate

ValidateTemplate implémente TemplateManager.ValidateTemplate


```go
func (tm *TemplateManagerImpl) ValidateTemplate(ctx context.Context, templateContent string) error
```

## Functions

### NewEmailManager

NewEmailManager crée une nouvelle instance du gestionnaire d'emails


```go
func NewEmailManager() (interfaces.EmailManager, error)
```

### NewQueueManager

NewQueueManager crée une nouvelle instance de QueueManager


```go
func NewQueueManager(logger *zap.Logger, queueSize int) interfaces.QueueManager
```

### NewTemplateManager

NewTemplateManager crée une nouvelle instance de TemplateManager


```go
func NewTemplateManager(logger *zap.Logger) interfaces.TemplateManager
```

