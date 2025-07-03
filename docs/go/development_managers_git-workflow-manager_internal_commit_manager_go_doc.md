# Package commit

## Types

### Manager

Manager handles Git commit operations


#### Methods

##### Manager.AmendLastCommit

AmendLastCommit amends the last commit with new changes


```go
func (m *Manager) AmendLastCommit(ctx context.Context, newMessage string) (*interfaces.CommitInfo, error)
```

##### Manager.CreateCommitWithFiles

CreateCommitWithFiles creates a commit with specific files


```go
func (m *Manager) CreateCommitWithFiles(ctx context.Context, message string, files []string) (*interfaces.CommitInfo, error)
```

##### Manager.CreateTimestampedCommit

CreateTimestampedCommit creates a commit with a timestamped message


```go
func (m *Manager) CreateTimestampedCommit(ctx context.Context, message string, files []string) (*interfaces.CommitInfo, error)
```

##### Manager.GetCommitDetails

GetCommitDetails returns detailed information about a specific commit


```go
func (m *Manager) GetCommitDetails(ctx context.Context, commitHash string) (*interfaces.CommitInfo, error)
```

##### Manager.GetCommitHistory

GetCommitHistory returns the commit history for a branch


```go
func (m *Manager) GetCommitHistory(ctx context.Context, branch string, limit int) ([]*interfaces.CommitInfo, error)
```

##### Manager.GetCommitStats

GetCommitStats returns statistics about commits


```go
func (m *Manager) GetCommitStats(ctx context.Context, branch string, since time.Time) (map[string]interface{}, error)
```

##### Manager.GetLastCommit

GetLastCommit returns the last commit for a branch


```go
func (m *Manager) GetLastCommit(ctx context.Context, branch string) (*interfaces.CommitInfo, error)
```

##### Manager.Health

Health checks the health of the commit manager


```go
func (m *Manager) Health() error
```

##### Manager.Shutdown

Shutdown gracefully shuts down the commit manager


```go
func (m *Manager) Shutdown(ctx context.Context) error
```

##### Manager.ValidateCommitMessage

ValidateCommitMessage validates a commit message against conventional commit standards


```go
func (m *Manager) ValidateCommitMessage(message string) error
```

