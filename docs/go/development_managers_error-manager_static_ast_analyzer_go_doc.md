# Package static

Analyseur Statique Go Intégré - Phase 9.1
Plan de développement v42 - Gestionnaire d'erreurs avancé

Règles de détection personnalisées - Phase 9.2
Plan de développement v42 - Gestionnaire d'erreurs avancé

Intégration Outils Externes - Phase 9.1.3
Plan de développement v42 - Gestionnaire d'erreurs avancé


## Types

### ASTAnalyzer

ASTAnalyzer représente l'analyseur statique principal


#### Methods

##### ASTAnalyzer.AnalyzeFile

AnalyzeFile analyse un fichier Go spécifique


```go
func (a *ASTAnalyzer) AnalyzeFile(filePath string) (*AnalysisResult, error)
```

##### ASTAnalyzer.AnalyzeProject

AnalyzeProject analyse tout un projet Go


```go
func (a *ASTAnalyzer) AnalyzeProject(projectPath string) ([]*AnalysisResult, error)
```

##### ASTAnalyzer.ClearCache

ClearCache vide le cache d'analyse


```go
func (a *ASTAnalyzer) ClearCache()
```

##### ASTAnalyzer.GetStatistics

GetStatistics retourne les statistiques actuelles


```go
func (a *ASTAnalyzer) GetStatistics() AnalyzerStats
```

### AnalysisResult

AnalysisResult représente le résultat d'une analyse statique


### AnalyzerConfig

AnalyzerConfig contient la configuration de l'analyseur


### AnalyzerStats

AnalyzerStats contient les statistiques d'analyse


### CategoryStat

CategoryStat représente une statistique par catégorie


### CodeMetrics

CodeMetrics contient les métriques de qualité du code


### ComplexityRule

ComplexityRule détecte les problèmes de complexité


#### Methods

##### ComplexityRule.Category

```go
func (r *ComplexityRule) Category() IssueCategory
```

##### ComplexityRule.Check

```go
func (r *ComplexityRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue
```

##### ComplexityRule.Description

```go
func (r *ComplexityRule) Description() string
```

##### ComplexityRule.Name

```go
func (r *ComplexityRule) Name() string
```

##### ComplexityRule.Severity

```go
func (r *ComplexityRule) Severity() IssueSeverity
```

### ConsolidatedIssue

ConsolidatedIssue représente une issue consolidée de plusieurs outils


### CustomLintRules

CustomLintRules contient toutes les règles de lint personnalisées


#### Methods

##### CustomLintRules.GetRules

GetRules retourne toutes les règles


```go
func (c *CustomLintRules) GetRules() []LintRule
```

### DRYViolationRule

DRYViolationRule détecte les violations du principe DRY (Don't Repeat Yourself)


#### Methods

##### DRYViolationRule.Category

```go
func (r *DRYViolationRule) Category() IssueCategory
```

##### DRYViolationRule.Check

```go
func (r *DRYViolationRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue
```

##### DRYViolationRule.Description

```go
func (r *DRYViolationRule) Description() string
```

##### DRYViolationRule.Name

```go
func (r *DRYViolationRule) Name() string
```

##### DRYViolationRule.Severity

```go
func (r *DRYViolationRule) Severity() IssueSeverity
```

### ErrorHandlingRule

ErrorHandlingRule vérifie la gestion des erreurs


#### Methods

##### ErrorHandlingRule.Category

```go
func (r *ErrorHandlingRule) Category() IssueCategory
```

##### ErrorHandlingRule.Check

```go
func (r *ErrorHandlingRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue
```

##### ErrorHandlingRule.Description

```go
func (r *ErrorHandlingRule) Description() string
```

##### ErrorHandlingRule.Name

```go
func (r *ErrorHandlingRule) Name() string
```

##### ErrorHandlingRule.Severity

```go
func (r *ErrorHandlingRule) Severity() IssueSeverity
```

### ExternalIssue

ExternalIssue représente une issue détectée par un outil externe


### ExternalTool

ExternalTool représente un outil d'analyse externe


### ExternalToolResult

ExternalToolResult représente le résultat d'un outil externe


### ExternalToolsManager

ExternalToolsManager gère l'intégration avec les outils externes


#### Methods

##### ExternalToolsManager.RunAllTools

RunAllTools exécute tous les outils activés


```go
func (etm *ExternalToolsManager) RunAllTools(ctx context.Context) (*UnifiedReport, error)
```

##### ExternalToolsManager.SaveReport

SaveReport sauvegarde le rapport dans un fichier


```go
func (etm *ExternalToolsManager) SaveReport(report *UnifiedReport, format string) error
```

### FixSuggestion

FixSuggestion contient une suggestion de correction


### FixType

### ImpactLevel

### IssueCategory

### IssueSeverity

### IssueType

Types énumérés


### KISSViolationRule

KISSViolationRule détecte les violations du principe KISS (Keep It Simple, Stupid)


#### Methods

##### KISSViolationRule.Category

```go
func (r *KISSViolationRule) Category() IssueCategory
```

##### KISSViolationRule.Check

```go
func (r *KISSViolationRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue
```

##### KISSViolationRule.Description

```go
func (r *KISSViolationRule) Description() string
```

##### KISSViolationRule.Name

```go
func (r *KISSViolationRule) Name() string
```

##### KISSViolationRule.Severity

```go
func (r *KISSViolationRule) Severity() IssueSeverity
```

### LintRule

LintRule représente une règle de lint personnalisée


### MaintainabilityRule

MaintainabilityRule vérifie la maintenabilité du code


#### Methods

##### MaintainabilityRule.Category

```go
func (r *MaintainabilityRule) Category() IssueCategory
```

##### MaintainabilityRule.Check

```go
func (r *MaintainabilityRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue
```

##### MaintainabilityRule.Description

```go
func (r *MaintainabilityRule) Description() string
```

##### MaintainabilityRule.Name

```go
func (r *MaintainabilityRule) Name() string
```

##### MaintainabilityRule.Severity

```go
func (r *MaintainabilityRule) Severity() IssueSeverity
```

### NamingConventionRule

NamingConventionRule vérifie les conventions de nommage


#### Methods

##### NamingConventionRule.Category

```go
func (r *NamingConventionRule) Category() IssueCategory
```

##### NamingConventionRule.Check

```go
func (r *NamingConventionRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue
```

##### NamingConventionRule.Description

```go
func (r *NamingConventionRule) Description() string
```

##### NamingConventionRule.Name

```go
func (r *NamingConventionRule) Name() string
```

##### NamingConventionRule.Severity

```go
func (r *NamingConventionRule) Severity() IssueSeverity
```

### PerformanceRule

PerformanceRule détecte les problèmes de performance potentiels


#### Methods

##### PerformanceRule.Category

```go
func (r *PerformanceRule) Category() IssueCategory
```

##### PerformanceRule.Check

```go
func (r *PerformanceRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue
```

##### PerformanceRule.Description

```go
func (r *PerformanceRule) Description() string
```

##### PerformanceRule.Name

```go
func (r *PerformanceRule) Name() string
```

##### PerformanceRule.Severity

```go
func (r *PerformanceRule) Severity() IssueSeverity
```

### QualityMetrics

QualityMetrics représente les métriques de qualité globales


### ReportSummary

ReportSummary résume les résultats du rapport


### SOLIDViolationRule

SOLIDViolationRule détecte les violations des principes SOLID


#### Methods

##### SOLIDViolationRule.Category

```go
func (r *SOLIDViolationRule) Category() IssueCategory
```

##### SOLIDViolationRule.Check

```go
func (r *SOLIDViolationRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue
```

##### SOLIDViolationRule.Description

```go
func (r *SOLIDViolationRule) Description() string
```

##### SOLIDViolationRule.Name

```go
func (r *SOLIDViolationRule) Name() string
```

##### SOLIDViolationRule.Severity

```go
func (r *SOLIDViolationRule) Severity() IssueSeverity
```

### SecurityRule

SecurityRule détecte les problèmes de sécurité potentiels


#### Methods

##### SecurityRule.Category

```go
func (r *SecurityRule) Category() IssueCategory
```

##### SecurityRule.Check

```go
func (r *SecurityRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue
```

##### SecurityRule.Description

```go
func (r *SecurityRule) Description() string
```

##### SecurityRule.Name

```go
func (r *SecurityRule) Name() string
```

##### SecurityRule.Severity

```go
func (r *SecurityRule) Severity() IssueSeverity
```

### StaticIssue

StaticIssue représente une erreur statique détectée


### TestabilityRule

TestabilityRule vérifie la testabilité du code


#### Methods

##### TestabilityRule.Category

```go
func (r *TestabilityRule) Category() IssueCategory
```

##### TestabilityRule.Check

```go
func (r *TestabilityRule) Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue
```

##### TestabilityRule.Description

```go
func (r *TestabilityRule) Description() string
```

##### TestabilityRule.Name

```go
func (r *TestabilityRule) Name() string
```

##### TestabilityRule.Severity

```go
func (r *TestabilityRule) Severity() IssueSeverity
```

### UnifiedReport

UnifiedReport représente un rapport consolidé de tous les outils


## Functions

### Max

Max simulation pour éviter l'import math


```go
func Max(a, b float64) float64
```

## Constants

### IssueTypeSyntax, IssueTypeType, IssueTypeImport, IssueTypeReference, IssueTypeStyle, IssueTypeComplexity, IssueTypeSecurity, IssueTypePerformance, SeverityError, SeverityWarning, SeverityInfo, SeverityHint, CategoryBugRisk, CategoryMaintenance, CategoryPerformance, CategorySecurity, CategoryStyle, FixTypeAutomatic, FixTypeManual, FixTypeSuggested, ImpactLow, ImpactMedium, ImpactHigh

```go
const (
	// Types d'issues
	IssueTypeSyntax		IssueType	= "syntax"
	IssueTypeType		IssueType	= "type"
	IssueTypeImport		IssueType	= "import"
	IssueTypeReference	IssueType	= "reference"
	IssueTypeStyle		IssueType	= "style"
	IssueTypeComplexity	IssueType	= "complexity"
	IssueTypeSecurity	IssueType	= "security"
	IssueTypePerformance	IssueType	= "performance"

	// Sévérités
	SeverityError	IssueSeverity	= "error"
	SeverityWarning	IssueSeverity	= "warning"
	SeverityInfo	IssueSeverity	= "info"
	SeverityHint	IssueSeverity	= "hint"

	// Catégories
	CategoryBugRisk		IssueCategory	= "bug_risk"
	CategoryMaintenance	IssueCategory	= "maintenance"
	CategoryPerformance	IssueCategory	= "performance"
	CategorySecurity	IssueCategory	= "security"
	CategoryStyle		IssueCategory	= "style"

	// Types de fix
	FixTypeAutomatic	FixType	= "automatic"
	FixTypeManual		FixType	= "manual"
	FixTypeSuggested	FixType	= "suggested"

	// Niveaux d'impact
	ImpactLow	ImpactLevel	= "low"
	ImpactMedium	ImpactLevel	= "medium"
	ImpactHigh	ImpactLevel	= "high"
)
```

