package main

import (
	"context"
	"sync"
	"time"

	"go.uber.org/zap"
)

// MetricsCollector collects and manages metrics from all managers
type MetricsCollector struct {
	metrics map[string]interface{}
	logger  *zap.Logger
	mu      sync.RWMutex
}

// NewMetricsCollector creates a new metrics collector
func NewMetricsCollector(logger *zap.Logger) *MetricsCollector {
	return &MetricsCollector{
		metrics: make(map[string]interface{}),
		logger:  logger,
	}
}

// Start initializes the metrics collector
func (mc *MetricsCollector) Start(ctx context.Context) error {
	mc.logger.Info("Starting metrics collector")
	return nil
}

// Stop shuts down the metrics collector
func (mc *MetricsCollector) Stop(ctx context.Context) error {
	mc.logger.Info("Stopping metrics collector")
	return nil
}

// Record records a metric
func (mc *MetricsCollector) Record(key string, value interface{}) {
	mc.mu.Lock()
	defer mc.mu.Unlock()
	mc.metrics[key] = value
}

// GetMetrics returns all collected metrics
func (mc *MetricsCollector) GetMetrics() map[string]interface{} {
	mc.mu.RLock()
	defer mc.mu.RUnlock()

	result := make(map[string]interface{})
	for k, v := range mc.metrics {
		result[k] = v
	}
	return result
}

// Additional missing config types
type ProcessConfig struct {
	MaxProcesses int `yaml:"max_processes"`
}

type ContainerConfig struct {
	Runtime string `yaml:"runtime"`
}

type DependencyConfig struct {
	AutoUpdate bool `yaml:"auto_update"`
}

type ConfigMgrConfig struct {
	WatchChanges bool `yaml:"watch_changes"`
}

type WatchConfig struct {
	Interval time.Duration `yaml:"interval"`
}
