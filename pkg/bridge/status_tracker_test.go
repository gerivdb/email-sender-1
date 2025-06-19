package bridge

import (
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

func TestMemoryStatusTracker_UpdateAndGetStatus(t *testing.T) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	update := StatusUpdate{
		WorkflowID:  "test-workflow-1",
		ExecutionID: "exec-1",
		Status:      "running",
		Progress:    50,
		Data:        map[string]interface{}{"step": "processing"},
	}

	err := tracker.UpdateStatus("test-workflow-1", update)
	require.NoError(t, err)

	status, exists := tracker.GetStatus("test-workflow-1")
	require.True(t, exists)
	assert.Equal(t, "test-workflow-1", status.WorkflowID)
	assert.Equal(t, "exec-1", status.ExecutionID)
	assert.Equal(t, "running", status.Status)
	assert.Equal(t, 50, status.Progress)
	assert.Equal(t, "processing", status.Data["step"])
}

func TestMemoryStatusTracker_UpdateWithError(t *testing.T) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	errorMsg := "Something went wrong"
	update := StatusUpdate{
		WorkflowID:  "test-workflow-2",
		ExecutionID: "exec-2",
		Status:      "failed",
		Error:       &errorMsg,
	}

	err := tracker.UpdateStatus("test-workflow-2", update)
	require.NoError(t, err)

	status, exists := tracker.GetStatus("test-workflow-2")
	require.True(t, exists)
	assert.Equal(t, "failed", status.Status)
	require.NotNil(t, status.Error)
	assert.Equal(t, "Something went wrong", *status.Error)
}

func TestMemoryStatusTracker_GetAllStatuses(t *testing.T) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	// Add multiple statuses
	updates := []StatusUpdate{
		{WorkflowID: "wf-1", Status: "running", Progress: 25},
		{WorkflowID: "wf-2", Status: "completed", Progress: 100},
		{WorkflowID: "wf-3", Status: "failed", Progress: 75},
	}

	for _, update := range updates {
		tracker.UpdateStatus(update.WorkflowID, update)
	}

	allStatuses := tracker.GetAllStatuses()
	assert.Len(t, allStatuses, 3)

	assert.Contains(t, allStatuses, "wf-1")
	assert.Contains(t, allStatuses, "wf-2")
	assert.Contains(t, allStatuses, "wf-3")

	assert.Equal(t, "running", allStatuses["wf-1"].Status)
	assert.Equal(t, "completed", allStatuses["wf-2"].Status)
	assert.Equal(t, "failed", allStatuses["wf-3"].Status)
}

func TestMemoryStatusTracker_DeleteStatus(t *testing.T) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	update := StatusUpdate{
		WorkflowID: "test-delete",
		Status:     "running",
	}

	tracker.UpdateStatus("test-delete", update)

	// Verify it exists
	_, exists := tracker.GetStatus("test-delete")
	assert.True(t, exists)

	// Delete it
	err := tracker.DeleteStatus("test-delete")
	require.NoError(t, err)

	// Verify it's gone
	_, exists = tracker.GetStatus("test-delete")
	assert.False(t, exists)
}

func TestMemoryStatusTracker_TTLExpiration(t *testing.T) {
	logger := zap.NewNop()
	shortTTL := 100 * time.Millisecond
	tracker := NewMemoryStatusTracker(logger, shortTTL)

	update := StatusUpdate{
		WorkflowID: "test-ttl",
		Status:     "running",
		LastUpdate: time.Now().Add(-shortTTL * 2), // Already expired
	}

	tracker.UpdateStatus("test-ttl", update)

	// Should be expired and automatically cleaned up
	_, exists := tracker.GetStatus("test-ttl")
	assert.False(t, exists)
}

func TestMemoryStatusTracker_CleanupExpiredStatuses(t *testing.T) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	// Add some statuses with different ages
	now := time.Now()
	updates := []StatusUpdate{
		{WorkflowID: "fresh", Status: "running", LastUpdate: now},
		{WorkflowID: "old1", Status: "completed", LastUpdate: now.Add(-2 * time.Hour)},
		{WorkflowID: "old2", Status: "failed", LastUpdate: now.Add(-3 * time.Hour)},
	}

	for _, update := range updates {
		tracker.UpdateStatus(update.WorkflowID, update)
	}

	// Clean up statuses older than 1 hour
	cleaned := tracker.CleanupExpiredStatuses(time.Hour)
	assert.Equal(t, 2, cleaned)

	// Only fresh status should remain
	allStatuses := tracker.GetAllStatuses()
	assert.Len(t, allStatuses, 1)
	assert.Contains(t, allStatuses, "fresh")
}

func TestMemoryStatusTracker_GetExpiredStatuses(t *testing.T) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	// Add statuses with different ages
	now := time.Now()
	updates := []StatusUpdate{
		{WorkflowID: "fresh", Status: "running", LastUpdate: now},
		{WorkflowID: "old1", Status: "completed", LastUpdate: now.Add(-2 * time.Hour)},
		{WorkflowID: "old2", Status: "failed", LastUpdate: now.Add(-3 * time.Hour)},
	}

	for _, update := range updates {
		tracker.UpdateStatus(update.WorkflowID, update)
	}

	expired := tracker.GetExpiredStatuses(time.Hour)
	assert.Len(t, expired, 2)
	assert.Contains(t, expired, "old1")
	assert.Contains(t, expired, "old2")
}

func TestMemoryStatusTracker_GetStatusesByStatus(t *testing.T) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	updates := []StatusUpdate{
		{WorkflowID: "wf-1", Status: "running", Progress: 25},
		{WorkflowID: "wf-2", Status: "running", Progress: 50},
		{WorkflowID: "wf-3", Status: "completed", Progress: 100},
		{WorkflowID: "wf-4", Status: "failed", Progress: 75},
	}

	for _, update := range updates {
		tracker.UpdateStatus(update.WorkflowID, update)
	}

	runningStatuses := tracker.GetStatusesByStatus("running")
	assert.Len(t, runningStatuses, 2)
	assert.Contains(t, runningStatuses, "wf-1")
	assert.Contains(t, runningStatuses, "wf-2")

	completedStatuses := tracker.GetStatusesByStatus("completed")
	assert.Len(t, completedStatuses, 1)
	assert.Contains(t, completedStatuses, "wf-3")
}

func TestMemoryStatusTracker_GetStatusesWithProgress(t *testing.T) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	updates := []StatusUpdate{
		{WorkflowID: "wf-1", Status: "running", Progress: 25},
		{WorkflowID: "wf-2", Status: "running", Progress: 0}, // No progress
		{WorkflowID: "wf-3", Status: "completed", Progress: 100},
	}

	for _, update := range updates {
		tracker.UpdateStatus(update.WorkflowID, update)
	}

	statusesWithProgress := tracker.GetStatusesWithProgress()
	assert.Len(t, statusesWithProgress, 2) // Only wf-1 and wf-3 have progress > 0
	assert.Contains(t, statusesWithProgress, "wf-1")
	assert.Contains(t, statusesWithProgress, "wf-3")
	assert.NotContains(t, statusesWithProgress, "wf-2")
}

func TestMemoryStatusTracker_GetStatistics(t *testing.T) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	updates := []StatusUpdate{
		{WorkflowID: "wf-1", Status: "running"},
		{WorkflowID: "wf-2", Status: "running"},
		{WorkflowID: "wf-3", Status: "completed"},
		{WorkflowID: "wf-4", Status: "failed"},
	}

	for _, update := range updates {
		tracker.UpdateStatus(update.WorkflowID, update)
	}

	stats := tracker.GetStatistics()
	assert.Equal(t, 4, stats["total_statuses"])
	assert.Equal(t, 1.0, stats["ttl_hours"])

	breakdown := stats["status_breakdown"].(map[string]int)
	assert.Equal(t, 2, breakdown["running"])
	assert.Equal(t, 1, breakdown["completed"])
	assert.Equal(t, 1, breakdown["failed"])
}

func TestMemoryStatusTracker_GetStatusCount(t *testing.T) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	assert.Equal(t, 0, tracker.GetStatusCount())

	update := StatusUpdate{WorkflowID: "test", Status: "running"}
	tracker.UpdateStatus("test", update)

	assert.Equal(t, 1, tracker.GetStatusCount())

	tracker.DeleteStatus("test")
	assert.Equal(t, 0, tracker.GetStatusCount())
}

func TestMemoryStatusTracker_ConcurrentAccess(t *testing.T) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	const numGoroutines = 10
	const numOperations = 100

	// Test concurrent updates and reads
	done := make(chan bool, numGoroutines)

	for i := 0; i < numGoroutines; i++ {
		go func(id int) {
			for j := 0; j < numOperations; j++ {
				workflowID := fmt.Sprintf("wf-%d-%d", id, j)
				update := StatusUpdate{
					WorkflowID: workflowID,
					Status:     "running",
					Progress:   j % 100,
				}

				tracker.UpdateStatus(workflowID, update)

				// Read back the status
				if status, exists := tracker.GetStatus(workflowID); exists {
					assert.Equal(t, "running", status.Status)
				}
			}
			done <- true
		}(i)
	}

	// Wait for all goroutines to complete
	for i := 0; i < numGoroutines; i++ {
		<-done
	}

	// Verify final state
	assert.Equal(t, numGoroutines*numOperations, tracker.GetStatusCount())
}

func BenchmarkMemoryStatusTracker_UpdateStatus(b *testing.B) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	update := StatusUpdate{
		WorkflowID: "bench-test",
		Status:     "running",
		Progress:   50,
	}

	b.ResetTimer()
	b.RunParallel(func(pb *testing.PB) {
		i := 0
		for pb.Next() {
			workflowID := fmt.Sprintf("bench-%d", i)
			update.WorkflowID = workflowID
			tracker.UpdateStatus(workflowID, update)
			i++
		}
	})
}

func BenchmarkMemoryStatusTracker_GetStatus(b *testing.B) {
	logger := zap.NewNop()
	tracker := NewMemoryStatusTracker(logger, time.Hour)

	// Pre-populate with some statuses
	for i := 0; i < 1000; i++ {
		update := StatusUpdate{
			WorkflowID: fmt.Sprintf("bench-%d", i),
			Status:     "running",
			Progress:   i % 100,
		}
		tracker.UpdateStatus(update.WorkflowID, update)
	}

	b.ResetTimer()
	b.RunParallel(func(pb *testing.PB) {
		i := 0
		for pb.Next() {
			workflowID := fmt.Sprintf("bench-%d", i%1000)
			tracker.GetStatus(workflowID)
			i++
		}
	})
}
