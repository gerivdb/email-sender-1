# Package gapanalyzer

## Types

### ExpectedModule

ExpectedModule représente un module attendu


### GapAnalysis

GapAnalysis représente le résultat de l'analyse d'écart


### ModuleInfo

ModuleInfo représente les informations d'un module (importé du scanner)


### RepositoryStructure

RepositoryStructure représente la structure complète du dépôt (importé du scanner)


## Functions

### GenerateMarkdownReport

GenerateMarkdownReport génère un rapport Markdown


```go
func GenerateMarkdownReport(analysis GapAnalysis) string
```

### IsLegitimateExtraModule

IsLegitimateExtraModule vérifie si un module "extra" est légitime


```go
func IsLegitimateExtraModule(moduleName string) bool
```

# Package main

