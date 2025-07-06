# Package integration

## Functions

### NewIntegrationManager

NewIntegrationManager crÃ©e une nouvelle instance de IntegrationManager


```go
func NewIntegrationManager(
	storageManager baseInterfaces.StorageManager,
	configManager baseInterfaces.ConfigManager,
	errorManager baseInterfaces.ErrorManager,
) (*integrationManagerImpl, error)
```

