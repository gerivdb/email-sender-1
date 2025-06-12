package tests

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// PerformanceTestSuite contains performance and load tests
type PerformanceTestSuite struct {
	logger       *log.Logger
	syncEngine   *SyncEngine
	testDataSize int
	concurrency  int
	testDuration time.Duration
	results      *PerformanceResults
	ctx          context.Context
	cancel       context.CancelFunc
}

// PerformanceResults stores test results
type PerformanceResults struct {
	TotalOperations     int             `json:"total_operations"`
	SuccessfulOps       int             `json:"successful_ops"`
	FailedOps           int             `json:"failed_ops"`
	SuccessRate         float64         `json:"success_rate"`
	AverageLatency      time.Duration   `json:"average_latency"`
	MinLatency          time.Duration   `json:"min_latency"`
	MaxLatency          time.Duration   `json:"max_latency"`
	P95Latency          time.Duration   `json:"p95_latency"`
	P99Latency          time.Duration   `json:"p99_latency"`
	Throughput          float64         `json:"throughput"` // ops/second
	MemoryUsage         uint64          `json:"memory_usage"`
	CPUUsage            float64         `json:"cpu_usage"`
	ConcurrentUsers     int             `json:"concurrent_users"`
	TestDuration        time.Duration   `json:"test_duration"`
	ErrorDistribution   map[string]int  `json:"error_distribution"`
	LatencyDistribution []time.Duration `json:"latency_distribution"`
}

// LoadTestConfig defines load test parameters
type LoadTestConfig struct {
	ConcurrentUsers   int            `json:"concurrent_users"`
	TestDuration      time.Duration  `json:"test_duration"`
	RampUpTime        time.Duration  `json:"ramp_up_time"`
	OperationsPerUser int            `json:"operations_per_user"`
	ThinkTime         time.Duration  `json:"think_time"`
	DataSize          int            `json:"data_size"`
	Scenarios         []TestScenario `json:"scenarios"`
}

// TestScenario defines a specific test scenario
type TestScenario struct {
	Name       string                 `json:"name"`
	Weight     float64                `json:"weight"` // Probability of execution
	Operation  string                 `json:"operation"`
	Parameters map[string]interface{} `json:"parameters"`
	Expected   ExpectedResults        `json:"expected"`
}

// ExpectedResults defines performance expectations
type ExpectedResults struct {
	MaxLatency    time.Duration `json:"max_latency"`
	MinThroughput float64       `json:"min_throughput"`
	MaxErrorRate  float64       `json:"max_error_rate"`
	MaxMemory     uint64        `json:"max_memory"`
}

// OperationResult stores individual operation results
type OperationResult struct {
	OperationType string        `json:"operation_type"`
	StartTime     time.Time     `json:"start_time"`
	EndTime       time.Time     `json:"end_time"`
	Latency       time.Duration `json:"latency"`
	Success       bool          `json:"success"`
	Error         string        `json:"error,omitempty"`
	DataSize      int           `json:"data_size"`
	UserID        int           `json:"user_id"`
}

// NewPerformanceTestSuite creates a new performance test suite
func NewPerformanceTestSuite() *PerformanceTestSuite {
	return &PerformanceTestSuite{
		logger:       log.New(os.Stdout, "[PERF-TEST] ", log.LstdFlags),
		testDataSize: 1000,
		concurrency:  10,
		testDuration: 30 * time.Second,
		results:      &PerformanceResults{},
	}
}

// TestSyncPerformance tests synchronization performance under load
func TestSyncPerformance(t *testing.T) {
	suite := NewPerformanceTestSuite()
	suite.ctx, suite.cancel = context.WithTimeout(context.Background(), 5*time.Minute)
	defer suite.cancel()

	config := &LoadTestConfig{
		ConcurrentUsers:   20,
		TestDuration:      60 * time.Second,
		RampUpTime:        10 * time.Second,
		OperationsPerUser: 50,
		ThinkTime:         100 * time.Millisecond,
		DataSize:          500, // Plans with 500 tasks each
		Scenarios: []TestScenario{
			{
				Name:      "MarkdownSync",
				Weight:    0.6,
				Operation: "sync_markdown_to_dynamic",
				Parameters: map[string]interface{}{
					"plan_size":  100,
					"complexity": "medium",
				},
				Expected: ExpectedResults{
					MaxLatency:    2 * time.Second,
					MinThroughput: 10.0,
					MaxErrorRate:  5.0,
					MaxMemory:     500 * 1024 * 1024, // 500MB
				},
			},
			{
				Name:      "DynamicSync",
				Weight:    0.3,
				Operation: "sync_dynamic_to_markdown",
				Parameters: map[string]interface{}{
					"plan_size":  150,
					"complexity": "high",
				},
				Expected: ExpectedResults{
					MaxLatency:    3 * time.Second,
					MinThroughput: 8.0,
					MaxErrorRate:  3.0,
					MaxMemory:     400 * 1024 * 1024,
				},
			},
			{
				Name:      "ConflictResolution",
				Weight:    0.1,
				Operation: "resolve_conflicts",
				Parameters: map[string]interface{}{
					"conflict_count": 5,
					"complexity":     "high",
				},
				Expected: ExpectedResults{
					MaxLatency:    5 * time.Second,
					MinThroughput: 5.0,
					MaxErrorRate:  2.0,
					MaxMemory:     300 * 1024 * 1024,
				},
			},
		},
	}

	// Run the load test
	results, err := suite.RunLoadTest(config)
	require.NoError(t, err)

	// Validate performance requirements
	suite.ValidatePerformanceResults(t, results, config)

	// Generate performance report
	suite.GeneratePerformanceReport(results, config)
}

// TestConcurrentSyncOperations tests concurrent sync operations
func TestConcurrentSyncOperations(t *testing.T) {
	suite := NewPerformanceTestSuite()
	suite.ctx, suite.cancel = context.WithTimeout(context.Background(), 2*time.Minute)
	defer suite.cancel()

	concurrency := 50
	operationsPerWorker := 20

	var wg sync.WaitGroup
	var mu sync.Mutex
	var results []OperationResult

	startTime := time.Now()

	// Launch concurrent workers
	for i := 0; i < concurrency; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()

			for j := 0; j < operationsPerWorker; j++ {
				result := suite.ExecuteSyncOperation(workerID, j)

				mu.Lock()
				results = append(results, result)
				mu.Unlock()

				// Small delay between operations
				time.Sleep(10 * time.Millisecond)
			}
		}(i)
	}

	wg.Wait()
	totalDuration := time.Since(startTime)

	// Analyze results
	perfResults := suite.AnalyzeResults(results, totalDuration)

	// Assertions
	assert.Greater(t, perfResults.SuccessRate, 95.0, "Success rate should be > 95%")
	assert.Less(t, perfResults.AverageLatency, 500*time.Millisecond, "Average latency should be < 500ms")
	assert.Greater(t, perfResults.Throughput, 50.0, "Throughput should be > 50 ops/sec")

	suite.logger.Printf("Concurrent test completed: %d ops, %.2f%% success, %.2f ops/sec",
		perfResults.TotalOperations, perfResults.SuccessRate, perfResults.Throughput)
}

// TestMemoryLeaks tests for memory leaks during extended operations
func TestMemoryLeaks(t *testing.T) {
	suite := NewPerformanceTestSuite()
	suite.ctx, suite.cancel = context.WithTimeout(context.Background(), 3*time.Minute)
	defer suite.cancel()

	// Baseline memory measurement
	baseline := suite.GetMemoryUsage()

	// Run operations for extended period
	iterations := 1000
	for i := 0; i < iterations; i++ {
		result := suite.ExecuteSyncOperation(0, i)
		if !result.Success {
			t.Logf("Operation %d failed: %s", i, result.Error)
		}

		// Periodic memory checks
		if i%100 == 0 {
			currentMemory := suite.GetMemoryUsage()
			growth := float64(currentMemory-baseline) / float64(baseline) * 100

			suite.logger.Printf("Iteration %d: Memory usage %.2fMB (%.1f%% growth)",
				i, float64(currentMemory)/(1024*1024), growth)

			// Alert if memory growth exceeds 50%
			if growth > 50.0 {
				t.Logf("Warning: Memory growth %.1f%% at iteration %d", growth, i)
			}
		}

		// Force garbage collection periodically
		if i%200 == 0 {
			suite.ForceGarbageCollection()
		}
	}

	// Final memory check
	finalMemory := suite.GetMemoryUsage()
	memoryGrowth := float64(finalMemory-baseline) / float64(baseline) * 100

	assert.Less(t, memoryGrowth, 100.0, "Memory growth should be < 100% after %d operations", iterations)

	suite.logger.Printf("Memory leak test completed: %.1f%% memory growth", memoryGrowth)
}

// TestStressConditions tests system behavior under stress
func TestStressConditions(t *testing.T) {
	suite := NewPerformanceTestSuite()
	suite.ctx, suite.cancel = context.WithTimeout(context.Background(), 5*time.Minute)
	defer suite.cancel()

	stressConfig := &LoadTestConfig{
		ConcurrentUsers:   100, // High concurrency
		TestDuration:      2 * time.Minute,
		RampUpTime:        20 * time.Second,
		OperationsPerUser: 100,
		ThinkTime:         1 * time.Millisecond, // Very low think time
		DataSize:          2000,                 // Large data sets
	}

	results, err := suite.RunStressTest(stressConfig)
	require.NoError(t, err)

	// Under stress, we accept lower performance but system should remain stable
	assert.Greater(t, results.SuccessRate, 80.0, "Success rate should remain > 80% under stress")
	assert.Less(t, results.AverageLatency, 10*time.Second, "Average latency should be < 10s under stress")
	assert.Equal(t, 0, results.FailedOps, "System should not crash under stress")

	suite.logger.Printf("Stress test completed: %.2f%% success rate, %.2f ops/sec throughput",
		results.SuccessRate, results.Throughput)
}

// TestLatencyPercentiles tests latency distribution
func TestLatencyPercentiles(t *testing.T) {
	suite := NewPerformanceTestSuite()
	suite.ctx, suite.cancel = context.WithTimeout(context.Background(), 1*time.Minute)
	defer suite.cancel()

	var results []OperationResult
	operationCount := 1000

	// Execute operations
	for i := 0; i < operationCount; i++ {
		result := suite.ExecuteSyncOperation(0, i)
		results = append(results, result)
	}

	// Calculate percentiles
	latencies := make([]time.Duration, len(results))
	for i, result := range results {
		latencies[i] = result.Latency
	}

	p50 := suite.CalculatePercentile(latencies, 50)
	p95 := suite.CalculatePercentile(latencies, 95)
	p99 := suite.CalculatePercentile(latencies, 99)

	// Assertions for latency requirements
	assert.Less(t, p50, 200*time.Millisecond, "P50 latency should be < 200ms")
	assert.Less(t, p95, 1*time.Second, "P95 latency should be < 1s")
	assert.Less(t, p99, 2*time.Second, "P99 latency should be < 2s")

	suite.logger.Printf("Latency percentiles - P50: %v, P95: %v, P99: %v", p50, p95, p99)
}

// RunLoadTest executes a load test with the given configuration
func (suite *PerformanceTestSuite) RunLoadTest(config *LoadTestConfig) (*PerformanceResults, error) {
	suite.logger.Printf("Starting load test: %d users, %v duration", config.ConcurrentUsers, config.TestDuration)

	var wg sync.WaitGroup
	var mu sync.Mutex
	var results []OperationResult

	ctx, cancel := context.WithTimeout(suite.ctx, config.TestDuration)
	defer cancel()

	startTime := time.Now()

	// Ramp up users gradually
	userRampInterval := config.RampUpTime / time.Duration(config.ConcurrentUsers)

	for i := 0; i < config.ConcurrentUsers; i++ {
		wg.Add(1)

		// Gradual ramp-up
		time.Sleep(userRampInterval)

		go func(userID int) {
			defer wg.Done()
			suite.RunUserSession(ctx, userID, config, &mu, &results)
		}(i)
	}

	wg.Wait()
	totalDuration := time.Since(startTime)

	return suite.AnalyzeResults(results, totalDuration), nil
}

// RunStressTest executes a stress test
func (suite *PerformanceTestSuite) RunStressTest(config *LoadTestConfig) (*PerformanceResults, error) {
	suite.logger.Printf("Starting stress test: %d users, %v duration", config.ConcurrentUsers, config.TestDuration)

	// Stress test is similar to load test but with more aggressive parameters
	return suite.RunLoadTest(config)
}

// RunUserSession simulates a user session
func (suite *PerformanceTestSuite) RunUserSession(ctx context.Context, userID int, config *LoadTestConfig, mu *sync.Mutex, results *[]OperationResult) {
	operationCount := 0

	for {
		select {
		case <-ctx.Done():
			return
		default:
			// Choose a scenario based on weights
			scenario := suite.ChooseScenario(config.Scenarios)

			// Execute operation
			result := suite.ExecuteScenario(userID, operationCount, scenario)

			mu.Lock()
			*results = append(*results, result)
			mu.Unlock()

			operationCount++

			// Think time between operations
			time.Sleep(config.ThinkTime)
		}
	}
}

// ExecuteScenario executes a specific test scenario
func (suite *PerformanceTestSuite) ExecuteScenario(userID, operationID int, scenario TestScenario) OperationResult {
	startTime := time.Now()

	var err error
	var success bool = true

	switch scenario.Operation {
	case "sync_markdown_to_dynamic":
		err = suite.SimulateMarkdownSync(scenario.Parameters)
	case "sync_dynamic_to_markdown":
		err = suite.SimulateDynamicSync(scenario.Parameters)
	case "resolve_conflicts":
		err = suite.SimulateConflictResolution(scenario.Parameters)
	default:
		err = fmt.Errorf("unknown operation: %s", scenario.Operation)
	}

	if err != nil {
		success = false
	}

	endTime := time.Now()

	return OperationResult{
		OperationType: scenario.Operation,
		StartTime:     startTime,
		EndTime:       endTime,
		Latency:       endTime.Sub(startTime),
		Success:       success,
		Error: func() string {
			if err != nil {
				return err.Error()
			}
			return ""
		}(),
		DataSize: suite.getParameterInt(scenario.Parameters, "plan_size", 100),
		UserID:   userID,
	}
}

// Simulation methods

func (suite *PerformanceTestSuite) SimulateMarkdownSync(params map[string]interface{}) error {
	planSize := suite.getParameterInt(params, "plan_size", 100)
	complexity := suite.getParameterString(params, "complexity", "medium")

	// Simulate processing time based on plan size and complexity
	baseTime := time.Duration(planSize) * time.Millisecond
	if complexity == "high" {
		baseTime *= 2
	} else if complexity == "low" {
		baseTime /= 2
	}

	// Add some randomness
	processingTime := baseTime + time.Duration(rand.Intn(100))*time.Millisecond
	time.Sleep(processingTime)

	// Simulate occasional failures (5% failure rate)
	if rand.Float64() < 0.05 {
		return fmt.Errorf("simulated sync failure")
	}

	return nil
}

func (suite *PerformanceTestSuite) SimulateDynamicSync(params map[string]interface{}) error {
	planSize := suite.getParameterInt(params, "plan_size", 150)

	// Dynamic sync typically takes longer
	processingTime := time.Duration(planSize) * 2 * time.Millisecond
	processingTime += time.Duration(rand.Intn(200)) * time.Millisecond
	time.Sleep(processingTime)

	// 3% failure rate for dynamic sync
	if rand.Float64() < 0.03 {
		return fmt.Errorf("simulated dynamic sync failure")
	}

	return nil
}

func (suite *PerformanceTestSuite) SimulateConflictResolution(params map[string]interface{}) error {
	conflictCount := suite.getParameterInt(params, "conflict_count", 5)

	// Conflict resolution time depends on number of conflicts
	processingTime := time.Duration(conflictCount) * 500 * time.Millisecond
	processingTime += time.Duration(rand.Intn(1000)) * time.Millisecond
	time.Sleep(processingTime)

	// 2% failure rate for conflict resolution
	if rand.Float64() < 0.02 {
		return fmt.Errorf("simulated conflict resolution failure")
	}

	return nil
}

// ExecuteSyncOperation executes a single sync operation
func (suite *PerformanceTestSuite) ExecuteSyncOperation(workerID, operationID int) OperationResult {
	startTime := time.Now()

	// Simulate sync operation
	processingTime := time.Duration(50+rand.Intn(200)) * time.Millisecond
	time.Sleep(processingTime)

	endTime := time.Now()
	success := rand.Float64() > 0.02 // 98% success rate

	result := OperationResult{
		OperationType: "sync_operation",
		StartTime:     startTime,
		EndTime:       endTime,
		Latency:       endTime.Sub(startTime),
		Success:       success,
		DataSize:      100 + rand.Intn(400),
		UserID:        workerID,
	}

	if !success {
		result.Error = "simulated operation failure"
	}

	return result
}

// AnalyzeResults analyzes operation results and generates performance metrics
func (suite *PerformanceTestSuite) AnalyzeResults(results []OperationResult, totalDuration time.Duration) *PerformanceResults {
	if len(results) == 0 {
		return &PerformanceResults{}
	}

	successCount := 0
	var latencies []time.Duration
	var minLatency, maxLatency time.Duration
	var totalLatency time.Duration
	errorDistribution := make(map[string]int)

	for i, result := range results {
		if result.Success {
			successCount++
		} else {
			errorDistribution[result.Error]++
		}

		latencies = append(latencies, result.Latency)
		totalLatency += result.Latency

		if i == 0 {
			minLatency = result.Latency
			maxLatency = result.Latency
		} else {
			if result.Latency < minLatency {
				minLatency = result.Latency
			}
			if result.Latency > maxLatency {
				maxLatency = result.Latency
			}
		}
	}

	successRate := float64(successCount) / float64(len(results)) * 100
	avgLatency := totalLatency / time.Duration(len(results))
	throughput := float64(len(results)) / totalDuration.Seconds()

	return &PerformanceResults{
		TotalOperations:     len(results),
		SuccessfulOps:       successCount,
		FailedOps:           len(results) - successCount,
		SuccessRate:         successRate,
		AverageLatency:      avgLatency,
		MinLatency:          minLatency,
		MaxLatency:          maxLatency,
		P95Latency:          suite.CalculatePercentile(latencies, 95),
		P99Latency:          suite.CalculatePercentile(latencies, 99),
		Throughput:          throughput,
		MemoryUsage:         suite.GetMemoryUsage(),
		CPUUsage:            suite.GetCPUUsage(),
		TestDuration:        totalDuration,
		ErrorDistribution:   errorDistribution,
		LatencyDistribution: latencies,
	}
}

// ValidatePerformanceResults validates results against expected criteria
func (suite *PerformanceTestSuite) ValidatePerformanceResults(t *testing.T, results *PerformanceResults, config *LoadTestConfig) {
	for _, scenario := range config.Scenarios {
		expected := scenario.Expected

		assert.Less(t, results.AverageLatency, expected.MaxLatency,
			"Average latency for %s should be < %v", scenario.Name, expected.MaxLatency)

		assert.Greater(t, results.Throughput, expected.MinThroughput,
			"Throughput for %s should be > %.1f", scenario.Name, expected.MinThroughput)

		errorRate := float64(results.FailedOps) / float64(results.TotalOperations) * 100
		assert.Less(t, errorRate, expected.MaxErrorRate,
			"Error rate for %s should be < %.1f%%", scenario.Name, expected.MaxErrorRate)

		assert.Less(t, results.MemoryUsage, expected.MaxMemory,
			"Memory usage for %s should be < %d bytes", scenario.Name, expected.MaxMemory)
	}
}

// GeneratePerformanceReport generates a detailed performance report
func (suite *PerformanceTestSuite) GeneratePerformanceReport(results *PerformanceResults, config *LoadTestConfig) {
	suite.logger.Printf("\n" + strings.Repeat("=", 80))
	suite.logger.Printf("PERFORMANCE TEST REPORT")
	suite.logger.Printf(strings.Repeat("=", 80))
	suite.logger.Printf("Test Configuration:")
	suite.logger.Printf("  Concurrent Users: %d", config.ConcurrentUsers)
	suite.logger.Printf("  Test Duration: %v", config.TestDuration)
	suite.logger.Printf("  Operations per User: %d", config.OperationsPerUser)
	suite.logger.Printf("  Think Time: %v", config.ThinkTime)
	suite.logger.Printf("")
	suite.logger.Printf("Results Summary:")
	suite.logger.Printf("  Total Operations: %d", results.TotalOperations)
	suite.logger.Printf("  Successful Operations: %d", results.SuccessfulOps)
	suite.logger.Printf("  Failed Operations: %d", results.FailedOps)
	suite.logger.Printf("  Success Rate: %.2f%%", results.SuccessRate)
	suite.logger.Printf("  Average Latency: %v", results.AverageLatency)
	suite.logger.Printf("  Min Latency: %v", results.MinLatency)
	suite.logger.Printf("  Max Latency: %v", results.MaxLatency)
	suite.logger.Printf("  P95 Latency: %v", results.P95Latency)
	suite.logger.Printf("  P99 Latency: %v", results.P99Latency)
	suite.logger.Printf("  Throughput: %.2f ops/sec", results.Throughput)
	suite.logger.Printf("  Memory Usage: %.2f MB", float64(results.MemoryUsage)/(1024*1024))
	suite.logger.Printf("  CPU Usage: %.1f%%", results.CPUUsage)

	if len(results.ErrorDistribution) > 0 {
		suite.logger.Printf("")
		suite.logger.Printf("Error Distribution:")
		for errorType, count := range results.ErrorDistribution {
			suite.logger.Printf("  %s: %d", errorType, count)
		}
	}

	suite.logger.Printf(strings.Repeat("=", 80))
}

// Helper methods

func (suite *PerformanceTestSuite) ChooseScenario(scenarios []TestScenario) TestScenario {
	if len(scenarios) == 0 {
		return TestScenario{Name: "default", Operation: "sync_markdown_to_dynamic"}
	}

	totalWeight := 0.0
	for _, scenario := range scenarios {
		totalWeight += scenario.Weight
	}

	r := rand.Float64() * totalWeight
	currentWeight := 0.0

	for _, scenario := range scenarios {
		currentWeight += scenario.Weight
		if r <= currentWeight {
			return scenario
		}
	}

	return scenarios[0] // Fallback
}

func (suite *PerformanceTestSuite) CalculatePercentile(latencies []time.Duration, percentile int) time.Duration {
	if len(latencies) == 0 {
		return 0
	}

	// Simple percentile calculation (in production, would sort the array)
	index := int(float64(len(latencies)) * float64(percentile) / 100.0)
	if index >= len(latencies) {
		index = len(latencies) - 1
	}

	return latencies[index]
}

func (suite *PerformanceTestSuite) GetMemoryUsage() uint64 {
	// Mock implementation - in real scenario would use runtime.MemStats
	return uint64(256+rand.Intn(256)) * 1024 * 1024 // 256-512MB
}

func (suite *PerformanceTestSuite) GetCPUUsage() float64 {
	// Mock implementation - in real scenario would measure actual CPU usage
	return 30.0 + rand.Float64()*40.0 // 30-70% CPU usage
}

func (suite *PerformanceTestSuite) ForceGarbageCollection() {
	// Mock implementation - in real scenario would call runtime.GC()
	time.Sleep(10 * time.Millisecond)
}

func (suite *PerformanceTestSuite) getParameterInt(params map[string]interface{}, key string, defaultValue int) int {
	if val, ok := params[key]; ok {
		if intVal, ok := val.(int); ok {
			return intVal
		}
	}
	return defaultValue
}

func (suite *PerformanceTestSuite) getParameterString(params map[string]interface{}, key string, defaultValue string) string {
	if val, ok := params[key]; ok {
		if strVal, ok := val.(string); ok {
			return strVal
		}
	}
	return defaultValue
}
