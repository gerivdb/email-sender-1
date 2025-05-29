// Package redis provides configuration validation functionality
package redis

import (
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"
	"time"
)

// ConfigValidator validates Redis configuration
type ConfigValidator struct {
	// Additional validation rules can be added here
}

// NewConfigValidator creates a new configuration validator
func NewConfigValidator() *ConfigValidator {
	return &ConfigValidator{}
}

// Validate validates a Redis configuration
func (cv *ConfigValidator) Validate(config *RedisConfig) error {
	if config == nil {
		return fmt.Errorf("config cannot be nil")
	}

	// Validate basic configuration
	if err := cv.validateBasicConfig(config); err != nil {
		return fmt.Errorf("basic config validation failed: %w", err)
	}

	// Validate connection parameters
	if err := cv.validateConnectionParams(config); err != nil {
		return fmt.Errorf("connection params validation failed: %w", err)
	}

	// Validate TLS configuration
	if err := cv.validateTLSConfig(config); err != nil {
		return fmt.Errorf("TLS config validation failed: %w", err)
	}

	// Validate retry configuration
	if err := cv.validateRetryConfig(config); err != nil {
		return fmt.Errorf("retry config validation failed: %w", err)
	}

	// Validate pool configuration
	if err := cv.validatePoolConfig(config); err != nil {
		return fmt.Errorf("pool config validation failed: %w", err)
	}

	// Validate timeouts
	if err := cv.validateTimeouts(config); err != nil {
		return fmt.Errorf("timeout validation failed: %w", err)
	}

	return nil
}

// validateBasicConfig validates basic Redis configuration
func (cv *ConfigValidator) validateBasicConfig(config *RedisConfig) error {
	// Validate host
	if config.Host == "" {
		return fmt.Errorf("host cannot be empty")
	}

	// Check if host is a valid hostname or IP
	if !cv.isValidHostname(config.Host) && net.ParseIP(config.Host) == nil {
		return fmt.Errorf("invalid host format: %s", config.Host)
	}

	// Validate port
	if config.Port <= 0 || config.Port > 65535 {
		return fmt.Errorf("port must be between 1 and 65535, got %d", config.Port)
	}

	// Validate database number
	if config.DB < 0 || config.DB > 15 {
		return fmt.Errorf("database number must be between 0 and 15, got %d", config.DB)
	}

	return nil
}

// validateConnectionParams validates connection parameters
func (cv *ConfigValidator) validateConnectionParams(config *RedisConfig) error {
	// Test network connectivity if host is not localhost
	if config.Host != "localhost" && config.Host != "127.0.0.1" && config.Host != "::1" {
		if err := cv.testNetworkConnectivity(config.Host, config.Port); err != nil {
			return fmt.Errorf("network connectivity test failed: %w", err)
		}
	}

	return nil
}

// validateTLSConfig validates TLS configuration
func (cv *ConfigValidator) validateTLSConfig(config *RedisConfig) error {
	if !config.TLSEnabled {
		return nil // TLS not enabled, skip validation
	}

	// If TLS is enabled, validate certificate files if provided
	if config.TLSCertFile != "" {
		if _, err := os.Stat(config.TLSCertFile); os.IsNotExist(err) {
			return fmt.Errorf("TLS certificate file not found: %s", config.TLSCertFile)
		}
	}

	if config.TLSKeyFile != "" {
		if _, err := os.Stat(config.TLSKeyFile); os.IsNotExist(err) {
			return fmt.Errorf("TLS key file not found: %s", config.TLSKeyFile)
		}
	}

	if config.TLSCAFile != "" {
		if _, err := os.Stat(config.TLSCAFile); os.IsNotExist(err) {
			return fmt.Errorf("TLS CA file not found: %s", config.TLSCAFile)
		}
	}

	// Both cert and key must be provided together
	if (config.TLSCertFile != "" && config.TLSKeyFile == "") ||
		(config.TLSCertFile == "" && config.TLSKeyFile != "") {
		return fmt.Errorf("both TLS cert file and key file must be provided together")
	}

	return nil
}

// validateRetryConfig validates retry configuration
func (cv *ConfigValidator) validateRetryConfig(config *RedisConfig) error {
	if config.MaxRetries < 0 {
		return fmt.Errorf("max retries cannot be negative, got %d", config.MaxRetries)
	}

	if config.MinRetryBackoff < 0 {
		return fmt.Errorf("min retry backoff cannot be negative, got %v", config.MinRetryBackoff)
	}

	if config.MaxRetryBackoff < 0 {
		return fmt.Errorf("max retry backoff cannot be negative, got %v", config.MaxRetryBackoff)
	}

	if config.MinRetryBackoff > config.MaxRetryBackoff {
		return fmt.Errorf("min retry backoff (%v) cannot be greater than max retry backoff (%v)",
			config.MinRetryBackoff, config.MaxRetryBackoff)
	}

	return nil
}

// validatePoolConfig validates connection pool configuration
func (cv *ConfigValidator) validatePoolConfig(config *RedisConfig) error {
	if config.PoolSize <= 0 {
		return fmt.Errorf("pool size must be greater than 0, got %d", config.PoolSize)
	}

	if config.MinIdleConns < 0 {
		return fmt.Errorf("min idle connections cannot be negative, got %d", config.MinIdleConns)
	}

	if config.MinIdleConns > config.PoolSize {
		return fmt.Errorf("min idle connections (%d) cannot be greater than pool size (%d)",
			config.MinIdleConns, config.PoolSize)
	}

	if config.MaxConnAge < 0 {
		return fmt.Errorf("max connection age cannot be negative, got %v", config.MaxConnAge)
	}

	if config.PoolTimeout <= 0 {
		return fmt.Errorf("pool timeout must be greater than 0, got %v", config.PoolTimeout)
	}

	if config.IdleTimeout < 0 {
		return fmt.Errorf("idle timeout cannot be negative, got %v", config.IdleTimeout)
	}

	if config.IdleCheckFrequency <= 0 {
		return fmt.Errorf("idle check frequency must be greater than 0, got %v", config.IdleCheckFrequency)
	}

	return nil
}

// validateTimeouts validates timeout configurations
func (cv *ConfigValidator) validateTimeouts(config *RedisConfig) error {
	if config.DialTimeout <= 0 {
		return fmt.Errorf("dial timeout must be greater than 0, got %v", config.DialTimeout)
	}

	if config.ReadTimeout <= 0 {
		return fmt.Errorf("read timeout must be greater than 0, got %v", config.ReadTimeout)
	}

	if config.WriteTimeout <= 0 {
		return fmt.Errorf("write timeout must be greater than 0, got %v", config.WriteTimeout)
	}

	// Reasonable timeout limits
	maxTimeout := 5 * time.Minute
	if config.DialTimeout > maxTimeout {
		return fmt.Errorf("dial timeout too high (max %v), got %v", maxTimeout, config.DialTimeout)
	}

	if config.ReadTimeout > maxTimeout {
		return fmt.Errorf("read timeout too high (max %v), got %v", maxTimeout, config.ReadTimeout)
	}

	if config.WriteTimeout > maxTimeout {
		return fmt.Errorf("write timeout too high (max %v), got %v", maxTimeout, config.WriteTimeout)
	}

	return nil
}

// isValidHostname checks if a string is a valid hostname
func (cv *ConfigValidator) isValidHostname(hostname string) bool {
	if len(hostname) == 0 || len(hostname) > 253 {
		return false
	}

	// Check for valid characters
	for _, char := range hostname {
		if !((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') ||
			(char >= '0' && char <= '9') || char == '-' || char == '.') {
			return false
		}
	}

	// Split by dots and validate each label
	labels := strings.Split(hostname, ".")
	for _, label := range labels {
		if len(label) == 0 || len(label) > 63 {
			return false
		}
		// Label cannot start or end with hyphen
		if strings.HasPrefix(label, "-") || strings.HasSuffix(label, "-") {
			return false
		}
	}

	return true
}

// testNetworkConnectivity tests if the Redis server is reachable
func (cv *ConfigValidator) testNetworkConnectivity(host string, port int) error {
	address := net.JoinHostPort(host, strconv.Itoa(port))
	conn, err := net.DialTimeout("tcp", address, 3*time.Second)
	if err != nil {
		return fmt.Errorf("cannot connect to %s: %w", address, err)
	}
	defer conn.Close()
	return nil
}

// ValidateFromEnvironment validates configuration loaded from environment variables
func (cv *ConfigValidator) ValidateFromEnvironment() (*RedisConfig, error) {
	config := DefaultRedisConfig()

	// Load from environment variables
	if host := os.Getenv("REDIS_HOST"); host != "" {
		config.Host = host
	}

	if portStr := os.Getenv("REDIS_PORT"); portStr != "" {
		port, err := strconv.Atoi(portStr)
		if err != nil {
			return nil, fmt.Errorf("invalid REDIS_PORT: %w", err)
		}
		config.Port = port
	}

	if password := os.Getenv("REDIS_PASSWORD"); password != "" {
		config.Password = password
	}

	if dbStr := os.Getenv("REDIS_DB"); dbStr != "" {
		db, err := strconv.Atoi(dbStr)
		if err != nil {
			return nil, fmt.Errorf("invalid REDIS_DB: %w", err)
		}
		config.DB = db
	}

	// TLS configuration
	if tlsEnabledStr := os.Getenv("REDIS_TLS_ENABLED"); tlsEnabledStr != "" {
		tlsEnabled, err := strconv.ParseBool(tlsEnabledStr)
		if err != nil {
			return nil, fmt.Errorf("invalid REDIS_TLS_ENABLED: %w", err)
		}
		config.TLSEnabled = tlsEnabled
	}

	if tlsSkipVerifyStr := os.Getenv("REDIS_TLS_SKIP_VERIFY"); tlsSkipVerifyStr != "" {
		tlsSkipVerify, err := strconv.ParseBool(tlsSkipVerifyStr)
		if err != nil {
			return nil, fmt.Errorf("invalid REDIS_TLS_SKIP_VERIFY: %w", err)
		}
		config.TLSSkipVerify = tlsSkipVerify
	}

	if certFile := os.Getenv("REDIS_TLS_CERT_FILE"); certFile != "" {
		config.TLSCertFile = certFile
	}

	if keyFile := os.Getenv("REDIS_TLS_KEY_FILE"); keyFile != "" {
		config.TLSKeyFile = keyFile
	}

	if caFile := os.Getenv("REDIS_TLS_CA_FILE"); caFile != "" {
		config.TLSCAFile = caFile
	}

	// Pool configuration
	if poolSizeStr := os.Getenv("REDIS_POOL_SIZE"); poolSizeStr != "" {
		poolSize, err := strconv.Atoi(poolSizeStr)
		if err != nil {
			return nil, fmt.Errorf("invalid REDIS_POOL_SIZE: %w", err)
		}
		config.PoolSize = poolSize
	}

	if minIdleConnsStr := os.Getenv("REDIS_MIN_IDLE_CONNS"); minIdleConnsStr != "" {
		minIdleConns, err := strconv.Atoi(minIdleConnsStr)
		if err != nil {
			return nil, fmt.Errorf("invalid REDIS_MIN_IDLE_CONNS: %w", err)
		}
		config.MinIdleConns = minIdleConns
	}

	// Validate the configuration
	if err := cv.Validate(config); err != nil {
		return nil, fmt.Errorf("configuration validation failed: %w", err)
	}

	return config, nil
}
