package integration

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/sirupsen/logrus"
)

// EventBus handles inter-manager communication and events
type EventBus struct {
	subscribers    map[string][]EventHandler
	eventQueue     chan *Event
	workers        int
	workerPool     []chan *Event
	mutex          sync.RWMutex
	logger         *logrus.Logger
	shutdownCh     chan struct{}
	eventHistory   []*Event
	maxHistory     int
	metrics        *EventMetrics
}

// EventMetrics tracks event bus performance
type EventMetrics struct {
	TotalEvents     int64                      `json:"total_events"`
	ProcessedEvents int64                      `json:"processed_events"`
	FailedEvents    int64                      `json:"failed_events"`
	AverageLatency  time.Duration              `json:"average_latency"`
	EventTypes      map[string]int64           `json:"event_types"`
	SubscriberCount map[string]int             `json:"subscriber_count"`
	LastProcessed   time.Time                  `json:"last_processed"`
}

// NewEventBus creates a new event bus
func NewEventBus(logger *logrus.Logger) *EventBus {
	return &EventBus{
		subscribers:  make(map[string][]EventHandler),
		eventQueue:   make(chan *Event, 1000), // Buffered channel for events
		workers:      5,                       // Number of worker goroutines
		workerPool:   make([]chan *Event, 5),
		logger:       logger,
		shutdownCh:   make(chan struct{}),
		eventHistory: make([]*Event, 0),
		maxHistory:   1000,
		metrics: &EventMetrics{
			EventTypes:      make(map[string]int64),
			SubscriberCount: make(map[string]int),
		},
	}
}

// Initialize initializes the event bus
func (eb *EventBus) Initialize() error {
	eb.logger.Info("Initializing EventBus...")

	// Initialize worker pool
	for i := 0; i < eb.workers; i++ {
		eb.workerPool[i] = make(chan *Event, 100)
		go eb.worker(i, eb.workerPool[i])
	}

	// Start event dispatcher
	go eb.dispatcher()

	// Start metrics collection
	go eb.startMetricsCollection()

	eb.logger.WithField("workers", eb.workers).Info("EventBus initialized successfully")
	return nil
}

// Subscribe subscribes to specific event types
func (eb *EventBus) Subscribe(eventType string, handler EventHandler) {
	eb.mutex.Lock()
	defer eb.mutex.Unlock()

	if eb.subscribers[eventType] == nil {
		eb.subscribers[eventType] = make([]EventHandler, 0)
	}

	eb.subscribers[eventType] = append(eb.subscribers[eventType], handler)
	eb.metrics.SubscriberCount[eventType] = len(eb.subscribers[eventType])

	eb.logger.WithFields(logrus.Fields{
		"event_type":  eventType,
		"subscribers": len(eb.subscribers[eventType]),
	}).Debug("New event subscription added")
}

// Unsubscribe removes a handler from event type (simplified implementation)
func (eb *EventBus) Unsubscribe(eventType string, handler EventHandler) {
	eb.mutex.Lock()
	defer eb.mutex.Unlock()

	if handlers, exists := eb.subscribers[eventType]; exists {
		// Note: This is a simplified implementation
		// In a real scenario, you'd need to compare function pointers or use registration IDs
		if len(handlers) > 0 {
			eb.subscribers[eventType] = handlers[:len(handlers)-1]
			eb.metrics.SubscriberCount[eventType] = len(eb.subscribers[eventType])
		}
	}
}

// Publish publishes an event to the bus
func (eb *EventBus) Publish(event *Event) error {
	if event == nil {
		return fmt.Errorf("event cannot be nil")
	}

	// Validate event
	if err := eb.validateEvent(event); err != nil {
		return fmt.Errorf("invalid event: %w", err)
	}

	// Set timestamp if not set
	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}

	// Generate ID if not set
	if event.ID == "" {
		event.ID = fmt.Sprintf("%s_%s_%d", event.Type, event.Source, event.Timestamp.Unix())
	}

	select {
	case eb.eventQueue <- event:
		eb.metrics.TotalEvents++
		eb.metrics.EventTypes[event.Type]++
		
		eb.logger.WithFields(logrus.Fields{
			"event_id":   event.ID,
			"event_type": event.Type,
			"source":     event.Source,
			"target":     event.Target,
		}).Debug("Event published")
		
		return nil
	default:
		eb.metrics.FailedEvents++
		return fmt.Errorf("event queue is full")
	}
}

// PublishSync publishes an event synchronously and waits for processing
func (eb *EventBus) PublishSync(ctx context.Context, event *Event) error {
	if err := eb.Publish(event); err != nil {
		return err
	}

	// Wait for event to be processed (simplified implementation)
	// In a real scenario, you'd implement proper synchronization
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-time.After(5 * time.Second): // Timeout
		return fmt.Errorf("event processing timeout")
	}
}

// GetEventHistory returns recent event history
func (eb *EventBus) GetEventHistory(limit int) []*Event {
	eb.mutex.RLock()
	defer eb.mutex.RUnlock()

	if limit <= 0 || limit > len(eb.eventHistory) {
		limit = len(eb.eventHistory)
	}

	// Return the most recent events
	start := len(eb.eventHistory) - limit
	if start < 0 {
		start = 0
	}

	history := make([]*Event, limit)
	copy(history, eb.eventHistory[start:])
	return history
}

// GetMetrics returns event bus metrics
func (eb *EventBus) GetMetrics() *EventMetrics {
	eb.mutex.RLock()
	defer eb.mutex.RUnlock()

	// Create a copy to avoid race conditions
	metrics := &EventMetrics{
		TotalEvents:     eb.metrics.TotalEvents,
		ProcessedEvents: eb.metrics.ProcessedEvents,
		FailedEvents:    eb.metrics.FailedEvents,
		AverageLatency:  eb.metrics.AverageLatency,
		LastProcessed:   eb.metrics.LastProcessed,
		EventTypes:      make(map[string]int64),
		SubscriberCount: make(map[string]int),
	}

	for k, v := range eb.metrics.EventTypes {
		metrics.EventTypes[k] = v
	}

	for k, v := range eb.metrics.SubscriberCount {
		metrics.SubscriberCount[k] = v
	}

	return metrics
}

// Shutdown gracefully shuts down the event bus
func (eb *EventBus) Shutdown() error {
	eb.logger.Info("Shutting down EventBus...")

	// Signal shutdown
	close(eb.shutdownCh)

	// Close event queue
	close(eb.eventQueue)

	// Close worker channels
	for _, workerCh := range eb.workerPool {
		close(workerCh)
	}

	eb.logger.Info("EventBus shutdown completed")
	return nil
}

// Private methods

// dispatcher distributes events to workers
func (eb *EventBus) dispatcher() {
	workerIndex := 0

	for {
		select {
		case event, ok := <-eb.eventQueue:
			if !ok {
				return // Queue closed
			}

			// Add to history
			eb.addToHistory(event)

			// Distribute to worker in round-robin fashion
			select {
			case eb.workerPool[workerIndex] <- event:
				workerIndex = (workerIndex + 1) % eb.workers
			default:
				// Worker queue full, log warning
				eb.logger.Warn("Worker queue full, dropping event", "event_id", event.ID)
				eb.metrics.FailedEvents++
			}

		case <-eb.shutdownCh:
			return
		}
	}
}

// worker processes events from the worker queue
func (eb *EventBus) worker(id int, eventCh chan *Event) {
	eb.logger.WithField("worker_id", id).Debug("Event worker started")

	for {
		select {
		case event, ok := <-eventCh:
			if !ok {
				eb.logger.WithField("worker_id", id).Debug("Event worker stopped")
				return
			}

			eb.processEvent(event)

		case <-eb.shutdownCh:
			eb.logger.WithField("worker_id", id).Debug("Event worker shutdown")
			return
		}
	}
}

// processEvent processes a single event
func (eb *EventBus) processEvent(event *Event) {
	startTime := time.Now()

	eb.logger.WithFields(logrus.Fields{
		"event_id":   event.ID,
		"event_type": event.Type,
		"source":     event.Source,
	}).Debug("Processing event")

	// Get subscribers for this event type
	eb.mutex.RLock()
	handlers := make([]EventHandler, len(eb.subscribers[event.Type]))
	copy(handlers, eb.subscribers[event.Type])
	
	// Also get wildcard subscribers (*)
	wildcardHandlers := make([]EventHandler, len(eb.subscribers["*"]))
	copy(wildcardHandlers, eb.subscribers["*"])
	eb.mutex.RUnlock()

	// Process all handlers
	allHandlers := append(handlers, wildcardHandlers...)
	processedCount := 0
	errorCount := 0

	for _, handler := range allHandlers {
		if err := handler(event); err != nil {
			eb.logger.WithFields(logrus.Fields{
				"event_id": event.ID,
				"error":    err,
			}).Warn("Event handler failed")
			errorCount++
		} else {
			processedCount++
		}
	}

	// Update metrics
	duration := time.Since(startTime)
	eb.updateProcessingMetrics(duration, processedCount, errorCount)

	eb.logger.WithFields(logrus.Fields{
		"event_id":        event.ID,
		"handlers":        len(allHandlers),
		"processed":       processedCount,
		"errors":          errorCount,
		"duration":        duration,
	}).Debug("Event processed")
}

// validateEvent validates an event before publishing
func (eb *EventBus) validateEvent(event *Event) error {
	if event.Type == "" {
		return fmt.Errorf("event type is required")
	}

	if event.Source == "" {
		return fmt.Errorf("event source is required")
	}

	if event.Data == nil {
		event.Data = make(map[string]interface{})
	}

	return nil
}

// addToHistory adds an event to the history buffer
func (eb *EventBus) addToHistory(event *Event) {
	eb.mutex.Lock()
	defer eb.mutex.Unlock()

	eb.eventHistory = append(eb.eventHistory, event)

	// Maintain history size limit
	if len(eb.eventHistory) > eb.maxHistory {
		// Remove oldest events
		eb.eventHistory = eb.eventHistory[len(eb.eventHistory)-eb.maxHistory:]
	}
}

// updateProcessingMetrics updates processing metrics
func (eb *EventBus) updateProcessingMetrics(duration time.Duration, processed, errors int) {
	eb.mutex.Lock()
	defer eb.mutex.Unlock()

	eb.metrics.ProcessedEvents += int64(processed)
	eb.metrics.FailedEvents += int64(errors)
	eb.metrics.LastProcessed = time.Now()

	// Update average latency
	if eb.metrics.ProcessedEvents > 0 {
		totalDuration := time.Duration(eb.metrics.ProcessedEvents-int64(processed))*eb.metrics.AverageLatency + duration
		eb.metrics.AverageLatency = totalDuration / time.Duration(eb.metrics.ProcessedEvents)
	} else {
		eb.metrics.AverageLatency = duration
	}
}

// startMetricsCollection starts periodic metrics collection
func (eb *EventBus) startMetricsCollection() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			eb.logMetrics()
		case <-eb.shutdownCh:
			return
		}
	}
}

// logMetrics logs current metrics
func (eb *EventBus) logMetrics() {
	metrics := eb.GetMetrics()
	
	eb.logger.WithFields(logrus.Fields{
		"total_events":     metrics.TotalEvents,
		"processed_events": metrics.ProcessedEvents,
		"failed_events":    metrics.FailedEvents,
		"average_latency":  metrics.AverageLatency,
		"event_types":      len(metrics.EventTypes),
		"subscribers":      len(metrics.SubscriberCount),
	}).Info("EventBus metrics")
}

// Built-in event types
const (
	EventTypeManagerRegistered   = "manager_registered"
	EventTypeManagerUnregistered = "manager_unregistered"
	EventTypeOperationStarted    = "operation_started"
	EventTypeOperationCompleted  = "operation_completed"
	EventTypeOperationFailed     = "operation_failed"
	EventTypeHealthCheckFailed   = "health_check_failed"
	EventTypeSystemAlert         = "system_alert"
	EventTypeConfigChanged       = "config_changed"
	EventTypeMaintenanceStarted  = "maintenance_started"
	EventTypeMaintenanceCompleted = "maintenance_completed"
)

// Common event publishers
func (eb *EventBus) PublishManagerRegistered(managerName string, capabilities []string) error {
	return eb.Publish(&Event{
		Type:   EventTypeManagerRegistered,
		Source: "integration_hub",
		Data: map[string]interface{}{
			"manager":      managerName,
			"capabilities": capabilities,
		},
		Priority:  1,
		Timestamp: time.Now(),
	})
}

func (eb *EventBus) PublishOperationStarted(operationID string, operationType string, managers []string) error {
	return eb.Publish(&Event{
		Type:   EventTypeOperationStarted,
		Source: "integration_hub",
		Data: map[string]interface{}{
			"operation_id":   operationID,
			"operation_type": operationType,
			"managers":       managers,
		},
		Priority:  2,
		Timestamp: time.Now(),
	})
}

func (eb *EventBus) PublishOperationCompleted(operationID string, success bool, duration time.Duration) error {
	eventType := EventTypeOperationCompleted
	if !success {
		eventType = EventTypeOperationFailed
	}

	return eb.Publish(&Event{
		Type:   eventType,
		Source: "integration_hub",
		Data: map[string]interface{}{
			"operation_id": operationID,
			"success":      success,
			"duration":     duration,
		},
		Priority:  2,
		Timestamp: time.Now(),
	})
}

func (eb *EventBus) PublishSystemAlert(level string, message string, component string) error {
	return eb.Publish(&Event{
		Type:   EventTypeSystemAlert,
		Source: component,
		Data: map[string]interface{}{
			"level":     level,
			"message":   message,
			"component": component,
		},
		Priority:  3,
		Timestamp: time.Now(),
	})
}
