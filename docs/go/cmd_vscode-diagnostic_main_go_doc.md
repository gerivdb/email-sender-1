# Package main

## Types

### DiagnosticCLI

DiagnosticCLI structure principale du CLI


#### Methods

##### DiagnosticCLI.RunDiagnosticOnly

RunDiagnosticOnly diagnostic rapide - Target: 50ms


```go
func (cli *DiagnosticCLI) RunDiagnosticOnly() (*DiagnosticReport, error)
```

##### DiagnosticCLI.RunEmergencyStop

RunEmergencyStop arrêt d'urgence - Target: 50ms


```go
func (cli *DiagnosticCLI) RunEmergencyStop() (map[string]interface{}, error)
```

##### DiagnosticCLI.RunErrorResolution

RunErrorResolution remplace le script PowerShell error-resolution-automation.ps1


```go
func (cli *DiagnosticCLI) RunErrorResolution(action string, dryRun bool) (interface{}, error)
```

##### DiagnosticCLI.RunFullDiagnostic

RunFullDiagnostic exécute un diagnostic complet - Target: 200ms


```go
func (cli *DiagnosticCLI) RunFullDiagnostic() (*DiagnosticReport, error)
```

##### DiagnosticCLI.RunHealthCheck

RunHealthCheck vérification santé rapide - Target: 10ms


```go
func (cli *DiagnosticCLI) RunHealthCheck() (map[string]interface{}, error)
```

##### DiagnosticCLI.RunRepairOnly

RunRepairOnly tentative de réparation - Target: 100ms


```go
func (cli *DiagnosticCLI) RunRepairOnly() (map[string]interface{}, error)
```

##### DiagnosticCLI.ShowUsage

ShowUsage affiche l'aide d'utilisation


```go
func (cli *DiagnosticCLI) ShowUsage()
```

##### DiagnosticCLI.StartRealtimeMonitor

StartRealtimeMonitor surveillance temps réel - Target: 5ms per cycle


```go
func (cli *DiagnosticCLI) StartRealtimeMonitor() (map[string]interface{}, error)
```

### DiagnosticReport

DiagnosticReport contient tous les résultats


### DiagnosticResult

DiagnosticResult représente le résultat d'un diagnostic


### Logger

Logger structure de logging simple


#### Methods

##### Logger.Error

Error enregistre une erreur


```go
func (l *Logger) Error(message string, err error)
```

##### Logger.Log

Log enregistre un message


```go
func (l *Logger) Log(message string)
```

### MetricsCollector

MetricsCollector collecteur de métriques simple


#### Methods

##### MetricsCollector.GetMetrics

GetMetrics retourne les métriques actuelles


```go
func (m *MetricsCollector) GetMetrics() map[string]interface{}
```

##### MetricsCollector.RecordRequest

RecordRequest enregistre une requête


```go
func (m *MetricsCollector) RecordRequest()
```

### SystemInfo

SystemInfo structure pour les informations système


