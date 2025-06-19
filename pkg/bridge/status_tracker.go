package bridge

import (
	"sync"
	"time"

	"go.uber.org/zap"
)

// WorkflowStatus represents the status of a workflow execution
type WorkflowStatus struct {
	WorkflowID  string                 `json:"workflow_id"`
	ExecutionID string                 `json:"execution_id"`
	Status      string                 `json:"status"`
	LastUpdate  time.Time              `json:"last_update"`
	Progress    int                    `json:"progress"`
	Error       *string                `json:"error,omitempty"`
	Data        map[string]interface{} `json:"data,omitempty"`
}

// StatusUpdate represents an update to workflow status
type StatusUpdate struct {
	WorkflowID  string                 `json:"workflow_id"`
	ExecutionID string                 `json:"execution_id"`
	Status      string                 `json:"status"`
	LastUpdate  time.Time              `json:"last_update"`
	Progress    int                    `json:"progress"`
	Error       *string                `json:"error,omitempty"`
	Data        map[string]interface{} `json:"data,omitempty"`
}

// StatusTracker interface defines status tracking operations
type StatusTracker interface {
	UpdateStatus(workflowID string, update StatusUpdate) error
	GetStatus(workflowID string) (*WorkflowStatus, bool)
	GetAllStatuses() map[string]*WorkflowStatus
	DeleteStatus(workflowID string) error
	GetExpiredStatuses(olderThan time.Duration) []string
	CleanupExpiredStatuses(olderThan time.Duration) int
	GetStatusCount() int
}

// MemoryStatusTracker implements StatusTracker using in-memory storage
type MemoryStatusTracker struct {
	statuses map[string]*WorkflowStatus
	mu       sync.RWMutex
	logger   *zap.Logger
	ttl      time.Duration
}

// NewMemoryStatusTracker creates a new memory-based status tracker
func NewMemoryStatusTracker(logger *zap.Logger, ttl time.Duration) *MemoryStatusTracker {
	if ttl == 0 {
		ttl = 24 * time.Hour // Default TTL of 24 hours
	}

	return &MemoryStatusTracker{
		statuses: make(map[string]*WorkflowStatus),
		logger:   logger,
		ttl:      ttl,
	}
}

// UpdateStatus updates the status of a workflow
func (tracker *MemoryStatusTracker) UpdateStatus(workflowID string, update StatusUpdate) error {
	tracker.mu.Lock()
	defer tracker.mu.Unlock()

	// Convert StatusUpdate to WorkflowStatus
	status := &WorkflowStatus{
		WorkflowID:  update.WorkflowID,
		ExecutionID: update.ExecutionID,
		Status:      update.Status,
		LastUpdate:  update.LastUpdate,
		Progress:    update.Progress,
		Error:       update.Error,
		Data:        update.Data,
	}

	if status.LastUpdate.IsZero() {
		status.LastUpdate = time.Now()
	}

	tracker.statuses[workflowID] = status

	tracker.logger.Debug("Status updated",
		zap.String("workflow_id", workflowID),
		zap.String("status", status.Status),
		zap.Int("progress", status.Progress))

	return nil
}

// GetStatus retrieves the status of a workflow
func (tracker *MemoryStatusTracker) GetStatus(workflowID string) (*WorkflowStatus, bool) {
	tracker.mu.RLock()
	defer tracker.mu.RUnlock()

	status, exists := tracker.statuses[workflowID]
	if !exists {
		return nil, false
	}

	// Check if status has expired
	if time.Since(status.LastUpdate) > tracker.ttl {
		// Status expired, clean it up
		go func() {
			tracker.mu.Lock()
			delete(tracker.statuses, workflowID)
			tracker.mu.Unlock()
			tracker.logger.Debug("Expired status cleaned up",
				zap.String("workflow_id", workflowID))
		}()
		return nil, false
	}

	// Return a copy to avoid race conditions
	statusCopy := *status
	return &statusCopy, true
}

// GetAllStatuses returns all current statuses
func (tracker *MemoryStatusTracker) GetAllStatuses() map[string]*WorkflowStatus {
	tracker.mu.RLock()
	defer tracker.mu.RUnlock()

	// Return copies to avoid race conditions
	result := make(map[string]*WorkflowStatus)
	now := time.Now()

	for workflowID, status := range tracker.statuses {
		// Skip expired statuses
		if now.Sub(status.LastUpdate) <= tracker.ttl {
			statusCopy := *status
			result[workflowID] = &statusCopy
		}
	}

	return result
}

// DeleteStatus removes the status of a workflow
func (tracker *MemoryStatusTracker) DeleteStatus(workflowID string) error {
	tracker.mu.Lock()
	defer tracker.mu.Unlock()

	delete(tracker.statuses, workflowID)

	tracker.logger.Debug("Status deleted",
		zap.String("workflow_id", workflowID))

	return nil
}

// GetExpiredStatuses returns workflow IDs with expired statuses
func (tracker *MemoryStatusTracker) GetExpiredStatuses(olderThan time.Duration) []string {
	tracker.mu.RLock()
	defer tracker.mu.RUnlock()

	var expired []string
	cutoff := time.Now().Add(-olderThan)

	for workflowID, status := range tracker.statuses {
		if status.LastUpdate.Before(cutoff) {
			expired = append(expired, workflowID)
		}
	}

	return expired
}

// CleanupExpiredStatuses removes statuses older than the specified duration
func (tracker *MemoryStatusTracker) CleanupExpiredStatuses(olderThan time.Duration) int {
	tracker.mu.Lock()
	defer tracker.mu.Unlock()

	cutoff := time.Now().Add(-olderThan)
	var cleaned []string

	for workflowID, status := range tracker.statuses {
		if status.LastUpdate.Before(cutoff) {
			cleaned = append(cleaned, workflowID)
			delete(tracker.statuses, workflowID)
		}
	}

	if len(cleaned) > 0 {
		tracker.logger.Info("Cleaned up expired statuses",
			zap.Int("count", len(cleaned)),
			zap.Strings("workflow_ids", cleaned))
	}

	return len(cleaned)
}

// GetStatusCount returns the current number of tracked statuses
func (tracker *MemoryStatusTracker) GetStatusCount() int {
	tracker.mu.RLock()
	defer tracker.mu.RUnlock()

	return len(tracker.statuses)
}

// GetStatusesByStatus returns statuses filtered by status value
func (tracker *MemoryStatusTracker) GetStatusesByStatus(statusFilter string) map[string]*WorkflowStatus {
	tracker.mu.RLock()
	defer tracker.mu.RUnlock()

	result := make(map[string]*WorkflowStatus)
	now := time.Now()

	for workflowID, status := range tracker.statuses {
		// Skip expired statuses
		if now.Sub(status.LastUpdate) <= tracker.ttl && status.Status == statusFilter {
			statusCopy := *status
			result[workflowID] = &statusCopy
		}
	}

	return result
}

// GetStatusesWithProgress returns statuses with progress information
func (tracker *MemoryStatusTracker) GetStatusesWithProgress() map[string]*WorkflowStatus {
	tracker.mu.RLock()
	defer tracker.mu.RUnlock()

	result := make(map[string]*WorkflowStatus)
	now := time.Now()

	for workflowID, status := range tracker.statuses {
		// Skip expired statuses and include only those with progress > 0
		if now.Sub(status.LastUpdate) <= tracker.ttl && status.Progress > 0 {
			statusCopy := *status
			result[workflowID] = &statusCopy
		}
	}

	return result
}

// GetStatistics returns statistics about the status tracker
func (tracker *MemoryStatusTracker) GetStatistics() map[string]interface{} {
	tracker.mu.RLock()
	defer tracker.mu.RUnlock()

	stats := map[string]interface{}{
		"total_statuses":   len(tracker.statuses),
		"ttl_hours":        tracker.ttl.Hours(),
		"status_breakdown": make(map[string]int),
	}

	statusBreakdown := make(map[string]int)
	now := time.Now()

	for _, status := range tracker.statuses {
		// Only count non-expired statuses
		if now.Sub(status.LastUpdate) <= tracker.ttl {
			statusBreakdown[status.Status]++
		}
	}

	stats["status_breakdown"] = statusBreakdown
	return stats
}

// StartCleanupRoutine starts a background routine to periodically clean up expired statuses
func (tracker *MemoryStatusTracker) StartCleanupRoutine(interval time.Duration) {
	if interval == 0 {
		interval = 10 * time.Minute // Default cleanup interval
	}

	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()

		for range ticker.C {
			cleaned := tracker.CleanupExpiredStatuses(tracker.ttl)
			if cleaned > 0 {
				tracker.logger.Info("Periodic cleanup completed",
					zap.Int("cleaned_count", cleaned))
			}
		}
	}()

	tracker.logger.Info("Status tracker cleanup routine started",
		zap.Duration("interval", interval),
		zap.Duration("ttl", tracker.ttl))
}
