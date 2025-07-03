# Package branch

## Types

### Manager

Manager handles Git branch operations


#### Methods

##### Manager.CreateBranch

CreateBranch creates a new branch from the specified source branch


```go
func (m *Manager) CreateBranch(ctx context.Context, branchName string, sourceBranch string) error
```

##### Manager.CreateSubBranch

CreateSubBranch creates a sub-branch with workflow-specific naming


```go
func (m *Manager) CreateSubBranch(ctx context.Context, subBranchName string, parentBranch string, workflowType interfaces.WorkflowType) (*interfaces.SubBranchInfo, error)
```

##### Manager.DeleteBranch

DeleteBranch deletes the specified branch


```go
func (m *Manager) DeleteBranch(ctx context.Context, branchName string, force bool) error
```

##### Manager.GetCurrentBranch

GetCurrentBranch returns the name of the current branch


```go
func (m *Manager) GetCurrentBranch(ctx context.Context) (string, error)
```

##### Manager.Health

Health checks the health of the branch manager


```go
func (m *Manager) Health() error
```

##### Manager.ListBranches

ListBranches returns a list of all branches


```go
func (m *Manager) ListBranches(ctx context.Context) ([]string, error)
```

##### Manager.ListSubBranches

ListSubBranches returns sub-branches for a given parent branch


```go
func (m *Manager) ListSubBranches(ctx context.Context, parentBranch string) ([]*interfaces.SubBranchInfo, error)
```

##### Manager.MergeSubBranch

MergeSubBranch merges a sub-branch into the target branch


```go
func (m *Manager) MergeSubBranch(ctx context.Context, subBranchName string, targetBranch string, deleteAfterMerge bool) error
```

##### Manager.Shutdown

Shutdown gracefully shuts down the branch manager


```go
func (m *Manager) Shutdown(ctx context.Context) error
```

##### Manager.SwitchBranch

SwitchBranch switches to the specified branch


```go
func (m *Manager) SwitchBranch(ctx context.Context, branchName string) error
```

