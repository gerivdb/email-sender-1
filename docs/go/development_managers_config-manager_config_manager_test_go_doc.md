# Package configmanager

## Types

### ConfigManager

ConfigManager defines the interface for managing configurations.


### ErrorEntry

ErrorEntry représente une erreur cataloguée


### ErrorHook

ErrorHook defines a function type for error handling hooks


### ErrorHooks

ErrorHooks définit les callbacks d'erreur


### ErrorManager

ErrorManager interface pour découpler la dépendance


### ErrorManagerImpl

ErrorManagerImpl implémente l'interface ErrorManager localement


#### Methods

##### ErrorManagerImpl.CatalogError

CatalogError catalog une erreur avec les détails structurés


```go
func (em *ErrorManagerImpl) CatalogError(entry ErrorEntry) error
```

##### ErrorManagerImpl.ProcessError

ProcessError traite une erreur avec le système de gestion centralisé


```go
func (em *ErrorManagerImpl) ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error
```

##### ErrorManagerImpl.ValidateErrorEntry

ValidateErrorEntry valide une entrée d'erreur


```go
func (em *ErrorManagerImpl) ValidateErrorEntry(entry ErrorEntry) error
```

### IntegratedConfigManager

IntegratedConfigManager wraps ConfigManager with integration capabilities


#### Methods

##### IntegratedConfigManager.GetConfigManager

GetConfigManager returns the underlying config manager


```go
func (icm *IntegratedConfigManager) GetConfigManager() ConfigManager
```

##### IntegratedConfigManager.GetManagerConfig

GetManagerConfig returns configuration for a specific manager


```go
func (icm *IntegratedConfigManager) GetManagerConfig(managerName string) (map[string]interface{}, error)
```

##### IntegratedConfigManager.Initialize

Initialize initializes the config manager with default configurations


```go
func (icm *IntegratedConfigManager) Initialize() error
```

##### IntegratedConfigManager.IsInitialized

IsInitialized returns whether the config manager has been initialized


```go
func (icm *IntegratedConfigManager) IsInitialized() bool
```

##### IntegratedConfigManager.LoadManagerConfigFile

LoadManagerConfigFile loads a configuration file specific to a manager


```go
func (icm *IntegratedConfigManager) LoadManagerConfigFile(managerName, configPath string) error
```

##### IntegratedConfigManager.ValidateManagerConfig

ValidateManagerConfig validates configuration for a specific manager


```go
func (icm *IntegratedConfigManager) ValidateManagerConfig(managerName string, requiredKeys []string) error
```

### IntegratedErrorManagerInterface

IntegratedErrorManagerInterface defines the minimal interface we need
from the actual IntegratedErrorManager without importing the package


### IntegrationManager

IntegrationManager defines the interface for manager integration
This interface should be implemented by the actual IntegratedManager


### RealIntegratedErrorManager

RealIntegratedErrorManager defines the interface that matches the actual IntegratedErrorManager
This allows us to integrate with the real integrated-manager package without circular imports


### RealIntegratedManagerAdapter

RealIntegratedManagerAdapter adapts the real IntegratedManager to our interface
This allows integration with the actual integrated-manager package


#### Methods

##### RealIntegratedManagerAdapter.GetConfigManager

GetConfigManager implements IntegrationManager interface


```go
func (rima *RealIntegratedManagerAdapter) GetConfigManager() ConfigManager
```

##### RealIntegratedManagerAdapter.InitializeConfigManager

InitializeConfigManager implements IntegrationManager interface


```go
func (rima *RealIntegratedManagerAdapter) InitializeConfigManager() (ConfigManager, error)
```

##### RealIntegratedManagerAdapter.PropagateError

PropagateError implements IntegrationManager interface


```go
func (rima *RealIntegratedManagerAdapter) PropagateError(module string, err error, context map[string]interface{})
```

### RealIntegratedManagerConnector

RealIntegratedManagerConnector provides connection to the real IntegratedManager


#### Methods

##### RealIntegratedManagerConnector.CreateManagerConfigFile

CreateManagerConfigFile creates a configuration file template for a specific manager


```go
func (rimc *RealIntegratedManagerConnector) CreateManagerConfigFile(managerName, configPath, fileType string) error
```

##### RealIntegratedManagerConnector.GetConfigManager

GetConfigManager returns the connected config manager


```go
func (rimc *RealIntegratedManagerConnector) GetConfigManager() ConfigManager
```

##### RealIntegratedManagerConnector.GetManagerConfig

GetManagerConfig retrieves configuration for a specific manager


```go
func (rimc *RealIntegratedManagerConnector) GetManagerConfig(managerName string) (map[string]interface{}, error)
```

##### RealIntegratedManagerConnector.InitializeWithRealManager

InitializeWithRealManager initializes the config manager and connects it to the real IntegratedManager


```go
func (rimc *RealIntegratedManagerConnector) InitializeWithRealManager() (ConfigManager, error)
```

##### RealIntegratedManagerConnector.IsConnected

IsConnected returns whether the connector is properly connected to the real manager


```go
func (rimc *RealIntegratedManagerConnector) IsConnected() bool
```

##### RealIntegratedManagerConnector.LoadManagerConfig

LoadManagerConfig loads configuration for a specific manager through the real integration


```go
func (rimc *RealIntegratedManagerConnector) LoadManagerConfig(managerName, configPath, fileType string) error
```

##### RealIntegratedManagerConnector.SetupManagerDefaults

SetupManagerDefaults sets up default configurations for all managers


```go
func (rimc *RealIntegratedManagerConnector) SetupManagerDefaults() error
```

##### RealIntegratedManagerConnector.ValidateManagerConfig

ValidateManagerConfig validates configuration for a specific manager


```go
func (rimc *RealIntegratedManagerConnector) ValidateManagerConfig(managerName string, requiredKeys []string) error
```

## Variables

### ErrKeyNotFound, ErrConfigParse, ErrInvalidType, ErrInvalidFormat

Config Manager specific errors


```go
var (
	ErrKeyNotFound		= errors.New("configuration key not found")
	ErrConfigParse		= errors.New("failed to parse configuration")
	ErrInvalidType		= errors.New("invalid type conversion")
	ErrInvalidFormat	= errors.New("invalid configuration format")
)
```

