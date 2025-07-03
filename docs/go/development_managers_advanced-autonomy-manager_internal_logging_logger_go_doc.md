# Package logging

Package logging provides logging capabilities for the AdvancedAutonomyManager


## Types

### LogLevel

LogLevel defines the severity of a log message


#### Methods

##### LogLevel.String

String returns the string representation of a log level


```go
func (l LogLevel) String() string
```

### Logger

Logger provides logging functionality


#### Methods

##### Logger.Debug

Debug logs a debug message


```go
func (l *Logger) Debug(msg string, keyvals ...interface{})
```

##### Logger.Error

Error logs an error message


```go
func (l *Logger) Error(msg string, keyvals ...interface{})
```

##### Logger.Fatal

Fatal logs a fatal message and exits the application


```go
func (l *Logger) Fatal(msg string, keyvals ...interface{})
```

##### Logger.Info

Info logs an informational message


```go
func (l *Logger) Info(msg string, keyvals ...interface{})
```

##### Logger.Warn

Warn logs a warning message


```go
func (l *Logger) Warn(msg string, keyvals ...interface{})
```

