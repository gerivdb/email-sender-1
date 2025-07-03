# Package main

## Types

### Config

Config represents the manager's configuration.


### ConfigManager

ConfigManager interface for configuration management.


### DepConfigManagerImpl

DepConfigManagerImpl implements ConfigManager for DependencyManager.


#### Methods

##### DepConfigManagerImpl.Cleanup

```go
func (cm *DepConfigManagerImpl) Cleanup() error
```

##### DepConfigManagerImpl.Get

```go
func (cm *DepConfigManagerImpl) Get(key string) interface{}
```

##### DepConfigManagerImpl.GetAll

```go
func (cm *DepConfigManagerImpl) GetAll() map[string]interface{}
```

##### DepConfigManagerImpl.GetBool

```go
func (cm *DepConfigManagerImpl) GetBool(key string) (bool, error)
```

##### DepConfigManagerImpl.GetErrorManager

```go
func (cm *DepConfigManagerImpl) GetErrorManager() ErrorManager
```

##### DepConfigManagerImpl.GetInt

```go
func (cm *DepConfigManagerImpl) GetInt(key string) (int, error)
```

##### DepConfigManagerImpl.GetLogger

```go
func (cm *DepConfigManagerImpl) GetLogger() *zap.Logger
```

##### DepConfigManagerImpl.GetString

ConfigManager interface implementation.


```go
func (cm *DepConfigManagerImpl) GetString(key string) (string, error)
```

##### DepConfigManagerImpl.IsSet

```go
func (cm *DepConfigManagerImpl) IsSet(key string) bool
```

##### DepConfigManagerImpl.LoadConfigFile

```go
func (cm *DepConfigManagerImpl) LoadConfigFile(filePath string, fileType string) error
```

##### DepConfigManagerImpl.LoadFromEnv

```go
func (cm *DepConfigManagerImpl) LoadFromEnv(prefix string)
```

##### DepConfigManagerImpl.RegisterDefaults

```go
func (cm *DepConfigManagerImpl) RegisterDefaults(defaults map[string]interface{})
```

##### DepConfigManagerImpl.SaveToFile

```go
func (cm *DepConfigManagerImpl) SaveToFile(filePath string, fileType string, config map[string]interface{}) error
```

##### DepConfigManagerImpl.Set

```go
func (cm *DepConfigManagerImpl) Set(key string, value interface{})
```

##### DepConfigManagerImpl.SetDefault

```go
func (cm *DepConfigManagerImpl) SetDefault(key string, value interface{})
```

##### DepConfigManagerImpl.SetRequiredKeys

```go
func (cm *DepConfigManagerImpl) SetRequiredKeys(keys []string)
```

##### DepConfigManagerImpl.UnmarshalKey

```go
func (cm *DepConfigManagerImpl) UnmarshalKey(key string, targetStruct interface{}) error
```

##### DepConfigManagerImpl.Validate

```go
func (cm *DepConfigManagerImpl) Validate() error
```

### DepManager

DepManager manages dependency operations (SOLID interface).


### Dependency

Dependency represents a dependency with its metadata.


### ErrorEntry

ErrorEntry represents a locally cataloged error.


### ErrorHooks

ErrorHooks defines callbacks for error handling.


### ErrorManager

ErrorManager interface for decoupling error handling.


### ErrorManagerImpl

ErrorManagerImpl implements ErrorManager.


#### Methods

##### ErrorManagerImpl.CatalogError

CatalogError catalogs an error with structured details.


```go
func (em *ErrorManagerImpl) CatalogError(entry ErrorEntry) error
```

##### ErrorManagerImpl.ProcessError

ProcessError processes an error with centralized error handling.


```go
func (em *ErrorManagerImpl) ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error
```

##### ErrorManagerImpl.ValidateErrorEntry

ValidateErrorEntry validates an error entry.


```go
func (em *ErrorManagerImpl) ValidateErrorEntry(entry ErrorEntry) error
```

### GoModManager

GoModManager implements DepManager for go.mod.


#### Methods

##### GoModManager.Add

Add adds a dependency to the project.


```go
func (m *GoModManager) Add(module, version string) error
```

##### GoModManager.Audit

Audit checks for dependency vulnerabilities.


```go
func (m *GoModManager) Audit() error
```

##### GoModManager.Cleanup

Cleanup removes unused dependencies.


```go
func (m *GoModManager) Cleanup() error
```

##### GoModManager.List

List returns the list of dependencies from go.mod.


```go
func (m *GoModManager) List() ([]Dependency, error)
```

##### GoModManager.Log

Log writes a message to the log.


```go
func (m *GoModManager) Log(level, message string)
```

##### GoModManager.Remove

Remove removes a dependency from the project.


```go
func (m *GoModManager) Remove(module string) error
```

##### GoModManager.Update

Update updates a dependency to the latest version.


```go
func (m *GoModManager) Update(module string) error
```

