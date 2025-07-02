package development

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/branching-manager/interfaces"
)

// CommitEventProcessor handles commit events for automatic branch creation
type CommitEventProcessor struct {
	manager *BranchingManagerImpl
}

func (p *CommitEventProcessor) ProcessEvent(ctx context.Context, event interfaces.BranchingEvent) error {
	p.manager.logger.Printf("Processing commit event: %v", event.Context)

	// Extract commit information from context
	commitHash, ok := event.Context["commit_hash"].(string)
	if !ok {
		return fmt.Errorf("missing commit_hash in event context")
	}

	commitMessage, ok := event.Context["commit_message"].(string)
	if !ok {
		return fmt.Errorf("missing commit_message in event context")
	}

	// Analyze commit message for automatic branching triggers
	if shouldCreateBranch, branchType := p.analyzeCommitMessage(commitMessage); shouldCreateBranch {
		branchName := p.generateEventDrivenBranchName(branchType, commitHash)

		// Create new branch
		branchID, err := p.manager.createGitBranch(ctx, branchName, "main")
		if err != nil {
			return fmt.Errorf("failed to create event-driven branch: %w", err)
		}

		// Create branch record
		branch := &interfaces.Branch{
			ID:         branchID,
			Name:       branchName,
			BaseBranch: "main",
			CreatedAt:  time.Now(),
			UpdatedAt:  time.Now(),
			Status:     interfaces.BranchStatusActive,
			Metadata: map[string]string{
				"trigger_type":   "commit",
				"commit_hash":    commitHash,
				"commit_message": commitMessage,
				"branch_type":    branchType,
			},
			EventID: event.Context["event_id"].(string),
			Level:   2, // Level 2: Event-Driven
		}

		// Store branch in database
		if err := p.storeBranch(ctx, branch); err != nil {
			p.manager.logger.Printf("Warning: failed to store event-driven branch: %v", err)
		}

		p.manager.logger.Printf("Created event-driven branch %s for commit %s", branchName, commitHash[:8])
	}

	return nil
}

func (p *CommitEventProcessor) GetEventType() interfaces.EventType {
	return interfaces.EventTypeCommit
}

func (p *CommitEventProcessor) analyzeCommitMessage(message string) (bool, string) {
	// Simple keyword analysis for demonstration
	keywords := map[string]string{
		"fix":      "hotfix",
		"bug":      "bugfix",
		"feature":  "feature",
		"feat":     "feature",
		"refactor": "refactor",
		"docs":     "documentation",
		"test":     "testing",
		"security": "security",
		"perf":     "performance",
	}
	for keyword, branchType := range keywords {
		if strings.Contains(strings.ToLower(message), keyword) {
			return true, branchType
		}
	}

	return false, ""
}

func (p *CommitEventProcessor) generateEventDrivenBranchName(branchType, commitHash string) string {
	timestamp := time.Now().Format("20060102-1504")
	return fmt.Sprintf("auto-%s-%s-%s", branchType, commitHash[:8], timestamp)
}

func (p *CommitEventProcessor) storeBranch(ctx context.Context, branch *interfaces.Branch) error {
	if p.manager.storageManager == nil {
		return fmt.Errorf("storage manager not available")
	}

	data, err := json.Marshal(branch)
	if err != nil {
		return err
	}

	return p.manager.storageManager.Store(ctx, "branches", branch.ID, string(data))
}

// PushEventProcessor handles push events
type PushEventProcessor struct {
	manager *BranchingManagerImpl
}

func (p *PushEventProcessor) ProcessEvent(ctx context.Context, event interfaces.BranchingEvent) error {
	p.manager.logger.Printf("Processing push event: %v", event.Context)

	branchName, ok := event.Context["branch"].(string)
	if !ok {
		return fmt.Errorf("missing branch in event context")
	}

	commits, ok := event.Context["commits"].([]interface{})
	if !ok {
		return fmt.Errorf("missing commits in event context")
	}

	// Analyze push for automatic actions
	if p.shouldTriggerMergeAction(branchName, commits) {
		return p.handleAutoMerge(ctx, branchName, event)
	}

	if p.shouldTriggerBackupBranch(branchName, commits) {
		return p.createBackupBranch(ctx, branchName, event)
	}

	return nil
}

func (p *PushEventProcessor) GetEventType() interfaces.EventType {
	return interfaces.EventTypePush
}

func (p *PushEventProcessor) shouldTriggerMergeAction(branchName string, commits []interface{}) bool {
	// Logic to determine if auto-merge should be triggered
	return strings.Contains(branchName, "hotfix") && len(commits) > 0
}

func (p *PushEventProcessor) shouldTriggerBackupBranch(branchName string, commits []interface{}) bool {
	// Logic to determine if backup branch should be created
	return strings.Contains(branchName, "main") || strings.Contains(branchName, "master")
}

func (p *PushEventProcessor) handleAutoMerge(ctx context.Context, branchName string, event interfaces.BranchingEvent) error {
	p.manager.logger.Printf("Triggering auto-merge for branch %s", branchName)
	// Implementation for auto-merge logic
	return nil
}

func (p *PushEventProcessor) createBackupBranch(ctx context.Context, branchName string, event interfaces.BranchingEvent) error {
	backupName := fmt.Sprintf("backup-%s-%s", branchName, time.Now().Format("20060102-1504"))

	branchID, err := p.manager.createGitBranch(ctx, backupName, branchName)
	if err != nil {
		return fmt.Errorf("failed to create backup branch: %w", err)
	}

	p.manager.logger.Printf("Created backup branch %s (ID: %s)", backupName, branchID)
	return nil
}

// PullRequestEventProcessor handles pull request events
type PullRequestEventProcessor struct {
	manager *BranchingManagerImpl
}

func (p *PullRequestEventProcessor) ProcessEvent(ctx context.Context, event interfaces.BranchingEvent) error {
	p.manager.logger.Printf("Processing pull request event: %v", event.Context)

	action, ok := event.Context["action"].(string)
	if !ok {
		return fmt.Errorf("missing action in event context")
	}

	sourceBranch, ok := event.Context["source_branch"].(string)
	if !ok {
		return fmt.Errorf("missing source_branch in event context")
	}

	targetBranch, ok := event.Context["target_branch"].(string)
	if !ok {
		return fmt.Errorf("missing target_branch in event context")
	}

	switch action {
	case "opened":
		return p.handlePROpened(ctx, sourceBranch, targetBranch, event)
	case "merged":
		return p.handlePRMerged(ctx, sourceBranch, targetBranch, event)
	case "closed":
		return p.handlePRClosed(ctx, sourceBranch, targetBranch, event)
	default:
		p.manager.logger.Printf("Unhandled PR action: %s", action)
	}

	return nil
}

func (p *PullRequestEventProcessor) GetEventType() interfaces.EventType {
	return interfaces.EventTypePullRequest
}

func (p *PullRequestEventProcessor) handlePROpened(ctx context.Context, source, target string, event interfaces.BranchingEvent) error {
	// Create review branch if needed
	if p.shouldCreateReviewBranch(source, target) {
		reviewBranchName := fmt.Sprintf("review-%s-to-%s-%s", source, target, time.Now().Format("20060102-1504"))

		branchID, err := p.manager.createGitBranch(ctx, reviewBranchName, source)
		if err != nil {
			return fmt.Errorf("failed to create review branch: %w", err)
		}

		p.manager.logger.Printf("Created review branch %s (ID: %s)", reviewBranchName, branchID)
	}

	return nil
}

func (p *PullRequestEventProcessor) handlePRMerged(ctx context.Context, source, target string, event interfaces.BranchingEvent) error {
	// Auto-cleanup source branch if configured
	if p.manager.config.AutoArchiveEnabled && p.shouldCleanupSourceBranch(source) {
		return p.archiveSourceBranch(ctx, source)
	}

	return nil
}

func (p *PullRequestEventProcessor) handlePRClosed(ctx context.Context, source, target string, event interfaces.BranchingEvent) error {
	// Handle PR closure without merge
	p.manager.logger.Printf("PR from %s to %s was closed without merge", source, target)
	return nil
}

func (p *PullRequestEventProcessor) shouldCreateReviewBranch(source, target string) bool {
	// Logic to determine if review branch should be created
	return target == "main" || target == "master"
}

func (p *PullRequestEventProcessor) shouldCleanupSourceBranch(source string) bool {
	// Logic to determine if source branch should be cleaned up
	return !strings.Contains(source, "main") && !strings.Contains(source, "master") && !strings.Contains(source, "develop")
}

func (p *PullRequestEventProcessor) archiveSourceBranch(ctx context.Context, branchName string) error {
	p.manager.logger.Printf("Archiving source branch %s", branchName)
	// Implementation for archiving branch
	return nil
}

// TimerEventProcessor handles timer-based events
type TimerEventProcessor struct {
	manager *BranchingManagerImpl
}

func (p *TimerEventProcessor) ProcessEvent(ctx context.Context, event interfaces.BranchingEvent) error {
	p.manager.logger.Printf("Processing timer event: %v", event.Context)

	timerType, ok := event.Context["timer_type"].(string)
	if !ok {
		return fmt.Errorf("missing timer_type in event context")
	}

	switch timerType {
	case "session_cleanup":
		return p.handleSessionCleanup(ctx)
	case "snapshot_creation":
		return p.handleSnapshotCreation(ctx)
	case "branch_cleanup":
		return p.handleBranchCleanup(ctx)
	default:
		p.manager.logger.Printf("Unhandled timer type: %s", timerType)
	}

	return nil
}

func (p *TimerEventProcessor) GetEventType() interfaces.EventType {
	return interfaces.EventTypeTimer
}

func (p *TimerEventProcessor) handleSessionCleanup(ctx context.Context) error {
	p.manager.logger.Println("Running session cleanup")
	p.manager.checkExpiredSessions(ctx)
	return nil
}

func (p *TimerEventProcessor) handleSnapshotCreation(ctx context.Context) error {
	p.manager.logger.Println("Running snapshot creation")
	p.manager.createSnapshotsForActiveBranches(ctx)
	return nil
}

func (p *TimerEventProcessor) handleBranchCleanup(ctx context.Context) error {
	p.manager.logger.Println("Running branch cleanup")
	// Implementation for cleaning up old branches
	return nil
}

// SessionEventProcessor handles session lifecycle events
type SessionEventProcessor struct {
	manager *BranchingManagerImpl
}

func (p *SessionEventProcessor) ProcessEvent(ctx context.Context, event interfaces.BranchingEvent) error {
	p.manager.logger.Printf("Processing session event: %v", event.Type)

	switch event.Type {
	case interfaces.EventTypeSessionCreated:
		return p.handleSessionCreated(ctx, event)
	case interfaces.EventTypeSessionEnded:
		return p.handleSessionEnded(ctx, event)
	default:
		return fmt.Errorf("unsupported session event type: %v", event.Type)
	}
}

func (p *SessionEventProcessor) GetEventType() interfaces.EventType {
	return interfaces.EventTypeSessionCreated
}

func (p *SessionEventProcessor) handleSessionCreated(ctx context.Context, event interfaces.BranchingEvent) error {
	sessionID := event.Data.(*interfaces.Session).ID
	p.manager.logger.Printf("Session created: %s", sessionID)
	return nil
}

func (p *SessionEventProcessor) handleSessionEnded(ctx context.Context, event interfaces.BranchingEvent) error {
	sessionID := event.Data.(*interfaces.Session).ID
	p.manager.logger.Printf("Session ended: %s", sessionID)
	return nil
}

// BranchEventProcessor handles branch lifecycle events
type BranchEventProcessor struct {
	manager *BranchingManagerImpl
}

func (p *BranchEventProcessor) ProcessEvent(ctx context.Context, event interfaces.BranchingEvent) error {
	p.manager.logger.Printf("Processing branch event: %v", event.Type)

	switch event.Type {
	case interfaces.EventTypeBranchCreated:
		return p.handleBranchCreated(ctx, event)
	case interfaces.EventTypeBranchMerged:
		return p.handleBranchMerged(ctx, event)
	default:
		return fmt.Errorf("unsupported branch event type: %v", event.Type)
	}
}

func (p *BranchEventProcessor) GetEventType() interfaces.EventType {
	return interfaces.EventTypeBranchCreated
}

func (p *BranchEventProcessor) handleBranchCreated(ctx context.Context, event interfaces.BranchingEvent) error {
	p.manager.logger.Printf("Branch created: %v", event.Data)
	return nil
}

func (p *BranchEventProcessor) handleBranchMerged(ctx context.Context, event interfaces.BranchingEvent) error {
	p.manager.logger.Printf("Branch merged: %v", event.Data)
	return nil
}

// Utility functions are now using strings.Contains from the standard library
