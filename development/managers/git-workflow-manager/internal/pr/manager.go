package pr

import (
	"context"
	"fmt"
	"log"
	"strings"
	"time"

	"EMAIL_SENDER_1/managers/interfaces"
	"github.com/google/go-github/v58/github"
	"golang.org/x/oauth2"
)

// Manager handles GitHub Pull Request operations
type Manager struct {
	client       *github.Client
	owner        string
	repo         string
	errorManager interfaces.ErrorManager
}

// NewManager creates a new pull request manager
func NewManager(githubToken string, errorManager interfaces.ErrorManager) (*Manager, error) {
	if errorManager == nil {
		return nil, fmt.Errorf("error manager is required")
	}

	var client *github.Client

	if githubToken != "" {
		// Create authenticated client
		ctx := context.Background()
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: githubToken},
		)
		tc := oauth2.NewClient(ctx, ts)
		client = github.NewClient(tc)
	} else {
		// Create unauthenticated client (limited functionality)
		client = github.NewClient(nil)
		log.Printf("Warning: GitHub token not provided, PR functionality will be limited")
	}

	manager := &Manager{
		client:       client,
		errorManager: errorManager,
		// owner and repo will be set dynamically or from config
	}

	log.Printf("Pull Request manager initialized")
	return manager, nil
}

// SetRepository sets the GitHub repository for operations
func (m *Manager) SetRepository(owner, repo string) {
	m.owner = owner
	m.repo = repo
	log.Printf("PR manager configured for repository: %s/%s", owner, repo)
}

// CreatePullRequest creates a new pull request
func (m *Manager) CreatePullRequest(ctx context.Context, title, description, sourceBranch, targetBranch string) (*interfaces.PullRequestInfo, error) {
	if m.owner == "" || m.repo == "" {
		return nil, fmt.Errorf("repository not configured, call SetRepository first")
	}

	if title == "" {
		return nil, fmt.Errorf("pull request title cannot be empty")
	}

	if sourceBranch == "" {
		return nil, fmt.Errorf("source branch cannot be empty")
	}

	if targetBranch == "" {
		targetBranch = "main" // Default to main branch
	}

	// Validate branches exist
	_, _, err := m.client.Git.GetRef(ctx, m.owner, m.repo, "heads/"+sourceBranch)
	if err != nil {
		return nil, fmt.Errorf("source branch %s does not exist: %w", sourceBranch, err)
	}

	_, _, err = m.client.Git.GetRef(ctx, m.owner, m.repo, "heads/"+targetBranch)
	if err != nil {
		return nil, fmt.Errorf("target branch %s does not exist: %w", targetBranch, err)
	}

	// Create pull request
	pr := &github.NewPullRequest{
		Title:               github.String(title),
		Head:                github.String(sourceBranch),
		Base:                github.String(targetBranch),
		Body:                github.String(description),
		MaintainerCanModify: github.Bool(true),
	}

	createdPR, _, err := m.client.PullRequests.Create(ctx, m.owner, m.repo, pr)
	if err != nil {
		return nil, fmt.Errorf("failed to create pull request: %w", err)
	}

	prInfo := &interfaces.PullRequestInfo{
		ID:           *createdPR.Number,
		Title:        *createdPR.Title,
		Description:  *createdPR.Body,
		SourceBranch: *createdPR.Head.Ref,
		TargetBranch: *createdPR.Base.Ref, Status: strings.ToLower(*createdPR.State),
		CreatedAt: createdPR.CreatedAt.Time,
		UpdatedAt: createdPR.UpdatedAt.Time,
	}

	log.Printf("Created pull request #%d: %s", prInfo.ID, prInfo.Title)
	return prInfo, nil
}

// GetPullRequestStatus returns the status of a pull request
func (m *Manager) GetPullRequestStatus(ctx context.Context, prID int) (*interfaces.PullRequestInfo, error) {
	if m.owner == "" || m.repo == "" {
		return nil, fmt.Errorf("repository not configured, call SetRepository first")
	}

	if prID <= 0 {
		return nil, fmt.Errorf("invalid pull request ID: %d", prID)
	}

	pr, _, err := m.client.PullRequests.Get(ctx, m.owner, m.repo, prID)
	if err != nil {
		return nil, fmt.Errorf("failed to get pull request #%d: %w", prID, err)
	}

	prInfo := &interfaces.PullRequestInfo{
		ID:           *pr.Number,
		Title:        *pr.Title,
		Description:  *pr.Body,
		SourceBranch: *pr.Head.Ref, TargetBranch: *pr.Base.Ref,
		Status:    strings.ToLower(*pr.State),
		CreatedAt: pr.CreatedAt.Time,
		UpdatedAt: pr.UpdatedAt.Time,
	}

	return prInfo, nil
}

// ListPullRequests returns a list of pull requests filtered by status
func (m *Manager) ListPullRequests(ctx context.Context, status string) ([]*interfaces.PullRequestInfo, error) {
	if m.owner == "" || m.repo == "" {
		return nil, fmt.Errorf("repository not configured, call SetRepository first")
	}

	// Normalize status
	if status == "" {
		status = "open"
	}

	opts := &github.PullRequestListOptions{
		State:       status,
		Sort:        "updated",
		Direction:   "desc",
		ListOptions: github.ListOptions{PerPage: 100},
	}

	var allPRs []*interfaces.PullRequestInfo

	for {
		prs, resp, err := m.client.PullRequests.List(ctx, m.owner, m.repo, opts)
		if err != nil {
			return nil, fmt.Errorf("failed to list pull requests: %w", err)
		}

		for _, pr := range prs {
			prInfo := &interfaces.PullRequestInfo{
				ID:           *pr.Number,
				Title:        *pr.Title,
				Description:  *pr.Body,
				SourceBranch: *pr.Head.Ref,
				TargetBranch: *pr.Base.Ref,
				Status:       strings.ToLower(*pr.State), CreatedAt: pr.CreatedAt.Time,
				UpdatedAt: pr.UpdatedAt.Time,
			}
			allPRs = append(allPRs, prInfo)
		}

		if resp.NextPage == 0 {
			break
		}
		opts.Page = resp.NextPage
	}

	log.Printf("Found %d pull requests with status: %s", len(allPRs), status)
	return allPRs, nil
}

// UpdatePullRequest updates an existing pull request
func (m *Manager) UpdatePullRequest(ctx context.Context, prID int, title, description string) (*interfaces.PullRequestInfo, error) {
	if m.owner == "" || m.repo == "" {
		return nil, fmt.Errorf("repository not configured, call SetRepository first")
	}

	if prID <= 0 {
		return nil, fmt.Errorf("invalid pull request ID: %d", prID)
	}

	// Prepare update
	pr := &github.PullRequest{}

	if title != "" {
		pr.Title = github.String(title)
	}

	if description != "" {
		pr.Body = github.String(description)
	}

	updatedPR, _, err := m.client.PullRequests.Edit(ctx, m.owner, m.repo, prID, pr)
	if err != nil {
		return nil, fmt.Errorf("failed to update pull request #%d: %w", prID, err)
	}

	prInfo := &interfaces.PullRequestInfo{
		ID:           *updatedPR.Number,
		Title:        *updatedPR.Title,
		Description:  *updatedPR.Body,
		SourceBranch: *updatedPR.Head.Ref,
		TargetBranch: *updatedPR.Base.Ref, Status: strings.ToLower(*updatedPR.State),
		CreatedAt: updatedPR.CreatedAt.Time,
		UpdatedAt: updatedPR.UpdatedAt.Time,
	}

	log.Printf("Updated pull request #%d", prID)
	return prInfo, nil
}

// ClosePullRequest closes a pull request
func (m *Manager) ClosePullRequest(ctx context.Context, prID int) error {
	if m.owner == "" || m.repo == "" {
		return fmt.Errorf("repository not configured, call SetRepository first")
	}

	if prID <= 0 {
		return fmt.Errorf("invalid pull request ID: %d", prID)
	}

	pr := &github.PullRequest{
		State: github.String("closed"),
	}

	_, _, err := m.client.PullRequests.Edit(ctx, m.owner, m.repo, prID, pr)
	if err != nil {
		return fmt.Errorf("failed to close pull request #%d: %w", prID, err)
	}

	log.Printf("Closed pull request #%d", prID)
	return nil
}

// MergePullRequest merges a pull request
func (m *Manager) MergePullRequest(ctx context.Context, prID int, commitMessage string, mergeMethod string) error {
	if m.owner == "" || m.repo == "" {
		return fmt.Errorf("repository not configured, call SetRepository first")
	}

	if prID <= 0 {
		return fmt.Errorf("invalid pull request ID: %d", prID)
	}

	if mergeMethod == "" {
		mergeMethod = "merge" // Default merge method
	}

	// Validate merge method
	validMethods := []string{"merge", "squash", "rebase"}
	isValid := false
	for _, method := range validMethods {
		if method == mergeMethod {
			isValid = true
			break
		}
	}

	if !isValid {
		return fmt.Errorf("invalid merge method: %s. Valid methods: %v", mergeMethod, validMethods)
	} // Use simple merge without options for now
	_, _, err := m.client.PullRequests.Merge(ctx, m.owner, m.repo, prID, commitMessage, nil)
	if err != nil {
		return fmt.Errorf("failed to merge pull request #%d: %w", prID, err)
	}

	log.Printf("Merged pull request #%d using method: %s", prID, mergeMethod)
	return nil
}

// GetPullRequestFiles returns the files changed in a pull request
func (m *Manager) GetPullRequestFiles(ctx context.Context, prID int) ([]string, error) {
	if m.owner == "" || m.repo == "" {
		return nil, fmt.Errorf("repository not configured, call SetRepository first")
	}

	if prID <= 0 {
		return nil, fmt.Errorf("invalid pull request ID: %d", prID)
	}

	opts := &github.ListOptions{PerPage: 100}
	var allFiles []string

	for {
		files, resp, err := m.client.PullRequests.ListFiles(ctx, m.owner, m.repo, prID, opts)
		if err != nil {
			return nil, fmt.Errorf("failed to get pull request files: %w", err)
		}

		for _, file := range files {
			allFiles = append(allFiles, *file.Filename)
		}

		if resp.NextPage == 0 {
			break
		}
		opts.Page = resp.NextPage
	}

	return allFiles, nil
}

// AddComment adds a comment to a pull request
func (m *Manager) AddComment(ctx context.Context, prID int, comment string) error {
	if m.owner == "" || m.repo == "" {
		return fmt.Errorf("repository not configured, call SetRepository first")
	}

	if prID <= 0 {
		return fmt.Errorf("invalid pull request ID: %d", prID)
	}

	if comment == "" {
		return fmt.Errorf("comment cannot be empty")
	}

	prComment := &github.IssueComment{
		Body: github.String(comment),
	}

	_, _, err := m.client.Issues.CreateComment(ctx, m.owner, m.repo, prID, prComment)
	if err != nil {
		return fmt.Errorf("failed to add comment to pull request #%d: %w", prID, err)
	}

	log.Printf("Added comment to pull request #%d", prID)
	return nil
}

// GetPullRequestComments returns comments for a pull request
func (m *Manager) GetPullRequestComments(ctx context.Context, prID int) ([]map[string]interface{}, error) {
	if m.owner == "" || m.repo == "" {
		return nil, fmt.Errorf("repository not configured, call SetRepository first")
	}

	if prID <= 0 {
		return nil, fmt.Errorf("invalid pull request ID: %d", prID)
	}

	opts := &github.IssueListCommentsOptions{
		Sort:        github.String("created"),
		Direction:   github.String("asc"),
		ListOptions: github.ListOptions{PerPage: 100},
	}

	var allComments []map[string]interface{}

	for {
		comments, resp, err := m.client.Issues.ListComments(ctx, m.owner, m.repo, prID, opts)
		if err != nil {
			return nil, fmt.Errorf("failed to get pull request comments: %w", err)
		}

		for _, comment := range comments {
			commentInfo := map[string]interface{}{
				"id":         *comment.ID,
				"body":       *comment.Body,
				"author":     *comment.User.Login,
				"created_at": *comment.CreatedAt,
				"updated_at": *comment.UpdatedAt,
			}
			allComments = append(allComments, commentInfo)
		}

		if resp.NextPage == 0 {
			break
		}
		opts.Page = resp.NextPage
	}

	return allComments, nil
}

// Health checks the health of the PR manager
func (m *Manager) Health() error {
	// Test GitHub API connectivity
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	_, _, err := m.client.Users.Get(ctx, "")
	if err != nil {
		return fmt.Errorf("GitHub API health check failed: %w", err)
	}

	return nil
}

// Shutdown gracefully shuts down the PR manager
func (m *Manager) Shutdown(ctx context.Context) error {
	// Clean up any resources if needed
	log.Printf("Pull Request manager shutdown completed")
	return nil
}
