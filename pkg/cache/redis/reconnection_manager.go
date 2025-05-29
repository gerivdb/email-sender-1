// Package redis provides reconnection management with exponential backoff
package redis

import (
	"context"
	"fmt"
	"log"
	"math"
	"math/rand"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

// ReconnectionConfig configures the reconnection manager
type ReconnectionConfig struct {
	InitialDelay        time.Duration `json:"initial_delay" yaml:"initial_delay"`
	MaxDelay            time.Duration `json:"max_delay" yaml:"max_delay"`
	Multiplier          float64       `json:"multiplier" yaml:"multiplier"`
	Jitter              bool          `json:"jitter" yaml:"jitter"`
	MaxAttempts         int           `json:"max_attempts" yaml:"max_attempts"`
	ResetAfter          time.Duration `json:"reset_after" yaml:"reset_after"`
	HealthCheckInterval time.Duration `json:"health_check_interval" yaml:"health_check_interval"`
}

// DefaultReconnectionConfig returns default reconnection configuration
func DefaultReconnectionConfig() *ReconnectionConfig {
	return &ReconnectionConfig{
		InitialDelay:        1 * time.Second,
		MaxDelay:            30 * time.Second,
		Multiplier:          2.0,
		Jitter:              true,
		MaxAttempts:         10,
		ResetAfter:          5 * time.Minute,
		HealthCheckInterval: 30 * time.Second,
	}
}

// ReconnectionManager manages Redis reconnections with exponential backoff
type ReconnectionManager struct {
	config         *ReconnectionConfig
	client         *redis.Client
	errorHandler   *ErrorHandler
	circuitBreaker *CircuitBreaker

	// State
	isConnected bool
	attempts    int
	lastAttempt time.Time
	lastSuccess time.Time

	// Synchronization
	mutex             sync.RWMutex
	stopChan          chan struct{}
	healthCheckTicker *time.Ticker

	// Logging
	logger *log.Logger

	// Callbacks
	onReconnect  func()
	onDisconnect func()
}

// NewReconnectionManager creates a new reconnection manager
func NewReconnectionManager(client *redis.Client, config *ReconnectionConfig, errorHandler *ErrorHandler, circuitBreaker *CircuitBreaker, logger *log.Logger) *ReconnectionManager {
	if config == nil {
		config = DefaultReconnectionConfig()
	}
	if logger == nil {
		logger = log.Default()
	}

	rm := &ReconnectionManager{
		config:         config,
		client:         client,
		errorHandler:   errorHandler,
		circuitBreaker: circuitBreaker,
		isConnected:    false,
		stopChan:       make(chan struct{}),
		logger:         logger,
	}

	// Start health check goroutine
	rm.startHealthCheck()

	return rm
}

// SetCallbacks sets reconnection callbacks
func (rm *ReconnectionManager) SetCallbacks(onReconnect, onDisconnect func()) {
	rm.mutex.Lock()
	defer rm.mutex.Unlock()

	rm.onReconnect = onReconnect
	rm.onDisconnect = onDisconnect
}

// IsConnected returns the current connection status
func (rm *ReconnectionManager) IsConnected() bool {
	rm.mutex.RLock()
	defer rm.mutex.RUnlock()
	return rm.isConnected
}

// Reconnect attempts to reconnect to Redis
func (rm *ReconnectionManager) Reconnect(ctx context.Context) error {
	rm.mutex.Lock()
	defer rm.mutex.Unlock()

	// Check if we should reset attempts
	if time.Since(rm.lastSuccess) > rm.config.ResetAfter {
		rm.attempts = 0
	}

	// Check max attempts
	if rm.config.MaxAttempts > 0 && rm.attempts >= rm.config.MaxAttempts {
		return fmt.Errorf("max reconnection attempts (%d) exceeded", rm.config.MaxAttempts)
	}

	rm.attempts++
	rm.lastAttempt = time.Now()

	// Calculate delay with exponential backoff
	delay := rm.calculateDelay()

	rm.logger.Printf("Attempting Redis reconnection #%d after %v delay", rm.attempts, delay)

	// Wait for delay (unless context is cancelled)
	select {
	case <-time.After(delay):
		// Continue with reconnection
	case <-ctx.Done():
		return ctx.Err()
	}

	// Attempt to ping Redis
	err := rm.client.Ping(ctx).Err()
	if err != nil {
		rm.logger.Printf("Redis reconnection attempt #%d failed: %v", rm.attempts, err)
		return rm.errorHandler.Handle(err)
	}

	// Success
	rm.isConnected = true
	rm.lastSuccess = time.Now()
	rm.attempts = 0

	rm.logger.Printf("Redis reconnection successful after %d attempts", rm.attempts)

	// Call reconnect callback
	if rm.onReconnect != nil {
		go rm.onReconnect()
	}

	return nil
}

// calculateDelay calculates the next delay using exponential backoff
func (rm *ReconnectionManager) calculateDelay() time.Duration {
	if rm.attempts <= 1 {
		return rm.config.InitialDelay
	}

	// Calculate exponential backoff
	delay := time.Duration(float64(rm.config.InitialDelay) * math.Pow(rm.config.Multiplier, float64(rm.attempts-1)))

	// Cap at max delay
	if delay > rm.config.MaxDelay {
		delay = rm.config.MaxDelay
	}

	// Add jitter if enabled
	if rm.config.Jitter {
		jitter := time.Duration(rand.Float64() * float64(delay) * 0.1) // 10% jitter
		delay += jitter
	}

	return delay
}

// startHealthCheck starts the health check goroutine
func (rm *ReconnectionManager) startHealthCheck() {
	rm.healthCheckTicker = time.NewTicker(rm.config.HealthCheckInterval)

	go func() {
		defer rm.healthCheckTicker.Stop()

		for {
			select {
			case <-rm.healthCheckTicker.C:
				rm.performHealthCheck()
			case <-rm.stopChan:
				return
			}
		}
	}()
}

// performHealthCheck performs a health check on the Redis connection
func (rm *ReconnectionManager) performHealthCheck() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err := rm.client.Ping(ctx).Err()

	rm.mutex.Lock()
	wasConnected := rm.isConnected
	rm.isConnected = (err == nil)
	rm.mutex.Unlock()

	// Check for state changes
	if wasConnected && !rm.isConnected {
		// Connection lost
		rm.logger.Printf("Redis connection lost: %v", err)
		if rm.onDisconnect != nil {
			go rm.onDisconnect()
		}

		// Trigger reconnection
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()
			rm.Reconnect(ctx)
		}()

	} else if !wasConnected && rm.isConnected {
		// Connection restored
		rm.logger.Printf("Redis connection restored")
		rm.mutex.Lock()
		rm.lastSuccess = time.Now()
		rm.attempts = 0
		rm.mutex.Unlock()

		if rm.onReconnect != nil {
			go rm.onReconnect()
		}
	}
}

// Stop stops the reconnection manager
func (rm *ReconnectionManager) Stop() {
	close(rm.stopChan)
	if rm.healthCheckTicker != nil {
		rm.healthCheckTicker.Stop()
	}
}

// Stats returns statistics about the reconnection manager
func (rm *ReconnectionManager) Stats() map[string]interface{} {
	rm.mutex.RLock()
	defer rm.mutex.RUnlock()

	return map[string]interface{}{
		"is_connected":  rm.isConnected,
		"attempts":      rm.attempts,
		"last_attempt":  rm.lastAttempt,
		"last_success":  rm.lastSuccess,
		"max_attempts":  rm.config.MaxAttempts,
		"initial_delay": rm.config.InitialDelay,
		"max_delay":     rm.config.MaxDelay,
		"multiplier":    rm.config.Multiplier,
		"jitter":        rm.config.Jitter,
	}
}

// HealthChecker provides health checking functionality
type HealthChecker struct {
	client   *redis.Client
	interval time.Duration
	timeout  time.Duration
	stopChan chan struct{}
	logger   *log.Logger
	mutex    sync.RWMutex

	// Callbacks
	onHealthy   func()
	onUnhealthy func(error)
	// State
	isHealthy    bool
	lastCheck    time.Time
	checkCount   int64
	failureCount int64
}

// NewHealthChecker creates a new health checker
func NewHealthChecker(client *redis.Client, interval, timeout time.Duration, logger *log.Logger) *HealthChecker {
	if logger == nil {
		logger = log.Default()
	}

	return &HealthChecker{
		client:   client,
		interval: interval,
		timeout:  timeout,
		stopChan: make(chan struct{}),
		logger:   logger,
	}
}

// SetCallbacks sets health check callbacks
func (hc *HealthChecker) SetCallbacks(onHealthy func(), onUnhealthy func(error)) {
	hc.onHealthy = onHealthy
	hc.onUnhealthy = onUnhealthy
}

// Start starts the health checker
func (hc *HealthChecker) Start() {
	ticker := time.NewTicker(hc.interval)
	defer ticker.Stop()

	go func() {
		for {
			select {
			case <-ticker.C:
				hc.ping()
			case <-hc.stopChan:
				return
			}
		}
	}()
}

// ping performs a ping to Redis
func (hc *HealthChecker) Ping() error {
	ctx, cancel := context.WithTimeout(context.Background(), hc.timeout)
	defer cancel()

	hc.mutex.Lock()
	hc.checkCount++
	hc.lastCheck = time.Now()
	hc.mutex.Unlock()

	err := hc.client.Ping(ctx).Err()
	if err != nil {
		hc.logger.Printf("Redis health check failed: %v", err)
		hc.setUnhealthy(err)
		if hc.onUnhealthy != nil {
			hc.onUnhealthy(err)
		}
	} else {
		hc.setHealthy()
		if hc.onHealthy != nil {
			hc.onHealthy()
		}
	}

	return err
}

// ping performs a health check ping
func (hc *HealthChecker) ping() {
	hc.Ping()
}

// Stop stops the health checker
func (hc *HealthChecker) Stop() {
	close(hc.stopChan)
}

// IsHealthy returns the current health status
func (hc *HealthChecker) IsHealthy() bool {
	hc.mutex.RLock()
	defer hc.mutex.RUnlock()
	return hc.isHealthy
}

// LastCheck returns the timestamp of the last health check
func (hc *HealthChecker) LastCheck() time.Time {
	hc.mutex.RLock()
	defer hc.mutex.RUnlock()
	return hc.lastCheck
}

// GetCheckCount returns the total number of health checks performed
func (hc *HealthChecker) GetCheckCount() int64 {
	hc.mutex.RLock()
	defer hc.mutex.RUnlock()
	return hc.checkCount
}

// GetFailureCount returns the total number of health check failures
func (hc *HealthChecker) GetFailureCount() int64 {
	hc.mutex.RLock()
	defer hc.mutex.RUnlock()
	return hc.failureCount
}

func (hc *HealthChecker) setHealthy() {
	hc.mutex.Lock()
	defer hc.mutex.Unlock()

	hc.isHealthy = true
	hc.lastCheck = time.Now()
	hc.checkCount++
}

func (hc *HealthChecker) setUnhealthy(err error) {
	hc.mutex.Lock()
	defer hc.mutex.Unlock()

	hc.isHealthy = false
	hc.lastCheck = time.Now()
	hc.checkCount++
	hc.failureCount++
}
