// Package core - Main Orchestrator FMOUA selon spécifications plan-dev-v53
// Implémente l'orchestration principale avec latence < 100ms et AI-First
package core

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/interfaces"
	"email_sender/pkg/fmoua/types"
)

// MaintenanceOrchestrator represents the main orchestrator
// Following SOLID Single Responsibility Principle
type MaintenanceOrchestrator struct {
	config           *FMOUAConfig
	integrationHub   interfaces.ManagerHub
	aiEngine         interfaces.IntelligenceEngine
	logger           *zap.Logger
	ctx              context.Context
	cancel           context.CancelFunc
	performanceStats *OrchestrationStats
	mu               sync.RWMutex
}

// OrchestrationStats tracks orchestrator performance
type OrchestrationStats struct {
	TotalOperations   int64         `json:"total_operations"`
	SuccessfulOps     int64         `json:"successful_operations"`
	FailedOps         int64         `json:"failed_operations"`
	AverageLatency    time.Duration `json:"average_latency"`
	LastOperationTime time.Time     `json:"last_operation_time"`
	LatencyUnder100ms int64         `json:"latency_under_100ms"`
}

// NewMaintenanceOrchestrator creates a new orchestrator instance
func NewMaintenanceOrchestrator(
	config *FMOUAConfig,
	integrationHub interfaces.ManagerHub,
	aiEngine interfaces.IntelligenceEngine,
	logger *zap.Logger,
) (*MaintenanceOrchestrator, error) {

	ctx, cancel := context.WithCancel(context.Background())

	orchestrator := &MaintenanceOrchestrator{
		config:           config,
		integrationHub:   integrationHub,
		aiEngine:         aiEngine,
		logger:           logger,
		ctx:              ctx,
		cancel:           cancel,
		performanceStats: &OrchestrationStats{},
	}

	return orchestrator, nil
}

// Start initializes and starts the orchestrator
func (o *MaintenanceOrchestrator) Start(ctx context.Context) error {
	o.logger.Info("Starting FMOUA Main Orchestrator")

	startTime := time.Now()

	// Validate configuration
	if err := ValidateFMOUAConfig(o.config); err != nil {
		return fmt.Errorf("invalid configuration: %w", err)
	}

	// Start monitoring performance metrics
	go o.performanceMonitoring()

	startupTime := time.Since(startTime)
	o.logger.Info("FMOUA Main Orchestrator started successfully",
		zap.Duration("startup_time", startupTime),
		zap.String("target_latency", "<100ms"),
		zap.Bool("ai_enabled", o.config.IsAIEnabled()))

	return nil
}

// performanceMonitoring monitors orchestrator performance
func (o *MaintenanceOrchestrator) performanceMonitoring() {
	ticker := time.NewTicker(time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-o.ctx.Done():
			return
		case <-ticker.C:
			o.logPerformanceMetrics()
		}
	}
}

// logPerformanceMetrics logs current performance statistics
func (o *MaintenanceOrchestrator) logPerformanceMetrics() {
	o.mu.RLock()
	stats := *o.performanceStats
	o.mu.RUnlock()

	if stats.TotalOperations > 0 {
		successRate := float64(stats.SuccessfulOps) / float64(stats.TotalOperations) * 100
		latencyCompliance := float64(stats.LatencyUnder100ms) / float64(stats.TotalOperations) * 100

		o.logger.Info("FMOUA Performance Metrics",
			zap.Int64("total_operations", stats.TotalOperations),
			zap.Float64("success_rate_percent", successRate),
			zap.Duration("average_latency", stats.AverageLatency),
			zap.Float64("sub_100ms_compliance_percent", latencyCompliance))
	}
}

// ExecuteOrganization performs AI-powered repository organization
func (o *MaintenanceOrchestrator) ExecuteOrganization(repoPath string) (*interfaces.AIDecision, error) {
	startTime := time.Now()
	defer func() {
		o.updatePerformanceStats(time.Since(startTime), nil)
	}()

	o.logger.Info("Starting AI-powered repository organization",
		zap.String("repository", repoPath))

	// Check if AI is enabled (AI-First principle)
	if !o.config.IsAIEnabled() {
		return nil, fmt.Errorf("AI is required for organization operations (AI-First principle)")
	}

	// Get AI decision for organization
	decision, err := o.aiEngine.AnalyzeRepository(repoPath)
	if err != nil {
		o.updatePerformanceStats(time.Since(startTime), err)
		return nil, fmt.Errorf("AI analysis failed: %w", err)
	}

	// Execute organization based on AI decision
	if err := o.executeOrganizationActions(decision); err != nil {
		o.updatePerformanceStats(time.Since(startTime), err)
		return nil, fmt.Errorf("failed to execute organization actions: %w", err)
	}

	executionTime := time.Since(startTime)
	o.logger.Info("Repository organization completed",
		zap.String("repository", repoPath),
		zap.Duration("execution_time", executionTime),
		zap.Float64("ai_confidence", decision.Confidence))

	return decision, nil
}

// executeOrganizationActions executes the actions recommended by AI
func (o *MaintenanceOrchestrator) executeOrganizationActions(decision *interfaces.AIDecision) error {
	for _, action := range decision.Actions {
		o.logger.Info("Executing organization action",
			zap.String("type", action.Type),
			zap.String("target", action.Target),
			zap.Int("priority", action.Priority))

		// Execute action through appropriate manager
		if err := o.executeAction(action); err != nil {
			return fmt.Errorf("failed to execute action %s: %w", action.Type, err)
		}
	}
	return nil
}

// executeAction executes a specific action through the integration hub
func (o *MaintenanceOrchestrator) executeAction(action interfaces.RecommendedAction) error {
	// Determine which manager should handle this action
	managerName := o.getManagerForActionType(action.Type)

	// Execute operation through integration hub
	result, err := o.integrationHub.ExecuteManagerOperation(managerName, action.Type, action.Parameters)
	if err != nil {
		return fmt.Errorf("manager operation failed: %w", err)
	}

	o.logger.Info("Action executed successfully",
		zap.String("action", action.Type),
		zap.String("manager", managerName),
		zap.Any("result", result))

	return nil
}

// getManagerForActionType determines which manager should handle an action
func (o *MaintenanceOrchestrator) getManagerForActionType(actionType string) string {
	// Map action types to appropriate managers
	actionManagerMap := map[string]string{
		"reorganize":         "StorageManager",
		"cleanup":            "StorageManager",
		"optimize":           "PerformanceManager",
		"security_scan":      "SecurityManager",
		"cache_optimization": "CacheManager",
		"log_cleanup":        "LogManager",
		"backup":             "BackupManager",
		"validate":           "ValidationManager",
		"test":               "TestManager",
		"deploy":             "DeploymentManager",
		"monitor":            "MonitoringManager",
	}

	if manager, exists := actionManagerMap[actionType]; exists {
		return manager
	}

	// Default to StorageManager for unknown actions
	return "StorageManager"
}

// ExecuteCleanup performs multi-level cleanup according to FMOUA specifications
func (o *MaintenanceOrchestrator) ExecuteCleanup(level int, targets []string) error {
	startTime := time.Now()
	defer func() {
		o.updatePerformanceStats(time.Since(startTime), nil)
	}()

	o.logger.Info("Starting FMOUA cleanup operation",
		zap.Int("level", level),
		zap.Strings("targets", targets))

	// Get cleanup configuration for the specified level
	cleanupConfig, err := o.config.GetCleanupLevelConfig(level)
	if err != nil {
		return fmt.Errorf("invalid cleanup level: %w", err)
	}

	// AI analysis for levels 2 and 3
	if cleanupConfig.AIAnalysisRequired {
		decision, err := o.aiEngine.MakeOrganizationDecision(map[string]interface{}{
			"cleanup_level": level,
			"targets":       targets,
		})
		if err != nil {
			return fmt.Errorf("AI analysis failed for cleanup: %w", err)
		}

		if decision.Confidence < cleanupConfig.ConfidenceThreshold {
			return fmt.Errorf("AI confidence %.2f below threshold %.2f",
				decision.Confidence, cleanupConfig.ConfidenceThreshold)
		}
	}

	// Execute cleanup through appropriate managers
	for _, target := range targets {
		if err := o.executeCleanupTarget(target, cleanupConfig); err != nil {
			o.updatePerformanceStats(time.Since(startTime), err)
			return fmt.Errorf("cleanup failed for target %s: %w", target, err)
		}
	}

	executionTime := time.Since(startTime)
	o.logger.Info("Cleanup operation completed successfully",
		zap.Int("level", level),
		zap.Strings("targets", targets),
		zap.Duration("execution_time", executionTime))

	return nil
}

// executeCleanupTarget executes cleanup for a specific target
func (o *MaintenanceOrchestrator) executeCleanupTarget(target string, config *types.CleanupLevelConfig) error {
	// Backup before cleanup if required
	if config.BackupBefore {
		if err := o.createBackup(target); err != nil {
			return fmt.Errorf("backup failed: %w", err)
		}
	}

	// Execute cleanup operation
	result, err := o.integrationHub.ExecuteManagerOperation("StorageManager", "cleanup", map[string]interface{}{
		"target":  target,
		"level":   config.Name,
		"dry_run": false,
	})
	if err != nil {
		return err
	}

	o.logger.Info("Cleanup target processed",
		zap.String("target", target),
		zap.String("level", config.Name),
		zap.Any("result", result))

	return nil
}

// createBackup creates a backup before performing operations
func (o *MaintenanceOrchestrator) createBackup(target string) error {
	_, err := o.integrationHub.ExecuteManagerOperation("BackupManager", "create_backup", map[string]interface{}{
		"target":    target,
		"timestamp": time.Now().Unix(),
	})
	return err
}

// GetHealth returns the health status of all integrated systems
func (o *MaintenanceOrchestrator) GetHealth() map[string]interface{} {
	health := make(map[string]interface{})

	// Get manager health status
	managerHealth := o.integrationHub.GetHealthStatus()
	health["managers"] = managerHealth

	// Get AI engine performance
	if o.config.IsAIEnabled() {
		aiStats := o.aiEngine.GetPerformanceStats()
		health["ai_engine"] = aiStats
	}

	// Get orchestrator stats
	o.mu.RLock()
	orchestratorStats := *o.performanceStats
	o.mu.RUnlock()
	health["orchestrator"] = orchestratorStats

	// Overall health assessment
	activeManagers := o.integrationHub.GetActiveManagers()
	health["overall_status"] = map[string]interface{}{
		"active_managers": len(activeManagers),
		"total_managers":  len(o.config.GetEnabledManagers()),
		"ai_enabled":      o.config.IsAIEnabled(),
		"status":          o.determineOverallHealth(managerHealth),
	}

	return health
}

// determineOverallHealth determines overall system health
func (o *MaintenanceOrchestrator) determineOverallHealth(managerHealth map[string]interfaces.HealthStatus) string {
	totalManagers := len(managerHealth)
	healthyManagers := 0

	for _, status := range managerHealth {
		if status.IsHealthy {
			healthyManagers++
		}
	}

	healthPercentage := float64(healthyManagers) / float64(totalManagers) * 100

	switch {
	case healthPercentage >= 90:
		return "healthy"
	case healthPercentage >= 70:
		return "warning"
	default:
		return "critical"
	}
}

// updatePerformanceStats updates internal performance tracking
func (o *MaintenanceOrchestrator) updatePerformanceStats(latency time.Duration, err error) {
	o.mu.Lock()
	defer o.mu.Unlock()

	o.performanceStats.TotalOperations++
	o.performanceStats.LastOperationTime = time.Now()

	if err == nil {
		o.performanceStats.SuccessfulOps++
	} else {
		o.performanceStats.FailedOps++
	}

	// Track sub-100ms latency compliance
	if latency < 100*time.Millisecond {
		o.performanceStats.LatencyUnder100ms++
	}

	// Update average latency (simplified moving average)
	if o.performanceStats.TotalOperations == 1 {
		o.performanceStats.AverageLatency = latency
	} else {
		o.performanceStats.AverageLatency = time.Duration(
			(int64(o.performanceStats.AverageLatency) + int64(latency)) / 2,
		)
	}
}

// Stop gracefully shuts down the orchestrator
func (o *MaintenanceOrchestrator) Stop() error {
	o.logger.Info("Stopping FMOUA Main Orchestrator")

	o.cancel()

	// Log final performance statistics
	o.logPerformanceMetrics()

	o.logger.Info("FMOUA Main Orchestrator stopped successfully")
	return nil
}

// GetPerformanceStats returns current orchestrator performance statistics
func (o *MaintenanceOrchestrator) GetPerformanceStats() *OrchestrationStats {
	o.mu.RLock()
	defer o.mu.RUnlock()

	stats := *o.performanceStats
	return &stats
}
