# Package coordinator

## Types

### CentralCoordinator

CentralCoordinator unifie les responsabilités communes entre managers


#### Methods

##### CentralCoordinator.GetAllManagersStatus

GetAllManagersStatus retourne le statut de tous les managers


```go
func (cc *CentralCoordinator) GetAllManagersStatus() map[string]ManagerStatus
```

##### CentralCoordinator.GetCoordinatorStatus

GetCoordinatorStatus retourne le statut du coordinateur


```go
func (cc *CentralCoordinator) GetCoordinatorStatus() CoordinatorStatus
```

##### CentralCoordinator.HealthCheck

HealthCheck vérifie la santé de tous les managers


```go
func (cc *CentralCoordinator) HealthCheck(ctx context.Context) error
```

##### CentralCoordinator.RegisterManager

RegisterManager enregistre un manager dans le coordinateur


```go
func (cc *CentralCoordinator) RegisterManager(name string, manager ManagerInterface) error
```

##### CentralCoordinator.StartAll

StartAll démarre tous les managers enregistrés


```go
func (cc *CentralCoordinator) StartAll(ctx context.Context) error
```

##### CentralCoordinator.StopAll

StopAll arrête tous les managers enregistrés


```go
func (cc *CentralCoordinator) StopAll(ctx context.Context) error
```

##### CentralCoordinator.UnregisterManager

UnregisterManager retire un manager du coordinateur


```go
func (cc *CentralCoordinator) UnregisterManager(name string) error
```

### CoordinatorStatus

CoordinatorStatus représente l'état du coordinateur


### EventBus

EventBus implémente un système de communication asynchrone entre managers


#### Methods

##### EventBus.Close

Close ferme le bus d'événements


```go
func (eb *EventBus) Close() error
```

##### EventBus.GetMetrics

GetMetrics retourne les métriques du bus d'événements


```go
func (eb *EventBus) GetMetrics() EventBusMetrics
```

##### EventBus.Publish

Publish publie un événement sur le bus


```go
func (eb *EventBus) Publish(ctx context.Context, event *ManagerEvent) error
```

##### EventBus.Subscribe

Subscribe s'abonne à un type d'événement


```go
func (eb *EventBus) Subscribe(eventType string, handler EventHandler) error
```

##### EventBus.Unsubscribe

Unsubscribe se désabonne d'un type d'événement


```go
func (eb *EventBus) Unsubscribe(eventType string, handler EventHandler) error
```

### EventBusMetrics

EventBusMetrics contient les métriques du bus d'événements


### EventFilter

EventFilter définit les critères pour filtrer les événements à persister


### EventHandler

EventHandler définit le type de fonction pour gérer les événements


### EventPriority

EventPriority définit la priorité d'un événement


### EventStore

EventStore gère la persistance des événements critiques


#### Methods

##### EventStore.LoadEvents

LoadEvents charge les événements depuis le disque


```go
func (es *EventStore) LoadEvents(filter EventFilter) ([]*ManagerEvent, error)
```

##### EventStore.StoreEvent

StoreEvent stocke un événement sur disque


```go
func (es *EventStore) StoreEvent(event *ManagerEvent) error
```

### ManagerDiscovery

ManagerDiscovery implémente la découverte automatique de managers


#### Methods

##### ManagerDiscovery.DiscoverManagers

DiscoverManagers découvre automatiquement tous les managers dans l'écosystème


```go
func (md *ManagerDiscovery) DiscoverManagers(ctx context.Context) ([]string, error)
```

##### ManagerDiscovery.GetAllManagers

GetAllManagers retourne tous les managers


```go
func (md *ManagerDiscovery) GetAllManagers() map[string]ManagerInterface
```

##### ManagerDiscovery.GetManager

GetManager retourne un manager par nom


```go
func (md *ManagerDiscovery) GetManager(name string) (ManagerInterface, error)
```

##### ManagerDiscovery.ListManagers

ListManagers retourne la liste de tous les managers découverts


```go
func (md *ManagerDiscovery) ListManagers() []string
```

### ManagerEvent

ManagerEvent représente un événement du système


### ManagerInterface

ManagerInterface définit l'interface commune (duplicata pour éviter import circulaire)


### ManagerMetrics

ManagerMetrics représente les métriques d'un manager


### ManagerStatus

ManagerStatus représente l'état d'un manager


### MockManager

MockManager implémente ManagerInterface pour les tests


#### Methods

##### MockManager.GetID

```go
func (m *MockManager) GetID() string
```

##### MockManager.GetMetrics

```go
func (m *MockManager) GetMetrics() ManagerMetrics
```

##### MockManager.GetName

```go
func (m *MockManager) GetName() string
```

##### MockManager.GetStatus

```go
func (m *MockManager) GetStatus() ManagerStatus
```

##### MockManager.GetVersion

```go
func (m *MockManager) GetVersion() string
```

##### MockManager.Health

```go
func (m *MockManager) Health(ctx context.Context) error
```

##### MockManager.Initialize

```go
func (m *MockManager) Initialize(ctx context.Context, config interface{}) error
```

##### MockManager.Start

```go
func (m *MockManager) Start(ctx context.Context) error
```

##### MockManager.Stop

```go
func (m *MockManager) Stop(ctx context.Context) error
```

##### MockManager.ValidateConfig

```go
func (m *MockManager) ValidateConfig(config interface{}) error
```

### PersistedEvent

PersistedEvent représente un événement stocké sur disque


### PersistentEventBus

PersistentEventBus étend EventBus avec la persistance


#### Methods

##### PersistentEventBus.Close

Close ferme le bus persistant et le store


```go
func (peb *PersistentEventBus) Close() error
```

##### PersistentEventBus.GetPersistedEvents

GetPersistedEvents récupère les événements persistés selon un filtre


```go
func (peb *PersistentEventBus) GetPersistedEvents(filter EventFilter) ([]*ManagerEvent, error)
```

##### PersistentEventBus.Replay

Replay rejone les événements persistés


```go
func (peb *PersistentEventBus) Replay(ctx context.Context, filter EventFilter) error
```

