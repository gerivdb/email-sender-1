package branch

import (
	"context"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/gerivdb/email-sender-1/managers/interfaces"
	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing"
)

// Manager handles Git branch operations
type Manager struct {
	repoPath     string
	repo         *git.Repository
	errorManager interfaces.ErrorManager
}

// NewManager creates a new branch manager
func NewManager(repoPath string, errorManager interfaces.ErrorManager) (*Manager, error) {
	if repoPath == "" {
		return nil, fmt.Errorf("repository path is required")
	}

	if errorManager == nil {
		return nil, fmt.Errorf("error manager is required")
	}

	// Open the Git repository
	repo, err := git.PlainOpen(repoPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open repository at %s: %w", repoPath, err)
	}

	manager := &Manager{
		repoPath:     repoPath,
		repo:         repo,
		errorManager: errorManager,
	}

	log.Printf("Branch manager initialized for repository: %s", repoPath)
	return manager, nil
}

// CreateBranch creates a new branch from the specified source branch
func (m *Manager) CreateBranch(ctx context.Context, branchName string, sourceBranch string) error {
	if branchName == "" {
		return fmt.Errorf("branch name cannot be empty")
	}

	// Get the source branch reference
	var sourceRef *plumbing.Reference
	var err error

	if sourceBranch == "" {
		// Use current branch if no source specified
		sourceRef, err = m.repo.Head()
		if err != nil {
			return fmt.Errorf("failed to get current branch: %w", err)
		}
	} else {
		sourceRef, err = m.repo.Reference(plumbing.NewBranchReferenceName(sourceBranch), true)
		if err != nil {
			return fmt.Errorf("failed to get source branch %s: %w", sourceBranch, err)
		}
	}

	// Create new branch reference
	newBranchRef := plumbing.NewBranchReferenceName(branchName)
	newRef := plumbing.NewHashReference(newBranchRef, sourceRef.Hash())

	err = m.repo.Storer.SetReference(newRef)
	if err != nil {
		return fmt.Errorf("failed to create branch %s: %w", branchName, err)
	}

	log.Printf("Created branch %s from %s", branchName, sourceBranch)
	return nil
}

// SwitchBranch switches to the specified branch
func (m *Manager) SwitchBranch(ctx context.Context, branchName string) error {
	if branchName == "" {
		return fmt.Errorf("branch name cannot be empty")
	}

	// Get the working tree
	worktree, err := m.repo.Worktree()
	if err != nil {
		return fmt.Errorf("failed to get working tree: %w", err)
	}

	// Create checkout options
	checkoutOptions := &git.CheckoutOptions{
		Branch: plumbing.NewBranchReferenceName(branchName),
	}

	err = worktree.Checkout(checkoutOptions)
	if err != nil {
		return fmt.Errorf("failed to switch to branch %s: %w", branchName, err)
	}

	log.Printf("Switched to branch %s", branchName)
	return nil
}

// DeleteBranch deletes the specified branch
func (m *Manager) DeleteBranch(ctx context.Context, branchName string, force bool) error {
	if branchName == "" {
		return fmt.Errorf("branch name cannot be empty")
	}

	// Check if we're trying to delete the current branch
	currentBranch, err := m.GetCurrentBranch(ctx)
	if err != nil {
		return fmt.Errorf("failed to get current branch: %w", err)
	}

	if currentBranch == branchName {
		return fmt.Errorf("cannot delete current branch %s", branchName)
	}

	// Delete the branch reference
	branchRef := plumbing.NewBranchReferenceName(branchName)
	err = m.repo.Storer.RemoveReference(branchRef)
	if err != nil {
		return fmt.Errorf("failed to delete branch %s: %w", branchName, err)
	}

	log.Printf("Deleted branch %s", branchName)
	return nil
}

// ListBranches returns a list of all branches
func (m *Manager) ListBranches(ctx context.Context) ([]string, error) {
	refs, err := m.repo.References()
	if err != nil {
		return nil, fmt.Errorf("failed to get references: %w", err)
	}

	var branches []string
	err = refs.ForEach(func(ref *plumbing.Reference) error {
		if ref.Name().IsBranch() {
			branchName := ref.Name().Short()
			branches = append(branches, branchName)
		}
		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to iterate references: %w", err)
	}

	return branches, nil
}

// GetCurrentBranch returns the name of the current branch
func (m *Manager) GetCurrentBranch(ctx context.Context) (string, error) {
	head, err := m.repo.Head()
	if err != nil {
		return "", fmt.Errorf("failed to get HEAD: %w", err)
	}

	if !head.Name().IsBranch() {
		return "", fmt.Errorf("HEAD is not pointing to a branch")
	}

	return head.Name().Short(), nil
}

// CreateSubBranch creates a sub-branch with workflow-specific naming
func (m *Manager) CreateSubBranch(ctx context.Context, subBranchName string, parentBranch string, workflowType interfaces.WorkflowType) (*interfaces.SubBranchInfo, error) {
	if subBranchName == "" {
		return nil, fmt.Errorf("sub-branch name cannot be empty")
	}

	if parentBranch == "" {
		// Use current branch as parent
		var err error
		parentBranch, err = m.GetCurrentBranch(ctx)
		if err != nil {
			return nil, fmt.Errorf("failed to get current branch as parent: %w", err)
		}
	}

	// Apply workflow-specific naming conventions
	fullBranchName := m.formatBranchName(subBranchName, workflowType)

	// Create the branch
	err := m.CreateBranch(ctx, fullBranchName, parentBranch)
	if err != nil {
		return nil, fmt.Errorf("failed to create sub-branch: %w", err)
	}

	// Get the last commit for the sub-branch info
	ref, err := m.repo.Reference(plumbing.NewBranchReferenceName(fullBranchName), true)
	if err != nil {
		return nil, fmt.Errorf("failed to get branch reference: %w", err)
	}

	subBranchInfo := &interfaces.SubBranchInfo{
		Name:         fullBranchName,
		ParentBranch: parentBranch,
		CreatedAt:    time.Now(),
		LastCommit:   ref.Hash().String(),
		Status:       "active",
	}

	log.Printf("Created sub-branch %s from parent %s", fullBranchName, parentBranch)
	return subBranchInfo, nil
}

// MergeSubBranch merges a sub-branch into the target branch
func (m *Manager) MergeSubBranch(ctx context.Context, subBranchName string, targetBranch string, deleteAfterMerge bool) error {
	if subBranchName == "" {
		return fmt.Errorf("sub-branch name cannot be empty")
	}

	if targetBranch == "" {
		return fmt.Errorf("target branch name cannot be empty")
	}

	// Get the working tree
	worktree, err := m.repo.Worktree()
	if err != nil {
		return fmt.Errorf("failed to get working tree: %w", err)
	}

	// Switch to target branch first
	err = m.SwitchBranch(ctx, targetBranch)
	if err != nil {
		return fmt.Errorf("failed to switch to target branch %s: %w", targetBranch, err)
	}

	// Get the sub-branch reference
	subBranchRef, err := m.repo.Reference(plumbing.NewBranchReferenceName(subBranchName), true)
	if err != nil {
		return fmt.Errorf("failed to get sub-branch reference: %w", err)
	}

	// Get the commit object for the sub-branch
	subBranchCommit, err := m.repo.CommitObject(subBranchRef.Hash())
	if err != nil {
		return fmt.Errorf("failed to get sub-branch commit: %w", err)
	}

	// Perform the merge (simplified merge, in practice you'd want more sophisticated merge strategies)
	_, err = worktree.Commit(fmt.Sprintf("Merge branch '%s' into %s", subBranchName, targetBranch), &git.CommitOptions{
		Parents: []plumbing.Hash{subBranchCommit.Hash},
	})
	if err != nil {
		return fmt.Errorf("failed to create merge commit: %w", err)
	}

	// Delete the sub-branch if requested
	if deleteAfterMerge {
		err = m.DeleteBranch(ctx, subBranchName, false)
		if err != nil {
			log.Printf("Warning: failed to delete sub-branch %s after merge: %v", subBranchName, err)
		}
	}

	log.Printf("Merged sub-branch %s into %s", subBranchName, targetBranch)
	return nil
}

// ListSubBranches returns sub-branches for a given parent branch
func (m *Manager) ListSubBranches(ctx context.Context, parentBranch string) ([]*interfaces.SubBranchInfo, error) {
	branches, err := m.ListBranches(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to list branches: %w", err)
	}

	var subBranches []*interfaces.SubBranchInfo

	// Filter branches that appear to be sub-branches of the parent
	// This is a simplified implementation - in practice you'd want to track this metadata
	for _, branch := range branches {
		if m.isSubBranch(branch, parentBranch) {
			// Get branch info
			ref, err := m.repo.Reference(plumbing.NewBranchReferenceName(branch), true)
			if err != nil {
				continue
			}

			// Get commit timestamp (simplified)
			commit, err := m.repo.CommitObject(ref.Hash())
			var createdAt time.Time
			if err == nil {
				createdAt = commit.Author.When
			} else {
				createdAt = time.Now()
			}

			subBranchInfo := &interfaces.SubBranchInfo{
				Name:         branch,
				ParentBranch: parentBranch,
				CreatedAt:    createdAt,
				LastCommit:   ref.Hash().String(),
				Status:       "active",
			}

			subBranches = append(subBranches, subBranchInfo)
		}
	}

	return subBranches, nil
}

// formatBranchName applies workflow-specific naming conventions
func (m *Manager) formatBranchName(branchName string, workflowType interfaces.WorkflowType) string {
	switch workflowType {
	case interfaces.WorkflowTypeGitFlow:
		if !strings.HasPrefix(branchName, "feature/") &&
			!strings.HasPrefix(branchName, "hotfix/") &&
			!strings.HasPrefix(branchName, "release/") {
			return "feature/" + branchName
		}
		return branchName
	case interfaces.WorkflowTypeGitHubFlow:
		// GitHub Flow typically uses feature branches
		if !strings.HasPrefix(branchName, "feature/") {
			return "feature/" + branchName
		}
		return branchName
	case interfaces.WorkflowTypeFeatureBranch:
		if !strings.HasPrefix(branchName, "feature/") {
			return "feature/" + branchName
		}
		return branchName
	default:
		return branchName
	}
}

// isSubBranch determines if a branch is a sub-branch of the parent
func (m *Manager) isSubBranch(branchName, parentBranch string) bool {
	// Simplified logic - in practice you'd want more sophisticated tracking
	if branchName == parentBranch {
		return false
	}

	// Check for common sub-branch patterns
	prefixes := []string{"feature/", "hotfix/", "bugfix/", "chore/"}

	for _, prefix := range prefixes {
		if strings.HasPrefix(branchName, prefix) {
			return true
		}
	}

	return false
}

// Health checks the health of the branch manager
func (m *Manager) Health() error {
	// Check if repository is accessible
	_, err := m.repo.Head()
	if err != nil {
		return fmt.Errorf("repository health check failed: %w", err)
	}

	return nil
}

// Shutdown gracefully shuts down the branch manager
func (m *Manager) Shutdown(ctx context.Context) error {
	// Clean up any resources if needed
	log.Printf("Branch manager shutdown completed")
	return nil
}
