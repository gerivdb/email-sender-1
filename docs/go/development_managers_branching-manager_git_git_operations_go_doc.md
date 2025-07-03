# Package git

## Types

### AheadBehindInfo

AheadBehindInfo represents ahead/behind commit counts


### GitConfig

GitConfig holds Git operation configuration


### GitOperationsManager

GitOperationsManager handles real Git operations


#### Methods

##### GitOperationsManager.CreateBranch

CreateBranch creates a new Git branch


```go
func (g *GitOperationsManager) CreateBranch(ctx context.Context, branchName, baseBranch string) (*interfaces.GitBranchResult, error)
```

##### GitOperationsManager.CreateCommit

CreateCommit creates a new commit with changes


```go
func (g *GitOperationsManager) CreateCommit(ctx context.Context, message string, files []string) (*interfaces.GitCommitResult, error)
```

##### GitOperationsManager.CreateTemporalSnapshot

CreateTemporalSnapshot creates a temporal snapshot for time-travel functionality


```go
func (g *GitOperationsManager) CreateTemporalSnapshot(ctx context.Context, branchName string, metadata map[string]interface{}) (*interfaces.TemporalSnapshot, error)
```

##### GitOperationsManager.DeleteBranch

DeleteBranch deletes a Git branch


```go
func (g *GitOperationsManager) DeleteBranch(ctx context.Context, branchName string, force bool) error
```

##### GitOperationsManager.GetBranchInfo

GetBranchInfo gets information about a branch


```go
func (g *GitOperationsManager) GetBranchInfo(ctx context.Context, branchName string) (*interfaces.GitBranchInfo, error)
```

##### GitOperationsManager.GetChangedFiles

GetChangedFiles returns files changed in the current branch


```go
func (g *GitOperationsManager) GetChangedFiles(ctx context.Context, baseBranch string) ([]string, error)
```

##### GitOperationsManager.GetCurrentBranch

GetCurrentBranch returns the current branch name


```go
func (g *GitOperationsManager) GetCurrentBranch(ctx context.Context) (string, error)
```

##### GitOperationsManager.GetRepositoryStatus

GetRepositoryStatus returns the current repository status


```go
func (g *GitOperationsManager) GetRepositoryStatus(ctx context.Context) (*interfaces.GitRepositoryStatus, error)
```

##### GitOperationsManager.Health

Health checks the Git operations manager health


```go
func (g *GitOperationsManager) Health(ctx context.Context) error
```

##### GitOperationsManager.ListBranches

ListBranches lists all branches


```go
func (g *GitOperationsManager) ListBranches(ctx context.Context, includeRemote bool) ([]string, error)
```

##### GitOperationsManager.MergeBranch

MergeBranch merges a branch into the target branch


```go
func (g *GitOperationsManager) MergeBranch(ctx context.Context, sourceBranch, targetBranch string, mergeMessage string) (*interfaces.GitMergeResult, error)
```

##### GitOperationsManager.PushBranch

PushBranch pushes a branch to remote repository


```go
func (g *GitOperationsManager) PushBranch(ctx context.Context, branchName string) error
```

##### GitOperationsManager.TimeTravelToSnapshot

TimeTravelToSnapshot restores repository to a specific snapshot


```go
func (g *GitOperationsManager) TimeTravelToSnapshot(ctx context.Context, snapshot *interfaces.TemporalSnapshot) error
```

##### GitOperationsManager.ValidateRepository

ValidateRepository validates that the repository is in a good state


```go
func (g *GitOperationsManager) ValidateRepository(ctx context.Context) error
```

### GitResult

GitResult represents the result of a Git operation


