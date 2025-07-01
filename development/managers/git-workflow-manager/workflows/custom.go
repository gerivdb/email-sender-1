package workflows

import (
	"context"
	"fmt"
	"regexp"
	"strings"

	"EMAIL_SENDER_1/managers/interfaces"
)

// CustomWorkflow implements a user-defined custom workflow
type CustomWorkflow struct {
	manager           interfaces.GitWorkflowManager
	config            map[string]interface{}
	branchPatterns    map[string]*regexp.Regexp
	mergeRules        map[string][]string
	protectedBranches []string
}

// NewCustomWorkflow creates a new custom workflow instance
func NewCustomWorkflow(manager interfaces.GitWorkflowManager, config map[string]interface{}) *CustomWorkflow {
	workflow := &CustomWorkflow{
		manager:           manager,
		config:            config,
		branchPatterns:    make(map[string]*regexp.Regexp),
		mergeRules:        make(map[string][]string),
		protectedBranches: []string{"main", "master"},
	}

	workflow.loadConfig()
	return workflow
}

// loadConfig loads configuration from the provided config map
func (c *CustomWorkflow) loadConfig() {
	// Load branch patterns
	if patterns, ok := c.config["branch_patterns"].(map[string]interface{}); ok {
		for name, pattern := range patterns {
			if patternStr, ok := pattern.(string); ok {
				if regex, err := regexp.Compile(patternStr); err == nil {
					c.branchPatterns[name] = regex
				}
			}
		}
	}

	// Load merge rules
	if rules, ok := c.config["merge_rules"].(map[string]interface{}); ok {
		for source, targets := range rules {
			if targetList, ok := targets.([]interface{}); ok {
				var stringTargets []string
				for _, target := range targetList {
					if targetStr, ok := target.(string); ok {
						stringTargets = append(stringTargets, targetStr)
					}
				}
				c.mergeRules[source] = stringTargets
			}
		}
	}

	// Load protected branches
	if protected, ok := c.config["protected_branches"].([]interface{}); ok {
		c.protectedBranches = []string{}
		for _, branch := range protected {
			if branchStr, ok := branch.(string); ok {
				c.protectedBranches = append(c.protectedBranches, branchStr)
			}
		}
	}
}

// CreateBranch creates a branch following custom rules
func (c *CustomWorkflow) CreateBranch(ctx context.Context, branchName, sourceBranch string) (*interfaces.SubBranchInfo, error) {
	// Validate branch name against custom patterns
	if err := c.ValidateBranchName(branchName); err != nil {
		return nil, err
	}

	// Validate source branch
	if sourceBranch == "" {
		sourceBranch = c.getDefaultSourceBranch(branchName)
	}

	subBranchInfo, err := c.manager.CreateSubBranch(ctx, branchName, sourceBranch, c.GetWorkflowType())
	if err != nil {
		return nil, err
	}
	return subBranchInfo, nil
}

// CreatePullRequest creates a pull request following custom merge rules
func (c *CustomWorkflow) CreatePullRequest(ctx context.Context, sourceBranch, targetBranch, title, description string) (*interfaces.PullRequestInfo, error) {
	// Validate merge rules
	if err := c.validateMergeRule(sourceBranch, targetBranch); err != nil {
		return nil, err
	}

	// The manager.CreatePullRequest method now takes individual string arguments
	// The prInfo struct is not passed directly to the manager method anymore
	// We still might want to construct it if other local methods use it, but the call to manager changes.

	pullRequestInfo, err := c.manager.CreatePullRequest(ctx, title, description, sourceBranch, targetBranch)
	if err != nil {
		return nil, err
	}
	return pullRequestInfo, nil
}

// ValidateBranchName validates branch name against custom patterns
func (c *CustomWorkflow) ValidateBranchName(branchName string) error {
	// Check if it's a protected branch
	for _, protected := range c.protectedBranches {
		if branchName == protected {
			return fmt.Errorf("cannot create branch with protected name '%s'", branchName)
		}
	}

	// If no custom patterns are defined, use basic validation
	if len(c.branchPatterns) == 0 {
		return c.basicValidation(branchName)
	}

	// Check against custom patterns
	for patternName, pattern := range c.branchPatterns {
		if pattern.MatchString(branchName) {
			// Branch name matches this pattern, validation passed
			return nil
		}
		_ = patternName // Avoid unused variable warning
	}

	return fmt.Errorf("branch name '%s' does not match any configured patterns", branchName)
}

// GetWorkflowType returns the workflow type
func (c *CustomWorkflow) GetWorkflowType() interfaces.WorkflowType {
	return interfaces.WorkflowTypeCustom
}

// GetBranchingStrategy returns the branching strategy description
func (c *CustomWorkflow) GetBranchingStrategy() string {
	if strategy, ok := c.config["description"].(string); ok {
		return strategy
	}
	return "Custom workflow with user-defined rules"
}

// GetMergeRules returns the configured merge rules
func (c *CustomWorkflow) GetMergeRules() map[string][]string {
	return c.mergeRules
}

// GetBranchPatterns returns the configured branch patterns
func (c *CustomWorkflow) GetBranchPatterns() map[string]string {
	patterns := make(map[string]string)
	for name, regex := range c.branchPatterns {
		patterns[name] = regex.String()
	}
	return patterns
}

// SetBranchPattern adds or updates a branch pattern
func (c *CustomWorkflow) SetBranchPattern(name, pattern string) error {
	regex, err := regexp.Compile(pattern)
	if err != nil {
		return fmt.Errorf("invalid regex pattern '%s': %w", pattern, err)
	}

	c.branchPatterns[name] = regex
	return nil
}

// SetMergeRule adds or updates a merge rule
func (c *CustomWorkflow) SetMergeRule(sourceBranch string, targetBranches []string) {
	c.mergeRules[sourceBranch] = targetBranches
}

// AddProtectedBranch adds a branch to the protected list
func (c *CustomWorkflow) AddProtectedBranch(branchName string) {
	for _, existing := range c.protectedBranches {
		if existing == branchName {
			return // Already protected
		}
	}
	c.protectedBranches = append(c.protectedBranches, branchName)
}

// RemoveProtectedBranch removes a branch from the protected list
func (c *CustomWorkflow) RemoveProtectedBranch(branchName string) {
	for i, existing := range c.protectedBranches {
		if existing == branchName {
			c.protectedBranches = append(c.protectedBranches[:i], c.protectedBranches[i+1:]...)
			return
		}
	}
}

// ExecuteCustomAction executes a custom workflow action
func (c *CustomWorkflow) ExecuteCustomAction(ctx context.Context, action string, params map[string]interface{}) error {
	// Custom actions can be defined by users
	switch action {
	case "sync_branches":
		return c.syncBranches(ctx, params)
	case "cleanup_old_branches":
		return c.cleanupOldBranches(ctx, params)
	case "enforce_naming":
		return c.enforceNaming(ctx, params)
	default:
		return fmt.Errorf("unknown custom action: %s", action)
	}
}

// Helper methods

func (c *CustomWorkflow) basicValidation(branchName string) error {
	if len(branchName) == 0 {
		return fmt.Errorf("branch name cannot be empty")
	}

	if len(branchName) > 250 {
		return fmt.Errorf("branch name too long (max 250 characters)")
	}

	// Check for invalid characters
	invalidChars := []string{" ", "\t", "\n", "..", "~", "^", ":", "?", "*", "[", "\\", "@", "{", "}"}
	for _, char := range invalidChars {
		if strings.Contains(branchName, char) {
			return fmt.Errorf("branch name contains invalid character '%s'", char)
		}
	}

	return nil
}

func (c *CustomWorkflow) getDefaultSourceBranch(branchName string) string {
	// Try to determine source branch based on branch name patterns
	for patternName, pattern := range c.branchPatterns {
		if pattern.MatchString(branchName) {
			// Look for source mapping in config
			if sources, ok := c.config["source_mapping"].(map[string]interface{}); ok {
				if source, ok := sources[patternName].(string); ok {
					return source
				}
			}
		}
	}

	// Default to main
	return "main"
}

func (c *CustomWorkflow) validateMergeRule(sourceBranch, targetBranch string) error {
	// If no merge rules are defined, allow all merges
	if len(c.mergeRules) == 0 {
		return nil
	}

	// Check if source branch has specific rules
	if allowedTargets, exists := c.mergeRules[sourceBranch]; exists {
		for _, allowed := range allowedTargets {
			if allowed == targetBranch {
				return nil
			}
		}
		return fmt.Errorf("merge from '%s' to '%s' is not allowed by workflow rules", sourceBranch, targetBranch)
	}

	// Check for wildcard rules
	if allowedTargets, exists := c.mergeRules["*"]; exists {
		for _, allowed := range allowedTargets {
			if allowed == targetBranch || allowed == "*" {
				return nil
			}
		}
		return fmt.Errorf("merge to '%s' is not allowed by workflow rules", targetBranch)
	}

	return nil
}

func (c *CustomWorkflow) getBranchLabels(branchName string) []string {
	labels := []string{"custom-workflow"}

	// Add labels based on branch patterns
	for patternName, pattern := range c.branchPatterns {
		if pattern.MatchString(branchName) {
			labels = append(labels, patternName)
		}
	}

	return labels
}

func (c *CustomWorkflow) syncBranches(ctx context.Context, params map[string]interface{}) error {
	// Custom action to sync branches
	// Implementation would depend on specific requirements
	return nil
}

func (c *CustomWorkflow) cleanupOldBranches(ctx context.Context, params map[string]interface{}) error {
	// Custom action to cleanup old branches
	// Implementation would depend on specific requirements
	return nil
}

func (c *CustomWorkflow) enforceNaming(ctx context.Context, params map[string]interface{}) error {
	// Custom action to enforce naming conventions
	// Implementation would depend on specific requirements
	return nil
}
