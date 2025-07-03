# Package scriptmanager

This file is used to force Go tools to recognize types defined in script_manager.go
It is only needed if you encounter build errors about undefined types in executors.go
You can safely delete this file if your build works without it.


## Types

### BackoffType

BackoffType defines the type of backoff strategy


### BashExecutor

BashExecutor executes Bash scripts (Unix/Linux)


#### Methods

##### BashExecutor.Execute

Execute executes a Bash script


```go
func (be *BashExecutor) Execute(ctx context.Context, script *ManagedScript, args map[string]interface{}) (*ExecutionResult, error)
```

##### BashExecutor.GetDefaultTimeout

GetDefaultTimeout returns the default timeout for Bash scripts


```go
func (be *BashExecutor) GetDefaultTimeout() time.Duration
```

##### BashExecutor.SupportsType

SupportsType checks if this executor supports the script type


```go
func (be *BashExecutor) SupportsType(scriptType ScriptType) bool
```

##### BashExecutor.Validate

Validate validates a Bash script


```go
func (be *BashExecutor) Validate(script *ManagedScript) error
```

### BatchExecutor

BatchExecutor executes Batch scripts (Windows)


#### Methods

##### BatchExecutor.Execute

Execute executes a Batch script


```go
func (bte *BatchExecutor) Execute(ctx context.Context, script *ManagedScript, args map[string]interface{}) (*ExecutionResult, error)
```

##### BatchExecutor.GetDefaultTimeout

GetDefaultTimeout returns the default timeout for Batch scripts


```go
func (bte *BatchExecutor) GetDefaultTimeout() time.Duration
```

##### BatchExecutor.SupportsType

SupportsType checks if this executor supports the script type


```go
func (bte *BatchExecutor) SupportsType(scriptType ScriptType) bool
```

##### BatchExecutor.Validate

Validate validates a Batch script


```go
func (bte *BatchExecutor) Validate(script *ManagedScript) error
```

### CircuitBreaker

CircuitBreaker provides resilience patterns (placeholder for integration)


### Config

Config defines the configuration for the Script Manager


### ErrorHooks

ErrorHooks defines error handling hooks


### ErrorManager

ErrorManager provides centralized error handling


#### Methods

##### ErrorManager.ProcessError

ProcessError handles errors through the centralized ErrorManager system


```go
func (em *ErrorManager) ProcessError(ctx context.Context, err error, hooks *ErrorHooks) error
```

### ExecutionResult

ExecutionResult represents the result of script execution


### JavaScriptExecutor

JavaScriptExecutor executes JavaScript/Node.js scripts


#### Methods

##### JavaScriptExecutor.Execute

Execute executes a JavaScript script


```go
func (jse *JavaScriptExecutor) Execute(ctx context.Context, script *ManagedScript, args map[string]interface{}) (*ExecutionResult, error)
```

##### JavaScriptExecutor.GetDefaultTimeout

GetDefaultTimeout returns the default timeout for JavaScript scripts


```go
func (jse *JavaScriptExecutor) GetDefaultTimeout() time.Duration
```

##### JavaScriptExecutor.SupportsType

SupportsType checks if this executor supports the script type


```go
func (jse *JavaScriptExecutor) SupportsType(scriptType ScriptType) bool
```

##### JavaScriptExecutor.Validate

Validate validates a JavaScript script


```go
func (jse *JavaScriptExecutor) Validate(script *ManagedScript) error
```

### ManagedScript

ManagedScript represents a script under management


### PowerShellExecutor

PowerShellExecutor executes PowerShell scripts


#### Methods

##### PowerShellExecutor.Execute

Execute executes a PowerShell script


```go
func (pse *PowerShellExecutor) Execute(ctx context.Context, script *ManagedScript, args map[string]interface{}) (*ExecutionResult, error)
```

##### PowerShellExecutor.GetDefaultTimeout

GetDefaultTimeout returns the default timeout for PowerShell scripts


```go
func (pse *PowerShellExecutor) GetDefaultTimeout() time.Duration
```

##### PowerShellExecutor.SupportsType

SupportsType checks if this executor supports the script type


```go
func (pse *PowerShellExecutor) SupportsType(scriptType ScriptType) bool
```

##### PowerShellExecutor.Validate

Validate validates a PowerShell script


```go
func (pse *PowerShellExecutor) Validate(script *ManagedScript) error
```

### PythonExecutor

PythonExecutor executes Python scripts


#### Methods

##### PythonExecutor.Execute

Execute executes a Python script


```go
func (pe *PythonExecutor) Execute(ctx context.Context, script *ManagedScript, args map[string]interface{}) (*ExecutionResult, error)
```

##### PythonExecutor.GetDefaultTimeout

GetDefaultTimeout returns the default timeout for Python scripts


```go
func (pe *PythonExecutor) GetDefaultTimeout() time.Duration
```

##### PythonExecutor.SupportsType

SupportsType checks if this executor supports the script type


```go
func (pe *PythonExecutor) SupportsType(scriptType ScriptType) bool
```

##### PythonExecutor.Validate

Validate validates a Python script


```go
func (pe *PythonExecutor) Validate(script *ManagedScript) error
```

### RetryPolicy

RetryPolicy defines retry behavior for failed scripts


### ScriptExecutor

ScriptExecutor interface for different script types


### ScriptManager

ScriptManager manages script execution and lifecycle with ErrorManager integration


#### Methods

##### ScriptManager.CreateScriptFromTemplate

CreateScriptFromTemplate creates a new script from a template


```go
func (sm *ScriptManager) CreateScriptFromTemplate(templateID, scriptName string, parameters map[string]interface{}) (*ManagedScript, error)
```

##### ScriptManager.ExecuteScript

ExecuteScript executes a script with the specified parameters


```go
func (sm *ScriptManager) ExecuteScript(scriptID string, parameters map[string]interface{}) (*ExecutionResult, error)
```

##### ScriptManager.GetMetrics

GetMetrics returns performance and usage metrics


```go
func (sm *ScriptManager) GetMetrics() map[string]interface{}
```

##### ScriptManager.GetScript

GetScript returns a specific script by ID


```go
func (sm *ScriptManager) GetScript(scriptID string) (*ManagedScript, error)
```

##### ScriptManager.GetScriptByName

GetScriptByName returns a script by name


```go
func (sm *ScriptManager) GetScriptByName(name string) (*ManagedScript, error)
```

##### ScriptManager.ListModules

ListModules returns a list of all available modules


```go
func (sm *ScriptManager) ListModules() []*ScriptModule
```

##### ScriptManager.ListScripts

ListScripts returns a list of all managed scripts


```go
func (sm *ScriptManager) ListScripts() []*ManagedScript
```

##### ScriptManager.ListTemplates

ListTemplates returns a list of all available templates


```go
func (sm *ScriptManager) ListTemplates() []*ScriptTemplate
```

##### ScriptManager.Shutdown

Shutdown gracefully shuts down the Script Manager


```go
func (sm *ScriptManager) Shutdown() error
```

##### ScriptManager.ValidateScript

ValidateScript validates a script for syntax and dependencies


```go
func (sm *ScriptManager) ValidateScript(scriptID string) error
```

### ScriptModule

ScriptModule represents a PowerShell module or script library


### ScriptStatus

ScriptStatus defines the status of a script


### ScriptTemplate

ScriptTemplate represents a script template for generation


### ScriptType

ScriptType defines the type of script


### TemplateParameter

TemplateParameter represents a template parameter


