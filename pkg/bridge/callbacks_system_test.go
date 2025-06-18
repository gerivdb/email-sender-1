package bridge

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Tests pour CallbackHandler

func TestWebhookCallbackHandler_RegisterObserver(t *testing.T) {
	handler := NewWebhookCallbackHandler()

	observer := NewSimpleCallbackObserver("test-observer", func(event CallbackEvent) error {
		return nil
	})

	handler.RegisterObserver(observer)

	// Vérifier que l'observateur est enregistré
	handler.observersMux.RLock()
	_, exists := handler.observers[observer.GetID()]
	handler.observersMux.RUnlock()

	assert.True(t, exists)
}

func TestWebhookCallbackHandler_HandleCallback(t *testing.T) {
	handler := NewWebhookCallbackHandler()
	require.NoError(t, handler.Start())
	defer handler.Stop()

	var receivedEvent CallbackEvent
	observer := NewSimpleCallbackObserver("test-observer", func(event CallbackEvent) error {
		receivedEvent = event
		return nil
	})

	handler.RegisterObserver(observer)

	event := CallbackEvent{
		WorkflowID:  "workflow-123",
		ExecutionID: "exec-456",
		Status:      "completed",
		Data:        map[string]interface{}{"result": "success"},
	}

	err := handler.HandleCallback(context.Background(), event)
	assert.NoError(t, err)

	// Attendre un peu pour que l'événement soit traité
	time.Sleep(100 * time.Millisecond)

	assert.Equal(t, event.WorkflowID, receivedEvent.WorkflowID)
	assert.Equal(t, event.Status, receivedEvent.Status)
}

func TestWebhookCallbackHandler_HTTPEndpoint(t *testing.T) {
	gin.SetMode(gin.TestMode)

	handler := NewWebhookCallbackHandler()
	require.NoError(t, handler.Start())
	defer handler.Stop()

	router := gin.New()
	handler.SetupRoutes(router)

	// Test POST callback
	callbackReq := CallbackRequest{
		WorkflowID:  "workflow-123",
		ExecutionID: "exec-456",
		Status:      "completed",
		Data:        map[string]interface{}{"result": "success"},
	}

	jsonData, _ := json.Marshal(callbackReq)
	req := httptest.NewRequest("POST", "/api/v1/callbacks/workflow-123", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response CallbackResponse
	err := json.Unmarshal(w.Body.Bytes(), &response)
	require.NoError(t, err)
	assert.True(t, response.Success)
}

// Tests pour EventBus

func TestChannelEventBus_PublishSubscribe(t *testing.T) {
	config := EventBusConfig{
		BufferSize: 100,
		UseRedis:   false,
	}

	bus, err := NewChannelEventBus(config)
	require.NoError(t, err)
	require.NoError(t, bus.Start())
	defer bus.Stop()

	var receivedEvent Event
	subscriber := NewSimpleEventSubscriber(
		"test-subscriber",
		[]EventType{WorkflowStarted, WorkflowCompleted},
		func(event Event) error {
			receivedEvent = event
			return nil
		},
	)

	err = bus.Subscribe(subscriber)
	require.NoError(t, err)

	event := Event{
		Type:       WorkflowStarted,
		WorkflowID: "workflow-123",
		Data:       map[string]interface{}{"test": "data"},
		Source:     "test",
	}

	err = bus.Publish(context.Background(), event)
	require.NoError(t, err)

	// Attendre que l'événement soit traité
	time.Sleep(100 * time.Millisecond)

	assert.Equal(t, event.Type, receivedEvent.Type)
	assert.Equal(t, event.WorkflowID, receivedEvent.WorkflowID)
}

func TestChannelEventBus_Stats(t *testing.T) {
	config := EventBusConfig{
		BufferSize: 100,
		UseRedis:   false,
	}

	bus, err := NewChannelEventBus(config)
	require.NoError(t, err)
	require.NoError(t, bus.Start())
	defer bus.Stop()

	subscriber := NewSimpleEventSubscriber(
		"test-subscriber",
		[]EventType{WorkflowStarted},
		func(event Event) error { return nil },
	)

	err = bus.Subscribe(subscriber)
	require.NoError(t, err)

	event := Event{
		Type:       WorkflowStarted,
		WorkflowID: "workflow-123",
	}

	err = bus.Publish(context.Background(), event)
	require.NoError(t, err)

	stats := bus.GetStats()
	assert.Equal(t, int64(1), stats.TotalPublished)
	assert.Equal(t, 1, stats.TotalSubscribers)
}

// Tests pour StatusTracker

func TestMemoryStatusTracker_CreateAndGetStatus(t *testing.T) {
	config := StatusTrackerConfig{
		DefaultTTL: 1 * time.Hour,
	}

	tracker := NewMemoryStatusTracker(config)
	require.NoError(t, tracker.StartCleanup())
	defer tracker.StopCleanup()

	status, err := tracker.CreateStatus("workflow-123", "exec-456")
	require.NoError(t, err)
	assert.Equal(t, "workflow-123", status.WorkflowID)
	assert.Equal(t, "exec-456", status.ExecutionID)
	assert.Equal(t, "started", status.Status)
	assert.Equal(t, 0.0, status.Progress)

	retrievedStatus, err := tracker.GetStatus("workflow-123")
	require.NoError(t, err)
	assert.Equal(t, status.WorkflowID, retrievedStatus.WorkflowID)
	assert.Equal(t, status.ExecutionID, retrievedStatus.ExecutionID)
}

func TestMemoryStatusTracker_UpdateStatus(t *testing.T) {
	config := StatusTrackerConfig{
		DefaultTTL: 1 * time.Hour,
	}

	tracker := NewMemoryStatusTracker(config)
	require.NoError(t, tracker.StartCleanup())
	defer tracker.StopCleanup()

	_, err := tracker.CreateStatus("workflow-123", "exec-456")
	require.NoError(t, err)

	updates := StatusUpdate{
		Status:   stringPtr("running"),
		Progress: float64Ptr(50.0),
		Data:     map[string]interface{}{"step": "processing"},
	}

	err = tracker.UpdateStatus("workflow-123", updates)
	require.NoError(t, err)

	status, err := tracker.GetStatus("workflow-123")
	require.NoError(t, err)
	assert.Equal(t, "running", status.Status)
	assert.Equal(t, 50.0, status.Progress)
	assert.Equal(t, "processing", status.Data["step"])
}

func TestMemoryStatusTracker_HTTPEndpoints(t *testing.T) {
	gin.SetMode(gin.TestMode)
	config := StatusTrackerConfig{
		DefaultTTL: 1 * time.Hour,
	}

	tracker := NewMemoryStatusTracker(config)
	require.NoError(t, tracker.StartCleanup())
	defer tracker.StopCleanup()

	router := gin.New()
	tracker.SetupRoutes(router)

	// Créer un statut
	_, err := tracker.CreateStatus("workflow-123", "exec-456")
	require.NoError(t, err)

	// Test GET status
	req := httptest.NewRequest("GET", "/api/v1/status/workflow-123", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var status WorkflowStatus
	err = json.Unmarshal(w.Body.Bytes(), &status)
	require.NoError(t, err)
	assert.Equal(t, "workflow-123", status.WorkflowID)

	// Test PUT update
	updates := StatusUpdate{
		Status:   stringPtr("completed"),
		Progress: float64Ptr(100.0),
	}

	jsonData, _ := json.Marshal(updates)
	req = httptest.NewRequest("PUT", "/api/v1/status/workflow-123", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")

	w = httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestMemoryStatusTracker_Steps(t *testing.T) {
	config := StatusTrackerConfig{
		DefaultTTL: 1 * time.Hour,
	}

	tracker := NewMemoryStatusTracker(config)
	require.NoError(t, tracker.StartCleanup())
	defer tracker.StopCleanup()

	_, err := tracker.CreateStatus("workflow-123", "exec-456")
	require.NoError(t, err)

	// Ajouter une étape
	step := WorkflowStep{
		StepID:    "step-1",
		Name:      "Initialize",
		Status:    "running",
		StartTime: time.Now(),
	}

	updates := StatusUpdate{
		AddStep: &step,
	}

	err = tracker.UpdateStatus("workflow-123", updates)
	require.NoError(t, err)

	status, err := tracker.GetStatus("workflow-123")
	require.NoError(t, err)
	assert.Len(t, status.Steps, 1)
	assert.Equal(t, "step-1", status.Steps[0].StepID)
	assert.Equal(t, "Initialize", status.Steps[0].Name)
}

// Tests de stress et performance

func TestCallbackHandler_ConcurrentCallbacks(t *testing.T) {
	handler := NewWebhookCallbackHandler()
	require.NoError(t, handler.Start())
	defer handler.Stop()

	var processedCount int64
	observer := NewSimpleCallbackObserver("stress-observer", func(event CallbackEvent) error {
		processedCount++
		return nil
	})

	handler.RegisterObserver(observer)

	// Envoyer 100 callbacks en parallèle
	numCallbacks := 100
	done := make(chan bool, numCallbacks)

	for i := 0; i < numCallbacks; i++ {
		go func(id int) {
			event := CallbackEvent{
				WorkflowID: fmt.Sprintf("workflow-%d", id),
				Status:     "completed",
			}
			handler.HandleCallback(context.Background(), event)
			done <- true
		}(i)
	}

	// Attendre que tous les callbacks soient envoyés
	for i := 0; i < numCallbacks; i++ {
		<-done
	}

	// Attendre le traitement
	time.Sleep(500 * time.Millisecond)

	// Note: processedCount pourrait être moins que numCallbacks
	// à cause du buffering, mais il devrait être > 0
	assert.Greater(t, int(processedCount), 0)
}

func TestEventBus_PerformanceTest(t *testing.T) {
	config := EventBusConfig{
		BufferSize: 1000,
		UseRedis:   false,
	}

	bus, err := NewChannelEventBus(config)
	require.NoError(t, err)
	require.NoError(t, bus.Start())
	defer bus.Stop()

	subscriber := NewSimpleEventSubscriber(
		"perf-subscriber",
		[]EventType{WorkflowStarted},
		func(event Event) error {
			// Simulation d'un traitement léger
			time.Sleep(1 * time.Millisecond)
			return nil
		},
	)

	err = bus.Subscribe(subscriber)
	require.NoError(t, err)

	start := time.Now()
	numEvents := 100

	for i := 0; i < numEvents; i++ {
		event := Event{
			Type:       WorkflowStarted,
			WorkflowID: fmt.Sprintf("workflow-%d", i),
		}
		bus.Publish(context.Background(), event)
	}

	duration := time.Since(start)
	t.Logf("Published %d events in %v", numEvents, duration)

	// Vérifier que la publication est rapide (< 100ms pour 100 événements)
	assert.Less(t, duration, 100*time.Millisecond)
}

// Fonctions utilitaires pour les tests

func stringPtr(s string) *string {
	return &s
}

func float64Ptr(f float64) *float64 {
	return &f
}
