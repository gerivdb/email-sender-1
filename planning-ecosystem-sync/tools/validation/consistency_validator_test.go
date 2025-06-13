package validation

import (
	"errors"
	"testing"
)

// MockRule is a mock implementation of ValidationRule interface for testing
type MockRule struct {
	name           string
	validateResult error
	canAutoFix     bool
	fixResult      error
}

func (r *MockRule) GetName() string {
	return r.name
}

func (r *MockRule) Validate(interface{}) error {
	return r.validateResult
}

func (r *MockRule) CanAutoFix() bool {
	return r.canAutoFix
}

func (r *MockRule) Fix(interface{}) error {
	return r.fixResult
}

func TestConsistencyValidation(t *testing.T) {
	t.Run("TestValidatorCreation", func(t *testing.T) {
		validator := NewConsistencyValidator()
		if validator == nil {
			t.Fatal("Failed to create ConsistencyValidator")
		}

		if len(validator.rules) != 0 {
			t.Errorf("New validator should have 0 rules, got %d", len(validator.rules))
		}
	})

	t.Run("TestAddRule", func(t *testing.T) {
		validator := NewConsistencyValidator()
		rule := &MockRule{name: "test-rule"}

		validator.AddRule(rule)

		if len(validator.rules) != 1 {
			t.Errorf("Expected 1 rule after adding, got %d", len(validator.rules))
		}
	})

	t.Run("TestValidate", func(t *testing.T) {
		validator := NewConsistencyValidator()

		// Add passing rule
		validator.AddRule(&MockRule{
			name:           "passing-rule",
			validateResult: nil,
		})

		// Add failing rule
		validator.AddRule(&MockRule{
			name:           "failing-rule",
			validateResult: errors.New("validation failed"),
		})

		errors := validator.Validate("test-data")

		if len(errors) != 1 {
			t.Errorf("Expected 1 error, got %d", len(errors))
		}
	})

	t.Run("TestAutoFix", func(t *testing.T) {
		validator := NewConsistencyValidator()

		// Add non-fixable rule
		validator.AddRule(&MockRule{
			name:       "non-fixable",
			canAutoFix: false,
		})

		// Add fixable rule that succeeds
		validator.AddRule(&MockRule{
			name:       "fixable-success",
			canAutoFix: true,
			fixResult:  nil,
		})

		// Add fixable rule that fails
		validator.AddRule(&MockRule{
			name:       "fixable-failure",
			canAutoFix: true,
			fixResult:  errors.New("fix failed"),
		})

		fixed, errors := validator.AutoFix("test-data")

		if !fixed {
			t.Error("Expected at least one successful fix")
		}

		if len(errors) != 1 {
			t.Errorf("Expected 1 error, got %d", len(errors))
		}
	})
}
