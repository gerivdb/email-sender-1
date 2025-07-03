# Package template_performance_manager

Package template_performance_manager provides advanced AI-powered template performance analytics
and optimization capabilities for the FMOUA ecosystem.

This manager integrates neural pattern processing, real-time metrics collection,
and adaptive optimization to maximize template generation performance.


## Types

### Config

Config holds configuration for the manager


### Manager

Manager implements the TemplatePerformanceAnalyticsManager interface
providing comprehensive template performance analysis and optimization


#### Methods

##### Manager.AnalyzeTemplatePerformance

AnalyzeTemplatePerformance performs comprehensive template performance analysis


```go
func (m *Manager) AnalyzeTemplatePerformance(ctx context.Context, request interfaces.AnalysisRequest) (*interfaces.PerformanceAnalysis, error)
```

##### Manager.ApplyOptimizations

ApplyOptimizations applies optimization recommendations


```go
func (m *Manager) ApplyOptimizations(ctx context.Context, request interfaces.OptimizationApplicationRequest) (*interfaces.OptimizationResult, error)
```

##### Manager.GenerateAnalyticsReport

GenerateAnalyticsReport creates comprehensive analytics reports


```go
func (m *Manager) GenerateAnalyticsReport(ctx context.Context, request interfaces.ReportRequest) (*interfaces.AnalyticsReport, error)
```

##### Manager.GetManagerStatus

GetManagerStatus returns current manager status


```go
func (m *Manager) GetManagerStatus() interfaces.ManagerStatus
```

##### Manager.GetPerformanceMetrics

GetPerformanceMetrics retrieves current performance metrics


```go
func (m *Manager) GetPerformanceMetrics(ctx context.Context, filter interfaces.MetricsFilter) (*interfaces.PerformanceMetrics, error)
```

##### Manager.Initialize

Initialize sets up the manager and its components


```go
func (m *Manager) Initialize(ctx context.Context) error
```

##### Manager.SetCallbacks

SetCallbacks configures event callbacks


```go
func (m *Manager) SetCallbacks(
	onAnalysisComplete func(*interfaces.PerformanceAnalysis),
	onOptimization func(*interfaces.OptimizationResult),
	onError func(error),
)
```

##### Manager.Start

Start begins the manager's operations


```go
func (m *Manager) Start(ctx context.Context) error
```

##### Manager.Stop

Stop gracefully shuts down the manager


```go
func (m *Manager) Stop(ctx context.Context) error
```

