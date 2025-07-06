# Package utils

## Types

### AuditReport

AuditReport représente le rapport d'audit global


### ModuleInfo

ModuleInfo représente les informations extraites d'un fichier go.mod


### NonCompliantImport

NonCompliantImport représente un import non conforme trouvé


### NonCompliantImportsReport

NonCompliantImportsReport représente le rapport des imports non conformes


## Functions

### GenerateMarkdownReportAudit

GenerateMarkdownReportAudit génère un rapport Markdown pour l'audit des modules


```go
func GenerateMarkdownReportAudit(report AuditReport) string
```

### GenerateMarkdownReportNonCompliantImports

GenerateMarkdownReportNonCompliantImports génère un rapport Markdown pour les imports non conformes


```go
func GenerateMarkdownReportNonCompliantImports(report NonCompliantImportsReport) string
```

### WriteReportJSON

WriteReportJSON écrit un rapport au format JSON


```go
func WriteReportJSON(report interface{}, outputPath string) error
```

### WriteReportMD

WriteReportMD écrit un rapport au format Markdown


```go
func WriteReportMD(reportMDContent string, outputPath string) error
```

