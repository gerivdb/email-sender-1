package commit

import (
	"context"
	"fmt"
	"log"
	"regexp"
	"strings"
	"time"

	"EMAIL_SENDER_1/managers/interfaces"
	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing"
	"github.com/go-git/go-git/v5/plumbing/object"
)

// Manager handles Git commit operations
type Manager struct {
	repoPath     string
	repo         *git.Repository
	errorManager interfaces.ErrorManager

	// Commit message validation patterns
	conventionalCommitPattern *regexp.Regexp
}

// NewManager creates a new commit manager
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

	// Compile conventional commit pattern
	// Pattern: type(scope): description
	pattern := regexp.MustCompile(`^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: .{1,50}`)

	manager := &Manager{
		repoPath:                  repoPath,
		repo:                      repo,
		errorManager:              errorManager,
		conventionalCommitPattern: pattern,
	}

	log.Printf("Commit manager initialized for repository: %s", repoPath)
	return manager, nil
}

// ValidateCommitMessage validates a commit message against conventional commit standards
func (m *Manager) ValidateCommitMessage(message string) error {
	if message == "" {
		return fmt.Errorf("commit message cannot be empty")
	}

	// Remove leading/trailing whitespace
	message = strings.TrimSpace(message)

	// Check minimum length
	if len(message) < 10 {
		return fmt.Errorf("commit message too short (minimum 10 characters)")
	}

	// Check maximum length for first line
	lines := strings.Split(message, "\n")
	firstLine := lines[0]

	if len(firstLine) > 72 {
		return fmt.Errorf("commit message first line too long (maximum 72 characters)")
	}

	// Validate conventional commit format
	if !m.conventionalCommitPattern.MatchString(firstLine) {
		return fmt.Errorf("commit message does not follow conventional commit format. Expected: type(scope): description")
	}

	// Additional checks
	if strings.HasSuffix(firstLine, ".") {
		return fmt.Errorf("commit message should not end with a period")
	}

	if strings.ToLower(firstLine) == firstLine {
		return fmt.Errorf("commit message should start with a capital letter")
	}

	return nil
}

// CreateTimestampedCommit creates a commit with a timestamped message
func (m *Manager) CreateTimestampedCommit(ctx context.Context, message string, files []string) (*interfaces.CommitInfo, error) {
	if message == "" {
		return nil, fmt.Errorf("commit message cannot be empty")
	}

	// Validate the commit message
	if err := m.ValidateCommitMessage(message); err != nil {
		return nil, fmt.Errorf("invalid commit message: %w", err)
	}

	// Get the working tree
	worktree, err := m.repo.Worktree()
	if err != nil {
		return nil, fmt.Errorf("failed to get working tree: %w", err)
	}

	// Add specified files or all changes if no files specified
	if len(files) > 0 {
		for _, file := range files {
			_, err = worktree.Add(file)
			if err != nil {
				return nil, fmt.Errorf("failed to add file %s: %w", file, err)
			}
		}
	} else {
		// Add all changes
		_, err = worktree.Add(".")
		if err != nil {
			return nil, fmt.Errorf("failed to add changes: %w", err)
		}
	}

	// Create timestamped commit message
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	timestampedMessage := fmt.Sprintf("%s\n\nTimestamp: %s", message, timestamp)

	// Create the commit
	commitHash, err := worktree.Commit(timestampedMessage, &git.CommitOptions{
		Author: &object.Signature{
			Name:  "GitWorkflowManager",
			Email: "git-workflow@email-sender.local",
			When:  time.Now(),
		},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create commit: %w", err)
	}

	// Get current branch
	head, err := m.repo.Head()
	if err != nil {
		return nil, fmt.Errorf("failed to get current branch: %w", err)
	}

	commitInfo := &interfaces.CommitInfo{
		Hash:      commitHash.String(),
		Message:   timestampedMessage,
		Author:    "GitWorkflowManager",
		Timestamp: time.Now(),
		Branch:    head.Name().Short(),
	}

	log.Printf("Created timestamped commit %s on branch %s", commitHash.String()[:8], head.Name().Short())
	return commitInfo, nil
}

// GetCommitHistory returns the commit history for a branch
func (m *Manager) GetCommitHistory(ctx context.Context, branch string, limit int) ([]*interfaces.CommitInfo, error) {
	if limit <= 0 {
		limit = 10 // Default limit
	}

	// Get the branch reference
	var ref *plumbing.Reference
	var err error

	if branch == "" {
		// Use current branch
		ref, err = m.repo.Head()
		if err != nil {
			return nil, fmt.Errorf("failed to get current branch: %w", err)
		}
	} else {
		ref, err = m.repo.Reference(plumbing.NewBranchReferenceName(branch), true)
		if err != nil {
			return nil, fmt.Errorf("failed to get branch %s: %w", branch, err)
		}
	}

	// Get commit iterator
	commitIter, err := m.repo.Log(&git.LogOptions{
		From:  ref.Hash(),
		Order: git.LogOrderCommitterTime,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get commit log: %w", err)
	}
	defer commitIter.Close()

	var commits []*interfaces.CommitInfo
	count := 0

	err = commitIter.ForEach(func(commit *object.Commit) error {
		if count >= limit {
			return fmt.Errorf("limit reached") // Use error to break iteration
		}

		commitInfo := &interfaces.CommitInfo{
			Hash:      commit.Hash.String(),
			Message:   commit.Message,
			Author:    commit.Author.Name,
			Timestamp: commit.Author.When,
			Branch:    ref.Name().Short(),
		}

		commits = append(commits, commitInfo)
		count++

		return nil
	})

	// Filter out the "limit reached" error
	if err != nil && !strings.Contains(err.Error(), "limit reached") {
		return nil, fmt.Errorf("failed to iterate commits: %w", err)
	}

	return commits, nil
}

// GetLastCommit returns the last commit for a branch
func (m *Manager) GetLastCommit(ctx context.Context, branch string) (*interfaces.CommitInfo, error) {
	commits, err := m.GetCommitHistory(ctx, branch, 1)
	if err != nil {
		return nil, fmt.Errorf("failed to get commit history: %w", err)
	}

	if len(commits) == 0 {
		return nil, fmt.Errorf("no commits found for branch %s", branch)
	}

	return commits[0], nil
}

// GetCommitDetails returns detailed information about a specific commit
func (m *Manager) GetCommitDetails(ctx context.Context, commitHash string) (*interfaces.CommitInfo, error) {
	if commitHash == "" {
		return nil, fmt.Errorf("commit hash cannot be empty")
	}

	// Parse the commit hash
	hash := plumbing.NewHash(commitHash)

	// Get the commit object
	commit, err := m.repo.CommitObject(hash)
	if err != nil {
		return nil, fmt.Errorf("failed to get commit %s: %w", commitHash, err)
	}

	// Determine which branch contains this commit (simplified approach)
	branch := "unknown"
	head, err := m.repo.Head()
	if err == nil {
		// Check if this commit is reachable from HEAD
		headCommit, err := m.repo.CommitObject(head.Hash())
		if err == nil && m.isCommitReachable(commit, headCommit) {
			branch = head.Name().Short()
		}
	}

	commitInfo := &interfaces.CommitInfo{
		Hash:      commit.Hash.String(),
		Message:   commit.Message,
		Author:    commit.Author.Name,
		Timestamp: commit.Author.When,
		Branch:    branch,
	}

	return commitInfo, nil
}

// isCommitReachable checks if a commit is reachable from another commit
func (m *Manager) isCommitReachable(target, from *object.Commit) bool {
	// Simplified implementation - walk the commit history
	if target.Hash == from.Hash {
		return true
	}

	// Check parents (limited depth to avoid infinite loops)
	depth := 0
	maxDepth := 100

	var checkParents func(*object.Commit) bool
	checkParents = func(commit *object.Commit) bool {
		if depth > maxDepth {
			return false
		}
		depth++

		parentIter := commit.Parents()
		defer parentIter.Close()

		err := parentIter.ForEach(func(parent *object.Commit) error {
			if parent.Hash == target.Hash {
				return fmt.Errorf("found") // Use error to break iteration
			}

			if checkParents(parent) {
				return fmt.Errorf("found")
			}

			return nil
		})

		return err != nil && strings.Contains(err.Error(), "found")
	}

	return checkParents(from)
}

// CreateCommitWithFiles creates a commit with specific files
func (m *Manager) CreateCommitWithFiles(ctx context.Context, message string, files []string) (*interfaces.CommitInfo, error) {
	if len(files) == 0 {
		return nil, fmt.Errorf("at least one file must be specified")
	}

	return m.CreateTimestampedCommit(ctx, message, files)
}

// AmendLastCommit amends the last commit with new changes
func (m *Manager) AmendLastCommit(ctx context.Context, newMessage string) (*interfaces.CommitInfo, error) {
	if newMessage != "" {
		// Validate the new message
		if err := m.ValidateCommitMessage(newMessage); err != nil {
			return nil, fmt.Errorf("invalid commit message: %w", err)
		}
	}

	// Get the working tree
	worktree, err := m.repo.Worktree()
	if err != nil {
		return nil, fmt.Errorf("failed to get working tree: %w", err)
	}

	// Add all changes
	_, err = worktree.Add(".")
	if err != nil {
		return nil, fmt.Errorf("failed to add changes: %w", err)
	}

	// Get the last commit
	head, err := m.repo.Head()
	if err != nil {
		return nil, fmt.Errorf("failed to get HEAD: %w", err)
	}

	lastCommit, err := m.repo.CommitObject(head.Hash())
	if err != nil {
		return nil, fmt.Errorf("failed to get last commit: %w", err)
	}

	// Use existing message if no new message provided
	message := lastCommit.Message
	if newMessage != "" {
		timestamp := time.Now().Format("2006-01-02 15:04:05")
		message = fmt.Sprintf("%s\n\nAmended: %s", newMessage, timestamp)
	}

	// Create amended commit	// Get parent hashes
	var parentHashes []plumbing.Hash
	parentIter := lastCommit.Parents()
	defer parentIter.Close()
	parentIter.ForEach(func(parent *object.Commit) error {
		parentHashes = append(parentHashes, parent.Hash)
		return nil
	})

	commitHash, err := worktree.Commit(message, &git.CommitOptions{
		Author: &object.Signature{
			Name:  "GitWorkflowManager",
			Email: "git-workflow@email-sender.local",
			When:  time.Now(),
		},
		Parents: parentHashes,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to amend commit: %w", err)
	}

	commitInfo := &interfaces.CommitInfo{
		Hash:      commitHash.String(),
		Message:   message,
		Author:    "GitWorkflowManager",
		Timestamp: time.Now(),
		Branch:    head.Name().Short(),
	}

	log.Printf("Amended commit %s on branch %s", commitHash.String()[:8], head.Name().Short())
	return commitInfo, nil
}

// GetCommitStats returns statistics about commits
func (m *Manager) GetCommitStats(ctx context.Context, branch string, since time.Time) (map[string]interface{}, error) {
	commits, err := m.GetCommitHistory(ctx, branch, 1000) // Get up to 1000 commits
	if err != nil {
		return nil, fmt.Errorf("failed to get commit history: %w", err)
	}

	stats := make(map[string]interface{})

	totalCommits := 0
	commitsSincePeriod := 0
	authorStats := make(map[string]int)

	for _, commit := range commits {
		totalCommits++

		if commit.Timestamp.After(since) {
			commitsSincePeriod++
		}

		authorStats[commit.Author]++
	}

	stats["total_commits"] = totalCommits
	stats["commits_since_period"] = commitsSincePeriod
	stats["author_stats"] = authorStats
	stats["since"] = since.Format("2006-01-02 15:04:05")

	return stats, nil
}

// Health checks the health of the commit manager
func (m *Manager) Health() error {
	// Check if repository is accessible
	_, err := m.repo.Head()
	if err != nil {
		return fmt.Errorf("repository health check failed: %w", err)
	}

	return nil
}

// Shutdown gracefully shuts down the commit manager
func (m *Manager) Shutdown(ctx context.Context) error {
	// Clean up any resources if needed
	log.Printf("Commit manager shutdown completed")
	return nil
}
