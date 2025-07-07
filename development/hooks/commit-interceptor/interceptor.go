// development/hooks/commit-interceptor/interceptor.go
package commit_interceptor

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os/exec"
	"strings"
	"time"
)

// CommitData represents the data extracted from a commit
type CommitData struct {
	Hash       string    `json:"hash"`
	Message    string    `json:"message"`
	Author     string    `json:"author"`
	Timestamp  time.Time `json:"timestamp"`
	Files      []string  `json:"files"`
	Branch     string    `json:"branch"`
	Repository string    `json:"repository"`
}

// GitWebhookPayload represents the incoming Git webhook payload
type GitWebhookPayload struct {
	Commits []struct {
		ID        string    `json:"id"`
		Message   string    `json:"message"`
		Timestamp time.Time `json:"timestamp"`
		Author    struct {
			Name  string `json:"name"`
			Email string `json:"email"`
		} `json:"author"`
		Added    []string `json:"added"`
		Removed  []string `json:"removed"`
		Modified []string `json:"modified"`
	} `json:"commits"`
	Repository struct {
		Name     string `json:"name"`
		FullName string `json:"full_name"`
	} `json:"repository"`
	Ref string `json:"ref"`
}

// ParseGitWebhookPayload parses Git webhook payload from HTTP request
func ParseGitWebhookPayload(r *http.Request) (*CommitData, error) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read request body: %w", err)
	}
	defer r.Body.Close()

	var payload GitWebhookPayload
	if err := json.Unmarshal(body, &payload); err != nil {
		return nil, fmt.Errorf("failed to parse JSON payload: %w", err)
	}

	if len(payload.Commits) == 0 {
		return nil, fmt.Errorf("no commits found in payload")
	}

	// Take the latest commit
	commit := payload.Commits[len(payload.Commits)-1]

	// Combine all file changes
	var files []string
	files = append(files, commit.Added...)
	files = append(files, commit.Removed...)
	files = append(files, commit.Modified...)

	// Extract branch name from ref
	branch := strings.TrimPrefix(payload.Ref, "refs/heads/")

	return &CommitData{
		Hash:       commit.ID,
		Message:    commit.Message,
		Author:     commit.Author.Name,
		Timestamp:  commit.Timestamp,
		Files:      files,
		Branch:     branch,
		Repository: payload.Repository.FullName,
	}, nil
}

// ExtractCommitMetadata extracts metadata from commit using Git commands
func ExtractCommitMetadata(commitHash string) (*CommitData, error) {
	if commitHash == "" {
		// Get the latest commit hash
		cmd := exec.Command("git", "rev-parse", "HEAD")
		output, err := cmd.Output()
		if err != nil {
			return nil, fmt.Errorf("failed to get latest commit hash: %w", err)
		}
		commitHash = strings.TrimSpace(string(output))
	}

	// Get commit message
	cmd := exec.Command("git", "log", "-1", "--pretty=format:%s", commitHash)
	messageOutput, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get commit message: %w", err)
	}
	message := strings.TrimSpace(string(messageOutput))

	// Get commit author
	cmd = exec.Command("git", "log", "-1", "--pretty=format:%an", commitHash)
	authorOutput, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get commit author: %w", err)
	}
	author := strings.TrimSpace(string(authorOutput))

	// Get commit timestamp
	cmd = exec.Command("git", "log", "-1", "--pretty=format:%ct", commitHash)
	timestampOutput, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get commit timestamp: %w", err)
	}

	// Parse timestamp
	timestamp, err := time.Parse("1136239445", strings.TrimSpace(string(timestampOutput)))
	if err != nil {
		timestamp = time.Now() // Fallback to current time
	}

	// Get changed files
	cmd = exec.Command("git", "show", "--name-only", "--pretty=format:", commitHash)
	filesOutput, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get changed files: %w", err)
	}

	filesStr := strings.TrimSpace(string(filesOutput))
	var files []string
	if filesStr != "" {
		files = strings.Split(filesStr, "\n")
	}

	// Get current branch
	cmd = exec.Command("git", "rev-parse", "--abbrev-ref", "HEAD")
	branchOutput, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to get current branch: %w", err)
	}
	branch := strings.TrimSpace(string(branchOutput))

	return &CommitData{
		Hash:      commitHash,
		Message:   message,
		Author:    author,
		Timestamp: timestamp,
		Files:     files,
		Branch:    branch,
	}, nil
}

// ValidateCommitData validates that commit data is complete and valid
func ValidateCommitData(data *CommitData) error {
	if data == nil {
		return fmt.Errorf("commit data is nil")
	}

	if data.Hash == "" {
		return fmt.Errorf("commit hash is required")
	}

	if data.Message == "" {
		return fmt.Errorf("commit message is required")
	}

	if data.Author == "" {
		return fmt.Errorf("commit author is required")
	}

	if len(data.Files) == 0 {
		return fmt.Errorf("at least one file change is required")
	}

	return nil
}
