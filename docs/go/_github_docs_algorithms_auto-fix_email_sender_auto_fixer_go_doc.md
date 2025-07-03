# Package main

## Types

### AutoFixStats

AutoFixStats tracks correction statistics


### EmailSenderAutoFixer

EmailSenderAutoFixer manages pattern-based error correction


#### Methods

##### EmailSenderAutoFixer.AutoFixFile

AutoFixFile applies pattern-matching fixes to a specific file


```go
func (fixer *EmailSenderAutoFixer) AutoFixFile(filename string, component EmailSenderComponent) (int, error)
```

##### EmailSenderAutoFixer.GenerateReport

GenerateReport creates a comprehensive fix report


```go
func (fixer *EmailSenderAutoFixer) GenerateReport()
```

### EmailSenderComponent

EmailSenderComponent represents different components of the EMAIL_SENDER_1 system


#### Methods

##### EmailSenderComponent.String

```go
func (c EmailSenderComponent) String() string
```

### EmailSenderFixRule

EmailSenderFixRule represents a pattern-matching fix rule


