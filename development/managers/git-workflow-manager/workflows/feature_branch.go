package workflows

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/email-sender/managers/interfaces"
)

// FeatureBranchWorkflow implements a simple feature branch workflow
type FeatureBranchWorkflow struct {
	manager      interfaces.GitWorkflowManager
	mainBranch   string
	autoCleanup  bool
	cleanupDays  int
}

// NewFeatureBranchWorkflow creates a new Feature Branch workflow instance
func NewFeatureBranchWorkflow(manager interfaces.GitWorkflowManager, mainBranch string) *FeatureBranchWorkflow {
	if mainBranch == "" {
		mainBranch = "main"
	}
	
	return &FeatureBranchWorkflow{
		manager:     manager,
		mainBranch:  mainBranch,
		autoCleanup: true,
		cleanupDays: 30,
	}
}

// SetCleanupPolicy configures automatic cleanup of old branches
func (f *FeatureBranchWorkflow) SetCleanupPolicy(enabled bool, days int) {
	f.autoCleanup = enabled
	f.cleanupDays = days
}

// CreateFeatureBranch creates a new feature branch
func (f *FeatureBranchWorkflow) CreateFeatureBranch(ctx context.Context, featureName string) error {
	branchName := f.formatBranchName(featureName)
	return f.manager.CreateSubBranch(ctx, branchName, f.mainBranch)
}

// CreateBugfixBranch creates a new bugfix branch
func (f *FeatureBranchWorkflow) CreateBugfixBranch(ctx context.Context, bugName string) error {
	branchName := fmt.Sprintf("bugfix/%s", strings.ToLower(bugName))
	return f.manager.CreateSubBranch(ctx, branchName, f.mainBranch)
}

// CreateTaskBranch creates a branch for a specific task
func (f *FeatureBranchWorkflow) CreateTaskBranch(ctx context.Context, taskID, description string) error {
	branchName := fmt.Sprintf("task/%s-%s", taskID, strings.ToLower(description))
	branchName = strings.ReplaceAll(branchName, " ", "-")
	return f.manager.CreateSubBranch(ctx, branchName, f.mainBranch)
}

// CreateExperimentBranch creates a branch for experimentation
func (f *FeatureBranchWorkflow) CreateExperimentBranch(ctx context.Context, experimentName string) error {
	branchName := fmt.Sprintf("experiment/%s", strings.ToLower(experimentName))
	return f.manager.CreateSubBranch(ctx, branchName, f.mainBranch)
}

// MergeFeature creates a pull request to merge a feature branch
func (f *FeatureBranchWorkflow) MergeFeature(ctx context.Context, branchName, title, description string) (int, error) {
	prInfo := interfaces.PullRequestInfo{
		Title:        title,
		Description:  description,
		SourceBranch: branchName,
		TargetBranch: f.mainBranch,
		Labels:       f.getBranchLabels(branchName),
	}
	
	return f.manager.CreatePullRequest(ctx, prInfo)
}

// GetBranchHistory returns the commit history for a feature branch
func (f *FeatureBranchWorkflow) GetBranchHistory(ctx context.Context, branchName string) ([]interfaces.CommitInfo, error) {
	return f.manager.GetCommitHistory(ctx, branchName, 100)
}

// RebaseBranch rebases a feature branch onto the main branch
func (f *FeatureBranchWorkflow) RebaseBranch(ctx context.Context, branchName string) error {
	// This would typically be implemented by:
	// 1. Switching to the feature branch
	// 2. Pulling latest changes from main
	// 3. Rebasing onto main
	// 4. Force pushing the rebased branch
	
	// For now, we'll create a commit that indicates a rebase
	commitInfo := interfaces.CommitInfo{
		Message: fmt.Sprintf("Rebase %s onto %s", branchName, f.mainBranch),
		Author:  "git-workflow-manager",
		Branch:  branchName,
	}
	
	return f.manager.CommitChanges(ctx, commitInfo)
}

// ArchiveBranch archives an old or completed branch
func (f *FeatureBranchWorkflow) ArchiveBranch(ctx context.Context, branchName string) error {
	// In a real implementation, this might:
	// 1. Tag the branch for archival
	// 2. Move it to an archive namespace
	// 3. Delete the original branch
	
	branches, err := f.manager.ListSubBranches(ctx)
	if err != nil {
		return fmt.Errorf("failed to list branches: %w", err)
	}
	
	for _, branch := range branches {
		if branch.Name == branchName {
			// Create an archive tag
			tagName := fmt.Sprintf("archive/%s", branchName)
			
			// Set metadata to mark as archived
			err := f.manager.SetMetadata(fmt.Sprintf("archived_%s", branchName), map[string]interface{}{
				"original_branch": branchName,
				"archived_at":     time.Now(),
				"reason":          "archived by feature branch workflow",
			})
			
			if err != nil {
				return fmt.Errorf("failed to set archive metadata: %w", err)
			}
			
			return f.manager.DeleteSubBranch(ctx, branchName)
		}
	}
	
	return fmt.Errorf("branch '%s' not found", branchName)
}

// CleanupStaleBranches removes branches that haven't been updated recently
func (f *FeatureBranchWorkflow) CleanupStaleBranches(ctx context.Context) error {
	if !f.autoCleanup {
		return nil
	}
	
	branches, err := f.manager.ListSubBranches(ctx)
	if err != nil {
		return fmt.Errorf("failed to list branches: %w", err)
	}
	
	cutoffDate := time.Now().AddDate(0, 0, -f.cleanupDays)
	
	for _, branch := range branches {
		// Skip protected branches
		if f.isProtectedBranch(branch.Name) {
			continue
		}
		
		// Check if branch is stale
		if branch.CreatedAt.Before(cutoffDate) && branch.Status != "active" {
			// Archive instead of directly deleting
			if err := f.ArchiveBranch(ctx, branch.Name); err != nil {
				// Log error but continue with other branches
				continue
			}
		}
	}
	
	return nil
}

// ValidateBranchName ensures branch names follow feature branch conventions
func (f *FeatureBranchWorkflow) ValidateBranchName(branchName string) error {
	// Allow flexible naming but with some basic rules
	
	if f.isProtectedBranch(branchName) {
		return fmt.Errorf("cannot create branch with protected name '%s'", branchName)
	}
	
	if len(branchName) == 0 {
		return fmt.Errorf("branch name cannot be empty")
	}
	
	if len(branchName) > 100 {
		return fmt.Errorf("branch name too long (max 100 characters)")
	}
	
	// Ensure no invalid characters
	invalidChars := []string{" ", "\t", "\n", "..", "~", "^", ":", "?", "*", "[", "\\"}
	for _, char := range invalidChars {
		if strings.Contains(branchName, char) {
			return fmt.Errorf("branch name contains invalid character '%s'", char)
		}
	}
	
	return nil
}

// GetWorkflowType returns the workflow type
func (f *FeatureBranchWorkflow) GetWorkflowType() interfaces.WorkflowType {
	return interfaces.FeatureBranchWorkflow
}

// GetBranchingStrategy returns the branching strategy description
func (f *FeatureBranchWorkflow) GetBranchingStrategy() string {
	return fmt.Sprintf("Feature branch workflow with %s as main branch", f.mainBranch)
}

// Helper methods

func (f *FeatureBranchWorkflow) formatBranchName(featureName string) string {
	name := strings.ToLower(featureName)
	name = strings.ReplaceAll(name, " ", "-")
	name = strings.ReplaceAll(name, "_", "-")
	return fmt.Sprintf("feature/%s", name)
}

func (f *FeatureBranchWorkflow) getBranchLabels(branchName string) []string {
	labels := []string{"feature-branch-workflow"}
	
	if strings.HasPrefix(branchName, "feature/") {
		labels = append(labels, "feature")
	} else if strings.HasPrefix(branchName, "bugfix/") {
		labels = append(labels, "bugfix")
	} else if strings.HasPrefix(branchName, "task/") {
		labels = append(labels, "task")
	} else if strings.HasPrefix(branchName, "experiment/") {
		labels = append(labels, "experiment")
	}
	
	return labels
}

func (f *FeatureBranchWorkflow) isProtectedBranch(branchName string) bool {
	protectedBranches := []string{"main", "master", "develop", "production", "staging"}
	for _, protected := range protectedBranches {
		if branchName == protected {
			return true
		}
	}
	return false
}
