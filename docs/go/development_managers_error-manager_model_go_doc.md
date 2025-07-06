# Package errormanager

## Types

### ErrorCorrelation

ErrorCorrelation représente la corrélation entre différentes erreurs


### ErrorEntry

ErrorEntry represents a structured error for cataloging


### ErrorPattern

ErrorPattern représente un pattern d'erreur détecté


### PatternAnalysisReport

PatternAnalysisReport représente un rapport d'analyse de pattern complet


### PatternAnalyzer

PatternAnalyzer gère l'analyse des patterns d'erreurs


#### Methods

##### PatternAnalyzer.AnalyzeErrorPatterns

AnalyzeErrorPatterns détecte les erreurs récurrentes selon la micro-étape 4.1.1


```go
func (pa *PatternAnalyzer) AnalyzeErrorPatterns() ([]PatternMetrics, error)
```

##### PatternAnalyzer.CreateFrequencyMetrics

CreateFrequencyMetrics crée des métriques de fréquence par module et code d'erreur selon la micro-étape 4.1.2


```go
func (pa *PatternAnalyzer) CreateFrequencyMetrics() (map[string]map[string]int, error)
```

##### PatternAnalyzer.IdentifyTemporalCorrelations

IdentifyTemporalCorrelations identifie les corrélations temporelles entre erreurs selon la micro-étape 4.1.3


```go
func (pa *PatternAnalyzer) IdentifyTemporalCorrelations(timeWindow time.Duration) ([]TemporalCorrelation, error)
```

### PatternMetrics

PatternMetrics représente les métriques d'un pattern d'erreur


### PatternReport

PatternReport représente un rapport d'analyse des patterns


### ReportGenerator

ReportGenerator gère la génération des rapports d'analyse


#### Methods

##### ReportGenerator.ExportToHTML

ExportToHTML exporte le rapport en HTML selon la micro-étape 4.2.2


```go
func (rg *ReportGenerator) ExportToHTML(report *PatternReport, filename string) error
```

##### ReportGenerator.ExportToJSON

ExportToJSON exporte le rapport en JSON selon la micro-étape 4.2.2


```go
func (rg *ReportGenerator) ExportToJSON(report *PatternReport, filename string) error
```

##### ReportGenerator.GeneratePatternReport

GeneratePatternReport génère un rapport complet d'analyse des patterns selon la micro-étape 4.2.1


```go
func (rg *ReportGenerator) GeneratePatternReport() (*PatternReport, error)
```

### TemporalCorrelation

TemporalCorrelation représente les corrélations temporelles entre erreurs


## Functions

### CatalogError

CatalogError prepares and logs an error entry


```go
func CatalogError(entry ErrorEntry)
```

### InitializeLogger

InitializeLogger initializes the Zap logger in production mode


```go
func InitializeLogger() error
```

### LogError

LogError logs an error with additional metadata


```go
func LogError(err error, module string, code string)
```

### TestAnalyzeErrorPatterns

TestAnalyzeErrorPatterns teste l'analyseur avec des données simulées


```go
func TestAnalyzeErrorPatterns()
```

### TestAnalyzeErrorPatternsWithMockData

TestAnalyzeErrorPatternsWithMockData teste avec des données simulées


```go
func TestAnalyzeErrorPatternsWithMockData()
```

### TestReportGeneration

TestReportGeneration teste la génération de rapports


```go
func TestReportGeneration()
```

### TestReportGenerationWithMockData

TestReportGenerationWithMockData teste avec des données simulées


```go
func TestReportGenerationWithMockData()
```

### TestWrapError

TestWrapError simulates an error and tests the WrapError function


```go
func TestWrapError()
```

### ValidateErrorEntry

ValidateErrorEntry validates the fields of an ErrorEntry


```go
func ValidateErrorEntry(entry ErrorEntry) error
```

### ValidateErrorEntryExample

Example JSON validation for ErrorEntry


```go
func ValidateErrorEntryExample()
```

### WrapError

WrapError enriches an error with additional context


```go
func WrapError(err error, message string) error
```

