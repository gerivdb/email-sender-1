package bridge

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

func TestChannelEventBus_PublishSubscribe(t *testing.T) {
	logger := zap.NewNop()
	eventBus := NewChannelEventBus(logger, nil)
	defer eventBus.Close()

	var receivedEvents []Event
	handler := func(ctx context.Context, event Event) error {
		receivedEvents = append(receivedEvents, event)
		return nil
	}

	err := eventBus.Subscribe("test_event", handler)
	require.NoError(t, err)

	event := Event{
		Type: "test_event",
		Data: map[string]interface{}{
			"message": "hello world",
		},
		TraceID: "test-trace-1",
	}

	err = eventBus.Publish(context.Background(), event)
	require.NoError(t, err)

	// Wait for async processing
	time.Sleep(100 * time.Millisecond)

	assert.Len(t, receivedEvents, 1)
	assert.Equal(t, "test_event", receivedEvents[0].Type)
	assert.Equal(t, "hello world", receivedEvents[0].Data["message"])
	assert.Equal(t, "test-trace-1", receivedEvents[0].TraceID)
}

func TestChannelEventBus_MultipleSubscribers(t *testing.T) {
	logger := zap.NewNop()
	eventBus := NewChannelEventBus(logger, nil)
	defer eventBus.Close()

	var events1, events2 []Event

	handler1 := func(ctx context.Context, event Event) error {
		events1 = append(events1, event)
		return nil
	}

	handler2 := func(ctx context.Context, event Event) error {
		events2 = append(events2, event)
		return nil
	}

	err := eventBus.Subscribe("multi_test", handler1)
	require.NoError(t, err)

	err = eventBus.Subscribe("multi_test", handler2)
	require.NoError(t, err)

	event := Event{
		Type: "multi_test",
		Data: map[string]interface{}{"value": 42},
	}

	err = eventBus.Publish(context.Background(), event)
	require.NoError(t, err)

	// Wait for async processing
	time.Sleep(100 * time.Millisecond)

	assert.Len(t, events1, 1)
	assert.Len(t, events2, 1)
	assert.Equal(t, 42, events1[0].Data["value"])
	assert.Equal(t, 42, events2[0].Data["value"])
}

func TestChannelEventBus_PublishWorkflowEvent(t *testing.T) {
	logger := zap.NewNop()
	eventBus := NewChannelEventBus(logger, nil)
	defer eventBus.Close()

	var receivedEvents []Event
	handler := func(ctx context.Context, event Event) error {
		receivedEvents = append(receivedEvents, event)
		return nil
	}

	err := eventBus.Subscribe("workflow_started", handler)
	require.NoError(t, err)

	err = eventBus.PublishWorkflowEvent(
		context.Background(),
		"workflow_started",
		"wf-123",
		"exec-456",
		"trace-789",
		map[string]interface{}{"priority": "high"},
	)
	require.NoError(t, err)

	// Wait for async processing
	time.Sleep(100 * time.Millisecond)

	assert.Len(t, receivedEvents, 1)
	event := receivedEvents[0]
	assert.Equal(t, "workflow_started", event.Type)
	assert.Equal(t, "wf-123", event.Data["workflow_id"])
	assert.Equal(t, "exec-456", event.Data["execution_id"])
	assert.Equal(t, "high", event.Data["priority"])
	assert.Equal(t, "trace-789", event.TraceID)
}

func TestChannelEventBus_GetEventStats(t *testing.T) {
	logger := zap.NewNop()
	eventBus := NewChannelEventBus(logger, nil)
	defer eventBus.Close()

	handler := func(ctx context.Context, event Event) error {
		return nil
	}

	// Subscribe to multiple event types
	eventBus.Subscribe("type1", handler)
	eventBus.Subscribe("type2", handler)
	eventBus.Subscribe("type1", handler) // Second handler for type1

	stats, err := eventBus.GetEventStats(context.Background())
	require.NoError(t, err)

	assert.Equal(t, 2, stats["active_event_types"])
	assert.Equal(t, 2, stats["total_subscribers"])
	assert.Equal(t, false, stats["persistence_enabled"])

	channelsInfo := stats["channels_info"].(map[string]interface{})
	assert.Contains(t, channelsInfo, "type1")
	assert.Contains(t, channelsInfo, "type2")
}

func TestChannelEventBus_ConcurrentPublish(t *testing.T) {
	logger := zap.NewNop()
	eventBus := NewChannelEventBus(logger, nil)
	defer eventBus.Close()

	var receivedCount int
	handler := func(ctx context.Context, event Event) error {
		receivedCount++
		return nil
	}

	err := eventBus.Subscribe("concurrent_test", handler)
	require.NoError(t, err)

	const numEvents = 100

	// Publish events concurrently
	for i := 0; i < numEvents; i++ {
		go func(id int) {
			event := Event{
				Type: "concurrent_test",
				Data: map[string]interface{}{"id": id},
			}
			eventBus.Publish(context.Background(), event)
		}(i)
	}

	// Wait for all events to be processed
	time.Sleep(500 * time.Millisecond)

	assert.Equal(t, numEvents, receivedCount)
}

func BenchmarkChannelEventBus_Publish(b *testing.B) {
	logger := zap.NewNop()
	eventBus := NewChannelEventBus(logger, nil)
	defer eventBus.Close()

	handler := func(ctx context.Context, event Event) error {
		return nil
	}

	eventBus.Subscribe("benchmark", handler)

	event := Event{
		Type: "benchmark",
		Data: map[string]interface{}{"test": "data"},
	}

	b.ResetTimer()
	b.RunParallel(func(pb *testing.PB) {
		for pb.Next() {
			eventBus.Publish(context.Background(), event)
		}
	})
}
