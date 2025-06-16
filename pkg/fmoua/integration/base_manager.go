// Package integration provides specialized managers for FMOUA Phase 2
// Implements BaseManager and specialized managers (Email, Database, Cache, Webhook)
package integration

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/types"
)

// BaseManager provides common functionality for all specialized managers
type BaseManager struct {
	id      string
	config  types.ManagerConfig
	status  types.ManagerStatus
	metrics MetricsCollector
	logger  *zap.Logger
	mu      sync.RWMutex
	ctx     context.Context
	cancel  context.CancelFunc
}

// MetricsCollector interface for collecting manager metrics
type MetricsCollector interface {
	Increment(metric string, tags map[string]string)
	Gauge(metric string, value float64, tags map[string]string)
	Histogram(metric string, value float64, tags map[string]string)
	GetMetrics() map[string]interface{}
}

// NewBaseManager creates a new BaseManager instance
func NewBaseManager(id string, config types.ManagerConfig, logger *zap.Logger, metrics MetricsCollector) *BaseManager {
	ctx, cancel := context.WithCancel(context.Background())

	return &BaseManager{
		id:      id,
		config:  config,
		status:  types.ManagerStatusStopped,
		metrics: metrics,
		logger:  logger.With(zap.String("manager_id", id)),
		ctx:     ctx,
		cancel:  cancel,
	}
}

// GetID returns the manager identifier
func (bm *BaseManager) GetID() string {
	bm.mu.RLock()
	defer bm.mu.RUnlock()
	return bm.id
}

// GetType returns the manager type from configuration
func (bm *BaseManager) GetType() string {
	bm.mu.RLock()
	defer bm.mu.RUnlock()
	return bm.config.Type
}

// GetStatus returns the current manager status
func (bm *BaseManager) GetStatus() types.ManagerStatus {
	bm.mu.RLock()
	defer bm.mu.RUnlock()
	return bm.status
}

// SetStatus updates the manager status with logging
func (bm *BaseManager) SetStatus(status types.ManagerStatus) {
	bm.mu.Lock()
	defer bm.mu.Unlock()

	oldStatus := bm.status
	bm.status = status

	bm.logger.Info("Manager status changed",
		zap.String("from", string(oldStatus)),
		zap.String("to", string(status)),
	)

	// Update metrics
	if bm.metrics != nil {
		bm.metrics.Increment("manager_status_change", map[string]string{
			"manager_id": bm.id,
			"from":       string(oldStatus),
			"to":         string(status),
		})
	}
}

// Initialize initializes the base manager with validation
func (bm *BaseManager) Initialize(config types.ManagerConfig) error {
	bm.mu.Lock()
	defer bm.mu.Unlock()

	// Validate configuration
	if config.ID == "" {
		return fmt.Errorf("manager ID cannot be empty")
	}

	if config.Type == "" {
		return fmt.Errorf("manager type cannot be empty")
	}

	bm.config = config
	bm.logger.Info("Manager initialized",
		zap.String("type", config.Type),
		zap.Int("priority", config.Priority),
	)

	return nil
}

// Start starts the base manager (to be extended by specialized managers)
func (bm *BaseManager) Start() error {
	bm.SetStatus(types.ManagerStatusStarting)

	bm.logger.Info("Starting base manager")

	// Record start time for metrics
	startTime := time.Now()
	defer func() {
		if bm.metrics != nil {
			bm.metrics.Histogram("manager_start_duration",
				float64(time.Since(startTime).Milliseconds()),
				map[string]string{"manager_id": bm.id},
			)
		}
	}()

	bm.SetStatus(types.ManagerStatusRunning)
	return nil
}

// Stop stops the base manager
func (bm *BaseManager) Stop() error {
	bm.SetStatus(types.ManagerStatusStopping)

	bm.logger.Info("Stopping base manager")

	// Cancel context to stop all operations
	if bm.cancel != nil {
		bm.cancel()
	}

	bm.SetStatus(types.ManagerStatusStopped)
	return nil
}

// Cleanup performs cleanup operations
func (bm *BaseManager) Cleanup() error {
	bm.logger.Info("Cleaning up base manager")

	// Cancel context if not already done
	if bm.cancel != nil {
		bm.cancel()
	}

	return nil
}

// LogInfo logs an info message with manager context
func (bm *BaseManager) LogInfo(message string, fields ...zap.Field) {
	bm.logger.Info(message, fields...)
}

// LogError logs an error message with manager context
func (bm *BaseManager) LogError(message string, err error, fields ...zap.Field) {
	allFields := append(fields, zap.Error(err))
	bm.logger.Error(message, allFields...)
}

// LogDebug logs a debug message with manager context
func (bm *BaseManager) LogDebug(message string, fields ...zap.Field) {
	bm.logger.Debug(message, fields...)
}

// GetMetrics returns current metrics for the manager
func (bm *BaseManager) GetMetrics() map[string]interface{} {
	if bm.metrics == nil {
		return map[string]interface{}{}
	}
	return bm.metrics.GetMetrics()
}

// Context returns the manager's context
func (bm *BaseManager) Context() context.Context {
	return bm.ctx
}

// DefaultMetricsCollector provides a basic metrics implementation
type DefaultMetricsCollector struct {
	counters   map[string]int64
	gauges     map[string]float64
	histograms map[string][]float64
	mu         sync.RWMutex
}

// NewDefaultMetricsCollector creates a new metrics collector
func NewDefaultMetricsCollector() *DefaultMetricsCollector {
	return &DefaultMetricsCollector{
		counters:   make(map[string]int64),
		gauges:     make(map[string]float64),
		histograms: make(map[string][]float64),
	}
}

// Increment increments a counter metric
func (dmc *DefaultMetricsCollector) Increment(metric string, tags map[string]string) {
	dmc.mu.Lock()
	defer dmc.mu.Unlock()

	key := metric
	for k, v := range tags {
		key += fmt.Sprintf(",%s=%s", k, v)
	}

	dmc.counters[key]++
}

// Gauge sets a gauge metric value
func (dmc *DefaultMetricsCollector) Gauge(metric string, value float64, tags map[string]string) {
	dmc.mu.Lock()
	defer dmc.mu.Unlock()

	key := metric
	for k, v := range tags {
		key += fmt.Sprintf(",%s=%s", k, v)
	}

	dmc.gauges[key] = value
}

// Histogram records a histogram value
func (dmc *DefaultMetricsCollector) Histogram(metric string, value float64, tags map[string]string) {
	dmc.mu.Lock()
	defer dmc.mu.Unlock()

	key := metric
	for k, v := range tags {
		key += fmt.Sprintf(",%s=%s", k, v)
	}

	dmc.histograms[key] = append(dmc.histograms[key], value)
}

// GetMetrics returns all collected metrics
func (dmc *DefaultMetricsCollector) GetMetrics() map[string]interface{} {
	dmc.mu.RLock()
	defer dmc.mu.RUnlock()

	return map[string]interface{}{
		"counters":   dmc.counters,
		"gauges":     dmc.gauges,
		"histograms": dmc.histograms,
	}
}
