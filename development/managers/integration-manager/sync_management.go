package integration_manager

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"

	"github.com/gerivdb/email-sender-1/development/managers/interfaces"
)

// ===== Synchronization Management =====

func (im *IntegrationManagerImpl) CreateSyncJob(ctx context.Context, syncJob *interfaces.SyncJob) error {
	if syncJob == nil {
		return fmt.Errorf("sync job cannot be nil")
	}

	im.syncMutex.Lock()
	defer im.syncMutex.Unlock()

	// Generate ID if not provided
	if syncJob.ID == "" {
		syncJob.ID = uuid.New().String()
	}

	// Check if sync job already exists
	if _, exists := im.syncJobs[syncJob.ID]; exists {
		return fmt.Errorf("sync job with ID %s already exists", syncJob.ID)
	}

	// Validate sync job
	if err := im.validateSyncJob(syncJob); err != nil {
		return fmt.Errorf("invalid sync job: %w", err)
	}

	// Set timestamps and defaults
	now := time.Now()
	syncJob.CreatedAt = now
	syncJob.UpdatedAt = now

	// Store sync job
	im.syncJobs[syncJob.ID] = syncJob

	// Initialize sync status
	im.syncStatuses[syncJob.ID] = &interfaces.SyncStatus{
		Status:        interfaces.SyncStateIdle,
		Progress:      0,
		RecordsTotal:  0,
		RecordsSync:   0,
		RecordsFailed: 0,
		Metrics:       make(map[string]interface{}),
	}

	// Initialize sync events
	im.syncEvents[syncJob.ID] = make([]*interfaces.SyncEvent, 0)

	// Calculate next run time if scheduled
	if syncJob.Schedule != "" {
		nextRun, err := im.calculateNextRun(syncJob.Schedule)
		if err == nil {
			syncJob.NextRun = &nextRun
		}
	}

	im.logger.WithFields(logrus.Fields{
		"sync_job_id":   syncJob.ID,
		"sync_job_name": syncJob.Name,
		"source_id":     syncJob.SourceID,
		"target_id":     syncJob.TargetID,
		"type":          syncJob.Type,
	}).Info("Sync job created successfully")

	return nil
}

func (im *IntegrationManagerImpl) StartSync(ctx context.Context, syncJobID string) error {
	im.syncMutex.Lock()
	syncJob, exists := im.syncJobs[syncJobID]
	if !exists {
		im.syncMutex.Unlock()
		return fmt.Errorf("sync job with ID %s not found", syncJobID)
	}

	if !syncJob.IsActive {
		im.syncMutex.Unlock()
		return fmt.Errorf("sync job %s is not active", syncJobID)
	}

	// Check if already running
	status := im.syncStatuses[syncJobID]
	if status.Status == interfaces.SyncStateRunning {
		im.syncMutex.Unlock()
		return fmt.Errorf("sync job %s is already running", syncJobID)
	}

	// Check concurrent sync limit
	if im.syncManager.activeSyncs >= im.syncManager.maxConcurrent {
		im.syncMutex.Unlock()
		return fmt.Errorf("maximum concurrent sync jobs reached (%d)", im.syncManager.maxConcurrent)
	}

	// Update status to running
	now := time.Now()
	status.Status = interfaces.SyncStateRunning
	status.Progress = 0
	status.StartedAt = &now
	status.CompletedAt = nil
	status.LastError = ""
	im.syncManager.activeSyncs++

	// Update job last run time
	syncJob.LastRun = &now

	im.syncMutex.Unlock()

	// Add sync event
	im.addSyncEvent(syncJobID, interfaces.SyncEventStarted, "Sync job started", nil)

	// Start sync in background
	go im.executeSyncJob(ctx, syncJob)

	im.logger.WithFields(logrus.Fields{
		"sync_job_id":   syncJobID,
		"sync_job_name": syncJob.Name,
	}).Info("Sync job started")

	return nil
}

func (im *IntegrationManagerImpl) StopSync(ctx context.Context, syncJobID string) error {
	im.syncMutex.Lock()
	defer im.syncMutex.Unlock()

	syncJob, exists := im.syncJobs[syncJobID]
	if !exists {
		return fmt.Errorf("sync job with ID %s not found", syncJobID)
	}

	status := im.syncStatuses[syncJobID]
	if status.Status != interfaces.SyncStateRunning {
		return fmt.Errorf("sync job %s is not running", syncJobID)
	}

	// Update status to cancelled
	now := time.Now()
	status.Status = interfaces.SyncStateCancelled
	status.CompletedAt = &now
	im.syncManager.activeSyncs--

	// Add sync event
	im.addSyncEvent(syncJobID, interfaces.SyncEventFailed, "Sync job cancelled", nil)

	im.logger.WithFields(logrus.Fields{
		"sync_job_id":   syncJobID,
		"sync_job_name": syncJob.Name,
	}).Info("Sync job stopped")

	return nil
}

func (im *IntegrationManagerImpl) GetSyncStatus(ctx context.Context, syncJobID string) (*interfaces.SyncStatus, error) {
	im.syncMutex.RLock()
	defer im.syncMutex.RUnlock()

	status, exists := im.syncStatuses[syncJobID]
	if !exists {
		return nil, fmt.Errorf("sync status for job ID %s not found", syncJobID)
	}

	// Return a copy to prevent external modification
	statusCopy := *status
	return &statusCopy, nil
}

func (im *IntegrationManagerImpl) GetSyncHistory(ctx context.Context, syncJobID string) ([]*interfaces.SyncEvent, error) {
	im.syncMutex.RLock()
	defer im.syncMutex.RUnlock()

	events, exists := im.syncEvents[syncJobID]
	if !exists {
		return nil, fmt.Errorf("sync events for job ID %s not found", syncJobID)
	}

	// Return copies to prevent external modification
	eventsCopy := make([]*interfaces.SyncEvent, len(events))
	for i, event := range events {
		eventCopy := *event
		eventsCopy[i] = &eventCopy
	}

	return eventsCopy, nil
}

// ===== Helper Methods for Synchronization =====

func (im *IntegrationManagerImpl) validateSyncJob(syncJob *interfaces.SyncJob) error {
	if syncJob.Name == "" {
		return fmt.Errorf("sync job name is required")
	}

	if syncJob.SourceID == "" {
		return fmt.Errorf("source ID is required")
	}

	if syncJob.TargetID == "" {
		return fmt.Errorf("target ID is required")
	}

	if syncJob.Type == "" {
		return fmt.Errorf("sync type is required")
	}

	// Validate sync type
	validTypes := []interfaces.SyncType{
		interfaces.SyncTypeOneWay,
		interfaces.SyncTypeTwoWay,
		interfaces.SyncTypeBidirect,
		interfaces.SyncTypeIncremental,
		interfaces.SyncTypeFull,
	}

	typeValid := false
	for _, validType := range validTypes {
		if syncJob.Type == validType {
			typeValid = true
			break
		}
	}

	if !typeValid {
		return fmt.Errorf("invalid sync type: %s", syncJob.Type)
	}

	// Validate that source and target integrations exist
	im.mutex.RLock()
	_, sourceExists := im.integrations[syncJob.SourceID]
	_, targetExists := im.integrations[syncJob.TargetID]
	im.mutex.RUnlock()

	if !sourceExists {
		return fmt.Errorf("source integration %s not found", syncJob.SourceID)
	}

	if !targetExists {
		return fmt.Errorf("target integration %s not found", syncJob.TargetID)
	}

	return nil
}

func (im *IntegrationManagerImpl) executeSyncJob(ctx context.Context, syncJob *interfaces.SyncJob) {
	syncJobID := syncJob.ID

	defer func() {
		// Cleanup on completion/failure
		im.syncMutex.Lock()
		if im.syncManager.activeSyncs > 0 {
			im.syncManager.activeSyncs--
		}
		im.syncMutex.Unlock()
	}()

	im.logger.WithField("sync_job_id", syncJobID).Info("Executing sync job")

	// Get source and target integrations
	im.mutex.RLock()
	sourceIntegration, sourceExists := im.integrations[syncJob.SourceID]
	targetIntegration, targetExists := im.integrations[syncJob.TargetID]
	im.mutex.RUnlock()

	if !sourceExists || !targetExists {
		im.finalizeSyncJob(syncJobID, interfaces.SyncStateFailed, "Source or target integration not found", nil)
		return
	}

	// Execute sync based on type
	var err error
	switch syncJob.Type {
	case interfaces.SyncTypeOneWay:
		err = im.executeOneWaySync(ctx, syncJob, sourceIntegration, targetIntegration)
	case interfaces.SyncTypeTwoWay:
		err = im.executeTwoWaySync(ctx, syncJob, sourceIntegration, targetIntegration)
	case interfaces.SyncTypeIncremental:
		err = im.executeIncrementalSync(ctx, syncJob, sourceIntegration, targetIntegration)
	case interfaces.SyncTypeFull:
		err = im.executeFullSync(ctx, syncJob, sourceIntegration, targetIntegration)
	default:
		err = fmt.Errorf("unsupported sync type: %s", syncJob.Type)
	}

	// Finalize sync job
	if err != nil {
		im.finalizeSyncJob(syncJobID, interfaces.SyncStateFailed, err.Error(), nil)
	} else {
		metrics := map[string]interface{}{
			"duration": time.Since(*im.syncStatuses[syncJobID].StartedAt),
		}
		im.finalizeSyncJob(syncJobID, interfaces.SyncStateCompleted, "", metrics)
	}

	// Calculate next run time if scheduled
	if syncJob.Schedule != "" {
		nextRun, err := im.calculateNextRun(syncJob.Schedule)
		if err == nil {
			im.syncMutex.Lock()
			syncJob.NextRun = &nextRun
			im.syncMutex.Unlock()
		}
	}
}

func (im *IntegrationManagerImpl) executeOneWaySync(ctx context.Context, syncJob *interfaces.SyncJob, source, target *interfaces.Integration) error {
	im.logger.WithField("sync_job_id", syncJob.ID).Info("Executing one-way sync")

	// Update progress
	im.updateSyncProgress(syncJob.ID, 25)

	// Simulate sync operations
	data, err := im.extractDataFromSource(ctx, source, syncJob.Config)
	if err != nil {
		return fmt.Errorf("failed to extract data from source: %w", err)
	}

	im.updateSyncProgress(syncJob.ID, 50)

	// Transform data if needed
	transformedData, err := im.transformSyncData(ctx, data, syncJob.Config)
	if err != nil {
		return fmt.Errorf("failed to transform data: %w", err)
	}

	im.updateSyncProgress(syncJob.ID, 75)

	// Load data to target
	err = im.loadDataToTarget(ctx, target, transformedData, syncJob.Config)
	if err != nil {
		return fmt.Errorf("failed to load data to target: %w", err)
	}

	im.updateSyncProgress(syncJob.ID, 100)

	return nil
}

func (im *IntegrationManagerImpl) executeTwoWaySync(ctx context.Context, syncJob *interfaces.SyncJob, source, target *interfaces.Integration) error {
	im.logger.WithField("sync_job_id", syncJob.ID).Info("Executing two-way sync")

	// This is a placeholder implementation
	// Real implementation would involve conflict resolution and bidirectional sync

	im.updateSyncProgress(syncJob.ID, 100)
	return nil
}

func (im *IntegrationManagerImpl) executeIncrementalSync(ctx context.Context, syncJob *interfaces.SyncJob, source, target *interfaces.Integration) error {
	im.logger.WithField("sync_job_id", syncJob.ID).Info("Executing incremental sync")

	// This is a placeholder implementation
	// Real implementation would sync only changed data since last sync

	im.updateSyncProgress(syncJob.ID, 100)
	return nil
}

func (im *IntegrationManagerImpl) executeFullSync(ctx context.Context, syncJob *interfaces.SyncJob, source, target *interfaces.Integration) error {
	im.logger.WithField("sync_job_id", syncJob.ID).Info("Executing full sync")

	// This is a placeholder implementation
	// Real implementation would sync all data

	im.updateSyncProgress(syncJob.ID, 100)
	return nil
}

func (im *IntegrationManagerImpl) extractDataFromSource(ctx context.Context, source *interfaces.Integration, config map[string]interface{}) (interface{}, error) {
	// This is a placeholder implementation
	// Real implementation would extract data based on integration type

	switch source.Type {
	case interfaces.IntegrationTypeAPI:
		return im.extractDataFromAPI(ctx, source, config)
	case interfaces.IntegrationTypeDatabase:
		return im.extractDataFromDatabase(ctx, source, config)
	case interfaces.IntegrationTypeFile:
		return im.extractDataFromFile(ctx, source, config)
	default:
		return nil, fmt.Errorf("unsupported source integration type: %s", source.Type)
	}
}

func (im *IntegrationManagerImpl) extractDataFromAPI(ctx context.Context, source *interfaces.Integration, config map[string]interface{}) (interface{}, error) {
	// Placeholder implementation for API data extraction
	return map[string]interface{}{
		"records": []map[string]interface{}{
			{"id": "1", "name": "Record 1"},
			{"id": "2", "name": "Record 2"},
		},
	}, nil
}

func (im *IntegrationManagerImpl) extractDataFromDatabase(ctx context.Context, source *interfaces.Integration, config map[string]interface{}) (interface{}, error) {
	// Placeholder implementation for database data extraction
	return map[string]interface{}{
		"records": []map[string]interface{}{
			{"id": "1", "name": "DB Record 1"},
			{"id": "2", "name": "DB Record 2"},
		},
	}, nil
}

func (im *IntegrationManagerImpl) extractDataFromFile(ctx context.Context, source *interfaces.Integration, config map[string]interface{}) (interface{}, error) {
	// Placeholder implementation for file data extraction
	return map[string]interface{}{
		"records": []map[string]interface{}{
			{"id": "1", "name": "File Record 1"},
			{"id": "2", "name": "File Record 2"},
		},
	}, nil
}

func (im *IntegrationManagerImpl) transformSyncData(ctx context.Context, data interface{}, config map[string]interface{}) (interface{}, error) {
	// This is a placeholder implementation
	// Real implementation would apply transformations based on config
	return data, nil
}

func (im *IntegrationManagerImpl) loadDataToTarget(ctx context.Context, target *interfaces.Integration, data interface{}, config map[string]interface{}) error {
	// This is a placeholder implementation
	// Real implementation would load data based on target integration type

	switch target.Type {
	case interfaces.IntegrationTypeAPI:
		return im.loadDataToAPI(ctx, target, data, config)
	case interfaces.IntegrationTypeDatabase:
		return im.loadDataToDatabase(ctx, target, data, config)
	case interfaces.IntegrationTypeFile:
		return im.loadDataToFile(ctx, target, data, config)
	default:
		return fmt.Errorf("unsupported target integration type: %s", target.Type)
	}
}

func (im *IntegrationManagerImpl) loadDataToAPI(ctx context.Context, target *interfaces.Integration, data interface{}, config map[string]interface{}) error {
	// Placeholder implementation for API data loading
	im.logger.WithField("target_id", target.ID).Info("Loading data to API")
	return nil
}

func (im *IntegrationManagerImpl) loadDataToDatabase(ctx context.Context, target *interfaces.Integration, data interface{}, config map[string]interface{}) error {
	// Placeholder implementation for database data loading
	im.logger.WithField("target_id", target.ID).Info("Loading data to database")
	return nil
}

func (im *IntegrationManagerImpl) loadDataToFile(ctx context.Context, target *interfaces.Integration, data interface{}, config map[string]interface{}) error {
	// Placeholder implementation for file data loading
	im.logger.WithField("target_id", target.ID).Info("Loading data to file")
	return nil
}

func (im *IntegrationManagerImpl) updateSyncProgress(syncJobID string, progress float64) {
	im.syncMutex.Lock()
	defer im.syncMutex.Unlock()

	if status, exists := im.syncStatuses[syncJobID]; exists {
		status.Progress = progress

		// Add progress event
		im.addSyncEventUnsafe(syncJobID, interfaces.SyncEventProgress, fmt.Sprintf("Progress: %.1f%%", progress), map[string]interface{}{
			"progress": progress,
		})
	}
}

func (im *IntegrationManagerImpl) finalizeSyncJob(syncJobID string, finalStatus interfaces.SyncState, errorMessage string, metrics map[string]interface{}) {
	im.syncMutex.Lock()
	defer im.syncMutex.Unlock()

	status := im.syncStatuses[syncJobID]
	if status == nil {
		return
	}

	now := time.Now()
	status.Status = finalStatus
	status.CompletedAt = &now
	status.LastError = errorMessage

	if metrics != nil {
		for key, value := range metrics {
			status.Metrics[key] = value
		}
	}

	// Add completion event
	eventType := interfaces.SyncEventCompleted
	message := "Sync job completed successfully"

	if finalStatus == interfaces.SyncStateFailed {
		eventType = interfaces.SyncEventFailed
		message = "Sync job failed: " + errorMessage
	}

	im.addSyncEventUnsafe(syncJobID, eventType, message, metrics)

	im.logger.WithFields(logrus.Fields{
		"sync_job_id": syncJobID,
		"status":      finalStatus,
		"error":       errorMessage,
	}).Info("Sync job finalized")
}

func (im *IntegrationManagerImpl) addSyncEvent(syncJobID string, eventType interfaces.SyncEventType, message string, data map[string]interface{}) {
	im.syncMutex.Lock()
	defer im.syncMutex.Unlock()

	im.addSyncEventUnsafe(syncJobID, eventType, message, data)
}

func (im *IntegrationManagerImpl) addSyncEventUnsafe(syncJobID string, eventType interfaces.SyncEventType, message string, data map[string]interface{}) {
	event := &interfaces.SyncEvent{
		ID:        uuid.New().String(),
		SyncJobID: syncJobID,
		Type:      eventType,
		Timestamp: time.Now(),
		Data:      data,
		Status:    string(eventType),
		Message:   message,
	}

	if events, exists := im.syncEvents[syncJobID]; exists {
		// Limit the number of events stored
		maxEvents := 100
		if len(events) >= maxEvents {
			// Remove oldest events
			im.syncEvents[syncJobID] = events[len(events)-maxEvents+1:]
		}
		im.syncEvents[syncJobID] = append(im.syncEvents[syncJobID], event)
	} else {
		im.syncEvents[syncJobID] = []*interfaces.SyncEvent{event}
	}
}

func (im *IntegrationManagerImpl) calculateNextRun(schedule string) (time.Time, error) {
	// This is a placeholder implementation
	// Real implementation would parse cron expressions or other schedule formats

	// For now, assume schedule is a duration like "1h", "30m", etc.
	duration, err := time.ParseDuration(schedule)
	if err != nil {
		return time.Time{}, fmt.Errorf("invalid schedule format: %s", schedule)
	}

	return time.Now().Add(duration), nil
}

func (im *IntegrationManagerImpl) checkScheduledSyncs(ctx context.Context) {
	im.syncMutex.RLock()
	now := time.Now()
	jobsToStart := make([]*interfaces.SyncJob, 0)

	for _, job := range im.syncJobs {
		if job.IsActive && job.NextRun != nil && job.NextRun.Before(now) {
			// Check if not already running
			if status, exists := im.syncStatuses[job.ID]; exists && status.Status != interfaces.SyncStateRunning {
				jobsToStart = append(jobsToStart, job)
			}
		}
	}
	im.syncMutex.RUnlock()

	for _, job := range jobsToStart {
		if err := im.StartSync(ctx, job.ID); err != nil {
			im.logger.WithFields(logrus.Fields{
				"sync_job_id": job.ID,
				"error":       err,
			}).Error("Failed to start scheduled sync job")
		}
	}
}
