# TTL (Time-To-Live) Cache Management System

A comprehensive Redis-based TTL management system for optimizing cache performance in the email sender application.

## 📋 Overview

The TTL management system provides intelligent cache optimization through:
- **Automatic TTL Configuration** - Type-specific TTL settings based on data usage patterns
- **Real-time Analysis** - Continuous monitoring and optimization of cache performance
- **Smart Invalidation** - Multiple invalidation strategies (time, event, and version-based)
- **Comprehensive Monitoring** - Detailed metrics, alerting, and performance insights
- **CLI Tools** - Command-line utilities for cache analysis and optimization

## 🏗️ Architecture

```plaintext
pkg/cache/ttl/
├── manager.go        # Core TTL management and Redis integration

├── analyzer.go       # Usage pattern analysis and optimization

├── invalidation.go   # Cache invalidation strategies

├── monitoring.go     # Metrics collection and alerting

└── ttl_test.go      # Comprehensive test suite

```plaintext
## 🚀 Quick Start

### Basic Usage

```go
import "pkg/cache/ttl"

// Initialize TTL manager
manager := ttl.NewTTLManager(redisClient)

// Set data with automatic TTL
err := manager.Set("user:123", userData, ttl.UserSessions)
if err != nil {
    log.Fatal(err)
}

// Get data
var user User
found, err := manager.Get("user:123", &user)
if err != nil {
    log.Fatal(err)
}
```plaintext
### Advanced Configuration

```go
// Create analyzer for optimization
analyzer := ttl.NewAnalyzer(redisClient)

// Start automatic optimization
ctx := context.Background()
go analyzer.StartAutoOptimization(ctx, 30*time.Minute)

// Set up monitoring
monitor := ttl.NewCacheMetrics(redisClient)
go monitor.StartMetricsCollection(ctx, 10*time.Second)
```plaintext
## 📊 Data Types & TTL Defaults

| Data Type | Default TTL | Use Case |
|-----------|-------------|-----------|
| `DefaultValues` | 1 hour | General cache data |
| `Statistics` | 24 hours | Analytics and reports |
| `MLModels` | 1 hour | Machine learning models |
| `Configuration` | 30 minutes | Application config |
| `UserSessions` | 2 hours | User session data |

## 🔧 Features

### 1. Intelligent TTL Management

```go
// Type-specific TTL configuration
manager.SetTTL(ttl.Statistics, 24*time.Hour)
manager.SetTTL(ttl.UserSessions, 2*time.Hour)

// Automatic optimization based on usage patterns
analyzer.OptimizeTTL("user_data_pattern")
```plaintext
### 2. Cache Analysis & Optimization

```go
// Analyze cache performance
analysis := analyzer.AnalyzePattern("email_queue")
fmt.Printf("Hit Rate: %.2f%%\n", analysis.HitRate*100)
fmt.Printf("Recommended TTL: %v\n", analysis.RecommendedTTL)

// Get optimization recommendations
recommendations := analyzer.GetOptimizationRecommendations()
```plaintext
### 3. Smart Invalidation Strategies

```go
// Time-based invalidation
invalidator := ttl.NewInvalidationManager(redisClient)
invalidator.InvalidateByAge(30*time.Minute)

// Event-based invalidation
invalidator.InvalidateByEvent("user_update", "user:*")

// Version-based invalidation
invalidator.InvalidateByVersion("config", 2)
```plaintext
### 4. Comprehensive Monitoring

```go
// Start metrics collection
metrics := ttl.NewCacheMetrics(redisClient)
go metrics.StartMetricsCollection(ctx, 10*time.Second)

// Set up alerts
alert := ttl.AlertConfig{
    MetricType: ttl.HitRateAlert,
    Threshold:  0.8, // Alert if hit rate < 80%
    Action:     ttl.LogAlert,
}
metrics.AddAlert(alert)
```plaintext
## 🛠️ CLI Tools

### Cache Analyzer Tool

```bash
# Build the analyzer tool

go build -o cache-analyzer tools/cache-analyzer/main.go

# Run analysis

./cache-analyzer -redis-addr="localhost:6379" -analysis-type="comprehensive"

# Generate recommendations

./cache-analyzer -redis-addr="localhost:6379" -analysis-type="recommendations"
```plaintext
### Example Output

```plaintext
Cache Analysis Report
====================
Overall Hit Rate: 89.2%
Memory Usage: 256.8 MB
Average Latency: 1.2ms
Cache Size: 15,432 keys

Recommendations:
- Increase TTL for 'user_sessions' pattern (current: 2h, recommended: 3h)
- Consider implementing preloading for 'email_templates' pattern
- Monitor 'ml_models' pattern - high eviction rate detected
```plaintext
## 📈 Performance Metrics

The system tracks comprehensive metrics:

- **Hit/Miss Rates** - Cache effectiveness
- **Eviction Rates** - Memory pressure indicators
- **Latency Metrics** - Response time analysis
- **Memory Usage** - Resource utilization
- **Throughput** - Requests per second
- **Type-specific Metrics** - Per-data-type analysis

## 🔍 Monitoring & Alerting

### Available Alerts

- **Hit Rate Alerts** - When cache hit rate drops below threshold
- **Memory Alerts** - When memory usage exceeds limits
- **Latency Alerts** - When response times increase
- **Eviction Alerts** - When eviction rate is too high

### Alert Actions

- **Log Alert** - Write to application logs
- **Email Alert** - Send email notifications
- **Webhook Alert** - HTTP callback notifications

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests

go test ./pkg/cache/ttl/... -v

# Run with Redis integration (requires Redis server)

go test ./pkg/cache/ttl/... -v -tags=integration

# Run benchmarks

go test ./pkg/cache/ttl/... -bench=. -benchmem
```plaintext
## 📋 Demo Scripts

### Simple Demo

```bash
go run demo/ttl-demo-simple.go
```plaintext
### Comprehensive Demo

```bash
go run demo/ttl-system-demo.go
```plaintext
### Working Demo with Fallback

```bash
go run demo/ttl-demo-working.go
```plaintext
## ⚙️ Configuration

### Environment Variables

```bash
# Redis Configuration

REDIS_ADDR=localhost:6379
REDIS_PASSWORD=
REDIS_DB=0

# TTL Configuration

TTL_DEFAULT_VALUES=1h
TTL_STATISTICS=24h
TTL_ML_MODELS=1h
TTL_CONFIGURATION=30m
TTL_USER_SESSIONS=2h

# Monitoring Configuration

METRICS_COLLECTION_INTERVAL=10s
OPTIMIZATION_INTERVAL=30m
```plaintext
### Programmatic Configuration

```go
config := ttl.Config{
    RedisAddr:     "localhost:6379",
    RedisPassword: "",
    RedisDB:       0,
    TTLSettings: map[ttl.DataType]time.Duration{
        ttl.DefaultValues: time.Hour,
        ttl.Statistics:    24 * time.Hour,
        ttl.MLModels:      time.Hour,
        ttl.Configuration: 30 * time.Minute,
        ttl.UserSessions:  2 * time.Hour,
    },
}

manager := ttl.NewTTLManagerWithConfig(config)
```plaintext
## 🔧 Production Deployment

### Docker Deployment

```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o email-sender ./cmd/server

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/email-sender .
CMD ["./email-sender"]
```plaintext
### Kubernetes Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: email-sender
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
        env:
        - name: REDIS_ADDR
          value: "redis-service:6379"
        - name: TTL_OPTIMIZATION_INTERVAL
          value: "30m"
```plaintext
### Performance Tuning

1. **Memory Optimization**
   - Set appropriate `maxmemory` in Redis
   - Use `allkeys-lru` eviction policy
   - Monitor memory usage alerts

2. **TTL Optimization**
   - Start with conservative TTL values
   - Enable auto-optimization
   - Monitor hit rates and adjust

3. **Connection Pooling**
   - Configure Redis connection pool size
   - Set appropriate timeouts
   - Monitor connection metrics

## 🤝 Integration Examples

### Email Queue Integration

```go
// Cache email templates with optimized TTL
manager.Set("template:welcome", welcomeTemplate, ttl.Configuration)

// Cache user preferences
manager.Set("user:preferences:123", userPrefs, ttl.UserSessions)

// Cache ML model results
manager.Set("ml:sentiment:abc", sentimentResult, ttl.MLModels)
```plaintext
### Metrics Integration

```go
// Expose metrics for Prometheus
http.Handle("/metrics", promhttp.Handler())

// Custom metrics collection
go func() {
    for {
        metrics := monitor.GetCurrentMetrics()
        // Send to monitoring system
        sendToMonitoring(metrics)
        time.Sleep(30 * time.Second)
    }
}()
```plaintext
## 📚 API Reference

### TTLManager

- `NewTTLManager(redis *redis.Client) *TTLManager`
- `Set(key string, value interface{}, dataType DataType) error`
- `Get(key string, dest interface{}) (bool, error)`
- `Delete(key string) error`
- `SetTTL(dataType DataType, ttl time.Duration)`

### Analyzer

- `NewAnalyzer(redis *redis.Client) *Analyzer`
- `AnalyzePattern(pattern string) *PatternAnalysis`
- `OptimizeTTL(pattern string) error`
- `GetOptimizationRecommendations() []OptimizationRecommendation`

### Monitoring

- `NewCacheMetrics(redis *redis.Client) *CacheMetrics`
- `StartMetricsCollection(ctx context.Context, interval time.Duration)`
- `GetCurrentMetrics() *MetricData`
- `AddAlert(config AlertConfig)`

## 🐛 Troubleshooting

### Common Issues

1. **Redis Connection Issues**
   ```
   Error: dial tcp 127.0.0.1:6379: connect: connection refused
   ```
   - Ensure Redis server is running
   - Check Redis configuration
   - Verify network connectivity

2. **High Memory Usage**
   - Review TTL settings
   - Check for memory leaks
   - Monitor eviction rates

3. **Low Hit Rates**
   - Analyze access patterns
   - Consider increasing TTL values
   - Review cache invalidation strategies

### Debug Mode

Enable debug logging:

```go
manager.SetDebugMode(true)
analyzer.SetDebugMode(true)
```plaintext
## 📄 License

This TTL management system is part of the EMAIL_SENDER_1 project.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

---

For more information, see the main project [README](../../../README.md).
