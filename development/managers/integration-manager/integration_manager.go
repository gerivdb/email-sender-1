package integration_manager

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"

	"github.com/gerivdb/email-sender-1/development/managers/interfaces"
)

// IntegrationManagerImpl implémente l'interface IntegrationManager
type IntegrationManagerImpl struct {
	integrations    map[string]*interfaces.Integration
	apis            map[string]*interfaces.APIEndpoint
	syncJobs        map[string]*interfaces.SyncJob
	webhooks        map[string]*interfaces.Webhook
	transformations map[string]*interfaces.DataTransformation

	// Storages pour les logs et statuts
	syncStatuses map[string]*interfaces.SyncStatus
	syncEvents   map[string][]*interfaces.SyncEvent
	webhookLogs  map[string][]*interfaces.WebhookLog
	apiStatuses  map[string]*interfaces.APIStatus

	logger         *logrus.Logger
	config         *IntegrationConfig
	httpClient     *http.Client
	syncManager    *SyncManager
	webhookManager *WebhookManager

	// Thread safety
	mutex        sync.RWMutex
	syncMutex    sync.RWMutex
	webhookMutex sync.RWMutex

	// Manager state
	isStarted  bool
	shutdownCh chan struct{}
}

// IntegrationConfig représente la configuration du gestionnaire d'intégration
type IntegrationConfig struct {
	HTTPTimeout       time.Duration `json:"http_timeout"`
	MaxRetries        int           `json:"max_retries"`
	WebhookSecret     string        `json:"webhook_secret"`
	SyncInterval      time.Duration `json:"sync_interval"`
	MaxConcurrentSync int           `json:"max_concurrent_sync"`
	LogLevel          string        `json:"log_level"`
}

// SyncManager gère les tâches de synchronisation
type SyncManager struct {
	jobs          map[string]*interfaces.SyncJob
	statuses      map[string]*interfaces.SyncStatus
	events        map[string][]*interfaces.SyncEvent
	mutex         sync.RWMutex
	maxConcurrent int
	activeSyncs   int
}

// WebhookManager gère les webhooks
type WebhookManager struct {
	webhooks map[string]*interfaces.Webhook
	logs     map[string][]*interfaces.WebhookLog
	mutex    sync.RWMutex
	secret   string
}

// NewIntegrationManager crée une nouvelle instance d'IntegrationManager
func NewIntegrationManager(config *IntegrationConfig, logger *logrus.Logger) *IntegrationManagerImpl {
	if config == nil {
		config = &IntegrationConfig{
			HTTPTimeout:       30 * time.Second,
			MaxRetries:        3,
			WebhookSecret:     generateSecret(),
			SyncInterval:      5 * time.Minute,
			MaxConcurrentSync: 5,
			LogLevel:          "info",
		}
	}

	if logger == nil {
		logger = logrus.New()
		level, _ := logrus.ParseLevel(config.LogLevel)
		logger.SetLevel(level)
	}

	httpClient := &http.Client{
		Timeout: config.HTTPTimeout,
	}

	syncManager := &SyncManager{
		jobs:          make(map[string]*interfaces.SyncJob),
		statuses:      make(map[string]*interfaces.SyncStatus),
		events:        make(map[string][]*interfaces.SyncEvent),
		maxConcurrent: config.MaxConcurrentSync,
	}

	webhookManager := &WebhookManager{
		webhooks: make(map[string]*interfaces.Webhook),
		logs:     make(map[string][]*interfaces.WebhookLog),
		secret:   config.WebhookSecret,
	}

	return &IntegrationManagerImpl{
		integrations:    make(map[string]*interfaces.Integration),
		apis:            make(map[string]*interfaces.APIEndpoint),
		syncJobs:        make(map[string]*interfaces.SyncJob),
		webhooks:        make(map[string]*interfaces.Webhook),
		transformations: make(map[string]*interfaces.DataTransformation),
		syncStatuses:    make(map[string]*interfaces.SyncStatus),
		syncEvents:      make(map[string][]*interfaces.SyncEvent),
		webhookLogs:     make(map[string][]*interfaces.WebhookLog),
		apiStatuses:     make(map[string]*interfaces.APIStatus),
		logger:          logger,
		config:          config,
		httpClient:      httpClient,
		syncManager:     syncManager,
		webhookManager:  webhookManager,
		shutdownCh:      make(chan struct{}),
	}
}

// ===== BaseManager Interface Implementation =====

func (im *IntegrationManagerImpl) Start(ctx context.Context) error {
	im.mutex.Lock()
	defer im.mutex.Unlock()

	if im.isStarted {
		return fmt.Errorf("integration manager already started")
	}

	im.logger.Info("Starting Integration Manager")

	// Start background processes
	go im.syncScheduler(ctx)
	go im.webhookLogCleaner(ctx)
	go im.apiHealthChecker(ctx)

	im.isStarted = true
	im.logger.Info("Integration Manager started successfully")
	return nil
}

func (im *IntegrationManagerImpl) Stop(ctx context.Context) error {
	im.mutex.Lock()
	defer im.mutex.Unlock()

	if !im.isStarted {
		return fmt.Errorf("integration manager not started")
	}

	im.logger.Info("Stopping Integration Manager")

	// Signal shutdown
	close(im.shutdownCh)

	// Stop all running sync jobs
	im.stopAllSyncJobs(ctx)

	im.isStarted = false
	im.logger.Info("Integration Manager stopped successfully")
	return nil
}

func (im *IntegrationManagerImpl) GetStatus(ctx context.Context) map[string]interface{} {
	im.mutex.RLock()
	defer im.mutex.RUnlock()

	status := map[string]interface{}{
		"status":                "running",
		"started":               im.isStarted,
		"total_integrations":    len(im.integrations),
		"active_integrations":   im.countActiveIntegrations(),
		"total_apis":            len(im.apis),
		"total_sync_jobs":       len(im.syncJobs),
		"active_sync_jobs":      im.countActiveSyncJobs(),
		"total_webhooks":        len(im.webhooks),
		"active_webhooks":       im.countActiveWebhooks(),
		"total_transformations": len(im.transformations),
		"last_updated":          time.Now(),
	}

	return status
}

func (im *IntegrationManagerImpl) GetVersion() string {
	return "1.0.0"
}

func (im *IntegrationManagerImpl) GetMetrics(ctx context.Context) map[string]interface{} {
	im.mutex.RLock()
	defer im.mutex.RUnlock()

	// Calculate sync job metrics
	syncMetrics := im.calculateSyncMetrics()

	// Calculate API metrics
	apiMetrics := im.calculateAPIMetrics()

	// Calculate webhook metrics
	webhookMetrics := im.calculateWebhookMetrics()

	return map[string]interface{}{
		"sync_jobs": syncMetrics,
		"apis":      apiMetrics,
		"webhooks":  webhookMetrics,
		"timestamp": time.Now(),
	}
}

// ===== Integration Management =====

func (im *IntegrationManagerImpl) CreateIntegration(ctx context.Context, integration *interfaces.Integration) error {
	if integration == nil {
		return fmt.Errorf("integration cannot be nil")
	}

	im.mutex.Lock()
	defer im.mutex.Unlock()

	// Generate ID if not provided
	if integration.ID == "" {
		integration.ID = uuid.New().String()
	}

	// Check if integration already exists
	if _, exists := im.integrations[integration.ID]; exists {
		return fmt.Errorf("integration with ID %s already exists", integration.ID)
	}

	// Validate integration
	if err := im.validateIntegration(integration); err != nil {
		return fmt.Errorf("invalid integration: %w", err)
	}

	// Set timestamps
	now := time.Now()
	integration.CreatedAt = now
	integration.UpdatedAt = now
	integration.Status = interfaces.IntegrationStatusInactive

	// Store integration
	im.integrations[integration.ID] = integration

	im.logger.WithFields(logrus.Fields{
		"integration_id":   integration.ID,
		"integration_name": integration.Name,
		"integration_type": integration.Type,
	}).Info("Integration created successfully")

	return nil
}

func (im *IntegrationManagerImpl) UpdateIntegration(ctx context.Context, integrationID string, integration *interfaces.Integration) error {
	if integration == nil {
		return fmt.Errorf("integration cannot be nil")
	}

	im.mutex.Lock()
	defer im.mutex.Unlock()

	// Check if integration exists
	existing, exists := im.integrations[integrationID]
	if !exists {
		return fmt.Errorf("integration with ID %s not found", integrationID)
	}

	// Validate integration
	if err := im.validateIntegration(integration); err != nil {
		return fmt.Errorf("invalid integration: %w", err)
	}

	// Preserve original ID and creation time
	integration.ID = integrationID
	integration.CreatedAt = existing.CreatedAt
	integration.UpdatedAt = time.Now()

	// Update integration
	im.integrations[integrationID] = integration

	im.logger.WithFields(logrus.Fields{
		"integration_id":   integrationID,
		"integration_name": integration.Name,
	}).Info("Integration updated successfully")

	return nil
}

func (im *IntegrationManagerImpl) DeleteIntegration(ctx context.Context, integrationID string) error {
	im.mutex.Lock()
	defer im.mutex.Unlock()

	// Check if integration exists
	if _, exists := im.integrations[integrationID]; !exists {
		return fmt.Errorf("integration with ID %s not found", integrationID)
	}

	// Stop any related sync jobs
	im.stopSyncJobsByIntegration(ctx, integrationID)

	// Delete integration
	delete(im.integrations, integrationID)

	im.logger.WithField("integration_id", integrationID).Info("Integration deleted successfully")

	return nil
}

func (im *IntegrationManagerImpl) GetIntegration(ctx context.Context, integrationID string) (*interfaces.Integration, error) {
	im.mutex.RLock()
	defer im.mutex.RUnlock()

	integration, exists := im.integrations[integrationID]
	if !exists {
		return nil, fmt.Errorf("integration with ID %s not found", integrationID)
	}

	// Return a copy to prevent external modification
	integrationCopy := *integration
	return &integrationCopy, nil
}

func (im *IntegrationManagerImpl) ListIntegrations(ctx context.Context) ([]*interfaces.Integration, error) {
	im.mutex.RLock()
	defer im.mutex.RUnlock()

	integrations := make([]*interfaces.Integration, 0, len(im.integrations))
	for _, integration := range im.integrations {
		// Return copies to prevent external modification
		integrationCopy := *integration
		integrations = append(integrations, &integrationCopy)
	}

	return integrations, nil
}

func (im *IntegrationManagerImpl) TestIntegration(ctx context.Context, integrationID string) error {
	integration, err := im.GetIntegration(ctx, integrationID)
	if err != nil {
		return err
	}

	im.logger.WithField("integration_id", integrationID).Info("Testing integration")

	// Test integration based on type
	switch integration.Type {
	case interfaces.IntegrationTypeAPI:
		return im.testAPIIntegration(ctx, integration)
	case interfaces.IntegrationTypeDatabase:
		return im.testDatabaseIntegration(ctx, integration)
	case interfaces.IntegrationTypeWebhook:
		return im.testWebhookIntegration(ctx, integration)
	default:
		return fmt.Errorf("unsupported integration type: %s", integration.Type)
	}
}

// ===== Helper Methods =====

func generateSecret() string {
	bytes := make([]byte, 32)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

func (im *IntegrationManagerImpl) validateIntegration(integration *interfaces.Integration) error {
	if integration.Name == "" {
		return fmt.Errorf("integration name is required")
	}

	if integration.Type == "" {
		return fmt.Errorf("integration type is required")
	}

	// Validate type
	validTypes := []interfaces.IntegrationType{
		interfaces.IntegrationTypeAPI,
		interfaces.IntegrationTypeDatabase,
		interfaces.IntegrationTypeFile,
		interfaces.IntegrationTypeWebhook,
		interfaces.IntegrationTypeQueue,
		interfaces.IntegrationTypeStream,
	}

	typeValid := false
	for _, validType := range validTypes {
		if integration.Type == validType {
			typeValid = true
			break
		}
	}

	if !typeValid {
		return fmt.Errorf("invalid integration type: %s", integration.Type)
	}

	return nil
}

func (im *IntegrationManagerImpl) countActiveIntegrations() int {
	count := 0
	for _, integration := range im.integrations {
		if integration.IsActive && integration.Status == interfaces.IntegrationStatusActive {
			count++
		}
	}
	return count
}

func (im *IntegrationManagerImpl) countActiveSyncJobs() int {
	count := 0
	for _, syncJob := range im.syncJobs {
		if syncJob.IsActive {
			count++
		}
	}
	return count
}

func (im *IntegrationManagerImpl) countActiveWebhooks() int {
	count := 0
	for _, webhook := range im.webhooks {
		if webhook.IsActive {
			count++
		}
	}
	return count
}

func (im *IntegrationManagerImpl) calculateSyncMetrics() map[string]interface{} {
	totalJobs := len(im.syncJobs)
	activeJobs := im.countActiveSyncJobs()
	runningJobs := 0

	for _, status := range im.syncStatuses {
		if status.Status == interfaces.SyncStateRunning {
			runningJobs++
		}
	}

	return map[string]interface{}{
		"total_jobs":   totalJobs,
		"active_jobs":  activeJobs,
		"running_jobs": runningJobs,
	}
}

func (im *IntegrationManagerImpl) calculateAPIMetrics() map[string]interface{} {
	totalAPIs := len(im.apis)
	activeAPIs := 0
	availableAPIs := 0

	for _, api := range im.apis {
		if api.IsActive {
			activeAPIs++
		}
	}

	for _, status := range im.apiStatuses {
		if status.IsAvailable {
			availableAPIs++
		}
	}

	return map[string]interface{}{
		"total_apis":     totalAPIs,
		"active_apis":    activeAPIs,
		"available_apis": availableAPIs,
	}
}

func (im *IntegrationManagerImpl) calculateWebhookMetrics() map[string]interface{} {
	totalWebhooks := len(im.webhooks)
	activeWebhooks := im.countActiveWebhooks()
	totalCalls := 0

	for _, logs := range im.webhookLogs {
		totalCalls += len(logs)
	}

	return map[string]interface{}{
		"total_webhooks":  totalWebhooks,
		"active_webhooks": activeWebhooks,
		"total_calls":     totalCalls,
	}
}

func (im *IntegrationManagerImpl) testAPIIntegration(ctx context.Context, integration *interfaces.Integration) error {
	// Extract API configuration
	baseURL, ok := integration.Config["base_url"].(string)
	if !ok || baseURL == "" {
		return fmt.Errorf("missing or invalid base_url in integration config")
	}

	// Perform health check
	healthURL := baseURL
	if healthPath, exists := integration.Config["health_path"].(string); exists {
		healthURL = strings.TrimSuffix(baseURL, "/") + "/" + strings.TrimPrefix(healthPath, "/")
	}

	req, err := http.NewRequestWithContext(ctx, "GET", healthURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create health check request: %w", err)
	}

	resp, err := im.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("health check returned status %d", resp.StatusCode)
	}

	return nil
}

func (im *IntegrationManagerImpl) testDatabaseIntegration(ctx context.Context, integration *interfaces.Integration) error {
	// This is a placeholder - would implement actual database connectivity testing
	im.logger.WithField("integration_id", integration.ID).Info("Database integration test not implemented yet")
	return nil
}

func (im *IntegrationManagerImpl) testWebhookIntegration(ctx context.Context, integration *interfaces.Integration) error {
	// This is a placeholder - would implement webhook connectivity testing
	im.logger.WithField("integration_id", integration.ID).Info("Webhook integration test not implemented yet")
	return nil
}

func (im *IntegrationManagerImpl) stopAllSyncJobs(ctx context.Context) {
	for jobID := range im.syncJobs {
		im.StopSync(ctx, jobID)
	}
}

func (im *IntegrationManagerImpl) stopSyncJobsByIntegration(ctx context.Context, integrationID string) {
	for jobID, job := range im.syncJobs {
		if job.SourceID == integrationID || job.TargetID == integrationID {
			im.StopSync(ctx, jobID)
		}
	}
}

// Background processes
func (im *IntegrationManagerImpl) syncScheduler(ctx context.Context) {
	ticker := time.NewTicker(im.config.SyncInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-im.shutdownCh:
			return
		case <-ticker.C:
			im.checkScheduledSyncs(ctx)
		}
	}
}

func (im *IntegrationManagerImpl) webhookLogCleaner(ctx context.Context) {
	ticker := time.NewTicker(1 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-im.shutdownCh:
			return
		case <-ticker.C:
			im.cleanOldWebhookLogs()
		}
	}
}

func (im *IntegrationManagerImpl) apiHealthChecker(ctx context.Context) {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-im.shutdownCh:
			return
		case <-ticker.C:
			im.checkAPIHealth(ctx)
		}
	}
}

func (im *IntegrationManagerImpl) checkScheduledSyncs(ctx context.Context) {
	// Implementation would check for scheduled sync jobs and start them
	im.logger.Debug("Checking scheduled sync jobs")
}

func (im *IntegrationManagerImpl) cleanOldWebhookLogs() {
	// Implementation would clean webhook logs older than a certain threshold
	im.logger.Debug("Cleaning old webhook logs")
}

func (im *IntegrationManagerImpl) checkAPIHealth(ctx context.Context) {
	// Implementation would check the health of all registered APIs
	im.logger.Debug("Checking API health")
}
