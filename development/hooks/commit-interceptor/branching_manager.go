// development/hooks/commit-interceptor/branching_manager.go
package main

import (
    "fmt"
    "os/exec"
    "strings"
    "time"
)

// BranchingManager handles Git branching operations
type BranchingManager struct {
    config *Config
}

// NewBranchingManager creates a new branching manager
func NewBranchingManager(config *Config) *BranchingManager {
    return &BranchingManager{
        config: config,
    }
}

// ExecuteRouting executes the routing decision
func (bm *BranchingManager) ExecuteRouting(decision *BranchDecision) error {
    // En mode test, on simule les opérations Git
    if bm.config.TestMode {
        return bm.simulateGitOperations(decision)
    }

    // Validate the decision first
    router := NewBranchRouter(bm.config)
    if err := router.ValidateRoutingDecision(decision); err != nil {
        return fmt.Errorf("invalid routing decision: %w", err)
    }

    // Create branch if needed
    if decision.CreateBranch {
        if err := bm.createBranch(decision.TargetBranch); err != nil {
            return fmt.Errorf("failed to create branch: %w", err)
        }
    }

    // Switch to target branch
    if err := bm.switchToBranch(decision.TargetBranch); err != nil {
        return fmt.Errorf("failed to switch to branch: %w", err)
    }

    // Execute merge strategy
    switch decision.MergeStrategy {
    case "auto":
        return bm.executeAutoMerge(decision)
    case "manual":
        return bm.prepareManualMerge(decision)
    case "fast-forward":
        return bm.executeFastForward(decision)
    default:
        return fmt.Errorf("unknown merge strategy: %s", decision.MergeStrategy)
    }
}

// createBranch creates a new Git branch
func (bm *BranchingManager) createBranch(branchName string) error {
    // Check if branch already exists
    exists, err := bm.branchExists(branchName)
    if err != nil {
        return fmt.Errorf("failed to check if branch exists: %w", err)
    }

    if exists {
        return fmt.Errorf("branch %s already exists", branchName)
    }

    // Create the branch
    cmd := exec.Command("git", "checkout", "-b", branchName)
    output, err := cmd.CombinedOutput()
    if err != nil {
        return fmt.Errorf("failed to create branch %s: %w\nOutput: %s", branchName, err, string(output))
    }

    return nil
}

// switchToBranch switches to the specified branch
func (bm *BranchingManager) switchToBranch(branchName string) error {
    // Check if we're already on the target branch
    currentBranch, err := bm.getCurrentBranch()
    if err != nil {
        return fmt.Errorf("failed to get current branch: %w", err)
    }

    if currentBranch == branchName {
        return nil // Already on target branch
    }

    // Switch to the branch
    cmd := exec.Command("git", "checkout", branchName)
    output, err := cmd.CombinedOutput()
    if err != nil {
        return fmt.Errorf("failed to switch to branch %s: %w\nOutput: %s", branchName, err, string(output))
    }

    return nil
}

// getCurrentBranch returns the name of the current branch
func (bm *BranchingManager) getCurrentBranch() (string, error) {
    cmd := exec.Command("git", "rev-parse", "--abbrev-ref", "HEAD")
    output, err := cmd.Output()
    if err != nil {
        return "", fmt.Errorf("failed to get current branch: %w", err)
    }

    return strings.TrimSpace(string(output)), nil
}

// branchExists checks if a branch exists
func (bm *BranchingManager) branchExists(branchName string) (bool, error) {
    cmd := exec.Command("git", "show-ref", "--verify", "--quiet", "refs/heads/"+branchName)
    err := cmd.Run()
    return err == nil, nil
}

// executeAutoMerge performs automatic merge
func (bm *BranchingManager) executeAutoMerge(decision *BranchDecision) error {
    // For auto merge, we typically merge from current branch to target
    // This is a simplified implementation
    
    // Ensure working directory is clean
    if err := bm.ensureCleanWorkingDirectory(); err != nil {
        return fmt.Errorf("working directory not clean: %w", err)
    }

    // Add and commit current changes if any
    if err := bm.commitCurrentChanges(decision); err != nil {
        return fmt.Errorf("failed to commit current changes: %w", err)
    }

    // If we're already on the target branch, nothing more to do
    currentBranch, _ := bm.getCurrentBranch()
    if currentBranch == decision.TargetBranch {
        return nil
    }

    return nil
}

// prepareManualMerge prepares for manual merge
func (bm *BranchingManager) prepareManualMerge(decision *BranchDecision) error {
    // For manual merge, we just prepare the branch and let humans handle the merge
    
    // Commit current changes to the target branch
    if err := bm.commitCurrentChanges(decision); err != nil {
        return fmt.Errorf("failed to commit changes: %w", err)
    }

    // Log information for manual review
    fmt.Printf("Manual merge required for branch: %s\n", decision.TargetBranch)
    fmt.Printf("Reason: %s\n", decision.Reason)
    if conflicts, exists := decision.Metadata["conflicts"]; exists && conflicts != "" {
        fmt.Printf("Potential conflicts in files: %s\n", conflicts)
    }

    return nil
}

// executeFastForward performs fast-forward merge
func (bm *BranchingManager) executeFastForward(decision *BranchDecision) error {
    // Fast-forward merge is only possible if there are no divergent changes
    
    // Check if fast-forward is possible
    canFastForward, err := bm.canFastForward(decision.TargetBranch)
    if err != nil {
        return fmt.Errorf("failed to check fast-forward possibility: %w", err)
    }

    if !canFastForward {
        return fmt.Errorf("fast-forward merge not possible, branches have diverged")
    }

    // Perform fast-forward merge
    cmd := exec.Command("git", "merge", "--ff-only", decision.TargetBranch)
    output, err := cmd.CombinedOutput()
    if err != nil {
        return fmt.Errorf("fast-forward merge failed: %w\nOutput: %s", err, string(output))
    }

    return nil
}

// canFastForward checks if fast-forward merge is possible
func (bm *BranchingManager) canFastForward(targetBranch string) (bool, error) {
    // Check if target branch is ahead of current branch
    cmd := exec.Command("git", "merge-base", "--is-ancestor", "HEAD", targetBranch)
    err := cmd.Run()
    return err == nil, nil
}

// ensureCleanWorkingDirectory ensures the working directory is clean
func (bm *BranchingManager) ensureCleanWorkingDirectory() error {
    cmd := exec.Command("git", "status", "--porcelain")
    output, err := cmd.Output()
    if err != nil {
        return fmt.Errorf("failed to check git status: %w", err)
    }

    if len(strings.TrimSpace(string(output))) > 0 {
        return fmt.Errorf("working directory has uncommitted changes")
    }

    return nil
}

// commitCurrentChanges commits any current changes
func (bm *BranchingManager) commitCurrentChanges(decision *BranchDecision) error {
    // Check if there are any changes to commit
    cmd := exec.Command("git", "status", "--porcelain")
    output, err := cmd.Output()
    if err != nil {
        return fmt.Errorf("failed to check git status: %w", err)
    }

    if len(strings.TrimSpace(string(output))) == 0 {
        return nil // No changes to commit
    }

    // Add all changes
    cmd = exec.Command("git", "add", ".")
    if err := cmd.Run(); err != nil {
        return fmt.Errorf("failed to add changes: %w", err)
    }

    // Create commit message
    commitMessage := bm.generateCommitMessage(decision)

    // Commit changes
    cmd = exec.Command("git", "commit", "-m", commitMessage)
    output, err = cmd.CombinedOutput()
    if err != nil {
        return fmt.Errorf("failed to commit changes: %w\nOutput: %s", err, string(output))
    }

    return nil
}

// generateCommitMessage generates a commit message based on the decision
func (bm *BranchingManager) generateCommitMessage(decision *BranchDecision) string {
    changeType := decision.Metadata["change_type"]
    if changeType == "" {
        changeType = "chore"
    }

    timestamp := time.Now().Format("2006-01-02 15:04:05")
    
    return fmt.Sprintf("%s: Auto-routed commit to %s [%s]", changeType, decision.TargetBranch, timestamp)
}

// GetBranchInfo returns information about a branch
func (bm *BranchingManager) GetBranchInfo(branchName string) (*BranchInfo, error) {
    exists, err := bm.branchExists(branchName)
    if err != nil {
        return nil, err
    }

    if !exists {
        return nil, fmt.Errorf("branch %s does not exist", branchName)
    }

    // Get last commit hash
    cmd := exec.Command("git", "rev-parse", branchName)
    hashOutput, err := cmd.Output()
    if err != nil {
        return nil, fmt.Errorf("failed to get branch hash: %w", err)
    }

    // Get last commit message
    cmd = exec.Command("git", "log", "-1", "--pretty=format:%s", branchName)
    messageOutput, err := cmd.Output()
    if err != nil {
        return nil, fmt.Errorf("failed to get last commit message: %w", err)
    }

    return &BranchInfo{
        Name:          branchName,
        LastCommitHash: strings.TrimSpace(string(hashOutput)),
        LastCommitMessage: strings.TrimSpace(string(messageOutput)),
        Exists:        true,
    }, nil
}

// BranchInfo contains information about a Git branch
type BranchInfo struct {
    Name              string `json:"name"`
    LastCommitHash    string `json:"last_commit_hash"`
    LastCommitMessage string `json:"last_commit_message"`
    Exists            bool   `json:"exists"`
}

// ListBranches returns a list of all branches
func (bm *BranchingManager) ListBranches() ([]string, error) {
    cmd := exec.Command("git", "branch", "--format=%(refname:short)")
    output, err := cmd.Output()
    if err != nil {
        return nil, fmt.Errorf("failed to list branches: %w", err)
    }

    branches := strings.Split(strings.TrimSpace(string(output)), "\n")
    var result []string
    for _, branch := range branches {
        branch = strings.TrimSpace(branch)
        if branch != "" {
            result = append(result, branch)
        }
    }

    return result, nil
}

// DeleteBranch deletes a Git branch
func (bm *BranchingManager) DeleteBranch(branchName string) error {
    // Check if branch exists
    exists, err := bm.branchExists(branchName)
    if err != nil {
        return fmt.Errorf("failed to check if branch exists: %w", err)
    }

    if !exists {
        return fmt.Errorf("branch %s does not exist", branchName)
    }

    // Check if it's a protected branch
    for _, protected := range bm.config.Git.ProtectedBranches {
        if branchName == protected {
            return fmt.Errorf("cannot delete protected branch: %s", branchName)
        }
    }

    // Switch away from the branch if we're currently on it
    currentBranch, _ := bm.getCurrentBranch()
    if currentBranch == branchName {
        if err := bm.switchToBranch(bm.config.Git.DefaultBranch); err != nil {
            return fmt.Errorf("failed to switch away from branch: %w", err)
        }
    }

    // Delete the branch
    cmd := exec.Command("git", "branch", "-D", branchName)
    output, err := cmd.CombinedOutput()
    if err != nil {
        return fmt.Errorf("failed to delete branch %s: %w\nOutput: %s", branchName, err, string(output))
    }

    return nil
}

// simulateGitOperations simule les opérations Git en mode test
func (bm *BranchingManager) simulateGitOperations(decision *BranchDecision) error {
    fmt.Printf("MODE TEST: Simulation des opérations Git\n")
    fmt.Printf("  - Branche cible: %s\n", decision.TargetBranch)
    fmt.Printf("  - Créer branche: %t\n", decision.CreateBranch)
    fmt.Printf("  - Stratégie merge: %s\n", decision.MergeStrategy)
    fmt.Printf("  - Raison: %s\n", decision.Reason)
    
    // En mode test, on simule juste le succès
    return nil
}
