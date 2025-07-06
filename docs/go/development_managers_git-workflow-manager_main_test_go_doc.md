# Package gitworkflowmanager

## Types

### GitWorkflowManagerFactory

Factory implementation


#### Methods

##### GitWorkflowManagerFactory.CreateGitWorkflowManager

```go
func (f *GitWorkflowManagerFactory) CreateGitWorkflowManager(ctx context.Context, config map[string]interface{}) (interfaces.GitWorkflowManager, error)
```

##### GitWorkflowManagerFactory.GetDefaultConfiguration

```go
func (f *GitWorkflowManagerFactory) GetDefaultConfiguration() map[string]interface{}
```

##### GitWorkflowManagerFactory.ValidateConfiguration

```go
func (f *GitWorkflowManagerFactory) ValidateConfiguration(config map[string]interface{}) error
```

### GitWorkflowManagerImpl

GitWorkflowManagerImpl implements the GitWorkflowManager interface


#### Methods

##### GitWorkflowManagerImpl.Cleanup

```go
func (g *GitWorkflowManagerImpl) Cleanup() error
```

##### GitWorkflowManagerImpl.ConfigureWebhook

```go
func (g *GitWorkflowManagerImpl) ConfigureWebhook(ctx context.Context, url string, events []string, secret string) error
```

##### GitWorkflowManagerImpl.CreateBranch

Branch Management implementation


```go
func (g *GitWorkflowManagerImpl) CreateBranch(ctx context.Context, branchName string, sourceBranch string) error
```

##### GitWorkflowManagerImpl.CreatePullRequest

Pull Request Management implementation


```go
func (g *GitWorkflowManagerImpl) CreatePullRequest(ctx context.Context, title, description, sourceBranch, targetBranch string) (*interfaces.PullRequestInfo, error)
```

##### GitWorkflowManagerImpl.CreateSubBranch

Sub-branch Management implementation


```go
func (g *GitWorkflowManagerImpl) CreateSubBranch(ctx context.Context, subBranchName string, parentBranch string, workflowType interfaces.WorkflowType) (*interfaces.SubBranchInfo, error)
```

##### GitWorkflowManagerImpl.CreateTimestampedCommit

```go
func (g *GitWorkflowManagerImpl) CreateTimestampedCommit(ctx context.Context, message string, files []string) (*interfaces.CommitInfo, error)
```

##### GitWorkflowManagerImpl.DeleteBranch

```go
func (g *GitWorkflowManagerImpl) DeleteBranch(ctx context.Context, branchName string, force bool) error
```

##### GitWorkflowManagerImpl.ExecuteWorkflow

Workflow Operations implementation


```go
func (g *GitWorkflowManagerImpl) ExecuteWorkflow(ctx context.Context, workflowType interfaces.WorkflowType, parameters map[string]interface{}) error
```

##### GitWorkflowManagerImpl.GetCommitHistory

```go
func (g *GitWorkflowManagerImpl) GetCommitHistory(ctx context.Context, branch string, limit int) ([]*interfaces.CommitInfo, error)
```

##### GitWorkflowManagerImpl.GetConfig

```go
func (g *GitWorkflowManagerImpl) GetConfig() map[string]interface{}
```

##### GitWorkflowManagerImpl.GetCurrentBranch

```go
func (g *GitWorkflowManagerImpl) GetCurrentBranch(ctx context.Context) (string, error)
```

##### GitWorkflowManagerImpl.GetID

BaseManager implementation


```go
func (g *GitWorkflowManagerImpl) GetID() string
```

##### GitWorkflowManagerImpl.GetLastCommit

```go
func (g *GitWorkflowManagerImpl) GetLastCommit(ctx context.Context, branch string) (*interfaces.CommitInfo, error)
```

##### GitWorkflowManagerImpl.GetMetadata

```go
func (g *GitWorkflowManagerImpl) GetMetadata() map[string]interface{}
```

##### GitWorkflowManagerImpl.GetName

```go
func (g *GitWorkflowManagerImpl) GetName() string
```

##### GitWorkflowManagerImpl.GetPullRequestStatus

```go
func (g *GitWorkflowManagerImpl) GetPullRequestStatus(ctx context.Context, prID int) (*interfaces.PullRequestInfo, error)
```

##### GitWorkflowManagerImpl.GetStatus

```go
func (g *GitWorkflowManagerImpl) GetStatus() string
```

##### GitWorkflowManagerImpl.GetWorkflowConfiguration

```go
func (g *GitWorkflowManagerImpl) GetWorkflowConfiguration(ctx context.Context) (map[string]interface{}, error)
```

##### GitWorkflowManagerImpl.GetWorkflowStatus

```go
func (g *GitWorkflowManagerImpl) GetWorkflowStatus(ctx context.Context) (map[string]interface{}, error)
```

##### GitWorkflowManagerImpl.Health

```go
func (g *GitWorkflowManagerImpl) Health() error
```

##### GitWorkflowManagerImpl.HealthCheck

BaseManager interface implementation


```go
func (g *GitWorkflowManagerImpl) HealthCheck(ctx context.Context) error
```

##### GitWorkflowManagerImpl.Initialize

```go
func (g *GitWorkflowManagerImpl) Initialize(ctx context.Context) error
```

##### GitWorkflowManagerImpl.ListBranches

```go
func (g *GitWorkflowManagerImpl) ListBranches(ctx context.Context) ([]string, error)
```

##### GitWorkflowManagerImpl.ListPullRequests

```go
func (g *GitWorkflowManagerImpl) ListPullRequests(ctx context.Context, status string) ([]*interfaces.PullRequestInfo, error)
```

##### GitWorkflowManagerImpl.ListSubBranches

```go
func (g *GitWorkflowManagerImpl) ListSubBranches(ctx context.Context, parentBranch string) ([]*interfaces.SubBranchInfo, error)
```

##### GitWorkflowManagerImpl.ListWebhooks

```go
func (g *GitWorkflowManagerImpl) ListWebhooks(ctx context.Context) ([]map[string]interface{}, error)
```

##### GitWorkflowManagerImpl.MergeSubBranch

```go
func (g *GitWorkflowManagerImpl) MergeSubBranch(ctx context.Context, subBranchName string, targetBranch string, deleteAfterMerge bool) error
```

##### GitWorkflowManagerImpl.ResetWorkflowConfiguration

```go
func (g *GitWorkflowManagerImpl) ResetWorkflowConfiguration(ctx context.Context) error
```

##### GitWorkflowManagerImpl.SendWebhook

Webhook Integration implementation


```go
func (g *GitWorkflowManagerImpl) SendWebhook(ctx context.Context, event string, payload *interfaces.WebhookPayload) error
```

##### GitWorkflowManagerImpl.SetMetadata

```go
func (g *GitWorkflowManagerImpl) SetMetadata(key string, value interface{}) error
```

##### GitWorkflowManagerImpl.SetWorkflowConfiguration

Configuration Management implementation


```go
func (g *GitWorkflowManagerImpl) SetWorkflowConfiguration(ctx context.Context, config map[string]interface{}) error
```

##### GitWorkflowManagerImpl.Shutdown

```go
func (g *GitWorkflowManagerImpl) Shutdown(ctx context.Context) error
```

##### GitWorkflowManagerImpl.SwitchBranch

```go
func (g *GitWorkflowManagerImpl) SwitchBranch(ctx context.Context, branchName string) error
```

##### GitWorkflowManagerImpl.UpdateConfig

```go
func (g *GitWorkflowManagerImpl) UpdateConfig(config map[string]interface{}) error
```

##### GitWorkflowManagerImpl.ValidateCommitMessage

Commit Management implementation


```go
func (g *GitWorkflowManagerImpl) ValidateCommitMessage(message string) error
```

##### GitWorkflowManagerImpl.ValidateWorkflow

```go
func (g *GitWorkflowManagerImpl) ValidateWorkflow(ctx context.Context, workflowType interfaces.WorkflowType) error
```

