# Package tools

## Types

### Alert

Alert represents a system alert


### AlertConfig

AlertConfig contains configuration for alert management


### AlertFrequency

AlertFrequency represents frequency of alert types


### AlertManager

AlertManager handles sending alerts via multiple channels


#### Methods

##### AlertManager.ClearHistory

ClearHistory clears the alert history


```go
func (am *AlertManager) ClearHistory()
```

##### AlertManager.GetAlertHistory

GetAlertHistory returns the alert history


```go
func (am *AlertManager) GetAlertHistory(limit int) []Alert
```

##### AlertManager.GetRecentAlerts

GetRecentAlerts returns recent alerts (used by dashboard and reporting)


```go
func (am *AlertManager) GetRecentAlerts(limit int) []Alert
```

##### AlertManager.GetStats

GetStats returns alert statistics


```go
func (am *AlertManager) GetStats() AlertStats
```

##### AlertManager.SendAlert

SendAlert sends an alert through all configured channels


```go
func (am *AlertManager) SendAlert(alert Alert) error
```

##### AlertManager.TestConnections

TestConnections tests the configured alert channels


```go
func (am *AlertManager) TestConnections() map[string]error
```

### AlertStats

AlertStats holds statistics about alerts


### AlertsSection

AlertsSection contains alert analysis and statistics


### Attachment

Attachment represents a Slack message attachment


### BusinessMetrics

BusinessMetrics contains business-specific metrics


### BusinessSection

BusinessSection contains business-oriented metrics and insights


### ChartData

ChartData represents data for generating charts in reports


### ConflictLogEntry

ConflictLogEntry represents a conflict log


### DashboardData

DashboardData represents real-time dashboard data


### DriftDetector

DriftDetector monitors for synchronization drift and performance issues


#### Methods

##### DriftDetector.GetStatus

GetStatus returns the current status of the drift detector


```go
func (dd *DriftDetector) GetStatus() map[string]interface{}
```

##### DriftDetector.GetThresholds

GetThresholds returns current threshold values


```go
func (dd *DriftDetector) GetThresholds() map[string]float64
```

##### DriftDetector.SetCheckInterval

SetCheckInterval updates the monitoring interval


```go
func (dd *DriftDetector) SetCheckInterval(interval time.Duration)
```

##### DriftDetector.Start

Start begins drift monitoring


```go
func (dd *DriftDetector) Start() error
```

##### DriftDetector.Stop

Stop stops drift monitoring


```go
func (dd *DriftDetector) Stop() error
```

##### DriftDetector.UpdateThreshold

UpdateThreshold updates a specific threshold value


```go
func (dd *DriftDetector) UpdateThreshold(key string, value float64) error
```

### EmailSender

EmailSender handles email delivery


#### Methods

##### EmailSender.SendEmail

SendEmail sends email using SMTP


```go
func (es *EmailSender) SendEmail(toEmails []string, subject, body string) error
```

### ErrorStats

ErrorStats represents error frequency statistics


### Field

Field represents a Slack attachment field


### MetricsConfig

MetricsConfig configuration for performance metrics


### PerformanceMetrics

PerformanceMetrics collects and analyzes system performance data


#### Methods

##### PerformanceMetrics.AddRecentError

AddRecentError adds an error message to the recent errors list


```go
func (pm *PerformanceMetrics) AddRecentError(err string)
```

##### PerformanceMetrics.CollectBusinessMetrics

CollectBusinessMetrics collects business-specific metrics


```go
func (pm *PerformanceMetrics) CollectBusinessMetrics() (*BusinessMetrics, error)
```

##### PerformanceMetrics.DecrementActiveSyncCount

DecrementActiveSyncCount decrements the active sync counter


```go
func (pm *PerformanceMetrics) DecrementActiveSyncCount()
```

##### PerformanceMetrics.GetActiveProcessCount

GetActiveProcessCount returns count of active processes


```go
func (pm *PerformanceMetrics) GetActiveProcessCount() int
```

##### PerformanceMetrics.GetActiveSyncCount

GetActiveSyncCount returns the number of currently active sync operations


```go
func (pm *PerformanceMetrics) GetActiveSyncCount() int
```

##### PerformanceMetrics.GetAffectedPlans

GetAffectedPlans returns list of plans affected by issues


```go
func (pm *PerformanceMetrics) GetAffectedPlans() []string
```

##### PerformanceMetrics.GetAvailableMemoryMB

GetAvailableMemoryMB returns available memory in MB


```go
func (pm *PerformanceMetrics) GetAvailableMemoryMB() float64
```

##### PerformanceMetrics.GetAvailableSpaceGB

GetAvailableSpaceGB returns available disk space in GB


```go
func (pm *PerformanceMetrics) GetAvailableSpaceGB() float64
```

##### PerformanceMetrics.GetAverageResponseTime

GetAverageResponseTime returns the average response time in milliseconds


```go
func (pm *PerformanceMetrics) GetAverageResponseTime() float64
```

##### PerformanceMetrics.GetConsistencyScore

GetConsistencyScore returns a consistency score based on error rate


```go
func (pm *PerformanceMetrics) GetConsistencyScore() float64
```

##### PerformanceMetrics.GetDiskUsagePercent

GetDiskUsagePercent returns disk usage as a percentage


```go
func (pm *PerformanceMetrics) GetDiskUsagePercent() float64
```

##### PerformanceMetrics.GetErrorRate

GetErrorRate returns the current error rate as a percentage


```go
func (pm *PerformanceMetrics) GetErrorRate() float64
```

##### PerformanceMetrics.GetFailedOperations

GetFailedOperations returns the total number of failed operations


```go
func (pm *PerformanceMetrics) GetFailedOperations() int
```

##### PerformanceMetrics.GetInconsistencies

GetInconsistencies returns list of inconsistencies detected


```go
func (pm *PerformanceMetrics) GetInconsistencies() []string
```

##### PerformanceMetrics.GetLastSyncTime

GetLastSyncTime returns the timestamp of the last synchronization


```go
func (pm *PerformanceMetrics) GetLastSyncTime() time.Time
```

##### PerformanceMetrics.GetLastValidationTime

GetLastValidationTime returns the timestamp of the last validation


```go
func (pm *PerformanceMetrics) GetLastValidationTime() time.Time
```

##### PerformanceMetrics.GetLogFilesSizeMB

Additional methods for queue and system monitoring


```go
func (pm *PerformanceMetrics) GetLogFilesSizeMB() float64
```

##### PerformanceMetrics.GetMemoryUsagePercent

GetMemoryUsagePercent returns memory usage as a percentage


```go
func (pm *PerformanceMetrics) GetMemoryUsagePercent() float64
```

##### PerformanceMetrics.GetOldestQueueItemAge

```go
func (pm *PerformanceMetrics) GetOldestQueueItemAge() time.Duration
```

##### PerformanceMetrics.GetPerformanceReport

GetPerformanceReport generates a comprehensive performance report


```go
func (pm *PerformanceMetrics) GetPerformanceReport() *PerformanceReport
```

##### PerformanceMetrics.GetPerformanceTrend

GetPerformanceTrend returns the performance trend analysis


```go
func (pm *PerformanceMetrics) GetPerformanceTrend() string
```

##### PerformanceMetrics.GetProcessingRate

```go
func (pm *PerformanceMetrics) GetProcessingRate() float64
```

##### PerformanceMetrics.GetQueueGrowthTrend

```go
func (pm *PerformanceMetrics) GetQueueGrowthTrend() string
```

##### PerformanceMetrics.GetQueueSize

```go
func (pm *PerformanceMetrics) GetQueueSize() int
```

##### PerformanceMetrics.GetRealtimeDashboardData

GetRealtimeDashboardData returns data for real-time dashboard


```go
func (pm *PerformanceMetrics) GetRealtimeDashboardData() map[string]interface{}
```

##### PerformanceMetrics.GetRecentErrors

GetRecentErrors returns the list of recent error messages with optional limit


```go
func (pm *PerformanceMetrics) GetRecentErrors(limit ...int) []string
```

##### PerformanceMetrics.GetThroughput

GetThroughput returns the current throughput (operations per second)


```go
func (pm *PerformanceMetrics) GetThroughput() float64
```

##### PerformanceMetrics.GetTotalOperations

GetTotalOperations returns the total number of operations processed


```go
func (pm *PerformanceMetrics) GetTotalOperations() int
```

##### PerformanceMetrics.IncrementActiveSyncCount

IncrementActiveSyncCount increments the active sync counter


```go
func (pm *PerformanceMetrics) IncrementActiveSyncCount()
```

##### PerformanceMetrics.IncrementTotalOperations

IncrementTotalOperations increments the total operations counter


```go
func (pm *PerformanceMetrics) IncrementTotalOperations()
```

##### PerformanceMetrics.RecordMemoryUsage

RecordMemoryUsage records memory usage


```go
func (pm *PerformanceMetrics) RecordMemoryUsage(usage uint64)
```

##### PerformanceMetrics.RecordResponseTime

RecordResponseTime records API response time


```go
func (pm *PerformanceMetrics) RecordResponseTime(duration time.Duration)
```

##### PerformanceMetrics.RecordSyncOperation

RecordSyncOperation records a synchronization operation


```go
func (pm *PerformanceMetrics) RecordSyncOperation(duration time.Duration, processed int, errors int)
```

##### PerformanceMetrics.SetLastSyncTime

SetLastSyncTime updates the last synchronization timestamp


```go
func (pm *PerformanceMetrics) SetLastSyncTime(t time.Time)
```

### PerformanceReport

PerformanceReport contains analyzed performance data


### PerformanceSection

PerformanceSection contains detailed performance analysis


### RealtimeDashboard

RealtimeDashboard provides real-time metrics dashboard functionality


#### Methods

##### RealtimeDashboard.GetConnectionCount

GetConnectionCount returns the number of active WebSocket connections


```go
func (rd *RealtimeDashboard) GetConnectionCount() int
```

##### RealtimeDashboard.StartDashboard

StartDashboard starts the real-time dashboard server


```go
func (rd *RealtimeDashboard) StartDashboard(port int) error
```

##### RealtimeDashboard.Stop

Stop stops the dashboard server


```go
func (rd *RealtimeDashboard) Stop() error
```

### Report

Report represents a comprehensive system report


### ReportConfig

ReportConfig contains configuration for report generation


### ReportGenerator

ReportGenerator handles automated report generation


#### Methods

##### ReportGenerator.CleanupOldReports

CleanupOldReports removes old reports based on retention policy


```go
func (rg *ReportGenerator) CleanupOldReports() error
```

##### ReportGenerator.GenerateReport

GenerateReport generates a comprehensive system report


```go
func (rg *ReportGenerator) GenerateReport(reportType string, period ReportPeriod) (*Report, error)
```

##### ReportGenerator.SaveReport

SaveReport saves a report in the specified formats


```go
func (rg *ReportGenerator) SaveReport(report *Report) error
```

##### ReportGenerator.StartScheduledReporting

StartScheduledReporting starts automatic report generation


```go
func (rg *ReportGenerator) StartScheduledReporting()
```

### ReportPeriod

ReportPeriod defines the time period covered by the report


### ReportSummary

ReportSummary contains executive summary information


### SeasonalPattern

SeasonalPattern represents seasonal usage patterns


### SlackMessage

SlackMessage represents a Slack webhook payload


### SyncLogEntry

SyncLogEntry represents a sync operation log


### SyncLogger

SyncLogger simple in-memory implementation


#### Methods

##### SyncLogger.CleanupOldLogs

CleanupOldLogs cleans old logs


```go
func (sl *SyncLogger) CleanupOldLogs(retentionDays int) error
```

##### SyncLogger.Close

Close closes the logger


```go
func (sl *SyncLogger) Close() error
```

##### SyncLogger.GetActiveConflicts

GetActiveConflicts returns active conflicts


```go
func (sl *SyncLogger) GetActiveConflicts() ([]ConflictLogEntry, error)
```

##### SyncLogger.GetSyncHistory

GetSyncHistory returns sync history


```go
func (sl *SyncLogger) GetSyncHistory(limit, offset int, operation, status string) ([]SyncLogEntry, error)
```

##### SyncLogger.GetSyncStats

GetSyncStats returns sync statistics


```go
func (sl *SyncLogger) GetSyncStats(since time.Time) (*SyncStats, error)
```

##### SyncLogger.LogConflict

LogConflict logs a conflict


```go
func (sl *SyncLogger) LogConflict(conflictID, filePath, conflictType, severity, sourceContent, targetContent string) error
```

##### SyncLogger.LogConflictResolution

LogConflictResolution logs conflict resolution


```go
func (sl *SyncLogger) LogConflictResolution(conflictID, resolution, resolvedBy, mergedContent string) error
```

##### SyncLogger.LogOperation

LogOperation logs a sync operation


```go
func (sl *SyncLogger) LogOperation(operation, status string, duration time.Duration, details string, metadata map[string]interface{}) error
```

### SyncStats

SyncStats represents sync statistics


### SystemStatus

SystemStatus represents current system status


### TrendAnalysis

TrendAnalysis contains trend analysis data


### TrendsSection

TrendsSection contains trend analysis and predictions


### UserSatisfaction

UserSatisfaction contains user satisfaction metrics


## Variables

### DriftThresholds

DriftThresholds contains default threshold values


```go
var DriftThresholds = map[string]float64{
	"sync_delay_minutes":	30.0,
	"error_rate_percent":	5.0,
	"response_time_ms":	1000.0,
	"memory_usage_percent":	80.0,
	"disk_space_percent":	90.0,
	"queue_size":		100.0,
	"consistency_score":	90.0,
}
```

