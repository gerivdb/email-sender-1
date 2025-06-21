// 4.4.3.3 IntelligentCache : cache adaptatif
package redisstreaming

import (
	"context"
	"time"
)

type IntelligentCache struct {
	client *redis.Client
}

func NewIntelligentCache(client *redis.Client) *IntelligentCache {
	return &IntelligentCache{client: client}
}

func (c *IntelligentCache) SetWithTTL(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	return c.client.Set(ctx, key, value, ttl).Err()
}

func (c *IntelligentCache) Get(ctx context.Context, key string) (string, error) {
	return c.client.Get(ctx, key).Result()
}
