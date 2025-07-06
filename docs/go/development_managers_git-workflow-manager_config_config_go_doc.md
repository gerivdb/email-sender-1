# Package main

## Types

### GitWorkflowConfig

GitWorkflowConfig represents the configuration for GitWorkflowManager


#### Methods

##### GitWorkflowConfig.ToMap

ToMap converts the configuration to a map[string]interface{}


```go
func (c *GitWorkflowConfig) ToMap() map[string]interface{}
```

## Functions

### SaveConfig

SaveConfig saves configuration to a YAML file


```go
func SaveConfig(config *GitWorkflowConfig, filename string) error
```

### ValidateConfig

ValidateConfig validates the configuration


```go
func ValidateConfig(config *GitWorkflowConfig) error
```

