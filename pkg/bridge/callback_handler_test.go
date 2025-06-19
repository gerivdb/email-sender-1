package bridge

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

// Mock implementations for testing
type mockEventBus struct {
	events []Event
	mu     sync.Mutex
}

func (m *mockEventBus) Publish(ctx context.Context, event Event) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.events = append(m.events, event)
	return nil
}

func (m *mockEventBus) Subscribe(eventType string, handler EventHandler) error {
	return nil
}

func (m *mockEventBus) Unsubscribe(eventType string, handler EventHandler) error {
	return nil
}

func (m *mockEventBus) Close() error {
	return nil
}

func (m *mockEventBus) GetEvents() []Event {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]Event{}, m.events...)
}

type mockStatusTracker struct {
	statuses map[string]StatusUpdate
	mu       sync.RWMutex
}

func newMockStatusTracker() *mockStatusTracker {
	return &mockStatusTracker{
		statuses: make(map[string]StatusUpdate),
	}
}

func (m *mockStatusTracker) UpdateStatus(workflowID string, update StatusUpdate) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.statuses[workflowID] = update
	return nil
}

func (m *mockStatusTracker) GetStatus(workflowID string) (*WorkflowStatus, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	if update, exists := m.statuses[workflowID]; exists {
		status := &WorkflowStatus{
			WorkflowID:  update.WorkflowID,
			ExecutionID: update.ExecutionID,
			Status:      update.Status,
			LastUpdate:  update.LastUpdate,
			Progress:    update.Progress,
			Error:       update.Error,
			Data:        update.Data,
		}
		return status, true
	}
	return nil, false
}

func (m *mockStatusTracker) GetAllStatuses() map[string]*WorkflowStatus {
	return nil
}

func (m *mockStatusTracker) DeleteStatus(workflowID string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.statuses, workflowID)
	return nil
}

func (m *mockStatusTracker) GetExpiredStatuses(olderThan time.Duration) []string {
	return nil
}

func (m *mockStatusTracker) CleanupExpiredStatuses(olderThan time.Duration) int {
	return 0
}

func (m *mockStatusTracker) GetStatusCount() int {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return len(m.statuses)
}

func TestCallbackHandler_HandleCallback(t *testing.T) {
	logger := zap.NewNop()
	eventBus := &mockEventBus{}
	statusTracker := newMockStatusTracker()
	handler := NewCallbackHandler(logger, eventBus, statusTracker)

	gin.SetMode(gin.TestMode)
	router := gin.New()
	handler.RegisterRoutes(router)

	payload := CallbackPayload{
		WorkflowID:  "test-workflow-1",
		ExecutionID: "exec-1",
		Event:       WorkflowStarted,
		Progress:    25,
	}

	jsonPayload, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "/api/v1/callbacks/test-workflow-1", bytes.NewBuffer(jsonPayload))
	req.Header.Set("Content-Type", "application/json")

	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, req)

	assert.Equal(t, http.StatusOK, recorder.Code)

	var response map[string]interface{}
	err := json.Unmarshal(recorder.Body.Bytes(), &response)
	require.NoError(t, err)

	assert.Equal(t, "accepted", response["status"])
	assert.Equal(t, "test-workflow-1", response["workflow_id"])
	assert.NotEmpty(t, response["trace_id"])

	// Wait a bit for async processing
	time.Sleep(100 * time.Millisecond)

	// Check that event was published
	events := eventBus.GetEvents()
	assert.Len(t, events, 1)
	assert.Equal(t, "workflow_started", events[0].Type)

	// Check that status was updated
	status, exists := statusTracker.GetStatus("test-workflow-1")
	require.True(t, exists)
	assert.Equal(t, "workflow_started", status.Status)
	assert.Equal(t, 25, status.Progress)
}

func TestCallbackHandler_ObserverPattern(t *testing.T) {
	logger := zap.NewNop()
	eventBus := &mockEventBus{}
	statusTracker := newMockStatusTracker()
	handler := NewCallbackHandler(logger, eventBus, statusTracker)

	var receivedPayloads []CallbackPayload
	var mu sync.Mutex

	observer := &CallbackObserver{
		ID: "test-observer",
		Handler: func(payload CallbackPayload) error {
			mu.Lock()
			defer mu.Unlock()
			receivedPayloads = append(receivedPayloads, payload)
			return nil
		},
		Filter: WorkflowStarted,
	}

	handler.RegisterObserver("test-workflow", observer)

	// Send callback
	payload := CallbackPayload{
		WorkflowID: "test-workflow",
		Event:      WorkflowStarted,
	}

	handler.processCallback(payload)

	// Wait for async processing
	time.Sleep(100 * time.Millisecond)

	mu.Lock()
	defer mu.Unlock()
	assert.Len(t, receivedPayloads, 1)
	assert.Equal(t, WorkflowStarted, receivedPayloads[0].Event)
}

func TestCallbackHandler_ConcurrencyStressTest(t *testing.T) {
	logger := zap.NewNop()
	eventBus := &mockEventBus{}
	statusTracker := newMockStatusTracker()
	handler := NewCallbackHandler(logger, eventBus, statusTracker)

	gin.SetMode(gin.TestMode)
	router := gin.New()
	handler.RegisterRoutes(router)

	const (
		numWorkers   = 50
		numCallbacks = 100
	)

	var wg sync.WaitGroup
	responses := make(chan int, numWorkers*numCallbacks)

	// Stress test with concurrent requests
	for i := 0; i < numWorkers; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			for j := 0; j < numCallbacks; j++ {
				payload := CallbackPayload{
					WorkflowID:  fmt.Sprintf("workflow-%d-%d", workerID, j),
					ExecutionID: fmt.Sprintf("exec-%d-%d", workerID, j),
					Event:       WorkflowStarted,
					Progress:    j % 100,
				}

				jsonPayload, _ := json.Marshal(payload)
				req, _ := http.NewRequest("POST", fmt.Sprintf("/api/v1/callbacks/workflow-%d-%d", workerID, j), bytes.NewBuffer(jsonPayload))
				req.Header.Set("Content-Type", "application/json")

				recorder := httptest.NewRecorder()
				router.ServeHTTP(recorder, req)
				responses <- recorder.Code
			}
		}(i)
	}

	wg.Wait()
	close(responses)

	// Verify all responses were successful
	successCount := 0
	for code := range responses {
		if code == http.StatusOK {
			successCount++
		}
	}

	expectedTotal := numWorkers * numCallbacks
	assert.Equal(t, expectedTotal, successCount, "All callbacks should be successful")

	// Wait for async processing to complete
	time.Sleep(2 * time.Second)

	// Verify events were published
	events := eventBus.GetEvents()
	assert.Equal(t, expectedTotal, len(events), "All events should be published")

	// Verify status updates
	assert.Equal(t, expectedTotal, statusTracker.GetStatusCount(), "All statuses should be updated")
}

func TestCallbackHandler_TimeoutHandling(t *testing.T) {
	logger := zap.NewNop()
	eventBus := &mockEventBus{}
	statusTracker := newMockStatusTracker()
	handler := NewCallbackHandler(logger, eventBus, statusTracker)

	// Start workflow
	startPayload := CallbackPayload{
		WorkflowID: "timeout-test",
		Event:      WorkflowStarted,
		Timestamp:  time.Now(),
	}

	handler.processCallback(startPayload)

	// Check timeout was set
	handler.timeoutMu.RLock()
	_, hasTimeout := handler.timeouts["timeout-test"]
	handler.timeoutMu.RUnlock()
	assert.True(t, hasTimeout, "Timeout should be set for started workflow")

	// Complete workflow
	completePayload := CallbackPayload{
		WorkflowID: "timeout-test",
		Event:      WorkflowCompleted,
		Timestamp:  time.Now(),
	}

	handler.processCallback(completePayload)

	// Check timeout was removed
	handler.timeoutMu.RLock()
	_, hasTimeout = handler.timeouts["timeout-test"]
	handler.timeoutMu.RUnlock()
	assert.False(t, hasTimeout, "Timeout should be removed for completed workflow")
}

func TestCallbackHandler_ErrorHandling(t *testing.T) {
	logger := zap.NewNop()
	eventBus := &mockEventBus{}
	statusTracker := newMockStatusTracker()
	handler := NewCallbackHandler(logger, eventBus, statusTracker)

	gin.SetMode(gin.TestMode)
	router := gin.New()
	handler.RegisterRoutes(router)

	// Test invalid JSON
	req, _ := http.NewRequest("POST", "/api/v1/callbacks/test-workflow", bytes.NewBuffer([]byte("invalid json")))
	req.Header.Set("Content-Type", "application/json")

	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, req)

	assert.Equal(t, http.StatusBadRequest, recorder.Code)

	// Test missing workflow ID
	req, _ = http.NewRequest("POST", "/api/v1/callbacks/", bytes.NewBuffer([]byte("{}")))
	req.Header.Set("Content-Type", "application/json")

	recorder = httptest.NewRecorder()
	router.ServeHTTP(recorder, req)

	assert.Equal(t, http.StatusNotFound, recorder.Code)
}

func TestCallbackHandler_PerformanceBenchmark(t *testing.T) {
	logger := zap.NewNop()
	eventBus := &mockEventBus{}
	statusTracker := newMockStatusTracker()
	handler := NewCallbackHandler(logger, eventBus, statusTracker)

	gin.SetMode(gin.TestMode)
	router := gin.New()
	handler.RegisterRoutes(router)

	payload := CallbackPayload{
		WorkflowID:  "perf-test",
		ExecutionID: "exec-1",
		Event:       WorkflowProgress,
		Progress:    50,
	}

	jsonPayload, _ := json.Marshal(payload)

	// Measure performance
	start := time.Now()
	const numRequests = 1000

	for i := 0; i < numRequests; i++ {
		req, _ := http.NewRequest("POST", "/api/v1/callbacks/perf-test", bytes.NewBuffer(jsonPayload))
		req.Header.Set("Content-Type", "application/json")

		recorder := httptest.NewRecorder()
		router.ServeHTTP(recorder, req)

		assert.Equal(t, http.StatusOK, recorder.Code)
	}

	duration := time.Since(start)
	requestsPerSecond := float64(numRequests) / duration.Seconds()

	t.Logf("Performance: %d requests in %v (%.2f req/sec)", numRequests, duration, requestsPerSecond)

	// Should handle at least 500 requests per second
	assert.Greater(t, requestsPerSecond, 500.0, "Should handle at least 500 requests per second")
}

func TestCallbackHandler_GetCallbackStatus(t *testing.T) {
	logger := zap.NewNop()
	eventBus := &mockEventBus{}
	statusTracker := newMockStatusTracker()
	handler := NewCallbackHandler(logger, eventBus, statusTracker)

	gin.SetMode(gin.TestMode)
	router := gin.New()
	handler.RegisterRoutes(router)

	// Add timeout for testing
	handler.timeoutMu.Lock()
	handler.timeouts["test-workflow"] = time.Now().Add(5 * time.Minute)
	handler.timeoutMu.Unlock()

	req, _ := http.NewRequest("GET", "/api/v1/callbacks/test-workflow/status", nil)
	recorder := httptest.NewRecorder()
	router.ServeHTTP(recorder, req)

	assert.Equal(t, http.StatusOK, recorder.Code)

	var response map[string]interface{}
	err := json.Unmarshal(recorder.Body.Bytes(), &response)
	require.NoError(t, err)

	assert.Equal(t, "test-workflow", response["workflow_id"])
	assert.Equal(t, float64(0), response["observer_count"])
	assert.Equal(t, true, response["has_timeout"])
	assert.NotNil(t, response["timeout_at"])
	assert.NotNil(t, response["time_remaining"])
}

func BenchmarkCallbackHandler_HandleCallback(b *testing.B) {
	logger := zap.NewNop()
	eventBus := &mockEventBus{}
	statusTracker := newMockStatusTracker()
	handler := NewCallbackHandler(logger, eventBus, statusTracker)

	gin.SetMode(gin.TestMode)
	router := gin.New()
	handler.RegisterRoutes(router)

	payload := CallbackPayload{
		WorkflowID:  "bench-test",
		ExecutionID: "exec-1",
		Event:       WorkflowProgress,
		Progress:    75,
	}

	jsonPayload, _ := json.Marshal(payload)

	b.ResetTimer()
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			req, _ := http.NewRequest("POST", "/api/v1/callbacks/bench-test", bytes.NewBuffer(jsonPayload))
			req.Header.Set("Content-Type", "application/json")

			recorder := httptest.NewRecorder()
			router.ServeHTTP(recorder, req)

			if recorder.Code != http.StatusOK {
				b.Fatalf("Expected status 200, got %d", recorder.Code)
			}
		}
	})
}
