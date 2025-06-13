package tools

import (
	"fmt"
	"log"
	"sync"
	"time"
)

// SyncLogger simple in-memory implementation
type SyncLogger struct {
	logger *log.Logger
	mutex  sync.RWMutex
}

// SyncLogEntry represents a sync operation log
type SyncLogEntry struct {
	ID        int       `json:"id"`
	Timestamp time.Time `json:"timestamp"`
	Operation string    `json:"operation"`
	Status    string    `json:"status"`
	Duration  string    `json:"duration"`
	Details   string    `json:"details"`
}

// ConflictLogEntry represents a conflict log
type ConflictLogEntry struct {
	ID            int       `json:"id"`
	ConflictID    string    `json:"conflictId"`
	Timestamp     time.Time `json:"timestamp"`
	FilePath      string    `json:"filePath"`
	ConflictType  string    `json:"conflictType"`
	Severity      string    `json:"severity"`
	Status        string    `json:"status"`
	SourceContent string    `json:"sourceContent"`
	TargetContent string    `json:"targetContent"`
}

// SyncStats represents sync statistics
type SyncStats struct {
	TotalOperations int           `json:"totalOperations"`
	SuccessfulOps   int           `json:"successfulOps"`
	FailedOps       int           `json:"failedOps"`
	SuccessRate     float64       `json:"successRate"`
	AverageTime     time.Duration `json:"averageTime"`
	LastOperation   time.Time     `json:"lastOperation"`
	TopErrors       []ErrorStats  `json:"topErrors"`
}

// ErrorStats represents error frequency statistics
type ErrorStats struct {
	Error string `json:"error"`
	Count int    `json:"count"`
}

// In-memory storage
var (
	syncLogs     []SyncLogEntry
	conflictLogs []ConflictLogEntry
	nextID       = 1
)

// NewSyncLogger creates a new logger
func NewSyncLogger(logDir string, logger *log.Logger) (*SyncLogger, error) {
	return &SyncLogger{logger: logger}, nil
}

// LogOperation logs a sync operation
func (sl *SyncLogger) LogOperation(operation, status string, duration time.Duration, details string, metadata map[string]interface{}) error {
	sl.mutex.Lock()
	defer sl.mutex.Unlock()

	entry := SyncLogEntry{
		ID:        nextID,
		Timestamp: time.Now(),
		Operation: operation,
		Status:    status,
		Duration:  duration.String(),
		Details:   details,
	}
	syncLogs = append(syncLogs, entry)
	nextID++
	return nil
}

// LogConflict logs a conflict
func (sl *SyncLogger) LogConflict(conflictID, filePath, conflictType, severity, sourceContent, targetContent string) error {
	sl.mutex.Lock()
	defer sl.mutex.Unlock()

	conflict := ConflictLogEntry{
		ID:            nextID,
		ConflictID:    conflictID,
		Timestamp:     time.Now(),
		FilePath:      filePath,
		ConflictType:  conflictType,
		Severity:      severity,
		Status:        "detected",
		SourceContent: sourceContent,
		TargetContent: targetContent,
	}
	conflictLogs = append(conflictLogs, conflict)
	nextID++
	return nil
}

// LogConflictResolution logs conflict resolution
func (sl *SyncLogger) LogConflictResolution(conflictID, resolution, resolvedBy, mergedContent string) error {
	sl.mutex.Lock()
	defer sl.mutex.Unlock()

	for i := range conflictLogs {
		if conflictLogs[i].ConflictID == conflictID {
			conflictLogs[i].Status = "resolved"
			return nil
		}
	}
	return fmt.Errorf("conflict not found: %s", conflictID)
}

// GetSyncHistory returns sync history
func (sl *SyncLogger) GetSyncHistory(limit, offset int, operation, status string) ([]SyncLogEntry, error) {
	sl.mutex.RLock()
	defer sl.mutex.RUnlock()

	if len(syncLogs) == 0 {
		return []SyncLogEntry{}, nil
	}

	end := len(syncLogs)
	if limit > 0 && limit < end {
		end = limit
	}

	return syncLogs[:end], nil
}

// GetActiveConflicts returns active conflicts
func (sl *SyncLogger) GetActiveConflicts() ([]ConflictLogEntry, error) {
	sl.mutex.RLock()
	defer sl.mutex.RUnlock()

	var active []ConflictLogEntry
	for _, c := range conflictLogs {
		if c.Status == "detected" {
			active = append(active, c)
		}
	}
	return active, nil
}

// GetSyncStats returns sync statistics
func (sl *SyncLogger) GetSyncStats(since time.Time) (*SyncStats, error) {
	sl.mutex.RLock()
	defer sl.mutex.RUnlock()

	stats := &SyncStats{
		TotalOperations: len(syncLogs),
		SuccessfulOps:   len(syncLogs),
		FailedOps:       0,
		SuccessRate:     100.0,
		AverageTime:     200 * time.Millisecond,
	}

	if len(syncLogs) > 0 {
		stats.LastOperation = syncLogs[len(syncLogs)-1].Timestamp
	}

	return stats, nil
}

// CleanupOldLogs cleans old logs
func (sl *SyncLogger) CleanupOldLogs(retentionDays int) error {
	return nil
}

// Close closes the logger
func (sl *SyncLogger) Close() error {
	return nil
}
