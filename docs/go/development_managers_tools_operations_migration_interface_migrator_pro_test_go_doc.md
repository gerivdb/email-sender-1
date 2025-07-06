# Package migration

## Types

### FileUpdate

FileUpdate describes what updates are needed for a file


### GeneratedType

GeneratedType représente un type généré automatiquement


### InterfaceLocation

InterfaceLocation specifies where an interface is located


### InterfaceMigrator

InterfaceMigrator handles professional interface migration with backup and validation


#### Methods

##### InterfaceMigrator.CreateBackup

CreateBackup creates a backup of the current state


```go
func (im *InterfaceMigrator) CreateBackup() error
```

##### InterfaceMigrator.CreateInterfacesStructure

CreateInterfacesStructure creates the interfaces directory structure


```go
func (im *InterfaceMigrator) CreateInterfacesStructure() error
```

##### InterfaceMigrator.CreateMigrationPlan

CreateMigrationPlan analyzes the codebase and creates a migration plan


```go
func (im *InterfaceMigrator) CreateMigrationPlan() (*MigrationPlan, error)
```

##### InterfaceMigrator.ExecuteMigration

ExecuteMigration performs the complete migration process


```go
func (im *InterfaceMigrator) ExecuteMigration() error
```

##### InterfaceMigrator.GenerateInterfaceFiles

GenerateInterfaceFiles generates the interface files


```go
func (im *InterfaceMigrator) GenerateInterfaceFiles(plan *MigrationPlan) error
```

##### InterfaceMigrator.GenerateMigrationReport

GenerateMigrationReport generates a migration report in the specified format


```go
func (im *InterfaceMigrator) GenerateMigrationReport(results *MigrationResults, format string) (string, error)
```

##### InterfaceMigrator.MigrateInterfaces

MigrateInterfaces performs interface migration with the given parameters


```go
func (im *InterfaceMigrator) MigrateInterfaces(ctx context.Context, sourceDir, targetDir, newPackage string) (*MigrationResults, error)
```

##### InterfaceMigrator.PrintMigrationPlan

```go
func (im *InterfaceMigrator) PrintMigrationPlan(plan *MigrationPlan)
```

##### InterfaceMigrator.UpdateExistingFiles

UpdateExistingFiles updates existing files according to the plan


```go
func (im *InterfaceMigrator) UpdateExistingFiles(plan *MigrationPlan) error
```

##### InterfaceMigrator.ValidateMigration

ValidateMigration validates that the migration was successful


```go
func (im *InterfaceMigrator) ValidateMigration() error
```

### MigrationPlan

MigrationPlan defines what will be migrated


### MigrationResults

MigrationResults contains the results of a migration operation


### NewFileSpec

NewFileSpec describes a new file to be created


### TypeDefGenerator

TypeDefGenerator implémente l'interface toolkit.ToolkitOperation pour la génération de définitions de types


#### Methods

##### TypeDefGenerator.CollectMetrics

CollectMetrics implémente ToolkitOperation.CollectMetrics


```go
func (tdg *TypeDefGenerator) CollectMetrics() map[string]interface{}
```

##### TypeDefGenerator.Execute

Execute implémente ToolkitOperation.Execute


```go
func (tdg *TypeDefGenerator) Execute(ctx context.Context, options *toolkit.OperationOptions) error
```

##### TypeDefGenerator.GetDescription

GetDescription implémente ToolkitOperation.GetDescription - description de l'outil


```go
func (tdg *TypeDefGenerator) GetDescription() string
```

##### TypeDefGenerator.HealthCheck

HealthCheck implémente ToolkitOperation.HealthCheck


```go
func (tdg *TypeDefGenerator) HealthCheck(ctx context.Context) error
```

##### TypeDefGenerator.Stop

Stop implémente ToolkitOperation.Stop - gestion des signaux d'arrêt


```go
func (tdg *TypeDefGenerator) Stop(ctx context.Context) error
```

##### TypeDefGenerator.String

String implémente ToolkitOperation.String - identification de l'outil


```go
func (tdg *TypeDefGenerator) String() string
```

##### TypeDefGenerator.Validate

Validate implémente ToolkitOperation.Validate


```go
func (tdg *TypeDefGenerator) Validate(ctx context.Context) error
```

### TypeGenReport

TypeGenReport représente le rapport de génération de types


### TypeGenSummary

TypeGenSummary fournit un résumé de la génération


### UndefinedType

UndefinedType représente un type non défini détecté


## Constants

### ToolVersion

ToolVersion defines the current version of this specific tool or the toolkit.


```go
const ToolVersion = "3.0.0"
```

