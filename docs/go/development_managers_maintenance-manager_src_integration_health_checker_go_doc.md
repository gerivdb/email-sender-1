# Package integration

## Types

### ComprehensiveHealthChecker

ComprehensiveHealthChecker performs deeper health analysis


#### Methods

##### ComprehensiveHealthChecker.CheckHealth

CheckHealth performs comprehensive health analysis


```go
func (chc *ComprehensiveHealthChecker) CheckHealth(ctx context.Context) HealthStatus
```

### DefaultHealthChecker

DefaultHealthChecker provides a concrete implementation of HealthChecker


#### Methods

##### DefaultHealthChecker.CheckHealth

CheckHealth performs an immediate health check


```go
func (dhc *DefaultHealthChecker) CheckHealth(ctx context.Context) HealthStatus
```

##### DefaultHealthChecker.GetHealthHistory

GetHealthHistory returns the health check history


```go
func (dhc *DefaultHealthChecker) GetHealthHistory() []HealthStatus
```

##### DefaultHealthChecker.GetHealthMetrics

GetHealthMetrics returns current health metrics


```go
func (dhc *DefaultHealthChecker) GetHealthMetrics() map[string]interface{}
```

##### DefaultHealthChecker.GetHealthSummary

GetHealthSummary returns a summary of health status


```go
func (dhc *DefaultHealthChecker) GetHealthSummary() map[string]interface{}
```

##### DefaultHealthChecker.GetLastHealthCheck

GetLastHealthCheck returns the timestamp of the last health check


```go
func (dhc *DefaultHealthChecker) GetLastHealthCheck() time.Time
```

##### DefaultHealthChecker.IsCurrentlyHealthy

IsCurrentlyHealthy returns the current health status


```go
func (dhc *DefaultHealthChecker) IsCurrentlyHealthy() bool
```

##### DefaultHealthChecker.SetCheckInterval

SetCheckInterval updates the check interval


```go
func (dhc *DefaultHealthChecker) SetCheckInterval(interval time.Duration)
```

##### DefaultHealthChecker.StartBackgroundChecks

StartBackgroundChecks starts periodic health checks


```go
func (dhc *DefaultHealthChecker) StartBackgroundChecks()
```

##### DefaultHealthChecker.StopBackgroundChecks

StopBackgroundChecks stops periodic health checks


```go
func (dhc *DefaultHealthChecker) StopBackgroundChecks()
```

### DefaultManagerCoordinator

DefaultManagerCoordinator provides a concrete implementation of ManagerCoordinator


#### Methods

##### DefaultManagerCoordinator.ExecuteOperation

ExecuteOperation executes an operation on the managed component


```go
func (dmc *DefaultManagerCoordinator) ExecuteOperation(ctx context.Context, op *Operation) (*OperationResult, error)
```

##### DefaultManagerCoordinator.GetCapabilities

GetCapabilities returns the list of capabilities


```go
func (dmc *DefaultManagerCoordinator) GetCapabilities() []string
```

##### DefaultManagerCoordinator.GetMetrics

GetMetrics returns coordination metrics


```go
func (dmc *DefaultManagerCoordinator) GetMetrics() map[string]interface{}
```

##### DefaultManagerCoordinator.GetStatus

GetStatus returns the current status of the manager


```go
func (dmc *DefaultManagerCoordinator) GetStatus() ManagerStatus
```

##### DefaultManagerCoordinator.GetVersion

GetVersion returns the manager version


```go
func (dmc *DefaultManagerCoordinator) GetVersion() string
```

##### DefaultManagerCoordinator.IsHealthy

IsHealthy returns the current health status


```go
func (dmc *DefaultManagerCoordinator) IsHealthy() bool
```

##### DefaultManagerCoordinator.SetStatus

SetStatus updates the manager status


```go
func (dmc *DefaultManagerCoordinator) SetStatus(status ManagerStatus)
```

### Event

Event represents an event in the system


### EventBus

EventBus handles inter-manager communication and events


#### Methods

##### EventBus.GetEventHistory

GetEventHistory returns recent event history


```go
func (eb *EventBus) GetEventHistory(limit int) []*Event
```

##### EventBus.GetMetrics

GetMetrics returns event bus metrics


```go
func (eb *EventBus) GetMetrics() *EventMetrics
```

##### EventBus.Initialize

Initialize initializes the event bus


```go
func (eb *EventBus) Initialize() error
```

##### EventBus.Publish

Publish publishes an event to the bus


```go
func (eb *EventBus) Publish(event *Event) error
```

##### EventBus.PublishManagerRegistered

Common event publishers


```go
func (eb *EventBus) PublishManagerRegistered(managerName string, capabilities []string) error
```

##### EventBus.PublishOperationCompleted

```go
func (eb *EventBus) PublishOperationCompleted(operationID string, success bool, duration time.Duration) error
```

##### EventBus.PublishOperationStarted

```go
func (eb *EventBus) PublishOperationStarted(operationID string, operationType string, managers []string) error
```

##### EventBus.PublishSync

PublishSync publishes an event synchronously and waits for processing


```go
func (eb *EventBus) PublishSync(ctx context.Context, event *Event) error
```

##### EventBus.PublishSystemAlert

```go
func (eb *EventBus) PublishSystemAlert(level string, message string, component string) error
```

##### EventBus.Shutdown

Shutdown gracefully shuts down the event bus


```go
func (eb *EventBus) Shutdown() error
```

##### EventBus.Subscribe

Subscribe subscribes to specific event types


```go
func (eb *EventBus) Subscribe(eventType string, handler EventHandler)
```

##### EventBus.Unsubscribe

Unsubscribe removes a handler from event type (simplified implementation)


```go
func (eb *EventBus) Unsubscribe(eventType string, handler EventHandler)
```

### EventMetrics

EventMetrics tracks event bus performance


### HealthChecker

HealthChecker monitors manager health


### HealthIssue

HealthIssue represents specific health problems


### HealthStatus

HealthStatus represents health check results


### HubMetrics

HubMetrics tracks integration hub performance


### IntegrationHub

IntegrationHub coordinates with all 17 managers in the ecosystem


#### Methods

##### IntegrationHub.ExecuteOperation

ExecuteOperation executes a coordinated operation across managers


```go
func (ih *IntegrationHub) ExecuteOperation(ctx context.Context, op *Operation) (*OperationResult, error)
```

##### IntegrationHub.GetHealthStatus

GetHealthStatus returns overall system health


```go
func (ih *IntegrationHub) GetHealthStatus() *SystemHealthStatus
```

##### IntegrationHub.GetManagerStates

GetManagerStates returns the current state of all managers


```go
func (ih *IntegrationHub) GetManagerStates() map[string]ManagerState
```

##### IntegrationHub.Initialize

Initialize initializes the integration hub and discovers managers


```go
func (ih *IntegrationHub) Initialize(ctx context.Context) error
```

##### IntegrationHub.RegisterManager

RegisterManager registers a manager with the hub


```go
func (ih *IntegrationHub) RegisterManager(name string, coordinator ManagerCoordinator, healthChecker HealthChecker) error
```

##### IntegrationHub.Shutdown

Shutdown gracefully shuts down the integration hub


```go
func (ih *IntegrationHub) Shutdown(ctx context.Context) error
```

##### IntegrationHub.SubscribeToEvents

SubscribeToEvents subscribes to specific event types


```go
func (ih *IntegrationHub) SubscribeToEvents(eventType string, handler EventHandler)
```

### ManagerCoordinator

ManagerCoordinator defines interface for manager coordination


### ManagerState

ManagerState represents the current state of a manager


### ManagerStatus

ManagerStatus represents different manager states


### MetricCollector

MetricCollector interface for managers that provide metrics


### Operation

Operation represents a coordinated operation across managers


### OperationResult

OperationResult represents the result of an operation


### OperationStatus

OperationStatus represents operation states


### SystemHealthStatus

SystemHealthStatus represents overall system health


## Constants

### EventTypeManagerRegistered, EventTypeManagerUnregistered, EventTypeOperationStarted, EventTypeOperationCompleted, EventTypeOperationFailed, EventTypeHealthCheckFailed, EventTypeSystemAlert, EventTypeConfigChanged, EventTypeMaintenanceStarted, EventTypeMaintenanceCompleted

Built-in event types


```go
const (
	EventTypeManagerRegistered	= "manager_registered"
	EventTypeManagerUnregistered	= "manager_unregistered"
	EventTypeOperationStarted	= "operation_started"
	EventTypeOperationCompleted	= "operation_completed"
	EventTypeOperationFailed	= "operation_failed"
	EventTypeHealthCheckFailed	= "health_check_failed"
	EventTypeSystemAlert		= "system_alert"
	EventTypeConfigChanged		= "config_changed"
	EventTypeMaintenanceStarted	= "maintenance_started"
	EventTypeMaintenanceCompleted	= "maintenance_completed"
)
```

