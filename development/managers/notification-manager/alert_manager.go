package notification

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/email-sender-notification-manager/interfaces"
	"go.uber.org/zap"
)

// AlertManagerImpl implémente l'interface AlertManager
type AlertManagerImpl struct {
	// Base manager fields
	id            string
	name          string
	version       string
	status        interfaces.ManagerStatus
	logger        *zap.Logger
	mu            sync.RWMutex
	isInitialized bool

	// Alert manager specific fields
	alerts        map[string]*interfaces.Alert
	alertHistory  map[string][]*interfaces.AlertEvent
	config        *AlertConfig
	
	// Alert evaluation
	evaluationInterval time.Duration
	stopEvaluation     chan struct{}
	evaluationTicker   *time.Ticker
	
	// Alert conditions processor
	conditionProcessor *AlertConditionProcessor
}

// AlertConfig represents alert manager configuration
type AlertConfig struct {
	EvaluationInterval    time.Duration `json:"evaluation_interval"`
	MaxHistoryPerAlert    int           `json:"max_history_per_alert"`
	DefaultSeverity       interfaces.AlertSeverity `json:"default_severity"`
	EnableAutoEvaluation  bool          `json:"enable_auto_evaluation"`
}

// AlertConditionProcessor handles condition evaluation logic
type AlertConditionProcessor struct {
	logger *zap.Logger
}

// NewAlertManager creates a new AlertManager instance
func NewAlertManager(logger *zap.Logger) interfaces.AlertManager {
	config := &AlertConfig{
		EvaluationInterval:   time.Minute * 5, // Evaluate conditions every 5 minutes
		MaxHistoryPerAlert:   100,             // Keep last 100 events per alert
		DefaultSeverity:      interfaces.AlertSeverityWarning,
		EnableAutoEvaluation: true,
	}

	return &AlertManagerImpl{
		id:                 uuid.New().String(),
		name:               "AlertManager",
		version:            "1.0.0",
		status:             interfaces.ManagerStatusStopped,
		logger:             logger,
		alerts:             make(map[string]*interfaces.Alert),
		alertHistory:       make(map[string][]*interfaces.AlertEvent),
		config:             config,
		evaluationInterval: config.EvaluationInterval,
		stopEvaluation:     make(chan struct{}),
		conditionProcessor: &AlertConditionProcessor{logger: logger},
	}
}

// Initialize implémente BaseManager.Initialize
func (am *AlertManagerImpl) Initialize(ctx context.Context) error {
	am.mu.Lock()
	defer am.mu.Unlock()

	if am.isInitialized {
		return fmt.Errorf("alert manager already initialized")
	}

	am.status = interfaces.ManagerStatusStarting
	am.logger.Info("Initializing alert manager", zap.String("id", am.id))

	// Start condition evaluation if enabled
	if am.config.EnableAutoEvaluation {
		am.startConditionEvaluation()
	}

	am.status = interfaces.ManagerStatusRunning
	am.isInitialized = true

	am.logger.Info("Alert manager initialized successfully")
	return nil
}

// Shutdown implémente BaseManager.Shutdown
func (am *AlertManagerImpl) Shutdown(ctx context.Context) error {
	am.mu.Lock()
	defer am.mu.Unlock()

	if !am.isInitialized {
		return fmt.Errorf("alert manager not initialized")
	}

	am.status = interfaces.ManagerStatusStopping
	am.logger.Info("Shutting down alert manager")

	// Stop condition evaluation
	am.stopConditionEvaluation()

	am.status = interfaces.ManagerStatusStopped
	am.isInitialized = false

	am.logger.Info("Alert manager shut down successfully")
	return nil
}

// GetID implémente BaseManager.GetID
func (am *AlertManagerImpl) GetID() string {
	am.mu.RLock()
	defer am.mu.RUnlock()
	return am.id
}

// GetName implémente BaseManager.GetName
func (am *AlertManagerImpl) GetName() string {
	am.mu.RLock()
	defer am.mu.RUnlock()
	return am.name
}

// GetVersion implémente BaseManager.GetVersion
func (am *AlertManagerImpl) GetVersion() string {
	am.mu.RLock()
	defer am.mu.RUnlock()
	return am.version
}

// GetStatus implémente BaseManager.GetStatus
func (am *AlertManagerImpl) GetStatus() interfaces.ManagerStatus {
	am.mu.RLock()
	defer am.mu.RUnlock()
	return am.status
}

// IsHealthy implémente BaseManager.IsHealthy
func (am *AlertManagerImpl) IsHealthy(ctx context.Context) bool {
	am.mu.RLock()
	defer am.mu.RUnlock()
	return am.status == interfaces.ManagerStatusRunning && am.isInitialized
}

// GetMetrics implémente BaseManager.GetMetrics
func (am *AlertManagerImpl) GetMetrics() map[string]interface{} {
	am.mu.RLock()
	defer am.mu.RUnlock()

	activeAlerts := 0
	for _, alert := range am.alerts {
		if alert.IsActive {
			activeAlerts++
		}
	}

	totalEvents := 0
	for _, events := range am.alertHistory {
		totalEvents += len(events)
	}

	return map[string]interface{}{
		"total_alerts":  len(am.alerts),
		"active_alerts": activeAlerts,
		"total_events":  totalEvents,
		"status":        am.status.String(),
	}
}

// CreateAlert implémente AlertManager.CreateAlert
func (am *AlertManagerImpl) CreateAlert(ctx context.Context, alert *interfaces.Alert) error {
	am.mu.Lock()
	defer am.mu.Unlock()

	if !am.isInitialized {
		return fmt.Errorf("alert manager not initialized")
	}

	if alert.ID == "" {
		alert.ID = uuid.New().String()
	}

	// Validate alert
	if err := am.validateAlert(alert); err != nil {
		return fmt.Errorf("invalid alert: %w", err)
	}

	alert.CreatedAt = time.Now()
	alert.UpdatedAt = time.Now()

	am.alerts[alert.ID] = alert
	am.alertHistory[alert.ID] = make([]*interfaces.AlertEvent, 0)

	am.logger.Info("Alert created", 
		zap.String("alert_id", alert.ID),
		zap.String("name", alert.Name),
		zap.String("severity", string(alert.Severity)))

	return nil
}

// UpdateAlert implémente AlertManager.UpdateAlert
func (am *AlertManagerImpl) UpdateAlert(ctx context.Context, alertID string, alert *interfaces.Alert) error {
	am.mu.Lock()
	defer am.mu.Unlock()

	if !am.isInitialized {
		return fmt.Errorf("alert manager not initialized")
	}

	existing, exists := am.alerts[alertID]
	if !exists {
		return fmt.Errorf("alert not found: %s", alertID)
	}

	// Validate alert
	if err := am.validateAlert(alert); err != nil {
		return fmt.Errorf("invalid alert: %w", err)
	}

	// Preserve creation info
	alert.ID = alertID
	alert.CreatedAt = existing.CreatedAt
	alert.UpdatedAt = time.Now()

	am.alerts[alertID] = alert

	am.logger.Info("Alert updated", 
		zap.String("alert_id", alertID),
		zap.String("name", alert.Name))

	return nil
}

// DeleteAlert implémente AlertManager.DeleteAlert
func (am *AlertManagerImpl) DeleteAlert(ctx context.Context, alertID string) error {
	am.mu.Lock()
	defer am.mu.Unlock()

	if !am.isInitialized {
		return fmt.Errorf("alert manager not initialized")
	}

	if _, exists := am.alerts[alertID]; !exists {
		return fmt.Errorf("alert not found: %s", alertID)
	}

	delete(am.alerts, alertID)
	delete(am.alertHistory, alertID)

	am.logger.Info("Alert deleted", zap.String("alert_id", alertID))
	return nil
}

// GetAlert implémente AlertManager.GetAlert
func (am *AlertManagerImpl) GetAlert(ctx context.Context, alertID string) (*interfaces.Alert, error) {
	am.mu.RLock()
	defer am.mu.RUnlock()

	if !am.isInitialized {
		return nil, fmt.Errorf("alert manager not initialized")
	}

	alert, exists := am.alerts[alertID]
	if !exists {
		return nil, fmt.Errorf("alert not found: %s", alertID)
	}

	return alert, nil
}

// ListAlerts implémente AlertManager.ListAlerts
func (am *AlertManagerImpl) ListAlerts(ctx context.Context) ([]*interfaces.Alert, error) {
	am.mu.RLock()
	defer am.mu.RUnlock()

	if !am.isInitialized {
		return nil, fmt.Errorf("alert manager not initialized")
	}

	alerts := make([]*interfaces.Alert, 0, len(am.alerts))
	for _, alert := range am.alerts {
		alerts = append(alerts, alert)
	}

	return alerts, nil
}

// TriggerAlert implémente AlertManager.TriggerAlert
func (am *AlertManagerImpl) TriggerAlert(ctx context.Context, alertID string, data map[string]interface{}) error {
	am.mu.Lock()
	defer am.mu.Unlock()

	if !am.isInitialized {
		return fmt.Errorf("alert manager not initialized")
	}

	alert, exists := am.alerts[alertID]
	if !exists {
		return fmt.Errorf("alert not found: %s", alertID)
	}

	if !alert.IsActive {
		return fmt.Errorf("alert is not active: %s", alertID)
	}

	// Create alert event
	event := &interfaces.AlertEvent{
		ID:        uuid.New().String(),
		AlertID:   alertID,
		Type:      interfaces.AlertEventTriggered,
		Timestamp: time.Now(),
		Data:      data,
		Resolved:  false,
	}

	// Add to history
	am.addAlertEvent(alertID, event)

	// Update alert last triggered time
	now := time.Now()
	alert.LastTriggered = &now
	alert.UpdatedAt = now

	am.logger.Warn("Alert triggered", 
		zap.String("alert_id", alertID),
		zap.String("alert_name", alert.Name),
		zap.String("severity", string(alert.Severity)),
		zap.Any("data", data))

	return nil
}

// GetAlertHistory implémente AlertManager.GetAlertHistory
func (am *AlertManagerImpl) GetAlertHistory(ctx context.Context, alertID string) ([]*interfaces.AlertEvent, error) {
	am.mu.RLock()
	defer am.mu.RUnlock()

	if !am.isInitialized {
		return nil, fmt.Errorf("alert manager not initialized")
	}

	if _, exists := am.alerts[alertID]; !exists {
		return nil, fmt.Errorf("alert not found: %s", alertID)
	}

	history, exists := am.alertHistory[alertID]
	if !exists {
		return []*interfaces.AlertEvent{}, nil
	}

	// Return a copy of the history
	result := make([]*interfaces.AlertEvent, len(history))
	copy(result, history)

	return result, nil
}

// EvaluateAlertConditions implémente AlertManager.EvaluateAlertConditions
func (am *AlertManagerImpl) EvaluateAlertConditions(ctx context.Context) error {
	am.mu.RLock()
	defer am.mu.RUnlock()

	if !am.isInitialized {
		return fmt.Errorf("alert manager not initialized")
	}

	evaluatedCount := 0
	triggeredCount := 0

	for _, alert := range am.alerts {
		if !alert.IsActive {
			continue
		}

		evaluatedCount++

		// Evaluate conditions for this alert
		shouldTrigger, evalData, err := am.conditionProcessor.EvaluateConditions(alert.Conditions)
		if err != nil {
			am.logger.Error("Failed to evaluate alert conditions",
				zap.String("alert_id", alert.ID),
				zap.Error(err))
			continue
		}

		if shouldTrigger {
			// Trigger the alert with evaluation data
			if err := am.TriggerAlert(ctx, alert.ID, evalData); err != nil {
				am.logger.Error("Failed to trigger alert",
					zap.String("alert_id", alert.ID),
					zap.Error(err))
			} else {
				triggeredCount++
			}
		}
	}

	am.logger.Debug("Alert condition evaluation completed",
		zap.Int("evaluated", evaluatedCount),
		zap.Int("triggered", triggeredCount))

	return nil
}

// Private helper methods

// validateAlert validates an alert configuration
func (am *AlertManagerImpl) validateAlert(alert *interfaces.Alert) error {
	if alert.Name == "" {
		return fmt.Errorf("alert name cannot be empty")
	}

	if len(alert.Conditions) == 0 {
		return fmt.Errorf("alert must have at least one condition")
	}

	if len(alert.Actions) == 0 {
		return fmt.Errorf("alert must have at least one action")
	}

	// Validate conditions
	for i, condition := range alert.Conditions {
		if condition.Type == "" {
			return fmt.Errorf("condition %d: type cannot be empty", i)
		}
		if condition.Operator == "" {
			return fmt.Errorf("condition %d: operator cannot be empty", i)
		}
	}

	// Validate actions
	for i, action := range alert.Actions {
		if action.Type == "" {
			return fmt.Errorf("action %d: type cannot be empty", i)
		}
		if len(action.Channels) == 0 {
			return fmt.Errorf("action %d: must specify at least one channel", i)
		}
	}

	return nil
}

// addAlertEvent adds an event to alert history with size management
func (am *AlertManagerImpl) addAlertEvent(alertID string, event *interfaces.AlertEvent) {
	history := am.alertHistory[alertID]
	
	// Add new event
	history = append(history, event)
	
	// Trim history if it exceeds maximum size
	if len(history) > am.config.MaxHistoryPerAlert {
		// Keep only the most recent events
		history = history[len(history)-am.config.MaxHistoryPerAlert:]
	}
	
	am.alertHistory[alertID] = history
}

// startConditionEvaluation starts the automatic condition evaluation
func (am *AlertManagerImpl) startConditionEvaluation() {
	am.evaluationTicker = time.NewTicker(am.evaluationInterval)
	
	go func() {
		am.logger.Info("Started alert condition evaluation",
			zap.Duration("interval", am.evaluationInterval))
		
		for {
			select {
			case <-am.evaluationTicker.C:
				ctx := context.Background()
				if err := am.EvaluateAlertConditions(ctx); err != nil {
					am.logger.Error("Alert condition evaluation failed", zap.Error(err))
				}
			case <-am.stopEvaluation:
				am.logger.Info("Stopped alert condition evaluation")
				return
			}
		}
	}()
}

// stopConditionEvaluation stops the automatic condition evaluation
func (am *AlertManagerImpl) stopConditionEvaluation() {
	if am.evaluationTicker != nil {
		am.evaluationTicker.Stop()
		close(am.stopEvaluation)
		am.stopEvaluation = make(chan struct{}) // Reset for next initialization
	}
}

// AlertConditionProcessor methods

// EvaluateConditions evaluates alert conditions and returns whether to trigger
func (acp *AlertConditionProcessor) EvaluateConditions(conditions []*interfaces.AlertCondition) (bool, map[string]interface{}, error) {
	evalData := make(map[string]interface{})
	
	for i, condition := range conditions {
		result, err := acp.evaluateCondition(condition)
		if err != nil {
			return false, nil, fmt.Errorf("condition %d evaluation failed: %w", i, err)
		}
		
		evalData[fmt.Sprintf("condition_%d_result", i)] = result
		
		// For now, implement simple AND logic - all conditions must be true
		if !result {
			return false, evalData, nil
		}
	}
	
	return true, evalData, nil
}

// evaluateCondition evaluates a single alert condition
func (acp *AlertConditionProcessor) evaluateCondition(condition *interfaces.AlertCondition) (bool, error) {
	// This is a simplified implementation
	// In a real implementation, you would:
	// 1. Fetch metrics/data based on condition.Type
	// 2. Apply the operator to compare Value vs Threshold
	// 3. Return the result
	
	switch condition.Type {
	case "metric":
		return acp.evaluateMetricCondition(condition)
	case "threshold":
		return acp.evaluateThresholdCondition(condition)
	case "time":
		return acp.evaluateTimeCondition(condition)
	default:
		return false, fmt.Errorf("unsupported condition type: %s", condition.Type)
	}
}

// evaluateMetricCondition evaluates metric-based conditions
func (acp *AlertConditionProcessor) evaluateMetricCondition(condition *interfaces.AlertCondition) (bool, error) {
	// Placeholder implementation
	// In real implementation, fetch actual metrics and compare
	acp.logger.Debug("Evaluating metric condition", 
		zap.String("operator", condition.Operator),
		zap.Any("value", condition.Value),
		zap.Any("threshold", condition.Threshold))
	
	// For now, randomly return false to avoid constant triggering
	return false, nil
}

// evaluateThresholdCondition evaluates threshold-based conditions
func (acp *AlertConditionProcessor) evaluateThresholdCondition(condition *interfaces.AlertCondition) (bool, error) {
	// Placeholder implementation
	acp.logger.Debug("Evaluating threshold condition",
		zap.String("operator", condition.Operator),
		zap.Any("value", condition.Value),
		zap.Any("threshold", condition.Threshold))
	
	return false, nil
}

// evaluateTimeCondition evaluates time-based conditions
func (acp *AlertConditionProcessor) evaluateTimeCondition(condition *interfaces.AlertCondition) (bool, error) {
	// Placeholder implementation
	acp.logger.Debug("Evaluating time condition",
		zap.String("operator", condition.Operator),
		zap.Any("value", condition.Value))
	
	return false, nil
}
