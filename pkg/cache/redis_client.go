package cache

import (
	"context"
	"fmt"
	"time"

	redisconfig "email_sender/pkg/cache/redis"

	"github.com/redis/go-redis/v9"
)

type RedisClient struct {
	client         *redis.Client
	config         *redisconfig.RedisConfig
	errorHandler   *redisconfig.ErrorHandler
	circuitBreaker *redisconfig.CircuitBreaker
	healthChecker  *redisconfig.HealthChecker
}

// NewRedisClient initializes a new Redis client with advanced configuration
func NewRedisClient(config *redisconfig.RedisConfig) (*RedisClient, error) {
	if config == nil {
		config = redisconfig.DefaultRedisConfig()
	}

	// Validate configuration
	validator := redisconfig.NewConfigValidator()
	if err := validator.Validate(config); err != nil {
		return nil, fmt.Errorf("invalid Redis configuration: %w", err)
	}

	// Create Redis client with configured options
	opts := config.ToRedisOptions()
	client := redis.NewClient(opts)

	// Test connection
	ctx, cancel := context.WithTimeout(context.Background(), config.DialTimeout)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		client.Close()
		return nil, fmt.Errorf("failed to connect to Redis: %w", err)
	} // Create error handler, circuit breaker and health checker
	errorHandler := redisconfig.NewErrorHandler(nil)
	circuitBreaker := redisconfig.NewCircuitBreaker(redisconfig.DefaultCircuitBreakerConfig(), nil)
	healthChecker := redisconfig.NewHealthChecker(client, config.HealthCheckInterval, 5*time.Second, nil)
	redisClient := &RedisClient{
		client:         client,
		config:         config,
		errorHandler:   errorHandler,
		circuitBreaker: circuitBreaker,
		healthChecker:  healthChecker,
	}

	// Start health checker
	healthChecker.Start()

	return redisClient, nil
}

// NewRedisClientFromDefaults creates a Redis client with default configuration
func NewRedisClientFromDefaults(host string, port int, password string, db int) (*RedisClient, error) {
	config := redisconfig.DefaultRedisConfig()
	config.Host = host
	config.Port = port
	config.Password = password
	config.DB = db

	return NewRedisClient(config)
}

// Set sets a key-value pair in Redis
func (r *RedisClient) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	return r.client.Set(ctx, key, value, ttl).Err()
}

// Get retrieves a value by key from Redis
func (r *RedisClient) Get(ctx context.Context, key string) (string, error) {
	return r.client.Get(ctx, key).Result()
}

// Delete removes a key from Redis
func (r *RedisClient) Delete(ctx context.Context, key string) error {
	return r.client.Del(ctx, key).Err()
}

// Close closes the Redis client and stops health checker
func (r *RedisClient) Close() error {
	if r.healthChecker != nil {
		r.healthChecker.Stop()
	}
	if r.client != nil {
		return r.client.Close()
	}
	return nil
}

// GetConfig returns the Redis configuration
func (r *RedisClient) GetConfig() *redisconfig.RedisConfig {
	return r.config
}

// IsHealthy returns true if the Redis connection is healthy
func (r *RedisClient) IsHealthy() bool {
	if r.healthChecker != nil {
		return r.healthChecker.IsHealthy()
	}
	return false
}

// GetStats returns Redis client statistics
func (r *RedisClient) GetStats() map[string]interface{} {
	stats := make(map[string]interface{})

	if r.client != nil {
		poolStats := r.client.PoolStats()
		stats["pool"] = map[string]interface{}{
			"hits":        poolStats.Hits,
			"misses":      poolStats.Misses,
			"timeouts":    poolStats.Timeouts,
			"total_conns": poolStats.TotalConns,
			"idle_conns":  poolStats.IdleConns,
			"stale_conns": poolStats.StaleConns,
		}
	}
	if r.circuitBreaker != nil {
		stats["circuit_breaker"] = r.circuitBreaker.Stats()
	}

	if r.healthChecker != nil {
		stats["health"] = map[string]interface{}{
			"is_healthy":    r.healthChecker.IsHealthy(),
			"last_check":    r.healthChecker.LastCheck(),
			"check_count":   r.healthChecker.GetCheckCount(),
			"failure_count": r.healthChecker.GetFailureCount(),
		}
	}

	return stats
}

// Ping tests the Redis connection
func (r *RedisClient) Ping(ctx context.Context) error {
	return r.circuitBreaker.Execute(func() error {
		err := r.client.Ping(ctx).Err()
		if err != nil {
			r.errorHandler.Handle(err)
		}
		return err
	})
}
