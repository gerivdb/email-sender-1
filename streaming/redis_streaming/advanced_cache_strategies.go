// 4.4.3.4 Stratégies de cache avancées
package redisstreaming

import (
	"context"
	"time"
)

// AdvancedCacheStrategy applique une stratégie de cache basée sur la fréquence d'accès
func (c *IntelligentCache) AdvancedCacheStrategy(ctx context.Context, key string, value interface{}, accessCount int) error {
	var ttl time.Duration
	switch {
	case accessCount > 100:
		ttl = 24 * time.Hour
	case accessCount > 10:
		ttl = 1 * time.Hour
	default:
		ttl = 10 * time.Minute
	}
	return c.SetWithTTL(ctx, key, value, ttl)
}
