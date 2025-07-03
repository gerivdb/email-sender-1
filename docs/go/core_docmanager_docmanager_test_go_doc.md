# Package docmanager

## Types

### AuditResult

### BranchAware

Gestion multi-branches


### BranchDocStatus

### BranchSynchronizer

### Cache

### Config

Types de base (stubs pour Phase 1)


### DocManager

#### Methods

##### DocManager.CreateDocument

Implémentation stub de CreateDocument


```go
func (dm *DocManager) CreateDocument(ctx context.Context, doc *Document) error
```

##### DocManager.SyncAcrossBranches

Implémentation stub de SyncAcrossBranches


```go
func (dm *DocManager) SyncAcrossBranches(ctx context.Context) error
```

### Document

### DocumentManager

Interface principale de gestion documentaire


### InfluxClient

### ManagerIntegrator

Intégration des managers


### ManagerStatus

### ManagerType

### Objective

### Orchestrator

### OrchestratorImpl

#### Methods

##### OrchestratorImpl.DefineObjectives

```go
func (o *OrchestratorImpl) DefineObjectives(objs []Objective) error
```

##### OrchestratorImpl.ValidateObjectives

```go
func (o *OrchestratorImpl) ValidateObjectives() bool
```

### PathResilient

Résilience aux déplacements de fichiers


### PathTracker

### PostgresClient

### QDrantClient

### RedisClient

### Repository

Abstraction du repository documentaire


### SearchQuery

### Vectorizer

## Functions

### DetectDependencies

```go
func DetectDependencies(managerName string) ([]string, error)
```

### SyncInterfaces

```go
func SyncInterfaces(ctx context.Context, managerName string) error
```

