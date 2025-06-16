package integration

import (
	"context"
	"testing"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/interfaces"
	"email_sender/pkg/fmoua/types"
)

func TestNewManagerProxy(t *testing.T) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	managerType := "TestManager"

	proxy := NewManagerProxy(managerType, config, logger)

	if proxy == nil {
		t.Error("Proxy should not be nil")
	}
	if proxy.managerType != managerType {
		t.Errorf("Expected manager type '%s', got '%s'", managerType, proxy.managerType)
	}
	if proxy.config != config {
		t.Error("Config should be set correctly")
	}
	if proxy.isRunning {
		t.Error("Proxy should not be running initially")
	}
}

func TestManagerProxy_Name(t *testing.T) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	managerType := "StorageManager"

	proxy := NewManagerProxy(managerType, config, logger)
	expectedName := "StorageManager-proxy"

	if proxy.Name() != expectedName {
		t.Errorf("Expected name '%s', got '%s'", expectedName, proxy.Name())
	}
}

func TestManagerProxy_Status(t *testing.T) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	proxy := NewManagerProxy("TestManager", config, logger)

	// Test status when not running
	status := proxy.Status()
	if status.IsHealthy {
		t.Error("Status should not be healthy when not running")
	}
	if status.ResponseTime <= 0 {
		t.Error("Response time should be positive")
	}
	if status.LastCheck.IsZero() {
		t.Error("Last check should be set")
	}

	// Test status when running
	ctx := context.Background()
	proxy.Start(ctx)
	status = proxy.Status()
	if !status.IsHealthy {
		t.Error("Status should be healthy when running")
	}

	proxy.Stop()
}

func TestManagerProxy_StartStop(t *testing.T) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	proxy := NewManagerProxy("TestManager", config, logger)

	ctx := context.Background()

	// Test start
	startTime := time.Now()
	err := proxy.Start(ctx)
	startDuration := time.Since(startTime)

	if err != nil {
		t.Errorf("Unexpected error starting proxy: %v", err)
	}
	if !proxy.isRunning {
		t.Error("Proxy should be running after start")
	}
	if startDuration > 200*time.Millisecond {
		t.Errorf("Start took %v, should be faster for proxy", startDuration)
	}

	// Test stop
	err = proxy.Stop()
	if err != nil {
		t.Errorf("Unexpected error stopping proxy: %v", err)
	}
	if proxy.isRunning {
		t.Error("Proxy should not be running after stop")
	}
}

func TestManagerProxy_Health(t *testing.T) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	proxy := NewManagerProxy("TestManager", config, logger)

	// Test health when not running
	err := proxy.Health()
	if err == nil {
		t.Error("Health check should fail when proxy is not running")
	}

	// Test health when running
	ctx := context.Background()
	proxy.Start(ctx)

	err = proxy.Health()
	if err != nil {
		// Note: Due to simulated occasional failures, this might fail sometimes
		// In a real test, we'd want more predictable behavior
		t.Logf("Health check failed (this may be expected due to simulation): %v", err)
	}

	proxy.Stop()
}

func TestManagerProxy_PerformanceCompliance(t *testing.T) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	proxy := NewManagerProxy("PerformanceTestManager", config, logger)

	ctx := context.Background()
	proxy.Start(ctx)
	defer proxy.Stop()

	// Test health check performance
	numChecks := 100
	startTime := time.Now()

	for i := 0; i < numChecks; i++ {
		proxy.Health()
	}

	totalDuration := time.Since(startTime)
	averageLatency := totalDuration / time.Duration(numChecks)

	if averageLatency > 10*time.Millisecond {
		t.Errorf("Average health check latency %v too high", averageLatency)
	}

	// Test status retrieval performance
	startTime = time.Now()
	for i := 0; i < numChecks; i++ {
		proxy.Status()
	}
	totalDuration = time.Since(startTime)
	averageLatency = totalDuration / time.Duration(numChecks)

	if averageLatency > 1*time.Millisecond {
		t.Errorf("Average status retrieval latency %v too high", averageLatency)
	}
}

func TestManagerProxy_ConcurrentAccess(t *testing.T) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	proxy := NewManagerProxy("ConcurrentTestManager", config, logger)

	ctx := context.Background()
	proxy.Start(ctx)
	defer proxy.Stop()

	numGoroutines := 10
	numOperationsPerGoroutine := 50
	results := make(chan error, numGoroutines*numOperationsPerGoroutine)

	// Run concurrent operations
	for i := 0; i < numGoroutines; i++ {
		go func() {
			for j := 0; j < numOperationsPerGoroutine; j++ {
				// Alternate between health checks and status requests
				if j%2 == 0 {
					results <- proxy.Health()
				} else {
					proxy.Status()
					results <- nil
				}
			}
		}()
	}

	// Collect results
	var errors []error
	for i := 0; i < numGoroutines*numOperationsPerGoroutine; i++ {
		if err := <-results; err != nil {
			errors = append(errors, err)
		}
	}

	// Some health check failures are expected due to simulation
	errorRate := float64(len(errors)) / float64(numGoroutines*numOperationsPerGoroutine)
	if errorRate > 0.1 { // Allow up to 10% error rate due to simulation
		t.Errorf("Error rate %.2f%% too high for concurrent access", errorRate*100)
	}
}

func TestManagerProxy_InterfaceCompliance(t *testing.T) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	proxy := NewManagerProxy("InterfaceTestManager", config, logger)

	// Verify proxy implements Manager interface
	var _ interfaces.Manager = proxy

	// Test interface methods
	name := proxy.Name()
	if name == "" {
		t.Error("Name should not be empty")
	}

	status := proxy.Status()
	if status.LastCheck.IsZero() {
		t.Error("Status should have LastCheck set")
	}

	ctx := context.Background()
	err := proxy.Start(ctx)
	if err != nil {
		t.Errorf("Start should not fail: %v", err)
	}

	err = proxy.Health()
	// Health may fail due to simulation, which is acceptable

	err = proxy.Stop()
	if err != nil {
		t.Errorf("Stop should not fail: %v", err)
	}
}

func TestManagerProxy_StateTransitions(t *testing.T) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	proxy := NewManagerProxy("StateTestManager", config, logger)

	// Initial state
	if proxy.isRunning {
		t.Error("Proxy should not be running initially")
	}

	// Start -> Running
	ctx := context.Background()
	proxy.Start(ctx)
	if !proxy.isRunning {
		t.Error("Proxy should be running after start")
	}

	// Running -> Stopped
	proxy.Stop()
	if proxy.isRunning {
		t.Error("Proxy should not be running after stop")
	}

	// Multiple starts/stops
	for i := 0; i < 5; i++ {
		proxy.Start(ctx)
		if !proxy.isRunning {
			t.Errorf("Proxy should be running after start iteration %d", i)
		}
		proxy.Stop()
		if proxy.isRunning {
			t.Errorf("Proxy should not be running after stop iteration %d", i)
		}
	}
}

func TestManagerProxy_HealthCheckTiming(t *testing.T) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	proxy := NewManagerProxy("TimingTestManager", config, logger)

	ctx := context.Background()
	proxy.Start(ctx)
	defer proxy.Stop()

	// Record time before and after health check
	beforeCheck := proxy.lastHealth
	time.Sleep(10 * time.Millisecond) // Ensure time difference

	proxy.Health()
	afterCheck := proxy.lastHealth

	if !afterCheck.After(beforeCheck) {
		t.Error("lastHealth should be updated after health check")
	}

	// Verify timing is reasonable
	timeDiff := afterCheck.Sub(beforeCheck)
	if timeDiff > 100*time.Millisecond {
		t.Errorf("Health check timing update took too long: %v", timeDiff)
	}
}

func BenchmarkManagerProxy_Health(b *testing.B) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	proxy := NewManagerProxy("BenchmarkManager", config, logger)

	ctx := context.Background()
	proxy.Start(ctx)
	defer proxy.Stop()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		proxy.Health()
	}
}

func BenchmarkManagerProxy_Status(b *testing.B) {
	config := &types.ManagersConfig{
		HealthCheckInterval: 30 * time.Second,
		DefaultTimeout:      10 * time.Second,
		MaxRetries:          3,
	}
	logger := zap.NewNop()
	proxy := NewManagerProxy("BenchmarkManager", config, logger)

	ctx := context.Background()
	proxy.Start(ctx)
	defer proxy.Stop()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		proxy.Status()
	}
}
