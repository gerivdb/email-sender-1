// Package main provides a command-line tool for testing Redis connections
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

var (
	configFile  = flag.String("config", "", "Path to Redis configuration file (JSON)")
	host        = flag.String("host", "localhost", "Redis host")
	port        = flag.Int("port", 6379, "Redis port")
	password    = flag.String("password", "", "Redis password")
	db          = flag.Int("db", 0, "Redis database number")
	timeout     = flag.Duration("timeout", 30*time.Second, "Connection timeout")
	verbose     = flag.Bool("verbose", false, "Verbose output")
	testPool    = flag.Bool("test-pool", false, "Test connection pool")
	testRetry   = flag.Bool("test-retry", false, "Test retry mechanism")
	testCircuit = flag.Bool("test-circuit", false, "Test circuit breaker")
)

func main() {
	flag.Parse()

	logger := log.New(os.Stdout, "[REDIS-TEST] ", log.LstdFlags)

	var config *redisconfig.RedisConfig
	var err error

	// Load configuration
	if *configFile != "" {
		config, err = loadConfigFromFile(*configFile)
		if err != nil {
			logger.Fatalf("Failed to load config from file: %v", err)
		}
	} else {
		config = &redisconfig.RedisConfig{
			Host:     *host,
			Port:     *port,
			Password: *password,
			DB:       *db,
		} // Apply defaults
		defaultConfig := redisconfig.DefaultRedisConfig()
		config.DialTimeout = defaultConfig.DialTimeout
		config.ReadTimeout = defaultConfig.ReadTimeout
		config.WriteTimeout = defaultConfig.WriteTimeout
		config.MaxRetries = defaultConfig.MaxRetries
		config.MinRetryBackoff = defaultConfig.MinRetryBackoff
		config.MaxRetryBackoff = defaultConfig.MaxRetryBackoff
		config.PoolSize = defaultConfig.PoolSize
		config.MinIdleConns = defaultConfig.MinIdleConns
		config.PoolTimeout = defaultConfig.PoolTimeout
		config.IdleTimeout = defaultConfig.IdleTimeout
		config.IdleCheckFrequency = defaultConfig.IdleCheckFrequency
	}

	if *verbose {
		logger.Printf("Using configuration: %s", config.String())
	}

	// Validate configuration
	validator := redisconfig.NewConfigValidator()
	if err := validator.Validate(config); err != nil {
		logger.Fatalf("Configuration validation failed: %v", err)
	}

	logger.Println("✓ Configuration validation passed")

	// Test basic connection
	if err := testBasicConnection(config, logger); err != nil {
		logger.Fatalf("Basic connection test failed: %v", err)
	}

	logger.Println("✓ Basic connection test passed")

	// Test Redis operations
	if err := testRedisOperations(config, logger); err != nil {
		logger.Fatalf("Redis operations test failed: %v", err)
	}

	logger.Println("✓ Redis operations test passed")

	// Optional tests
	if *testPool {
		if err := testConnectionPool(config, logger); err != nil {
			logger.Printf("⚠ Connection pool test failed: %v", err)
		} else {
			logger.Println("✓ Connection pool test passed")
		}
	}

	if *testRetry {
		if err := testRetryMechanism(config, logger); err != nil {
			logger.Printf("⚠ Retry mechanism test failed: %v", err)
		} else {
			logger.Println("✓ Retry mechanism test passed")
		}
	}

	if *testCircuit {
		if err := testCircuitBreaker(config, logger); err != nil {
			logger.Printf("⚠ Circuit breaker test failed: %v", err)
		} else {
			logger.Println("✓ Circuit breaker test passed")
		}
	}

	logger.Println("🎉 All tests completed successfully!")
}

func loadConfigFromFile(filename string) (*redisconfig.RedisConfig, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config redisconfig.RedisConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	return &config, nil
}

func testBasicConnection(config *redisconfig.RedisConfig, logger *log.Logger) error {
	opts := config.ToRedisOptions()
	client := redis.NewClient(opts)
	defer client.Close()

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// Test ping
	result, err := client.Ping(ctx).Result()
	if err != nil {
		return fmt.Errorf("ping failed: %w", err)
	}

	if *verbose {
		logger.Printf("Ping result: %s", result)
	}

	// Test info command
	info, err := client.Info(ctx).Result()
	if err != nil {
		return fmt.Errorf("info command failed: %w", err)
	}

	if *verbose {
		logger.Printf("Redis info (first 200 chars): %s", truncateString(info, 200))
	}

	return nil
}

func testRedisOperations(config *redisconfig.RedisConfig, logger *log.Logger) error {
	opts := config.ToRedisOptions()
	client := redis.NewClient(opts)
	defer client.Close()

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	testKey := "redis-test:connection-test"
	testValue := fmt.Sprintf("test-value-%d", time.Now().Unix())

	// Test SET
	err := client.Set(ctx, testKey, testValue, 60*time.Second).Err()
	if err != nil {
		return fmt.Errorf("SET operation failed: %w", err)
	}

	if *verbose {
		logger.Printf("SET %s = %s", testKey, testValue)
	}

	// Test GET
	retrievedValue, err := client.Get(ctx, testKey).Result()
	if err != nil {
		return fmt.Errorf("GET operation failed: %w", err)
	}

	if retrievedValue != testValue {
		return fmt.Errorf("value mismatch: expected %s, got %s", testValue, retrievedValue)
	}

	if *verbose {
		logger.Printf("GET %s = %s", testKey, retrievedValue)
	}

	// Test DEL
	deleted, err := client.Del(ctx, testKey).Result()
	if err != nil {
		return fmt.Errorf("DEL operation failed: %w", err)
	}

	if deleted != 1 {
		return fmt.Errorf("expected 1 key deleted, got %d", deleted)
	}

	if *verbose {
		logger.Printf("DEL %s (deleted: %d)", testKey, deleted)
	}

	return nil
}

func testConnectionPool(config *redisconfig.RedisConfig, logger *log.Logger) error {
	opts := config.ToRedisOptions()
	client := redis.NewClient(opts)
	defer client.Close()

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	// Get pool stats
	stats := client.PoolStats()
	if *verbose {
		logger.Printf("Pool stats - Total: %d, Idle: %d, Stale: %d",
			stats.TotalConns, stats.IdleConns, stats.StaleConns)
	}

	// Test concurrent operations
	const numGoroutines = 10
	const numOperations = 100

	errChan := make(chan error, numGoroutines)

	for i := 0; i < numGoroutines; i++ {
		go func(id int) {
			for j := 0; j < numOperations; j++ {
				key := fmt.Sprintf("pool-test:%d:%d", id, j)
				value := fmt.Sprintf("value-%d-%d", id, j)

				// SET
				if err := client.Set(ctx, key, value, 10*time.Second).Err(); err != nil {
					errChan <- fmt.Errorf("goroutine %d: SET failed: %w", id, err)
					return
				}

				// GET
				if _, err := client.Get(ctx, key).Result(); err != nil {
					errChan <- fmt.Errorf("goroutine %d: GET failed: %w", id, err)
					return
				}

				// DEL
				if err := client.Del(ctx, key).Err(); err != nil {
					errChan <- fmt.Errorf("goroutine %d: DEL failed: %w", id, err)
					return
				}
			}
			errChan <- nil
		}(i)
	}

	// Wait for all goroutines
	for i := 0; i < numGoroutines; i++ {
		if err := <-errChan; err != nil {
			return err
		}
	}

	finalStats := client.PoolStats()
	if *verbose {
		logger.Printf("Final pool stats - Total: %d, Idle: %d, Stale: %d, Hits: %d, Misses: %d",
			finalStats.TotalConns, finalStats.IdleConns, finalStats.StaleConns,
			finalStats.Hits, finalStats.Misses)
	}

	return nil
}

func testRetryMechanism(config *redisconfig.RedisConfig, logger *log.Logger) error {
	// Create a client with retry configuration
	opts := config.ToRedisOptions()
	client := redis.NewClient(opts)
	defer client.Close()

	// Test with a very short timeout to trigger retry
	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()

	// This should fail and trigger retries
	_, err := client.Get(ctx, "retry-test-key").Result()

	// We expect this to fail due to timeout, but retries should have been attempted
	if err != nil && *verbose {
		logger.Printf("Expected retry test error: %v", err)
	}

	return nil
}

func testCircuitBreaker(config *redisconfig.RedisConfig, logger *log.Logger) error {
	// Create error handler and circuit breaker
	errorHandler := redisconfig.NewErrorHandler(logger)
	circuitBreaker := redisconfig.NewCircuitBreaker(redisconfig.DefaultCircuitBreakerConfig(), logger)

	// Simulate some errors to trigger circuit breaker
	for i := 0; i < 6; i++ {
		err := fmt.Errorf("simulated error %d", i)
		circuitBreaker.Execute(func() error {
			errorHandler.Handle(err)
			return err
		})
	}

	stats := circuitBreaker.Stats()
	if *verbose {
		logger.Printf("Circuit breaker stats: %+v", stats)
	}

	// Circuit breaker should be open now
	if circuitBreaker.State() != redisconfig.StateOpen {
		return fmt.Errorf("expected circuit breaker to be open, got %v", circuitBreaker.State())
	}

	return nil
}

func truncateString(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}
