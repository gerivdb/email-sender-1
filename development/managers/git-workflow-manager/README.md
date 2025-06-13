# GitWorkflowManager Documentation

## Overview

The GitWorkflowManager is a comprehensive solution for managing Git workflows in software development projects. It provides a unified interface for different workflow patterns including GitFlow, GitHub Flow, Feature Branch workflow, and custom workflows.

## Features

- **Multiple Workflow Support**: GitFlow, GitHub Flow, Feature Branch, and Custom workflows
- **Branch Management**: Create, validate, merge, and delete branches with workflow-specific conventions
- **Commit Validation**: Conventional commit support with customizable rules
- **Pull Request Integration**: GitHub API integration for automated PR management
- **Webhook Support**: HTTP webhook delivery with retry logic and signature verification
- **Configuration Management**: YAML-based configuration with validation
- **Error Handling**: Comprehensive error handling and logging
- **Testing**: Complete test suite with mocks and integration tests

## Architecture

```plaintext
GitWorkflowManager
├── Internal Managers
│   ├── BranchManager - Git branch operations
│   ├── CommitManager - Commit validation and creation
│   ├── PRManager - GitHub Pull Request integration
│   └── WebhookManager - HTTP webhook delivery
├── Workflows
│   ├── GitFlowWorkflow - GitFlow pattern implementation
│   ├── GitHubFlowWorkflow - GitHub Flow pattern implementation
│   ├── FeatureBranchWorkflow - Feature branch pattern implementation
│   └── CustomWorkflow - User-defined workflow patterns
├── Configuration - YAML-based configuration management
└── Tests - Comprehensive test suite
```plaintext
## Installation

1. Add the module to your project:
```bash
go mod init your-project
go get github.com/email-sender/git-workflow-manager
```plaintext
2. Install dependencies:
```bash
go mod tidy
```plaintext
## Quick Start

### Basic Usage

```go
package main

import (
    "context"
    "log"
    
    "github.com/email-sender/git-workflow-manager"
    "github.com/email-sender/managers/interfaces"
)

func main() {
    // Create dependencies (implement these based on your system)
    errorManager := &YourErrorManager{}
    configManager := &YourConfigManager{}
    storageManager := &YourStorageManager{}
    
    // Configuration
    config := map[string]interface{}{
        "repository_path": "/path/to/your/repo",
        "workflow_type":   "gitflow",
        "github_token":    "your-github-token",
    }
    
    // Create GitWorkflowManager
    manager := main.NewGitWorkflowManager(
        errorManager,
        configManager,
        storageManager,
        config,
    )
    
    ctx := context.Background()
    
    // Create a feature branch
    err := manager.CreateSubBranch(ctx, "feature/new-feature", "develop")
    if err != nil {
        log.Fatalf("Failed to create branch: %v", err)
    }
    
    // Make a commit
    commitInfo := interfaces.CommitInfo{
        Message: "feat: add new feature implementation",
        Author:  "developer@example.com",
        Branch:  "feature/new-feature",
    }
    
    err = manager.CommitChanges(ctx, commitInfo)
    if err != nil {
        log.Fatalf("Failed to commit: %v", err)
    }
    
    // Create pull request
    prInfo := interfaces.PullRequestInfo{
        Title:        "Add new feature",
        Description:  "Implementation of the new feature",
        SourceBranch: "feature/new-feature",
        TargetBranch: "develop",
        Labels:       []string{"feature", "enhancement"},
    }
    
    prID, err := manager.CreatePullRequest(ctx, prInfo)
    if err != nil {
        log.Fatalf("Failed to create PR: %v", err)
    }
    
    log.Printf("Created pull request: %d", prID)
}
```plaintext
## Workflows

### GitFlow Workflow

GitFlow is a branching model that uses two main branches (`main` and `develop`) and supporting branches for features, releases, and hotfixes.

```go
import "github.com/email-sender/git-workflow-manager/workflows"

// Create GitFlow workflow
factory := workflows.NewWorkflowFactory(manager)
gitflow, err := factory.CreateWorkflow(interfaces.GitFlowWorkflow, config)

// Create feature branch
err = gitflow.CreateFeatureBranch(ctx, "user-authentication")

// Finish feature (creates PR to develop)
err = gitflow.FinishFeature(ctx, "user-authentication")
```plaintext
**Branch Conventions:**
- `feature/*` - Feature branches from `develop`
- `release/*` - Release branches from `develop`
- `hotfix/*` - Hotfix branches from `main`

### GitHub Flow Workflow

GitHub Flow is a simple workflow where all development happens in feature branches created from `main`.

```go
// Create GitHub Flow workflow
githubFlow, err := factory.CreateWorkflow(interfaces.GitHubFlowWorkflow, config)

// Create feature branch
err = githubFlow.CreateBranch(ctx, "add-user-profile")

// Create pull request to main
prID, err := githubFlow.CreatePullRequest(ctx, "add-user-profile", "Add user profile", "Implementation of user profile feature")

// Deploy branch (triggers webhooks)
err = githubFlow.DeployBranch(ctx, "add-user-profile")
```plaintext
### Feature Branch Workflow

A flexible workflow that allows various branch types with automated cleanup.

```go
// Create Feature Branch workflow
featureBranch, err := factory.CreateWorkflow(interfaces.FeatureBranchWorkflow, map[string]interface{}{
    "main_branch":   "main",
    "auto_cleanup":  true,
    "cleanup_days":  30,
})

// Create different types of branches
err = featureBranch.CreateFeatureBranch(ctx, "payment-integration")
err = featureBranch.CreateBugfixBranch(ctx, "login-error")
err = featureBranch.CreateTaskBranch(ctx, "TASK-123", "update documentation")

// Cleanup stale branches
err = featureBranch.CleanupStaleBranches(ctx)
```plaintext
### Custom Workflow

Define your own workflow patterns with custom rules and conventions.

```go
// Custom workflow configuration
customConfig := map[string]interface{}{
    "branch_patterns": map[string]interface{}{
        "feature": `^feature/[A-Z]+-\d+-.+$`,
        "bugfix":  `^bugfix/[A-Z]+-\d+-.+$`,
        "hotfix":  `^hotfix/v\d+\.\d+\.\d+-.+$`,
    },
    "merge_rules": map[string]interface{}{
        "feature/*": []string{"develop", "staging"},
        "bugfix/*":  []string{"develop", "staging"},
        "hotfix/*":  []string{"main", "develop"},
    },
    "protected_branches": []string{"main", "develop", "staging"},
}

// Create custom workflow
customWorkflow, err := factory.CreateWorkflow(interfaces.CustomWorkflow, customConfig)

// Add custom patterns
err = customWorkflow.SetBranchPattern("epic", `^epic/[A-Z]+-\d+-.+$`)
customWorkflow.SetMergeRule("epic/*", []string{"develop"})
```plaintext
## Configuration

### YAML Configuration

Create a `config/config.yaml` file:

```yaml
repository:
  path: "."
  remote: "origin"
  owner: "your-organization"
  name: "your-repository"

workflow:
  type: "gitflow" # gitflow, githubflow, feature-branch, custom

  default_branch: "main"
  protected_branches:
    - "main"
    - "develop"
  branch_naming:
    feature: "feature/{name}"
    hotfix: "hotfix/{name}"
    release: "release/{version}"
    bugfix: "bugfix/{name}"

commit_rules:
  conventional_commits: true
  required_format: "^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\\(.+\\))?: .{1,50}"
  max_length: 72
  min_length: 10
  allowed_types:
    - "feat"
    - "fix"
    - "docs"
    - "style"
    - "refactor"
    - "test"
    - "chore"
    - "perf"
    - "ci"
    - "build"
    - "revert"

github:
  token: "your-github-token"
  organization: "your-organization"
  repository: "your-repository"
  api_endpoint: "https://api.github.com"

webhooks:
  enabled: true
  endpoints:
    - name: "slack-notifications"
      url: "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
      events: ["push", "pull_request", "branch_created"]
      secret: "your-webhook-secret"
  timeout: 30
  retries: 3

automation:
  auto_merge:
    enabled: false
    required_checks: []
    required_reviews: 1
  
  branch_cleanup:
    enabled: true
    days_after_merge: 7
    exclude_branches:
      - "main"
      - "develop"

logging:
  level: "info"
  format: "json"
  output: "stdout"
```plaintext
### Programmatic Configuration

```go
config := map[string]interface{}{
    "repository_path": "/path/to/repo",
    "workflow_type":   "gitflow",
    "github_token":    "token",
    "webhook_config": map[string]interface{}{
        "enabled": true,
        "timeout": 30,
        "endpoints": []map[string]interface{}{
            {
                "name": "slack",
                "url":  "https://hooks.slack.com/...",
                "events": []string{"push", "pull_request"},
            },
        },
    },
}
```plaintext
## API Reference

### GitWorkflowManager Interface

```go
type GitWorkflowManager interface {
    // BaseManager methods
    GetID() string
    GetName() string
    GetStatus() string
    GetConfig() map[string]interface{}
    UpdateConfig(config map[string]interface{}) error
    GetMetadata() map[string]interface{}
    SetMetadata(key string, value interface{}) error
    Health() error
    Shutdown(ctx context.Context) error

    // Branch operations
    CreateSubBranch(ctx context.Context, branchName, sourceBranch string) error
    DeleteSubBranch(ctx context.Context, branchName string) error
    ListSubBranches(ctx context.Context) ([]SubBranchInfo, error)
    SwitchBranch(ctx context.Context, branchName string) error
    MergeBranch(ctx context.Context, sourceBranch, targetBranch string) error
    ValidateBranchName(branchName string) error

    // Commit operations
    CommitChanges(ctx context.Context, commitInfo CommitInfo) error
    GetCommitHistory(ctx context.Context, branchName string, limit int) ([]CommitInfo, error)
    ValidateCommitMessage(message string) error
    CreateTag(ctx context.Context, tagName, message string) error

    // Pull Request operations
    CreatePullRequest(ctx context.Context, prInfo PullRequestInfo) (int, error)
    UpdatePullRequest(ctx context.Context, prID int, updates PullRequestInfo) error
    MergePullRequest(ctx context.Context, prID int) error
    ListPullRequests(ctx context.Context, state string) ([]PullRequestInfo, error)

    // Webhook operations
    SendWebhook(ctx context.Context, payload WebhookPayload) error
    RegisterWebhook(ctx context.Context, endpoint WebhookEndpoint) error

    // Workflow operations
    GetWorkflowType() WorkflowType
    SetWorkflowType(workflowType WorkflowType) error
    ValidateWorkflow() error
    GetWorkflowStatus() (WorkflowStatus, error)
}
```plaintext
### Workflow Interface

```go
type Workflow interface {
    GetWorkflowType() WorkflowType
    GetBranchingStrategy() string
    ValidateBranchName(branchName string) error
}
```plaintext
## Testing

### Running Tests

```bash
# Run unit tests

go test ./...

# Run tests with coverage

go test -cover ./...

# Run integration tests

go test -tags=integration ./...

# Run benchmarks

go test -bench=. ./...
```plaintext
### Example Test

```go
func TestGitWorkflowManager(t *testing.T) {
    // Create mock dependencies
    errorManager := &MockErrorManager{}
    configManager := &MockConfigManager{}
    storageManager := &MockStorageManager{}

    config := map[string]interface{}{
        "repository_path": ".",
        "workflow_type":   "gitflow",
    }

    // Create manager
    manager := NewGitWorkflowManager(errorManager, configManager, storageManager, config)

    // Test health check
    if err := manager.Health(); err != nil {
        t.Errorf("Health check failed: %v", err)
    }

    // Test branch validation
    if err := manager.ValidateBranchName("feature/test"); err != nil {
        t.Errorf("Valid branch name failed validation: %v", err)
    }
}
```plaintext
## Error Handling

The GitWorkflowManager provides comprehensive error handling:

```go
import "github.com/email-sender/git-workflow-manager/errors"

// Custom error types
type WorkflowError struct {
    Type    string
    Message string
    Cause   error
}

// Error handling example
err := manager.CreateSubBranch(ctx, "invalid name", "main")
if err != nil {
    switch e := err.(type) {
    case *WorkflowError:
        log.Printf("Workflow error: %s - %s", e.Type, e.Message)
    default:
        log.Printf("Unknown error: %v", err)
    }
}
```plaintext
## Webhooks

### Configuration

```yaml
webhooks:
  enabled: true
  endpoints:
    - name: "slack-notifications"
      url: "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
      events: ["push", "pull_request", "branch_created"]
      secret: "your-webhook-secret"
      headers:
        "X-Custom-Header": "value"
  timeout: 30
  retries: 3
```plaintext
### Usage

```go
// Send webhook
webhook := interfaces.WebhookPayload{
    Event: "branch_created",
    Data: map[string]interface{}{
        "branch_name": "feature/new-feature",
        "created_by":  "developer@example.com",
        "repository":  "your-repo",
    },
}

err := manager.SendWebhook(ctx, webhook)
```plaintext
## Integration Examples

### CI/CD Integration

```go
// GitHub Actions integration
func handlePushEvent(ctx context.Context, manager interfaces.GitWorkflowManager, payload GitHubWebhook) {
    if payload.Ref == "refs/heads/main" {
        // Trigger deployment
        webhook := interfaces.WebhookPayload{
            Event: "deployment_trigger",
            Data: map[string]interface{}{
                "branch":     "main",
                "commit_sha": payload.After,
                "environment": "production",
            },
        }
        manager.SendWebhook(ctx, webhook)
    }
}
```plaintext
### Slack Integration

```go
// Slack notification webhook
func setupSlackWebhook(manager interfaces.GitWorkflowManager) {
    endpoint := interfaces.WebhookEndpoint{
        Name: "slack",
        URL:  "https://hooks.slack.com/services/...",
        Events: []string{"pull_request", "branch_created", "merge_completed"},
        Secret: "slack-webhook-secret",
    }
    
    manager.RegisterWebhook(context.Background(), endpoint)
}
```plaintext
## Best Practices

1. **Branch Naming**: Use consistent, descriptive branch names that follow your workflow conventions
2. **Commit Messages**: Follow conventional commit format for better changelog generation
3. **Pull Requests**: Include detailed descriptions and link to relevant issues
4. **Webhooks**: Use webhook secrets for security and implement retry logic
5. **Configuration**: Use YAML configuration files for complex setups
6. **Testing**: Write tests for custom workflows and validate branch operations
7. **Error Handling**: Implement comprehensive error handling and logging

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Ensure GitHub token has necessary permissions
2. **Branch Creation Failures**: Check branch naming conventions and source branch existence
3. **Webhook Delivery Failures**: Verify endpoint URLs and network connectivity
4. **Commit Validation Errors**: Review commit message format requirements

### Debug Mode

Enable debug logging:

```go
config["logging"] = map[string]interface{}{
    "level": "debug",
    "format": "text",
}
```plaintext
## Contributing

1. Fork the repository
2. Create a feature branch following the project's workflow
3. Make your changes with appropriate tests
4. Submit a pull request with detailed description

## License

This project is licensed under the MIT License - see the LICENSE file for details.
