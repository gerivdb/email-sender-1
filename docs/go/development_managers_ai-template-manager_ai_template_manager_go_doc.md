# Package ai_template_manager

## Types

### AITemplateManager

AITemplateManager implements the AI-powered template management system


#### Methods

##### AITemplateManager.AnalyzePatterns

AnalyzePatterns implements AITemplateManager.AnalyzePatterns


```go
func (atm *AITemplateManager) AnalyzePatterns(projectPath string) (*interfaces.PatternAnalysis, error)
```

##### AITemplateManager.Cleanup

Cleanup implements BaseManager.Cleanup


```go
func (atm *AITemplateManager) Cleanup() error
```

##### AITemplateManager.GenerateSuggestions

GenerateSuggestions implements AITemplateManager.GenerateSuggestions


```go
func (atm *AITemplateManager) GenerateSuggestions(context *interfaces.ProjectContext) (*interfaces.Suggestions, error)
```

##### AITemplateManager.HealthCheck

HealthCheck implements BaseManager.HealthCheck


```go
func (atm *AITemplateManager) HealthCheck(ctx context.Context) error
```

##### AITemplateManager.Initialize

Initialize implements BaseManager.Initialize


```go
func (atm *AITemplateManager) Initialize(ctx context.Context) error
```

##### AITemplateManager.OptimizeTemplate

OptimizeTemplate implements AITemplateManager.OptimizeTemplate


```go
func (atm *AITemplateManager) OptimizeTemplate(template *interfaces.Template, performance *interfaces.PerformanceMetrics) (*interfaces.Template, error)
```

##### AITemplateManager.ProcessTemplate

ProcessTemplate implements AITemplateManager.ProcessTemplate


```go
func (atm *AITemplateManager) ProcessTemplate(templatePath string, vars map[string]interface{}) (*interfaces.Template, error)
```

##### AITemplateManager.ValidateVariables

ValidateVariables implements AITemplateManager.ValidateVariables


```go
func (atm *AITemplateManager) ValidateVariables(template *interfaces.Template, vars map[string]interface{}) (*interfaces.ValidationResult, error)
```

### CachedTemplate

CachedTemplate represents a cached template with metadata


### Config

Config holds AITemplateManager configuration


### PerformanceStats

PerformanceStats tracks performance metrics


