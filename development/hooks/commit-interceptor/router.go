// development/hooks/commit-interceptor/router.go
package main

import (
    "fmt"
    "os/exec"
    "strings"
    "time"
)

// BranchDecision represents a routing decision for a commit
type BranchDecision struct {
    TargetBranch     string            `json:"target_branch"`
    CreateBranch     bool              `json:"create_branch"`
    MergeStrategy    string            `json:"merge_strategy"`    // auto, manual, fast-forward
    ConflictStrategy string            `json:"conflict_strategy"` // abort, resolve, skip
    Metadata         map[string]string `json:"metadata"`
    Reason           string            `json:"reason"`
    Confidence       float64           `json:"confidence"`
}

// BranchRouter handles routing decisions for commits
type BranchRouter struct {
    config *Config
}

// NewBranchRouter creates a new branch router
func NewBranchRouter(config *Config) *BranchRouter {
    return &BranchRouter{
        config: config,
    }
}

// RouteCommit makes routing decisions based on commit analysis
func (br *BranchRouter) RouteCommit(analysis *CommitAnalysis) (*BranchDecision, error) {
    decision := &BranchDecision{
        Metadata: make(map[string]string),
    }

    // Apply routing rules
    br.applyRoutingRules(analysis, decision)
    
    // Check for conflicts
    conflicts, err := br.checkPotentialConflicts(analysis, decision.TargetBranch)
    if err != nil {
        return nil, fmt.Errorf("failed to check conflicts: %w", err)
    }
    
    // Adjust strategy based on conflicts
    br.handleConflicts(decision, conflicts)
    
    // Set metadata
    br.setDecisionMetadata(analysis, decision)
    
    return decision, nil
}

// applyRoutingRules applies configured routing rules
func (br *BranchRouter) applyRoutingRules(analysis *CommitAnalysis, decision *BranchDecision) {
    changeType := analysis.ChangeType
    impact := analysis.Impact
    priority := analysis.Priority

    // Default routing logic
    switch changeType {
    case "feature":
        if br.shouldCreateFeatureBranch(analysis) {
            decision.TargetBranch = analysis.SuggestedBranch
            decision.CreateBranch = true
            decision.MergeStrategy = "manual"
            decision.Reason = "New feature requires separate branch"
        } else {
            decision.TargetBranch = "develop"
            decision.CreateBranch = false
            decision.MergeStrategy = "auto"
            decision.Reason = "Small feature can be merged directly to develop"
        }

    case "fix":
        if priority == "critical" || impact == "high" {
            decision.TargetBranch = analysis.SuggestedBranch
            decision.CreateBranch = true
            decision.MergeStrategy = "manual"
            decision.ConflictStrategy = "abort"
            decision.Reason = "Critical fix requires hotfix branch"
        } else {
            decision.TargetBranch = "develop"
            decision.CreateBranch = false
            decision.MergeStrategy = "auto"
            decision.Reason = "Regular fix can go to develop"
        }

    case "hotfix":
        decision.TargetBranch = analysis.SuggestedBranch
        decision.CreateBranch = true
        decision.MergeStrategy = "manual"
        decision.ConflictStrategy = "abort"
        decision.Reason = "Hotfix requires dedicated branch and careful merge"

    case "refactor":
        if impact == "high" {
            decision.TargetBranch = analysis.SuggestedBranch
            decision.CreateBranch = true
            decision.MergeStrategy = "manual"
            decision.Reason = "Large refactor needs separate branch for review"
        } else {
            decision.TargetBranch = "develop"
            decision.CreateBranch = false
            decision.MergeStrategy = "auto"
            decision.Reason = "Small refactor can go directly to develop"
        }

    case "docs", "style", "chore":
        decision.TargetBranch = "develop"
        decision.CreateBranch = false
        decision.MergeStrategy = "auto"
        decision.Reason = "Documentation/style changes go directly to develop"

    case "test":
        decision.TargetBranch = "develop"
        decision.CreateBranch = false
        decision.MergeStrategy = "auto"
        decision.Reason = "Test changes go directly to develop"

    default:
        decision.TargetBranch = "develop"
        decision.CreateBranch = false
        decision.MergeStrategy = "manual"
        decision.Reason = "Unknown change type, manual review required"
    }

    // Override with custom rules if configured
    br.applyCustomRules(analysis, decision)
}

// shouldCreateFeatureBranch determines if a feature needs its own branch
func (br *BranchRouter) shouldCreateFeatureBranch(analysis *CommitAnalysis) bool {
    // Create branch for medium/high impact features
    if analysis.Impact == "medium" || analysis.Impact == "high" {
        return true
    }
    
    // Create branch if many files are affected
    if len(analysis.CommitData.Files) > 3 {
        return true
    }
    
    // Create branch for low confidence predictions
    if analysis.Confidence < 0.7 {
        return true
    }
    
    return false
}

// applyCustomRules applies any custom routing rules from configuration
func (br *BranchRouter) applyCustomRules(analysis *CommitAnalysis, decision *BranchDecision) {
    // This would read from br.config.RoutingRules if available
    // For now, we implement some basic custom logic
    
    message := strings.ToLower(analysis.CommitData.Message)
    
    // Force manual review for security-related changes
    securityKeywords := []string{"security", "auth", "password", "token", "encrypt"}
    for _, keyword := range securityKeywords {
        if strings.Contains(message, keyword) {
            decision.MergeStrategy = "manual"
            decision.ConflictStrategy = "abort"
            decision.Reason += " (Security-related change requires manual review)"
            break
        }
    }
    
    // Database migration changes
    dbKeywords := []string{"migration", "schema", "database", "sql"}
    for _, keyword := range dbKeywords {
        if strings.Contains(message, keyword) {
            decision.CreateBranch = true
            decision.MergeStrategy = "manual"
            decision.Reason += " (Database change requires careful review)"
            break
        }
    }
}

// checkPotentialConflicts checks for potential merge conflicts
func (br *BranchRouter) checkPotentialConflicts(analysis *CommitAnalysis, targetBranch string) ([]string, error) {
    var conflicts []string
    
    // Check if target branch exists
    exists, err := br.branchExists(targetBranch)
    if err != nil {
        return nil, fmt.Errorf("failed to check if branch exists: %w", err)
    }
    
    if !exists && targetBranch != "develop" && targetBranch != "main" && targetBranch != "master" {
        // No conflicts if we're creating a new branch
        return conflicts, nil
    }
    
    // Check for file conflicts using git
    for _, file := range analysis.CommitData.Files {
        hasConflict, err := br.fileHasConflict(file, targetBranch)
        if err != nil {
            // Log error but continue checking other files
            continue
        }
        if hasConflict {
            conflicts = append(conflicts, file)
        }
    }
    
    return conflicts, nil
}

// branchExists checks if a branch exists
func (br *BranchRouter) branchExists(branchName string) (bool, error) {
    cmd := exec.Command("git", "show-ref", "--verify", "--quiet", "refs/heads/"+branchName)
    err := cmd.Run()
    if err != nil {
        // Branch doesn't exist
        return false, nil
    }
    return true, nil
}

// fileHasConflict checks if a file might have conflicts with target branch
func (br *BranchRouter) fileHasConflict(filename, targetBranch string) (bool, error) {
    // Get the file content from current branch
    cmd := exec.Command("git", "show", "HEAD:"+filename)
    currentContent, err := cmd.Output()
    if err != nil {
        // File might be new, no conflict
        return false, nil
    }
    
    // Get the file content from target branch
    cmd = exec.Command("git", "show", targetBranch+":"+filename)
    targetContent, err := cmd.Output()
    if err != nil {
        // File doesn't exist in target branch, no conflict
        return false, nil
    }
    
    // Simple heuristic: if contents are different, there might be a conflict
    if string(currentContent) != string(targetContent) {
        return true, nil
    }
    
    return false, nil
}

// handleConflicts adjusts decision based on potential conflicts
func (br *BranchRouter) handleConflicts(decision *BranchDecision, conflicts []string) {
    if len(conflicts) == 0 {
        return
    }
    
    // If there are conflicts, be more conservative
    if decision.MergeStrategy == "auto" {
        decision.MergeStrategy = "manual"
        decision.ConflictStrategy = "resolve"
        decision.Reason += fmt.Sprintf(" (Potential conflicts in %d files)", len(conflicts))
    }
    
    // Store conflict information in metadata
    decision.Metadata["conflicts"] = strings.Join(conflicts, ",")
    decision.Metadata["conflict_count"] = fmt.Sprintf("%d", len(conflicts))
}

// setDecisionMetadata sets additional metadata for the decision
func (br *BranchRouter) setDecisionMetadata(analysis *CommitAnalysis, decision *BranchDecision) {
    decision.Metadata["change_type"] = analysis.ChangeType
    decision.Metadata["impact"] = analysis.Impact
    decision.Metadata["priority"] = analysis.Priority
    decision.Metadata["file_count"] = fmt.Sprintf("%d", len(analysis.CommitData.Files))
    decision.Metadata["author"] = analysis.CommitData.Author
    decision.Metadata["commit_hash"] = analysis.CommitData.Hash
    decision.Metadata["timestamp"] = analysis.CommitData.Timestamp.Format(time.RFC3339)
    decision.Confidence = analysis.Confidence
}

// ValidateRoutingDecision validates that a routing decision is valid
func (br *BranchRouter) ValidateRoutingDecision(decision *BranchDecision) error {
    if decision.TargetBranch == "" {
        return fmt.Errorf("target branch cannot be empty")
    }
    
    validStrategies := map[string]bool{
        "auto":         true,
        "manual":       true,
        "fast-forward": true,
    }
    
    if !validStrategies[decision.MergeStrategy] {
        return fmt.Errorf("invalid merge strategy: %s", decision.MergeStrategy)
    }
    
    validConflictStrategies := map[string]bool{
        "abort":   true,
        "resolve": true,
        "skip":    true,
        "":        true, // Empty is allowed (default behavior)
    }
    
    if !validConflictStrategies[decision.ConflictStrategy] {
        return fmt.Errorf("invalid conflict strategy: %s", decision.ConflictStrategy)
    }
    
    return nil
}