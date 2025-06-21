// 4.4.3.2 PublishDocumentationEvent : publication d'événements
package redisstreaming

import (
	"context"
)

type DocumentationEvent struct {
	ManagerID int
	DocumentID int
	EventType string
	Payload string
}

func (r *RedisStreamingDocSync) PublishDocumentationEvent(ctx context.Context, event DocumentationEvent) error {
	return r.client.XAdd(ctx, &redis.XAddArgs{
		Stream: "documentation_events",
		Values: map[string]interface{}{
			"manager_id": event.ManagerID,
			"document_id": event.DocumentID,
			"event_type": event.EventType,
			"payload": event.Payload,
		},
	}).Err()
}
