# Package retrieval

## Functions

### NewRetrievalManager

NewRetrievalManager crÃ©e une nouvelle instance de RetrievalManager


```go
func NewRetrievalManager(
	storageManager baseInterfaces.StorageManager,
	errorManager baseInterfaces.ErrorManager,
	configManager baseInterfaces.ConfigManager,
	indexManager interfaces.IndexManager,
	monitoringManager interfaces.MonitoringManager,
) (*retrievalManagerImpl, error)
```

