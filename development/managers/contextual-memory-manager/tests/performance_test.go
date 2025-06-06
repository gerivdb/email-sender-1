package tests

import (
	"context"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"../interfaces"
)

// MockPerformanceManager provides minimal implementation for performance testing
type MockPerformanceManager struct {
	operations []string
	mu         sync.RWMutex
}

func (m *MockPerformanceManager) GetID() string {
	return "performance-test-manager"
}

func (m *MockPerformanceManager) Initialize(config map[string]interface{}) error {
	return nil
}

func (m *MockPerformanceManager) Shutdown() error {
	return nil
}

func (m *MockPerformanceManager) GetStatus() interfaces.ManagerStatus {
	return interfaces.ManagerStatus{
		IsHealthy:   true,
		LastError:   "",
		Uptime:      time.Hour,
		ActiveTasks: 0,
	}
}

func (m *MockPerformanceManager) StoreContextualAction(ctx context.Context, action interfaces.ContextualAction) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.operations = append(m.operations, "store")
	// Simulate minimal processing time
	time.Sleep(time.Microsecond * 100) // 0.1ms
	return nil
}

func (m *MockPerformanceManager) RetrieveContextualActions(ctx context.Context, sessionID string, filters interfaces.RetrievalFilters) ([]interfaces.ContextualAction, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	
	// Simulate retrieval time
	time.Sleep(time.Microsecond * 200) // 0.2ms
	
	// Return mock actions
	return []interfaces.ContextualAction{
		{
			ID:        "test-1",
			SessionID: sessionID,
			ActionType: "email",
			Content:   "Test email action",
			Timestamp: time.Now(),
		},
	}, nil
}

func (m *MockPerformanceManager) SearchSimilarActions(ctx context.Context, query string, filters interfaces.SearchFilters) ([]interfaces.ContextualAction, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	
	// Simulate search time
	time.Sleep(time.Microsecond * 300) // 0.3ms
	
	return []interfaces.ContextualAction{
		{
			ID:        "similar-1",
			SessionID: "test-session",
			ActionType: "email",
			Content:   "Similar email action",
			Timestamp: time.Now(),
		},
	}, nil
}

func (m *MockPerformanceManager) GetSessionContext(ctx context.Context, sessionID string) (*interfaces.SessionContext, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	
	// Simulate context retrieval
	time.Sleep(time.Microsecond * 150) // 0.15ms
	
	return &interfaces.SessionContext{
		SessionID:   sessionID,
		UserID:      "test-user",
		StartTime:   time.Now().Add(-time.Hour),
		LastActive:  time.Now(),
		ActionCount: 5,
		Tags:        []string{"test", "performance"},
	}, nil
}

func (m *MockPerformanceManager) UpdateSession(ctx context.Context, sessionID string, updates interfaces.SessionUpdates) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.operations = append(m.operations, "update_session")
	time.Sleep(time.Microsecond * 100) // 0.1ms
	return nil
}

func (m *MockPerformanceManager) GetMetrics(ctx context.Context) (*interfaces.ManagerMetrics, error) {
	return &interfaces.ManagerMetrics{
		RequestCount:    1000,
		AverageLatency:  time.Millisecond * 2,
		ErrorRate:       0.01,
		ActiveSessions:  50,
		CacheHitRate:    0.85,
		Timestamp:       time.Now(),
	}, nil
}

// TestPerformanceStoreAction tests single store operation performance
func TestPerformanceStoreAction(t *testing.T) {
	manager := &MockPerformanceManager{}
	ctx := context.Background()

	action := interfaces.ContextualAction{
		ID:         "perf-test-1",
		SessionID:  "session-1",
		UserID:     "user-1",
		ActionType: "email",
		Content:    "Performance test email",
		Timestamp:  time.Now(),
	}

	start := time.Now()
	err := manager.StoreContextualAction(ctx, action)
	duration := time.Since(start)

	require.NoError(t, err)
	assert.Less(t, duration, time.Millisecond*10, "Store action should complete in under 10ms")
	t.Logf("Store operation took: %v", duration)
}

// TestPerformanceRetrieveActions tests retrieval performance
func TestPerformanceRetrieveActions(t *testing.T) {
	manager := &MockPerformanceManager{}
	ctx := context.Background()

	filters := interfaces.RetrievalFilters{
		Limit:     10,
		ActionTypes: []string{"email"},
	}

	start := time.Now()
	actions, err := manager.RetrieveContextualActions(ctx, "session-1", filters)
	duration := time.Since(start)

	require.NoError(t, err)
	assert.NotEmpty(t, actions)
	assert.Less(t, duration, time.Millisecond*10, "Retrieve actions should complete in under 10ms")
	t.Logf("Retrieval operation took: %v", duration)
}

// TestPerformanceSearchSimilar tests search performance
func TestPerformanceSearchSimilar(t *testing.T) {
	manager := &MockPerformanceManager{}
	ctx := context.Background()

	filters := interfaces.SearchFilters{
		Limit:     5,
		MinScore:  0.8,
	}

	start := time.Now()
	actions, err := manager.SearchSimilarActions(ctx, "test email query", filters)
	duration := time.Since(start)

	require.NoError(t, err)
	assert.NotEmpty(t, actions)
	assert.Less(t, duration, time.Millisecond*10, "Search should complete in under 10ms")
	t.Logf("Search operation took: %v", duration)
}

// TestPerformanceConcurrentOperations tests performance under concurrent load
func TestPerformanceConcurrentOperations(t *testing.T) {
	manager := &MockPerformanceManager{}
	ctx := context.Background()

	const numGoroutines = 100
	const operationsPerGoroutine = 10

	var wg sync.WaitGroup
	results := make(chan time.Duration, numGoroutines*operationsPerGoroutine)

	// Start concurrent operations
	start := time.Now()
	
	for i := 0; i < numGoroutines; i++ {
		wg.Add(1)
		go func(goroutineID int) {
			defer wg.Done()
			
			for j := 0; j < operationsPerGoroutine; j++ {
				opStart := time.Now()
				
				// Perform a mixed workload
				switch j % 3 {
				case 0:
					action := interfaces.ContextualAction{
						ID:         fmt.Sprintf("action-%d-%d", goroutineID, j),
						SessionID:  fmt.Sprintf("session-%d", goroutineID),
						UserID:     fmt.Sprintf("user-%d", goroutineID),
						ActionType: "email",
						Content:    "Concurrent test action",
						Timestamp:  time.Now(),
					}
					manager.StoreContextualAction(ctx, action)
				case 1:
					manager.RetrieveContextualActions(ctx, fmt.Sprintf("session-%d", goroutineID), interfaces.RetrievalFilters{Limit: 10})
				case 2:
					manager.SearchSimilarActions(ctx, "test query", interfaces.SearchFilters{Limit: 5, MinScore: 0.8})
				}
				
				results <- time.Since(opStart)
			}
		}(i)
	}

	wg.Wait()
	totalDuration := time.Since(start)
	close(results)

	// Analyze results
	var totalOps int
	var totalLatency time.Duration
	var maxLatency time.Duration
	var slowOps int

	for duration := range results {
		totalOps++
		totalLatency += duration
		if duration > maxLatency {
			maxLatency = duration
		}
		if duration > time.Millisecond*100 { // Operations taking more than 100ms
			slowOps++
		}
	}

	avgLatency := totalLatency / time.Duration(totalOps)
	throughput := float64(totalOps) / totalDuration.Seconds()

	t.Logf("Concurrent Performance Results:")
	t.Logf("  Total Operations: %d", totalOps)
	t.Logf("  Total Duration: %v", totalDuration)
	t.Logf("  Average Latency: %v", avgLatency)
	t.Logf("  Max Latency: %v", maxLatency)
	t.Logf("  Throughput: %.2f ops/sec", throughput)
	t.Logf("  Operations > 100ms: %d (%.2f%%)", slowOps, float64(slowOps)/float64(totalOps)*100)

	// Performance assertions
	assert.Less(t, avgLatency, time.Millisecond*50, "Average latency should be under 50ms")
	assert.Less(t, maxLatency, time.Millisecond*100, "Max latency should be under 100ms")
	assert.Greater(t, throughput, 100.0, "Should handle at least 100 operations per second")
	assert.Less(t, float64(slowOps)/float64(totalOps), 0.05, "Less than 5% of operations should exceed 100ms")
}

// TestPerformanceSessionOperations tests session-related performance
func TestPerformanceSessionOperations(t *testing.T) {
	manager := &MockPerformanceManager{}
	ctx := context.Background()

	// Test GetSessionContext performance
	start := time.Now()
	sessionContext, err := manager.GetSessionContext(ctx, "test-session")
	duration := time.Since(start)

	require.NoError(t, err)
	assert.NotNil(t, sessionContext)
	assert.Less(t, duration, time.Millisecond*10, "GetSessionContext should complete in under 10ms")
	t.Logf("GetSessionContext took: %v", duration)

	// Test UpdateSession performance
	updates := interfaces.SessionUpdates{
		LastActive: &time.Time{},
		Tags:       []string{"updated", "performance"},
	}

	start = time.Now()
	err = manager.UpdateSession(ctx, "test-session", updates)
	duration = time.Since(start)

	require.NoError(t, err)
	assert.Less(t, duration, time.Millisecond*10, "UpdateSession should complete in under 10ms")
	t.Logf("UpdateSession took: %v", duration)
}

// BenchmarkStoreAction benchmarks the store operation
func BenchmarkStoreAction(b *testing.B) {
	manager := &MockPerformanceManager{}
	ctx := context.Background()

	action := interfaces.ContextualAction{
		ID:         "bench-action",
		SessionID:  "bench-session",
		UserID:     "bench-user",
		ActionType: "email",
		Content:    "Benchmark test action",
		Timestamp:  time.Now(),
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		action.ID = fmt.Sprintf("bench-action-%d", i)
		manager.StoreContextualAction(ctx, action)
	}
}

// BenchmarkRetrieveActions benchmarks the retrieval operation
func BenchmarkRetrieveActions(b *testing.B) {
	manager := &MockPerformanceManager{}
	ctx := context.Background()

	filters := interfaces.RetrievalFilters{
		Limit:     10,
		ActionTypes: []string{"email"},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		manager.RetrieveContextualActions(ctx, fmt.Sprintf("session-%d", i%10), filters)
	}
}

// BenchmarkSearchSimilar benchmarks the search operation
func BenchmarkSearchSimilar(b *testing.B) {
	manager := &MockPerformanceManager{}
	ctx := context.Background()

	filters := interfaces.SearchFilters{
		Limit:     5,
		MinScore:  0.8,
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		manager.SearchSimilarActions(ctx, fmt.Sprintf("query-%d", i), filters)
	}
}
