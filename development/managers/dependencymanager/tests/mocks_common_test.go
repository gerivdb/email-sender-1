package tests

import (
	"context"
	"encoding/json"
	"time"

	"go.uber.org/zap"

	"EMAIL_SENDER_1/development/managers/interfaces"
)

// MockSecurityManagerFull implements interfaces.SecurityManagerInterface for testing
type MockSecurityManagerFull struct {
	logger          *zap.Logger
	vulnerabilities map[string][]string
}

func (m *MockSecurityManagerFull) GetSecret(key string) (string, error) {
	return "mock-secret", nil
}

func (m *MockSecurityManagerFull) ValidateAPIKey(ctx context.Context, key string) (bool, error) {
	return true, nil
}
func (m *MockSecurityManagerFull) HealthCheck(ctx context.Context) error { return nil }

func (m *MockSecurityManagerFull) EncryptData(data []byte) ([]byte, error) {
	return append([]byte("encrypted:"), data...), nil
}

func (m *MockSecurityManagerFull) DecryptData(encryptedData []byte) ([]byte, error) {
	return []byte("decrypted-data"), nil
}

func (m *MockSecurityManagerFull) ScanForVulnerabilities(ctx context.Context, dependencies []interfaces.Dependency) (*interfaces.VulnerabilityReport, error) {
	report := &interfaces.VulnerabilityReport{
		TotalScanned:         len(dependencies),
		VulnerabilitiesFound: 0,
		Timestamp:            time.Now(),
		Details:              make(map[string]*interfaces.VulnerabilityInfo),
	}

	// Check each dependency against our vulnerability database
	for _, dep := range dependencies {
		if cves, exists := m.vulnerabilities[dep.Name]; exists {
			report.VulnerabilitiesFound++
			report.Details[dep.Name] = &interfaces.VulnerabilityInfo{
				Severity:    "high",
				Description: "Security vulnerability found in package",
				CVEIDs:      cves,
				FixVersion:  dep.Version + "-patched",
			}
		}
	}

	return report, nil
}

// MockMonitoringManagerFull implements interfaces.MonitoringManagerInterface for testing
type MockMonitoringManagerFull struct {
	logger           *zap.Logger
	operationMetrics map[string]*interfaces.OperationMetrics
	alertsConfigured map[string]bool
}

func (m *MockMonitoringManagerFull) HealthCheck(ctx context.Context) error { return nil }
func (m *MockMonitoringManagerFull) CollectMetrics(ctx context.Context) (*interfaces.SystemMetrics, error) {
	return &interfaces.SystemMetrics{}, nil
}

func (m *MockMonitoringManagerFull) CheckSystemHealth(ctx context.Context) (*interfaces.HealthStatus, error) {
	return &interfaces.HealthStatus{}, nil
}

func (m *MockMonitoringManagerFull) StartOperationMonitoring(ctx context.Context, operation string) (*interfaces.OperationMetrics, error) {
	if m.operationMetrics == nil {
		m.operationMetrics = make(map[string]*interfaces.OperationMetrics)
	}

	if m.alertsConfigured == nil {
		m.alertsConfigured = make(map[string]bool)
	}

	metrics := &interfaces.OperationMetrics{
		Operation:   operation,
		StartTime:   time.Now(),
		CPUUsage:    5.0,
		MemoryUsage: 10.0,
	}

	m.operationMetrics[operation] = metrics
	return metrics, nil
}

func (m *MockMonitoringManagerFull) StopOperationMonitoring(ctx context.Context, metrics *interfaces.OperationMetrics) error {
	if metrics == nil {
		return nil
	}

	metrics.EndTime = time.Now()
	metrics.Duration = metrics.EndTime.Sub(metrics.StartTime)

	m.operationMetrics[metrics.Operation] = metrics
	return nil
}

func (m *MockMonitoringManagerFull) ConfigureAlerts(ctx context.Context, config *interfaces.AlertConfig) error {
	if m.alertsConfigured == nil {
		m.alertsConfigured = make(map[string]bool)
	}

	m.alertsConfigured[config.Name] = config.Enabled
	return nil
}

// MockStorageManager implements interfaces.StorageManagerInterface for testing
type MockStorageManager struct {
	logger   *zap.Logger
	metadata map[string]*interfaces.DependencyMetadata
}

func NewMockStorageManager(logger *zap.Logger) *MockStorageManager {
	return &MockStorageManager{
		logger:   logger,
		metadata: make(map[string]*interfaces.DependencyMetadata),
	}
}

func (m *MockStorageManager) StoreObject(ctx context.Context, key string, data interface{}) error {
	dataBytes, err := json.Marshal(data)
	if err != nil {
		return err
	}

	var metadata interfaces.DependencyMetadata
	if err := json.Unmarshal(dataBytes, &metadata); err != nil {
		return err
	}

	m.metadata[metadata.Name] = &metadata
	return nil
}

func (m *MockStorageManager) GetObject(ctx context.Context, key string, target interface{}) error {
	if metadata, exists := m.metadata[key]; exists {
		dataBytes, err := json.Marshal(metadata)
		if err != nil {
			return err
		}

		return json.Unmarshal(dataBytes, target)
	}

	return nil
}

func (m *MockStorageManager) DeleteObject(ctx context.Context, key string) error {
	delete(m.metadata, key)
	return nil
}

func (m *MockStorageManager) ListObjects(ctx context.Context, prefix string) ([]string, error) {
	var keys []string
	for key := range m.metadata {
		keys = append(keys, key)
	}
	return keys, nil
}
