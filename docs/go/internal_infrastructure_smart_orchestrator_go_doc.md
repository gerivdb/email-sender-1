# Package infrastructure

## Types

### EnvironmentInfo

EnvironmentInfo contient les informations sur l'environnement détecté


### InfrastructureOrchestrator

InfrastructureOrchestrator définit l'interface pour l'orchestration de l'infrastructure


### ResourceInfo

ResourceInfo contient les informations sur les ressources système


### ServiceState

ServiceState représente l'état d'un service individuel


### ServiceStatus

ServiceStatus représente l'état des services


### SmartInfrastructureManager

SmartInfrastructureManager implémente InfrastructureOrchestrator


#### Methods

##### SmartInfrastructureManager.AutoRecover

AutoRecover tente de récupérer automatiquement les services défaillants


```go
func (sim *SmartInfrastructureManager) AutoRecover(ctx context.Context) error
```

##### SmartInfrastructureManager.DetectEnvironment

DetectEnvironment détecte automatiquement l'environnement et la configuration


```go
func (sim *SmartInfrastructureManager) DetectEnvironment() (*EnvironmentInfo, error)
```

##### SmartInfrastructureManager.EnableAutoHealing

EnableAutoHealing active ou désactive le système d'auto-healing


```go
func (sim *SmartInfrastructureManager) EnableAutoHealing(enabled bool) error
```

##### SmartInfrastructureManager.GetAdvancedHealthStatus

GetAdvancedHealthStatus retourne le statut de santé avancé de tous les services


```go
func (sim *SmartInfrastructureManager) GetAdvancedHealthStatus(ctx context.Context) (map[string]monitoring.ServiceHealthStatus, error)
```

##### SmartInfrastructureManager.GetMonitoringStatus

GetMonitoringStatus retourne l'état actuel du système de monitoring avancé


```go
func (sim *SmartInfrastructureManager) GetMonitoringStatus() monitoring.MonitoringStatus
```

##### SmartInfrastructureManager.GetServiceStatus

GetServiceStatus retourne l'état actuel de tous les services


```go
func (sim *SmartInfrastructureManager) GetServiceStatus(ctx context.Context) (ServiceStatus, error)
```

##### SmartInfrastructureManager.HealthCheck

HealthCheck effectue une vérification globale de la santé du système


```go
func (sim *SmartInfrastructureManager) HealthCheck(ctx context.Context) error
```

##### SmartInfrastructureManager.StartAdvancedMonitoring

StartAdvancedMonitoring démarre le système de monitoring avancé


```go
func (sim *SmartInfrastructureManager) StartAdvancedMonitoring(ctx context.Context) error
```

##### SmartInfrastructureManager.StartServices

StartServices démarre les services dans l'ordre approprié


```go
func (sim *SmartInfrastructureManager) StartServices(ctx context.Context) error
```

##### SmartInfrastructureManager.StopAdvancedMonitoring

StopAdvancedMonitoring arrête le système de monitoring avancé


```go
func (sim *SmartInfrastructureManager) StopAdvancedMonitoring() error
```

##### SmartInfrastructureManager.StopServices

StopServices arrête tous les services


```go
func (sim *SmartInfrastructureManager) StopServices(ctx context.Context) error
```

