// Package validation provides comprehensive consistency validation for planning ecosystem sync
package validation

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"sync"
	"time"
)

// ValidationStatus represents the current status of a validation operation
type ValidationStatus string

const (
	ValidationPending   ValidationStatus = "pending"
	ValidationRunning   ValidationStatus = "running"
	ValidationCompleted ValidationStatus = "completed"
	ValidationFailed    ValidationStatus = "failed"
	ValidationSkipped   ValidationStatus = "skipped"
)

// ValidationSeverity defines the severity levels for validation issues
type ValidationSeverity string

const (
	SeverityInfo     ValidationSeverity = "info"
	SeverityWarning  ValidationSeverity = "warning"
	SeverityError    ValidationSeverity = "error"
	SeverityCritical ValidationSeverity = "critical"
)

// ValidationConfig holds configuration for consistency validation
type ValidationConfig struct {
	StrictMode         bool              `yaml:"strict_mode" json:"strict_mode"`
	ToleranceThreshold float64           `yaml:"tolerance_threshold" json:"tolerance_threshold"`
	ValidationRules    []string          `yaml:"validation_rules" json:"validation_rules"`
	ReportFormat       string            `yaml:"report_format" json:"report_format"`
	AutoFix            bool              `yaml:"auto_fix" json:"auto_fix"`
	MaxConcurrency     int               `yaml:"max_concurrency" json:"max_concurrency"`
	TimeoutDuration    time.Duration     `yaml:"timeout_duration" json:"timeout_duration"`
	CacheResults       bool              `yaml:"cache_results" json:"cache_results"`
	EnableMetrics      bool              `yaml:"enable_metrics" json:"enable_metrics"`
}

// ValidationResult represents the result of a consistency validation
type ValidationResult struct {
	PlanID         string               `json:"plan_id"`
	Status         ValidationStatus     `json:"status"`
	Issues         []ValidationIssue    `json:"issues"`
	Score          float64              `json:"score"`
	Timestamp      time.Time            `json:"timestamp"`
	Duration       time.Duration        `json:"duration"`
	RulesExecuted  int                  `json:"rules_executed"`
	RulesPassed    int                  `json:"rules_passed"`
	RulesFailed    int                  `json:"rules_failed"`
	AutoFixesApplied int               `json:"auto_fixes_applied"`
	Metadata       map[string]interface{} `json:"metadata"`
}

// ValidationIssue represents a specific validation issue found
type ValidationIssue struct {
	ID          string             `json:"id"`
	Type        string             `json:"type"`
	Severity    ValidationSeverity `json:"severity"`
	Message     string             `json:"message"`
	Location    string             `json:"location"`
	Suggestion  string             `json:"suggestion"`
	AutoFixable bool               `json:"auto_fixable"`
	RuleName    string             `json:"rule_name"`
	Timestamp   time.Time          `json:"timestamp"`
	Context     map[string]interface{} `json:"context,omitempty"`
}

// ValidationStats tracks performance and usage statistics
type ValidationStats struct {
	TotalValidations     int           `json:"total_validations"`
	SuccessfulValidations int           `json:"successful_validations"`
	FailedValidations    int           `json:"failed_validations"`
	AverageScore         float64       `json:"average_score"`
	AverageDuration      time.Duration `json:"average_duration"`
	TotalIssuesFound     int           `json:"total_issues_found"`
	TotalAutoFixes       int           `json:"total_auto_fixes"`
	LastValidation       time.Time     `json:"last_validation"`
	mu                   sync.RWMutex
}

// ValidationRule defines the interface for validation rules
type ValidationRule interface {
	Name() string
	Description() string
	Severity() ValidationSeverity
	Validate(ctx context.Context, planID string, data interface{}) ([]ValidationIssue, error)
	CanAutoFix() bool
	AutoFix(ctx context.Context, issue ValidationIssue) error
}

// OperationOptions represents options for validation operations
type OperationOptions struct {
	Target      string                 `json:"target"`
	Parameters  map[string]interface{} `json:"parameters"`
	Timeout     time.Duration          `json:"timeout"`
	Concurrent  bool                   `json:"concurrent"`
	DryRun      bool                   `json:"dry_run"`
	SkipCache   bool                   `json:"skip_cache"`
}

// ConsistencyValidator provides comprehensive consistency validation
type ConsistencyValidator struct {
	Config      *ValidationConfig
	Logger      *log.Logger
	Stats       *ValidationStats
	Rules       []ValidationRule
	ResultCache map[string]*ValidationResult
	mu          sync.RWMutex
}

// NewConsistencyValidator creates a new ConsistencyValidator instance
func NewConsistencyValidator(config *ValidationConfig, logger *log.Logger) *ConsistencyValidator {
	if config == nil {
		config = &ValidationConfig{
			StrictMode:         false,
			ToleranceThreshold: 0.8,
			ReportFormat:       "json",
			AutoFix:            false,
			MaxConcurrency:     4,
			TimeoutDuration:    5 * time.Minute,
			CacheResults:       true,
			EnableMetrics:      true,
		}
	}

	if logger == nil {
		logger = log.New(log.Writer(), "[ConsistencyValidator] ", log.LstdFlags|log.Lshortfile)
	}

	return &ConsistencyValidator{
		Config:      config,
		Logger:      logger,
		Stats:       &ValidationStats{},
		Rules:       make([]ValidationRule, 0),
		ResultCache: make(map[string]*ValidationResult),
	}
}

// AddRule adds a validation rule to the validator
func (cv *ConsistencyValidator) AddRule(rule ValidationRule) {
	cv.mu.Lock()
	defer cv.mu.Unlock()
	
	cv.Rules = append(cv.Rules, rule)
	cv.Logger.Printf("Added validation rule: %s (%s)", rule.Name(), rule.Description())
}

// Execute performs consistency validation following ToolkitOperation interface
func (cv *ConsistencyValidator) Execute(ctx context.Context, options *OperationOptions) error {
	cv.Logger.Printf("🔍 Starting consistency validation for: %s", options.Target)
	
	startTime := time.Now()
	
	// Check cache first if enabled
	if cv.Config.CacheResults && !options.SkipCache {
		if cached := cv.getCachedResult(options.Target); cached != nil {
			cv.Logger.Printf("✅ Using cached validation result for: %s", options.Target)
			return nil
		}
	}
	
	result := &ValidationResult{
		PlanID:    options.Target,
		Status:    ValidationRunning,
		Timestamp: startTime,
		Issues:    make([]ValidationIssue, 0),
		Metadata:  make(map[string]interface{}),
	}
	
	// Set timeout context
	validationCtx := ctx
	if cv.Config.TimeoutDuration > 0 {
		var cancel context.CancelFunc
		validationCtx, cancel = context.WithTimeout(ctx, cv.Config.TimeoutDuration)
		defer cancel()
	}
	
	// Execute validation rules
	if options.Concurrent && cv.Config.MaxConcurrency > 1 {
		err := cv.executeRulesConcurrently(validationCtx, options.Target, result)
		if err != nil {
			result.Status = ValidationFailed
			cv.updateStats(result)
			return fmt.Errorf("concurrent validation failed: %w", err)
		}
	} else {
		err := cv.executeRulesSequentially(validationCtx, options.Target, result)
		if err != nil {
			result.Status = ValidationFailed
			cv.updateStats(result)
			return fmt.Errorf("sequential validation failed: %w", err)
		}
	}
	
	// Calculate final results
	result.Score = cv.calculateConsistencyScore(result.Issues)
	result.Status = cv.determineStatus(result.Score)
	result.Duration = time.Since(startTime)
	
	// Apply auto-fixes if enabled and in non-dry-run mode
	if cv.Config.AutoFix && !options.DryRun {
		result.AutoFixesApplied = cv.applyAutoFixes(validationCtx, result.Issues)
	}
	
	// Cache result if enabled
	if cv.Config.CacheResults {
		cv.cacheResult(options.Target, result)
	}
	
	// Update statistics
	cv.updateStats(result)
	
	cv.Logger.Printf("✅ Validation completed for %s: Score=%.2f, Issues=%d, Duration=%v", 
		options.Target, result.Score, len(result.Issues), result.Duration)
	
	return nil
}

// executeRulesSequentially executes validation rules one by one
func (cv *ConsistencyValidator) executeRulesSequentially(ctx context.Context, planID string, result *ValidationResult) error {
	for _, rule := range cv.Rules {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}
		
		cv.Logger.Printf("Executing rule: %s", rule.Name())
		
		issues, err := rule.Validate(ctx, planID, nil)
		if err != nil {
			cv.Logger.Printf("⚠️ Rule %s failed: %v", rule.Name(), err)
			result.RulesFailed++
			continue
		}
		
		result.Issues = append(result.Issues, issues...)
		result.RulesExecuted++
		if len(issues) == 0 {
			result.RulesPassed++
		}
	}
	
	return nil
}

// executeRulesConcurrently executes validation rules concurrently
func (cv *ConsistencyValidator) executeRulesConcurrently(ctx context.Context, planID string, result *ValidationResult) error {
	semaphore := make(chan struct{}, cv.Config.MaxConcurrency)
	var wg sync.WaitGroup
	var mu sync.Mutex
	
	for _, rule := range cv.Rules {
		wg.Add(1)
		go func(r ValidationRule) {
			defer wg.Done()
			
			semaphore <- struct{}{}
			defer func() { <-semaphore }()
			
			select {
			case <-ctx.Done():
				return
			default:
			}
			
			cv.Logger.Printf("Executing rule concurrently: %s", r.Name())
			
			issues, err := r.Validate(ctx, planID, nil)
			
			mu.Lock()
			defer mu.Unlock()
			
			if err != nil {
				cv.Logger.Printf("⚠️ Rule %s failed: %v", r.Name(), err)
				result.RulesFailed++
				return
			}
			
			result.Issues = append(result.Issues, issues...)
			result.RulesExecuted++
			if len(issues) == 0 {
				result.RulesPassed++
			}
		}(rule)
	}
	
	wg.Wait()
	return nil
}

// calculateConsistencyScore calculates a consistency score based on validation issues
func (cv *ConsistencyValidator) calculateConsistencyScore(issues []ValidationIssue) float64 {
	if len(issues) == 0 {
		return 1.0
	}
	
	totalWeight := 0.0
	penaltyWeight := 0.0
	
	for _, issue := range issues {
		weight := cv.getSeverityWeight(issue.Severity)
		totalWeight += weight
		penaltyWeight += weight
	}
	
	// Base score starts at 1.0 and decreases based on severity-weighted issues
	maxPossibleWeight := float64(len(issues)) * cv.getSeverityWeight(SeverityCritical)
	if maxPossibleWeight == 0 {
		return 1.0
	}
	
	score := 1.0 - (penaltyWeight / maxPossibleWeight)
	if score < 0 {
		score = 0
	}
	
	return score
}

// getSeverityWeight returns the weight for a given severity level
func (cv *ConsistencyValidator) getSeverityWeight(severity ValidationSeverity) float64 {
	switch severity {
	case SeverityInfo:
		return 0.1
	case SeverityWarning:
		return 0.3
	case SeverityError:
		return 0.7
	case SeverityCritical:
		return 1.0
	default:
		return 0.5
	}
}

// determineStatus determines validation status based on score and configuration
func (cv *ConsistencyValidator) determineStatus(score float64) ValidationStatus {
	if score >= cv.Config.ToleranceThreshold {
		return ValidationCompleted
	}
	
	if cv.Config.StrictMode && score < 1.0 {
		return ValidationFailed
	}
	
	return ValidationCompleted
}

// applyAutoFixes applies automatic fixes for auto-fixable issues
func (cv *ConsistencyValidator) applyAutoFixes(ctx context.Context, issues []ValidationIssue) int {
	fixesApplied := 0
	
	for _, issue := range issues {
		if !issue.AutoFixable {
			continue
		}
		
		// Find the rule that can fix this issue
		for _, rule := range cv.Rules {
			if rule.Name() == issue.RuleName && rule.CanAutoFix() {
				err := rule.AutoFix(ctx, issue)
				if err != nil {
					cv.Logger.Printf("⚠️ Auto-fix failed for issue %s: %v", issue.ID, err)
					continue
				}
				
				cv.Logger.Printf("🔧 Auto-fix applied for issue: %s", issue.Message)
				fixesApplied++
				break
			}
		}
	}
	
	return fixesApplied
}

// getCachedResult retrieves a cached validation result
func (cv *ConsistencyValidator) getCachedResult(planID string) *ValidationResult {
	cv.mu.RLock()
	defer cv.mu.RUnlock()
	
	if result, exists := cv.ResultCache[planID]; exists {
		// Check if cache is still valid (within 1 hour)
		if time.Since(result.Timestamp) < time.Hour {
			return result
		}
		// Remove expired cache entry
		delete(cv.ResultCache, planID)
	}
	
	return nil
}

// cacheResult stores a validation result in cache
func (cv *ConsistencyValidator) cacheResult(planID string, result *ValidationResult) {
	cv.mu.Lock()
	defer cv.mu.Unlock()
	
	cv.ResultCache[planID] = result
}

// updateStats updates validation statistics
func (cv *ConsistencyValidator) updateStats(result *ValidationResult) {
	cv.Stats.mu.Lock()
	defer cv.Stats.mu.Unlock()
	
	cv.Stats.TotalValidations++
	cv.Stats.LastValidation = result.Timestamp
	cv.Stats.TotalIssuesFound += len(result.Issues)
	cv.Stats.TotalAutoFixes += result.AutoFixesApplied
	
	if result.Status == ValidationCompleted {
		cv.Stats.SuccessfulValidations++
	} else if result.Status == ValidationFailed {
		cv.Stats.FailedValidations++
	}
	
	// Update average score
	if cv.Stats.TotalValidations > 0 {
		cv.Stats.AverageScore = (cv.Stats.AverageScore*float64(cv.Stats.TotalValidations-1) + result.Score) / float64(cv.Stats.TotalValidations)
	}
	
	// Update average duration
	if cv.Stats.TotalValidations > 0 {
		cv.Stats.AverageDuration = time.Duration(
			(int64(cv.Stats.AverageDuration)*int64(cv.Stats.TotalValidations-1) + int64(result.Duration)) / int64(cv.Stats.TotalValidations),
		)
	}
}

// GetStats returns current validation statistics
func (cv *ConsistencyValidator) GetStats() ValidationStats {
	cv.Stats.mu.RLock()
	defer cv.Stats.mu.RUnlock()
	
	return *cv.Stats
}

// GenerateReport generates a validation report in the specified format
func (cv *ConsistencyValidator) GenerateReport(result *ValidationResult) ([]byte, error) {
	switch cv.Config.ReportFormat {
	case "json":
		return json.MarshalIndent(result, "", "  ")
	case "text":
		return cv.generateTextReport(result), nil
	default:
		return json.MarshalIndent(result, "", "  ")
	}
}

// generateTextReport generates a human-readable text report
func (cv *ConsistencyValidator) generateTextReport(result *ValidationResult) []byte {
	report := fmt.Sprintf("Consistency Validation Report\n")
	report += fmt.Sprintf("=============================\n\n")
	report += fmt.Sprintf("Plan ID: %s\n", result.PlanID)
	report += fmt.Sprintf("Status: %s\n", result.Status)
	report += fmt.Sprintf("Score: %.2f/1.00\n", result.Score)
	report += fmt.Sprintf("Duration: %v\n", result.Duration)
	report += fmt.Sprintf("Rules Executed: %d\n", result.RulesExecuted)
	report += fmt.Sprintf("Rules Passed: %d\n", result.RulesPassed)
	report += fmt.Sprintf("Rules Failed: %d\n", result.RulesFailed)
	report += fmt.Sprintf("Total Issues: %d\n", len(result.Issues))
	report += fmt.Sprintf("Auto-fixes Applied: %d\n\n", result.AutoFixesApplied)
	
	if len(result.Issues) > 0 {
		report += "Issues Found:\n"
		report += "=============\n\n"
		
		for i, issue := range result.Issues {
			report += fmt.Sprintf("%d. [%s] %s\n", i+1, issue.Severity, issue.Message)
			report += fmt.Sprintf("   Location: %s\n", issue.Location)
			report += fmt.Sprintf("   Rule: %s\n", issue.RuleName)
			if issue.Suggestion != "" {
				report += fmt.Sprintf("   Suggestion: %s\n", issue.Suggestion)
			}
			if issue.AutoFixable {
				report += "   Auto-fixable: Yes\n"
			}
			report += "\n"
		}
	}
	
	return []byte(report)
}

// ClearCache clears the validation result cache
func (cv *ConsistencyValidator) ClearCache() {
	cv.mu.Lock()
	defer cv.mu.Unlock()
	
	cv.ResultCache = make(map[string]*ValidationResult)
	cv.Logger.Printf("🗑️ Validation cache cleared")
}

// Name returns the name of this operation
func (cv *ConsistencyValidator) Name() string {
	return "ConsistencyValidator"
}

// Description returns a description of this operation
func (cv *ConsistencyValidator) Description() string {
	return "Validates consistency between Markdown plans and dynamic system data"
}

// Version returns the version of this operation
func (cv *ConsistencyValidator) Version() string {
	return "3.0.0"
}
