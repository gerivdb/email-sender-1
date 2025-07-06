# Package integration_manager

## Types

### IntegrationConfig

IntegrationConfig représente la configuration du gestionnaire d'intégration


### IntegrationManagerImpl

IntegrationManagerImpl implémente l'interface IntegrationManager


#### Methods

##### IntegrationManagerImpl.CallAPI

```go
func (im *IntegrationManagerImpl) CallAPI(ctx context.Context, apiID string, request *interfaces.APIRequest) (*interfaces.APIResponse, error)
```

##### IntegrationManagerImpl.CreateIntegration

```go
func (im *IntegrationManagerImpl) CreateIntegration(ctx context.Context, integration *interfaces.Integration) error
```

##### IntegrationManagerImpl.CreateSyncJob

```go
func (im *IntegrationManagerImpl) CreateSyncJob(ctx context.Context, syncJob *interfaces.SyncJob) error
```

##### IntegrationManagerImpl.DeactivateAPI

```go
func (im *IntegrationManagerImpl) DeactivateAPI(ctx context.Context, apiID string) error
```

##### IntegrationManagerImpl.DeleteIntegration

```go
func (im *IntegrationManagerImpl) DeleteIntegration(ctx context.Context, integrationID string) error
```

##### IntegrationManagerImpl.GetAPIStatus

```go
func (im *IntegrationManagerImpl) GetAPIStatus(ctx context.Context, apiID string) (*interfaces.APIStatus, error)
```

##### IntegrationManagerImpl.GetIntegration

```go
func (im *IntegrationManagerImpl) GetIntegration(ctx context.Context, integrationID string) (*interfaces.Integration, error)
```

##### IntegrationManagerImpl.GetMetrics

```go
func (im *IntegrationManagerImpl) GetMetrics(ctx context.Context) map[string]interface{}
```

##### IntegrationManagerImpl.GetStatus

```go
func (im *IntegrationManagerImpl) GetStatus(ctx context.Context) map[string]interface{}
```

##### IntegrationManagerImpl.GetSyncHistory

```go
func (im *IntegrationManagerImpl) GetSyncHistory(ctx context.Context, syncJobID string) ([]*interfaces.SyncEvent, error)
```

##### IntegrationManagerImpl.GetSyncStatus

```go
func (im *IntegrationManagerImpl) GetSyncStatus(ctx context.Context, syncJobID string) (*interfaces.SyncStatus, error)
```

##### IntegrationManagerImpl.GetVersion

```go
func (im *IntegrationManagerImpl) GetVersion() string
```

##### IntegrationManagerImpl.GetWebhookLogs

GetWebhookLogs retrieves webhook execution logs


```go
func (im *IntegrationManagerImpl) GetWebhookLogs(webhookID string, limit int) ([]*interfaces.WebhookLog, error)
```

##### IntegrationManagerImpl.HandleWebhook

HandleWebhook processes incoming webhook requests


```go
func (im *IntegrationManagerImpl) HandleWebhook(webhookID string, request *http.Request) error
```

##### IntegrationManagerImpl.ListIntegrations

```go
func (im *IntegrationManagerImpl) ListIntegrations(ctx context.Context) ([]*interfaces.Integration, error)
```

##### IntegrationManagerImpl.RegisterAPI

```go
func (im *IntegrationManagerImpl) RegisterAPI(ctx context.Context, api *interfaces.APIEndpoint) error
```

##### IntegrationManagerImpl.RegisterTransformation

RegisterTransformation registers a new data transformation


```go
func (im *IntegrationManagerImpl) RegisterTransformation(transformation *interfaces.DataTransformation) error
```

##### IntegrationManagerImpl.RegisterWebhook

RegisterWebhook registers a new webhook


```go
func (im *IntegrationManagerImpl) RegisterWebhook(webhook *interfaces.Webhook) error
```

##### IntegrationManagerImpl.Start

```go
func (im *IntegrationManagerImpl) Start(ctx context.Context) error
```

##### IntegrationManagerImpl.StartSync

```go
func (im *IntegrationManagerImpl) StartSync(ctx context.Context, syncJobID string) error
```

##### IntegrationManagerImpl.Stop

```go
func (im *IntegrationManagerImpl) Stop(ctx context.Context) error
```

##### IntegrationManagerImpl.StopSync

```go
func (im *IntegrationManagerImpl) StopSync(ctx context.Context, syncJobID string) error
```

##### IntegrationManagerImpl.TestIntegration

```go
func (im *IntegrationManagerImpl) TestIntegration(ctx context.Context, integrationID string) error
```

##### IntegrationManagerImpl.TransformData

TransformData transforms data using the specified transformation


```go
func (im *IntegrationManagerImpl) TransformData(transformationID string, data interface{}) (interface{}, error)
```

##### IntegrationManagerImpl.UpdateAPI

```go
func (im *IntegrationManagerImpl) UpdateAPI(ctx context.Context, apiID string, api *interfaces.APIEndpoint) error
```

##### IntegrationManagerImpl.UpdateIntegration

```go
func (im *IntegrationManagerImpl) UpdateIntegration(ctx context.Context, integrationID string, integration *interfaces.Integration) error
```

### SyncManager

SyncManager gère les tâches de synchronisation


### WebhookManager

WebhookManager gère les webhooks


