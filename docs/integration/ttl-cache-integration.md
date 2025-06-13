# TTL Cache Integration Guide

This guide shows how to integrate the TTL cache management system with your email sender application.

## 🚀 Quick Integration

### 1. Add Dependencies

First, ensure your `go.mod` includes the necessary Redis dependencies:

```go
module email_sender

go 1.21

require (
    github.com/redis/go-redis/v9 v9.0.5
    github.com/gorilla/mux v1.8.0
    github.com/prometheus/client_golang v1.15.1
)
```plaintext
### 2. Basic Integration

```go
package main

import (
    "github.com/redis/go-redis/v9"
    "pkg/cache/ttl"
    "pkg/email"
)

func main() {
    // Initialize Redis client
    redisClient := redis.NewClient(&redis.Options{
        Addr: "localhost:6379",
    })
    
    // Create email service with TTL caching
    emailService := email.NewEmailService(redisClient)
    
    // Use the service
    template, err := emailService.GetEmailTemplate("welcome")
    if err != nil {
        log.Fatal(err)
    }
    
    fmt.Printf("Template: %+v\n", template)
}
```plaintext
### 3. Advanced Configuration

```go
// Custom TTL configuration
config := ttl.Config{
    RedisAddr:     "localhost:6379",
    RedisPassword: "",
    RedisDB:       0,
    TTLSettings: map[ttl.DataType]time.Duration{
        ttl.DefaultValues: time.Hour,        // 1 hour
        ttl.Statistics:    24 * time.Hour,   // 24 hours
        ttl.MLModels:      time.Hour,        // 1 hour
        ttl.Configuration: 30 * time.Minute, // 30 minutes
        ttl.UserSessions:  2 * time.Hour,    // 2 hours
    },
    MonitoringInterval:   10 * time.Second,
    OptimizationInterval: 30 * time.Minute,
}

manager := ttl.NewTTLManagerWithConfig(config)
```plaintext
## 🏗️ Integration Examples

### Email Template Caching

```go
// Get template with intelligent caching
func (s *EmailService) GetTemplate(id string) (*Template, error) {
    cacheKey := fmt.Sprintf("template:%s", id)
    
    var template Template
    found, err := s.cacheManager.Get(cacheKey, &template)
    if err != nil {
        return nil, err
    }
    
    if found {
        return &template, nil // Served from cache
    }
    
    // Load from database
    template, err = s.loadTemplateFromDB(id)
    if err != nil {
        return nil, err
    }
    
    // Cache with configuration TTL (30 minutes)
    s.cacheManager.Set(cacheKey, template, ttl.Configuration)
    return &template, nil
}
```plaintext
### User Session Caching

```go
// Cache user sessions with automatic expiration
func (s *EmailService) GetUserSession(userID string) (*Session, error) {
    cacheKey := fmt.Sprintf("session:%s", userID)
    
    var session Session
    found, err := s.cacheManager.Get(cacheKey, &session)
    if err != nil {
        return nil, err
    }
    
    if found {
        return &session, nil
    }
    
    // Create new session
    session = s.createUserSession(userID)
    
    // Cache with user session TTL (2 hours)
    s.cacheManager.Set(cacheKey, session, ttl.UserSessions)
    return &session, nil
}
```plaintext
### ML Model Results Caching

```go
// Cache expensive ML computations
func (s *EmailService) GetSentimentAnalysis(text string) (*Sentiment, error) {
    // Create cache key from text hash
    textHash := sha256.Sum256([]byte(text))
    cacheKey := fmt.Sprintf("sentiment:%x", textHash)
    
    var sentiment Sentiment
    found, err := s.cacheManager.Get(cacheKey, &sentiment)
    if err != nil {
        return nil, err
    }
    
    if found {
        return &sentiment, nil
    }
    
    // Expensive ML computation
    sentiment, err = s.runSentimentAnalysis(text)
    if err != nil {
        return nil, err
    }
    
    // Cache with ML model TTL (1 hour)
    s.cacheManager.Set(cacheKey, sentiment, ttl.MLModels)
    return &sentiment, nil
}
```plaintext
## 🔧 Production Configuration

### Environment Variables

Create a `.env` file for production configuration:

```env
# Redis Configuration

REDIS_ADDR=redis-cluster:6379
REDIS_PASSWORD=your_secure_password
REDIS_DB=0
REDIS_MAX_RETRIES=3
REDIS_POOL_SIZE=100

# TTL Configuration

TTL_DEFAULT_VALUES=1h
TTL_STATISTICS=24h
TTL_ML_MODELS=1h
TTL_CONFIGURATION=30m
TTL_USER_SESSIONS=2h

# Monitoring Configuration

METRICS_COLLECTION_INTERVAL=10s
OPTIMIZATION_INTERVAL=30m
CACHE_MEMORY_LIMIT=1GB

# Alert Configuration

ALERT_HIT_RATE_THRESHOLD=0.80
ALERT_MEMORY_THRESHOLD=800MB
ALERT_LATENCY_THRESHOLD=5ms
ALERT_EMAIL_WEBHOOK=https://your-webhook.com/alerts
```plaintext
### Docker Compose Configuration

```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes --maxmemory 1gb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

  email-sender:
    build: .
    ports:
      - "8080:8080"
      - "9090:9090"  # Metrics port

    environment:
      - REDIS_ADDR=redis:6379
      - REDIS_PASSWORD=""
      - TTL_OPTIMIZATION_INTERVAL=30m
      - METRICS_COLLECTION_INTERVAL=10s
    depends_on:
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9091:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'

volumes:
  redis_data:
```plaintext
### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: email-sender
  labels:
    app: email-sender
spec:
  replicas: 3
  selector:
    matchLabels:
      app: email-sender
  template:
    metadata:
      labels:
        app: email-sender
    spec:
      containers:
      - name: email-sender
        image: email-sender:latest
        ports:
        - containerPort: 8080
        - containerPort: 9090
        env:
        - name: REDIS_ADDR
          value: "redis-service:6379"
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-secret
              key: password
        - name: TTL_OPTIMIZATION_INTERVAL
          value: "30m"
        - name: METRICS_COLLECTION_INTERVAL
          value: "10s"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10

---
apiVersion: v1
kind: Service
metadata:
  name: email-sender-service
spec:
  selector:
    app: email-sender
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: metrics
    port: 9090
    targetPort: 9090
  type: LoadBalancer
```plaintext
## 📊 Monitoring Setup

### Prometheus Configuration

Create `prometheus.yml`:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'email-sender'
    static_configs:
      - targets: ['email-sender:9090']
    metrics_path: '/metrics'
    scrape_interval: 10s
```plaintext
### Grafana Dashboard

Import the provided Grafana dashboard for cache metrics visualization:

```json
{
  "dashboard": {
    "title": "Email Sender Cache Metrics",
    "panels": [
      {
        "title": "Cache Hit Rate",
        "type": "stat",
        "targets": [
          {
            "expr": "cache_hit_rate",
            "legendFormat": "Hit Rate"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "cache_memory_usage_mb",
            "legendFormat": "Memory (MB)"
          }
        ]
      },
      {
        "title": "Cache Operations",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(cache_operations_total[5m])",
            "legendFormat": "{{operation}}"
          }
        ]
      }
    ]
  }
}
```plaintext
## 🧪 Testing Integration

### Unit Tests

```go
func TestEmailServiceIntegration(t *testing.T) {
    // Setup test Redis client
    redisClient := redis.NewClient(&redis.Options{
        Addr: "localhost:6379",
        DB:   1, // Use test database
    })
    
    // Clean test database
    redisClient.FlushDB(context.Background())
    defer redisClient.FlushDB(context.Background())
    
    // Create service
    service := email.NewEmailService(redisClient)
    
    // Test template caching
    template, err := service.GetEmailTemplate("test-template")
    assert.NoError(t, err)
    assert.NotNil(t, template)
    
    // Verify cache hit on second call
    template2, err := service.GetEmailTemplate("test-template")
    assert.NoError(t, err)
    assert.Equal(t, template.ID, template2.ID)
    
    // Verify cache metrics
    metrics := service.GetCacheMetrics()
    assert.True(t, metrics.HitRate > 0)
}
```plaintext
### Load Testing

Use the provided load test script:

```bash
# Install dependencies

go get github.com/rakyll/hey

# Run load test

hey -n 10000 -c 100 -m GET http://localhost:8080/api/v1/templates/welcome

# Monitor cache metrics during test

curl http://localhost:8080/api/v1/cache/metrics
```plaintext
## 🚨 Troubleshooting

### Common Issues

1. **Redis Connection Errors**
   ```bash
   # Check Redis connectivity

   redis-cli -h localhost -p 6379 ping
   
   # Check Redis logs

   docker logs redis-container
   ```

2. **High Memory Usage**
   ```bash
   # Check Redis memory usage

   redis-cli info memory
   
   # Analyze cache patterns

   ./cache-analyzer -redis-addr="localhost:6379" -analysis-type="memory"
   ```

3. **Low Cache Hit Rates**
   ```bash
   # Get cache analysis

   curl http://localhost:8080/api/v1/cache/analysis
   
   # Get optimization recommendations

   curl http://localhost:8080/api/v1/cache/recommendations
   ```

### Debug Mode

Enable debug logging for detailed cache operations:

```go
// Enable debug mode
manager.SetDebugMode(true)
analyzer.SetDebugMode(true)

// Check cache operations
log.Printf("Cache operation: %s", operation)
```plaintext
## 📈 Performance Optimization

### Redis Configuration

Optimize Redis for cache workload:

```conf
# redis.conf

maxmemory 1gb
maxmemory-policy allkeys-lru
save ""  # Disable persistence for cache

appendonly no
tcp-keepalive 60
timeout 300
```plaintext
### TTL Optimization

Monitor and adjust TTL values based on usage patterns:

```go
// Analyze patterns and adjust TTL
analysis := analyzer.AnalyzePattern("email_template:*")
if analysis.HitRate < 0.8 {
    // Increase TTL for better hit rate
    manager.SetTTL(ttl.Configuration, time.Hour)
}
```plaintext
### Connection Pooling

Optimize Redis connection pool:

```go
redisClient := redis.NewClient(&redis.Options{
    Addr:         "localhost:6379",
    PoolSize:     100,
    MinIdleConns: 10,
    MaxRetries:   3,
    DialTimeout:  5 * time.Second,
    ReadTimeout:  3 * time.Second,
    WriteTimeout: 3 * time.Second,
})
```plaintext
## 📚 Best Practices

1. **Cache Key Design**
   - Use consistent naming patterns
   - Include version information when needed
   - Use hierarchical keys for easy invalidation

2. **TTL Strategy**
   - Start with conservative TTL values
   - Monitor hit rates and adjust accordingly
   - Use different TTL values for different data types

3. **Error Handling**
   - Always handle cache misses gracefully
   - Implement fallback mechanisms
   - Log cache errors for monitoring

4. **Security**
   - Use Redis AUTH in production
   - Encrypt sensitive cached data
   - Implement proper access controls

5. **Monitoring**
   - Set up comprehensive metrics collection
   - Configure alerts for cache performance
   - Regular cache analysis and optimization

---

For more details, see the [TTL system documentation](../README.md).
