# Package workflows

## Types

### CustomWorkflow

CustomWorkflow implements a user-defined custom workflow


#### Methods

##### CustomWorkflow.AddProtectedBranch

AddProtectedBranch adds a branch to the protected list


```go
func (c *CustomWorkflow) AddProtectedBranch(branchName string)
```

##### CustomWorkflow.CreateBranch

CreateBranch creates a branch following custom rules


```go
func (c *CustomWorkflow) CreateBranch(ctx context.Context, branchName, sourceBranch string) (*interfaces.SubBranchInfo, error)
```

##### CustomWorkflow.CreatePullRequest

CreatePullRequest creates a pull request following custom merge rules


```go
func (c *CustomWorkflow) CreatePullRequest(ctx context.Context, sourceBranch, targetBranch, title, description string) (*interfaces.PullRequestInfo, error)
```

##### CustomWorkflow.ExecuteCustomAction

ExecuteCustomAction executes a custom workflow action


```go
func (c *CustomWorkflow) ExecuteCustomAction(ctx context.Context, action string, params map[string]interface{}) error
```

##### CustomWorkflow.GetBranchPatterns

GetBranchPatterns returns the configured branch patterns


```go
func (c *CustomWorkflow) GetBranchPatterns() map[string]string
```

##### CustomWorkflow.GetBranchingStrategy

GetBranchingStrategy returns the branching strategy description


```go
func (c *CustomWorkflow) GetBranchingStrategy() string
```

##### CustomWorkflow.GetMergeRules

GetMergeRules returns the configured merge rules


```go
func (c *CustomWorkflow) GetMergeRules() map[string][]string
```

##### CustomWorkflow.GetWorkflowType

GetWorkflowType returns the workflow type


```go
func (c *CustomWorkflow) GetWorkflowType() interfaces.WorkflowType
```

##### CustomWorkflow.RemoveProtectedBranch

RemoveProtectedBranch removes a branch from the protected list


```go
func (c *CustomWorkflow) RemoveProtectedBranch(branchName string)
```

##### CustomWorkflow.SetBranchPattern

SetBranchPattern adds or updates a branch pattern


```go
func (c *CustomWorkflow) SetBranchPattern(name, pattern string) error
```

##### CustomWorkflow.SetMergeRule

SetMergeRule adds or updates a merge rule


```go
func (c *CustomWorkflow) SetMergeRule(sourceBranch string, targetBranches []string)
```

##### CustomWorkflow.ValidateBranchName

ValidateBranchName validates branch name against custom patterns


```go
func (c *CustomWorkflow) ValidateBranchName(branchName string) error
```

### FeatureBranchWorkflow

FeatureBranchWorkflow implements a simple feature branch workflow


#### Methods

##### FeatureBranchWorkflow.ArchiveBranch

ArchiveBranch archives an old or completed branch


```go
func (f *FeatureBranchWorkflow) ArchiveBranch(ctx context.Context, branchName string) error
```

##### FeatureBranchWorkflow.CleanupStaleBranches

CleanupStaleBranches removes branches that haven't been updated recently


```go
func (f *FeatureBranchWorkflow) CleanupStaleBranches(ctx context.Context) error
```

##### FeatureBranchWorkflow.CreateBugfixBranch

CreateBugfixBranch creates a new bugfix branch


```go
func (f *FeatureBranchWorkflow) CreateBugfixBranch(ctx context.Context, bugName string) (*interfaces.SubBranchInfo, error)
```

##### FeatureBranchWorkflow.CreateExperimentBranch

CreateExperimentBranch creates a branch for experimentation


```go
func (f *FeatureBranchWorkflow) CreateExperimentBranch(ctx context.Context, experimentName string) (*interfaces.SubBranchInfo, error)
```

##### FeatureBranchWorkflow.CreateFeatureBranch

CreateFeatureBranch creates a new feature branch


```go
func (f *FeatureBranchWorkflow) CreateFeatureBranch(ctx context.Context, featureName string) (*interfaces.SubBranchInfo, error)
```

##### FeatureBranchWorkflow.CreateTaskBranch

CreateTaskBranch creates a branch for a specific task


```go
func (f *FeatureBranchWorkflow) CreateTaskBranch(ctx context.Context, taskID, description string) (*interfaces.SubBranchInfo, error)
```

##### FeatureBranchWorkflow.GetBranchHistory

GetBranchHistory returns the commit history for a feature branch


```go
func (f *FeatureBranchWorkflow) GetBranchHistory(ctx context.Context, branchName string) ([]*interfaces.CommitInfo, error)
```

##### FeatureBranchWorkflow.GetBranchingStrategy

GetBranchingStrategy returns the branching strategy description


```go
func (f *FeatureBranchWorkflow) GetBranchingStrategy() string
```

##### FeatureBranchWorkflow.GetWorkflowType

GetWorkflowType returns the workflow type


```go
func (f *FeatureBranchWorkflow) GetWorkflowType() interfaces.WorkflowType
```

##### FeatureBranchWorkflow.MergeFeature

MergeFeature creates a pull request to merge a feature branch


```go
func (f *FeatureBranchWorkflow) MergeFeature(ctx context.Context, branchName, title, description string) (*interfaces.PullRequestInfo, error)
```

##### FeatureBranchWorkflow.RebaseBranch

RebaseBranch rebases a feature branch onto the main branch


```go
func (f *FeatureBranchWorkflow) RebaseBranch(ctx context.Context, branchName string) error
```

##### FeatureBranchWorkflow.SetCleanupPolicy

SetCleanupPolicy configures automatic cleanup of old branches


```go
func (f *FeatureBranchWorkflow) SetCleanupPolicy(enabled bool, days int)
```

##### FeatureBranchWorkflow.ValidateBranchName

ValidateBranchName ensures branch names follow feature branch conventions


```go
func (f *FeatureBranchWorkflow) ValidateBranchName(branchName string) error
```

### GitFlowWorkflow

GitFlowWorkflow implements the GitFlow workflow pattern


#### Methods

##### GitFlowWorkflow.CreateFeatureBranch

CreateFeatureBranch creates a new feature branch following GitFlow conventions


```go
func (g *GitFlowWorkflow) CreateFeatureBranch(ctx context.Context, featureName string) (*interfaces.SubBranchInfo, error)
```

##### GitFlowWorkflow.CreateHotfixBranch

CreateHotfixBranch creates a new hotfix branch following GitFlow conventions


```go
func (g *GitFlowWorkflow) CreateHotfixBranch(ctx context.Context, hotfixName string) (*interfaces.SubBranchInfo, error)
```

##### GitFlowWorkflow.CreateReleaseBranch

CreateReleaseBranch creates a new release branch following GitFlow conventions


```go
func (g *GitFlowWorkflow) CreateReleaseBranch(ctx context.Context, version string) (*interfaces.SubBranchInfo, error)
```

##### GitFlowWorkflow.FinishFeature

FinishFeature completes a feature by merging it back to develop


```go
func (g *GitFlowWorkflow) FinishFeature(ctx context.Context, featureName string) error
```

##### GitFlowWorkflow.FinishHotfix

FinishHotfix completes a hotfix by merging to main and develop


```go
func (g *GitFlowWorkflow) FinishHotfix(ctx context.Context, hotfixName string) error
```

##### GitFlowWorkflow.FinishRelease

FinishRelease completes a release by merging to main and develop


```go
func (g *GitFlowWorkflow) FinishRelease(ctx context.Context, version string) error
```

##### GitFlowWorkflow.GetBranchingStrategy

GetBranchingStrategy returns the branching strategy description


```go
func (g *GitFlowWorkflow) GetBranchingStrategy() string
```

##### GitFlowWorkflow.GetWorkflowType

GetWorkflowType returns the workflow type


```go
func (g *GitFlowWorkflow) GetWorkflowType() interfaces.WorkflowType
```

##### GitFlowWorkflow.ValidateBranchName

ValidateBranchName ensures branch names follow GitFlow conventions


```go
func (g *GitFlowWorkflow) ValidateBranchName(branchName string) error
```

### GitHubFlowWorkflow

GitHubFlowWorkflow implements the GitHub Flow workflow pattern


#### Methods

##### GitHubFlowWorkflow.CleanupMergedBranches

CleanupMergedBranches removes branches that have been merged to main


```go
func (g *GitHubFlowWorkflow) CleanupMergedBranches(ctx context.Context) error
```

##### GitHubFlowWorkflow.CreateBranch

CreateBranch creates any type of branch from main


```go
func (g *GitHubFlowWorkflow) CreateBranch(ctx context.Context, branchName string) (*interfaces.SubBranchInfo, error)
```

##### GitHubFlowWorkflow.CreateFeatureBranch

CreateFeatureBranch creates a new feature branch following GitHub Flow conventions


```go
func (g *GitHubFlowWorkflow) CreateFeatureBranch(ctx context.Context, branchName string) (*interfaces.SubBranchInfo, error)
```

##### GitHubFlowWorkflow.CreatePullRequest

CreatePullRequest creates a pull request to merge a branch back to main


```go
func (g *GitHubFlowWorkflow) CreatePullRequest(ctx context.Context, branchName, title, description string) (*interfaces.PullRequestInfo, error)
```

##### GitHubFlowWorkflow.DeployBranch

DeployBranch handles deployment workflow for a branch


```go
func (g *GitHubFlowWorkflow) DeployBranch(ctx context.Context, branchName string) error
```

##### GitHubFlowWorkflow.GetBranchingStrategy

GetBranchingStrategy returns the branching strategy description


```go
func (g *GitHubFlowWorkflow) GetBranchingStrategy() string
```

##### GitHubFlowWorkflow.GetDeploymentStrategy

GetDeploymentStrategy returns the deployment strategy


```go
func (g *GitHubFlowWorkflow) GetDeploymentStrategy() string
```

##### GitHubFlowWorkflow.GetWorkflowType

GetWorkflowType returns the workflow type


```go
func (g *GitHubFlowWorkflow) GetWorkflowType() interfaces.WorkflowType
```

##### GitHubFlowWorkflow.MergeBranch

MergeBranch completes the workflow by merging a branch to main


```go
func (g *GitHubFlowWorkflow) MergeBranch(ctx context.Context, branchName string) error
```

##### GitHubFlowWorkflow.ValidateBranchName

ValidateBranchName ensures branch names follow GitHub Flow conventions


```go
func (g *GitHubFlowWorkflow) ValidateBranchName(branchName string) error
```

### Workflow

Workflow interface defines common operations for all workflow types


### WorkflowFactory

WorkflowFactory creates workflow instances based on workflow type


#### Methods

##### WorkflowFactory.CreateWorkflow

CreateWorkflow creates a workflow instance based on the specified type


```go
func (f *WorkflowFactory) CreateWorkflow(workflowType interfaces.WorkflowType, config map[string]interface{}) (Workflow, error)
```

##### WorkflowFactory.GetAvailableWorkflows

GetAvailableWorkflows returns a list of available workflow types


```go
func (f *WorkflowFactory) GetAvailableWorkflows() []interfaces.WorkflowType
```

##### WorkflowFactory.GetWorkflowDescription

GetWorkflowDescription returns a description of the specified workflow type


```go
func (f *WorkflowFactory) GetWorkflowDescription(workflowType interfaces.WorkflowType) string
```

