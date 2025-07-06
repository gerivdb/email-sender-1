# Package integratedmanager

filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\integrated-manager\conformity_api.go

filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\integrated-manager\error_integration.go

Stubs pour lever les erreurs de compilation liées à l'intégration d'erreurs


## Types

### APIDocReport

### ArchitectureReport

### BadgeType

### BenchmarkResult

### CodeMetrics

### CodeSmell

### ComplianceLevel

### ConformityAPIServer

ConformityAPIServer provides REST API endpoints for conformity management


#### Methods

##### ConformityAPIServer.Start

Start starts the conformity API server


```go
func (s *ConformityAPIServer) Start() error
```

##### ConformityAPIServer.StartBackground

StartBackground starts the API server in background


```go
func (s *ConformityAPIServer) StartBackground() error
```

##### ConformityAPIServer.Stop

Stop gracefully stops the API server


```go
func (s *ConformityAPIServer) Stop() error
```

### ConformityConfig

### ConformityIssue

### ConformityManager

#### Methods

##### ConformityManager.GenerateConformityReport

```go
func (cm *ConformityManager) GenerateConformityReport(ctx context.Context, managerName string, format ReportFormat) ([]byte, error)
```

##### ConformityManager.GetConformityConfig

```go
func (cm *ConformityManager) GetConformityConfig() *ConformityConfig
```

##### ConformityManager.GetConformityMetrics

```go
func (cm *ConformityManager) GetConformityMetrics(ctx context.Context) (*EcosystemMetrics, error)
```

##### ConformityManager.SetConformityConfig

```go
func (cm *ConformityManager) SetConformityConfig(config *ConformityConfig)
```

##### ConformityManager.UpdateConformityStatus

```go
func (cm *ConformityManager) UpdateConformityStatus(ctx context.Context, managerName string, status ComplianceLevel) error
```

##### ConformityManager.VerifyEcosystemConformity

```go
func (cm *ConformityManager) VerifyEcosystemConformity(ctx context.Context) (*EcosystemConformityReport, error)
```

##### ConformityManager.VerifyManagerConformity

```go
func (cm *ConformityManager) VerifyManagerConformity(ctx context.Context, managerName string) (*ConformityReport, error)
```

### ConformityReport

### ConformityScores

### ConformityStatus

ConformityStatus represents the conformity status of a manager


### ConformityThresholds

### ConformityTrends

ConformityTrends tracks conformity improvements over time


### DependencyMetrics

### DiagramsReport

### DocumentationIssue

### DocumentationReport

### EcosystemConformityReport

### EcosystemHealth

EcosystemHealth represents the health of the entire ecosystem


### EcosystemMetrics

### ErrorEntry

ErrorEntry : structure d'exemple pour la gestion d'erreurs


### ErrorHook

ErrorHook définit un hook d'erreur pour un manager spécifique


### ErrorManager

ErrorManager interface pour découpler la dépendance


### ErrorThreshold

ErrorThreshold définit les seuils d'erreurs pour un manager


### ExamplesReport

### ExportTarget

### HistoricalScore

HistoricalScore represents a score at a point in time


### IComplianceReporter

Génération de rapports


### IConformityChecker

Vérification de conformité


### IConformityManager

IConformityManager interface for conformity verification


### IDocumentationValidator

Validation documentaire


### IMetricsCollector

Collecte de métriques


### IntegratedErrorManager

IntegratedErrorManager : stub du gestionnaire d'erreurs intégré


#### Methods

##### IntegratedErrorManager.AddHook

AddHook ajoute un hook d'erreur pour un module spécifique


```go
func (iem *IntegratedErrorManager) AddHook(module string, hook ErrorHook)
```

##### IntegratedErrorManager.CentralizeError

CentralizeError collecte et centralise toutes les erreurs


```go
func (iem *IntegratedErrorManager) CentralizeError(module string, err error, context map[string]interface{}) error
```

##### IntegratedErrorManager.GenerateConformityReport

GenerateConformityReport generates a conformity report in the specified format


```go
func (iem *IntegratedErrorManager) GenerateConformityReport(ctx context.Context, managerName string, format ReportFormat) ([]byte, error)
```

##### IntegratedErrorManager.GetAllManagerStatuses

GetAllManagerStatuses returns all manager conformity statuses


```go
func (iem *IntegratedErrorManager) GetAllManagerStatuses() map[string]ConformityStatus
```

##### IntegratedErrorManager.GetConformityConfig

GetConformityConfig returns the current conformity configuration


```go
func (iem *IntegratedErrorManager) GetConformityConfig() *ConformityConfig
```

##### IntegratedErrorManager.GetManagerConformityStatus

GetManagerConformityStatus returns the conformity status for a manager


```go
func (iem *IntegratedErrorManager) GetManagerConformityStatus(managerName string) (*ConformityStatus, error)
```

##### IntegratedErrorManager.PropagateError

PropagateError propage une erreur vers le gestionnaire d'erreurs


```go
func (iem *IntegratedErrorManager) PropagateError(module string, err error, context map[string]interface{})
```

##### IntegratedErrorManager.SetConformityConfig

SetConformityConfig sets the conformity configuration


```go
func (iem *IntegratedErrorManager) SetConformityConfig(config *ConformityConfig)
```

##### IntegratedErrorManager.SetConformityManager

SetConformityManager sets the conformity manager instance


```go
func (iem *IntegratedErrorManager) SetConformityManager(cm IConformityManager)
```

##### IntegratedErrorManager.SetErrorManager

SetErrorManager configure le gestionnaire d'erreurs


```go
func (iem *IntegratedErrorManager) SetErrorManager(em ErrorManager)
```

##### IntegratedErrorManager.Shutdown

Shutdown gracefully shuts down the integrated manager including API server


```go
func (iem *IntegratedErrorManager) Shutdown() error
```

##### IntegratedErrorManager.UpdateConformityStatus

UpdateConformityStatus updates the conformity status of a manager


```go
func (iem *IntegratedErrorManager) UpdateConformityStatus(ctx context.Context, managerName string, level ComplianceLevel) error
```

##### IntegratedErrorManager.VerifyEcosystemConformity

VerifyEcosystemConformity verifies conformity for the entire ecosystem


```go
func (iem *IntegratedErrorManager) VerifyEcosystemConformity(ctx context.Context) (*EcosystemConformityReport, error)
```

##### IntegratedErrorManager.VerifyManagerConformity

VerifyManagerConformity verifies conformity for a specific manager


```go
func (iem *IntegratedErrorManager) VerifyManagerConformity(ctx context.Context, managerName string) (*ConformityReport, error)
```

### IntegrationReport

### PerformanceMetrics

### ReportFormat

### SOLIDMetrics

### TestCoverageMetrics

### TrendAnalysis

## Functions

### AddErrorHook

AddErrorHook : stub d'ajout de hook d'erreur


```go
func AddErrorHook(hook func(ErrorEntry))
```

### CentralizeError

CentralizeError fonction globale pour la compatibilité


```go
func CentralizeError(module string, err error) error
```

### CentralizeErrorWithContext

CentralizeErrorWithContext : stub de centralisation d'une erreur avec contexte


```go
func CentralizeErrorWithContext(ctx context.Context, entry ErrorEntry)
```

### ConfigureErrorThresholds

ConfigureErrorThresholds configure les seuils d'erreurs pour chaque manager


```go
func ConfigureErrorThresholds() map[string]ErrorThreshold
```

### GenerateConformityReportGlobal

GenerateConformityReportGlobal generates a conformity report globally


```go
func GenerateConformityReportGlobal(ctx context.Context, managerName string, format ReportFormat) ([]byte, error)
```

### InitializeManagerHooks

InitializeManagerHooks configure les hooks spécifiques pour chaque manager


```go
func InitializeManagerHooks()
```

### MonitorErrorThresholds

MonitorErrorThresholds surveille les seuils d'erreurs et déclenche des actions


```go
func MonitorErrorThresholds(thresholds map[string]ErrorThreshold)
```

### PropagateError

PropagateError : stub de propagation d'une erreur


```go
func PropagateError(err error)
```

### PropagateErrorWithContext

PropagateErrorWithContext : stub de propagation d'une erreur avec contexte


```go
func PropagateErrorWithContext(ctx context.Context, err error)
```

### RegisterManagerIntegrations

RegisterManagerIntegrations enregistre toutes les intégrations


```go
func RegisterManagerIntegrations()
```

### SetGlobalConformityManager

SetGlobalConformityManager sets the conformity manager globally


```go
func SetGlobalConformityManager(cm IConformityManager)
```

### UpdateConformityStatusGlobal

UpdateConformityStatusGlobal updates conformity status globally


```go
func UpdateConformityStatusGlobal(ctx context.Context, managerName string, level ComplianceLevel) error
```

