# Package main

## Types

### Algorithm

Algorithm interface that all algorithms must implement


### AlgorithmConfig

AlgorithmConfig represents configuration for a single algorithm


### AlgorithmInfo

AlgorithmInfo contains information about each algorithm


### AlgorithmResult

AlgorithmResult represents the result of algorithm execution


### AnalysisPipelineAlgorithm

AnalysisPipelineAlgorithm implements Algorithm 6 - Analysis Pipeline


#### Methods

##### AnalysisPipelineAlgorithm.Execute

```go
func (apa *AnalysisPipelineAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error)
```

##### AnalysisPipelineAlgorithm.ID

```go
func (apa *AnalysisPipelineAlgorithm) ID() string
```

##### AnalysisPipelineAlgorithm.Name

```go
func (apa *AnalysisPipelineAlgorithm) Name() string
```

##### AnalysisPipelineAlgorithm.Validate

```go
func (apa *AnalysisPipelineAlgorithm) Validate(config AlgorithmConfig) error
```

### AutoFixAlgorithm

AutoFixAlgorithm implements Algorithm 5 - Auto-Fix Pattern Matching


#### Methods

##### AutoFixAlgorithm.Execute

```go
func (afa *AutoFixAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error)
```

##### AutoFixAlgorithm.ID

```go
func (afa *AutoFixAlgorithm) ID() string
```

##### AutoFixAlgorithm.Name

```go
func (afa *AutoFixAlgorithm) Name() string
```

##### AutoFixAlgorithm.Validate

```go
func (afa *AutoFixAlgorithm) Validate(config AlgorithmConfig) error
```

### BinarySearchAlgorithm

BinarySearchAlgorithm implements Algorithm 2 - Binary Search Debug


#### Methods

##### BinarySearchAlgorithm.Execute

```go
func (bsa *BinarySearchAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error)
```

##### BinarySearchAlgorithm.ID

```go
func (bsa *BinarySearchAlgorithm) ID() string
```

##### BinarySearchAlgorithm.Name

```go
func (bsa *BinarySearchAlgorithm) Name() string
```

##### BinarySearchAlgorithm.Validate

```go
func (bsa *BinarySearchAlgorithm) Validate(config AlgorithmConfig) error
```

### ConfigValidatorAlgorithm

ConfigValidatorAlgorithm implements Algorithm 7 - Config Validator


#### Methods

##### ConfigValidatorAlgorithm.Execute

```go
func (cva *ConfigValidatorAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error)
```

##### ConfigValidatorAlgorithm.ID

```go
func (cva *ConfigValidatorAlgorithm) ID() string
```

##### ConfigValidatorAlgorithm.Name

```go
func (cva *ConfigValidatorAlgorithm) Name() string
```

##### ConfigValidatorAlgorithm.Validate

```go
func (cva *ConfigValidatorAlgorithm) Validate(config AlgorithmConfig) error
```

### DependencyAnalysisAlgorithm

DependencyAnalysisAlgorithm implements Algorithm 3 - Dependency Analysis


#### Methods

##### DependencyAnalysisAlgorithm.Execute

```go
func (daa *DependencyAnalysisAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error)
```

##### DependencyAnalysisAlgorithm.ID

```go
func (daa *DependencyAnalysisAlgorithm) ID() string
```

##### DependencyAnalysisAlgorithm.Name

```go
func (daa *DependencyAnalysisAlgorithm) Name() string
```

##### DependencyAnalysisAlgorithm.Validate

```go
func (daa *DependencyAnalysisAlgorithm) Validate(config AlgorithmConfig) error
```

### DependencyResolutionAlgorithm

DependencyResolutionAlgorithm implements Algorithm 8 - Dependency Resolution


#### Methods

##### DependencyResolutionAlgorithm.Execute

```go
func (dra *DependencyResolutionAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error)
```

##### DependencyResolutionAlgorithm.ID

```go
func (dra *DependencyResolutionAlgorithm) ID() string
```

##### DependencyResolutionAlgorithm.Name

```go
func (dra *DependencyResolutionAlgorithm) Name() string
```

##### DependencyResolutionAlgorithm.Validate

```go
func (dra *DependencyResolutionAlgorithm) Validate(config AlgorithmConfig) error
```

### EmailSenderOrchestrator

EmailSenderOrchestrator manages the execution of all EMAIL_SENDER_1 algorithms


#### Methods

##### EmailSenderOrchestrator.Cleanup

Cleanup performs cleanup operations


```go
func (eso *EmailSenderOrchestrator) Cleanup()
```

##### EmailSenderOrchestrator.Execute

Execute runs the complete EMAIL_SENDER_1 algorithm orchestration


```go
func (eso *EmailSenderOrchestrator) Execute() (*OrchestratorResult, error)
```

##### EmailSenderOrchestrator.RegisterAlgorithms

RegisterAlgorithms registers all EMAIL_SENDER_1 algorithms


```go
func (eso *EmailSenderOrchestrator) RegisterAlgorithms() map[string]Algorithm
```

### EmailSenderOrchestratorModule

EmailSenderOrchestratorModule - Version modulaire de l'orchestrateur


#### Methods

##### EmailSenderOrchestratorModule.Cleanup

Cleanup performs cleanup operations


```go
func (eso *EmailSenderOrchestratorModule) Cleanup()
```

##### EmailSenderOrchestratorModule.ExecuteDebugSession

ExecuteDebugSession exécute une session complète de débogage d'erreurs


```go
func (eso *EmailSenderOrchestratorModule) ExecuteDebugSession() (*OrchestratorResult, error)
```

### ErrorTriageAlgorithm

ErrorTriageAlgorithm implements Algorithm 1 - Error Triage


#### Methods

##### ErrorTriageAlgorithm.Execute

```go
func (eta *ErrorTriageAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error)
```

##### ErrorTriageAlgorithm.ID

```go
func (eta *ErrorTriageAlgorithm) ID() string
```

##### ErrorTriageAlgorithm.Name

```go
func (eta *ErrorTriageAlgorithm) Name() string
```

##### ErrorTriageAlgorithm.Validate

```go
func (eta *ErrorTriageAlgorithm) Validate(config AlgorithmConfig) error
```

### OrchestratorConfig

OrchestratorConfig represents the unified orchestrator configuration


### OrchestratorResult

OrchestratorResult represents the overall orchestration result


### ParallelAlgorithm

ParallelAlgorithm implémente l'interface Algorithm pour l'intégration du système parallélisé


#### Methods

##### ParallelAlgorithm.Execute

Execute exécute l'algorithme parallèle


```go
func (pa *ParallelAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error)
```

##### ParallelAlgorithm.ID

ID retourne l'identifiant de l'algorithme


```go
func (pa *ParallelAlgorithm) ID() string
```

##### ParallelAlgorithm.Name

Name retourne le nom de l'algorithme


```go
func (pa *ParallelAlgorithm) Name() string
```

##### ParallelAlgorithm.Validate

Validate valide la configuration de l'algorithme


```go
func (pa *ParallelAlgorithm) Validate(config AlgorithmConfig) error
```

### ProgressiveBuildAlgorithm

ProgressiveBuildAlgorithm implements Algorithm 4 - Progressive Build


#### Methods

##### ProgressiveBuildAlgorithm.Execute

```go
func (pba *ProgressiveBuildAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error)
```

##### ProgressiveBuildAlgorithm.ID

```go
func (pba *ProgressiveBuildAlgorithm) ID() string
```

##### ProgressiveBuildAlgorithm.Name

```go
func (pba *ProgressiveBuildAlgorithm) Name() string
```

##### ProgressiveBuildAlgorithm.Validate

```go
func (pba *ProgressiveBuildAlgorithm) Validate(config AlgorithmConfig) error
```

### ValidationReport

### ValidationSuite

ValidationSuite represents the complete validation suite


#### Methods

##### ValidationSuite.DisplayResults

DisplayResults displays validation results in the terminal


```go
func (vs *ValidationSuite) DisplayResults()
```

##### ValidationSuite.GenerateReport

GenerateReport generates a comprehensive validation report


```go
func (vs *ValidationSuite) GenerateReport(outputFile string) error
```

##### ValidationSuite.RunAllValidations

RunAllValidations executes all validation tests


```go
func (vs *ValidationSuite) RunAllValidations()
```

### ValidationSummary

ValidationSummary provides overall validation statistics


### ValidationTest

ValidationTest represents a single validation test


