package validation

import (
	"context"
	"encoding/json"
	"testing"
	"time"
	"log"
	"os"
)

func TestConsistencyValidatorCreation(t *testing.T) {
	// Test creation with default config
	validator := NewConsistencyValidator(nil, nil)
	if validator == nil {
		t.Fatal("Expected validator to be created, got nil")
	}

	if validator.Config == nil {
		t.Fatal("Expected default config to be created")
	}

	if validator.Logger == nil {
		t.Fatal("Expected default logger to be created")
	}

	if validator.Stats == nil {
		t.Fatal("Expected stats to be initialized")
	}

	// Test creation with custom config
	config := &ValidationConfig{
		StrictMode:         true,
		ToleranceThreshold: 0.9,
		ReportFormat:       "json",
		AutoFix:            true,
		MaxConcurrency:     8,
		TimeoutDuration:    10 * time.Minute,
		CacheResults:       false,
		EnableMetrics:      true,
	}

	logger := log.New(os.Stdout, "[TEST] ", log.LstdFlags)
	validator2 := NewConsistencyValidator(config, logger)

	if validator2.Config.StrictMode != true {
		t.Errorf("Expected StrictMode to be true, got %v", validator2.Config.StrictMode)
	}

	if validator2.Config.ToleranceThreshold != 0.9 {
		t.Errorf("Expected ToleranceThreshold to be 0.9, got %f", validator2.Config.ToleranceThreshold)
	}

	if validator2.Config.MaxConcurrency != 8 {
		t.Errorf("Expected MaxConcurrency to be 8, got %d", validator2.Config.MaxConcurrency)
	}
}

func TestAddRule(t *testing.T) {
	validator := NewConsistencyValidator(nil, nil)

	// Test adding metadata rule
	metadataRule := NewMetadataRule()
	validator.AddRule(metadataRule)

	if len(validator.Rules) != 1 {
		t.Errorf("Expected 1 rule, got %d", len(validator.Rules))
	}

	if validator.Rules[0].Name() != "metadata_consistency" {
		t.Errorf("Expected rule name to be 'metadata_consistency', got %s", validator.Rules[0].Name())
	}

	// Test adding multiple rules
	taskRule := NewTaskRule()
	structureRule := NewStructureRule()
	validator.AddRule(taskRule)
	validator.AddRule(structureRule)

	if len(validator.Rules) != 3 {
		t.Errorf("Expected 3 rules, got %d", len(validator.Rules))
	}
}

func TestExecuteValidation(t *testing.T) {
	validator := NewConsistencyValidator(nil, nil)

	// Add test rules
	validator.AddRule(NewMetadataRule())
	validator.AddRule(NewTaskRule())

	// Test execution
	ctx := context.Background()
	options := &OperationOptions{
		Target:     "test-plan-v55",
		Parameters: map[string]interface{}{},
		Timeout:    30 * time.Second,
		Concurrent: false,
		DryRun:     false,
		SkipCache:  false,
	}

	err := validator.Execute(ctx, options)
	if err != nil {
		t.Errorf("Validation execution failed: %v", err)
	}

	// Check that stats were updated
	stats := validator.GetStats()
	if stats.TotalValidations != 1 {
		t.Errorf("Expected 1 validation, got %d", stats.TotalValidations)
	}

	if stats.LastValidation.IsZero() {
		t.Error("Expected LastValidation to be set")
	}
}

func TestExecuteConcurrentValidation(t *testing.T) {
	config := &ValidationConfig{
		MaxConcurrency: 4,
		TimeoutDuration: 30 * time.Second,
	}
	validator := NewConsistencyValidator(config, nil)

	// Add multiple rules
	validator.AddRule(NewMetadataRule())
	validator.AddRule(NewTaskRule())
	validator.AddRule(NewStructureRule())
	validator.AddRule(NewContentIntegrityRule())

	ctx := context.Background()
	options := &OperationOptions{
		Target:     "test-plan-concurrent",
		Concurrent: true,
		DryRun:     false,
		SkipCache:  true,
	}

	err := validator.Execute(ctx, options)
	if err != nil {
		t.Errorf("Concurrent validation execution failed: %v", err)
	}

	stats := validator.GetStats()
	if stats.TotalValidations != 1 {
		t.Errorf("Expected 1 validation, got %d", stats.TotalValidations)
	}
}

func TestCalculateConsistencyScore(t *testing.T) {
	validator := NewConsistencyValidator(nil, nil)

	// Test perfect score (no issues)
	score := validator.calculateConsistencyScore([]ValidationIssue{})
	if score != 1.0 {
		t.Errorf("Expected perfect score of 1.0, got %f", score)
	}

	// Test with different severity issues
	issues := []ValidationIssue{
		{Severity: SeverityInfo, Message: "Info issue"},
		{Severity: SeverityWarning, Message: "Warning issue"},
		{Severity: SeverityError, Message: "Error issue"},
	}

	score = validator.calculateConsistencyScore(issues)
	if score >= 1.0 || score <= 0.0 {
		t.Errorf("Expected score between 0 and 1, got %f", score)
	}

	// Test with critical issues
	criticalIssues := []ValidationIssue{
		{Severity: SeverityCritical, Message: "Critical issue 1"},
		{Severity: SeverityCritical, Message: "Critical issue 2"},
	}

	criticalScore := validator.calculateConsistencyScore(criticalIssues)
	if criticalScore >= score {
		t.Errorf("Expected critical score (%f) to be lower than mixed score (%f)", criticalScore, score)
	}
}

func TestDetermineStatus(t *testing.T) {
	// Test with default config
	config := &ValidationConfig{
		StrictMode:         false,
		ToleranceThreshold: 0.8,
	}
	validator := NewConsistencyValidator(config, nil)

	// Test passing score
	status := validator.determineStatus(0.9)
	if status != ValidationCompleted {
		t.Errorf("Expected ValidationCompleted, got %s", status)
	}

	// Test failing score
	status = validator.determineStatus(0.7)
	if status != ValidationCompleted {
		t.Errorf("Expected ValidationCompleted (non-strict mode), got %s", status)
	}

	// Test strict mode
	validator.Config.StrictMode = true
	status = validator.determineStatus(0.95)
	if status != ValidationFailed {
		t.Errorf("Expected ValidationFailed (strict mode with imperfect score), got %s", status)
	}

	status = validator.determineStatus(1.0)
	if status != ValidationCompleted {
		t.Errorf("Expected ValidationCompleted (strict mode with perfect score), got %s", status)
	}
}

func TestCacheOperations(t *testing.T) {
	config := &ValidationConfig{
		CacheResults: true,
	}
	validator := NewConsistencyValidator(config, nil)

	planID := "test-cache-plan"
	result := &ValidationResult{
		PlanID:    planID,
		Status:    ValidationCompleted,
		Score:     0.95,
		Timestamp: time.Now(),
		Issues:    []ValidationIssue{},
	}

	// Test caching
	validator.cacheResult(planID, result)
	
	// Test cache retrieval
	cached := validator.getCachedResult(planID)
	if cached == nil {
		t.Error("Expected cached result, got nil")
	}

	if cached.PlanID != planID {
		t.Errorf("Expected cached plan ID %s, got %s", planID, cached.PlanID)
	}

	if cached.Score != 0.95 {
		t.Errorf("Expected cached score 0.95, got %f", cached.Score)
	}

	// Test cache clearing
	validator.ClearCache()
	cached = validator.getCachedResult(planID)
	if cached != nil {
		t.Error("Expected cache to be cleared, but got cached result")
	}
}

func TestGenerateReport(t *testing.T) {
	validator := NewConsistencyValidator(nil, nil)

	result := &ValidationResult{
		PlanID:           "test-report-plan",
		Status:           ValidationCompleted,
		Score:            0.85,
		Timestamp:        time.Now(),
		Duration:         2 * time.Second,
		RulesExecuted:    4,
		RulesPassed:      3,
		RulesFailed:      1,
		AutoFixesApplied: 2,
		Issues: []ValidationIssue{
			{
				Type:        "metadata_version_mismatch",
				Severity:    SeverityWarning,
				Message:     "Version mismatch detected",
				Location:    "metadata.version",
				Suggestion:  "Sync version numbers",
				AutoFixable: true,
				RuleName:    "metadata_consistency",
			},
		},
	}

	// Test JSON report
	validator.Config.ReportFormat = "json"
	jsonReport, err := validator.GenerateReport(result)
	if err != nil {
		t.Errorf("Failed to generate JSON report: %v", err)
	}

	var parsedResult ValidationResult
	err = json.Unmarshal(jsonReport, &parsedResult)
	if err != nil {
		t.Errorf("Failed to parse JSON report: %v", err)
	}

	if parsedResult.PlanID != result.PlanID {
		t.Errorf("Expected plan ID %s in report, got %s", result.PlanID, parsedResult.PlanID)
	}

	// Test text report
	validator.Config.ReportFormat = "text"
	textReport, err := validator.GenerateReport(result)
	if err != nil {
		t.Errorf("Failed to generate text report: %v", err)
	}

	textStr := string(textReport)
	if !contains(textStr, "test-report-plan") {
		t.Error("Expected plan ID in text report")
	}

	if !contains(textStr, "0.85") {
		t.Error("Expected score in text report")
	}

	if !contains(textStr, "Version mismatch detected") {
		t.Error("Expected issue message in text report")
	}
}

func TestStatsUpdate(t *testing.T) {
	validator := NewConsistencyValidator(nil, nil)

	// Initial stats should be zero
	stats := validator.GetStats()
	if stats.TotalValidations != 0 {
		t.Errorf("Expected 0 total validations, got %d", stats.TotalValidations)
	}

	// Create test results
	result1 := &ValidationResult{
		Status:           ValidationCompleted,
		Score:            0.9,
		Duration:         1 * time.Second,
		Issues:           []ValidationIssue{{}, {}},
		AutoFixesApplied: 1,
		Timestamp:        time.Now(),
	}

	result2 := &ValidationResult{
		Status:           ValidationFailed,
		Score:            0.6,
		Duration:         2 * time.Second,
		Issues:           []ValidationIssue{{}, {}, {}},
		AutoFixesApplied: 0,
		Timestamp:        time.Now(),
	}

	// Update stats
	validator.updateStats(result1)
	validator.updateStats(result2)

	// Check updated stats
	stats = validator.GetStats()
	if stats.TotalValidations != 2 {
		t.Errorf("Expected 2 total validations, got %d", stats.TotalValidations)
	}

	if stats.SuccessfulValidations != 1 {
		t.Errorf("Expected 1 successful validation, got %d", stats.SuccessfulValidations)
	}

	if stats.FailedValidations != 1 {
		t.Errorf("Expected 1 failed validation, got %d", stats.FailedValidations)
	}

	if stats.TotalIssuesFound != 5 {
		t.Errorf("Expected 5 total issues, got %d", stats.TotalIssuesFound)
	}

	if stats.TotalAutoFixes != 1 {
		t.Errorf("Expected 1 total auto-fix, got %d", stats.TotalAutoFixes)
	}

	expectedAvgScore := (0.9 + 0.6) / 2
	if abs(stats.AverageScore-expectedAvgScore) > 0.001 {
		t.Errorf("Expected average score %f, got %f", expectedAvgScore, stats.AverageScore)
	}
}

func TestTimeoutHandling(t *testing.T) {
	config := &ValidationConfig{
		TimeoutDuration: 100 * time.Millisecond, // Very short timeout
	}
	validator := NewConsistencyValidator(config, nil)

	// Add a rule (rules are mocked and shouldn't actually timeout)
	validator.AddRule(NewMetadataRule())

	ctx := context.Background()
	options := &OperationOptions{
		Target:    "timeout-test-plan",
		SkipCache: true,
	}

	// This should complete successfully since our mock rules are fast
	err := validator.Execute(ctx, options)
	if err != nil {
		t.Errorf("Validation should not timeout with fast rules: %v", err)
	}
}

func TestAutoFixApplication(t *testing.T) {
	config := &ValidationConfig{
		AutoFix: true,
	}
	validator := NewConsistencyValidator(config, nil)
	validator.AddRule(NewMetadataRule())

	ctx := context.Background()
	options := &OperationOptions{
		Target:    "autofix-test-plan",
		DryRun:    false, // Enable auto-fix
		SkipCache: true,
	}

	err := validator.Execute(ctx, options)
	if err != nil {
		t.Errorf("Validation with auto-fix failed: %v", err)
	}

	// Note: Auto-fixes are attempted but may fail in mock implementation
	// The important thing is that the validation process completes
}

func TestDryRunMode(t *testing.T) {
	config := &ValidationConfig{
		AutoFix: true,
	}
	validator := NewConsistencyValidator(config, nil)
	validator.AddRule(NewMetadataRule())

	ctx := context.Background()
	options := &OperationOptions{
		Target:    "dry-run-test-plan",
		DryRun:    true, // Dry run mode
		SkipCache: true,
	}

	err := validator.Execute(ctx, options)
	if err != nil {
		t.Errorf("Dry run validation failed: %v", err)
	}

	// In dry run mode, no auto-fixes should be applied
	// We can verify this by checking that no actual changes were made
	// (In a real implementation, this would involve checking the actual data)
}

// Performance test
func BenchmarkValidationExecution(b *testing.B) {
	validator := NewConsistencyValidator(nil, nil)
	validator.AddRule(NewMetadataRule())
	validator.AddRule(NewTaskRule())

	ctx := context.Background()
	options := &OperationOptions{
		Target:    "benchmark-plan",
		SkipCache: true,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		err := validator.Execute(ctx, options)
		if err != nil {
			b.Errorf("Validation failed: %v", err)
		}
	}
}

// Helper function to check if string contains substring
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || 
		(len(s) > len(substr) && (s[:len(substr)] == substr || 
		s[len(s)-len(substr):] == substr ||
		func() bool {
			for i := 1; i < len(s)-len(substr)+1; i++ {
				if s[i:i+len(substr)] == substr {
					return true
				}
			}
			return false
		}())))
}
