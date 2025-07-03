# Package reporting

## Types

### Issue

Issue représente un ticket ou une demande


### Requirement

Requirement représente un besoin identifié


### RequirementsAnalysis

RequirementsAnalysis représente l'analyse des besoins


### Specification

Specification représente une spécification technique


### SpecificationAnalysis

SpecificationAnalysis représente l'analyse des spécifications


### TestCase

TestCase représente un cas de test


## Functions

### GenerateMarkdownReport

GenerateMarkdownReport génère un rapport Markdown des besoins


```go
func GenerateMarkdownReport(analysis RequirementsAnalysis) string
```

### GenerateSpecMarkdownReport

GenerateSpecMarkdownReport génère un rapport Markdown des spécifications


```go
func GenerateSpecMarkdownReport(analysis SpecificationAnalysis) string
```

