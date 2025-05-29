// Package redis provides Redis client configuration and connection management
package redis

import (
	"context"
	"crypto/tls"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// RedisConfig represents the Redis connection configuration
type RedisConfig struct {
	Host     string `json:"host" yaml:"host"`
	Port     int    `json:"port" yaml:"port"`
	Password string `json:"password" yaml:"password"`
	DB       int    `json:"db" yaml:"db"`

	// Connection options with timeouts specified (Plan v39)
	DialTimeout  time.Duration `json:"dial_timeout" yaml:"dial_timeout"`
	ReadTimeout  time.Duration `json:"read_timeout" yaml:"read_timeout"`
	WriteTimeout time.Duration `json:"write_timeout" yaml:"write_timeout"`

	// SSL/TLS configuration for production
	TLSEnabled    bool   `json:"tls_enabled" yaml:"tls_enabled"`
	TLSSkipVerify bool   `json:"tls_skip_verify" yaml:"tls_skip_verify"`
	TLSCertFile   string `json:"tls_cert_file" yaml:"tls_cert_file"`
	TLSKeyFile    string `json:"tls_key_file" yaml:"tls_key_file"`
	TLSCAFile     string `json:"tls_ca_file" yaml:"tls_ca_file"`

	// Retry parameters (MaxRetries=3, RetryDelay=1s)
	MaxRetries      int           `json:"max_retries" yaml:"max_retries"`
	MinRetryBackoff time.Duration `json:"min_retry_backoff" yaml:"min_retry_backoff"`
	MaxRetryBackoff time.Duration `json:"max_retry_backoff" yaml:"max_retry_backoff"`

	// Connection pool configuration (PoolSize=10, MinIdleConns=5, PoolTimeout=4s, etc.)
	PoolSize           int           `json:"pool_size" yaml:"pool_size"`
	MinIdleConns       int           `json:"min_idle_conns" yaml:"min_idle_conns"`
	MaxConnAge         time.Duration `json:"max_conn_age" yaml:"max_conn_age"`
	PoolTimeout        time.Duration `json:"pool_timeout" yaml:"pool_timeout"`
	IdleTimeout        time.Duration `json:"idle_timeout" yaml:"idle_timeout"`
	IdleCheckFrequency time.Duration `json:"idle_check_frequency" yaml:"idle_check_frequency"`

	// HealthChecker with ping every 30 seconds
	HealthCheckInterval time.Duration `json:"health_check_interval" yaml:"health_check_interval"`
}

// DefaultRedisConfig returns a default Redis configuration following Plan v39 specifications
func DefaultRedisConfig() *RedisConfig {
	return &RedisConfig{
		Host:     "localhost",
		Port:     6379,
		Password: "",
		DB:       0,

		// Connection timeouts as specified in the plan (DialTimeout=5s, ReadTimeout=3s)
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,

		// TLS disabled by default
		TLSEnabled:    false,
		TLSSkipVerify: false,

		// Retry configuration as specified (MaxRetries=3, RetryDelay=1s)
		MaxRetries:      3,
		MinRetryBackoff: 1 * time.Second,
		MaxRetryBackoff: 3 * time.Second,

		// Connection pool configuration as specified (PoolSize=10, MinIdleConns=5, PoolTimeout=4s)
		PoolSize:           10,                // PoolSize=10
		MinIdleConns:       5,                 // MinIdleConns=5
		MaxConnAge:         0,                 // MaxConnAge=0 for persistent connections
		PoolTimeout:        4 * time.Second,   // PoolTimeout=4s to avoid blocking
		IdleTimeout:        300 * time.Second, // IdleTimeout=300s to free inactive connections
		IdleCheckFrequency: 60 * time.Second,  // IdleCheckFrequency=60s for automatic maintenance

		// HealthChecker with ping every 30 seconds (Plan v39)
		HealthCheckInterval: 30 * time.Second,
	}
}

// Validate validates the Redis configuration
func (c *RedisConfig) Validate() error {
	if c.Host == "" {
		return fmt.Errorf("redis host cannot be empty")
	}

	if c.Port <= 0 || c.Port > 65535 {
		return fmt.Errorf("redis port must be between 1 and 65535, got %d", c.Port)
	}

	if c.DB < 0 || c.DB > 15 {
		return fmt.Errorf("redis database must be between 0 and 15, got %d", c.DB)
	}

	if c.PoolSize <= 0 {
		return fmt.Errorf("pool size must be greater than 0, got %d", c.PoolSize)
	}

	if c.MinIdleConns < 0 {
		return fmt.Errorf("min idle connections cannot be negative, got %d", c.MinIdleConns)
	}

	if c.MinIdleConns > c.PoolSize {
		return fmt.Errorf("min idle connections (%d) cannot be greater than pool size (%d)", c.MinIdleConns, c.PoolSize)
	}

	if c.MaxRetries < 0 {
		return fmt.Errorf("max retries cannot be negative, got %d", c.MaxRetries)
	}

	return nil
}

// ToRedisOptions converts RedisConfig to redis.Options
func (c *RedisConfig) ToRedisOptions() *redis.Options {
	opts := &redis.Options{
		Addr:     fmt.Sprintf("%s:%d", c.Host, c.Port),
		Password: c.Password,
		DB:       c.DB,

		// Connection timeouts
		DialTimeout:  c.DialTimeout,
		ReadTimeout:  c.ReadTimeout,
		WriteTimeout: c.WriteTimeout,

		// Retry configuration
		MaxRetries:      c.MaxRetries,
		MinRetryBackoff: c.MinRetryBackoff,
		MaxRetryBackoff: c.MaxRetryBackoff,
		// Connection pool
		PoolSize:     c.PoolSize,
		MinIdleConns: c.MinIdleConns,
		PoolTimeout:  c.PoolTimeout,
	}

	// Configure TLS if enabled
	if c.TLSEnabled {
		tlsConfig := &tls.Config{
			InsecureSkipVerify: c.TLSSkipVerify,
		}

		// Load client certificates if provided
		if c.TLSCertFile != "" && c.TLSKeyFile != "" {
			cert, err := tls.LoadX509KeyPair(c.TLSCertFile, c.TLSKeyFile)
			if err == nil {
				tlsConfig.Certificates = []tls.Certificate{cert}
			}
		}

		opts.TLSConfig = tlsConfig
	}

	return opts
}

// Address returns the Redis server address
func (c *RedisConfig) Address() string {
	return fmt.Sprintf("%s:%d", c.Host, c.Port)
}

// String returns a string representation of the config (without sensitive data)
func (c *RedisConfig) String() string {
	return fmt.Sprintf("RedisConfig{Host: %s, Port: %d, DB: %d, TLS: %v, PoolSize: %d}",
		c.Host, c.Port, c.DB, c.TLSEnabled, c.PoolSize)
}

// Clone creates a deep copy of the RedisConfig
func (c *RedisConfig) Clone() *RedisConfig {
	clone := *c
	return &clone
}

// CreateClient creates a new Redis client using this configuration
func (c *RedisConfig) CreateClient() (*redis.Client, error) {
	if err := c.Validate(); err != nil {
		return nil, fmt.Errorf("invalid configuration: %w", err)
	}

	opts := c.ToRedisOptions()
	client := redis.NewClient(opts)

	// Test connection
	ctx := context.Background()
	if err := client.Ping(ctx).Err(); err != nil {
		client.Close()
		return nil, fmt.Errorf("failed to connect to Redis: %w", err)
	}

	return client, nil
}
