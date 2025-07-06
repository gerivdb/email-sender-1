# Package utils

## Types

### PIDManager

PIDManager handles PID file operations


#### Methods

##### PIDManager.GetPIDFile

GetPIDFile returns the PID file path


```go
func (p *PIDManager) GetPIDFile() string
```

##### PIDManager.RemovePID

RemovePID removes the PID file


```go
func (p *PIDManager) RemovePID() error
```

##### PIDManager.WritePID

WritePID writes the current process ID to the PID file


```go
func (p *PIDManager) WritePID() error
```

## Functions

### FirstNonEmpty

```go
func FirstNonEmpty(str1, str2 string) string
```

### MapToEnvList

MapToEnvList converts a map to a slice of "key=value" strings.


```go
func MapToEnvList(env map[string]string) []string
```

### SendSignalToPIDFile

SendSignalToPIDFile sends a signal to the process identified by the PID file


```go
func SendSignalToPIDFile(pidFile string, sig syscall.Signal) error
```

