package interfaces

import (
	"context"
	"time"
)

// CommitInfo represents information about a Git commit
type CommitInfo struct {
	Hash      string
	Message   string
	Author    string
	Timestamp time.Time
	Branch    string
}

// SubBranchInfo represents information about a sub-branch
type SubBranchInfo struct {
	Name         string
	ParentBranch string
	CreatedAt    time.Time
	LastCommit   string
	Status       string // "active", "merged", "abandoned"
}

// PullRequestInfo represents information about a pull request
type PullRequestInfo struct {
	ID           int
	Title        string
	Description  string
	SourceBranch string
	TargetBranch string
	Status       string // "open", "closed", "merged"
	CreatedAt    time.Time
	UpdatedAt    time.Time
}

// WebhookPayload represents the payload sent to webhooks
type WebhookPayload struct {
	Event     string                 `json:"event"`
	Timestamp time.Time              `json:"timestamp"`
	Data      map[string]interface{} `json:"data"`
	Metadata  map[string]string      `json:"metadata"`
}

// WorkflowType represents different types of Git workflows
type WorkflowType string

const (
	WorkflowTypeGitFlow       WorkflowType = "gitflow"
	WorkflowTypeGitHubFlow    WorkflowType = "githubflow"
	WorkflowTypeFeatureBranch WorkflowType = "feature-branch"
	WorkflowTypeCustom        WorkflowType = "custom"
)

// GitWorkflowManager defines the interface for Git workflow management operations
type GitWorkflowManager interface {
	BaseManager

	// Branch Management
	CreateBranch(ctx context.Context, branchName string, sourceBranch string) error
	SwitchBranch(ctx context.Context, branchName string) error
	DeleteBranch(ctx context.Context, branchName string, force bool) error
	ListBranches(ctx context.Context) ([]string, error)
	GetCurrentBranch(ctx context.Context) (string, error)

	// Commit Management
	ValidateCommitMessage(message string) error
	CreateTimestampedCommit(ctx context.Context, message string, files []string) (*CommitInfo, error)
	GetCommitHistory(ctx context.Context, branch string, limit int) ([]*CommitInfo, error)
	GetLastCommit(ctx context.Context, branch string) (*CommitInfo, error)

	// Sub-branch Management
	CreateSubBranch(ctx context.Context, subBranchName string, parentBranch string, workflowType WorkflowType) (*SubBranchInfo, error)
	MergeSubBranch(ctx context.Context, subBranchName string, targetBranch string, deleteAfterMerge bool) error
	ListSubBranches(ctx context.Context, parentBranch string) ([]*SubBranchInfo, error)

	// Pull Request Management
	CreatePullRequest(ctx context.Context, title, description, sourceBranch, targetBranch string) (*PullRequestInfo, error)
	GetPullRequestStatus(ctx context.Context, prID int) (*PullRequestInfo, error)
	ListPullRequests(ctx context.Context, status string) ([]*PullRequestInfo, error)

	// Webhook Integration
	SendWebhook(ctx context.Context, event string, payload *WebhookPayload) error
	ConfigureWebhook(ctx context.Context, url string, events []string, secret string) error
	ListWebhooks(ctx context.Context) ([]map[string]interface{}, error)

	// Workflow Operations
	ExecuteWorkflow(ctx context.Context, workflowType WorkflowType, parameters map[string]interface{}) error
	ValidateWorkflow(ctx context.Context, workflowType WorkflowType) error
	GetWorkflowStatus(ctx context.Context) (map[string]interface{}, error)

	// Configuration Management
	SetWorkflowConfiguration(ctx context.Context, config map[string]interface{}) error
	GetWorkflowConfiguration(ctx context.Context) (map[string]interface{}, error)
	ResetWorkflowConfiguration(ctx context.Context) error
}

// GitWorkflowManagerFactory defines the factory interface for creating GitWorkflowManager instances
type GitWorkflowManagerFactory interface {
	CreateGitWorkflowManager(ctx context.Context, config map[string]interface{}) (GitWorkflowManager, error)
	ValidateConfiguration(config map[string]interface{}) error
	GetDefaultConfiguration() map[string]interface{}
}
