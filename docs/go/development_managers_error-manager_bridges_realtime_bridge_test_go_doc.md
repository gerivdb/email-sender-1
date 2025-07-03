# Package bridges

Package bridges implementes the real-time monitoring bridge for Section 8.2
"Optimisation Surveillance Temps Réel" of plan-dev-v42-error-manager.md


## Types

### RealtimeBridge

RealtimeBridge implements real-time monitoring capabilities


#### Methods

##### RealtimeBridge.ClearEvents

ClearEvents clears the event buffer


```go
func (rb *RealtimeBridge) ClearEvents()
```

##### RealtimeBridge.GetEventCount

GetEventCount returns total number of events processed


```go
func (rb *RealtimeBridge) GetEventCount() int64
```

##### RealtimeBridge.GetEvents

GetEvents returns current event buffer (for testing/monitoring)


```go
func (rb *RealtimeBridge) GetEvents() []RealtimeEvent
```

##### RealtimeBridge.Start

Start initiates the real-time monitoring


```go
func (rb *RealtimeBridge) Start() error
```

##### RealtimeBridge.Stop

Stop gracefully stops the real-time bridge


```go
func (rb *RealtimeBridge) Stop() error
```

### RealtimeBridgeConfig

RealtimeBridgeConfig holds configuration for the real-time bridge


### RealtimeEvent

RealtimeEvent represents a real-time file system event


