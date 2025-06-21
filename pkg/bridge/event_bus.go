package bridge

import (
	"context"
	"encoding/json"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
)

// Event represents an event in the system
type Event struct {
	Type      string                 `json:"type"`
	Data      map[string]interface{} `json:"data"`
	Timestamp time.Time              `json:"timestamp"`
	TraceID   string                 `json:"trace_id"`
}

// EventHandler defines the signature for event handlers
type EventHandler func(ctx context.Context, event Event) error

// EventBus interface defines the event bus operations
type EventBus interface {
	Publish(ctx context.Context, event Event) error
	Subscribe(eventType string, handler EventHandler) error
	Unsubscribe(eventType string, handler EventHandler) error
	Close() error
}

// ChannelEventBus implements EventBus using Go channels
type ChannelEventBus struct {
	logger      *zap.Logger
	subscribers map[string][]EventHandler
	channels    map[string]chan Event
	mu          sync.RWMutex
	ctx         context.Context
	cancel      context.CancelFunc
	redisClient *redis.Client
	persistence bool
}

// NewChannelEventBus creates a new channel-based event bus
func NewChannelEventBus(logger *zap.Logger, redisClient *redis.Client) *ChannelEventBus {
	ctx, cancel := context.WithCancel(context.Background())

	return &ChannelEventBus{
		logger:      logger,
		subscribers: make(map[string][]EventHandler),
		channels:    make(map[string]chan Event),
		ctx:         ctx,
		cancel:      cancel,
		redisClient: redisClient,
		persistence: redisClient != nil,
	}
}

// Publish publishes an event to all subscribers
func (bus *ChannelEventBus) Publish(ctx context.Context, event Event) error {
	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}

	bus.logger.Debug("Publishing event",
		zap.String("type", event.Type),
		zap.String("trace_id", event.TraceID),
		zap.Time("timestamp", event.Timestamp))

	// Persist to Redis if enabled
	if bus.persistence {
		if err := bus.persistEvent(ctx, event); err != nil {
			bus.logger.Error("Failed to persist event to Redis",
				zap.Error(err),
				zap.String("event_type", event.Type))
		}
	}

	// Send to channel subscribers
	bus.mu.RLock()
	channel, exists := bus.channels[event.Type]
	// handlers := bus.subscribers[event.Type] // Removed direct handler call from Publish
	bus.mu.RUnlock()

	if exists {
		select {
		case channel <- event:
		case <-ctx.Done():
			bus.logger.Info("Context done, event not published", zap.String("event_type", event.Type))
			return ctx.Err()
		default:
			// This case can happen if the channel buffer is full.
			// It's important to log this, as events might be lost.
			bus.logger.Warn("Event channel full, dropping event",
				zap.String("event_type", event.Type),
				zap.String("trace_id", event.TraceID))
			// Depending on requirements, this could return an error or implement other strategies.
		}
	} else {
		// Log if no channel (and thus no subscribers via channel processing) exists for the event type.
		// This might be normal if some events are fire-and-forget with no active subscribers.
		bus.logger.Debug("No channel for event type, event not sent to channel",
			zap.String("event_type", event.Type),
			zap.String("trace_id", event.TraceID))
	}

	// Direct handlers were removed from here.
	// All subscribed handlers will be called by processEventChannel.

	return nil
}

// Subscribe adds a handler for a specific event type
func (bus *ChannelEventBus) Subscribe(eventType string, handler EventHandler) error {
	bus.mu.Lock()
	defer bus.mu.Unlock()

	// Create channel if it doesn't exist
	if _, exists := bus.channels[eventType]; !exists {
		bus.channels[eventType] = make(chan Event, 100) // Buffered channel
		go bus.processEventChannel(eventType)
	}

	// Add handler to direct subscribers
	bus.subscribers[eventType] = append(bus.subscribers[eventType], handler)

	bus.logger.Info("Event handler subscribed",
		zap.String("event_type", eventType),
		zap.Int("total_handlers", len(bus.subscribers[eventType])))

	return nil
}

// Unsubscribe removes a handler for a specific event type
func (bus *ChannelEventBus) Unsubscribe(eventType string, handler EventHandler) error {
	bus.mu.Lock()
	defer bus.mu.Unlock()

	handlers := bus.subscribers[eventType]
	for i, h := range handlers {
		// Note: We can't directly compare function pointers, so this is a simplified approach
		// In a real implementation, you might want to use handler IDs
		if &h == &handler {
			bus.subscribers[eventType] = append(handlers[:i], handlers[i+1:]...)
			break
		}
	}

	// Close channel if no more subscribers
	if len(bus.subscribers[eventType]) == 0 {
		if channel, exists := bus.channels[eventType]; exists {
			close(channel)
			delete(bus.channels, eventType)
		}
		delete(bus.subscribers, eventType)
	}

	return nil
}

// processEventChannel processes events from a specific channel
func (bus *ChannelEventBus) processEventChannel(eventType string) {
	bus.mu.RLock()
	channel := bus.channels[eventType]
	bus.mu.RUnlock()

	for {
		select {
		case event, ok := <-channel:
			if !ok {
				return // Channel closed
			}

			bus.mu.RLock()
			handlers := bus.subscribers[eventType]
			bus.mu.RUnlock()

			// Process with all handlers
			for _, handler := range handlers {
				go func(h EventHandler) {
					if err := h(bus.ctx, event); err != nil {
						bus.logger.Error("Channel event handler failed",
							zap.Error(err),
							zap.String("event_type", eventType))
					}
				}(handler)
			}

		case <-bus.ctx.Done():
			return
		}
	}
}

// persistEvent saves the event to Redis for reliability
func (bus *ChannelEventBus) persistEvent(ctx context.Context, event Event) error {
	if bus.redisClient == nil {
		return nil
	}

	eventJSON, err := json.Marshal(event)
	if err != nil {
		return err
	}

	// Store in Redis list for the event type
	key := "events:" + event.Type
	err = bus.redisClient.LPush(ctx, key, eventJSON).Err()
	if err != nil {
		return err
	}

	// Set expiration for the list (7 days)
	bus.redisClient.Expire(ctx, key, 7*24*time.Hour)

	// Store in global events list with timestamp
	globalKey := "events:all"
	timestampedEvent := map[string]interface{}{
		"timestamp": event.Timestamp.Unix(),
		"type":      event.Type,
		"trace_id":  event.TraceID,
		"data":      event.Data,
	}

	globalEventJSON, _ := json.Marshal(timestampedEvent)
	bus.redisClient.LPush(ctx, globalKey, globalEventJSON)
	bus.redisClient.Expire(ctx, globalKey, 7*24*time.Hour)

	return nil
}

// GetRecentEvents retrieves recent events from Redis
func (bus *ChannelEventBus) GetRecentEvents(ctx context.Context, eventType string, limit int64) ([]Event, error) {
	if bus.redisClient == nil {
		return nil, nil
	}

	key := "events:" + eventType
	eventStrings, err := bus.redisClient.LRange(ctx, key, 0, limit-1).Result()
	if err != nil {
		return nil, err
	}

	events := make([]Event, 0, len(eventStrings))
	for _, eventStr := range eventStrings {
		var event Event
		if err := json.Unmarshal([]byte(eventStr), &event); err != nil {
			bus.logger.Warn("Failed to unmarshal event from Redis",
				zap.Error(err),
				zap.String("event_type", eventType))
			continue
		}
		events = append(events, event)
	}

	return events, nil
}

// GetEventStats returns statistics about events
func (bus *ChannelEventBus) GetEventStats(ctx context.Context) (map[string]interface{}, error) {
	bus.mu.RLock()
	defer bus.mu.RUnlock()

	stats := map[string]interface{}{
		"active_event_types":  len(bus.channels),
		"total_subscribers":   len(bus.subscribers),
		"channels_info":       make(map[string]interface{}),
		"persistence_enabled": bus.persistence,
	}

	channelsInfo := make(map[string]interface{})
	for eventType, channel := range bus.channels {
		channelsInfo[eventType] = map[string]interface{}{
			"channel_length":   len(channel),
			"channel_capacity": cap(channel),
			"subscriber_count": len(bus.subscribers[eventType]),
		}
	}
	stats["channels_info"] = channelsInfo

	return stats, nil
}

// Close closes the event bus and all channels
func (bus *ChannelEventBus) Close() error {
	bus.logger.Info("Closing event bus")

	bus.cancel() // Cancel context

	bus.mu.Lock()
	defer bus.mu.Unlock()

	// Close all channels
	for eventType, channel := range bus.channels {
		close(channel)
		bus.logger.Debug("Closed channel for event type", zap.String("event_type", eventType))
	}

	// Clear maps
	bus.channels = make(map[string]chan Event)
	bus.subscribers = make(map[string][]EventHandler)

	return nil
}

// PublishWorkflowEvent is a convenience method for publishing workflow events
func (bus *ChannelEventBus) PublishWorkflowEvent(ctx context.Context, eventType, workflowID, executionID, traceID string, data map[string]interface{}) error {
	event := Event{
		Type:      eventType,
		Timestamp: time.Now(),
		TraceID:   traceID,
		Data: map[string]interface{}{
			"workflow_id":  workflowID,
			"execution_id": executionID,
		},
	}

	// Merge additional data
	for k, v := range data {
		event.Data[k] = v
	}

	return bus.Publish(ctx, event)
}
