# Package indexing

## Functions

### NewIndexManager

NewIndexManager crÃ©e une nouvelle instance de IndexManager


```go
func NewIndexManager(
	storageManager baseInterfaces.StorageManager,
	errorManager baseInterfaces.ErrorManager,
	configManager baseInterfaces.ConfigManager,
	monitoringManager interfaces.MonitoringManager,
) (*indexManagerImpl, error)
```

