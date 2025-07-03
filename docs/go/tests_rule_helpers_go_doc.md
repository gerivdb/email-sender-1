# Package tests

Package tests contains test stubs


## Types

### Alert

Alert représente une alerte


### AlertConfig

AlertConfig represents alert configuration


### AlertManager

AlertManager gère les alertes


#### Methods

##### AlertManager.GetRecentAlerts

GetRecentAlerts récupère les alertes récentes


```go
func (am *AlertManager) GetRecentAlerts(count int) []Alert
```

##### AlertManager.ResolveAlert

ResolveAlert résout une alerte par son ID


```go
func (am *AlertManager) ResolveAlert(alertID string) error
```

##### AlertManager.SendAlert

SendAlert envoie une alerte


```go
func (am *AlertManager) SendAlert(alert Alert) error
```

### AutoResolver

AutoResolver automatically resolves conflicts


#### Methods

##### AutoResolver.AutoFixIssuesWithCount

AutoFixIssuesWithCount fixes issues and returns a count of fixed issues


```go
func (ar *AutoResolver) AutoFixIssuesWithCount(plan string, issues []string) (*FixResult, error)
```

##### AutoResolver.ResolveConflicts

```go
func (ar *AutoResolver) ResolveConflicts(conflicts []string) error
```

### Backup

Backup représente une sauvegarde


### BaseConsistencyRule

BaseConsistencyRule provides common functionality for consistency rules


#### Methods

##### BaseConsistencyRule.GetName

AddMethod adds GetName method to ConsistencyRule


```go
func (cr *BaseConsistencyRule) GetName() string
```

##### BaseConsistencyRule.Name

Name returns the rule name


```go
func (r *BaseConsistencyRule) Name() string
```

### CoherenceTestScenario

CoherenceTestScenario defines scenarios for coherence testing


### Conflict

Conflict représente un conflit entre deux versions


### ConflictAnalyzer

ConflictAnalyzer analyzes conflicts between plans


#### Methods

##### ConflictAnalyzer.AnalyzeConflicts

```go
func (ca *ConflictAnalyzer) AnalyzeConflicts(planA, planB string) ([]string, error)
```

### ConflictConfig

ConflictConfig contains configuration for the conflict analyzer


### ConflictDetectionConfig

ConflictDetectionConfig represents conflict detection configuration


### ConflictResolution

ConflictResolution représente la résolution d'un conflit


### ConflictResolver

ConflictResolver resolves conflicts between changes


#### Methods

##### ConflictResolver.DetectConflict

DetectConflict detects conflicts between changes


```go
func (cr *ConflictResolver) DetectConflict(markdownChange, dynamicChange interface{}) *Conflict
```

##### ConflictResolver.ResolveConflict

ResolveConflict resolves a conflict


```go
func (cr *ConflictResolver) ResolveConflict(conflict *Conflict) (*ConflictResolution, error)
```

### ConflictScenario

ConflictScenario represents a conflict test scenario


### ConflictType

ConflictType represents the type of conflict


#### Methods

##### ConflictType.GetType

GetType is a compatibility method for ConflictType


```go
func (ct ConflictType) GetType() string
```

### ConsistencyRule

ConsistencyRule defines the interface for consistency rules


### ConsistencyValidator

ConsistencyValidator validates plan consistency


#### Methods

##### ConsistencyValidator.Validate

Stub methods for basic functionality


```go
func (cv *ConsistencyValidator) Validate(planPath string) (*ValidationResult, error)
```

##### ConsistencyValidator.ValidatePlan

Mock for the validator function


```go
func (cv *ConsistencyValidator) ValidatePlan(planPath string) (*ValidationResult, error)
```

### DashboardData

DashboardData représente les données du tableau de bord


### DriftDetector

DriftDetector détecte les dérives


#### Methods

##### DriftDetector.Start

Start démarre le détecteur


```go
func (dd *DriftDetector) Start()
```

##### DriftDetector.StartMonitoring

StartMonitoring démarre la surveillance de dérive


```go
func (dd *DriftDetector) StartMonitoring(ctx context.Context) error
```

##### DriftDetector.Stop

Stop arrête le détecteur


```go
func (dd *DriftDetector) Stop()
```

##### DriftDetector.StopMonitoring

StopMonitoring arrête la surveillance de dérive


```go
func (dd *DriftDetector) StopMonitoring()
```

### ExpectedResults

ExpectedResults defines performance expectations


### FixResult

FixResult contains the result of auto-fixing issues


#### Methods

##### FixResult.String

String returns the string representation of a FixResult


```go
func (fr *FixResult) String() string
```

### FixResultAdapter

FixResultAdapter adapts string to FixResult


### IntegrationTestSuite

IntegrationTestSuite contains all integration tests for the planning ecosystem sync


#### Methods

##### IntegrationTestSuite.SetupSuite

SetupSuite initializes the test suite


```go
func (suite *IntegrationTestSuite) SetupSuite()
```

##### IntegrationTestSuite.SetupTest

SetupTest prepares each individual test


```go
func (suite *IntegrationTestSuite) SetupTest()
```

##### IntegrationTestSuite.TearDownSuite

TearDownSuite cleans up after all tests


```go
func (suite *IntegrationTestSuite) TearDownSuite()
```

##### IntegrationTestSuite.Test_AlertSystem

Test_AlertSystem tests the alert detection and notification system


```go
func (suite *IntegrationTestSuite) Test_AlertSystem()
```

##### IntegrationTestSuite.Test_ConflictHandling

Test_ConflictHandling tests conflict detection and resolution


```go
func (suite *IntegrationTestSuite) Test_ConflictHandling()
```

##### IntegrationTestSuite.Test_DriftDetection

Test_DriftDetection tests drift detection functionality


```go
func (suite *IntegrationTestSuite) Test_DriftDetection()
```

##### IntegrationTestSuite.Test_DynamicToMarkdownSync

Test_DynamicToMarkdownSync tests synchronization from dynamic systems to Markdown


```go
func (suite *IntegrationTestSuite) Test_DynamicToMarkdownSync()
```

##### IntegrationTestSuite.Test_MarkdownToDynamicSync

Test_MarkdownToDynamicSync tests synchronization from Markdown to dynamic systems


```go
func (suite *IntegrationTestSuite) Test_MarkdownToDynamicSync()
```

##### IntegrationTestSuite.Test_MigrationRollback

Test_MigrationRollback tests migration rollback functionality


```go
func (suite *IntegrationTestSuite) Test_MigrationRollback()
```

##### IntegrationTestSuite.Test_PerformanceMetrics

Test_PerformanceMetrics tests performance monitoring and metrics collection


```go
func (suite *IntegrationTestSuite) Test_PerformanceMetrics()
```

##### IntegrationTestSuite.Test_RealtimeDashboard

Test_RealtimeDashboard tests the real-time dashboard functionality


```go
func (suite *IntegrationTestSuite) Test_RealtimeDashboard()
```

##### IntegrationTestSuite.Test_ReportGeneration

Test_ReportGeneration tests automated report generation


```go
func (suite *IntegrationTestSuite) Test_ReportGeneration()
```

### LoadTestConfig

LoadTestConfig defines load test parameters


### Logger

Logger wrapper for test logging


#### Methods

##### Logger.Info

Info adds Info logging method to Logger


```go
func (l *Logger) Info(format string, args ...interface{})
```

### ManualResolutionStrategy

ManualResolutionStrategy represents a manual resolution strategy


#### Methods

##### ManualResolutionStrategy.Name

Name returns the strategy name


```go
func (s *ManualResolutionStrategy) Name() string
```

##### ManualResolutionStrategy.Resolve

Resolve resolves a conflict manually


```go
func (s *ManualResolutionStrategy) Resolve(conflict *Conflict) (*ConflictResolution, error)
```

##### ManualResolutionStrategy.ResolveVal

ResolveVal resolves a conflict manually (accepting a value)


```go
func (s *ManualResolutionStrategy) ResolveVal(conflict Conflict) (*ConflictResolution, error)
```

### MetadataChange

MetadataChange represents a metadata change


### MetadataConsistencyRule

MetadataConsistencyRule checks metadata consistency


#### Methods

##### MetadataConsistencyRule.Validate

Validate validates the metadata


```go
func (r *MetadataConsistencyRule) Validate(data interface{}) (bool, []string, error)
```

### MetricsCollector

MetricsCollector collecte des métriques


#### Methods

##### MetricsCollector.SetErrorRate

SetErrorRate définit le taux d'erreur


```go
func (mc *MetricsCollector) SetErrorRate(rate float64)
```

##### MetricsCollector.SetLastSyncTime

SetLastSyncTime définit le temps de la dernière synchronisation


```go
func (mc *MetricsCollector) SetLastSyncTime(t time.Time)
```

##### MetricsCollector.SetResponseTime

SetResponseTime définit le temps de réponse


```go
func (mc *MetricsCollector) SetResponseTime(duration time.Duration)
```

### MetricsConfig

MetricsConfig represents metrics configuration


### MigrationAssistant

MigrationAssistant handles plan migrations


#### Methods

##### MigrationAssistant.CreateBackup

CreateBackup creates a backup of a plan


```go
func (ma *MigrationAssistant) CreateBackup(planPath string) (*Backup, error)
```

##### MigrationAssistant.MigratePlan

MigratePlan migrates a plan


```go
func (ma *MigrationAssistant) MigratePlan(planPath string) (*MigrationResult, error)
```

##### MigrationAssistant.RollbackMigration

RollbackMigration rolls back a migration


```go
func (ma *MigrationAssistant) RollbackMigration(backup *Backup) error
```

### MigrationResult

MigrationResult représente le résultat d'une migration


### MockTaskChange

MockTaskChange represents a mock task change for testing


### OperationResult

OperationResult stores individual operation results


### PerformanceMetrics

PerformanceMetrics handles performance metrics


#### Methods

##### PerformanceMetrics.GetAverageResponseTime

GetAverageResponseTime récupère le temps de réponse moyen


```go
func (pm *PerformanceMetrics) GetAverageResponseTime() float64
```

##### PerformanceMetrics.GetPerformanceReport

GetPerformanceReport récupère un rapport de performance


```go
func (pm *PerformanceMetrics) GetPerformanceReport() *PerformanceReport
```

##### PerformanceMetrics.GetRealtimeDashboardData

GetRealtimeDashboardData récupère les données du tableau de bord en temps réel


```go
func (pm *PerformanceMetrics) GetRealtimeDashboardData() map[string]interface{}
```

##### PerformanceMetrics.RecordMemoryUsage

RecordMemoryUsage records memory usage


```go
func (pm *PerformanceMetrics) RecordMemoryUsage(byteCount int)
```

##### PerformanceMetrics.RecordResponseTime

RecordResponseTime records a response time


```go
func (pm *PerformanceMetrics) RecordResponseTime(duration time.Duration)
```

##### PerformanceMetrics.RecordSyncOperation

RecordSyncOperation records a sync operation


```go
func (pm *PerformanceMetrics) RecordSyncOperation(duration time.Duration, itemsProcessed, errors int)
```

### PerformanceReport

PerformanceReport représente un rapport de performance


### PerformanceResults

PerformanceResults stores test results


### PerformanceTestSuite

PerformanceTestSuite contains performance and load tests


#### Methods

##### PerformanceTestSuite.AnalyzeResults

AnalyzeResults analyzes operation results and generates performance metrics


```go
func (suite *PerformanceTestSuite) AnalyzeResults(results []OperationResult, totalDuration time.Duration) *PerformanceResults
```

##### PerformanceTestSuite.CalculatePercentile

```go
func (suite *PerformanceTestSuite) CalculatePercentile(latencies []time.Duration, percentile int) time.Duration
```

##### PerformanceTestSuite.ChooseScenario

```go
func (suite *PerformanceTestSuite) ChooseScenario(scenarios []TestScenario) TestScenario
```

##### PerformanceTestSuite.ExecuteScenario

ExecuteScenario executes a specific test scenario


```go
func (suite *PerformanceTestSuite) ExecuteScenario(userID, operationID int, scenario TestScenario) OperationResult
```

##### PerformanceTestSuite.ExecuteSyncOperation

ExecuteSyncOperation executes a single sync operation


```go
func (suite *PerformanceTestSuite) ExecuteSyncOperation(workerID, operationID int) OperationResult
```

##### PerformanceTestSuite.ForceGarbageCollection

```go
func (suite *PerformanceTestSuite) ForceGarbageCollection()
```

##### PerformanceTestSuite.GeneratePerformanceReport

GeneratePerformanceReport generates a detailed performance report


```go
func (suite *PerformanceTestSuite) GeneratePerformanceReport(results *PerformanceResults, config *LoadTestConfig)
```

##### PerformanceTestSuite.GetCPUUsage

```go
func (suite *PerformanceTestSuite) GetCPUUsage() float64
```

##### PerformanceTestSuite.GetMemoryUsage

```go
func (suite *PerformanceTestSuite) GetMemoryUsage() uint64
```

##### PerformanceTestSuite.RunLoadTest

RunLoadTest executes a load test with the given configuration


```go
func (suite *PerformanceTestSuite) RunLoadTest(config *LoadTestConfig) (*PerformanceResults, error)
```

##### PerformanceTestSuite.RunStressTest

RunStressTest executes a stress test


```go
func (suite *PerformanceTestSuite) RunStressTest(config *LoadTestConfig) (*PerformanceResults, error)
```

##### PerformanceTestSuite.RunUserSession

RunUserSession simulates a user session


```go
func (suite *PerformanceTestSuite) RunUserSession(ctx context.Context, userID int, config *LoadTestConfig, mu *sync.Mutex, results *[]OperationResult)
```

##### PerformanceTestSuite.SimulateConflictResolution

```go
func (suite *PerformanceTestSuite) SimulateConflictResolution(params map[string]interface{}) error
```

##### PerformanceTestSuite.SimulateDynamicSync

```go
func (suite *PerformanceTestSuite) SimulateDynamicSync(params map[string]interface{}) error
```

##### PerformanceTestSuite.SimulateMarkdownSync

```go
func (suite *PerformanceTestSuite) SimulateMarkdownSync(params map[string]interface{}) error
```

##### PerformanceTestSuite.ValidatePerformanceResults

ValidatePerformanceResults validates results against expected criteria


```go
func (suite *PerformanceTestSuite) ValidatePerformanceResults(t *testing.T, results *PerformanceResults, config *LoadTestConfig)
```

### Phase

Phase represents a phase in a plan


### Plan

Plan represents a development plan


### PlanSynchronizer

PlanSynchronizer handles plan synchronization


#### Methods

##### PlanSynchronizer.SyncPlans

```go
func (ps *PlanSynchronizer) SyncPlans(source, target string) error
```

##### PlanSynchronizer.ValidateSync

```go
func (ps *PlanSynchronizer) ValidateSync() error
```

### PriorityBasedStrategy

PriorityBasedStrategy represents a priority-based resolution strategy


#### Methods

##### PriorityBasedStrategy.Name

Name returns the strategy name


```go
func (s *PriorityBasedStrategy) Name() string
```

##### PriorityBasedStrategy.Resolve

Resolve resolves a conflict based on priority


```go
func (s *PriorityBasedStrategy) Resolve(conflict *Conflict) (*ConflictResolution, error)
```

### ProgressChange

ProgressChange represents a progress modification


### ProgressConsistencyRule

ProgressConsistencyRule checks progress consistency


#### Methods

##### ProgressConsistencyRule.Validate

Validate validates the progress


```go
func (r *ProgressConsistencyRule) Validate(data interface{}) (bool, []string, error)
```

### RealtimeDashboard

RealtimeDashboard représente un tableau de bord en temps réel


#### Methods

##### RealtimeDashboard.GetConnectionCount

GetConnectionCount récupère le nombre de connexions


```go
func (rd *RealtimeDashboard) GetConnectionCount() int
```

### RegressionTestCase

RegressionTestCase defines regression test cases


### Report

Report represents a generated report


### ReportConfig

ReportConfig represents report configuration


### ReportGenerator

ReportGenerator generates reports


#### Methods

##### ReportGenerator.GenerateReport

GenerateReport generates a report for the given period


```go
func (rg *ReportGenerator) GenerateReport(reportType string, period ReportPeriod) (*Report, error)
```

##### ReportGenerator.SaveReport

SaveReport saves a report to disk


```go
func (rg *ReportGenerator) SaveReport(report *Report) error
```

### ReportPeriod

ReportPeriod represents a reporting period
ReportPeriod defines the time period covered by a report


### ReportPeriodType

ReportPeriodType represents the type of reporting period


### ResolutionConfig

ResolutionConfig contains configuration for conflict resolution


### ResolutionStrategy

ResolutionStrategy represents a conflict resolution strategy


### SMTPConfig

SMTPConfig represents SMTP configuration for alerts


### StructureChange

StructureChange represents a structure change


### StructureConsistencyRule

StructureConsistencyRule checks structure consistency


#### Methods

##### StructureConsistencyRule.Validate

Validate validates the structure


```go
func (r *StructureConsistencyRule) Validate(data interface{}) (bool, []string, error)
```

### SyncConfig

SyncConfig represents synchronization configuration


### SyncEngine

SyncEngine mock for testing


### SystemStatus

SystemStatus représente l'état du système


### Task

Task represents a task in a plan


### TaskChange

TaskChange represents a task modification


### TaskConsistencyRule

TaskConsistencyRule checks task consistency


#### Methods

##### TaskConsistencyRule.Validate

Validate validates the tasks


```go
func (r *TaskConsistencyRule) Validate(data interface{}) (bool, []string, error)
```

### TestPhase

TestPhase represents a test phase


### TestPlan

TestPlan represents a test plan structure


### TestScenario

TestScenario defines a specific test scenario


### TestTask

TestTask represents a test task


### TimestampBasedStrategy

TimestampBasedStrategy represents a timestamp-based resolution strategy


#### Methods

##### TimestampBasedStrategy.Name

Name returns the strategy name


```go
func (s *TimestampBasedStrategy) Name() string
```

##### TimestampBasedStrategy.Resolve

Resolve resolves a conflict based on timestamps


```go
func (s *TimestampBasedStrategy) Resolve(conflict *Conflict) (*ConflictResolution, error)
```

### TimestampConsistencyRule

TimestampConsistencyRule checks timestamp consistency


#### Methods

##### TimestampConsistencyRule.Validate

Validate validates the timestamps


```go
func (r *TimestampConsistencyRule) Validate(data interface{}) (bool, []string, error)
```

### ValidationConfig

ValidationConfig contains configuration for the consistency validator


### ValidationEngine

ValidationEngine mock for testing


### ValidationResult

ValidationResult represents validation test result


### ValidationRule

ValidationRule represents a validation rule


#### Methods

##### ValidationRule.GetDescription

GetDescription returns the description of a ValidationRule


```go
func (rule ValidationRule) GetDescription() string
```

##### ValidationRule.GetName

GetName is a compatibility method for ValidatonRule


```go
func (rule ValidationRule) GetName() string
```

##### ValidationRule.GetSeverity

GetSeverity returns the severity of a ValidationRule


```go
func (rule ValidationRule) GetSeverity() string
```

### ValidationRuleAdapter

ValidationRuleAdapter adapts ValidationRule to ConsistencyRule


#### Methods

##### ValidationRuleAdapter.Name

Name implements ConsistencyRule.Name


```go
func (vra *ValidationRuleAdapter) Name() string
```

##### ValidationRuleAdapter.Validate

Validate implements ConsistencyRule.Validate


```go
func (vra *ValidationRuleAdapter) Validate(data interface{}) (bool, []string, error)
```

### ValidationRuleType

ValidationRuleType is an alias for string


### ValidationSettings

ValidationSettings represents basic validation settings


### ValidationTestSuite

ValidationTestSuite contains validation and regression testing


#### Methods

##### ValidationTestSuite.RunAllValidationTests

RunAllValidationTests runs the complete validation test suite


```go
func (vts *ValidationTestSuite) RunAllValidationTests(t *testing.T)
```

##### ValidationTestSuite.TestConflictResolutionStrategies

TestConflictResolutionStrategies tests different conflict resolution strategies


```go
func (vts *ValidationTestSuite) TestConflictResolutionStrategies(t *testing.T)
```

##### ValidationTestSuite.TestCorrectionAutomatique

TestCorrectionAutomatique tests automatic correction capabilities


```go
func (vts *ValidationTestSuite) TestCorrectionAutomatique(t *testing.T)
```

##### ValidationTestSuite.TestDetectionDivergences

TestDetectionDivergences tests divergence detection capabilities


```go
func (vts *ValidationTestSuite) TestDetectionDivergences(t *testing.T)
```

##### ValidationTestSuite.TestPlansExistants

TestPlansExistants tests existing plans for regression


```go
func (vts *ValidationTestSuite) TestPlansExistants(t *testing.T)
```

##### ValidationTestSuite.TestRobustesse

TestRobustesse tests system robustness with edge cases


```go
func (vts *ValidationTestSuite) TestRobustesse(t *testing.T)
```

##### ValidationTestSuite.TestValidationRulesCoverage

TestValidationRulesCoverage tests coverage of all validation rules


```go
func (vts *ValidationTestSuite) TestValidationRulesCoverage(t *testing.T)
```

## Functions

### ConvertToString

ConvertToString converts a ConflictType to a string


```go
func ConvertToString(ct ConflictType) string
```

### GetAction

GetAction is a helper to get the Action field from ConflictResolution


```go
func GetAction(cr *ConflictResolution) string
```

### GetNameForValidationRule

GetNameForValidationRule is a helper function to get the name of a ValidationRule


```go
func GetNameForValidationRule(rule ValidationRule) string
```

### GetNameHelper

GetNameHelper is a helper function to get the name of a ConsistencyRule


```go
func GetNameHelper(rule ConsistencyRule) string
```

### GetRuleName

GetRuleName returns the name of a ConsistencyRule


```go
func GetRuleName(cr ConsistencyRule) string
```

### TestConcurrentSyncOperations

TestConcurrentSyncOperations tests concurrent sync operations


```go
func TestConcurrentSyncOperations(t *testing.T)
```

### TestIntegrationSuite

Run the integration test suite


```go
func TestIntegrationSuite(t *testing.T)
```

### TestLatencyPercentiles

TestLatencyPercentiles tests latency distribution


```go
func TestLatencyPercentiles(t *testing.T)
```

### TestMemoryLeaks

TestMemoryLeaks tests for memory leaks during extended operations


```go
func TestMemoryLeaks(t *testing.T)
```

### TestStressConditions

TestStressConditions tests system behavior under stress


```go
func TestStressConditions(t *testing.T)
```

### TestSyncPerformance

TestSyncPerformance tests synchronization performance under load


```go
func TestSyncPerformance(t *testing.T)
```

### ValidateRuleWithContext

ValidateRuleWithContext validates a rule with context


```go
func ValidateRuleWithContext(rule ConsistencyRule, ctx context.Context, testPlan string) ([]interface{}, error)
```

