package bridge

import (
	"context"
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// CallbackEvent represents different types of callback events
type CallbackEvent string

const (
	WorkflowStarted   CallbackEvent = "workflow_started"
	WorkflowProgress  CallbackEvent = "workflow_progress"
	WorkflowCompleted CallbackEvent = "workflow_completed"
	WorkflowFailed    CallbackEvent = "workflow_failed"
)

// CallbackPayload represents the structure of callback data
type CallbackPayload struct {
	WorkflowID  string                 `json:"workflow_id"`
	ExecutionID string                 `json:"execution_id"`
	Event       CallbackEvent          `json:"event"`
	Timestamp   time.Time              `json:"timestamp"`
	Data        map[string]interface{} `json:"data,omitempty"`
	Error       string                 `json:"error,omitempty"`
	Progress    int                    `json:"progress,omitempty"`
	TraceID     string                 `json:"trace_id"`
}

// CallbackHandler manages webhook callbacks using Observer pattern
type CallbackHandler struct {
	logger        *zap.Logger
	observers     map[string][]Observer
	mu            sync.RWMutex
	eventBus      EventBus
	statusTracker StatusTracker
	timeouts      map[string]time.Time
	timeoutMu     sync.RWMutex
}

// Observer interface for callback handling
type Observer interface {
	OnCallback(payload CallbackPayload) error
}

// CallbackObserver implements Observer interface
type CallbackObserver struct {
	ID      string
	Handler func(CallbackPayload) error
	Filter  CallbackEvent
}

func (o *CallbackObserver) OnCallback(payload CallbackPayload) error {
	if o.Filter != "" && o.Filter != payload.Event {
		return nil // Skip if filter doesn't match
	}
	return o.Handler(payload)
}

// NewCallbackHandler creates a new callback handler
func NewCallbackHandler(logger *zap.Logger, eventBus EventBus, statusTracker StatusTracker) *CallbackHandler {
	return &CallbackHandler{
		logger:        logger,
		observers:     make(map[string][]Observer),
		eventBus:      eventBus,
		statusTracker: statusTracker,
		timeouts:      make(map[string]time.Time),
	}
}

// RegisterObserver adds an observer for a specific workflow
func (h *CallbackHandler) RegisterObserver(workflowID string, observer Observer) {
	h.mu.Lock()
	defer h.mu.Unlock()

	h.observers[workflowID] = append(h.observers[workflowID], observer)
	h.logger.Info("Observer registered",
		zap.String("workflow_id", workflowID),
		zap.String("observer_type", fmt.Sprintf("%T", observer)))
}

// UnregisterObserver removes an observer for a workflow
func (h *CallbackHandler) UnregisterObserver(workflowID string, observer Observer) {
	h.mu.Lock()
	defer h.mu.Unlock()

	observers := h.observers[workflowID]
	for i, obs := range observers {
		if obs == observer {
			h.observers[workflowID] = append(observers[:i], observers[i+1:]...)
			break
		}
	}

	if len(h.observers[workflowID]) == 0 {
		delete(h.observers, workflowID)
	}
}

// HandleCallback processes incoming webhook callbacks
func (h *CallbackHandler) HandleCallback(c *gin.Context) {
	workflowID := c.Param("workflow_id")
	if workflowID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "workflow_id is required"})
		return
	}

	var payload CallbackPayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		h.logger.Error("Failed to bind callback payload",
			zap.String("workflow_id", workflowID),
			zap.Error(err))
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid payload format"})
		return
	}

	// Validate payload
	if payload.WorkflowID == "" {
		payload.WorkflowID = workflowID
	}
	if payload.Timestamp.IsZero() {
		payload.Timestamp = time.Now()
	}
	if payload.TraceID == "" {
		payload.TraceID = uuid.New().String()
	}

	// Process callback asynchronously
	go h.processCallback(payload)

	c.JSON(http.StatusOK, gin.H{
		"status":      "accepted",
		"workflow_id": workflowID,
		"trace_id":    payload.TraceID,
	})
}

// processCallback handles the callback processing logic
func (h *CallbackHandler) processCallback(payload CallbackPayload) {
	ctx := context.Background()

	// Log the callback
	h.logger.Info("Processing callback",
		zap.String("workflow_id", payload.WorkflowID),
		zap.String("event", string(payload.Event)),
		zap.String("trace_id", payload.TraceID))

	// Update status tracker
	statusUpdate := StatusUpdate{
		WorkflowID:  payload.WorkflowID,
		ExecutionID: payload.ExecutionID,
		Status:      string(payload.Event),
		LastUpdate:  payload.Timestamp,
		Progress:    payload.Progress,
		Data:        payload.Data,
	}

	if payload.Error != "" {
		statusUpdate.Error = &payload.Error
	}

	h.statusTracker.UpdateStatus(payload.WorkflowID, statusUpdate)

	// Publish to event bus
	event := Event{
		Type:      string(payload.Event),
		Timestamp: payload.Timestamp,
		TraceID:   payload.TraceID,
		Data: map[string]interface{}{
			"workflow_id":  payload.WorkflowID,
			"execution_id": payload.ExecutionID,
			"data":         payload.Data,
			"error":        payload.Error,
			"progress":     payload.Progress,
		},
	}

	h.eventBus.Publish(ctx, event)

	// Notify observers
	h.notifyObservers(payload)

	// Handle timeouts and cleanup
	h.handleTimeout(payload)
}

// notifyObservers sends callback to all registered observers
func (h *CallbackHandler) notifyObservers(payload CallbackPayload) {
	h.mu.RLock()
	observers := h.observers[payload.WorkflowID]
	h.mu.RUnlock()

	if len(observers) == 0 {
		h.logger.Debug("No observers registered for workflow",
			zap.String("workflow_id", payload.WorkflowID))
		return
	}

	// Notify all observers concurrently
	var wg sync.WaitGroup
	for _, observer := range observers {
		wg.Add(1)
		go func(obs Observer) {
			defer wg.Done()
			if err := obs.OnCallback(payload); err != nil {
				h.logger.Error("Observer callback failed",
					zap.String("workflow_id", payload.WorkflowID),
					zap.String("observer_type", fmt.Sprintf("%T", obs)),
					zap.Error(err))
			}
		}(observer)
	}
	wg.Wait()
}

// handleTimeout manages workflow timeouts and cleanup
func (h *CallbackHandler) handleTimeout(payload CallbackPayload) {
	h.timeoutMu.Lock()
	defer h.timeoutMu.Unlock()

	switch payload.Event {
	case WorkflowStarted:
		// Set timeout for workflow
		h.timeouts[payload.WorkflowID] = time.Now().Add(30 * time.Minute)
	case WorkflowCompleted, WorkflowFailed:
		// Remove timeout and cleanup
		delete(h.timeouts, payload.WorkflowID)
		h.cleanupWorkflow(payload.WorkflowID)
	}
}

// cleanupWorkflow removes all observers and status for completed workflows
func (h *CallbackHandler) cleanupWorkflow(workflowID string) {
	h.mu.Lock()
	delete(h.observers, workflowID)
	h.mu.Unlock()

	h.logger.Info("Cleaned up workflow resources",
		zap.String("workflow_id", workflowID))
}

// GetCallbackURL returns the callback URL for a workflow
func (h *CallbackHandler) GetCallbackURL(baseURL, workflowID string) string {
	return fmt.Sprintf("%s/api/v1/callbacks/%s", baseURL, workflowID)
}

// RegisterRoutes registers callback routes with Gin router
func (h *CallbackHandler) RegisterRoutes(router *gin.Engine) {
	api := router.Group("/api/v1")
	{
		api.POST("/callbacks/:workflow_id", h.HandleCallback)
		api.GET("/callbacks/:workflow_id/status", h.GetCallbackStatus)
	}
}

// GetCallbackStatus returns the callback status for a workflow
func (h *CallbackHandler) GetCallbackStatus(c *gin.Context) {
	workflowID := c.Param("workflow_id")

	h.mu.RLock()
	observerCount := len(h.observers[workflowID])
	h.mu.RUnlock()

	h.timeoutMu.RLock()
	timeout, hasTimeout := h.timeouts[workflowID]
	h.timeoutMu.RUnlock()

	status := gin.H{
		"workflow_id":    workflowID,
		"observer_count": observerCount,
		"has_timeout":    hasTimeout,
	}

	if hasTimeout {
		status["timeout_at"] = timeout
		status["time_remaining"] = time.Until(timeout).String()
	}

	c.JSON(http.StatusOK, status)
}

// StartTimeoutMonitor starts a goroutine to monitor and handle timeouts
func (h *CallbackHandler) StartTimeoutMonitor(ctx context.Context) {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			h.checkTimeouts()
		}
	}
}

// checkTimeouts checks for expired workflows and cleans them up
func (h *CallbackHandler) checkTimeouts() {
	h.timeoutMu.Lock()
	defer h.timeoutMu.Unlock()

	now := time.Now()
	for workflowID, timeout := range h.timeouts {
		if now.After(timeout) {
			h.logger.Warn("Workflow timed out",
				zap.String("workflow_id", workflowID),
				zap.Time("timeout", timeout))

			// Send timeout event
			payload := CallbackPayload{
				WorkflowID: workflowID,
				Event:      WorkflowFailed,
				Timestamp:  now,
				Error:      "Workflow timeout",
				TraceID:    uuid.New().String(),
			}

			go h.processCallback(payload)
			delete(h.timeouts, workflowID)
		}
	}
}
