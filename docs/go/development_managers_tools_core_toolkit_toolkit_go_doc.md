# Package toolkit

// Package toolkit fournit les structures minimales pour les tests struct_validator.


## Types

### DependencyHealth

DependencyHealth contains dependency-related health information


### DuplicateRemover

DuplicateRemover removes duplicate code and methods


#### Methods

##### DuplicateRemover.ProcessAllFiles

ProcessAllFiles processes all Go files to remove duplicates


```go
func (dr *DuplicateRemover) ProcessAllFiles() error
```

##### DuplicateRemover.ProcessSingleFile

ProcessSingleFile processes a single file for duplicate removal


```go
func (dr *DuplicateRemover) ProcessSingleFile(filePath string) error
```

### FileStatistics

FileStatistics contains file-related statistics


### HealthChecker

HealthChecker performs comprehensive health checks


#### Methods

##### HealthChecker.CheckHealth

CheckHealth performs comprehensive health check


```go
func (hc *HealthChecker) CheckHealth() *HealthReport
```

### HealthIssue

HealthIssue represents a health issue


### HealthReport

HealthReport contains health check results


### ImportFixer

ImportFixer handles sophisticated import statement fixes


#### Methods

##### ImportFixer.FixAllImports

FixAllImports fixes imports across all Go files


```go
func (fixer *ImportFixer) FixAllImports() error
```

##### ImportFixer.FixSingleFile

FixSingleFile fixes imports in a single file


```go
func (fixer *ImportFixer) FixSingleFile(filePath string) error
```

### Logger

Logger provides logging functionality for toolkit operations


#### Methods

##### Logger.Close

Close closes the logger (placeholder)


```go
func (l *Logger) Close() error
```

##### Logger.Debug

Debug logs a debug message


```go
func (l *Logger) Debug(format string, args ...interface{})
```

##### Logger.Error

Error logs an error message


```go
func (l *Logger) Error(format string, args ...interface{})
```

##### Logger.Info

Info logs an info message


```go
func (l *Logger) Info(format string, args ...interface{})
```

##### Logger.Warn

Warn logs a warning message


```go
func (l *Logger) Warn(format string, args ...interface{})
```

### MethodRange

MethodRange represents a method's position in the file


### Operation

Type Operation représente le type d'opération dans le toolkit


### OperationOptions

OperationOptions holds options for operations


### SyntaxFixer

SyntaxFixer fixes syntax errors in Go files


#### Methods

##### SyntaxFixer.FixAllFiles

FixAllFiles fixes syntax errors in all Go files


```go
func (sf *SyntaxFixer) FixAllFiles() error
```

##### SyntaxFixer.FixSingleFile

FixSingleFile fixes syntax errors in a single file


```go
func (sf *SyntaxFixer) FixSingleFile(filePath string) error
```

### ToolkitConfig

Configuration du toolkit


### ToolkitOperation

ToolkitOperation represents the common interface for all toolkit operations


### ToolkitStats

ToolkitStats tracks operation statistics


## Constants

### LogLevelDebug, LogLevelInfo, LogLevelWarn, LogLevelError

LogLevel constants


```go
const (
	LogLevelDebug	= "DEBUG"
	LogLevelInfo	= "INFO"
	LogLevelWarn	= "WARN"
	LogLevelError	= "ERROR"
)
```

