# Redis Configuration System - Plan v39 Section 1.3.1.1

## Overview

This implementation provides a complete Redis configuration system following the specifications in Plan v39, Section 1.3.1.1. It includes advanced features like circuit breaker pattern, connection pooling, health checking, and local cache fallback.

## Features Implemented

### ✅ Core Configuration (Plan v39)

- **Connection Parameters**: Host, Port, Password, DB with validation
- **Timeouts**: DialTimeout=5s, ReadTimeout=3s, WriteTimeout=3s
- **SSL/TLS**: Production-ready SSL configuration support
- **Retry Logic**: MaxRetries=3, MinRetryBackoff=1s, MaxRetryBackoff=3s
- **Connection Pool**: PoolSize=10, MinIdleConns=5, PoolTimeout=4s
- **Health Checks**: Automatic ping every 30 seconds

### ✅ Advanced Features

- **Circuit Breaker Pattern**: Prevents cascade failures with configurable thresholds
- **Error Classification**: Categorizes Redis errors by type (Connection, Timeout, Auth, Network)
- **Reconnection Management**: Exponential backoff with jitter for robust reconnections
- **Local Cache Fallback**: Automatic fallback to in-memory cache when Redis is unavailable
- **Health Monitoring**: Continuous health checking with statistics and callbacks

## Usage Examples

### Basic Redis Client

```go
import redisconfig "email_sender/pkg/cache/redis"

// Create client with default configuration
config := redisconfig.DefaultRedisConfig()
config.Host = "your-redis-host"
config.Password = "your-password"

client, err := config.CreateClient()
if err != nil {
    log.Fatal(err)
}
defer client.Close()

// Use Redis client
ctx := context.Background()
err = client.Set(ctx, "key", "value", time.Hour).Err()
```plaintext
### Advanced Redis Client with Circuit Breaker

```go
import (
    "email_sender/pkg/cache"
    redisconfig "email_sender/pkg/cache/redis"
)

config := redisconfig.DefaultRedisConfig()
config.Host = "your-redis-host"

// Create advanced Redis client with error handling
redisClient, err := cache.NewRedisClient(config)
if err != nil {
    log.Fatal(err)
}
defer redisClient.Close()

// Test connection with circuit breaker protection
ctx := context.Background()
err = redisClient.Ping(ctx)
if err != nil {
    log.Printf("Redis ping failed: %v", err)
}

// Get client statistics
stats := redisClient.GetStats()
fmt.Printf("Redis Stats: %+v\n", stats)
```plaintext
### Hybrid Client with Fallback Cache

```go
import redisconfig "email_sender/pkg/cache/redis"

// Create hybrid client that automatically falls back to local cache
config := redisconfig.DefaultRedisConfig()
config.Host = "your-redis-host"

hybridClient, err := redisconfig.NewHybridRedisClient(config)
if err != nil {
    log.Fatal(err)
}
defer hybridClient.Close()

ctx := context.Background()

// Set value (tries Redis first, falls back to local cache)
err = hybridClient.Set(ctx, "key", "value", time.Hour)
if err != nil {
    log.Printf("Failed to set value: %v", err)
}

// Get value (tries Redis first, falls back to local cache)
value, err := hybridClient.Get(ctx, "key")
if err != nil {
    log.Printf("Failed to get value: %v", err)
} else {
    fmt.Printf("Retrieved: %v\n", value)
}

// Check if Redis is healthy
if hybridClient.IsRedisHealthy() {
    fmt.Println("Redis is healthy")
} else {
    fmt.Println("Using fallback cache")
}
```plaintext
### Configuration Validation

```go
import redisconfig "email_sender/pkg/cache/redis"

config := &redisconfig.RedisConfig{
    Host:     "localhost",
    Port:     6379,
    Password: "secret",
    DB:       0,
    // ... other fields
}

// Validate configuration
validator := redisconfig.NewConfigValidator()
if err := validator.Validate(config); err != nil {
    log.Fatalf("Invalid configuration: %v", err)
}

// Convert to Redis options
opts := config.ToRedisOptions()
client := redis.NewClient(opts)
```plaintext
### Circuit Breaker Usage

```go
import redisconfig "email_sender/pkg/cache/redis"

// Create circuit breaker with custom config
cbConfig := &redisconfig.CircuitBreakerConfig{
    MaxFailures:      5,
    ResetTimeout:     30 * time.Second,
    CheckInterval:    10 * time.Second,
    SuccessThreshold: 2,
}

cb := redisconfig.NewCircuitBreaker(cbConfig, nil)

// Execute operations with circuit breaker protection
err := cb.Execute(func() error {
    // Your Redis operation here
    return client.Ping(ctx).Err()
})

if err != nil {
    log.Printf("Operation failed: %v", err)
}

// Check circuit breaker state
fmt.Printf("Circuit Breaker State: %s\n", cb.State())
stats := cb.Stats()
fmt.Printf("Circuit Breaker Stats: %+v\n", stats)
```plaintext
## Configuration Options

### RedisConfig Structure

```go
type RedisConfig struct {
    // Basic connection
    Host     string `json:"host"`
    Port     int    `json:"port"`
    Password string `json:"password"`
    DB       int    `json:"db"`

    // Timeouts (Plan v39 specifications)
    DialTimeout  time.Duration `json:"dial_timeout"`  // 5s
    ReadTimeout  time.Duration `json:"read_timeout"`  // 3s
    WriteTimeout time.Duration `json:"write_timeout"` // 3s

    // TLS/SSL
    TLSEnabled    bool   `json:"tls_enabled"`
    TLSSkipVerify bool   `json:"tls_skip_verify"`
    TLSCertFile   string `json:"tls_cert_file"`
    TLSKeyFile    string `json:"tls_key_file"`
    TLSCAFile     string `json:"tls_ca_file"`

    // Retry configuration (Plan v39)
    MaxRetries      int           `json:"max_retries"`        // 3
    MinRetryBackoff time.Duration `json:"min_retry_backoff"` // 1s
    MaxRetryBackoff time.Duration `json:"max_retry_backoff"` // 3s

    // Connection pool (Plan v39)
    PoolSize           int           `json:"pool_size"`            // 10
    MinIdleConns       int           `json:"min_idle_conns"`       // 5
    PoolTimeout        time.Duration `json:"pool_timeout"`         // 4s
    MaxConnAge         time.Duration `json:"max_conn_age"`
    IdleTimeout        time.Duration `json:"idle_timeout"`
    IdleCheckFrequency time.Duration `json:"idle_check_frequency"`

    // Health checking (Plan v39)
    HealthCheckInterval time.Duration `json:"health_check_interval"` // 30s
}
```plaintext
## Testing

### Run Unit Tests

```bash
go test ./pkg/cache/redis -v
```plaintext
### Run Integration Tests

```bash
# Test with Redis server

go run ./cmd/redis-test -host localhost -port 6379

# Test fallback functionality

go run ./cmd/redis-fallback-test
```plaintext
## Architecture

The Redis configuration system is built with a modular architecture:

1. **RedisConfig**: Core configuration management
2. **ConfigValidator**: Configuration validation with network checks
3. **ErrorHandler**: Error classification and handling
4. **CircuitBreaker**: Circuit breaker pattern implementation
5. **ReconnectionManager**: Exponential backoff reconnection logic
6. **HealthChecker**: Continuous health monitoring
7. **LocalCache**: In-memory fallback cache
8. **HybridRedisClient**: Intelligent client with automatic fallback

## Compliance with Plan v39

This implementation fully complies with Section 1.3.1.1 of Plan v39:

- ✅ **Configuration Parameters**: All specified timeouts and pool settings
- ✅ **SSL/TLS Support**: Production-ready SSL configuration
- ✅ **Retry Mechanism**: Configurable retry with exponential backoff
- ✅ **Connection Pooling**: Optimized pool configuration
- ✅ **Health Checking**: Automatic ping every 30 seconds
- ✅ **Circuit Breaker**: Fault tolerance pattern
- ✅ **Error Handling**: Comprehensive error classification
- ✅ **Fallback Cache**: Local cache when Redis unavailable
- ✅ **Validation**: Complete configuration validation

## Dependencies

- `github.com/redis/go-redis/v9`: Redis client library
- Go standard library packages for networking, context, time, etc.

## Files Structure

```plaintext
pkg/cache/redis/
├── client.go              # Core Redis configuration

├── config_validator.go    # Configuration validation

├── error_handler.go       # Error handling and circuit breaker

├── reconnection_manager.go # Reconnection with health checking

├── fallback_cache.go      # Local cache and hybrid client

└── redis_test.go          # Comprehensive unit tests

pkg/cache/
└── redis_client.go        # Main Redis client wrapper

cmd/
├── redis-test/            # Redis connection testing tool

└── redis-fallback-test/   # Fallback functionality test

```plaintext