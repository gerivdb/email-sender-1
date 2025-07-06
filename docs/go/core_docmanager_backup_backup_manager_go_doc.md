# Package backup

## Functions

### BackupAll

```go
func BackupAll(ctx context.Context) error
```

### BackupComponent

```go
func BackupComponent(ctx context.Context, name string) error
```

### RestoreFromBackup

```go
func RestoreFromBackup(ctx context.Context, backupID string) error
```

### ScheduleBackups

```go
func ScheduleBackups(ctx context.Context) error
```

### TestDisasterRecovery

```go
func TestDisasterRecovery(ctx context.Context) error
```

