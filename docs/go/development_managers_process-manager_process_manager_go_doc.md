# Package processmanager

## Types

### CircuitBreaker

CircuitBreaker provides circuit breaker functionality for process operations


#### Methods

##### CircuitBreaker.CanExecute

CanExecute checks if the circuit breaker allows execution


```go
func (cb *CircuitBreaker) CanExecute() bool
```

##### CircuitBreaker.RecordFailure

RecordFailure records a failed operation


```go
func (cb *CircuitBreaker) RecordFailure()
```

##### CircuitBreaker.RecordSuccess

RecordSuccess records a successful operation


```go
func (cb *CircuitBreaker) RecordSuccess()
```

### CircuitBreakerConfig

CircuitBreakerConfig holds circuit breaker configuration


### Config

Config holds the process manager configuration


### ErrorManager

ErrorManager encapsulates error management functionality


#### Methods

##### ErrorManager.ProcessError

ProcessError handles and catalogs errors with ErrorManager integration


```go
func (em *ErrorManager) ProcessError(ctx context.Context, err error, component, operation string) error
```

### HealthCheckConfig

HealthCheckConfig defines health check parameters


### ManagedProcess

ManagedProcess represents a process under management


### ManagerManifest

ManagerManifest describes a manager's capabilities and requirements


### ProcessManager

ProcessManager manages the lifecycle of other managers and external processes


#### Methods

##### ProcessManager.ExecuteTask

ExecuteTask executes a task defined in a manager manifest


```go
func (pm *ProcessManager) ExecuteTask(managerName, taskName string, params map[string]interface{}) error
```

##### ProcessManager.GetProcessStatus

GetProcessStatus returns the status of a managed process


```go
func (pm *ProcessManager) GetProcessStatus(name string) (*ManagedProcess, error)
```

##### ProcessManager.HealthCheck

HealthCheck performs health checks on all managed processes


```go
func (pm *ProcessManager) HealthCheck() map[string]bool
```

##### ProcessManager.ListProcesses

ListProcesses returns all managed processes


```go
func (pm *ProcessManager) ListProcesses() map[string]*ManagedProcess
```

##### ProcessManager.LoadManifests

LoadManifests loads manager manifests from the manifest directory


```go
func (pm *ProcessManager) LoadManifests() error
```

##### ProcessManager.Shutdown

Shutdown gracefully shuts down the process manager


```go
func (pm *ProcessManager) Shutdown() error
```

##### ProcessManager.StartProcess

StartProcess starts a new managed process


```go
func (pm *ProcessManager) StartProcess(name, command string, args []string, env map[string]string) (*ManagedProcess, error)
```

##### ProcessManager.StopProcess

StopProcess stops a managed process


```go
func (pm *ProcessManager) StopProcess(name string) error
```

### ProcessStatus

ProcessStatus represents the status of a managed process


### TaskDefinition

TaskDefinition describes a task that can be executed


