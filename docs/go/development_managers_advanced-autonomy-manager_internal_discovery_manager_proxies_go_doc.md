# Package discovery

Package discovery provides service discovery capabilities for the AdvancedAutonomyManager

Package discovery implements manager discovery and connection mechanisms
for the AdvancedAutonomyManager to connect to all 20 ecosystem managers

Package discovery implements proxy patterns for connecting to different types of managers


## Types

### ComposeFileInfo

ComposeFileInfo contains information about a discovered docker-compose file


### ConnectionStatus

ConnectionStatus définit l'état d'une connexion manager


### DiscoveryConfig

DiscoveryConfig configure le service de découverte des managers


### InfrastructureDiscoveryService

InfrastructureDiscoveryService provides discovery for infrastructure components


#### Methods

##### InfrastructureDiscoveryService.GetContainerManagerInfo

GetContainerManagerInfo returns information about the discovered container manager


```go
func (ids *InfrastructureDiscoveryService) GetContainerManagerInfo() (*ServiceInfo, bool)
```

##### InfrastructureDiscoveryService.GetDiscoveredComposeFiles

GetDiscoveredComposeFiles returns all discovered docker-compose files


```go
func (ids *InfrastructureDiscoveryService) GetDiscoveredComposeFiles() []*ComposeFileInfo
```

##### InfrastructureDiscoveryService.GetDiscoveredServices

GetDiscoveredServices returns all discovered services


```go
func (ids *InfrastructureDiscoveryService) GetDiscoveredServices() []*ServiceInfo
```

##### InfrastructureDiscoveryService.GetStorageManagerInfo

GetStorageManagerInfo returns information about the discovered storage manager


```go
func (ids *InfrastructureDiscoveryService) GetStorageManagerInfo() (*ServiceInfo, bool)
```

##### InfrastructureDiscoveryService.RegisterService

RegisterService registers a new infrastructure service


```go
func (ids *InfrastructureDiscoveryService) RegisterService(serviceInfo *ServiceInfo)
```

##### InfrastructureDiscoveryService.Start

Start begins the discovery process


```go
func (ids *InfrastructureDiscoveryService) Start(ctx context.Context) error
```

##### InfrastructureDiscoveryService.Stop

Stop halts the discovery process


```go
func (ids *InfrastructureDiscoveryService) Stop()
```

### ManagerConnection

ManagerConnection représente une connexion à un manager découvert


### ManagerDiscoveryService

ManagerDiscoveryService découvre et connecte aux 20 managers de l'écosystème FMOUA


#### Methods

##### ManagerDiscoveryService.Cleanup

Cleanup nettoie les ressources du service de découverte


```go
func (mds *ManagerDiscoveryService) Cleanup() error
```

##### ManagerDiscoveryService.DiscoverAllManagers

DiscoverAllManagers découvre tous les managers de l'écosystème


```go
func (mds *ManagerDiscoveryService) DiscoverAllManagers(ctx context.Context) (map[string]interfaces.BaseManager, error)
```

##### ManagerDiscoveryService.GetConnectionPool

GetConnectionPool retourne le pool de connexions actives


```go
func (mds *ManagerDiscoveryService) GetConnectionPool() map[string]interfaces.BaseManager
```

##### ManagerDiscoveryService.GetDiscoveredManagers

GetDiscoveredManagers retourne tous les managers découverts


```go
func (mds *ManagerDiscoveryService) GetDiscoveredManagers() map[string]*ManagerConnection
```

##### ManagerDiscoveryService.Initialize

Initialize initialise le service de découverte


```go
func (mds *ManagerDiscoveryService) Initialize(ctx context.Context) error
```

##### ManagerDiscoveryService.MonitorConnections

MonitorConnections surveille les connexions et maintient leur santé


```go
func (mds *ManagerDiscoveryService) MonitorConnections(ctx context.Context)
```

### ManagerProxy

ManagerProxy est un proxy générique pour les managers basés sur le système de fichiers


#### Methods

##### ManagerProxy.Cleanup

Cleanup nettoie les ressources du proxy


```go
func (mp *ManagerProxy) Cleanup() error
```

##### ManagerProxy.GetConfiguration

GetConfiguration retourne la configuration


```go
func (mp *ManagerProxy) GetConfiguration() interface{}
```

##### ManagerProxy.GetDependencies

GetDependencies retourne les dépendances


```go
func (mp *ManagerProxy) GetDependencies() []string
```

##### ManagerProxy.GetHealth

GetHealth retourne le statut de santé


```go
func (mp *ManagerProxy) GetHealth() interfaces.HealthStatus
```

##### ManagerProxy.GetMetrics

GetMetrics retourne les métriques


```go
func (mp *ManagerProxy) GetMetrics() map[string]interface{}
```

##### ManagerProxy.GetName

GetName retourne le nom du manager


```go
func (mp *ManagerProxy) GetName() string
```

##### ManagerProxy.GetStatus

GetStatus retourne le statut du manager


```go
func (mp *ManagerProxy) GetStatus() string
```

##### ManagerProxy.GetVersion

GetVersion retourne la version du manager


```go
func (mp *ManagerProxy) GetVersion() string
```

##### ManagerProxy.HealthCheck

HealthCheck vérifie la santé du manager via le proxy


```go
func (mp *ManagerProxy) HealthCheck(ctx context.Context) error
```

##### ManagerProxy.Initialize

Initialize initialise le proxy manager


```go
func (mp *ManagerProxy) Initialize(ctx context.Context) error
```

##### ManagerProxy.ProcessOperation

ProcessOperation traite une opération


```go
func (mp *ManagerProxy) ProcessOperation(operation *interfaces.Operation) error
```

##### ManagerProxy.Start

Start démarre le manager


```go
func (mp *ManagerProxy) Start(ctx context.Context) error
```

##### ManagerProxy.Stop

Stop arrête le manager


```go
func (mp *ManagerProxy) Stop(ctx context.Context) error
```

##### ManagerProxy.UpdateConfiguration

UpdateConfiguration met à jour la configuration


```go
func (mp *ManagerProxy) UpdateConfiguration(config interface{}) error
```

##### ManagerProxy.ValidateConfiguration

ValidateConfiguration valide la configuration


```go
func (mp *ManagerProxy) ValidateConfiguration() error
```

### MockManagerProxy

MockManagerProxy est un proxy fictif pour les tests et le développement


#### Methods

##### MockManagerProxy.Cleanup

Cleanup nettoie les ressources du proxy mock


```go
func (mmp *MockManagerProxy) Cleanup() error
```

##### MockManagerProxy.ExecuteCommand

ExecuteCommand simule l'exécution d'une commande


```go
func (mmp *MockManagerProxy) ExecuteCommand(ctx context.Context, command string, params map[string]interface{}) (map[string]interface{}, error)
```

##### MockManagerProxy.GetCapabilities

GetCapabilities retourne les capacités du manager mock


```go
func (mmp *MockManagerProxy) GetCapabilities() []string
```

##### MockManagerProxy.GetConfiguration

GetConfiguration retourne la configuration mock


```go
func (mmp *MockManagerProxy) GetConfiguration() interface{}
```

##### MockManagerProxy.GetDependencies

GetDependencies retourne les dépendances mock


```go
func (mmp *MockManagerProxy) GetDependencies() []string
```

##### MockManagerProxy.GetHealth

GetHealth retourne le statut de santé mock


```go
func (mmp *MockManagerProxy) GetHealth() interfaces.HealthStatus
```

##### MockManagerProxy.GetMetrics

GetMetrics retourne les métriques mock (corrigé la signature)


```go
func (mmp *MockManagerProxy) GetMetrics() map[string]interface{}
```

##### MockManagerProxy.GetName

GetName retourne le nom du manager


```go
func (mmp *MockManagerProxy) GetName() string
```

##### MockManagerProxy.GetStatus

GetStatus retourne le statut du manager


```go
func (mmp *MockManagerProxy) GetStatus() string
```

##### MockManagerProxy.GetVersion

GetVersion retourne la version du manager


```go
func (mmp *MockManagerProxy) GetVersion() string
```

##### MockManagerProxy.HealthCheck

HealthCheck simule une vérification de santé


```go
func (mmp *MockManagerProxy) HealthCheck(ctx context.Context) error
```

##### MockManagerProxy.Initialize

Initialize initialise le proxy mock


```go
func (mmp *MockManagerProxy) Initialize(ctx context.Context) error
```

##### MockManagerProxy.ProcessOperation

ProcessOperation traite une opération mock


```go
func (mmp *MockManagerProxy) ProcessOperation(operation *interfaces.Operation) error
```

##### MockManagerProxy.SimulateFailure

SimulateFailure simule une défaillance pour les tests


```go
func (mmp *MockManagerProxy) SimulateFailure(failureType string) error
```

##### MockManagerProxy.Start

Start démarre le manager mock


```go
func (mmp *MockManagerProxy) Start(ctx context.Context) error
```

##### MockManagerProxy.Stop

Stop arrête le manager mock


```go
func (mmp *MockManagerProxy) Stop(ctx context.Context) error
```

##### MockManagerProxy.UpdateConfiguration

UpdateConfiguration met à jour la configuration mock


```go
func (mmp *MockManagerProxy) UpdateConfiguration(config interface{}) error
```

##### MockManagerProxy.ValidateConfiguration

ValidateConfiguration valide la configuration mock


```go
func (mmp *MockManagerProxy) ValidateConfiguration() error
```

### NetworkManagerProxy

NetworkManagerProxy est un proxy pour les managers accessibles via réseau


#### Methods

##### NetworkManagerProxy.Cleanup

Cleanup nettoie les ressources du proxy réseau


```go
func (nmp *NetworkManagerProxy) Cleanup() error
```

##### NetworkManagerProxy.ExecuteCommand

ExecuteCommand exécute une commande sur le manager distant


```go
func (nmp *NetworkManagerProxy) ExecuteCommand(ctx context.Context, command string, params map[string]interface{}) (map[string]interface{}, error)
```

##### NetworkManagerProxy.GetConfiguration

GetConfiguration retourne la configuration


```go
func (nmp *NetworkManagerProxy) GetConfiguration() interface{}
```

##### NetworkManagerProxy.GetDependencies

GetDependencies retourne les dépendances


```go
func (nmp *NetworkManagerProxy) GetDependencies() []string
```

##### NetworkManagerProxy.GetHealth

GetHealth retourne le statut de santé


```go
func (nmp *NetworkManagerProxy) GetHealth() interfaces.HealthStatus
```

##### NetworkManagerProxy.GetMetrics

GetMetrics retourne les métriques


```go
func (nmp *NetworkManagerProxy) GetMetrics() map[string]interface{}
```

##### NetworkManagerProxy.GetName

GetName retourne le nom du manager


```go
func (nmp *NetworkManagerProxy) GetName() string
```

##### NetworkManagerProxy.GetStatus

GetStatus retourne le statut du manager


```go
func (nmp *NetworkManagerProxy) GetStatus() string
```

##### NetworkManagerProxy.GetVersion

GetVersion retourne la version du manager


```go
func (nmp *NetworkManagerProxy) GetVersion() string
```

##### NetworkManagerProxy.HealthCheck

HealthCheck vérifie la santé du manager via HTTP


```go
func (nmp *NetworkManagerProxy) HealthCheck(ctx context.Context) error
```

##### NetworkManagerProxy.Initialize

Initialize initialise le proxy réseau


```go
func (nmp *NetworkManagerProxy) Initialize(ctx context.Context) error
```

##### NetworkManagerProxy.ProcessOperation

ProcessOperation traite une opération


```go
func (nmp *NetworkManagerProxy) ProcessOperation(operation *interfaces.Operation) error
```

##### NetworkManagerProxy.Start

Start démarre le manager distant


```go
func (nmp *NetworkManagerProxy) Start(ctx context.Context) error
```

##### NetworkManagerProxy.Stop

Stop arrête le manager distant


```go
func (nmp *NetworkManagerProxy) Stop(ctx context.Context) error
```

##### NetworkManagerProxy.UpdateConfiguration

UpdateConfiguration met à jour la configuration


```go
func (nmp *NetworkManagerProxy) UpdateConfiguration(config interface{}) error
```

##### NetworkManagerProxy.ValidateConfiguration

ValidateConfiguration valide la configuration


```go
func (nmp *NetworkManagerProxy) ValidateConfiguration() error
```

### ServiceInfo

ServiceInfo contains information about a discovered service


### ServiceType

ServiceType defines the type of service being discovered


## Variables

### ExpectedEcosystemManagers

Noms des 20 managers de l'écosystème FMOUA


```go
var ExpectedEcosystemManagers = []string{
	"file-manager",
	"dependency-manager",
	"config-manager",
	"security-manager",
	"monitoring-manager",
	"storage-manager",
	"container-manager",
	"deployment-manager",
	"network-manager",
	"backup-manager",
	"log-manager",
	"cache-manager",
	"task-manager",
	"notification-manager",
	"workflow-manager",
	"template-manager",
	"error-manager",
	"maintenance-manager",
	"contextual-memory-manager",
	"mcp-manager",
}
```

