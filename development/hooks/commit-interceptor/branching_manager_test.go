// FILE: development/hooks/commit-interceptor/branching_manager_test.go
package commitinterceptor

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ========================================================================
// TESTS SPÉCIALISÉS DU GESTIONNAIRE DE BRANCHEMENT
// ========================================================================

func TestBranchingManager_ExecuteRouting(t *testing.T) {
	config := getTestConfig()
	config.TestMode = true	// Enable test mode to simulate Git operations
	manager := NewBranchingManager(config)

	routingTestCases := []struct {
		name		string
		branchDecision	*BranchDecision
		expectedError	bool
	}{
		{
			name:	"Create new feature branch",
			branchDecision: &BranchDecision{
				TargetBranch:		"feature/user-auth-123456",
				CreateBranch:		true,
				MergeStrategy:		"auto",
				ConflictStrategy:	"abort",
				Metadata:		map[string]string{"type": "feature"},
				Reason:			"New feature branch for user authentication",
				Confidence:		0.95,
			},
			expectedError:	false,
		},
		{
			name:	"Merge to existing develop branch",
			branchDecision: &BranchDecision{
				TargetBranch:		"develop",
				CreateBranch:		false,
				MergeStrategy:		"fast-forward",
				ConflictStrategy:	"resolve",
				Metadata:		map[string]string{"type": "merge"},
				Reason:			"Merge fix to develop",
				Confidence:		0.90,
			},
			expectedError:	false,
		},
	}

	for _, tc := range routingTestCases {
		t.Run(tc.name, func(t *testing.T) {
			err := manager.ExecuteRouting(tc.branchDecision)

			if tc.expectedError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestBranchingManager_SimulateGitOperations(t *testing.T) {
	config := getTestConfig()
	config.TestMode = true
	manager := NewBranchingManager(config)

	decision := &BranchDecision{
		TargetBranch:		"feature/test-simulation",
		CreateBranch:		true,
		MergeStrategy:		"auto",
		ConflictStrategy:	"abort",
		Metadata:		map[string]string{"test": "simulation"},
		Reason:			"Test Git operation simulation",
		Confidence:		0.95,
	}

	// In test mode, this should simulate without real Git operations
	err := manager.ExecuteRouting(decision)
	assert.NoError(t, err, "Simulation should not fail")
}

func BenchmarkBranchingManager_ExecuteRouting(b *testing.B) {
	config := getTestConfig()
	config.TestMode = true
	manager := NewBranchingManager(config)

	decision := &BranchDecision{
		TargetBranch:		"benchmark/performance-test",
		CreateBranch:		true,
		MergeStrategy:		"auto",
		ConflictStrategy:	"abort",
		Metadata:		map[string]string{"benchmark": "true"},
		Reason:			"Performance benchmark test",
		Confidence:		0.95,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		err := manager.ExecuteRouting(decision)
		if err != nil {
			b.Fatal(err)
		}
	}
}

// ========================================================================
// TESTS D'INTÉGRATION WORKFLOW COMPLET
// ========================================================================

func TestBranchingManager_FullWorkflow_Integration(t *testing.T) {
	config := getTestConfig()
	config.TestMode = true

	router := NewBranchRouter(config)
	manager := NewBranchingManager(config)

	workflows := []struct {
		name		string
		analysis	*CommitAnalysis
	}{
		{
			name:	"Feature Development Workflow",
			analysis: &CommitAnalysis{
				ChangeType:	"feature",
				Impact:		"medium",
				Confidence:	0.95,
				CommitData: &CommitData{
					Hash:		"workflow123",
					Message:	"feat: implement user profile management",
					Author:		"Developer",
					Timestamp:	time.Now(),
					Files:		[]string{"profile.go", "profile_test.go"},
					Branch:		"main",
				},
			},
		},
		{
			name:	"Critical Hotfix Workflow",
			analysis: &CommitAnalysis{
				ChangeType:	"fix",
				Impact:		"high",
				Confidence:	0.98,
				CommitData: &CommitData{
					Hash:		"workflow124",
					Message:	"fix: critical security vulnerability",
					Author:		"Security Team",
					Timestamp:	time.Now(),
					Files:		[]string{"auth.go"},
					Branch:		"main",
				},
			},
		},
	}

	for _, workflow := range workflows {
		t.Run(workflow.name, func(t *testing.T) {
			// Step 1: Route the commit
			routingResult, err := router.RouteCommit(workflow.analysis)
			require.NoError(t, err)

			// Step 2: Execute the routing decision
			err = manager.ExecuteRouting(routingResult)
			require.NoError(t, err)

			// Step 3: Validate results
			assert.NotEmpty(t, routingResult.TargetBranch)
			assert.NotEmpty(t, routingResult.Reason)
			assert.Greater(t, routingResult.Confidence, 0.0)
		})
	}
}
