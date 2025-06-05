package interfaces

import "context"

// MonitoringManager interface pour la surveillance
type MonitoringManager interface {
	BaseManager
	StartOperationMonitoring(ctx context.Context, operation string) (*OperationMetrics, error)
	StopOperationMonitoring(ctx context.Context, metrics *OperationMetrics) error
	CheckSystemHealth(ctx context.Context) error
	ConfigureAlerts(ctx context.Context, config map[string]interface{}) error
	CollectMetrics(ctx context.Context) (*SystemMetrics, error)
	StartMonitoring(ctx context.Context) error
	StopMonitoring(ctx context.Context) error
}
