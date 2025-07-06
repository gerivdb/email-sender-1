# Package templates

## Types

### AIAnalyzer

AIAnalyzer provides AI capabilities for template generation


### ActionInfo

ActionInfo describes post-generation actions


### DevPlanTemplate

DevPlanTemplate represents a development plan template structure


#### Methods

##### DevPlanTemplate.ParseTemplateFiles

ParseTemplateFiles is a helper method for DevPlanTemplate


```go
func (dpt *DevPlanTemplate) ParseTemplateFiles(templateDir string) *template.Template
```

### GenerationResult

GenerationResult represents the result of template generation


### GoGenEngine

GoGenEngine - Native Go template system to replace Hygen with AI integration


#### Methods

##### GoGenEngine.CreateTemplate

CreateTemplate creates a new template


```go
func (gge *GoGenEngine) CreateTemplate(template *DevPlanTemplate) error
```

##### GoGenEngine.GenerateDevPlan

GenerateDevPlan generates a development plan from template


```go
func (gge *GoGenEngine) GenerateDevPlan(planType string, variables map[string]interface{}) (*GenerationResult, error)
```

##### GoGenEngine.Initialize

Initialize initializes the GoGenEngine


```go
func (gge *GoGenEngine) Initialize(ctx context.Context) error
```

##### GoGenEngine.ValidateTemplate

ValidateTemplate validates a template


```go
func (gge *GoGenEngine) ValidateTemplate(templatePath string) error
```

### PostAction

PostAction represents actions to execute after template generation


### TemplateFile

TemplateFile represents a file to be generated from template


### TemplateInfo

TemplateInfo describes a template


### TemplateMetadata

TemplateMetadata contains template metadata


### ValidationRule

ValidationRule represents validation rules for generated content


### VariableInfo

VariableInfo describes template variables


## Functions

### GetDefaultTemplateRegistry

GetDefaultTemplateRegistry returns the registry of all default templates


```go
func GetDefaultTemplateRegistry() map[string]TemplateInfo
```

### GetTemplateDefaults

GetTemplateDefaults returns default values for template variables


```go
func GetTemplateDefaults(template TemplateInfo) map[string]interface{}
```

### GetTemplateFile

GetTemplateFile returns the content of a template file


```go
func GetTemplateFile(templatePath, fileName string) ([]byte, error)
```

### ListTemplateFiles

ListTemplateFiles returns all files in a template directory


```go
func ListTemplateFiles(templatePath string) ([]string, error)
```

### ValidateTemplateVariables

ValidateTemplateVariables checks if all required variables are provided


```go
func ValidateTemplateVariables(template TemplateInfo, variables map[string]interface{}) error
```

## Variables

### DefaultTemplates

DefaultTemplates contains embedded default templates for common scenarios


```go
var DefaultTemplates embed.FS
```

## Constants

### CategoryManager, CategoryAPI, CategoryDatabase, CategoryConfig, CategoryTest, CategoryDocker, CategoryCI

Template categories


```go
const (
	CategoryManager		= "manager"
	CategoryAPI		= "api"
	CategoryDatabase	= "database"
	CategoryConfig		= "config"
	CategoryTest		= "test"
	CategoryDocker		= "docker"
	CategoryCI		= "ci"
)
```

