package main

import (
	"context"
	"time"
)

// MonitoringManagerInterface defines the subset of MonitoringManager functions used by DependencyManager
type MonitoringManagerInterface interface {
	StartOperationMonitoring(ctx context.Context, operation string) (*OperationMetrics, error)
	StopOperationMonitoring(ctx context.Context, metrics *OperationMetrics) error
	ConfigureAlerts(ctx context.Context, config *AlertConfig) error
}

// OperationMetrics represents metrics for a monitored operation
type OperationMetrics struct {
	Operation    string        `json:"operation"`
	StartTime    time.Time     `json:"start_time"`
	EndTime      time.Time     `json:"end_time,omitempty"`
	Duration     time.Duration `json:"duration"`
	CPUUsage     float64       `json:"cpu_usage"`
	MemoryUsage  float64       `json:"memory_usage"`
	Success      bool          `json:"success"`
	ErrorMessage string        `json:"error_message,omitempty"`
}

// AlertConfig defines configuration for dependency operation alerts
type AlertConfig struct {
	Name            string   `json:"name"`
	Enabled         bool     `json:"enabled"`
	Conditions      []string `json:"conditions"`
	Thresholds      map[string]float64 `json:"thresholds"`
	NotifyChannels  []string `json:"notify_channels"`
	SuppressTimeout int      `json:"suppress_timeout_minutes"`
}

// StorageManagerInterface defines the subset of StorageManager functions used by DependencyManager
type StorageManagerInterface interface {
	StoreObject(ctx context.Context, key string, data interface{}) error
	GetObject(ctx context.Context, key string, target interface{}) error
	DeleteObject(ctx context.Context, key string) error
	ListObjects(ctx context.Context, prefix string) ([]string, error)
}

// These interfaces allow us to use only the functions we need from each manager
// while maintaining compatibility with the full manager implementations.
// They also help with testing by making it easier to create mock implementations.
