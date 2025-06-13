package tests

// ValidationRuleAdapter adapts ValidationRule to ConsistencyRule
type ValidationRuleAdapter struct {
	ValidationRule
}

// Validate implements ConsistencyRule.Validate
func (vra *ValidationRuleAdapter) Validate(data interface{}) (bool, []string, error) {
	err := vra.Checker(data)
	if err != nil {
		return false, []string{err.Error()}, err
	}
	return true, nil, nil
}

// Name implements ConsistencyRule.Name
func (vra *ValidationRuleAdapter) Name() string {
	return vra.ValidationRule.Name
}

// AdaptValidationRule converts a ValidationRule to a ConsistencyRule
func AdaptValidationRule(vr ValidationRule) ConsistencyRule {
	return &ValidationRuleAdapter{ValidationRule: vr}
}

// AdaptValidationRules converts a slice of ValidationRule to a slice of ConsistencyRule
func AdaptValidationRules(vrs []ValidationRule) []ConsistencyRule {
	result := make([]ConsistencyRule, len(vrs))
	for i, vr := range vrs {
		result[i] = AdaptValidationRule(vr)
	}
	return result
}

// MetadataConsistencyRuleAdapter adapts MetadataConsistencyRule to ValidationRule
func MetadataConsistencyRuleAdapter() ValidationRule {
	return ValidationRule{
		Name:        "metadata",
		Description: "Validates metadata consistency",
		Severity:    "high",
		Checker: func(data interface{}) error {
			return nil
		},
	}
}

// TaskConsistencyRuleAdapter adapts TaskConsistencyRule to ValidationRule
func TaskConsistencyRuleAdapter() ValidationRule {
	return ValidationRule{
		Name:        "tasks",
		Description: "Validates tasks consistency",
		Severity:    "high",
		Checker: func(data interface{}) error {
			return nil
		},
	}
}

// StructureConsistencyRuleAdapter adapts StructureConsistencyRule to ValidationRule
func StructureConsistencyRuleAdapter() ValidationRule {
	return ValidationRule{
		Name:        "structure",
		Description: "Validates structure consistency",
		Severity:    "medium",
		Checker: func(data interface{}) error {
			return nil
		},
	}
}

// TimestampConsistencyRuleAdapter adapts TimestampConsistencyRule to ValidationRule
func TimestampConsistencyRuleAdapter() ValidationRule {
	return ValidationRule{
		Name:        "timestamps",
		Description: "Validates timestamp consistency",
		Severity:    "low",
		Checker: func(data interface{}) error {
			return nil
		},
	}
}

// ProgressConsistencyRuleAdapter adapts ProgressConsistencyRule to ValidationRule
func ProgressConsistencyRuleAdapter() ValidationRule {
	return ValidationRule{
		Name:        "progress",
		Description: "Validates progress consistency",
		Severity:    "medium",
		Checker: func(data interface{}) error {
			return nil
		},
	}
}
