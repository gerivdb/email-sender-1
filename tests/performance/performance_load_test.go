package performance

import (
	"context"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/gerivdb/email-sender-1/pkg/managers"
	"github.com/gerivdb/email-sender-1/pkg/queue"

	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"
)

// PerformanceTestConfig configuration du test de charge
type PerformanceTestConfig struct {
	NumConcurrentRequests int
	NumTotalRequests      int
	QueueName             string
	JobType               string
	Timeout               time.Duration
}

// PerformanceResult résultats du test de charge
type PerformanceResult struct {
	TotalRequests      int
	SuccessfulRequests int
	FailedRequests     int
	AverageLatency     time.Duration
	MinLatency         time.Duration
	MaxLatency         time.Duration
	Throughput         float64 // req/sec
	Errors             []string
}

// TestPerformanceLoad exécute un test de charge sur le système de queue
func TestPerformanceLoad(t *testing.T) {
	logger := zaptest.NewLogger(t)
	config := &PerformanceTestConfig{
		NumConcurrentRequests: 50,
		NumTotalRequests:      1000,
		QueueName:             "perf-test-queue",
		JobType:               "go-cli",
		Timeout:               10 * time.Second,
	}

	managerConfig := &managers.N8NManagerConfig{
		Name:              "perf-manager",
		Version:           "1.0.0-perf",
		MaxConcurrency:    100,
		DefaultTimeout:    30 * time.Second,
		HeartbeatInterval: 5 * time.Second,
		CLIPath:           "email-sender",
		CLITimeout:        30 * time.Second,
		CLIRetries:        2,
		DefaultQueue:      config.QueueName,
		QueueWorkers:      map[string]int{config.QueueName: 10},
		EnableMetrics:     true,
		EnableTracing:     false,
		LogLevel:          "warn",
		MetricsInterval:   1 * time.Second,
	}

	manager, err := managers.NewSimpleN8NManager(managerConfig, logger)
	require.NoError(t, err)
	err = manager.Start(context.Background())
	require.NoError(t, err)

	queueConfig := &queue.QueueConfig{
		DefaultWorkers:  10,
		MaxWorkers:      100,
		JobTimeout:      10 * time.Second,
		RetryAttempts:   2,
		RetryBackoff:    500 * time.Millisecond,
		QueueCapacity:   2000,
		MetricsInterval: 1 * time.Second,
	}
	queueSystem := queue.NewAsyncQueueSystem(queueConfig, logger)
	err = queueSystem.CreateQueue(config.QueueName, 10)
	require.NoError(t, err)

	var wg sync.WaitGroup
	latencies := make([]time.Duration, config.NumTotalRequests)
	errors := make([]string, 0)
	successCount := 0
	failCount := 0
	mu := sync.Mutex{}

	start := time.Now()
	sem := make(chan struct{}, config.NumConcurrentRequests)

	for i := 0; i < config.NumTotalRequests; i++ {
		wg.Add(1)
		sem <- struct{}{}
		go func(idx int) {
			defer wg.Done()
			job := &queue.Job{
				Type:      config.JobType,
				QueueName: config.QueueName,
				Priority:  queue.PriorityNormal,
				Payload: map[string]interface{}{
					"command": "email-sender",
					"args":    []string{fmt.Sprintf("--recipient=test%d@example.com", idx)},
				},
				MaxRetries:    2,
				TraceID:       fmt.Sprintf("trace-%d", idx),
				CorrelationID: fmt.Sprintf("corr-%d", idx),
			}
			enqueueStart := time.Now()
			err := queueSystem.EnqueueJob(job)
			if err != nil {
				mu.Lock()
				failCount++
				errors = append(errors, fmt.Sprintf("enqueue error: %v", err))
				mu.Unlock()
				<-sem
				return
			}

			// Wait for job completion or timeout
			timeout := time.After(config.Timeout)
			for {
				select {
				case <-timeout:
					mu.Lock()
					failCount++
					errors = append(errors, fmt.Sprintf("timeout for job %s", job.ID))
					mu.Unlock()
					<-sem
					return
				default:
					jobStatus, err := queueSystem.GetJobStatus(job.ID)
					if err == nil && jobStatus.Status == queue.JobStatusCompleted {
						latency := time.Since(enqueueStart)
						mu.Lock()
						latencies[idx] = latency
						successCount++
						mu.Unlock()
						<-sem
						return
					}
					time.Sleep(10 * time.Millisecond)
				}
			}
		}(i)
	}

	wg.Wait()
	totalTime := time.Since(start)

	minLatency := time.Hour
	maxLatency := time.Duration(0)
	sumLatency := time.Duration(0)
	for _, l := range latencies {
		if l == 0 {
			continue
		}
		if l < minLatency {
			minLatency = l
		}
		if l > maxLatency {
			maxLatency = l
		}
		sumLatency += l
	}
	avgLatency := time.Duration(0)
	if successCount > 0 {
		avgLatency = sumLatency / time.Duration(successCount)
	}
	throughput := float64(successCount) / totalTime.Seconds()

	result := &PerformanceResult{
		TotalRequests:      config.NumTotalRequests,
		SuccessfulRequests: successCount,
		FailedRequests:     failCount,
		AverageLatency:     avgLatency,
		MinLatency:         minLatency,
		MaxLatency:         maxLatency,
		Throughput:         throughput,
		Errors:             errors,
	}

	logger.Info("Performance Load Test Results",
		zap.Int("total_requests", result.TotalRequests),
		zap.Int("successful_requests", result.SuccessfulRequests),
		zap.Int("failed_requests", result.FailedRequests),
		zap.Duration("average_latency", result.AverageLatency),
		zap.Duration("min_latency", result.MinLatency),
		zap.Duration("max_latency", result.MaxLatency),
		zap.Float64("throughput", result.Throughput),
		zap.Int("errors_count", len(result.Errors)),
	)

	if float64(result.SuccessfulRequests)/float64(result.TotalRequests) < 0.98 {
		t.Errorf("Success rate too low: %.2f%%", 100*float64(result.SuccessfulRequests)/float64(result.TotalRequests))
	}
	if result.AverageLatency > 2*time.Second {
		t.Errorf("Average latency too high: %v", result.AverageLatency)
	}
}
