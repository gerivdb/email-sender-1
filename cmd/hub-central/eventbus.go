package main

import (
	"context"
	"fmt"
	"math/rand"
	"sync"
	"time"

	"go.uber.org/zap"
)

// EventType represents the type of event
type EventType string

const (
	EventManagerStarted EventType = "manager_started"
	EventManagerStopped EventType = "manager_stopped"
	EventManagerError   EventType = "manager_error"
	EventConfigChanged  EventType = "config_changed"
	EventHealthCheck    EventType = "health_check"
	EventMetricsUpdate  EventType = "metrics_update"
	EventSystemAlert    EventType = "system_alert"
	EventUserAction     EventType = "user_action"
)

// Event represents a single event in the system
type Event struct {
	Type      EventType              `json:"type"`
	Source    string                 `json:"source"`
	Target    string                 `json:"target,omitempty"`
	Payload   map[string]interface{} `json:"payload"`
	Timestamp time.Time              `json:"timestamp"`
	ID        string                 `json:"id"`
}

// Subscriber represents a function that handles events
type Subscriber func(event Event) error

// EventBus manages event publishing and subscription
type EventBus struct {
	subscribers map[EventType][]Subscriber
	eventQueue  chan Event
	workers     []*EventWorker
	logger      *zap.Logger
	mu          sync.RWMutex
	running     bool
	ctx         context.Context
	cancel      context.CancelFunc
	stats       *EventBusStats
}

// EventWorker processes events from the queue
type EventWorker struct {
	id       int
	eventBus *EventBus
	logger   *zap.Logger
}

// EventBusStats tracks event bus statistics
type EventBusStats struct {
	EventsProcessed int64             `json:"events_processed"`
	EventsQueued    int64             `json:"events_queued"`
	SubscriberCount map[EventType]int `json:"subscriber_count"`
	AverageLatency  time.Duration     `json:"average_latency"`
	ErrorCount      int64             `json:"error_count"`
	LastEventTime   time.Time         `json:"last_event_time"`
	mu              sync.RWMutex
}

// NewEventBus creates a new event bus instance
func NewEventBus(logger *zap.Logger) *EventBus {
	ctx, cancel := context.WithCancel(context.Background())

	return &EventBus{
		subscribers: make(map[EventType][]Subscriber),
		eventQueue:  make(chan Event, 1000), // Buffer for 1000 events
		logger:      logger,
		ctx:         ctx,
		cancel:      cancel,
		stats: &EventBusStats{
			SubscriberCount: make(map[EventType]int),
		},
	}
}

// Start initializes and starts the event bus
func (eb *EventBus) Start(ctx context.Context) error {
	eb.mu.Lock()
	defer eb.mu.Unlock()

	if eb.running {
		return nil
	}

	eb.logger.Info("Starting Event Bus")

	// Start worker goroutines
	workerCount := 4
	eb.workers = make([]*EventWorker, workerCount)

	for i := 0; i < workerCount; i++ {
		worker := &EventWorker{
			id:       i,
			eventBus: eb,
			logger:   eb.logger.With(zap.Int("worker_id", i)),
		}
		eb.workers[i] = worker
		go worker.start(eb.ctx)
	}

	eb.running = true
	eb.logger.Info("Event Bus started successfully", zap.Int("workers", workerCount))

	return nil
}

// Stop gracefully shuts down the event bus
func (eb *EventBus) Stop(ctx context.Context) error {
	eb.mu.Lock()
	defer eb.mu.Unlock()

	if !eb.running {
		return nil
	}

	eb.logger.Info("Stopping Event Bus")

	eb.cancel()
	close(eb.eventQueue)
	eb.running = false

	eb.logger.Info("Event Bus stopped successfully")
	return nil
}

// Publish sends an event to all subscribers
func (eb *EventBus) Publish(event Event) error {
	if !eb.running {
		return nil // Silently ignore events when not running
	}

	// Add timestamp and ID if not set
	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}
	if event.ID == "" {
		event.ID = generateEventID()
	}

	select {
	case eb.eventQueue <- event:
		eb.stats.mu.Lock()
		eb.stats.EventsQueued++
		eb.stats.mu.Unlock()
		return nil
	case <-eb.ctx.Done():
		return eb.ctx.Err()
	default:
		// Queue is full, log warning but don't block
		eb.logger.Warn("Event queue is full, dropping event",
			zap.String("event_type", string(event.Type)),
			zap.String("source", event.Source))
		return nil
	}
}

// Subscribe registers a subscriber for a specific event type
func (eb *EventBus) Subscribe(eventType EventType, subscriber Subscriber) {
	eb.mu.Lock()
	defer eb.mu.Unlock()

	eb.subscribers[eventType] = append(eb.subscribers[eventType], subscriber)

	eb.stats.mu.Lock()
	eb.stats.SubscriberCount[eventType]++
	eb.stats.mu.Unlock()

	eb.logger.Info("New subscriber registered",
		zap.String("event_type", string(eventType)),
		zap.Int("total_subscribers", len(eb.subscribers[eventType])))
}

// Health returns the health status of the event bus
func (eb *EventBus) Health() HealthStatus {
	eb.stats.mu.RLock()
	defer eb.stats.mu.RUnlock()

	status := "healthy"
	message := "Event bus is operating normally"

	if !eb.running {
		status = "unhealthy"
		message = "Event bus is not running"
	} else if eb.stats.ErrorCount > 100 {
		status = "degraded"
		message = "High error count detected"
	}

	return HealthStatus{
		Status:    status,
		Message:   message,
		Timestamp: time.Now(),
		Details: map[string]interface{}{
			"events_processed": eb.stats.EventsProcessed,
			"events_queued":    eb.stats.EventsQueued,
			"error_count":      eb.stats.ErrorCount,
			"worker_count":     len(eb.workers),
		},
	}
}

// GetStats returns current event bus statistics
func (eb *EventBus) GetStats() map[string]interface{} {
	eb.stats.mu.RLock()
	defer eb.stats.mu.RUnlock()

	return map[string]interface{}{
		"events_processed":   eb.stats.EventsProcessed,
		"events_queued":      eb.stats.EventsQueued,
		"subscriber_count":   eb.stats.SubscriberCount,
		"average_latency_ms": eb.stats.AverageLatency.Milliseconds(),
		"error_count":        eb.stats.ErrorCount,
		"last_event_time":    eb.stats.LastEventTime,
		"queue_capacity":     cap(eb.eventQueue),
		"queue_length":       len(eb.eventQueue),
	}
}

// EventWorker methods

// start begins processing events for this worker
func (w *EventWorker) start(ctx context.Context) {
	w.logger.Info("Event worker started")

	for {
		select {
		case event, ok := <-w.eventBus.eventQueue:
			if !ok {
				w.logger.Info("Event worker stopping - queue closed")
				return
			}
			w.processEvent(event)
		case <-ctx.Done():
			w.logger.Info("Event worker stopping - context cancelled")
			return
		}
	}
}

// processEvent handles a single event
func (w *EventWorker) processEvent(event Event) {
	start := time.Now()

	w.eventBus.mu.RLock()
	subscribers := w.eventBus.subscribers[event.Type]
	w.eventBus.mu.RUnlock()

	if len(subscribers) == 0 {
		// No subscribers for this event type
		return
	}

	w.logger.Debug("Processing event",
		zap.String("event_type", string(event.Type)),
		zap.String("source", event.Source),
		zap.Int("subscriber_count", len(subscribers)))

	for _, subscriber := range subscribers {
		if err := subscriber(event); err != nil {
			w.logger.Error("Subscriber error",
				zap.String("event_type", string(event.Type)),
				zap.Error(err))

			w.eventBus.stats.mu.Lock()
			w.eventBus.stats.ErrorCount++
			w.eventBus.stats.mu.Unlock()
		}
	}

	// Update statistics
	duration := time.Since(start)
	w.eventBus.stats.mu.Lock()
	w.eventBus.stats.EventsProcessed++
	w.eventBus.stats.LastEventTime = time.Now()

	// Calculate rolling average latency
	if w.eventBus.stats.AverageLatency == 0 {
		w.eventBus.stats.AverageLatency = duration
	} else {
		w.eventBus.stats.AverageLatency = (w.eventBus.stats.AverageLatency + duration) / 2
	}
	w.eventBus.stats.mu.Unlock()
}

// Helper function to generate unique event IDs
func generateEventID() string {
	return fmt.Sprintf("%d-%d", time.Now().UnixNano(), rand.Int63())
}
