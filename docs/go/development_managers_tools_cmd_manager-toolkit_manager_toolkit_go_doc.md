# Package main

## Types

### ManagerToolkit

Main toolkit structure


#### Methods

##### ManagerToolkit.Close

Close closes the toolkit and releases resources


```go
func (mt *ManagerToolkit) Close() error
```

##### ManagerToolkit.ExecuteOperation

ExecuteOperation executes the specified operation


```go
func (mt *ManagerToolkit) ExecuteOperation(ctx context.Context, op Operation, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.FixImports

FixImports fixes import statements


```go
func (mt *ManagerToolkit) FixImports(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.FixSyntaxErrors

FixSyntaxErrors fixes syntax errors


```go
func (mt *ManagerToolkit) FixSyntaxErrors(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.InitializeConfig

InitializeConfig initializes the toolkit configuration


```go
func (mt *ManagerToolkit) InitializeConfig(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.PrintFinalStats

PrintFinalStats prints a summary of operations performed


```go
func (mt *ManagerToolkit) PrintFinalStats()
```

##### ManagerToolkit.RemoveDuplicates

RemoveDuplicates removes duplicate code


```go
func (mt *ManagerToolkit) RemoveDuplicates(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.RunAnalysis

RunAnalysis performs comprehensive analysis


```go
func (mt *ManagerToolkit) RunAnalysis(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.RunDependencyAnalysis

RunDependencyAnalysis analyzes dependencies in the codebase


```go
func (mt *ManagerToolkit) RunDependencyAnalysis(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.RunDuplicateTypeDetection

RunDuplicateTypeDetection detects duplicate type definitions


```go
func (mt *ManagerToolkit) RunDuplicateTypeDetection(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.RunFullSuite

RunFullSuite runs the full suite of toolkit operations


```go
func (mt *ManagerToolkit) RunFullSuite(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.RunHealthCheck

RunHealthCheck performs a health check on the codebase


```go
func (mt *ManagerToolkit) RunHealthCheck(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.RunImportConflictResolution

RunImportConflictResolution resolves import conflicts in Go files


```go
func (mt *ManagerToolkit) RunImportConflictResolution(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.RunMigration

RunMigration performs interface migration


```go
func (mt *ManagerToolkit) RunMigration(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.RunNormalizeNaming

RunNormalizeNaming runs the naming normalizer


```go
func (mt *ManagerToolkit) RunNormalizeNaming(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.RunStructValidation

RunStructValidation validates struct declarations in the codebase


```go
func (mt *ManagerToolkit) RunStructValidation(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.RunSyntaxCheck

RunSyntaxCheck runs the syntax checker


```go
func (mt *ManagerToolkit) RunSyntaxCheck(ctx context.Context, opts *toolkit.OperationOptions) error
```

##### ManagerToolkit.RunTypeDefGen

RunTypeDefGen runs the type definition generator


```go
func (mt *ManagerToolkit) RunTypeDefGen(ctx context.Context, opts *toolkit.OperationOptions) error
```

### Operation

Command line operations


## Functions

### CreateDefaultConfigStruct

CreateDefaultConfigStruct creates a default configuration


```go
func CreateDefaultConfigStruct(baseDir string) *toolkit.ToolkitConfig
```

### LoadConfig

LoadConfig loads configuration from a JSON file


```go
func LoadConfig(path string) (*toolkit.ToolkitConfig, error)
```

### LoadOrCreateConfig

LoadOrCreateConfig loads an existing config or creates a default one


```go
func LoadOrCreateConfig(configPath, baseDir string) (*toolkit.ToolkitConfig, error)
```

### SaveConfig

SaveConfig saves configuration to a JSON file


```go
func SaveConfig(config *toolkit.ToolkitConfig, path string) error
```

## Constants

### ToolVersion, DefaultBaseDir, ConfigFile, LogFile

Configuration constants


```go
const (
	ToolVersion	= "3.0.0"
	DefaultBaseDir	= "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers"
	ConfigFile	= "toolkit.config.json"
	LogFile		= "toolkit.log"
)
```

