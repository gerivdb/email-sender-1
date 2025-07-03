# Package pr

## Types

### Manager

Manager handles GitHub Pull Request operations


#### Methods

##### Manager.AddComment

AddComment adds a comment to a pull request


```go
func (m *Manager) AddComment(ctx context.Context, prID int, comment string) error
```

##### Manager.ClosePullRequest

ClosePullRequest closes a pull request


```go
func (m *Manager) ClosePullRequest(ctx context.Context, prID int) error
```

##### Manager.CreatePullRequest

CreatePullRequest creates a new pull request


```go
func (m *Manager) CreatePullRequest(ctx context.Context, title, description, sourceBranch, targetBranch string) (*interfaces.PullRequestInfo, error)
```

##### Manager.GetPullRequestComments

GetPullRequestComments returns comments for a pull request


```go
func (m *Manager) GetPullRequestComments(ctx context.Context, prID int) ([]map[string]interface{}, error)
```

##### Manager.GetPullRequestFiles

GetPullRequestFiles returns the files changed in a pull request


```go
func (m *Manager) GetPullRequestFiles(ctx context.Context, prID int) ([]string, error)
```

##### Manager.GetPullRequestStatus

GetPullRequestStatus returns the status of a pull request


```go
func (m *Manager) GetPullRequestStatus(ctx context.Context, prID int) (*interfaces.PullRequestInfo, error)
```

##### Manager.Health

Health checks the health of the PR manager


```go
func (m *Manager) Health() error
```

##### Manager.ListPullRequests

ListPullRequests returns a list of pull requests filtered by status


```go
func (m *Manager) ListPullRequests(ctx context.Context, status string) ([]*interfaces.PullRequestInfo, error)
```

##### Manager.MergePullRequest

MergePullRequest merges a pull request


```go
func (m *Manager) MergePullRequest(ctx context.Context, prID int, commitMessage string, mergeMethod string) error
```

##### Manager.SetRepository

SetRepository sets the GitHub repository for operations


```go
func (m *Manager) SetRepository(owner, repo string)
```

##### Manager.Shutdown

Shutdown gracefully shuts down the PR manager


```go
func (m *Manager) Shutdown(ctx context.Context) error
```

##### Manager.UpdatePullRequest

UpdatePullRequest updates an existing pull request


```go
func (m *Manager) UpdatePullRequest(ctx context.Context, prID int, title, description string) (*interfaces.PullRequestInfo, error)
```

