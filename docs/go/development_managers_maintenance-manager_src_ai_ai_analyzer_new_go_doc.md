# Package ai

filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\maintenance-manager\src\ai\ai_analyzer.go


## Types

### AIAnalyzer

AIAnalyzer provides AI-driven analysis and optimization capabilities


#### Methods

##### AIAnalyzer.AnalyzeFiles

AnalyzeFiles performs AI-driven analysis of files and directories


```go
func (ai *AIAnalyzer) AnalyzeFiles(ctx context.Context, files []core.FileInfo) (*core.AnalysisResult, error)
```

##### AIAnalyzer.GetHealthStatus

GetHealthStatus returns the health status of the AI analyzer


```go
func (ai *AIAnalyzer) GetHealthStatus(ctx context.Context) core.HealthStatus
```

##### AIAnalyzer.RecordFeedback

RecordFeedback records user feedback for learning


```go
func (ai *AIAnalyzer) RecordFeedback(suggestionID string, success bool, feedback string) error
```

### AIChoice

AIChoice represents a choice in the AI response


### AIMessage

AIMessage represents a message in the AI conversation


### AIRequest

AIRequest represents a request to the AI service


### AIResponse

AIResponse represents the response from the AI service


### AIUsage

AIUsage represents token usage information


### AnalysisPattern

AnalysisPattern represents a recognized file organization pattern


### LearningData

LearningData contains accumulated learning information


### PatternSuccess

PatternSuccess records successful pattern applications


