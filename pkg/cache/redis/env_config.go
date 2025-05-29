package redis

import (
	"os"
	"strconv"
	"time"
)

// LoadFromEnv loads Redis configuration from environment variables
// This method populates the configuration fields from standard environment variables
func (c *RedisConfig) LoadFromEnv() error {
	// Basic connection settings
	if host := os.Getenv("REDIS_HOST"); host != "" {
		c.Host = host
	}

	if portStr := os.Getenv("REDIS_PORT"); portStr != "" {
		if port, err := strconv.Atoi(portStr); err == nil {
			c.Port = port
		}
	}

	if password := os.Getenv("REDIS_PASSWORD"); password != "" {
		c.Password = password
	}

	if dbStr := os.Getenv("REDIS_DB"); dbStr != "" {
		if db, err := strconv.Atoi(dbStr); err == nil {
			c.DB = db
		}
	}

	// Timeout settings
	if dialTimeoutStr := os.Getenv("REDIS_DIAL_TIMEOUT"); dialTimeoutStr != "" {
		if dialTimeout, err := time.ParseDuration(dialTimeoutStr); err == nil {
			c.DialTimeout = dialTimeout
		}
	}

	if readTimeoutStr := os.Getenv("REDIS_READ_TIMEOUT"); readTimeoutStr != "" {
		if readTimeout, err := time.ParseDuration(readTimeoutStr); err == nil {
			c.ReadTimeout = readTimeout
		}
	}

	if writeTimeoutStr := os.Getenv("REDIS_WRITE_TIMEOUT"); writeTimeoutStr != "" {
		if writeTimeout, err := time.ParseDuration(writeTimeoutStr); err == nil {
			c.WriteTimeout = writeTimeout
		}
	}

	// TLS settings
	if tlsEnabledStr := os.Getenv("REDIS_TLS_ENABLED"); tlsEnabledStr != "" {
		if tlsEnabled, err := strconv.ParseBool(tlsEnabledStr); err == nil {
			c.TLSEnabled = tlsEnabled
		}
	}

	if tlsSkipVerifyStr := os.Getenv("REDIS_TLS_SKIP_VERIFY"); tlsSkipVerifyStr != "" {
		if tlsSkipVerify, err := strconv.ParseBool(tlsSkipVerifyStr); err == nil {
			c.TLSSkipVerify = tlsSkipVerify
		}
	}

	if tlsCertFile := os.Getenv("REDIS_TLS_CERT_FILE"); tlsCertFile != "" {
		c.TLSCertFile = tlsCertFile
	}

	if tlsKeyFile := os.Getenv("REDIS_TLS_KEY_FILE"); tlsKeyFile != "" {
		c.TLSKeyFile = tlsKeyFile
	}

	if tlsCAFile := os.Getenv("REDIS_TLS_CA_FILE"); tlsCAFile != "" {
		c.TLSCAFile = tlsCAFile
	}

	// Retry settings
	if maxRetriesStr := os.Getenv("REDIS_MAX_RETRIES"); maxRetriesStr != "" {
		if maxRetries, err := strconv.Atoi(maxRetriesStr); err == nil {
			c.MaxRetries = maxRetries
		}
	}

	if minRetryBackoffStr := os.Getenv("REDIS_MIN_RETRY_BACKOFF"); minRetryBackoffStr != "" {
		if minRetryBackoff, err := time.ParseDuration(minRetryBackoffStr); err == nil {
			c.MinRetryBackoff = minRetryBackoff
		}
	}

	if maxRetryBackoffStr := os.Getenv("REDIS_MAX_RETRY_BACKOFF"); maxRetryBackoffStr != "" {
		if maxRetryBackoff, err := time.ParseDuration(maxRetryBackoffStr); err == nil {
			c.MaxRetryBackoff = maxRetryBackoff
		}
	}

	// Pool settings
	if poolSizeStr := os.Getenv("REDIS_POOL_SIZE"); poolSizeStr != "" {
		if poolSize, err := strconv.Atoi(poolSizeStr); err == nil {
			c.PoolSize = poolSize
		}
	}

	if minIdleConnsStr := os.Getenv("REDIS_MIN_IDLE_CONNS"); minIdleConnsStr != "" {
		if minIdleConns, err := strconv.Atoi(minIdleConnsStr); err == nil {
			c.MinIdleConns = minIdleConns
		}
	}

	if poolTimeoutStr := os.Getenv("REDIS_POOL_TIMEOUT"); poolTimeoutStr != "" {
		if poolTimeout, err := time.ParseDuration(poolTimeoutStr); err == nil {
			c.PoolTimeout = poolTimeout
		}
	}

	if maxConnAgeStr := os.Getenv("REDIS_MAX_CONN_AGE"); maxConnAgeStr != "" {
		if maxConnAge, err := time.ParseDuration(maxConnAgeStr); err == nil {
			c.MaxConnAge = maxConnAge
		}
	}

	if idleTimeoutStr := os.Getenv("REDIS_IDLE_TIMEOUT"); idleTimeoutStr != "" {
		if idleTimeout, err := time.ParseDuration(idleTimeoutStr); err == nil {
			c.IdleTimeout = idleTimeout
		}
	}

	if idleCheckFrequencyStr := os.Getenv("REDIS_IDLE_CHECK_FREQUENCY"); idleCheckFrequencyStr != "" {
		if idleCheckFrequency, err := time.ParseDuration(idleCheckFrequencyStr); err == nil {
			c.IdleCheckFrequency = idleCheckFrequency
		}
	}

	// Health check settings
	if healthCheckIntervalStr := os.Getenv("REDIS_HEALTH_CHECK_INTERVAL"); healthCheckIntervalStr != "" {
		if healthCheckInterval, err := time.ParseDuration(healthCheckIntervalStr); err == nil {
			c.HealthCheckInterval = healthCheckInterval
		}
	}

	return nil
}

// NewConfigFromEnv creates a new Redis configuration from environment variables
// It starts with default values and overrides them with environment variables
func NewConfigFromEnv() *RedisConfig {
	config := DefaultRedisConfig()
	config.LoadFromEnv()
	return config
}
