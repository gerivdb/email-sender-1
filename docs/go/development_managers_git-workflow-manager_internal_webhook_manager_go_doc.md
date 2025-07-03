# Package webhook

## Types

### Manager

Manager handles webhook operations


#### Methods

##### Manager.ConfigureWebhook

ConfigureWebhook adds or updates a webhook configuration


```go
func (m *Manager) ConfigureWebhook(ctx context.Context, url string, events []string, secret string) error
```

##### Manager.DeleteWebhook

DeleteWebhook removes a webhook configuration


```go
func (m *Manager) DeleteWebhook(ctx context.Context, name string) error
```

##### Manager.DisableWebhook

DisableWebhook disables a webhook


```go
func (m *Manager) DisableWebhook(ctx context.Context, name string) error
```

##### Manager.EnableWebhook

EnableWebhook enables a webhook


```go
func (m *Manager) EnableWebhook(ctx context.Context, name string) error
```

##### Manager.GetWebhookStats

GetWebhookStats returns statistics about webhook deliveries


```go
func (m *Manager) GetWebhookStats(ctx context.Context) (map[string]interface{}, error)
```

##### Manager.Health

Health checks the health of the webhook manager


```go
func (m *Manager) Health() error
```

##### Manager.ListWebhooks

ListWebhooks returns all configured webhooks


```go
func (m *Manager) ListWebhooks(ctx context.Context) ([]map[string]interface{}, error)
```

##### Manager.SendWebhook

SendWebhook sends a webhook payload to configured endpoints


```go
func (m *Manager) SendWebhook(ctx context.Context, event string, payload *interfaces.WebhookPayload) error
```

##### Manager.Shutdown

Shutdown gracefully shuts down the webhook manager


```go
func (m *Manager) Shutdown(ctx context.Context) error
```

##### Manager.TestWebhook

TestWebhook sends a test payload to a specific webhook


```go
func (m *Manager) TestWebhook(ctx context.Context, name string) error
```

##### Manager.UpdateWebhook

UpdateWebhook updates an existing webhook configuration


```go
func (m *Manager) UpdateWebhook(ctx context.Context, name string, updates map[string]interface{}) error
```

### WebhookConfig

WebhookConfig represents webhook configuration


