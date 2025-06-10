package main

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"

	"branching-framework-dev/development"
	"branching-framework-dev/interfaces"
)

// setupTestManager creates a branching manager for testing
func setupTestManager(t *testing.T) *development.BranchingManagerImpl {
	manager, err := development.NewBranchingManager("../config/branching_config.yaml")
	require.NoError(t, err)

	// Set up mock dependencies
	manager.SetStorageManager(development.NewMockStorageManager())
	manager.SetPredictor(development.NewMockBranchingPredictor())
	manager.SetAnalyzer(development.NewMockPatternAnalyzer())

	return manager
}

// Test Level 1: Micro-Sessions Temporelles
func TestLevel1_MicroSessions(t *testing.T) {
	manager := setupTestManager(t)
	ctx := context.Background()

	t.Run("CreateSession", func(t *testing.T) {
		sessionConfig := interfaces.SessionConfig{
			Scope:       "feature/test",
			MaxDuration: 30 * time.Minute,
			Metadata: map[string]string{
				"project": "test-project",
				"user":    "test-user",
			},
		}

		session, err := manager.CreateSession(ctx, sessionConfig)
		assert.NoError(t, err)
		assert.NotNil(t, session)
		assert.NotEmpty(t, session.ID)
		assert.Equal(t, interfaces.SessionStatusActive, session.Status)
		assert.Equal(t, sessionConfig.Scope, session.Scope)
		assert.Equal(t, sessionConfig.MaxDuration, session.Duration)
	})

	t.Run("GetActiveSession", func(t *testing.T) {
		// Create a session first
		sessionConfig := interfaces.SessionConfig{
			Scope:       "feature/active-test",
			MaxDuration: 30 * time.Minute,
		}
		createdSession, err := manager.CreateSession(ctx, sessionConfig)
		require.NoError(t, err)

		// Get active session
		activeSession, err := manager.GetActiveSession(ctx)
		assert.NoError(t, err)
		assert.NotNil(t, activeSession)
		assert.Equal(t, createdSession.ID, activeSession.ID)
	})

	t.Run("EndSession", func(t *testing.T) {
		// Create a session first
		sessionConfig := interfaces.SessionConfig{
			Scope:       "feature/end-test",
			MaxDuration: 30 * time.Minute,
		}
		session, err := manager.CreateSession(ctx, sessionConfig)
		require.NoError(t, err)

		// End the session
		err = manager.EndSession(ctx, session.ID)
		assert.NoError(t, err)

		// Verify session is ended
		_, err = manager.GetActiveSession(ctx)
		assert.Error(t, err) // Should not find active session
	})
}

// Test Level 2: Event-Driven Branching
func TestLevel2_EventDriven(t *testing.T) {
	manager := setupTestManager(t)
	ctx := context.Background()

	t.Run("TriggerBranchCreation", func(t *testing.T) {
		event := interfaces.BranchingEvent{
			Type:        interfaces.EventTypeCommit,
			Trigger:     "test-trigger",
			Context:     map[string]interface{}{"commit_hash": "abc123"},
			AutoCreated: true,
			Priority:    interfaces.EventPriorityMedium,
			CreatedAt:   time.Now(),
		}

		branch, err := manager.TriggerBranchCreation(ctx, event)
		assert.NoError(t, err)
		assert.NotNil(t, branch)
		assert.NotEmpty(t, branch.ID)
		assert.Equal(t, interfaces.BranchStatusActive, branch.Status)
		assert.Equal(t, 2, branch.Level) // Level 2: Event-Driven
	})

	t.Run("ProcessGitHook", func(t *testing.T) {
		payload := map[string]interface{}{
			"ref":        "refs/heads/main",
			"repository": "test-repo",
			"commits":    []string{"abc123", "def456"},
		}

		err := manager.ProcessGitHook(ctx, "pre-commit", payload)
		assert.NoError(t, err)
	})

	t.Run("HandleEventDriven", func(t *testing.T) {
		context := map[string]interface{}{
			"issue_id":    "12345",
			"issue_title": "Test Feature",
			"assignee":    "test-user",
		}

		err := manager.HandleEventDriven(ctx, "issue_created", context)
		assert.NoError(t, err)
	})
}

// Test Level 3: Multi-Dimensional Branching
func TestLevel3_MultiDimensional(t *testing.T) {
	manager := setupTestManager(t)
	ctx := context.Background()

	t.Run("CreateMultiDimBranch", func(t *testing.T) {
		dimensions := []interfaces.BranchDimension{
			{
				Name:   "feature_type",
				Value:  "ui_component",
				Type:   interfaces.DimensionTypeFeature,
				Weight: 0.8,
			},
			{
				Name:   "priority",
				Value:  "high",
				Type:   interfaces.DimensionTypePriority,
				Weight: 0.9,
			},
			{
				Name:   "complexity",
				Value:  "medium",
				Type:   interfaces.DimensionTypeComplexity,
				Weight: 0.6,
			},
		}

		branch, err := manager.CreateMultiDimBranch(ctx, dimensions)
		assert.NoError(t, err)
		assert.NotNil(t, branch)
		assert.NotEmpty(t, branch.ID)
		assert.Equal(t, 3, branch.Level) // Level 3: Multi-Dimensional
	})

	t.Run("TagBranch", func(t *testing.T) {
		// Create a branch first
		dimensions := []interfaces.BranchDimension{
			{Name: "test", Value: "tag", Type: interfaces.DimensionTypeFeature, Weight: 0.5},
		}
		branch, err := manager.CreateMultiDimBranch(ctx, dimensions)
		require.NoError(t, err)

		// Add tags
		tags := []interfaces.BranchTag{
			{Key: "environment", Value: "development", Category: "deployment"},
			{Key: "reviewer", Value: "senior-dev", Category: "review"},
		}

		err = manager.TagBranch(ctx, branch.ID, tags)
		assert.NoError(t, err)
	})

	t.Run("SearchBranchesByDimensions", func(t *testing.T) {
		query := interfaces.DimensionQuery{
			Dimensions: []interfaces.BranchDimension{
				{Type: interfaces.DimensionTypeFeature, Value: "ui_component"},
			},
			Tags: []interfaces.BranchTag{
				{Key: "environment", Value: "development"},
			},
			Operator: interfaces.QueryOperatorAND,
			Limit:    10,
		}

		branches, err := manager.SearchBranchesByDimensions(ctx, query)
		assert.NoError(t, err)
		assert.NotNil(t, branches)
	})
}

// Test Level 4: Contextual Memory Integration
func TestLevel4_ContextualMemory(t *testing.T) {
	manager := setupTestManager(t)
	ctx := context.Background()

	t.Run("IntegrateContextualMemory", func(t *testing.T) {
		branchID := "test-branch-123"
		memoryContext := interfaces.MemoryContext{
			ContextID: "memory-ctx-456",
			Type:      interfaces.MemoryTypeProject,
			Content:   "Test project context for branching",
			Metadata:  map[string]interface{}{"project": "test"},
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}

		err := manager.IntegrateContextualMemory(ctx, branchID, memoryContext)
		assert.NoError(t, err)
	})

	t.Run("GenerateAutoDocumentation", func(t *testing.T) {
		branchID := "test-branch-doc"

		// Mock branch would need to be stored first in a real scenario
		// For this test, we'll just verify the method doesn't crash
		doc, err := manager.GenerateAutoDocumentation(ctx, branchID)
		// Error expected since branch doesn't exist, but method should handle gracefully
		assert.Error(t, err)
		assert.Nil(t, doc)
	})

	t.Run("LinkBranchToContext", func(t *testing.T) {
		branchID := "test-branch-link"
		contextID := "test-context-789"

		err := manager.LinkBranchToContext(ctx, branchID, contextID)
		assert.NoError(t, err)
	})
}

// Test Level 5: Temporal Branching & Time-Travel
func TestLevel5_Temporal(t *testing.T) {
	manager := setupTestManager(t)
	ctx := context.Background()

	t.Run("CreateTemporalSnapshot", func(t *testing.T) {
		branchID := "test-branch-temporal"

		snapshot, err := manager.CreateTemporalSnapshot(ctx, branchID)
		assert.NoError(t, err)
		assert.NotNil(t, snapshot)
		assert.NotEmpty(t, snapshot.ID)
		assert.Equal(t, branchID, snapshot.BranchID)
		assert.NotEmpty(t, snapshot.CommitHash)
	})

	t.Run("GetTemporalHistory", func(t *testing.T) {
		branchID := "test-branch-history"
		timeRange := interfaces.TimeRange{
			Start: time.Now().Add(-24 * time.Hour),
			End:   time.Now(),
		}

		snapshots, err := manager.GetTemporalHistory(ctx, branchID, timeRange)
		assert.NoError(t, err)
		assert.NotNil(t, snapshots)
	})

	t.Run("TimeTravelToBranch", func(t *testing.T) {
		// Create a snapshot first
		branchID := "test-branch-timetravel"
		snapshot, err := manager.CreateTemporalSnapshot(ctx, branchID)
		require.NoError(t, err)

		// Time travel to snapshot
		targetTime := snapshot.Timestamp
		err = manager.TimeTravelToBranch(ctx, snapshot.ID, targetTime)
		assert.NoError(t, err)
	})
}

// Test Level 6: Predictive Branching
func TestLevel6_Predictive(t *testing.T) {
	manager := setupTestManager(t)
	ctx := context.Background()

	t.Run("PredictOptimalBranch", func(t *testing.T) {
		intent := interfaces.BranchingIntent{
			Goal:        "implement_user_authentication",
			Context:     map[string]interface{}{"technology": "jwt", "complexity": "medium"},
			Priority:    interfaces.IntentPriorityHigh,
			Constraints: []string{"security_compliant", "mobile_friendly"},
			Deadline:    time.Now().Add(48 * time.Hour),
		}

		prediction, err := manager.PredictOptimalBranch(ctx, intent)
		assert.NoError(t, err)
		assert.NotNil(t, prediction)
		assert.NotEmpty(t, prediction.RecommendedName)
		assert.Greater(t, prediction.Confidence, 0.0)
		assert.LessOrEqual(t, prediction.Confidence, 1.0)
	})

	t.Run("AnalyzeBranchingPatterns", func(t *testing.T) {
		projectID := "test-project-123"

		analysis, err := manager.AnalyzeBranchingPatterns(ctx, projectID)
		assert.NoError(t, err)
		assert.NotNil(t, analysis)
		assert.Equal(t, projectID, analysis.ProjectID)
		assert.NotEmpty(t, analysis.Patterns)
		assert.Greater(t, analysis.EfficiencyScore, 0.0)
	})

	t.Run("OptimizeBranchingStrategy", func(t *testing.T) {
		strategy := interfaces.BranchingStrategy{
			Name:        "feature_branch_strategy",
			Description: "Standard feature branch workflow",
			Rules: []interfaces.BranchingRule{
				{
					Condition: "feature_request",
					Action:    "create_feature_branch",
					Priority:  1,
				},
			},
			Metadata: map[string]interface{}{"version": "1.0"},
		}

		optimizedStrategy, err := manager.OptimizeBranchingStrategy(ctx, strategy)
		assert.NoError(t, err)
		assert.NotNil(t, optimizedStrategy)
		assert.Contains(t, optimizedStrategy.OptimizedStrategy.Name, "optimized")
		assert.Greater(t, optimizedStrategy.ConfidenceScore, 0.0)
	})
}

// Test Level 7: Branching as Code
func TestLevel7_BranchingAsCode(t *testing.T) {
	manager := setupTestManager(t)
	ctx := context.Background()

	t.Run("ValidateBranchingCode_YAML", func(t *testing.T) {
		config := interfaces.BranchingAsCodeConfig{
			ID:       "test-config-yaml",
			Name:     "Test YAML Configuration",
			Language: interfaces.LanguageYAML,
			Code: `
operations:
  - type: create
    name: feature/test-yaml
    config:
      base_branch: main
      description: "Test feature branch"
  - type: create
    name: feature/another-test
    config:
      base_branch: develop
`,
			CreatedAt: time.Now(),
		}

		validation, err := manager.ValidateBranchingCode(ctx, config)
		assert.NoError(t, err)
		assert.NotNil(t, validation)
		assert.True(t, validation.IsValid)
		assert.Empty(t, validation.Errors)
	})

	t.Run("ValidateBranchingCode_JSON", func(t *testing.T) {
		config := interfaces.BranchingAsCodeConfig{
			ID:       "test-config-json",
			Name:     "Test JSON Configuration",
			Language: interfaces.LanguageJSON,
			Code: `{
  "operations": [
    {
      "type": "create",
      "name": "feature/test-json",
      "config": {
        "base_branch": "main",
        "description": "Test feature branch from JSON"
      }
    }
  ]
}`,
			CreatedAt: time.Now(),
		}

		validation, err := manager.ValidateBranchingCode(ctx, config)
		assert.NoError(t, err)
		assert.NotNil(t, validation)
		assert.True(t, validation.IsValid)
		assert.Empty(t, validation.Errors)
	})

	t.Run("ExecuteBranchingAsCode", func(t *testing.T) {
		config := interfaces.BranchingAsCodeConfig{
			ID:       "test-config-execute",
			Name:     "Test Execute Configuration",
			Language: interfaces.LanguageYAML,
			Code: `
operations:
  - type: create
    name: feature/executed-branch
    config:
      base_branch: main
`,
			CreatedAt: time.Now(),
		}

		result, err := manager.ExecuteBranchingAsCode(ctx, config)
		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, interfaces.ExecutionStatusSuccess, result.Status)
		assert.NotEmpty(t, result.CreatedBranches)
	})

	t.Run("LoadBranchingTemplate", func(t *testing.T) {
		templateID := "feature-template"
		params := map[string]interface{}{
			"feature_name": "user_profile",
			"assignee":     "developer1",
		}

		// This would fail in a real scenario without a stored template
		// But tests the method doesn't crash
		config, err := manager.LoadBranchingTemplate(ctx, templateID, params)
		assert.Error(t, err) // Expected since template doesn't exist
		assert.Nil(t, config)
	})
}

// Test Level 8: Quantum Branching
func TestLevel8_QuantumBranching(t *testing.T) {
	manager := setupTestManager(t)
	ctx := context.Background()

	t.Run("CreateQuantumBranch", func(t *testing.T) {
		quantumConfig := interfaces.QuantumBranchConfig{
			Name: "auth_implementation_quantum",
			Goal: "Implement user authentication with multiple approaches",
			Approaches: []interfaces.BranchApproachConfig{
				{
					Name:            "jwt_approach",
					Strategy:        "JWT token-based authentication",
					Parameters:      map[string]interface{}{"token_expiry": "24h"},
					Priority:        1,
					EstimatedEffort: 120, // 2 hours in seconds
				},
				{
					Name:            "session_approach",
					Strategy:        "Session-based authentication",
					Parameters:      map[string]interface{}{"session_store": "redis"},
					Priority:        2,
					EstimatedEffort: 180, // 3 hours in seconds
				},
				{
					Name:            "oauth_approach",
					Strategy:        "OAuth 2.0 integration",
					Parameters:      map[string]interface{}{"providers": []string{"google", "github"}},
					Priority:        3,
					EstimatedEffort: 240, // 4 hours in seconds
				},
			},
			Metadata: map[string]interface{}{
				"project":    "user_system",
				"complexity": "high",
			},
		}

		quantumBranch, err := manager.CreateQuantumBranch(ctx, quantumConfig)
		assert.NoError(t, err)
		assert.NotNil(t, quantumBranch)
		assert.NotEmpty(t, quantumBranch.ID)
		assert.Equal(t, quantumConfig.Name, quantumBranch.Name)
		assert.Equal(t, quantumConfig.Goal, quantumBranch.Goal)
		assert.Equal(t, interfaces.QuantumStatusActive, quantumBranch.Status)
		assert.Len(t, quantumBranch.Approaches, 3)
	})

	t.Run("ExecuteQuantumApproaches", func(t *testing.T) {
		// Create quantum branch first
		quantumConfig := interfaces.QuantumBranchConfig{
			Name: "test_quantum_execution",
			Goal: "Test parallel execution",
			Approaches: []interfaces.BranchApproachConfig{
				{
					Name:            "approach_1",
					Strategy:        "Strategy 1",
					EstimatedEffort: 1, // 1 second for fast test
				},
				{
					Name:            "approach_2",
					Strategy:        "Strategy 2",
					EstimatedEffort: 1, // 1 second for fast test
				},
			},
		}

		quantumBranch, err := manager.CreateQuantumBranch(ctx, quantumConfig)
		require.NoError(t, err)

		// Execute all approaches
		executionResult, err := manager.ExecuteQuantumApproaches(ctx, quantumBranch.ID)
		assert.NoError(t, err)
		assert.NotNil(t, executionResult)
		assert.Equal(t, quantumBranch.ID, executionResult.QuantumBranchID)
		assert.Len(t, executionResult.Results, 2)
		assert.Equal(t, interfaces.QuantumExecutionStatusSuccess, executionResult.Status)
	})

	t.Run("SelectOptimalApproach", func(t *testing.T) {
		// Create mock execution result
		executionResult := &interfaces.QuantumExecutionResult{
			QuantumBranchID: "test-quantum-123",
			Results: []interfaces.ApproachResult{
				{
					ApproachID:    "approach-1",
					ApproachName:  "JWT Approach",
					Success:       true,
					ExecutionTime: 2 * time.Minute,
					Metrics: interfaces.ApproachMetrics{
						LinesOfCode:      500,
						TestCoverage:     95.0,
						ComplexityScore:  3.2,
						PerformanceScore: 88.0,
					},
				},
				{
					ApproachID:    "approach-2",
					ApproachName:  "Session Approach",
					Success:       true,
					ExecutionTime: 3 * time.Minute,
					Metrics: interfaces.ApproachMetrics{
						LinesOfCode:      750,
						TestCoverage:     87.0,
						ComplexityScore:  4.1,
						PerformanceScore: 82.0,
					},
				},
			},
			Status: interfaces.QuantumExecutionStatusSuccess,
		}

		selection, err := manager.SelectOptimalApproach(ctx, executionResult)
		assert.NoError(t, err)
		assert.NotNil(t, selection)
		assert.Equal(t, executionResult.QuantumBranchID, selection.QuantumBranchID)
		assert.NotEmpty(t, selection.OptimalApproachID)
		assert.Greater(t, selection.Confidence, 0.0)
		assert.NotEmpty(t, selection.SelectionReasons)
	})

	t.Run("QuantumBranch_InvalidApproaches", func(t *testing.T) {
		quantumConfig := interfaces.QuantumBranchConfig{
			Name: "invalid_quantum",
			Goal: "Test validation",
			Approaches: []interfaces.BranchApproachConfig{
				{
					Name:     "", // Invalid: empty name
					Strategy: "Some strategy",
				},
			},
		}

		quantumBranch, err := manager.CreateQuantumBranch(ctx, quantumConfig)
		assert.Error(t, err)
		assert.Nil(t, quantumBranch)
	})

	t.Run("QuantumBranch_TooManyApproaches", func(t *testing.T) {
		// Create more approaches than the maximum allowed
		approaches := make([]interfaces.BranchApproachConfig, 10) // Assuming max is 5
		for i := range approaches {
			approaches[i] = interfaces.BranchApproachConfig{
				Name:     fmt.Sprintf("approach_%d", i),
				Strategy: fmt.Sprintf("Strategy %d", i),
			}
		}

		quantumConfig := interfaces.QuantumBranchConfig{
			Name:       "too_many_approaches",
			Goal:       "Test limits",
			Approaches: approaches,
		}

		quantumBranch, err := manager.CreateQuantumBranch(ctx, quantumConfig)
		assert.Error(t, err)
		assert.Nil(t, quantumBranch)
	})
}

// Integration tests
func TestIntegration_FullWorkflow(t *testing.T) {
	manager := setupTestManager(t)
	ctx := context.Background()

	// Start the manager
	err := manager.Start(ctx)
	require.NoError(t, err)

	// Test full workflow: Session -> Event -> Multi-Dim -> Memory -> Temporal -> Predictive -> Code -> Quantum

	// 1. Create a session
	sessionConfig := interfaces.SessionConfig{
		Scope:       "feature/integration-test",
		MaxDuration: 2 * time.Hour,
	}
	session, err := manager.CreateSession(ctx, sessionConfig)
	require.NoError(t, err)

	// 2. Trigger event-driven branch
	event := interfaces.BranchingEvent{
		Type:     interfaces.EventTypeCommit,
		Trigger:  "integration-test",
		Context:  map[string]interface{}{"test": "integration"},
		Priority: interfaces.EventPriorityHigh,
	}
	eventBranch, err := manager.TriggerBranchCreation(ctx, event)
	require.NoError(t, err)

	// 3. Create multi-dimensional branch
	dimensions := []interfaces.BranchDimension{
		{Name: "feature", Value: "integration", Type: interfaces.DimensionTypeFeature, Weight: 0.8},
	}
	multiDimBranch, err := manager.CreateMultiDimBranch(ctx, dimensions)
	require.NoError(t, err)

	// 4. Create temporal snapshot
	snapshot, err := manager.CreateTemporalSnapshot(ctx, multiDimBranch.ID)
	require.NoError(t, err)

	// 5. Predict optimal branch
	intent := interfaces.BranchingIntent{
		Goal:     "complete_integration_test",
		Priority: interfaces.IntentPriorityHigh,
	}
	prediction, err := manager.PredictOptimalBranch(ctx, intent)
	require.NoError(t, err)

	// 6. Execute branching as code
	codeConfig := interfaces.BranchingAsCodeConfig{
		ID:       "integration-code",
		Name:     "Integration Code Test",
		Language: interfaces.LanguageYAML,
		Code:     "operations:\n  - type: create\n    name: feature/code-generated",
	}
	codeResult, err := manager.ExecuteBranchingAsCode(ctx, codeConfig)
	require.NoError(t, err)

	// 7. Create quantum branch
	quantumConfig := interfaces.QuantumBranchConfig{
		Name: "integration_quantum",
		Goal: "Test quantum integration",
		Approaches: []interfaces.BranchApproachConfig{
			{Name: "approach_1", Strategy: "Strategy 1", EstimatedEffort: 1},
		},
	}
	quantumBranch, err := manager.CreateQuantumBranch(ctx, quantumConfig)
	require.NoError(t, err)

	// Verify all components were created successfully
	assert.NotNil(t, session)
	assert.NotNil(t, eventBranch)
	assert.NotNil(t, multiDimBranch)
	assert.NotNil(t, snapshot)
	assert.NotNil(t, prediction)
	assert.NotNil(t, codeResult)
	assert.NotNil(t, quantumBranch)

	// Stop the manager
	err = manager.Stop()
	assert.NoError(t, err)
}

// Benchmark tests
func BenchmarkLevel1_CreateSession(b *testing.B) {
	manager := setupTestManager(b)
	ctx := context.Background()

	sessionConfig := interfaces.SessionConfig{
		Scope:       "benchmark/test",
		MaxDuration: 30 * time.Minute,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := manager.CreateSession(ctx, sessionConfig)
		if err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkLevel8_QuantumBranch(b *testing.B) {
	manager := setupTestManager(b)
	ctx := context.Background()

	quantumConfig := interfaces.QuantumBranchConfig{
		Name: "benchmark_quantum",
		Goal: "Benchmark quantum branching",
		Approaches: []interfaces.BranchApproachConfig{
			{Name: "approach_1", Strategy: "Strategy 1", EstimatedEffort: 1},
			{Name: "approach_2", Strategy: "Strategy 2", EstimatedEffort: 1},
		},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := manager.CreateQuantumBranch(ctx, quantumConfig)
		if err != nil {
			b.Fatal(err)
		}
	}
}

// MockStorageManager implements interfaces.StorageManager for testing
type MockStorageManager struct {
	mock.Mock
}

func (m *MockStorageManager) Store(ctx context.Context, collection, key, value string) error {
	args := m.Called(ctx, collection, key, value)
	return args.Error(0)
}

func (m *MockStorageManager) Health() error {
	args := m.Called()
	return args.Error(0)
}

// Test Level 1: Micro-Sessions Temporelles

func TestCreateSession_Success(t *testing.T) {
	// Setup
	mockStorage := &MockStorageManager{}
	manager := &BranchingManagerImpl{
		config: &BranchingConfig{
			DefaultSessionDuration: 30 * time.Minute,
			AutoArchiveEnabled:     true,
		},
		storageManager: mockStorage,
		activeSessions: make(map[string]*interfaces.Session),
	}

	// Mock expectations
	mockStorage.On("Store", mock.Anything, "sessions", mock.AnythingOfType("string"), mock.AnythingOfType("string")).Return(nil)

	// Test data
	config := interfaces.SessionConfig{
		MaxDuration:   60 * time.Minute,
		AutoArchive:   true,
		NamingPattern: "test-session-{{.ID}}",
		Scope:         "feature-development",
		Metadata: map[string]string{
			"project": "test-project",
			"user":    "test-user",
		},
	}

	// Execute
	ctx := context.Background()
	session, err := manager.CreateSession(ctx, config)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, session)
	assert.NotEmpty(t, session.ID)
	assert.Equal(t, interfaces.SessionStatusActive, session.Status)
	assert.Equal(t, "feature-development", session.Scope)
	assert.Equal(t, 60*time.Minute, session.Duration)
	assert.NotEmpty(t, session.BranchID)

	// Verify session is stored in active sessions
	assert.Contains(t, manager.activeSessions, session.ID)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}

func TestCreateSession_DefaultDuration(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{
		config: &BranchingConfig{
			DefaultSessionDuration: 45 * time.Minute,
		},
		activeSessions: make(map[string]*interfaces.Session),
	}

	// Test data - no duration specified
	config := interfaces.SessionConfig{
		Scope: "test-scope",
	}

	// Execute
	ctx := context.Background()
	session, err := manager.CreateSession(ctx, config)

	// Assert
	assert.NoError(t, err)
	assert.Equal(t, 45*time.Minute, session.Duration)
}

func TestEndSession_Success(t *testing.T) {
	// Setup
	mockStorage := &MockStorageManager{}
	manager := &BranchingManagerImpl{
		config: &BranchingConfig{
			AutoArchiveEnabled: true,
		},
		storageManager: mockStorage,
		activeSessions: make(map[string]*interfaces.Session),
	}

	// Create active session
	sessionID := "test-session-123"
	session := &interfaces.Session{
		ID:        sessionID,
		Status:    interfaces.SessionStatusActive,
		CreatedAt: time.Now(),
	}
	manager.activeSessions[sessionID] = session

	// Mock expectations
	mockStorage.On("Update", mock.Anything, "sessions", sessionID, mock.AnythingOfType("string")).Return(nil)

	// Execute
	ctx := context.Background()
	err := manager.EndSession(ctx, sessionID)

	// Assert
	assert.NoError(t, err)
	assert.Equal(t, interfaces.SessionStatusArchived, session.Status) // Should be archived due to AutoArchiveEnabled
	assert.NotNil(t, session.EndedAt)

	// Session should be removed from active sessions
	assert.NotContains(t, manager.activeSessions, sessionID)

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}

func TestEndSession_NotFound(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{
		activeSessions: make(map[string]*interfaces.Session),
	}

	// Execute
	ctx := context.Background()
	err := manager.EndSession(ctx, "non-existent-session")

	// Assert
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "session non-existent-session not found")
}

func TestGetActiveSession_Success(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{
		activeSessions: make(map[string]*interfaces.Session),
	}

	// Create active session
	activeSession := &interfaces.Session{
		ID:     "active-session",
		Status: interfaces.SessionStatusActive,
	}
	manager.activeSessions["active-session"] = activeSession

	// Execute
	ctx := context.Background()
	session, err := manager.GetActiveSession(ctx)

	// Assert
	assert.NoError(t, err)
	assert.Equal(t, activeSession, session)
}

func TestGetActiveSession_NoActiveSession(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{
		activeSessions: make(map[string]*interfaces.Session),
	}

	// Add ended session
	endedSession := &interfaces.Session{
		ID:     "ended-session",
		Status: interfaces.SessionStatusEnded,
	}
	manager.activeSessions["ended-session"] = endedSession

	// Execute
	ctx := context.Background()
	session, err := manager.GetActiveSession(ctx)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, session)
	assert.Contains(t, err.Error(), "no active session found")
}

// Test Level 2: Event-Driven Branching

func TestTriggerBranchCreation_Success(t *testing.T) {
	// Setup
	mockStorage := &MockStorageManager{}
	manager := &BranchingManagerImpl{
		config:         &BranchingConfig{},
		storageManager: mockStorage,
	}

	// Mock expectations
	mockStorage.On("Store", mock.Anything, "branches", mock.AnythingOfType("string"), mock.AnythingOfType("string")).Return(nil)

	// Test data
	event := interfaces.BranchingEvent{
		Type:    interfaces.EventTypeCommit,
		Trigger: "commit-trigger",
		Context: map[string]interface{}{
			"commit_hash":    "abc123def456",
			"commit_message": "fix: critical bug in user authentication",
			"author":         "test-user",
		},
		AutoCreated: true,
		Priority:    interfaces.EventPriorityHigh,
		CreatedAt:   time.Now(),
	}

	// Execute
	ctx := context.Background()
	branch, err := manager.TriggerBranchCreation(ctx, event)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, branch)
	assert.NotEmpty(t, branch.ID)
	assert.NotEmpty(t, branch.Name)
	assert.Equal(t, "main", branch.BaseBranch)
	assert.Equal(t, interfaces.BranchStatusActive, branch.Status)
	assert.Equal(t, 2, branch.Level) // Level 2: Event-Driven
	assert.Contains(t, branch.Name, "commit")
	assert.Equal(t, "commit", branch.Metadata["event_type"])
	assert.Equal(t, "commit-trigger", branch.Metadata["trigger"])

	// Verify mock expectations
	mockStorage.AssertExpectations(t)
}

func TestProcessGitHook_Success(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{
		config: &BranchingConfig{
			GitHooksEnabled: true,
			EventQueueSize:  100,
		},
		eventQueue: make(chan interfaces.BranchingEvent, 100),
	}

	// Test data
	payload := map[string]interface{}{
		"ref":        "refs/heads/main",
		"commit_id":  "abc123def456",
		"repository": "test-repo",
	}

	// Execute
	ctx := context.Background()
	err := manager.ProcessGitHook(ctx, "pre-commit", payload)

	// Assert
	assert.NoError(t, err)

	// Verify event was queued
	assert.Equal(t, 1, len(manager.eventQueue))

	// Get the queued event
	event := <-manager.eventQueue
	assert.Equal(t, interfaces.EventTypeCommit, event.Type)
	assert.Equal(t, "git_hook_pre-commit", event.Trigger)
	assert.True(t, event.AutoCreated)
	assert.Equal(t, interfaces.EventPriorityMedium, event.Priority)
}

func TestProcessGitHook_Disabled(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{
		config: &BranchingConfig{
			GitHooksEnabled: false,
		},
	}

	// Execute
	ctx := context.Background()
	err := manager.ProcessGitHook(ctx, "pre-commit", map[string]interface{}{})

	// Assert
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "git hooks are disabled")
}

func TestHandleEventDriven_Success(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{
		config: &BranchingConfig{
			AutoBranchingEnabled: true,
			EventQueueSize:       100,
		},
		eventQueue: make(chan interfaces.BranchingEvent, 100),
	}

	// Test data
	context := map[string]interface{}{
		"issue_id":    "ISS-123",
		"issue_title": "Critical bug in payment system",
		"priority":    "high",
		"assignee":    "test-user",
	}

	// Execute
	ctx := context.Background()
	err := manager.HandleEventDriven(ctx, "issue", context)

	// Assert
	assert.NoError(t, err)

	// Verify event was queued
	assert.Equal(t, 1, len(manager.eventQueue))

	// Get the queued event
	event := <-manager.eventQueue
	assert.Equal(t, interfaces.EventType("issue"), event.Type)
	assert.Equal(t, "manual_trigger", event.Trigger)
	assert.False(t, event.AutoCreated)
	assert.Equal(t, interfaces.EventPriorityMedium, event.Priority)
	assert.Contains(t, event.Context, "event_id")
}

func TestHandleEventDriven_Disabled(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{
		config: &BranchingConfig{
			AutoBranchingEnabled: false,
		},
	}

	// Execute
	ctx := context.Background()
	err := manager.HandleEventDriven(ctx, "test", map[string]interface{}{})

	// Assert
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "auto-branching is disabled")
}

// Test Helper Functions

func TestGenerateEventBranchName_WithIssueID(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{}

	// Test data
	event := interfaces.BranchingEvent{
		Type: interfaces.EventTypeIssue,
		Context: map[string]interface{}{
			"issue_id": "ISS-456",
		},
	}

	// Execute
	branchName := manager.generateEventBranchName(event)

	// Assert
	assert.Contains(t, branchName, "event-issue")
	assert.Contains(t, branchName, "issue-ISS-456")
	assert.Contains(t, branchName, time.Now().Format("20060102"))
}

func TestGenerateEventBranchName_WithCommitHash(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{}

	// Test data
	event := interfaces.BranchingEvent{
		Type: interfaces.EventTypeCommit,
		Context: map[string]interface{}{
			"commit_hash": "abcdef123456789",
		},
	}

	// Execute
	branchName := manager.generateEventBranchName(event)

	// Assert
	assert.Contains(t, branchName, "event-commit")
	assert.Contains(t, branchName, "commit-abcdef12")
	assert.Contains(t, branchName, time.Now().Format("20060102"))
}

func TestMapHookTypeToEventType(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{}

	// Test cases
	testCases := []struct {
		hookType string
		expected interfaces.EventType
	}{
		{"pre-commit", interfaces.EventTypeCommit},
		{"post-commit", interfaces.EventTypeCommit},
		{"pre-push", interfaces.EventTypePush},
		{"post-receive", interfaces.EventTypePush},
		{"unknown-hook", interfaces.EventTypeSystemTrigger},
	}

	// Execute and Assert
	for _, tc := range testCases {
		result := manager.mapHookTypeToEventType(tc.hookType)
		assert.Equal(t, tc.expected, result, "Failed for hook type: %s", tc.hookType)
	}
}

func TestGetHookPriority(t *testing.T) {
	// Setup
	manager := &BranchingManagerImpl{}

	// Test cases
	testCases := []struct {
		hookType string
		expected interfaces.EventPriority
	}{
		{"pre-receive", interfaces.EventPriorityCritical},
		{"pre-push", interfaces.EventPriorityHigh},
		{"post-receive", interfaces.EventPriorityHigh},
		{"pre-commit", interfaces.EventPriorityMedium},
		{"unknown-hook", interfaces.EventPriorityLow},
	}

	// Execute and Assert
	for _, tc := range testCases {
		result := manager.getHookPriority(tc.hookType)
		assert.Equal(t, tc.expected, result, "Failed for hook type: %s", tc.hookType)
	}
}
