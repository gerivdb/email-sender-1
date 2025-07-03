# Package main

Package bridge implements the PowerShell-Go bridge for ErrorManager integration
Section 1.4 - Implementation des Recommandations


## Types

### BridgeConfig

BridgeConfig holds configuration for the PowerShell bridge


### BridgeStats

BridgeStats tracks bridge statistics


### ErrorManagerService

ErrorManagerService provides logging capabilities for the bridge


#### Methods

##### ErrorManagerService.ProcessPowerShellError

ProcessPowerShellError processes an error from PowerShell


```go
func (ems *ErrorManagerService) ProcessPowerShellError(ctx context.Context, psError PowerShellError) (*PowerShellErrorResponse, error)
```

### PowerShellBridge

PowerShellBridge implements the bridge server


#### Methods

##### PowerShellBridge.Start

Start starts the PowerShell bridge server


```go
func (pb *PowerShellBridge) Start() error
```

##### PowerShellBridge.Stop

Stop gracefully stops the PowerShell bridge server


```go
func (pb *PowerShellBridge) Stop(ctx context.Context) error
```

### PowerShellError

PowerShellError represents an error received from PowerShell


### PowerShellErrorResponse

PowerShellErrorResponse represents the response sent back to PowerShell


