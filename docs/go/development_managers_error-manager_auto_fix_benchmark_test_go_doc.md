# Package auto_fix

Moteur de Suggestions de Correction - Phase 9.2.1
Plan de développement v42 - Gestionnaire d'erreurs avancé


## Types

### CLIAction

CLIAction represents an action taken through the CLI


### CLIConfig

CLIConfig contains configuration for the CLI


### CLIInterface

CLIInterface provides a command-line interface for reviewing and applying fixes


#### Methods

##### CLIInterface.LoadSession

LoadSession loads a review session from disk


```go
func (cli *CLIInterface) LoadSession(path string) (*ReviewSession, error)
```

##### CLIInterface.SaveSession

SaveSession saves a review session to disk


```go
func (cli *CLIInterface) SaveSession(session *ReviewSession, path string) error
```

##### CLIInterface.StartReviewSession

StartReviewSession starts an interactive review session


```go
func (cli *CLIInterface) StartReviewSession(ctx context.Context, projectPath string) (*ReviewSession, error)
```

### DiffInfo

DiffInfo contains information about a code diff


### EngineConfig

EngineConfig contient la configuration du moteur


### EngineStats

EngineStats contient les statistiques du moteur


### ErrorHandlingFixer

ErrorHandlingFixer améliore la gestion d'erreurs


#### Methods

##### ErrorHandlingFixer.CanFix

```go
func (f *ErrorHandlingFixer) CanFix(issue StaticIssue) bool
```

##### ErrorHandlingFixer.GenerateFix

```go
func (f *ErrorHandlingFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error)
```

##### ErrorHandlingFixer.GetCategory

```go
func (f *ErrorHandlingFixer) GetCategory() FixCategory
```

##### ErrorHandlingFixer.GetConfidence

```go
func (f *ErrorHandlingFixer) GetConfidence() float64
```

### FixCategory

FixCategory représente la catégorie de correction


### FixSuggestion

FixSuggestion représente une suggestion de correction


### FixTemplate

FixTemplate représente un template de correction


### FixType

FixType représente le type de correction


### FormatCodeFixer

FormatCodeFixer corrige les problèmes de formatage


#### Methods

##### FormatCodeFixer.CanFix

```go
func (f *FormatCodeFixer) CanFix(issue StaticIssue) bool
```

##### FormatCodeFixer.GenerateFix

```go
func (f *FormatCodeFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error)
```

##### FormatCodeFixer.GetCategory

```go
func (f *FormatCodeFixer) GetCategory() FixCategory
```

##### FormatCodeFixer.GetConfidence

```go
func (f *FormatCodeFixer) GetConfidence() float64
```

### ImpactLevel

ImpactLevel représente le niveau d'impact d'une correction


### NamingConventionFixer

NamingConventionFixer corrige les conventions de nommage


#### Methods

##### NamingConventionFixer.CanFix

```go
func (f *NamingConventionFixer) CanFix(issue StaticIssue) bool
```

##### NamingConventionFixer.GenerateFix

```go
func (f *NamingConventionFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error)
```

##### NamingConventionFixer.GetCategory

```go
func (f *NamingConventionFixer) GetCategory() FixCategory
```

##### NamingConventionFixer.GetConfidence

```go
func (f *NamingConventionFixer) GetConfidence() float64
```

### ReviewSession

ReviewSession represents a fix review session


### SafetyLevel

SafetyLevel représente le niveau de sécurité d'une correction


### SandboxConfig

SandboxConfig defines configuration for the validation sandbox


### SimplifyCodeFixer

SimplifyCodeFixer simplifie le code complexe


#### Methods

##### SimplifyCodeFixer.CanFix

```go
func (f *SimplifyCodeFixer) CanFix(issue StaticIssue) bool
```

##### SimplifyCodeFixer.GenerateFix

```go
func (f *SimplifyCodeFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error)
```

##### SimplifyCodeFixer.GetCategory

```go
func (f *SimplifyCodeFixer) GetCategory() FixCategory
```

##### SimplifyCodeFixer.GetConfidence

```go
func (f *SimplifyCodeFixer) GetConfidence() float64
```

### SpecificFixer

SpecificFixer interface pour les correcteurs spécifiques


### StaticIssue

StaticIssue interface pour les problèmes statiques (importé depuis le package static)


### SuggestionEngine

SuggestionEngine est le moteur principal de suggestions


#### Methods

##### SuggestionEngine.AnalyzeCode

AnalyzeCode analyses le code pour identifier les problèmes


```go
func (se *SuggestionEngine) AnalyzeCode(ctx context.Context, filePath string) ([]*FixSuggestion, error)
```

##### SuggestionEngine.GenerateSuggestions

GenerateSuggestions génère des suggestions de correction pour une liste d'issues


```go
func (se *SuggestionEngine) GenerateSuggestions(ctx context.Context, issues []StaticIssue) ([]*FixSuggestion, error)
```

### TemplateCondition

TemplateCondition représente une condition pour appliquer un template


### TestExecution

TestExecution tracks an ongoing test execution


### TestResult

TestResult represents the result of running a specific test


### UnusedImportFixer

UnusedImportFixer corrige les imports non utilisés


#### Methods

##### UnusedImportFixer.CanFix

```go
func (f *UnusedImportFixer) CanFix(issue StaticIssue) bool
```

##### UnusedImportFixer.GenerateFix

```go
func (f *UnusedImportFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error)
```

##### UnusedImportFixer.GetCategory

```go
func (f *UnusedImportFixer) GetCategory() FixCategory
```

##### UnusedImportFixer.GetConfidence

```go
func (f *UnusedImportFixer) GetConfidence() float64
```

### UnusedVariableFixer

UnusedVariableFixer corrige les variables non utilisées


#### Methods

##### UnusedVariableFixer.CanFix

```go
func (f *UnusedVariableFixer) CanFix(issue StaticIssue) bool
```

##### UnusedVariableFixer.GenerateFix

```go
func (f *UnusedVariableFixer) GenerateFix(issue StaticIssue, fset *token.FileSet, file *ast.File) (*FixSuggestion, error)
```

##### UnusedVariableFixer.GetCategory

```go
func (f *UnusedVariableFixer) GetCategory() FixCategory
```

##### UnusedVariableFixer.GetConfidence

```go
func (f *UnusedVariableFixer) GetConfidence() float64
```

### ValidationMetrics

ValidationMetrics contains metrics about the validation process


### ValidationResult

ValidationResult represents the result of validating a proposed fix


### ValidationSystem

ValidationSystem handles validation of proposed fixes


#### Methods

##### ValidationSystem.CancelTest

CancelTest cancels a running test


```go
func (vs *ValidationSystem) CancelTest(testID string) error
```

##### ValidationSystem.GetActiveTests

GetActiveTests returns currently running tests


```go
func (vs *ValidationSystem) GetActiveTests() map[string]*TestExecution
```

##### ValidationSystem.ValidateProposedFix

ValidateProposedFix validates a proposed fix using sandbox testing


```go
func (vs *ValidationSystem) ValidateProposedFix(fix *FixSuggestion, originalCode string) (*ValidationResult, error)
```

