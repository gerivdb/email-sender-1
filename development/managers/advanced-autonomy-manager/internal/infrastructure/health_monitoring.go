// Package infrastructure provides tools for automated infrastructure management
// within the AdvancedAutonomyManager ecosystem.
package infrastructure

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"sync"
	"time"
)

// HealthMonitorConfig defines configuration for the health monitor
type HealthMonitorConfig struct {
	CheckInterval    time.Duration         `json:"check_interval"`     // Interval between health checks
	Timeout          time.Duration         `json:"timeout"`            // Timeout for health checks
	HealthEndpoints  map[string]string     `json:"health_endpoints"`   // Service health endpoints
	CustomCheckers   map[string]HealthCheck `json:"custom_checkers"`   // Custom health check functions
}

// HealthCheck defines a function type for custom health checks
type HealthCheck func(ctx context.Context) (bool, error)

// NewHealthMonitor creates a new health monitor
func NewHealthMonitor(config *HealthMonitorConfig) (*HealthMonitor, error) {
	if config == nil {
		return nil, ErrInvalidConfiguration
	}

	if config.CheckInterval <= 0 {
		config.CheckInterval = 10 * time.Second
	}

	if config.Timeout <= 0 {
		config.Timeout = 5 * time.Second
	}

	monitor := &HealthMonitor{
		checkInterval: config.CheckInterval,
		timeout:       config.Timeout,
		endpoints:     config.HealthEndpoints,
		customCheckers: config.CustomCheckers,
		status:        make(map[string]bool),
		lastCheck:     make(map[string]time.Time),
		lock:          sync.RWMutex{},
		stopCh:        make(chan struct{}),
	}

	return monitor, nil
}

// customCheckers stores custom health check functions
type customCheckers map[string]HealthCheck

// Start begins periodic health monitoring
func (m *HealthMonitor) Start(ctx context.Context) {
	ticker := time.NewTicker(m.checkInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-m.stopCh:
			return
		case <-ticker.C:
			m.checkAllServices(ctx)
		}
	}
}

// Stop halts the health monitoring
func (m *HealthMonitor) Stop() {
	close(m.stopCh)
}

// GetServiceHealth returns the health status for a service
func (m *HealthMonitor) GetServiceHealth(service string) (bool, time.Time, bool) {
	m.lock.RLock()
	defer m.lock.RUnlock()
	
	status, exists := m.status[service]
	lastCheck, _ := m.lastCheck[service]
	return status, lastCheck, exists
}

// GetAllServiceHealth returns health status for all services
func (m *HealthMonitor) GetAllServiceHealth() map[string]ServiceStatus {
	m.lock.RLock()
	defer m.lock.RUnlock()

	result := make(map[string]ServiceStatus)
	for service, healthy := range m.status {
		result[service] = ServiceStatus{
			Name:           service,
			HealthStatus:   healthy,
			LastHealthTime: m.lastCheck[service],
		}
	}

	return result
}

// AddServiceEndpoint adds or updates a service health endpoint
func (m *HealthMonitor) AddServiceEndpoint(service, endpoint string) {
	m.lock.Lock()
	defer m.lock.Unlock()
	
	m.endpoints[service] = endpoint
}

// AddCustomChecker adds a custom health checker for a service
func (m *HealthMonitor) AddCustomChecker(service string, checker HealthCheck) {
	m.lock.Lock()
	defer m.lock.Unlock()
	
	if m.customCheckers == nil {
		m.customCheckers = make(map[string]HealthCheck)
	}
	
	m.customCheckers[service] = checker
}

// CheckServiceHealth performs a health check for a specific service
func (m *HealthMonitor) CheckServiceHealth(ctx context.Context, service string) (bool, error) {
	m.lock.RLock()
	endpoint, hasEndpoint := m.endpoints[service]
	checker, hasChecker := m.customCheckers[service]
	m.lock.RUnlock()

	// Create context with timeout
	ctx, cancel := context.WithTimeout(ctx, m.timeout)
	defer cancel()

	// Use custom checker if available
	if hasChecker {
		healthy, err := checker(ctx)
		m.updateServiceStatus(service, healthy)
		return healthy, err
	}

	// Use HTTP endpoint if available
	if hasEndpoint {
		healthy, err := m.checkHTTPEndpoint(ctx, endpoint)
		m.updateServiceStatus(service, healthy)
		return healthy, err
	}

	return false, fmt.Errorf("no health check configured for service %s", service)
}

// checkAllServices performs health checks on all configured services
func (m *HealthMonitor) checkAllServices(ctx context.Context) {
	m.lock.RLock()
	services := make([]string, 0, len(m.endpoints)+len(m.customCheckers))
	
	// Collect all service names
	for service := range m.endpoints {
		services = append(services, service)
	}
	
	for service := range m.customCheckers {
		// Avoid duplicates
		if _, exists := m.endpoints[service]; !exists {
			services = append(services, service)
		}
	}
	m.lock.RUnlock()

	// Check each service
	for _, service := range services {
		m.CheckServiceHealth(ctx, service)
	}
}

// updateServiceStatus updates the health status for a service
func (m *HealthMonitor) updateServiceStatus(service string, healthy bool) {
	m.lock.Lock()
	defer m.lock.Unlock()
	
	m.status[service] = healthy
	m.lastCheck[service] = time.Now()
}

// checkHTTPEndpoint checks a service's health via HTTP endpoint
func (m *HealthMonitor) checkHTTPEndpoint(ctx context.Context, endpoint string) (bool, error) {
	// Validate URL
	_, err := url.Parse(endpoint)
	if err != nil {
		return false, fmt.Errorf("invalid health check URL %s: %w", endpoint, err)
	}

	// Create HTTP request with context
	req, err := http.NewRequestWithContext(ctx, "GET", endpoint, nil)
	if err != nil {
		return false, err
	}

	// Execute request
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return false, err
	}
	defer resp.Body.Close()

	// Check for success status code
	return resp.StatusCode >= 200 && resp.StatusCode < 300, nil
}

// checkRedisHealth checks Redis health with PING command
func (m *HealthMonitor) checkRedisHealth(ctx context.Context, redisURL string) (bool, error) {
	// In a real implementation, this would use the Redis client to send a PING command
	// For now, just simulating the behavior
	
	// Parse Redis URL
	_, err := url.Parse(redisURL)
	if err != nil {
		return false, fmt.Errorf("invalid Redis URL %s: %w", redisURL, err)
	}
	
	// Example of how to integrate with a Redis client:
	/*
	client := redis.NewClient(&redis.Options{
		Addr: redisHost,
	})
	defer client.Close()
	
	status := client.Ping(ctx)
	return status.Err() == nil, status.Err()
	*/
	
	// Simulated implementation
	return true, nil
}

// checkPostgreSQLHealth checks PostgreSQL health with a simple query
func (m *HealthMonitor) checkPostgreSQLHealth(ctx context.Context, pgURL string) (bool, error) {
	// In a real implementation, this would use the PostgreSQL driver to execute a simple query
	// For now, just simulating the behavior
	
	// Parse PostgreSQL URL
	_, err := url.Parse(pgURL)
	if err != nil {
		return false, fmt.Errorf("invalid PostgreSQL URL %s: %w", pgURL, err)
	}
	
	// Example of how to integrate with a PostgreSQL client:
	/*
	db, err := sql.Open("postgres", pgURL)
	if err != nil {
		return false, err
	}
	defer db.Close()
	
	err = db.PingContext(ctx)
	return err == nil, err
	*/
	
	// Simulated implementation
	return true, nil
}

// checkQDrantHealth checks QDrant vector database health
func (m *HealthMonitor) checkQDrantHealth(ctx context.Context, qdrantURL string) (bool, error) {
	// QDrant typically has a REST API health endpoint
	endpoint := fmt.Sprintf("%s/health", qdrantURL)
	return m.checkHTTPEndpoint(ctx, endpoint)
}
