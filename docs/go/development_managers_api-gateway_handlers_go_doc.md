# Package main

## Types

### APIGateway

APIGateway centralise tous les endpoints de l'écosystème


#### Methods

##### APIGateway.RegisterManager

RegisterManager enregistre un manager dans la gateway


```go
func (ag *APIGateway) RegisterManager(name string, manager ManagerInterface)
```

##### APIGateway.SetupRoutes

SetupRoutes configure tous les endpoints de l'API


```go
func (ag *APIGateway) SetupRoutes()
```

##### APIGateway.Start

Start démarre le serveur API Gateway


```go
func (ag *APIGateway) Start(ctx context.Context, port int) error
```

##### APIGateway.Stop

Stop arrête le serveur API Gateway


```go
func (ag *APIGateway) Stop(ctx context.Context) error
```

### ManagerInterface

ManagerInterface définit l'interface commune pour tous les managers


