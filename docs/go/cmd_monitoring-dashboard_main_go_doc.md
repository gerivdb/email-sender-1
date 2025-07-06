# Package main

Ultra-Advanced 8-Level Branching Framework - Monitoring Dashboard


## Types

### Alert

Alert represents an active alert


### AlertManager

AlertManager handles alerting logic


### AlertRule

AlertRule defines alerting conditions


### DashboardMetrics

DashboardMetrics represents real-time metrics for the dashboard


### HealthCheck

HealthCheck represents individual health check


### HealthChecker

HealthChecker monitors system health


### MetricsCollector

MetricsCollector handles Prometheus metrics


### MonitoringDashboard

MonitoringDashboard provides comprehensive observability


#### Methods

##### MonitoringDashboard.Start

Start begins the monitoring dashboard server


```go
func (md *MonitoringDashboard) Start(ctx context.Context, port int) error
```

##### MonitoringDashboard.Stop

Stop gracefully shuts down the monitoring dashboard


```go
func (md *MonitoringDashboard) Stop(ctx context.Context) error
```

### Notifier

Notifier interface for alert notifications


### PerformanceStats

PerformanceStats tracks detailed performance metrics


### ResourceUsage

ResourceUsage tracks system resource consumption


