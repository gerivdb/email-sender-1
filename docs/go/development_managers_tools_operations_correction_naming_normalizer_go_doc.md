# Package correction

## Types

### ImportAnalysis

ImportAnalysis représente l'analyse d'imports d'un fichier


### ImportConflict

ImportConflict représente un conflit d'import détecté


### ImportConflictResolver

ImportConflictResolver implémente l'interface toolkit.ToolkitOperation pour résoudre les conflits d'imports


#### Methods

##### ImportConflictResolver.CollectMetrics

CollectMetrics implémente ToolkitOperation.CollectMetrics


```go
func (icr *ImportConflictResolver) CollectMetrics() map[string]interface{}
```

##### ImportConflictResolver.Execute

Execute implémente ToolkitOperation.Execute


```go
func (icr *ImportConflictResolver) Execute(ctx context.Context, options *toolkit.OperationOptions) error
```

##### ImportConflictResolver.GetDescription

GetDescription implémente ToolkitOperation.GetDescription - description de l'outil


```go
func (icr *ImportConflictResolver) GetDescription() string
```

##### ImportConflictResolver.HealthCheck

HealthCheck implémente ToolkitOperation.HealthCheck


```go
func (icr *ImportConflictResolver) HealthCheck(ctx context.Context) error
```

##### ImportConflictResolver.Stop

Stop implémente ToolkitOperation.Stop - gestion des signaux d'arrêt


```go
func (icr *ImportConflictResolver) Stop(ctx context.Context) error
```

##### ImportConflictResolver.String

String implémente ToolkitOperation.String - identification de l'outil


```go
func (icr *ImportConflictResolver) String() string
```

##### ImportConflictResolver.Validate

Validate implémente ToolkitOperation.Validate


```go
func (icr *ImportConflictResolver) Validate(ctx context.Context) error
```

### ImportInfo

ImportInfo représente les informations d'un import


### ImportReport

ImportReport représente le rapport de résolution des conflits d'imports


### NamingConventions

NamingConventions defines the naming rules for the ecosystem


### NamingIssue

NamingIssue represents a naming convention problem


### NamingNormalizer

NamingNormalizer implements toolkit.ToolkitOperation for naming convention normalization


#### Methods

##### NamingNormalizer.CollectMetrics

CollectMetrics implements ToolkitOperation.CollectMetrics


```go
func (nn *NamingNormalizer) CollectMetrics() map[string]interface{}
```

##### NamingNormalizer.Execute

Execute implements ToolkitOperation.Execute


```go
func (nn *NamingNormalizer) Execute(ctx context.Context, options *toolkit.OperationOptions) error
```

##### NamingNormalizer.GetDescription

GetDescription implémente ToolkitOperation.GetDescription - description de l'outil


```go
func (nn *NamingNormalizer) GetDescription() string
```

##### NamingNormalizer.HealthCheck

HealthCheck implements ToolkitOperation.HealthCheck


```go
func (nn *NamingNormalizer) HealthCheck(ctx context.Context) error
```

##### NamingNormalizer.Stop

Stop implémente ToolkitOperation.Stop - gestion des signaux d'arrêt


```go
func (nn *NamingNormalizer) Stop(ctx context.Context) error
```

##### NamingNormalizer.String

String implémente ToolkitOperation.String - identification de l'outil


```go
func (nn *NamingNormalizer) String() string
```

##### NamingNormalizer.Validate

Validate implements ToolkitOperation.Validate


```go
func (nn *NamingNormalizer) Validate(ctx context.Context) error
```

