package git

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/gerivdb/email-sender-1/development/managers/branching-manager/interfaces"
)

// GitOperationsManager handles real Git operations
type GitOperationsManager struct {
	repoPath      string
	gitExecutable string
	defaultBranch string
	remoteName    string
}

// GitConfig holds Git operation configuration
type GitConfig struct {
	RepoPath      string
	GitExecutable string
	DefaultBranch string
	RemoteName    string
}

// GitResult represents the result of a Git operation
type GitResult struct {
	Success  bool
	Output   string
	Error    string
	ExitCode int
	Duration time.Duration
}

// NewGitOperationsManager creates a new Git operations manager
func NewGitOperationsManager(config *GitConfig) (*GitOperationsManager, error) {
	// Validate repository path
	if _, err := os.Stat(config.RepoPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("repository path does not exist: %s", config.RepoPath)
	}

	// Check if it's a Git repository
	gitDir := filepath.Join(config.RepoPath, ".git")
	if _, err := os.Stat(gitDir); os.IsNotExist(err) {
		return nil, fmt.Errorf("not a Git repository: %s", config.RepoPath)
	}

	// Validate Git executable
	if _, err := exec.LookPath(config.GitExecutable); err != nil {
		return nil, fmt.Errorf("git executable not found: %s", config.GitExecutable)
	}

	return &GitOperationsManager{
		repoPath:      config.RepoPath,
		gitExecutable: config.GitExecutable,
		defaultBranch: config.DefaultBranch,
		remoteName:    config.RemoteName,
	}, nil
}

// CreateBranch creates a new Git branch
func (g *GitOperationsManager) CreateBranch(ctx context.Context, branchName, baseBranch string) (*interfaces.GitBranchResult, error) {
	// Ensure we're on the base branch first
	if err := g.checkoutBranch(ctx, baseBranch); err != nil {
		return nil, fmt.Errorf("failed to checkout base branch %s: %v", baseBranch, err)
	}

	// Pull latest changes from remote
	if err := g.pullChanges(ctx, baseBranch); err != nil {
		return nil, fmt.Errorf("failed to pull latest changes: %v", err)
	}

	// Create and checkout new branch
	result := g.executeGitCommand(ctx, "checkout", "-b", branchName)
	if !result.Success {
		return nil, fmt.Errorf("failed to create branch %s: %s", branchName, result.Error)
	}

	// Get the current commit hash
	hashResult := g.executeGitCommand(ctx, "rev-parse", "HEAD")
	if !hashResult.Success {
		return nil, fmt.Errorf("failed to get commit hash: %s", hashResult.Error)
	}

	return &interfaces.GitBranchResult{
		BranchName: branchName,
		BaseBranch: baseBranch,
		GitHash:    strings.TrimSpace(hashResult.Output),
		Success:    true,
		CreatedAt:  time.Now(),
	}, nil
}

// DeleteBranch deletes a Git branch
func (g *GitOperationsManager) DeleteBranch(ctx context.Context, branchName string, force bool) error {
	// Switch to default branch before deleting
	if err := g.checkoutBranch(ctx, g.defaultBranch); err != nil {
		return fmt.Errorf("failed to checkout default branch: %v", err)
	}

	// Delete local branch
	deleteFlag := "-d"
	if force {
		deleteFlag = "-D"
	}

	result := g.executeGitCommand(ctx, "branch", deleteFlag, branchName)
	if !result.Success {
		return fmt.Errorf("failed to delete branch %s: %s", branchName, result.Error)
	}

	// Delete remote branch if it exists
	g.executeGitCommand(ctx, "push", g.remoteName, "--delete", branchName)
	// Ignore errors for remote deletion as the branch might not exist remotely

	return nil
}

// MergeBranch merges a branch into the target branch
func (g *GitOperationsManager) MergeBranch(ctx context.Context, sourceBranch, targetBranch string, mergeMessage string) (*interfaces.GitMergeResult, error) {
	// Checkout target branch
	if err := g.checkoutBranch(ctx, targetBranch); err != nil {
		return nil, fmt.Errorf("failed to checkout target branch %s: %v", targetBranch, err)
	}

	// Pull latest changes
	if err := g.pullChanges(ctx, targetBranch); err != nil {
		return nil, fmt.Errorf("failed to pull latest changes: %v", err)
	}

	// Perform merge
	args := []string{"merge", sourceBranch}
	if mergeMessage != "" {
		args = append(args, "-m", mergeMessage)
	}

	result := g.executeGitCommand(ctx, args...)
	if !result.Success {
		return &interfaces.GitMergeResult{
			Success:       false,
			ErrorMessage:  result.Error,
			ConflictFiles: g.getConflictFiles(ctx),
		}, nil
	}

	// Get merge commit hash
	hashResult := g.executeGitCommand(ctx, "rev-parse", "HEAD")
	gitHash := ""
	if hashResult.Success {
		gitHash = strings.TrimSpace(hashResult.Output)
	}

	return &interfaces.GitMergeResult{
		Success:     true,
		MergeCommit: gitHash,
		MergedAt:    time.Now(),
	}, nil
}

// CreateCommit creates a new commit with changes
func (g *GitOperationsManager) CreateCommit(ctx context.Context, message string, files []string) (*interfaces.GitCommitResult, error) {
	// Stage files
	if len(files) > 0 {
		args := append([]string{"add"}, files...)
		result := g.executeGitCommand(ctx, args...)
		if !result.Success {
			return nil, fmt.Errorf("failed to stage files: %s", result.Error)
		}
	} else {
		// Stage all changes if no specific files provided
		result := g.executeGitCommand(ctx, "add", ".")
		if !result.Success {
			return nil, fmt.Errorf("failed to stage changes: %s", result.Error)
		}
	}

	// Check if there are any changes to commit
	statusResult := g.executeGitCommand(ctx, "status", "--porcelain", "--cached")
	if !statusResult.Success {
		return nil, fmt.Errorf("failed to check git status: %s", statusResult.Error)
	}

	if strings.TrimSpace(statusResult.Output) == "" {
		return &interfaces.GitCommitResult{
			Success: false,
			Message: "No changes to commit",
		}, nil
	}

	// Create commit
	result := g.executeGitCommand(ctx, "commit", "-m", message)
	if !result.Success {
		return nil, fmt.Errorf("failed to create commit: %s", result.Error)
	}

	// Get commit hash
	hashResult := g.executeGitCommand(ctx, "rev-parse", "HEAD")
	gitHash := ""
	if hashResult.Success {
		gitHash = strings.TrimSpace(hashResult.Output)
	}

	return &interfaces.GitCommitResult{
		Success:     true,
		CommitHash:  gitHash,
		Message:     message,
		CommittedAt: time.Now(),
	}, nil
}

// PushBranch pushes a branch to remote repository
func (g *GitOperationsManager) PushBranch(ctx context.Context, branchName string) error {
	result := g.executeGitCommand(ctx, "push", "-u", g.remoteName, branchName)
	if !result.Success {
		return fmt.Errorf("failed to push branch %s: %s", branchName, result.Error)
	}
	return nil
}

// GetBranchInfo gets information about a branch
func (g *GitOperationsManager) GetBranchInfo(ctx context.Context, branchName string) (*interfaces.GitBranchInfo, error) {
	// Check if branch exists
	result := g.executeGitCommand(ctx, "rev-parse", "--verify", branchName)
	if !result.Success {
		return nil, fmt.Errorf("branch %s does not exist", branchName)
	}

	gitHash := strings.TrimSpace(result.Output)

	// Get last commit message
	messageResult := g.executeGitCommand(ctx, "log", "-1", "--pretty=format:%s", branchName)
	lastCommitMessage := ""
	if messageResult.Success {
		lastCommitMessage = strings.TrimSpace(messageResult.Output)
	}

	// Get last commit date
	dateResult := g.executeGitCommand(ctx, "log", "-1", "--pretty=format:%ci", branchName)
	var lastCommitDate time.Time
	if dateResult.Success {
		if parsedTime, err := time.Parse("2006-01-02 15:04:05 -0700", strings.TrimSpace(dateResult.Output)); err == nil {
			lastCommitDate = parsedTime
		}
	}

	// Get author
	authorResult := g.executeGitCommand(ctx, "log", "-1", "--pretty=format:%an", branchName)
	author := ""
	if authorResult.Success {
		author = strings.TrimSpace(authorResult.Output)
	}

	// Get ahead/behind info compared to default branch
	aheadBehind := g.getAheadBehindInfo(ctx, branchName, g.defaultBranch)

	return &interfaces.GitBranchInfo{
		Name:              branchName,
		GitHash:           gitHash,
		LastCommitMessage: lastCommitMessage,
		LastCommitDate:    lastCommitDate,
		Author:            author,
		AheadBy:           aheadBehind.Ahead,
		BehindBy:          aheadBehind.Behind,
	}, nil
}

// GetCurrentBranch returns the current branch name
func (g *GitOperationsManager) GetCurrentBranch(ctx context.Context) (string, error) {
	result := g.executeGitCommand(ctx, "branch", "--show-current")
	if !result.Success {
		return "", fmt.Errorf("failed to get current branch: %s", result.Error)
	}
	return strings.TrimSpace(result.Output), nil
}

// ListBranches lists all branches
func (g *GitOperationsManager) ListBranches(ctx context.Context, includeRemote bool) ([]string, error) {
	args := []string{"branch"}
	if includeRemote {
		args = append(args, "-a")
	}

	result := g.executeGitCommand(ctx, args...)
	if !result.Success {
		return nil, fmt.Errorf("failed to list branches: %s", result.Error)
	}

	var branches []string
	scanner := bufio.NewScanner(strings.NewReader(result.Output))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}

		// Remove current branch indicator (*)
		if strings.HasPrefix(line, "* ") {
			line = strings.TrimSpace(line[2:])
		}

		// Skip HEAD detached state
		if strings.Contains(line, "HEAD detached") {
			continue
		}

		branches = append(branches, line)
	}

	return branches, nil
}

// GetChangedFiles returns files changed in the current branch
func (g *GitOperationsManager) GetChangedFiles(ctx context.Context, baseBranch string) ([]string, error) {
	result := g.executeGitCommand(ctx, "diff", "--name-only", baseBranch+"...HEAD")
	if !result.Success {
		return nil, fmt.Errorf("failed to get changed files: %s", result.Error)
	}

	var files []string
	scanner := bufio.NewScanner(strings.NewReader(result.Output))
	for scanner.Scan() {
		file := strings.TrimSpace(scanner.Text())
		if file != "" {
			files = append(files, file)
		}
	}

	return files, nil
}

// CreateTemporalSnapshot creates a temporal snapshot for time-travel functionality
func (g *GitOperationsManager) CreateTemporalSnapshot(ctx context.Context, branchName string, metadata map[string]interface{}) (*interfaces.TemporalSnapshot, error) {
	// Get current commit hash
	hashResult := g.executeGitCommand(ctx, "rev-parse", "HEAD")
	if !hashResult.Success {
		return nil, fmt.Errorf("failed to get commit hash: %s", hashResult.Error)
	}

	gitHash := strings.TrimSpace(hashResult.Output)

	// Get changes summary
	changesResult := g.executeGitCommand(ctx, "diff", "--stat", "HEAD~1..HEAD")
	changesSummary := ""
	if changesResult.Success {
		changesSummary = changesResult.Output
	}

	// Create snapshot tag for easy reference
	snapshotID := uuid.New().String()
	tagName := fmt.Sprintf("snapshot-%s-%d", branchName, time.Now().Unix())

	g.executeGitCommand(ctx, "tag", tagName, gitHash)

	return &interfaces.TemporalSnapshot{
		ID:             snapshotID,
		BranchID:       branchName,
		GitHash:        gitHash,
		Timestamp:      time.Now(),
		ChangesSummary: changesSummary,
		TagName:        tagName,
		Metadata:       metadata,
	}, nil
}

// TimeTravelToSnapshot restores repository to a specific snapshot
func (g *GitOperationsManager) TimeTravelToSnapshot(ctx context.Context, snapshot *interfaces.TemporalSnapshot) error {
	// Create a new branch for the time-travel operation
	timeTravelBranch := fmt.Sprintf("time-travel-%s-%d", snapshot.BranchID, time.Now().Unix())

	result := g.executeGitCommand(ctx, "checkout", "-b", timeTravelBranch, snapshot.GitHash)
	if !result.Success {
		return fmt.Errorf("failed to create time-travel branch: %s", result.Error)
	}

	return nil
}

// checkoutBranch switches to the specified branch
func (g *GitOperationsManager) checkoutBranch(ctx context.Context, branchName string) error {
	result := g.executeGitCommand(ctx, "checkout", branchName)
	if !result.Success {
		return fmt.Errorf("failed to checkout branch %s: %s", branchName, result.Error)
	}
	return nil
}

// pullChanges pulls latest changes from remote
func (g *GitOperationsManager) pullChanges(ctx context.Context, branchName string) error {
	result := g.executeGitCommand(ctx, "pull", g.remoteName, branchName)
	if !result.Success {
		// Pull might fail if remote branch doesn't exist, which is okay for new branches
		if !strings.Contains(result.Error, "couldn't find remote ref") {
			return fmt.Errorf("failed to pull changes: %s", result.Error)
		}
	}
	return nil
}

// getConflictFiles returns list of files with merge conflicts
func (g *GitOperationsManager) getConflictFiles(ctx context.Context) []string {
	result := g.executeGitCommand(ctx, "diff", "--name-only", "--diff-filter=U")
	if !result.Success {
		return nil
	}

	var files []string
	scanner := bufio.NewScanner(strings.NewReader(result.Output))
	for scanner.Scan() {
		file := strings.TrimSpace(scanner.Text())
		if file != "" {
			files = append(files, file)
		}
	}

	return files
}

// AheadBehindInfo represents ahead/behind commit counts
type AheadBehindInfo struct {
	Ahead  int
	Behind int
}

// getAheadBehindInfo gets ahead/behind commit counts
func (g *GitOperationsManager) getAheadBehindInfo(ctx context.Context, branch, baseBranch string) AheadBehindInfo {
	result := g.executeGitCommand(ctx, "rev-list", "--left-right", "--count", branch+"..."+baseBranch)
	if !result.Success {
		return AheadBehindInfo{}
	}

	parts := strings.Fields(strings.TrimSpace(result.Output))
	if len(parts) != 2 {
		return AheadBehindInfo{}
	}

	ahead := 0
	behind := 0

	if val, err := parseIntSafe(parts[0]); err == nil {
		ahead = val
	}
	if val, err := parseIntSafe(parts[1]); err == nil {
		behind = val
	}

	return AheadBehindInfo{
		Ahead:  ahead,
		Behind: behind,
	}
}

// executeGitCommand executes a Git command and returns the result
func (g *GitOperationsManager) executeGitCommand(ctx context.Context, args ...string) *GitResult {
	startTime := time.Now()

	cmd := exec.CommandContext(ctx, g.gitExecutable, args...)
	cmd.Dir = g.repoPath

	output, err := cmd.CombinedOutput()
	duration := time.Since(startTime)

	result := &GitResult{
		Output:   string(output),
		Duration: duration,
	}

	if err != nil {
		result.Success = false
		result.Error = err.Error()
		if exitError, ok := err.(*exec.ExitError); ok {
			result.ExitCode = exitError.ExitCode()
		}
	} else {
		result.Success = true
		result.ExitCode = 0
	}

	return result
}

// GetRepositoryStatus returns the current repository status
func (g *GitOperationsManager) GetRepositoryStatus(ctx context.Context) (*interfaces.GitRepositoryStatus, error) {
	// Get current branch
	currentBranch, err := g.GetCurrentBranch(ctx)
	if err != nil {
		return nil, err
	}

	// Get status
	statusResult := g.executeGitCommand(ctx, "status", "--porcelain")
	if !statusResult.Success {
		return nil, fmt.Errorf("failed to get repository status: %s", statusResult.Error)
	}

	// Parse status output
	var modifiedFiles, untrackedFiles, stagedFiles []string
	scanner := bufio.NewScanner(strings.NewReader(statusResult.Output))
	for scanner.Scan() {
		line := scanner.Text()
		if len(line) < 3 {
			continue
		}

		status := line[:2]
		file := strings.TrimSpace(line[3:])

		switch {
		case status[0] != ' ' && status[0] != '?':
			stagedFiles = append(stagedFiles, file)
		case status[1] == 'M':
			modifiedFiles = append(modifiedFiles, file)
		case status == "??":
			untrackedFiles = append(untrackedFiles, file)
		}
	}

	// Get last commit info
	hashResult := g.executeGitCommand(ctx, "rev-parse", "HEAD")
	lastCommitHash := ""
	if hashResult.Success {
		lastCommitHash = strings.TrimSpace(hashResult.Output)
	}

	return &interfaces.GitRepositoryStatus{
		CurrentBranch:  currentBranch,
		LastCommitHash: lastCommitHash,
		ModifiedFiles:  modifiedFiles,
		UntrackedFiles: untrackedFiles,
		StagedFiles:    stagedFiles,
		IsClean:        len(modifiedFiles) == 0 && len(untrackedFiles) == 0 && len(stagedFiles) == 0,
	}, nil
}

// ValidateRepository validates that the repository is in a good state
func (g *GitOperationsManager) ValidateRepository(ctx context.Context) error {
	// Check if we're in a Git repository
	result := g.executeGitCommand(ctx, "rev-parse", "--is-inside-work-tree")
	if !result.Success {
		return fmt.Errorf("not inside a Git repository")
	}

	// Check if repository is not corrupted
	result = g.executeGitCommand(ctx, "fsck", "--no-progress")
	if !result.Success {
		return fmt.Errorf("repository is corrupted: %s", result.Error)
	}

	return nil
}

// parseIntSafe safely parses an integer string
func parseIntSafe(s string) (int, error) {
	var result int
	_, err := fmt.Sscanf(s, "%d", &result)
	return result, err
}

// Health checks the Git operations manager health
func (g *GitOperationsManager) Health(ctx context.Context) error {
	// Check if Git executable is available
	if _, err := exec.LookPath(g.gitExecutable); err != nil {
		return fmt.Errorf("git executable not found: %v", err)
	}

	// Check if repository path exists
	if _, err := os.Stat(g.repoPath); os.IsNotExist(err) {
		return fmt.Errorf("repository path does not exist: %s", g.repoPath)
	}

	// Validate repository
	return g.ValidateRepository(ctx)
}
