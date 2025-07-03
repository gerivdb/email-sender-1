# Package evolution

## Types

### CompatibilityRule

CompatibilityRule définit une règle de compatibilité


### CompatibilityValidator

CompatibilityValidator valide la compatibilité entre versions


#### Methods

##### CompatibilityValidator.ValidateCompatibility

ValidateCompatibility valide la compatibilité entre deux versions


```go
func (cv *CompatibilityValidator) ValidateCompatibility(from, to Version) (bool, []string, error)
```

### EvolutionManager

EvolutionManager gère les migrations et évolutions du système


#### Methods

##### EvolutionManager.ExecuteMigration

ExecuteMigration exécute une migration


```go
func (em *EvolutionManager) ExecuteMigration(ctx context.Context, migration Migration) error
```

##### EvolutionManager.PlanMigration

PlanMigration planifie une migration entre deux versions


```go
func (em *EvolutionManager) PlanMigration(from, to Version) (*MigrationPlan, error)
```

### EvolutionMetrics

EvolutionMetrics contient les métriques d'évolution


### Migration

Migration représente une migration système


### MigrationPlan

MigrationPlan représente un plan de migration


### MigrationStep

MigrationStep représente une étape de migration


### RiskLevel

RiskLevel définit le niveau de risque d'une migration


### Rollback

Rollback représente une procédure de rollback


### StepType

StepType définit le type d'étape de migration


### Version

Version représente une version du système


#### Methods

##### Version.Compare

Compare compare deux versions (-1: plus ancienne, 0: égale, 1: plus récente)


```go
func (v Version) Compare(other Version) int
```

##### Version.String

String retourne une représentation string de la version


```go
func (v Version) String() string
```

