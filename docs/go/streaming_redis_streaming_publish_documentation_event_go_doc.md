# Package redisstreaming

4.4.3.4 Stratégies de cache avancées

4.4.3.3 IntelligentCache : cache adaptatif

4.4.3.2 PublishDocumentationEvent : publication d'événements

4.4.3.1 RedisStreamingDocSync : structure principale


## Types

### DocumentationEvent

### IntelligentCache

#### Methods

##### IntelligentCache.AdvancedCacheStrategy

AdvancedCacheStrategy applique une stratégie de cache basée sur la fréquence d'accès


```go
func (c *IntelligentCache) AdvancedCacheStrategy(ctx context.Context, key string, value interface{}, accessCount int) error
```

##### IntelligentCache.Get

```go
func (c *IntelligentCache) Get(ctx context.Context, key string) (string, error)
```

##### IntelligentCache.SetWithTTL

```go
func (c *IntelligentCache) SetWithTTL(ctx context.Context, key string, value interface{}, ttl time.Duration) error
```

### RedisStreamingDocSync

#### Methods

##### RedisStreamingDocSync.Close

```go
func (r *RedisStreamingDocSync) Close() error
```

##### RedisStreamingDocSync.PublishDocumentationEvent

```go
func (r *RedisStreamingDocSync) PublishDocumentationEvent(ctx context.Context, event DocumentationEvent) error
```

