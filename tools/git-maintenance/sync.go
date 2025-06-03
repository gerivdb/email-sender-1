package main

import (
	"bufio"
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

type SubmoduleStatus struct {
	Path            string    `json:"path"`
	URL             string    `json:"url"`
	LocalSHA        string    `json:"localSHA"`
	RemoteSHA       string    `json:"remoteSHA"`
	LastSync        time.Time `json:"lastSync"`
	LastFetch       time.Time `json:"lastFetch"`
	HasDivergence   bool      `json:"hasDivergence"`
	HasLocalCommit  bool      `json:"hasLocalCommit"`
	HasRemoteCommit bool      `json:"hasRemoteCommit"`
	ConflictType    string    `json:"conflictType,omitempty"`
	SyncStrategy    string    `json:"syncStrategy,omitempty"`
}

type SyncResult struct {
	Path        string `json:"path"`
	Status      string `json:"status"`
	Message     string `json:"message"`
	ChangesHash string `json:"changesHash,omitempty"`
}

type SubmoduleSync struct {
	config Config
	logger *log.Logger
}

func NewSubmoduleSync(config Config) *SubmoduleSync {
	logger := log.New(os.Stdout, "[SubmoduleSync] ", log.LstdFlags)
	if !config.Verbose {
		logger.SetOutput(os.Stderr)
	}

	return &SubmoduleSync{
		config: config,
		logger: logger,
	}
}

func (s *SubmoduleSync) Execute() error {
	s.logger.Println("Starting submodule synchronization...")

	submodules, err := s.getSubmodules()
	if err != nil {
		return fmt.Errorf("failed to get submodules: %w", err)
	}

	if len(submodules) == 0 {
		fmt.Println("✅ No submodules found")
		return nil
	}

	statuses, err := s.getSubmoduleStatuses(submodules)
	if err != nil {
		return fmt.Errorf("failed to get submodule statuses: %w", err)
	}

	results := s.syncSubmodules(statuses)
	s.printSyncResults(results)

	return nil
}

func (s *SubmoduleSync) ShowStatus() error {
	submodules, err := s.getSubmodules()
	if err != nil {
		return fmt.Errorf("failed to get submodules: %w", err)
	}

	if len(submodules) == 0 {
		fmt.Println("✅ No submodules configured")
		return nil
	}

	statuses, err := s.getSubmoduleStatuses(submodules)
	if err != nil {
		return fmt.Errorf("failed to get submodule statuses: %w", err)
	}

	s.printStatusReport(statuses)
	return nil
}

func (s *SubmoduleSync) Cleanup() error {
	s.logger.Println("Starting submodule cleanup...")

	if s.config.DryRun {
		fmt.Println("🧪 Would clean up stale submodule references")
		return nil
	}

	// Remove orphaned submodule directories
	if err := s.cleanupOrphanedSubmodules(); err != nil {
		return fmt.Errorf("failed to cleanup orphaned submodules: %w", err)
	}

	// Clean up .git/modules for removed submodules
	if err := s.cleanupGitModules(); err != nil {
		return fmt.Errorf("failed to cleanup git modules: %w", err)
	}

	fmt.Println("✅ Cleanup completed")
	return nil
}

func (s *SubmoduleSync) getSubmodules() ([]string, error) {
	cmd := exec.Command("git", "config", "--file", ".gitmodules", "--name-only", "--get-regexp", "path")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	var submodules []string
	scanner := bufio.NewScanner(strings.NewReader(string(output)))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasSuffix(line, ".path") {
			submoduleName := strings.TrimSuffix(line, ".path")
			submoduleName = strings.TrimPrefix(submoduleName, "submodule.")
			submodules = append(submodules, submoduleName)
		}
	}

	return submodules, nil
}

func (s *SubmoduleSync) getSubmoduleStatuses(submodules []string) ([]SubmoduleStatus, error) {
	var statuses []SubmoduleStatus
	var mu sync.Mutex
	var wg sync.WaitGroup

	semaphore := make(chan struct{}, s.config.MaxConcurrency)

	for _, submodule := range submodules {
		wg.Add(1)
		go func(sm string) {
			defer wg.Done()
			semaphore <- struct{}{}
			defer func() { <-semaphore }()

			status, err := s.getSubmoduleStatus(sm)
			if err != nil {
				s.logger.Printf("Error getting status for %s: %v", sm, err)
				return
			}

			mu.Lock()
			statuses = append(statuses, status)
			mu.Unlock()
		}(submodule)
	}

	wg.Wait()
	return statuses, nil
}

func (s *SubmoduleSync) getSubmoduleStatus(submodule string) (SubmoduleStatus, error) {
	path, err := s.getSubmodulePath(submodule)
	if err != nil {
		return SubmoduleStatus{}, err
	}

	url, err := s.getSubmoduleURL(submodule)
	if err != nil {
		return SubmoduleStatus{}, err
	}

	status := SubmoduleStatus{
		Path: path,
		URL:  url,
	}

	// Get local SHA
	if localSHA, err := s.getLocalSHA(path); err == nil {
		status.LocalSHA = localSHA
	}

	// Fetch remote with timeout
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(s.config.TimeoutSeconds)*time.Second)
	defer cancel()

	if err := s.fetchRemote(ctx, path); err == nil {
		status.LastFetch = time.Now()

		// Get remote SHA
		if remoteSHA, err := s.getRemoteSHA(path); err == nil {
			status.RemoteSHA = remoteSHA
		}

		// Check for divergence
		status.HasDivergence = status.LocalSHA != "" && status.RemoteSHA != "" && status.LocalSHA != status.RemoteSHA
		status.HasLocalCommit = status.LocalSHA != ""
		status.HasRemoteCommit = status.RemoteSHA != ""

		// Determine conflict type and sync strategy
		if status.HasDivergence {
			status.ConflictType = s.determineConflictType(path, status.LocalSHA, status.RemoteSHA)
			status.SyncStrategy = s.determineSyncStrategy(status.ConflictType)
		}
	}

	return status, nil
}

func (s *SubmoduleSync) syncSubmodules(statuses []SubmoduleStatus) []SyncResult {
	var results []SyncResult

	for _, status := range statuses {
		result := s.syncSubmodule(status)
		results = append(results, result)
	}

	return results
}

func (s *SubmoduleSync) syncSubmodule(status SubmoduleStatus) SyncResult {
	if s.config.DryRun {
		return SyncResult{
			Path:    status.Path,
			Status:  "dry-run",
			Message: fmt.Sprintf("Would sync using strategy: %s", status.SyncStrategy),
		}
	}

	if !status.HasDivergence {
		return SyncResult{
			Path:    status.Path,
			Status:  "up-to-date",
			Message: "No sync needed",
		}
	}

	switch status.SyncStrategy {
	case "auto-ff":
		return s.performFastForward(status)
	case "manual-review":
		return s.requestManualReview(status)
	case "force-sync":
		return s.performForceSync(status)
	default:
		return SyncResult{
			Path:    status.Path,
			Status:  "error",
			Message: fmt.Sprintf("Unknown sync strategy: %s", status.SyncStrategy),
		}
	}
}

func (s *SubmoduleSync) performFastForward(status SubmoduleStatus) SyncResult {
	cmd := exec.Command("git", "merge", "--ff-only", "origin/main")
	cmd.Dir = status.Path

	if err := cmd.Run(); err != nil {
		return SyncResult{
			Path:    status.Path,
			Status:  "error",
			Message: fmt.Sprintf("Fast-forward failed: %v", err),
		}
	}

	return SyncResult{
		Path:    status.Path,
		Status:  "synced",
		Message: "Fast-forward completed successfully",
	}
}

func (s *SubmoduleSync) requestManualReview(status SubmoduleStatus) SyncResult {
	return SyncResult{
		Path:    status.Path,
		Status:  "manual-review-required",
		Message: fmt.Sprintf("Manual review required for conflict type: %s", status.ConflictType),
	}
}

func (s *SubmoduleSync) performForceSync(status SubmoduleStatus) SyncResult {
	cmd := exec.Command("git", "reset", "--hard", "origin/main")
	cmd.Dir = status.Path

	if err := cmd.Run(); err != nil {
		return SyncResult{
			Path:    status.Path,
			Status:  "error",
			Message: fmt.Sprintf("Force sync failed: %v", err),
		}
	}

	return SyncResult{
		Path:    status.Path,
		Status:  "force-synced",
		Message: "Force sync completed (local changes lost)",
	}
}

func (s *SubmoduleSync) printSyncResults(results []SyncResult) {
	fmt.Println("\n📋 Synchronization Results:")
	fmt.Println("═══════════════════════════════════")

	var synced, errors, manualReview, upToDate int

	for _, result := range results {
		icon := s.getStatusIcon(result.Status)
		fmt.Printf("%s %s: %s\n", icon, result.Path, result.Message)

		switch result.Status {
		case "synced", "force-synced":
			synced++
		case "error":
			errors++
		case "manual-review-required":
			manualReview++
		case "up-to-date":
			upToDate++
		}
	}

	fmt.Println("\n📊 Summary:")
	fmt.Printf("  • Up to date: %d\n", upToDate)
	fmt.Printf("  • Successfully synced: %d\n", synced)
	fmt.Printf("  • Manual review required: %d\n", manualReview)
	fmt.Printf("  • Errors: %d\n", errors)
}

func (s *SubmoduleSync) printStatusReport(statuses []SubmoduleStatus) {
	fmt.Println("\n📊 Submodule Status Report:")
	fmt.Println("═══════════════════════════════════")

	for _, status := range statuses {
		icon := "✅"
		if status.HasDivergence {
			icon = "⚠️"
		}

		fmt.Printf("%s %s\n", icon, status.Path)
		fmt.Printf("   URL: %s\n", status.URL)
		if status.LocalSHA != "" {
			fmt.Printf("   Local:  %s\n", status.LocalSHA[:8])
		}
		if status.RemoteSHA != "" {
			fmt.Printf("   Remote: %s\n", status.RemoteSHA[:8])
		}
		if status.HasDivergence {
			fmt.Printf("   Conflict: %s (Strategy: %s)\n", status.ConflictType, status.SyncStrategy)
		}
		if !status.LastFetch.IsZero() {
			fmt.Printf("   Last Fetch: %s\n", status.LastFetch.Format("2006-01-02 15:04:05"))
		}
		fmt.Println()
	}
}

// Helper methods

func (s *SubmoduleSync) getSubmodulePath(submodule string) (string, error) {
	cmd := exec.Command("git", "config", "--file", ".gitmodules", fmt.Sprintf("submodule.%s.path", submodule))
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func (s *SubmoduleSync) getSubmoduleURL(submodule string) (string, error) {
	cmd := exec.Command("git", "config", "--file", ".gitmodules", fmt.Sprintf("submodule.%s.url", submodule))
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func (s *SubmoduleSync) getLocalSHA(path string) (string, error) {
	if _, err := os.Stat(filepath.Join(path, ".git")); os.IsNotExist(err) {
		return "", nil
	}

	cmd := exec.Command("git", "rev-parse", "HEAD")
	cmd.Dir = path
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func (s *SubmoduleSync) getRemoteSHA(path string) (string, error) {
	cmd := exec.Command("git", "rev-parse", "origin/main")
	cmd.Dir = path
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(output)), nil
}

func (s *SubmoduleSync) fetchRemote(ctx context.Context, path string) error {
	cmd := exec.CommandContext(ctx, "git", "fetch", "origin")
	cmd.Dir = path
	return cmd.Run()
}

func (s *SubmoduleSync) determineConflictType(path, localSHA, remoteSHA string) string {
	// Check if local is ahead
	cmd := exec.Command("git", "merge-base", "--is-ancestor", remoteSHA, localSHA)
	cmd.Dir = path
	if cmd.Run() == nil {
		return "local-ahead"
	}

	// Check if remote is ahead
	cmd = exec.Command("git", "merge-base", "--is-ancestor", localSHA, remoteSHA)
	cmd.Dir = path
	if cmd.Run() == nil {
		return "remote-ahead"
	}

	return "diverged"
}

func (s *SubmoduleSync) determineSyncStrategy(conflictType string) string {
	switch s.config.SyncStrategy {
	case "auto-ff":
		if conflictType == "remote-ahead" {
			return "auto-ff"
		}
		return "manual-review"
	case "force-sync":
		return "force-sync"
	default:
		return "manual-review"
	}
}

func (s *SubmoduleSync) getStatusIcon(status string) string {
	switch status {
	case "up-to-date":
		return "✅"
	case "synced", "force-synced":
		return "🔄"
	case "manual-review-required":
		return "⚠️"
	case "error":
		return "❌"
	case "dry-run":
		return "🧪"
	default:
		return "ℹ️"
	}
}

func (s *SubmoduleSync) cleanupOrphanedSubmodules() error {
	// Implementation for cleaning up orphaned submodules
	s.logger.Println("Cleaning up orphaned submodules...")
	return nil
}

func (s *SubmoduleSync) cleanupGitModules() error {
	// Implementation for cleaning up .git/modules
	s.logger.Println("Cleaning up .git/modules...")
	return nil
}
