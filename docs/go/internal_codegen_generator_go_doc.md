# Package codegen

Package codegen provides advanced code generation for RAG system
Time-Saving Method 5: Code Generation Framework
ROI: +36h immediate (eliminates 80% boilerplate code)


## Types

### ComponentSpec

ComponentSpec defines a component to generate


### FieldSpec

FieldSpec defines struct fields


### Generator

Generator handles automatic code generation for RAG components


#### Methods

##### Generator.GenerateCLI

GenerateCLI generates CLI commands for the RAG system


```go
func (g *Generator) GenerateCLI() error
```

##### Generator.GenerateComponent

GenerateComponent generates code for a specific component


```go
func (g *Generator) GenerateComponent(spec ComponentSpec) error
```

##### Generator.GenerateRAGService

GenerateRAGService generates a complete RAG service with all components


```go
func (g *Generator) GenerateRAGService() error
```

### GeneratorConfig

GeneratorConfig controls code generation behavior


### InterfaceSpec

InterfaceSpec defines an interface to implement


### MethodSpec

MethodSpec defines a method to generate


### ParamSpec

ParamSpec defines method parameters


