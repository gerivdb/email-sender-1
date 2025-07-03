# Package gatewaymanager

## Types

### GatewayManager

GatewayManager représente le gestionnaire de passerelle, avec des dépendances sur d'autres managers.


#### Methods

##### GatewayManager.ProcessRequest

ProcessRequest simule le traitement d'une requête, utilisant les managers dépendants.


```go
func (gm *GatewayManager) ProcessRequest(ctx context.Context, requestID string, data map[string]interface{}) (string, error)
```

##### GatewayManager.Start

Start démarre le gestionnaire de passerelle.


```go
func (gm *GatewayManager) Start()
```

