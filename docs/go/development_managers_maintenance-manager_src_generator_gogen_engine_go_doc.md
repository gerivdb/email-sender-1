# Package generator

Package generator provides advanced code generation capabilities for the maintenance manager

Package generator - Template definitions for the GoGenEngine


## Types

### GeneratedFile

GeneratedFile represents a generated file


### GenerationOptions

GenerationOptions controls generation behavior


### GenerationRequest

GenerationRequest represents a code generation request


### GenerationResult

GenerationResult represents the result of a generation operation


### GoGenEngine

GoGenEngine provides comprehensive code generation capabilities


#### Methods

##### GoGenEngine.Generate

Generate executes a code generation request


```go
func (e *GoGenEngine) Generate(req *GenerationRequest) (*GenerationResult, error)
```

##### GoGenEngine.GenerateFromTemplate

GenerateFromTemplate generates code using a specific template


```go
func (e *GoGenEngine) GenerateFromTemplate(templateName string, data interface{}, outputPath string) error
```

##### GoGenEngine.ListTemplates

ListTemplates returns available templates


```go
func (e *GoGenEngine) ListTemplates() []string
```

##### GoGenEngine.ValidateTemplate

ValidateTemplate validates a template


```go
func (e *GoGenEngine) ValidateTemplate(templateName string) error
```

### TemplateData

TemplateData holds data for template rendering


