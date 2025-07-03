# Package main

## Types

### AnalysisConfig

AnalysisConfig holds configuration for the analysis pipeline


### AnalysisMetrics

AnalysisMetrics represents various metrics collected during analysis


### AnalysisRecommendation

AnalysisRecommendation represents actionable recommendations


### ComponentAnalysis

ComponentAnalysis represents analysis results for a specific component


### EmailSenderAnalysisPipeline

EmailSenderAnalysisPipeline manages the comprehensive analysis process


#### Methods

##### EmailSenderAnalysisPipeline.AnalyzeAlgorithmResults

AnalyzeAlgorithmResults analyzes results from previous algorithms


```go
func (pipeline *EmailSenderAnalysisPipeline) AnalyzeAlgorithmResults() error
```

##### EmailSenderAnalysisPipeline.AnalyzeComponents

AnalyzeComponents performs detailed analysis of each EMAIL_SENDER_1 component


```go
func (pipeline *EmailSenderAnalysisPipeline) AnalyzeComponents() error
```

##### EmailSenderAnalysisPipeline.CalculateOverallMetrics

CalculateOverallMetrics calculates overall system metrics


```go
func (pipeline *EmailSenderAnalysisPipeline) CalculateOverallMetrics()
```

##### EmailSenderAnalysisPipeline.CollectAnalysisData

CollectAnalysisData collects data from various sources for analysis


```go
func (pipeline *EmailSenderAnalysisPipeline) CollectAnalysisData() error
```

##### EmailSenderAnalysisPipeline.DisplayAnalysisSummary

DisplayAnalysisSummary displays a summary of the analysis results


```go
func (pipeline *EmailSenderAnalysisPipeline) DisplayAnalysisSummary()
```

##### EmailSenderAnalysisPipeline.GenerateOptimizationPlan

GenerateOptimizationPlan generates a comprehensive optimization plan


```go
func (pipeline *EmailSenderAnalysisPipeline) GenerateOptimizationPlan() error
```

##### EmailSenderAnalysisPipeline.GenerateReport

GenerateReport generates the comprehensive analysis report


```go
func (pipeline *EmailSenderAnalysisPipeline) GenerateReport(outputFile string) error
```

##### EmailSenderAnalysisPipeline.LoadConfig

LoadConfig loads analysis configuration from file


```go
func (pipeline *EmailSenderAnalysisPipeline) LoadConfig(configFile string) error
```

### HistoricalDataPoint

HistoricalDataPoint represents a point in time for trend analysis


### OptimizationAction

OptimizationAction represents a specific optimization action


### OptimizationPlan

OptimizationPlan represents the optimization strategy


### PerformanceMetrics

PerformanceMetrics represents performance-related metrics


### ReportSummary

ReportSummary provides executive summary of analysis


### TrendAnalysis

TrendAnalysis represents trend analysis over time


