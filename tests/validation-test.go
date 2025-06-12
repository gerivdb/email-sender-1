package tests

import (
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ValidationTestSuite contains validation and regression testing
type ValidationTestSuite struct {
	validator          *ConsistencyValidator
	conflictAnalyzer   *ConflictAnalyzer
	autoResolver       *AutoResolver
	testDataDir        string
	logger             *Logger
	validationRules    []ValidationRule
}

// CoherenceTestScenario defines scenarios for coherence testing
type CoherenceTestScenario struct {
	Name              string
	PlanFile          string
	ExpectedIssues    int
	ExpectedScore     float64
	ShouldAutoFix     bool
	ValidationTypes   []string
}

// RegressionTestCase defines regression test cases
type RegressionTestCase struct {
	Name            string
	PlanFiles       []string
	ExpectedResults map[string]interface{}
	Baseline        *ValidationResult
	Tolerance       float64
}

// NewValidationTestSuite creates a new validation test suite
func NewValidationTestSuite(testDataDir string) (*ValidationTestSuite, error) {
	validator := NewConsistencyValidator(&ValidationConfig{
		StrictMode:         true,
		ToleranceThreshold: 0.90,
		AutoFix:           false,
		ValidationRules:   []string{"metadata", "structure", "tasks", "timestamps"},
	})

	conflictAnalyzer := NewConflictAnalyzer(&ConflictConfig{
		EnabledTypes: []ConflictType{
			MetadataConflict,
			TaskStatusConflict,
			StructureConflict,
			TimestampConflict,
		},
	})

	autoResolver := NewAutoResolver(&ResolutionConfig{
		EnableAutoResolve: true,
		BackupBeforeResolve: true,
		ResolutionStrategies: []string{"timestamp", "priority", "manual"},
	})

	validationRules := []ValidationRule{
		NewMetadataConsistencyRule(),
		NewTaskConsistencyRule(),
		NewStructureConsistencyRule(),
		NewTimestampConsistencyRule(),
		NewProgressConsistencyRule(),
	}

	return &ValidationTestSuite{
		validator:        validator,
		conflictAnalyzer: conflictAnalyzer,
		autoResolver:     autoResolver,
		testDataDir:      testDataDir,
		logger:           NewLogger("validation-test-suite"),
		validationRules:  validationRules,
	}, nil
}

// TestDetectionDivergences tests divergence detection capabilities
func (vts *ValidationTestSuite) TestDetectionDivergences(t *testing.T) {
	scenarios := []CoherenceTestScenario{
		{
			Name:            "Clean Plan - No Divergences",
			PlanFile:        "plan-clean-test.md",
			ExpectedIssues:  0,
			ExpectedScore:   100.0,
			ShouldAutoFix:   false,
			ValidationTypes: []string{"metadata", "structure", "tasks"},
		},
		{
			Name:            "Metadata Inconsistencies",
			PlanFile:        "plan-metadata-issues.md",
			ExpectedIssues:  3,
			ExpectedScore:   75.0,
			ShouldAutoFix:   true,
			ValidationTypes: []string{"metadata", "timestamps"},
		},
		{
			Name:            "Task Status Divergences",
			PlanFile:        "plan-task-divergences.md",
			ExpectedIssues:  5,
			ExpectedScore:   60.0,
			ShouldAutoFix:   false,
			ValidationTypes: []string{"tasks", "structure"},
		},
		{
			Name:            "Structure Problems",
			PlanFile:        "plan-structure-issues.md",
			ExpectedIssues:  8,
			ExpectedScore:   45.0,
			ShouldAutoFix:   false,
			ValidationTypes: []string{"structure", "metadata"},
		},
		{
			Name:            "Critical Divergences",
			PlanFile:        "plan-critical-issues.md",
			ExpectedIssues:  12,
			ExpectedScore:   25.0,
			ShouldAutoFix:   false,
			ValidationTypes: []string{"metadata", "structure", "tasks", "timestamps"},
		},
	}

	for _, scenario := range scenarios {
		t.Run(scenario.Name, func(t *testing.T) {
			vts.runCoherenceScenario(t, scenario)
		})
	}
}

// TestCorrectionAutomatique tests automatic correction capabilities
func (vts *ValidationTestSuite) TestCorrectionAutomatique(t *testing.T) {
	testCases := []struct {
		name           string
		planFile       string
		issuesType     []string
		expectedFixes  int
		shouldSucceed  bool
	}{
		{
			name:          "Auto-fix Metadata Issues",
			planFile:      "plan-autofix-metadata.md",
			issuesType:    []string{"metadata"},
			expectedFixes: 3,
			shouldSucceed: true,
		},
		{
			name:          "Auto-fix Progress Calculation",
			planFile:      "plan-autofix-progress.md",
			issuesType:    []string{"progress"},
			expectedFixes: 2,
			shouldSucceed: true,
		},
		{
			name:          "Cannot Auto-fix Structural Issues",
			planFile:      "plan-structure-complex.md",
			issuesType:    []string{"structure"},
			expectedFixes: 0,
			shouldSucceed: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			// Initial validation
			planPath := fmt.Sprintf("%s/%s", vts.testDataDir, tc.planFile)
			
			initialResult, err := vts.validator.ValidatePlan(planPath)
			require.NoError(t, err, "Initial validation should succeed")
			
			// Attempt auto-fix
			fixResult, err := vts.autoResolver.AutoFixIssues(planPath, initialResult.Issues)
			
			if tc.shouldSucceed {
				require.NoError(t, err, "Auto-fix should succeed")
				assert.Equal(t, tc.expectedFixes, fixResult.FixedCount,
					"Should fix expected number of issues")
				
				// Re-validate after fix
				postFixResult, err := vts.validator.ValidatePlan(planPath)
				require.NoError(t, err, "Post-fix validation should succeed")
				
				assert.Greater(t, postFixResult.Score, initialResult.Score,
					"Score should improve after auto-fix")
				
				assert.LessOrEqual(t, len(postFixResult.Issues), len(initialResult.Issues)-tc.expectedFixes,
					"Should have fewer issues after auto-fix")
			} else {
				// Auto-fix should either fail or fix nothing
				if err == nil {
					assert.Equal(t, 0, fixResult.FixedCount,
						"Should not fix issues when not expected to succeed")
				}
			}
			
			vts.logger.Info("✅ Auto-correction test completed: %s", tc.name)
		})
	}
}

// TestConflictResolutionStrategies tests different conflict resolution strategies
func (vts *ValidationTestSuite) TestConflictResolutionStrategies(t *testing.T) {
	strategies := []struct {
		name     string
		strategy ResolutionStrategy
		conflicts []Conflict
		expectedResults map[string]string
	}{
		{
			name:     "Timestamp-based Resolution",
			strategy: NewTimestampBasedStrategy(),
			conflicts: []Conflict{
				{
					Type: TaskStatusConflict,
					MarkdownValue: TaskChange{Status: "completed", Timestamp: time.Now()},
					DynamicValue:  TaskChange{Status: "in-progress", Timestamp: time.Now().Add(-1*time.Hour)},
				},
			},
			expectedResults: map[string]string{
				"action": "use_markdown_value",
				"reason": "newer_timestamp",
			},
		},
		{
			name:     "Priority-based Resolution",
			strategy: NewPriorityBasedStrategy(),
			conflicts: []Conflict{
				{
					Type: MetadataConflict,
					MarkdownValue: MetadataChange{Source: "markdown", Priority: "high"},
					DynamicValue:  MetadataChange{Source: "dynamic", Priority: "medium"},
				},
			},
			expectedResults: map[string]string{
				"action": "use_markdown_value",
				"reason": "higher_priority",
			},
		},
		{
			name:     "Manual Resolution Required",
			strategy: NewManualResolutionStrategy(),
			conflicts: []Conflict{
				{
					Type: StructureConflict,
					MarkdownValue: StructureChange{Operation: "move_phase"},
					DynamicValue:  StructureChange{Operation: "delete_phase"},
				},
			},
			expectedResults: map[string]string{
				"action": "require_manual_review",
				"reason": "structural_conflict",
			},
		},
	}

	for _, strategyTest := range strategies {
		t.Run(strategyTest.name, func(t *testing.T) {
			for _, conflict := range strategyTest.conflicts {
				resolution, err := strategyTest.strategy.Resolve(conflict)
				
				if strategyTest.expectedResults["action"] == "require_manual_review" {
					assert.Error(t, err, "Should require manual resolution")
					assert.Nil(t, resolution, "Resolution should be nil for manual cases")
				} else {
					require.NoError(t, err, "Resolution should succeed")
					require.NotNil(t, resolution, "Resolution should not be nil")
					
					assert.Equal(t, strategyTest.expectedResults["action"], resolution.Action,
						"Resolution action should match expected")
				}
			}
			
			vts.logger.Info("✅ Conflict resolution strategy test completed: %s", strategyTest.name)
		})
	}
}

// TestPlansExistants tests existing plans for regression
func (vts *ValidationTestSuite) TestPlansExistants(t *testing.T) {
	regressionCases := []RegressionTestCase{
		{
			Name: "Stable Plan Validation",
			PlanFiles: []string{
				"plan-dev-v48-repovisualizer.md",
				"plan-dev-v55-planning-ecosystem-sync.md",
			},
			ExpectedResults: map[string]interface{}{
				"min_score": 90.0,
				"max_issues": 2,
				"validation_time_ms": 3000,
			},
			Tolerance: 5.0, // 5% tolerance
		},
		{
			Name: "Complex Plans Validation",
			PlanFiles: []string{
				"plan-complex-multiPhase.md",
				"plan-with-dependencies.md",
			},
			ExpectedResults: map[string]interface{}{
				"min_score": 80.0,
				"max_issues": 5,
				"validation_time_ms": 5000,
			},
			Tolerance: 10.0, // 10% tolerance for complex plans
		},
	}

	for _, testCase := range regressionCases {
		t.Run(testCase.Name, func(t *testing.T) {
			vts.runRegressionTestCase(t, testCase)
		})
	}
}

// TestRobustesse tests system robustness with edge cases
func (vts *ValidationTestSuite) TestRobustesse(t *testing.T) {
	robustnessTests := []struct {
		name        string
		setup       func() string
		shouldFail  bool
		expectedError string
	}{
		{
			name: "Empty Plan File",
			setup: func() string {
				return vts.createEmptyPlan()
			},
			shouldFail: true,
			expectedError: "empty_content",
		},
		{
			name: "Corrupted Plan File", 
			setup: func() string {
				return vts.createCorruptedPlan()
			},
			shouldFail: true,
			expectedError: "parse_error",
		},
		{
			name: "Very Large Plan",
			setup: func() string {
				return vts.createLargePlan(10000) // 10k tasks
			},
			shouldFail: false,
			expectedError: "",
		},
		{
			name: "Unicode and Special Characters",
			setup: func() string {
				return vts.createUnicodePlan()
			},
			shouldFail: false,
			expectedError: "",
		},
		{
			name: "Deeply Nested Structure",
			setup: func() string {
				return vts.createDeeplyNestedPlan(20) // 20 levels deep
			},
			shouldFail: false,
			expectedError: "",
		},
	}

	for _, robustnessTest := range robustnessTests {
		t.Run(robustnessTest.name, func(t *testing.T) {
			planPath := robustnessTest.setup()
			
			result, err := vts.validator.ValidatePlan(planPath)
			
			if robustnessTest.shouldFail {
				assert.Error(t, err, "Validation should fail for: %s", robustnessTest.name)
				if robustnessTest.expectedError != "" {
					assert.Contains(t, err.Error(), robustnessTest.expectedError,
						"Error should contain expected message")
				}
			} else {
				assert.NoError(t, err, "Validation should succeed for: %s", robustnessTest.name)
				assert.NotNil(t, result, "Result should not be nil")
				
				// For successful cases, check reasonable performance
				assert.LessOrEqual(t, result.Duration, 30*time.Second,
					"Validation should complete in reasonable time")
			}
			
			vts.logger.Info("✅ Robustness test completed: %s", robustnessTest.name)
		})
	}
}

// TestValidationRulesCoverage tests coverage of all validation rules
func (vts *ValidationTestSuite) TestValidationRulesCoverage(t *testing.T) {
	// Test each validation rule individually
	for _, rule := range vts.validationRules {
		t.Run(fmt.Sprintf("Rule_%s", rule.GetName()), func(t *testing.T) {
			// Create test plan that triggers this rule
			testPlan := vts.createPlanForRule(rule)
			
			issues, err := rule.Validate(context.Background(), testPlan)
			assert.NoError(t, err, "Rule validation should not error")
			
			// Each rule should detect at least one issue in its test plan
			assert.Greater(t, len(issues), 0, "Rule should detect issues in test plan")
			
			// Verify issue types are correct for this rule
			for _, issue := range issues {
				assert.Contains(t, issue.Type, rule.GetName(),
					"Issue type should relate to rule name")
			}
			
			vts.logger.Info("✅ Validation rule coverage test completed: %s", rule.GetName())
		})
	}
}

// Helper methods

func (vts *ValidationTestSuite) runCoherenceScenario(t *testing.T, scenario CoherenceTestScenario) {
	planPath := fmt.Sprintf("%s/%s", vts.testDataDir, scenario.PlanFile)
	
	startTime := time.Now()
	result, err := vts.validator.ValidatePlan(planPath)
	validationDuration := time.Since(startTime)
	
	require.NoError(t, err, "Validation should succeed for scenario: %s", scenario.Name)
	require.NotNil(t, result, "Validation result should not be nil")
	
	// Check validation performance
	assert.LessOrEqual(t, validationDuration, 5*time.Second,
		"Validation should complete within 5 seconds")
	
	// Check expected issues count
	issueCount := len(result.Issues)
	tolerance := 2 // Allow some tolerance in issue count
	
	assert.InDelta(t, scenario.ExpectedIssues, issueCount, float64(tolerance),
		"Issue count should be within tolerance for scenario: %s", scenario.Name)
	
	// Check expected score
	scoreTolerance := 10.0 // 10% tolerance
	assert.InDelta(t, scenario.ExpectedScore, result.Score, scoreTolerance,
		"Score should be within tolerance for scenario: %s", scenario.Name)
	
	// Test auto-fix if expected
	if scenario.ShouldAutoFix && len(result.Issues) > 0 {
		fixResult, err := vts.autoResolver.AutoFixIssues(planPath, result.Issues)
		assert.NoError(t, err, "Auto-fix should succeed for scenario: %s", scenario.Name)
		assert.Greater(t, fixResult.FixedCount, 0, "Should fix at least one issue")
	}
	
	vts.logger.Info("✅ Coherence scenario completed: %s (score: %.2f, issues: %d)",
		scenario.Name, result.Score, issueCount)
}

func (vts *ValidationTestSuite) runRegressionTestCase(t *testing.T, testCase RegressionTestCase) {
	results := make([]*ValidationResult, 0, len(testCase.PlanFiles))
	
	for _, planFile := range testCase.PlanFiles {
		planPath := fmt.Sprintf("%s/%s", vts.testDataDir, planFile)
		
		result, err := vts.validator.ValidatePlan(planPath)
		require.NoError(t, err, "Validation should succeed for file: %s", planFile)
		
		results = append(results, result)
	}
	
	// Check aggregated results against expectations
	avgScore := 0.0
	maxIssues := 0
	maxValidationTime := time.Duration(0)
	
	for _, result := range results {
		avgScore += result.Score
		if len(result.Issues) > maxIssues {
			maxIssues = len(result.Issues)
		}
		if result.Duration > maxValidationTime {
			maxValidationTime = result.Duration
		}
	}
	
	avgScore /= float64(len(results))
	
	// Assert expectations with tolerance
	minScore := testCase.ExpectedResults["min_score"].(float64)
	assert.GreaterOrEqual(t, avgScore, minScore-testCase.Tolerance,
		"Average score should meet minimum requirement")
	
	maxExpectedIssues := int(testCase.ExpectedResults["max_issues"].(float64))
	assert.LessOrEqual(t, maxIssues, maxExpectedIssues,
		"Maximum issues should be within limits")
	
	maxExpectedTime := time.Duration(testCase.ExpectedResults["validation_time_ms"].(float64)) * time.Millisecond
	assert.LessOrEqual(t, maxValidationTime, maxExpectedTime,
		"Validation time should be within limits")
	
	vts.logger.Info("✅ Regression test case completed: %s (avg score: %.2f, max issues: %d)",
		testCase.Name, avgScore, maxIssues)
}

// Test data creation helpers

func (vts *ValidationTestSuite) createEmptyPlan() string {
	content := ""
	return vts.writeTestFile("empty-plan.md", content)
}

func (vts *ValidationTestSuite) createCorruptedPlan() string {
	content := "# Invalid Plan\n\n<<< corrupted markdown syntax [[["
	return vts.writeTestFile("corrupted-plan.md", content)
}

func (vts *ValidationTestSuite) createLargePlan(taskCount int) string {
	var builder strings.Builder
	builder.WriteString("# Large Test Plan\n\n")
	builder.WriteString("## Phase 1: Large Scale Testing\n\n")
	
	for i := 0; i < taskCount; i++ {
		status := "[ ]"
		if i%4 == 0 {
			status = "[x]"
		}
		builder.WriteString(fmt.Sprintf("- %s Task %d: Large scale test task\n", status, i+1))
	}
	
	return vts.writeTestFile("large-plan.md", builder.String())
}

func (vts *ValidationTestSuite) createUnicodePlan() string {
	content := `# Plan Unicode 🚀

## Phase 1: Tests Spéciaux avec Caractères 特殊字符 
- [x] Tâche avec émojis 🔧 ✅ 🎯
- [ ] Tâche avec accents éàùç
- [ ] Tâche avec chinois 中文测试
- [ ] Tâche avec arabe اختبار عربي
- [ ] Tâche avec russe тест русский`
	
	return vts.writeTestFile("unicode-plan.md", content)
}

func (vts *ValidationTestSuite) createDeeplyNestedPlan(depth int) string {
	var builder strings.Builder
	builder.WriteString("# Deeply Nested Plan\n\n")
	
	for i := 0; i < depth; i++ {
		indent := strings.Repeat("#", i+2)
		builder.WriteString(fmt.Sprintf("%s Level %d\n\n", indent, i+1))
		builder.WriteString(fmt.Sprintf("- [ ] Task at level %d\n\n", i+1))
	}
	
	return vts.writeTestFile("nested-plan.md", builder.String())
}

func (vts *ValidationTestSuite) createPlanForRule(rule ValidationRule) string {
	// Create a test plan that will trigger issues for the specific rule
	content := fmt.Sprintf(`# Test Plan for %s

## Phase 1: Test Phase
- [ ] Test task that should trigger %s rule
- [x] Completed test task

Progression: 50%%
`, rule.GetName(), rule.GetName())
	
	return vts.writeTestFile(fmt.Sprintf("test-plan-%s.md", rule.GetName()), content)
}

func (vts *ValidationTestSuite) writeTestFile(filename, content string) string {
	filePath := fmt.Sprintf("%s/%s", vts.testDataDir, filename)
	// In real implementation, would write to file system
	// For tests, return the path that would be created
	return filePath
}

// RunAllValidationTests runs the complete validation test suite
func (vts *ValidationTestSuite) RunAllValidationTests(t *testing.T) {
	vts.logger.Info("🚀 Starting comprehensive validation test suite...")
	
	t.Run("CoherenceDetection", vts.TestDetectionDivergences)
	t.Run("AutoCorrection", vts.TestCorrectionAutomatique)
	t.Run("ConflictResolution", vts.TestConflictResolutionStrategies)
	t.Run("ExistingPlans", vts.TestPlansExistants)
	t.Run("Robustness", vts.TestRobustesse)
	t.Run("ValidationRulesCoverage", vts.TestValidationRulesCoverage)
	
	vts.logger.Info("✅ Comprehensive validation test suite completed successfully")
}
