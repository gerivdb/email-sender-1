# Package main

## Types

### APIGateway

### CentralCoordinator

### ConnectionPool

### EcosystemTestSuite

EcosystemTestSuite représente l'environnement de test complet


#### Methods

##### EcosystemTestSuite.Cleanup

```go
func (ets *EcosystemTestSuite) Cleanup()
```

### EventBus

### ManagerInterface

ManagerInterface simulation pour les tests


### ManagerMetrics

### ManagerStatus

### MockManager

MockManager implémente ManagerInterface pour les tests


#### Methods

##### MockManager.GetMetrics

```go
func (mm *MockManager) GetMetrics() ManagerMetrics
```

##### MockManager.GetStatus

```go
func (mm *MockManager) GetStatus() ManagerStatus
```

##### MockManager.Initialize

```go
func (mm *MockManager) Initialize(ctx context.Context, config interface{}) error
```

##### MockManager.Start

```go
func (mm *MockManager) Start(ctx context.Context) error
```

##### MockManager.Stop

```go
func (mm *MockManager) Stop(ctx context.Context) error
```

##### MockManager.ValidateConfig

```go
func (mm *MockManager) ValidateConfig(config interface{}) error
```

### VectorCache

### VectorClient

Structures de simulation pour les tests


