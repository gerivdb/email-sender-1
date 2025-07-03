# Package analysis

## Types

### AnalysisReport

AnalysisReport contains comprehensive analysis results


### ComplexityMetrics

ComplexityMetrics provides code complexity analysis


### DependencyAnalyzer

DependencyAnalyzer implémente l'interface toolkit.ToolkitOperation pour l'analyse des dépendances


#### Methods

##### DependencyAnalyzer.CollectMetrics

CollectMetrics implémente ToolkitOperation.CollectMetrics


```go
func (da *DependencyAnalyzer) CollectMetrics() map[string]interface{}
```

##### DependencyAnalyzer.Execute

Execute implémente ToolkitOperation.Execute


```go
func (da *DependencyAnalyzer) Execute(ctx context.Context, options *toolkit.OperationOptions) error
```

##### DependencyAnalyzer.GetDescription

GetDescription implémente ToolkitOperation.GetDescription - description de l'outil


```go
func (da *DependencyAnalyzer) GetDescription() string
```

##### DependencyAnalyzer.HealthCheck

HealthCheck implémente ToolkitOperation.HealthCheck


```go
func (da *DependencyAnalyzer) HealthCheck(ctx context.Context) error
```

##### DependencyAnalyzer.Stop

Stop implémente ToolkitOperation.Stop - gestion des signaux d'arrêt


```go
func (da *DependencyAnalyzer) Stop(ctx context.Context) error
```

##### DependencyAnalyzer.String

String implémente ToolkitOperation.String - identification de l'outil


```go
func (da *DependencyAnalyzer) String() string
```

##### DependencyAnalyzer.Validate

Validate implémente ToolkitOperation.Validate


```go
func (da *DependencyAnalyzer) Validate(ctx context.Context) error
```

### DependencyInfo

DependencyInfo représente les informations d'une dépendance


### DependencyReport

DependencyReport représente le rapport d'analyse des dépendances


### DuplicateType

DuplicateType représente un type dupliqué


### DuplicateTypeDetector

DuplicateTypeDetector implémente l'interface toolkit.ToolkitOperation pour la détection des types dupliqués


#### Methods

##### DuplicateTypeDetector.CollectMetrics

CollectMetrics implémente ToolkitOperation.CollectMetrics


```go
func (dtd *DuplicateTypeDetector) CollectMetrics() map[string]interface{}
```

##### DuplicateTypeDetector.Execute

Execute implémente ToolkitOperation.Execute


```go
func (dtd *DuplicateTypeDetector) Execute(ctx context.Context, options *toolkit.OperationOptions) error
```

##### DuplicateTypeDetector.GetDescription

GetDescription implémente ToolkitOperation.GetDescription - description de l'outil


```go
func (dtd *DuplicateTypeDetector) GetDescription() string
```

##### DuplicateTypeDetector.HealthCheck

HealthCheck implémente ToolkitOperation.HealthCheck


```go
func (dtd *DuplicateTypeDetector) HealthCheck(ctx context.Context) error
```

##### DuplicateTypeDetector.Stop

Stop implémente ToolkitOperation.Stop - gestion des signaux d'arrêt


```go
func (dtd *DuplicateTypeDetector) Stop(ctx context.Context) error
```

##### DuplicateTypeDetector.String

String implémente ToolkitOperation.String - identification de l'outil


```go
func (dtd *DuplicateTypeDetector) String() string
```

##### DuplicateTypeDetector.Validate

Validate implémente ToolkitOperation.Validate


```go
func (dtd *DuplicateTypeDetector) Validate(ctx context.Context) error
```

### DuplicationReport

DuplicationReport représente le rapport de détection des doublons


### Interface

Interface represents a Go interface with metadata


### InterfaceAnalyzer

InterfaceAnalyzer provides comprehensive interface analysis capabilities


#### Methods

##### InterfaceAnalyzer.AnalyzeInterfaces

AnalyzeInterfaces performs comprehensive interface analysis


```go
func (ia *InterfaceAnalyzer) AnalyzeInterfaces() (*AnalysisReport, error)
```

##### InterfaceAnalyzer.GenerateAnalysisReport

GenerateAnalysisReport generates a formatted analysis report


```go
func (ia *InterfaceAnalyzer) GenerateAnalysisReport(format string) ([]byte, error)
```

### InterfaceInfo

InterfaceInfo is an alias for Interface for compatibility with tests


### InterfaceSyntaxError

InterfaceSyntaxError represents a syntax error with context for interface analysis


### Method

Method represents a method within an interface


### MethodInfo

MethodInfo is an alias for Method for compatibility with tests


### Parameter

Parameter represents a method parameter


### QualityScore

QualityScore represents the overall quality score with details


### Recommendation

Recommendation provides actionable improvement suggestions


### ReturnValue

ReturnValue represents a method return value


### SecuritySummary

SecuritySummary résume les vulnérabilités par sévérité


### SyntaxChecker

SyntaxChecker implémente l'interface toolkit.ToolkitOperation pour la correction de syntaxe


#### Methods

##### SyntaxChecker.CollectMetrics

CollectMetrics implémente ToolkitOperation.CollectMetrics


```go
func (sc *SyntaxChecker) CollectMetrics() map[string]interface{}
```

##### SyntaxChecker.Execute

Execute implémente ToolkitOperation.Execute


```go
func (sc *SyntaxChecker) Execute(ctx context.Context, options *toolkit.OperationOptions) error
```

##### SyntaxChecker.GetDescription

GetDescription returns the tool description


```go
func (sc *SyntaxChecker) GetDescription() string
```

##### SyntaxChecker.HealthCheck

HealthCheck implémente ToolkitOperation.HealthCheck


```go
func (sc *SyntaxChecker) HealthCheck(ctx context.Context) error
```

##### SyntaxChecker.Stop

Stop handles graceful shutdown


```go
func (sc *SyntaxChecker) Stop(ctx context.Context) error
```

##### SyntaxChecker.String

String returns the tool identifier


```go
func (sc *SyntaxChecker) String() string
```

##### SyntaxChecker.Validate

Validate implémente ToolkitOperation.Validate


```go
func (sc *SyntaxChecker) Validate(ctx context.Context) error
```

### SyntaxError

SyntaxError représente une erreur de syntaxe détectée


### SyntaxReport

SyntaxReport représente le rapport de vérification syntaxique


### SyntaxSummary

SyntaxSummary fournit un résumé des erreurs par type


### TypeDefinition

TypeDefinition représente une définition de type


### Vulnerability

Vulnerability représente une vulnérabilité de sécurité


## Constants

### ToolVersion

ToolVersion defines the current version of this specific tool or the toolkit.


```go
const ToolVersion = "3.0.0"
```

