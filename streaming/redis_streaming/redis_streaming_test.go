package redisstreaming

import (
	"context"
	"testing"
	"time"
	"github.com/go-redis/redis/v8"
)

func TestRedisStreamingDocSync_PublishDocumentationEvent(t *testing.T) {
	client := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	docSync := &RedisStreamingDocSync{client: client}
	event := DocumentationEvent{ManagerID: 1, DocumentID: 2, EventType: "create", Payload: "test"}
	err := docSync.PublishDocumentationEvent(context.Background(), event)
	if err != nil {
		t.Fatalf("PublishDocumentationEvent failed: %v", err)
	}
}

func TestIntelligentCache_SetAndGet(t *testing.T) {
	client := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
	cache := NewIntelligentCache(client)
	key := "test_key"
	value := "test_value"
	err := cache.SetWithTTL(context.Background(), key, value, 1*time.Minute)
	if err != nil {
		t.Fatalf("SetWithTTL failed: %v", err)
	}
	got, err := cache.Get(context.Background(), key)
	if err != nil || got != value {
		t.Fatalf("Get failed: got %v, err %v", got, err)
	}
}
