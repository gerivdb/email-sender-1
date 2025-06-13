package validation

import (
	"context"
	"testing"
)

func TestValidatorCreation(t *testing.T) {
	validator := NewConsistencyValidator(nil)
	if validator == nil {
		t.Fatal("Expected validator to be created")
	}

	if validator.Config == nil {
		t.Fatal("Expected default config to be set")
	}

	if validator.Stats == nil {
		t.Fatal("Expected stats to be initialized")
	}
}

func TestRuleManagement(t *testing.T) {
	validator := NewConsistencyValidator(nil)

	rule := NewMetadataConsistencyRule()
	validator.AddRule(rule)

	if len(validator.Rules) != 1 {
		t.Errorf("Expected 1 rule, got %d", len(validator.Rules))
	}

	removed := validator.RemoveRule("metadata_consistency")
	if !removed {
		t.Error("Expected rule to be removed")
	}

	if len(validator.Rules) != 0 {
		t.Errorf("Expected 0 rules after removal, got %d", len(validator.Rules))
	}
}

func TestExecuteValidation(t *testing.T) {
	validator := NewConsistencyValidator(&ValidationConfig{
		ToleranceThreshold: 0.8,
		TimeoutSeconds:     30,
	})

	validator.AddRule(NewMetadataConsistencyRule())

	ctx := context.Background()
	options := &OperationOptions{
		Target: "test-plan",
	}

	err := validator.Execute(ctx, options)
	if err != nil {
		t.Errorf("Expected validation to succeed, got error: %v", err)
	}

	stats := validator.GetStats()
	if stats.PlansValidated != 1 {
		t.Errorf("Expected 1 plan validated, got %d", stats.PlansValidated)
	}
}

func TestScoreCalculate(t *testing.T) {
	validator := NewConsistencyValidator(nil)

	// Test sans issues
	score := validator.calculateConsistencyScore([]ValidationIssue{})
	if score != 100.0 {
		t.Errorf("Expected perfect score 100.0, got %f", score)
	}

	// Test avec issues
	issues := []ValidationIssue{
		{Severity: SeverityError},
	}
	score = validator.calculateConsistencyScore(issues)
	if score == 100.0 {
		t.Error("Expected score to be less than 100 with issues")
	}
}

func TestHealthCheckFunc(t *testing.T) {
	validator := NewConsistencyValidator(nil)
	validator.AddRule(NewMetadataConsistencyRule())

	ctx := context.Background()
	err := validator.HealthCheck(ctx)
	if err != nil {
		t.Errorf("Expected health check to pass, got error: %v", err)
	}
}

func TestMetricsCollection(t *testing.T) {
	validator := NewConsistencyValidator(nil)

	validator.Stats.PlansValidated = 5
	validator.Stats.IssuesFound = 10

	metrics := validator.CollectMetrics()

	if plans, ok := metrics["plans_validated"]; !ok || plans != 5 {
		t.Errorf("Expected plans_validated=5, got %v", plans)
	}
}

func BenchmarkValidationRun(b *testing.B) {
	validator := NewConsistencyValidator(&ValidationConfig{
		ToleranceThreshold: 0.8,
		TimeoutSeconds:     30,
	})

	rules := GetAllValidationRules()
	for _, rule := range rules {
		validator.AddRule(rule)
	}

	ctx := context.Background()
	options := &OperationOptions{Target: "benchmark-plan"}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		validator.Execute(ctx, options)
	}
}
