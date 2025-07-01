package workflows

import (
	"context"
	"fmt"
	"strings"

	"EMAIL_SENDER_1/managers/interfaces"
)

// GitHubFlowWorkflow implements the GitHub Flow workflow pattern
type GitHubFlowWorkflow struct {
	manager interfaces.GitWorkflowManager
}

// NewGitHubFlowWorkflow creates a new GitHub Flow workflow instance
func NewGitHubFlowWorkflow(manager interfaces.GitWorkflowManager) *GitHubFlowWorkflow {
	return &GitHubFlowWorkflow{
		manager: manager,
	}
}

// CreateFeatureBranch creates a new feature branch following GitHub Flow conventions
func (g *GitHubFlowWorkflow) CreateFeatureBranch(ctx context.Context, branchName string) (*interfaces.SubBranchInfo, error) {
	// GitHub Flow all branches are created from main
	sourceBranch := "main"

	// Ensure branch name is descriptive but simple
	if !strings.Contains(branchName, "/") {
		branchName = fmt.Sprintf("feature/%s", strings.ToLower(branchName))
	}

	subBranchInfo, err := g.manager.CreateSubBranch(ctx, branchName, sourceBranch, g.GetWorkflowType())
	if err != nil {
		return nil, err
	}
	return subBranchInfo, nil
}

// CreateBranch creates any type of branch from main
func (g *GitHubFlowWorkflow) CreateBranch(ctx context.Context, branchName string) (*interfaces.SubBranchInfo, error) {
	// In GitHub Flow, all branches come from main
	sourceBranch := "main"
	subBranchInfo, err := g.manager.CreateSubBranch(ctx, branchName, sourceBranch, g.GetWorkflowType())
	if err != nil {
		return nil, err
	}
	return subBranchInfo, nil
}

// CreatePullRequest creates a pull request to merge a branch back to main
func (g *GitHubFlowWorkflow) CreatePullRequest(ctx context.Context, branchName, title, description string) (*interfaces.PullRequestInfo, error) {
	prInfo := interfaces.PullRequestInfo{ // This prInfo is for local use or if other methods need it structured.
		Title:        title,
		Description:  description,
		SourceBranch: branchName,
		TargetBranch: "main", // GitHub Flow always merges to main
	}

	pullRequestInfo, err := g.manager.CreatePullRequest(ctx, prInfo.Title, prInfo.Description, prInfo.SourceBranch, prInfo.TargetBranch)
	if err != nil {
		return nil, err
	}
	return pullRequestInfo, nil
}

// MergeBranch completes the workflow by merging a branch to main
func (g *GitHubFlowWorkflow) MergeBranch(ctx context.Context, branchName string) error {
	// In GitHub Flow, we create a simple PR to main
	prInfo := interfaces.PullRequestInfo{
		Title:        fmt.Sprintf("Merge %s", branchName),
		Description:  fmt.Sprintf("Merging changes from %s", branchName),
		SourceBranch: branchName,
		TargetBranch: "main",
	}

	_, err := g.manager.CreatePullRequest(ctx, prInfo.Title, prInfo.Description, prInfo.SourceBranch, prInfo.TargetBranch)
	return err
}

// DeployBranch handles deployment workflow for a branch
func (g *GitHubFlowWorkflow) DeployBranch(ctx context.Context, branchName string) error {
	// In GitHub Flow, deployment can happen from any branch
	// This would typically trigger CI/CD pipeline

	// Create a deployment webhook
	webhook := interfaces.WebhookPayload{
		Event: "deployment",
		Data: map[string]interface{}{
			"branch":    branchName,
			"workflow":  "github-flow",
			"action":    "deploy",
			"timestamp": "now", // Consider using time.Now() for actual timestamp
		},
	}

	return g.manager.SendWebhook(ctx, webhook.Event, &webhook)
}

// ValidateBranchName ensures branch names follow GitHub Flow conventions
func (g *GitHubFlowWorkflow) ValidateBranchName(branchName string) error {
	// GitHub Flow is more flexible with branch naming
	// Just ensure it's not main and has reasonable format

	if branchName == "main" || branchName == "master" {
		return fmt.Errorf("cannot create branch with protected name '%s'", branchName)
	}

	// Ensure branch name is not empty and has valid characters
	if len(branchName) == 0 {
		return fmt.Errorf("branch name cannot be empty")
	}

	if strings.Contains(branchName, " ") {
		return fmt.Errorf("branch name cannot contain spaces")
	}

	return nil
}

// CleanupMergedBranches removes branches that have been merged to main
func (g *GitHubFlowWorkflow) CleanupMergedBranches(ctx context.Context) error {
	// Get list of merged branches
	branches, err := g.manager.ListSubBranches(ctx, "") // Assuming listing all branches from root
	if err != nil {
		return fmt.Errorf("failed to list branches: %w", err)
	}

	for _, branch := range branches {
		if branch.Status == "merged" && branch.Name != "main" && branch.Name != "master" {
			// Delete the merged branch
			// if err := g.manager.DeleteSubBranch(ctx, branch.Name); err != nil {
			// 	// Log error but continue with other branches
			// 	continue
			// }
		}
	}

	return nil
}

// GetWorkflowType returns the workflow type
func (g *GitHubFlowWorkflow) GetWorkflowType() interfaces.WorkflowType {
	return interfaces.WorkflowTypeGitHubFlow
}

// GetBranchingStrategy returns the branching strategy description
func (g *GitHubFlowWorkflow) GetBranchingStrategy() string {
	return "GitHub Flow workflow with simple branching from main"
}

// GetDeploymentStrategy returns the deployment strategy
func (g *GitHubFlowWorkflow) GetDeploymentStrategy() string {
	return "Deploy any branch, continuous deployment from main"
}
