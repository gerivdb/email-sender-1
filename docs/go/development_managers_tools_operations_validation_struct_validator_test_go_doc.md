# Package validation

## Types

### SemanticAnalysisResult

SemanticAnalysisResult contient les résultats de l'analyse sémantique


### StructValidator

StructValidator implémente l'interface toolkit.ToolkitOperation pour la validation des structures


#### Methods

##### StructValidator.CollectMetrics

CollectMetrics implémente ToolkitOperation.CollectMetrics


```go
func (sv *StructValidator) CollectMetrics() map[string]interface{}
```

##### StructValidator.Execute

Execute implémente ToolkitOperation.Execute


```go
func (sv *StructValidator) Execute(ctx context.Context, options *toolkit.OperationOptions) error
```

##### StructValidator.GetDescription

GetDescription returns the tool description


```go
func (sv *StructValidator) GetDescription() string
```

##### StructValidator.HealthCheck

HealthCheck implémente ToolkitOperation.HealthCheck


```go
func (sv *StructValidator) HealthCheck(ctx context.Context) error
```

##### StructValidator.Stop

Stop handles graceful shutdown


```go
func (sv *StructValidator) Stop(ctx context.Context) error
```

##### StructValidator.String

String returns the tool identifier


```go
func (sv *StructValidator) String() string
```

##### StructValidator.Validate

Validate implémente ToolkitOperation.Validate


```go
func (sv *StructValidator) Validate(ctx context.Context) error
```

### ValidationError

ValidationError représente une erreur de validation


### ValidationReport

ValidationReport représente le rapport de validation


