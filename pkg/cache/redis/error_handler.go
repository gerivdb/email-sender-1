// Package redis provides error handling and circuit breaker functionality for Redis connections
package redis

import (
	"errors"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

// ErrorType represents different types of Redis errors
type ErrorType int

const (
	ErrorTypeConnection ErrorType = iota
	ErrorTypeTimeout
	ErrorTypeAuthentication
	ErrorTypeNetwork
	ErrorTypeUnknown
)

// RedisError represents a Redis error with type classification
type RedisError struct {
	Type    ErrorType
	Message string
	Cause   error
	Time    time.Time
}

func (e *RedisError) Error() string {
	return fmt.Sprintf("Redis error [%v] at %v: %s", e.Type, e.Time.Format(time.RFC3339), e.Message)
}

func (e *RedisError) Unwrap() error {
	return e.Cause
}

// ErrorHandler handles and classifies Redis errors
type ErrorHandler struct {
	logger *log.Logger
}

// NewErrorHandler creates a new error handler
func NewErrorHandler(logger *log.Logger) *ErrorHandler {
	if logger == nil {
		logger = log.Default()
	}
	return &ErrorHandler{logger: logger}
}

// Handle classifies and handles a Redis error
func (h *ErrorHandler) Handle(err error) *RedisError {
	if err == nil {
		return nil
	}

	redisErr := &RedisError{
		Type:    h.classifyError(err),
		Message: err.Error(),
		Cause:   err,
		Time:    time.Now(),
	}

	h.logger.Printf("Redis error handled: %v", redisErr)
	return redisErr
}

// classifyError determines the type of Redis error
func (h *ErrorHandler) classifyError(err error) ErrorType {
	if err == nil {
		return ErrorTypeUnknown
	}

	// Check for specific Redis errors
	if errors.Is(err, redis.Nil) {
		return ErrorTypeUnknown // Key not found is not really an error
	}

	// Check error message patterns
	errMsg := err.Error()
	switch {
	case contains(errMsg, "connection refused", "no such host", "network unreachable"):
		return ErrorTypeConnection
	case contains(errMsg, "timeout", "deadline exceeded", "context deadline exceeded"):
		return ErrorTypeTimeout
	case contains(errMsg, "auth", "authentication", "invalid password"):
		return ErrorTypeAuthentication
	case contains(errMsg, "network", "broken pipe", "connection reset"):
		return ErrorTypeNetwork
	default:
		return ErrorTypeUnknown
	}
}

func contains(s string, patterns ...string) bool {
	for _, pattern := range patterns {
		if len(s) >= len(pattern) {
			for i := 0; i <= len(s)-len(pattern); i++ {
				if s[i:i+len(pattern)] == pattern {
					return true
				}
			}
		}
	}
	return false
}

// CircuitBreakerState represents the state of the circuit breaker
type CircuitBreakerState int

const (
	StateClosed CircuitBreakerState = iota
	StateOpen
	StateHalfOpen
)

func (s CircuitBreakerState) String() string {
	switch s {
	case StateClosed:
		return "Closed"
	case StateOpen:
		return "Open"
	case StateHalfOpen:
		return "HalfOpen"
	default:
		return "Unknown"
	}
}

// CircuitBreakerConfig configures the circuit breaker
type CircuitBreakerConfig struct {
	MaxFailures      int           `json:"max_failures" yaml:"max_failures"`
	ResetTimeout     time.Duration `json:"reset_timeout" yaml:"reset_timeout"`
	CheckInterval    time.Duration `json:"check_interval" yaml:"check_interval"`
	SuccessThreshold int           `json:"success_threshold" yaml:"success_threshold"`
}

// DefaultCircuitBreakerConfig returns default circuit breaker configuration
func DefaultCircuitBreakerConfig() *CircuitBreakerConfig {
	return &CircuitBreakerConfig{
		MaxFailures:      5,
		ResetTimeout:     30 * time.Second,
		CheckInterval:    10 * time.Second,
		SuccessThreshold: 2,
	}
}

// CircuitBreaker implements circuit breaker pattern for Redis operations
type CircuitBreaker struct {
	config       *CircuitBreakerConfig
	state        CircuitBreakerState
	failures     int
	successes    int
	lastFailTime time.Time
	mutex        sync.RWMutex
	logger       *log.Logger
}

// NewCircuitBreaker creates a new circuit breaker
func NewCircuitBreaker(config *CircuitBreakerConfig, logger *log.Logger) *CircuitBreaker {
	if config == nil {
		config = DefaultCircuitBreakerConfig()
	}
	if logger == nil {
		logger = log.Default()
	}

	return &CircuitBreaker{
		config: config,
		state:  StateClosed,
		logger: logger,
	}
}

// Execute executes a function with circuit breaker protection
func (cb *CircuitBreaker) Execute(fn func() error) error {
	if !cb.canExecute() {
		return fmt.Errorf("circuit breaker is open")
	}

	err := fn()
	cb.recordResult(err)

	return err
}

// canExecute checks if the circuit breaker allows execution
func (cb *CircuitBreaker) canExecute() bool {
	cb.mutex.RLock()
	defer cb.mutex.RUnlock()

	switch cb.state {
	case StateClosed:
		return true
	case StateOpen:
		// Check if reset timeout has passed
		if time.Since(cb.lastFailTime) > cb.config.ResetTimeout {
			cb.mutex.RUnlock()
			cb.mutex.Lock()
			if cb.state == StateOpen && time.Since(cb.lastFailTime) > cb.config.ResetTimeout {
				cb.state = StateHalfOpen
				cb.successes = 0
				cb.logger.Printf("Circuit breaker moved to half-open state")
			}
			cb.mutex.Unlock()
			cb.mutex.RLock()
			return cb.state == StateHalfOpen
		}
		return false
	case StateHalfOpen:
		return true
	default:
		return false
	}
}

// recordResult records the result of an operation
func (cb *CircuitBreaker) recordResult(err error) {
	cb.mutex.Lock()
	defer cb.mutex.Unlock()

	if err != nil {
		cb.failures++
		cb.lastFailTime = time.Now()

		if cb.state == StateHalfOpen {
			cb.state = StateOpen
			cb.logger.Printf("Circuit breaker opened due to failure in half-open state")
		} else if cb.state == StateClosed && cb.failures >= cb.config.MaxFailures {
			cb.state = StateOpen
			cb.logger.Printf("Circuit breaker opened due to %d failures", cb.failures)
		}
	} else {
		cb.failures = 0

		if cb.state == StateHalfOpen {
			cb.successes++
			if cb.successes >= cb.config.SuccessThreshold {
				cb.state = StateClosed
				cb.logger.Printf("Circuit breaker closed after %d successes", cb.successes)
			}
		}
	}
}

// State returns the current state of the circuit breaker
func (cb *CircuitBreaker) State() CircuitBreakerState {
	cb.mutex.RLock()
	defer cb.mutex.RUnlock()
	return cb.state
}

// Stats returns statistics about the circuit breaker
func (cb *CircuitBreaker) Stats() map[string]interface{} {
	cb.mutex.RLock()
	defer cb.mutex.RUnlock()

	return map[string]interface{}{
		"state":          cb.state.String(),
		"failures":       cb.failures,
		"successes":      cb.successes,
		"last_fail_time": cb.lastFailTime,
		"max_failures":   cb.config.MaxFailures,
		"reset_timeout":  cb.config.ResetTimeout,
	}
}
