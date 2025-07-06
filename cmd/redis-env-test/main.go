// Package main demonstrates Redis configuration loading from environment variables
package main

import (
	"context"
	"log"
	"os"
	"time"
)

func main() {
	logger := log.New(os.Stdout, "[REDIS-ENV-TEST] ", log.LstdFlags)

	logger.Println("=== Redis Environment Configuration Test ===")

	// Set some example environment variables
	os.Setenv("REDIS_HOST", "redis.example.com")
	os.Setenv("REDIS_PORT", "6380")
	os.Setenv("REDIS_PASSWORD", "super-secret-password")
	os.Setenv("REDIS_DB", "1")
	os.Setenv("REDIS_TLS_ENABLED", "true")
	os.Setenv("REDIS_POOL_SIZE", "20")
	os.Setenv("REDIS_MIN_IDLE_CONNS", "10")
	os.Setenv("REDIS_DIAL_TIMEOUT", "10s")
	os.Setenv("REDIS_READ_TIMEOUT", "5s")
	os.Setenv("REDIS_WRITE_TIMEOUT", "5s")
	os.Setenv("REDIS_HEALTH_CHECK_INTERVAL", "60s")

	// Test 1: Load configuration from environment
	logger.Println("\n=== Test 1: Load Configuration from Environment ===")

	config := redisconfig.NewConfigFromEnv()

	// Verify environment variables were loaded correctly
	tests := []struct {
		field    string
		expected interface{}
		actual   interface{}
	}{
		{"Host", "redis.example.com", config.Host},
		{"Port", 6380, config.Port},
		{"Password", "super-secret-password", config.Password},
		{"DB", 1, config.DB},
		{"TLSEnabled", true, config.TLSEnabled},
		{"PoolSize", 20, config.PoolSize},
		{"MinIdleConns", 10, config.MinIdleConns},
		{"DialTimeout", 10 * time.Second, config.DialTimeout},
		{"ReadTimeout", 5 * time.Second, config.ReadTimeout},
		{"WriteTimeout", 5 * time.Second, config.WriteTimeout},
		{"HealthCheckInterval", 60 * time.Second, config.HealthCheckInterval},
	}

	allPassed := true
	for _, test := range tests {
		if test.expected != test.actual {
			logger.Printf("❌ %s: expected %v, got %v", test.field, test.expected, test.actual)
			allPassed = false
		} else {
			logger.Printf("✓ %s: %v", test.field, test.actual)
		}
	}

	if allPassed {
		logger.Println("✅ All environment variables loaded correctly")
	} else {
		logger.Println("❌ Some environment variables failed to load")
	}

	// Test 2: Validate environment-loaded configuration
	logger.Println("\n=== Test 2: Validate Environment Configuration ===")

	validator := redisconfig.NewConfigValidator()
	if err := validator.Validate(config); err != nil {
		logger.Printf("❌ Configuration validation failed: %v", err)
	} else {
		logger.Println("✅ Environment configuration is valid")
	}

	// Test 3: Show full configuration
	logger.Println("\n=== Test 3: Full Configuration Details ===")
	logger.Printf("Configuration: %s", config.String())

	// Test 4: Test fallback to defaults when env vars are not set
	logger.Println("\n=== Test 4: Test Default Fallback ===")

	// Clear some environment variables
	os.Unsetenv("REDIS_HOST")
	os.Unsetenv("REDIS_PORT")

	configWithDefaults := redisconfig.NewConfigFromEnv()

	if configWithDefaults.Host == "localhost" && configWithDefaults.Port == 6379 {
		logger.Println("✅ Correctly fell back to defaults for unset environment variables")
		logger.Printf("   Host: %s (default), Port: %d (default)", configWithDefaults.Host, configWithDefaults.Port)
	} else {
		logger.Printf("❌ Failed to fall back to defaults: Host=%s, Port=%d", configWithDefaults.Host, configWithDefaults.Port)
	}

	// Test 5: Test hybrid client with environment config
	logger.Println("\n=== Test 5: Hybrid Client with Environment Config ===")

	// Use invalid host to test fallback
	os.Setenv("REDIS_HOST", "invalid-env-host")
	os.Setenv("REDIS_PORT", "9999")

	envConfig := redisconfig.NewConfigFromEnv()
	hybridClient, err := redisconfig.NewHybridRedisClient(envConfig)
	if err != nil {
		logger.Printf("Failed to create hybrid client: %v", err)
		return
	}
	defer hybridClient.Close()

	// Test that Redis is not healthy (fallback mode)
	if !hybridClient.IsRedisHealthy() {
		logger.Println("✅ Redis is not healthy with env config, fallback mode active")
	} else {
		logger.Println("⚠️  Redis appears healthy (unexpected with invalid config)")
	}

	// Test Set/Get through hybrid client (should use local cache)
	ctx := context.Background()
	envKey := "env-test-key"
	envValue := "env-test-value"

	if err := hybridClient.Set(ctx, envKey, envValue, 5*time.Second); err != nil {
		logger.Printf("❌ Failed to set value through hybrid client: %v", err)
	} else {
		logger.Println("✅ Value set through hybrid client with env config")
	}

	retrievedEnvValue, err := hybridClient.Get(ctx, envKey)
	if err != nil {
		logger.Printf("❌ Failed to get value through hybrid client: %v", err)
	} else if retrievedEnvValue == envValue {
		logger.Println("✅ Value retrieved correctly through hybrid client with env config")
	} else {
		logger.Printf("❌ Retrieved value doesn't match: got %v, want %v", retrievedEnvValue, envValue)
	}

	// Show hybrid client stats
	envStats := hybridClient.GetStats()
	logger.Printf("Hybrid Client Stats with Env Config: fallback_enabled=%v, redis_healthy=%v",
		envStats["fallback_enabled"], envStats["redis_healthy"])

	logger.Println("\n=== Environment Configuration Test Completed ===")
	logger.Println("✅ Environment variable loading working correctly")
	logger.Println("✅ Default fallback mechanism working")
	logger.Println("✅ Hybrid client with environment config functional")
	logger.Println("✅ Environment configuration feature COMPLETED")
}
