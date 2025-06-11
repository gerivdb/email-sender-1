package validation

import (
	"context"
	"testing"
)

func BenchmarkValidationExecution(b *testing.B) {
	validator := NewConsistencyValidator(&ValidationConfig{
		ToleranceThreshold: 0.8,
		TimeoutSeconds:     30,
		MaxIssues:          100,
	})

	// Ajouter toutes les règles de validation disponibles
	rules := GetAllValidationRules()
	for _, rule := range rules {
		validator.AddRule(rule)
	}

	ctx := context.Background()
	options := &OperationOptions{
		Target: "benchmark-plan-test",
		Parameters: map[string]interface{}{
			"complexity": "medium",
			"task_count": 50,
		},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		err := validator.Execute(ctx, options)
		if err != nil {
			b.Fatalf("Benchmark failed: %v", err)
		}
	}
}

func BenchmarkScoreCalculation(b *testing.B) {
	validator := NewConsistencyValidator(nil)

	// Créer une liste d'issues représentative pour le benchmark
	issues := make([]ValidationIssue, 50)
	severities := []ValidationSeverity{SeverityInfo, SeverityWarning, SeverityError, SeverityCritical}

	for i := range issues {
		issues[i] = ValidationIssue{
			Type:        "test_issue",
			Severity:    severities[i%len(severities)],
			Message:     "Test issue for benchmarking",
			Location:    "test_location",
			Suggestion:  "Test suggestion",
			AutoFixable: i%2 == 0,
		}
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		score := validator.calculateConsistencyScore(issues)
		if score < 0 || score > 100 {
			b.Fatalf("Invalid score: %f", score)
		}
	}
}

func BenchmarkRuleExecution(b *testing.B) {
	rule := NewMetadataConsistencyRule()

	ctx := context.Background()
	planID := "benchmark-plan"
	data := ValidationData{
		MarkdownPlan: map[string]interface{}{
			"title":       "Test Plan",
			"version":     "1.0",
			"progression": 50.0,
		},
		DynamicPlan: map[string]interface{}{
			"title":       "Test Plan Modified",
			"version":     "1.1",
			"progression": 52.0,
		},
		Config: &ValidationConfig{
			ToleranceThreshold: 0.9,
		},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		issues, err := rule.Validate(ctx, planID, data)
		if err != nil {
			b.Fatalf("Rule execution failed: %v", err)
		}
		_ = issues // Use the result to prevent optimization
	}
}
