package workflows

import (
	"context"
	"fmt"
	"strings"

	"github.com/email-sender/managers/interfaces"
)

// GitFlowWorkflow implements the GitFlow workflow pattern
type GitFlowWorkflow struct {
	manager interfaces.GitWorkflowManager
}

// NewGitFlowWorkflow creates a new GitFlow workflow instance
func NewGitFlowWorkflow(manager interfaces.GitWorkflowManager) *GitFlowWorkflow {
	return &GitFlowWorkflow{
		manager: manager,
	}
}

// CreateFeatureBranch creates a new feature branch following GitFlow conventions
func (g *GitFlowWorkflow) CreateFeatureBranch(ctx context.Context, featureName string) error {
	// GitFlow feature branches are created from develop
	sourceBranch := "develop"
	branchName := fmt.Sprintf("feature/%s", strings.ToLower(featureName))
	
	return g.manager.CreateSubBranch(ctx, branchName, sourceBranch)
}

// CreateReleaseBranch creates a new release branch following GitFlow conventions
func (g *GitFlowWorkflow) CreateReleaseBranch(ctx context.Context, version string) error {
	// GitFlow release branches are created from develop
	sourceBranch := "develop"
	branchName := fmt.Sprintf("release/%s", version)
	
	return g.manager.CreateSubBranch(ctx, branchName, sourceBranch)
}

// CreateHotfixBranch creates a new hotfix branch following GitFlow conventions
func (g *GitFlowWorkflow) CreateHotfixBranch(ctx context.Context, hotfixName string) error {
	// GitFlow hotfix branches are created from main/master
	sourceBranch := "main"
	branchName := fmt.Sprintf("hotfix/%s", strings.ToLower(hotfixName))
	
	return g.manager.CreateSubBranch(ctx, branchName, sourceBranch)
}

// FinishFeature completes a feature by merging it back to develop
func (g *GitFlowWorkflow) FinishFeature(ctx context.Context, featureName string) error {
	branchName := fmt.Sprintf("feature/%s", strings.ToLower(featureName))
	targetBranch := "develop"
	
	// Create pull request for the feature
	prInfo := interfaces.PullRequestInfo{
		Title:        fmt.Sprintf("Feature: %s", featureName),
		Description:  fmt.Sprintf("Completing feature branch %s", branchName),
		SourceBranch: branchName,
		TargetBranch: targetBranch,
		Labels:       []string{"feature", "gitflow"},
	}
	
	_, err := g.manager.CreatePullRequest(ctx, prInfo)
	return err
}

// FinishRelease completes a release by merging to main and develop
func (g *GitFlowWorkflow) FinishRelease(ctx context.Context, version string) error {
	branchName := fmt.Sprintf("release/%s", version)
	
	// First merge to main
	prInfoMain := interfaces.PullRequestInfo{
		Title:        fmt.Sprintf("Release: %s", version),
		Description:  fmt.Sprintf("Completing release %s", version),
		SourceBranch: branchName,
		TargetBranch: "main",
		Labels:       []string{"release", "gitflow"},
	}
	
	_, err := g.manager.CreatePullRequest(ctx, prInfoMain)
	if err != nil {
		return fmt.Errorf("failed to create PR to main: %w", err)
	}
	
	// Then merge back to develop
	prInfoDevelop := interfaces.PullRequestInfo{
		Title:        fmt.Sprintf("Merge release %s back to develop", version),
		Description:  fmt.Sprintf("Merging release %s changes back to develop", version),
		SourceBranch: branchName,
		TargetBranch: "develop",
		Labels:       []string{"release", "gitflow", "backmerge"},
	}
	
	_, err = g.manager.CreatePullRequest(ctx, prInfoDevelop)
	return err
}

// FinishHotfix completes a hotfix by merging to main and develop
func (g *GitFlowWorkflow) FinishHotfix(ctx context.Context, hotfixName string) error {
	branchName := fmt.Sprintf("hotfix/%s", strings.ToLower(hotfixName))
	
	// First merge to main
	prInfoMain := interfaces.PullRequestInfo{
		Title:        fmt.Sprintf("Hotfix: %s", hotfixName),
		Description:  fmt.Sprintf("Emergency hotfix: %s", hotfixName),
		SourceBranch: branchName,
		TargetBranch: "main",
		Labels:       []string{"hotfix", "gitflow", "urgent"},
	}
	
	_, err := g.manager.CreatePullRequest(ctx, prInfoMain)
	if err != nil {
		return fmt.Errorf("failed to create hotfix PR to main: %w", err)
	}
	
	// Then merge back to develop
	prInfoDevelop := interfaces.PullRequestInfo{
		Title:        fmt.Sprintf("Merge hotfix %s to develop", hotfixName),
		Description:  fmt.Sprintf("Merging hotfix %s changes to develop", hotfixName),
		SourceBranch: branchName,
		TargetBranch: "develop",
		Labels:       []string{"hotfix", "gitflow", "backmerge"},
	}
	
	_, err = g.manager.CreatePullRequest(ctx, prInfoDevelop)
	return err
}

// ValidateBranchName ensures branch names follow GitFlow conventions
func (g *GitFlowWorkflow) ValidateBranchName(branchName string) error {
	validPrefixes := []string{"feature/", "release/", "hotfix/", "bugfix/"}
	
	for _, prefix := range validPrefixes {
		if strings.HasPrefix(branchName, prefix) {
			return nil
		}
	}
	
	// Allow main, develop, and master branches
	if branchName == "main" || branchName == "develop" || branchName == "master" {
		return nil
	}
	
	return fmt.Errorf("branch name '%s' does not follow GitFlow conventions", branchName)
}

// GetWorkflowType returns the workflow type
func (g *GitFlowWorkflow) GetWorkflowType() interfaces.WorkflowType {
	return interfaces.GitFlowWorkflow
}

// GetBranchingStrategy returns the branching strategy description
func (g *GitFlowWorkflow) GetBranchingStrategy() string {
	return "GitFlow workflow with feature, release, and hotfix branches"
}
