// FILE: development/hooks/commit-interceptor/router_test.go
package commitinterceptor

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestBranchRouter_RouteCommit(t *testing.T) {
	router := NewBranchRouter(getTestConfig())

	analysis := &CommitAnalysis{
		ChangeType:	"feature",
		Impact:		"medium",
		Confidence:	0.95,
		CommitData: &CommitData{
			Hash:		"test123",
			Message:	"feat: add user authentication system",
			Author:		"Test User",
			Timestamp:	time.Now(),
			Files:		[]string{"auth.go"},
			Branch:		"main",
		},
	}

	result, err := router.RouteCommit(analysis)

	require.NoError(t, err)
	assert.Contains(t, result.TargetBranch, "feature/")
	assert.Greater(t, result.Confidence, 0.0)
	assert.NotEmpty(t, result.Reason)
}

func TestBranchRouter_DryRunMode(t *testing.T) {
	config := getTestConfig()
	config.TestMode = true
	router := NewBranchRouter(config)

	analysis := &CommitAnalysis{
		ChangeType:	"feature",
		Impact:		"medium",
		Confidence:	0.95,
		CommitData: &CommitData{
			Hash:		"dryrun123",
			Message:	"feat: test dry run mode",
			Author:		"Test User",
			Timestamp:	time.Now(),
			Files:		[]string{"test.go"},
			Branch:		"main",
		},
	}

	result, err := router.RouteCommit(analysis)

	require.NoError(t, err)
	assert.Contains(t, result.TargetBranch, "feature/")
	assert.NotEmpty(t, result.Reason)
}

func TestBranchRouter_EdgeCases(t *testing.T) {
	router := NewBranchRouter(getTestConfig())

	analysis := &CommitAnalysis{
		ChangeType:	"feature",
		Impact:		"medium",
		Confidence:	0.9,
		CommitData: &CommitData{
			Hash:		"special123",
			Message:	"feat: add special chars éàü-_@#$%",
			Files:		[]string{"test.go"},
			Branch:		"main",
		},
	}

	result, err := router.RouteCommit(analysis)

	assert.NoError(t, err)
	assert.NotEmpty(t, result.TargetBranch)
}
