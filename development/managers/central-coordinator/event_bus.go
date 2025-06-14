package coordinator

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"
)

// EventBus implémente un système de communication asynchrone entre managers
type EventBus struct {
	mu          sync.RWMutex
	subscribers map[string][]EventHandler
	eventQueue  chan *ManagerEvent
	bufferSize  int
	logger      *zap.Logger
	metrics     EventBusMetrics
	ctx         context.Context
	cancel      context.CancelFunc
}

// EventHandler définit le type de fonction pour gérer les événements
type EventHandler func(ctx context.Context, event *ManagerEvent) error

// ManagerEvent représente un événement du système
type ManagerEvent struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"`
	Source    string                 `json:"source"`
	Target    string                 `json:"target,omitempty"`
	Timestamp time.Time              `json:"timestamp"`
	Data      map[string]interface{} `json:"data"`
	Priority  EventPriority          `json:"priority"`
}

// EventPriority définit la priorité d'un événement
type EventPriority int

const (
	PriorityLow EventPriority = iota
	PriorityNormal
	PriorityHigh
	PriorityCritical
)

// EventBusMetrics contient les métriques du bus d'événements
type EventBusMetrics struct {
	TotalEvents     int64         `json:"total_events"`
	ProcessedEvents int64         `json:"processed_events"`
	FailedEvents    int64         `json:"failed_events"`
	QueueSize       int           `json:"queue_size"`
	Subscribers     int           `json:"subscribers"`
	AverageLatency  time.Duration `json:"average_latency"`
}

// NewEventBus crée un nouveau bus d'événements
func NewEventBus(bufferSize int, logger *zap.Logger) *EventBus {
	ctx, cancel := context.WithCancel(context.Background())

	bus := &EventBus{
		subscribers: make(map[string][]EventHandler),
		eventQueue:  make(chan *ManagerEvent, bufferSize),
		bufferSize:  bufferSize,
		logger:      logger,
		ctx:         ctx,
		cancel:      cancel,
		metrics: EventBusMetrics{
			TotalEvents:     0,
			ProcessedEvents: 0,
			FailedEvents:    0,
			QueueSize:       0,
			Subscribers:     0,
		},
	}

	// Démarrer le processeur d'événements
	go bus.eventProcessor()

	logger.Info("Event bus initialized", zap.Int("buffer_size", bufferSize))
	return bus
}

// Subscribe s'abonne à un type d'événement
func (eb *EventBus) Subscribe(eventType string, handler EventHandler) error {
	eb.mu.Lock()
	defer eb.mu.Unlock()

	if eb.subscribers[eventType] == nil {
		eb.subscribers[eventType] = make([]EventHandler, 0)
	}

	eb.subscribers[eventType] = append(eb.subscribers[eventType], handler)
	eb.metrics.Subscribers = eb.getTotalSubscribers()

	eb.logger.Info("New subscriber registered",
		zap.String("event_type", eventType),
		zap.Int("total_subscribers", eb.metrics.Subscribers))

	return nil
}

// Unsubscribe se désabonne d'un type d'événement
func (eb *EventBus) Unsubscribe(eventType string, handler EventHandler) error {
	eb.mu.Lock()
	defer eb.mu.Unlock()

	handlers := eb.subscribers[eventType]
	if handlers == nil {
		return fmt.Errorf("no subscribers for event type: %s", eventType)
	}

	// Retirer le handler spécifique (comparaison par adresse de fonction)
	for i, h := range handlers {
		if fmt.Sprintf("%p", h) == fmt.Sprintf("%p", handler) {
			eb.subscribers[eventType] = append(handlers[:i], handlers[i+1:]...)
			eb.metrics.Subscribers = eb.getTotalSubscribers()

			eb.logger.Info("Subscriber unregistered", zap.String("event_type", eventType))
			return nil
		}
	}

	return fmt.Errorf("handler not found for event type: %s", eventType)
}

// Publish publie un événement sur le bus
func (eb *EventBus) Publish(ctx context.Context, event *ManagerEvent) error {
	if event == nil {
		return fmt.Errorf("event cannot be nil")
	}

	// Compléter les métadonnées de l'événement
	if event.ID == "" {
		event.ID = fmt.Sprintf("evt_%d", time.Now().UnixNano())
	}
	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}

	eb.mu.Lock()
	eb.metrics.TotalEvents++
	eb.mu.Unlock()

	select {
	case eb.eventQueue <- event:
		eb.logger.Debug("Event published",
			zap.String("event_id", event.ID),
			zap.String("type", event.Type),
			zap.String("source", event.Source))
		return nil
	case <-ctx.Done():
		return ctx.Err()
	case <-time.After(time.Second * 5): // Timeout après 5s
		eb.mu.Lock()
		eb.metrics.FailedEvents++
		eb.mu.Unlock()
		return fmt.Errorf("timeout publishing event: queue is full")
	}
}

// eventProcessor traite les événements en arrière-plan
func (eb *EventBus) eventProcessor() {
	eb.logger.Info("Event processor started")

	for {
		select {
		case event := <-eb.eventQueue:
			eb.processEvent(event)
		case <-eb.ctx.Done():
			eb.logger.Info("Event processor stopping")
			return
		}
	}
}

// processEvent traite un événement spécifique
func (eb *EventBus) processEvent(event *ManagerEvent) {
	startTime := time.Now()

	eb.mu.RLock()
	handlers := eb.subscribers[event.Type]
	eb.mu.RUnlock()

	if len(handlers) == 0 {
		eb.logger.Debug("No subscribers for event",
			zap.String("event_type", event.Type),
			zap.String("event_id", event.ID))
		return
	}

	// Traiter tous les handlers en parallèle
	var wg sync.WaitGroup
	errorChan := make(chan error, len(handlers))

	for _, handler := range handlers {
		wg.Add(1)
		go func(h EventHandler) {
			defer wg.Done()

			handlerCtx, cancel := context.WithTimeout(eb.ctx, time.Second*30)
			defer cancel()

			if err := h(handlerCtx, event); err != nil {
				errorChan <- err
				eb.logger.Error("Event handler failed",
					zap.String("event_id", event.ID),
					zap.String("event_type", event.Type),
					zap.Error(err))
			}
		}(handler)
	}

	wg.Wait()
	close(errorChan)

	// Collecter les erreurs
	errorCount := 0
	for range errorChan {
		errorCount++
	}

	// Mettre à jour les métriques
	eb.mu.Lock()
	eb.metrics.ProcessedEvents++
	if errorCount > 0 {
		eb.metrics.FailedEvents += int64(errorCount)
	}

	// Mettre à jour la latence moyenne
	latency := time.Since(startTime)
	eb.metrics.AverageLatency = (eb.metrics.AverageLatency + latency) / 2
	eb.metrics.QueueSize = len(eb.eventQueue)
	eb.mu.Unlock()

	eb.logger.Debug("Event processed",
		zap.String("event_id", event.ID),
		zap.Int("handlers_count", len(handlers)),
		zap.Int("errors", errorCount),
		zap.Duration("latency", latency))
}

// getTotalSubscribers calcule le nombre total de souscripteurs
func (eb *EventBus) getTotalSubscribers() int {
	total := 0
	for _, handlers := range eb.subscribers {
		total += len(handlers)
	}
	return total
}

// GetMetrics retourne les métriques du bus d'événements
func (eb *EventBus) GetMetrics() EventBusMetrics {
	eb.mu.RLock()
	defer eb.mu.RUnlock()

	metrics := eb.metrics
	metrics.QueueSize = len(eb.eventQueue)
	return metrics
}

// Close ferme le bus d'événements
func (eb *EventBus) Close() error {
	eb.cancel()
	close(eb.eventQueue)

	eb.logger.Info("Event bus closed")
	return nil
}

// CreateEvent est une fonction utilitaire pour créer des événements
func CreateEvent(eventType, source string, data map[string]interface{}) *ManagerEvent {
	return &ManagerEvent{
		ID:        fmt.Sprintf("evt_%d", time.Now().UnixNano()),
		Type:      eventType,
		Source:    source,
		Timestamp: time.Now(),
		Data:      data,
		Priority:  PriorityNormal,
	}
}

// CreatePriorityEvent crée un événement avec une priorité spécifique
func CreatePriorityEvent(eventType, source string, priority EventPriority, data map[string]interface{}) *ManagerEvent {
	event := CreateEvent(eventType, source, data)
	event.Priority = priority
	return event
}
