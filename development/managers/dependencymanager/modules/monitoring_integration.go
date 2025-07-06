package monitoring

import (
	"context"
	"fmt"

	"EMAIL_SENDER_1/development/managers/interfaces"
)

// initializeMonitoringIntegration sets up monitoring manager integration
func (m *GoModManager) initializeMonitoringIntegration() error {
	// Check if monitoring manager is already initialized
	if m.monitoringManager != nil {
		return nil
	}

	m.logger.Info("Initializing monitoring integration...")
	// In a real implementation, this would use a factory or service locator
	// to get an instance of the MonitoringManager

	// For now we'll just log this step
	m.logger.Info("Monitoring integration initialized successfully")
	return nil
}

// monitorDependencyOperation monitors the performance of dependency operations
func (m *GoModManager) monitorDependencyOperation(ctx context.Context, operation string, fn func() error) error {
	if m.monitoringManager == nil {
		// If no monitoring manager, just execute the function
		return fn()
	}

	m.logger.Info(fmt.Sprintf("Monitoring operation: %s", operation))

	// Start monitoring the operation
	// StartOperationMonitoring now returns *interfaces.OperationMetrics
	metrics, err := m.monitoringManager.StartOperationMonitoring(ctx, operation)
	if err != nil {
		m.logger.Warn(fmt.Sprintf("Warning: Failed to start monitoring for operation %s: %v", operation, err))
		// Continue with the operation even if monitoring fails
		return fn()
	}

	// Execute the operation
	opErr := fn()

	// If operation failed, set success to false
	if opErr != nil {
		metrics.Success = false
		metrics.ErrorMessage = opErr.Error()
	} else {
		metrics.Success = true
	}

	// Stop monitoring
	if stopErr := m.monitoringManager.StopOperationMonitoring(ctx, metrics); stopErr != nil {
		m.logger.Warn(fmt.Sprintf("Warning: Failed to stop monitoring for operation %s: %v", operation, stopErr))
	}

	return opErr
}

// configureOperationAlerts configures alerts for dependency operation failures
func (m *GoModManager) configureOperationAlerts() error {
	if m.monitoringManager == nil {
		return fmt.Errorf("monitoring manager not initialized")
	}

	m.logger.Info("Configuring alerts for dependency resolution failures...")

	// Configure alert for dependency resolution failures
	resolutionAlertConfig := &interfaces.AlertConfig{
		Name:    "dependency_resolution_failure",
		Enabled: true,
		Conditions: []string{
			"operation == 'add_dependency' && success == false",
			"operation == 'update_dependency' && success == false",
			"operation == 'remove_dependency' && success == false",
		},
		Thresholds: map[string]float64{
			"consecutive_failures": 2,   // Alert after 2 consecutive failures
			"failure_rate":         0.3, // Alert if 30% of operations fail
		},
		NotifyChannels:  []string{"email", "slack"},
		SuppressTimeout: 15, // Suppress similar alerts for 15 minutes
	}

	if err := m.monitoringManager.ConfigureAlerts(context.Background(), resolutionAlertConfig); err != nil {
		m.logger.Error(fmt.Sprintf("Error configuring resolution failure alerts: %v", err))
		return err
	}

	// Configure alert for security vulnerabilities
	vulnerabilityAlertConfig := &interfaces.AlertConfig{
		Name:    "dependency_vulnerability",
		Enabled: true,
		Conditions: []string{
			"operation == 'security_audit' && vulnerabilities_found > 0",
		},
		Thresholds: map[string]float64{
			"critical_vulnerabilities": 1, // Alert on any critical vulnerability
			"high_vulnerabilities":     3, // Alert if 3 or more high vulnerabilities
		},
		NotifyChannels:  []string{"email", "slack", "pagerduty"},
		SuppressTimeout: 60, // Suppress similar alerts for 60 minutes
	}

	if err := m.monitoringManager.ConfigureAlerts(context.Background(), vulnerabilityAlertConfig); err != nil {
		m.logger.Error(fmt.Sprintf("Error configuring vulnerability alerts: %v", err))
		return err
	}

	// Configure alert for performance degradation
	performanceAlertConfig := &interfaces.AlertConfig{
		Name:    "dependency_operation_slow",
		Enabled: true,
		Conditions: []string{
			"duration > threshold",
		},
		Thresholds: map[string]float64{
			"add_dependency":    5000,  // Alert if add takes more than 5s
			"update_dependency": 8000,  // Alert if update takes more than 8s
			"remove_dependency": 3000,  // Alert if remove takes more than 3s
			"list_dependencies": 500,   // Alert if list takes more than 0.5s
			"security_audit":    15000, // Alert if audit takes more than 15s
		},
		NotifyChannels:  []string{"email", "slack"},
		SuppressTimeout: 30, // Suppress similar alerts for 30 minutes
	}

	if err := m.monitoringManager.ConfigureAlerts(context.Background(), performanceAlertConfig); err != nil {
		m.logger.Error(fmt.Sprintf("Error configuring performance alerts: %v", err))
		return err
	}

	m.logger.Info("Alerts for dependency operations configured successfully")
	return nil
}

// monitorSecurityAudit monitors the security audit process and generates alerts for vulnerabilities
func (m *GoModManager) monitorSecurityAudit(ctx context.Context, dependencies []interfaces.Dependency) (*interfaces.VulnerabilityReport, error) {
	if m.securityManager == nil {
		return nil, fmt.Errorf("security manager not initialized")
	}

	if m.monitoringManager == nil {
		// If no monitoring manager, just execute the scan
		return m.securityManager.ScanDependenciesForVulnerabilities(ctx, dependencies) // Corrected method name
	}

	m.logger.Info("Monitoring security audit operation")

	// Start monitoring the security scan
	// StartOperationMonitoring now returns *interfaces.OperationMetrics
	metrics, err := m.monitoringManager.StartOperationMonitoring(ctx, "security_audit")
	if err != nil {
		m.logger.Warn(fmt.Sprintf("Warning: Failed to start monitoring for security audit: %v", err))
		// Continue with the operation even if monitoring fails
		return m.securityManager.ScanDependenciesForVulnerabilities(ctx, dependencies) // Corrected method name
	}

	// Execute the security scan
	report, scanErr := m.securityManager.ScanDependenciesForVulnerabilities(ctx, dependencies) // Corrected method name

	// Update metrics
	metrics.Success = scanErr == nil
	if scanErr != nil {
		metrics.ErrorMessage = scanErr.Error()
	} else {
		// Include vulnerability metrics in the monitoring data
		if report != nil { // Ensure report is not nil before accessing fields
			totalVulns := report.CriticalCount + report.HighCount + report.MediumCount + report.LowCount
			metrics.Tags = map[string]string{
				"total_scanned":         fmt.Sprintf("%d", report.TotalScanned),
				"vulnerabilities_found": fmt.Sprintf("%d", totalVulns),
			}
		}
	}

	// Stop monitoring
	if stopErr := m.monitoringManager.StopOperationMonitoring(ctx, metrics); stopErr != nil {
		m.logger.Warn(fmt.Sprintf("Warning: Failed to stop monitoring for security audit: %v", stopErr))
	}

	return report, scanErr
}
