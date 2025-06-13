package tests

import (
	"context"
	"fmt"
)

// ConvertToString converts a ConflictType to a string
func ConvertToString(ct ConflictType) string {
	return string(ct)
}

// StringToConflictType converts a string to a ConflictType
func StringToConflictType(s string) ConflictType {
	return ConflictType(s)
}

// GetNameHelper is a helper function to get the name of a ConsistencyRule
func GetNameHelper(rule ConsistencyRule) string {
	return rule.Name()
}

// GetNameForValidationRule is a helper function to get the name of a ValidationRule
func GetNameForValidationRule(rule ValidationRule) string {
	return rule.Name
}

// ConsistencyRuleToValidationRule converts a ConsistencyRule to a ValidationRule
func ConsistencyRuleToValidationRule(rule ConsistencyRule) ValidationRule {
	return ValidationRule{
		Name:        rule.Name(),
		Description: fmt.Sprintf("Converted from consistency rule %s", rule.Name()),
		Severity:    "medium",
		Checker: func(data interface{}) error {
			result, _, err := rule.Validate(data)
			if !result {
				return err
			}
			return nil
		},
	}
}

// ValidateRuleWithContext validates a rule with context
func ValidateRuleWithContext(rule ConsistencyRule, ctx context.Context, testPlan string) ([]interface{}, error) {
	result, issues, err := rule.Validate(testPlan)
	if !result {
		return []interface{}{map[string]string{"type": rule.Name(), "message": fmt.Sprintf("Validation failed: %v", issues)}}, err
	}
	return nil, nil
}
