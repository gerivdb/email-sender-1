// Package circuitbreaker provides a unified circuit breaker implementation
// for Section 1.4 - Implementation des Recommandations
package circuitbreaker

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"
)

// State represents the current state of a circuit breaker
type State int

const (
	// StateClosed indicates the circuit breaker is allowing requests
	StateClosed State = iota
	// StateOpen indicates the circuit breaker is blocking requests
	StateOpen
	// StateHalfOpen indicates the circuit breaker is testing if requests should be allowed
	StateHalfOpen
)

// String returns string representation of the state
func (s State) String() string {
	switch s {
	case StateClosed:
		return "CLOSED"
	case StateOpen:
		return "OPEN"
	case StateHalfOpen:
		return "HALF_OPEN"
	default:
		return "UNKNOWN"
	}
}

// Config holds configuration for circuit breaker
type Config struct {
	// MaxFailures is the maximum number of failures before opening the circuit
	MaxFailures int `json:"max_failures"`
	// ResetTimeout is the time to wait before attempting to close the circuit
	ResetTimeout time.Duration `json:"reset_timeout"`
	// CheckInterval is the interval to check for state transitions
	CheckInterval time.Duration `json:"check_interval"`
	// SuccessThreshold is the number of successes needed to close a half-open circuit
	SuccessThreshold int `json:"success_threshold"`
	// TimeoutDuration is the maximum time to wait for a function to complete
	TimeoutDuration time.Duration `json:"timeout_duration"`
}

// DefaultConfig returns default circuit breaker configuration
func DefaultConfig() *Config {
	return &Config{
		MaxFailures:      5,
		ResetTimeout:     30 * time.Second,
		CheckInterval:    10 * time.Second,
		SuccessThreshold: 2,
		TimeoutDuration:  30 * time.Second,
	}
}

// CircuitBreaker implements the circuit breaker pattern with ErrorManager integration
type CircuitBreaker struct {
	id              string
	name            string
	config          *Config
	state           State
	failures        int
	successes       int
	lastFailureTime time.Time
	lastSuccessTime time.Time
	lastStateChange time.Time
	mutex           sync.RWMutex
	logger          *zap.Logger
	errorManager    ErrorManager
	onStateChange   func(from, to State, reason string)

	// Metrics
	totalRequests  int64
	successfulReqs int64
	failedReqs     int64
	rejectedReqs   int64
}

// ErrorManager interface for error reporting
type ErrorManager interface {
	CatalogError(ctx context.Context, entry ErrorEntry) error
}

// ErrorEntry represents an error entry for the ErrorManager
type ErrorEntry struct {
	ID         string                 `json:"id"`
	Module     string                 `json:"module"`
	Component  string                 `json:"component"`
	ErrorCode  string                 `json:"error_code"`
	Message    string                 `json:"message"`
	Severity   string                 `json:"severity"`
	Category   string                 `json:"category"`
	Context    map[string]interface{} `json:"context"`
	Timestamp  time.Time              `json:"timestamp"`
	StackTrace string                 `json:"stack_trace,omitempty"`
}

// NewCircuitBreaker creates a new circuit breaker with ErrorManager integration
func NewCircuitBreaker(name string, config *Config, logger *zap.Logger, errorManager ErrorManager) *CircuitBreaker {
	if config == nil {
		config = DefaultConfig()
	}
	if logger == nil {
		logger = zap.NewNop()
	}

	cb := &CircuitBreaker{
		id:              uuid.New().String(),
		name:            name,
		config:          config,
		state:           StateClosed,
		logger:          logger,
		errorManager:    errorManager,
		lastStateChange: time.Now(),
	}

	cb.logger.Info("Circuit breaker initialized",
		zap.String("id", cb.id),
		zap.String("name", cb.name),
		zap.String("state", cb.state.String()),
		zap.Any("config", cb.config))

	return cb
}

// Execute executes a function with circuit breaker protection
func (cb *CircuitBreaker) Execute(ctx context.Context, fn func() error) error {
	if !cb.canExecute() {
		cb.recordRejection()
		err := fmt.Errorf("circuit breaker '%s' is open", cb.name)
		cb.reportError(ctx, "CIRCUIT_BREAKER_OPEN", err, map[string]interface{}{
			"state":    cb.state.String(),
			"failures": cb.failures,
		})
		return err
	}

	// Create timeout context
	timeoutCtx, cancel := context.WithTimeout(ctx, cb.config.TimeoutDuration)
	defer cancel()

	// Execute with timeout
	err := cb.executeWithTimeout(timeoutCtx, fn)
	cb.recordResult(ctx, err)

	return err
}

// executeWithTimeout executes function with timeout protection
func (cb *CircuitBreaker) executeWithTimeout(ctx context.Context, fn func() error) error {
	resultChan := make(chan error, 1)

	go func() {
		defer func() {
			if r := recover(); r != nil {
				resultChan <- fmt.Errorf("panic recovered: %v", r)
			}
		}()
		resultChan <- fn()
	}()

	select {
	case err := <-resultChan:
		return err
	case <-ctx.Done():
		return fmt.Errorf("circuit breaker '%s' timeout: %v", cb.name, ctx.Err())
	}
}

// canExecute determines if the circuit breaker allows execution
func (cb *CircuitBreaker) canExecute() bool {
	cb.mutex.RLock()
	defer cb.mutex.RUnlock()

	switch cb.state {
	case StateClosed:
		return true
	case StateOpen:
		// Check if reset timeout has passed
		if time.Since(cb.lastFailureTime) > cb.config.ResetTimeout {
			// Transition to half-open (will be done in recordResult)
			return true
		}
		return false
	case StateHalfOpen:
		return true
	default:
		return false
	}
}

// recordResult records the result and manages state transitions
func (cb *CircuitBreaker) recordResult(ctx context.Context, err error) {
	cb.mutex.Lock()
	defer cb.mutex.Unlock()

	cb.totalRequests++

	if err != nil {
		cb.failures++
		cb.failedReqs++
		cb.lastFailureTime = time.Now()

		cb.logger.Warn("Circuit breaker recorded failure",
			zap.String("name", cb.name),
			zap.String("state", cb.state.String()),
			zap.Int("failures", cb.failures),
			zap.Error(err))

		// Report error to ErrorManager
		cb.reportError(ctx, "OPERATION_FAILURE", err, map[string]interface{}{
			"consecutive_failures": cb.failures,
			"state":                cb.state.String(),
		})

		// Handle state transitions on failure
		switch cb.state {
		case StateClosed:
			if cb.failures >= cb.config.MaxFailures {
				cb.transitionTo(StateOpen, fmt.Sprintf("max failures reached: %d", cb.failures))
			}
		case StateHalfOpen:
			cb.transitionTo(StateOpen, "failure in half-open state")
		}
	} else {
		cb.successes++
		cb.successfulReqs++
		cb.lastSuccessTime = time.Now()

		cb.logger.Info("Circuit breaker recorded success",
			zap.String("name", cb.name),
			zap.String("state", cb.state.String()),
			zap.Int("successes", cb.successes))

		// Handle state transitions on success
		switch cb.state {
		case StateOpen:
			if time.Since(cb.lastFailureTime) > cb.config.ResetTimeout {
				cb.transitionTo(StateHalfOpen, "reset timeout elapsed")
				cb.successes = 1 // Reset success counter for half-open state
			}
		case StateHalfOpen:
			if cb.successes >= cb.config.SuccessThreshold {
				cb.transitionTo(StateClosed, fmt.Sprintf("success threshold reached: %d", cb.successes))
				cb.failures = 0 // Reset failure counter
			}
		case StateClosed:
			// Reset failures on success
			if cb.failures > 0 {
				cb.failures = 0
				cb.logger.Info("Circuit breaker failures reset due to success",
					zap.String("name", cb.name))
			}
		}
	}
}

// recordRejection records a rejected request
func (cb *CircuitBreaker) recordRejection() {
	cb.mutex.Lock()
	defer cb.mutex.Unlock()

	cb.totalRequests++
	cb.rejectedReqs++

	cb.logger.Warn("Circuit breaker rejected request",
		zap.String("name", cb.name),
		zap.String("state", cb.state.String()),
		zap.Int64("rejected_requests", cb.rejectedReqs))
}

// transitionTo transitions the circuit breaker to a new state
func (cb *CircuitBreaker) transitionTo(newState State, reason string) {
	oldState := cb.state
	cb.state = newState
	cb.lastStateChange = time.Now()

	cb.logger.Info("Circuit breaker state transition",
		zap.String("name", cb.name),
		zap.String("from", oldState.String()),
		zap.String("to", newState.String()),
		zap.String("reason", reason))

	// Call state change callback if set
	if cb.onStateChange != nil {
		cb.onStateChange(oldState, newState, reason)
	}

	// Report state change to ErrorManager
	if cb.errorManager != nil {
		ctx := context.Background()
		entry := ErrorEntry{
			ID:        uuid.New().String(),
			Module:    "circuit-breaker",
			Component: cb.name,
			ErrorCode: "STATE_TRANSITION",
			Message:   fmt.Sprintf("Circuit breaker transitioned from %s to %s: %s", oldState.String(), newState.String(), reason),
			Severity:  cb.getTransitionSeverity(oldState, newState),
			Category:  "CIRCUIT_BREAKER",
			Context: map[string]interface{}{
				"circuit_breaker_id": cb.id,
				"from_state":         oldState.String(),
				"to_state":           newState.String(),
				"reason":             reason,
				"failures":           cb.failures,
				"successes":          cb.successes,
			},
			Timestamp: time.Now(),
		}

		if err := cb.errorManager.CatalogError(ctx, entry); err != nil {
			cb.logger.Error("Failed to catalog state transition",
				zap.String("name", cb.name),
				zap.Error(err))
		}
	}
}

// getTransitionSeverity determines the severity based on state transition
func (cb *CircuitBreaker) getTransitionSeverity(from, to State) string {
	switch {
	case to == StateOpen:
		return "HIGH"
	case from == StateOpen && to == StateHalfOpen:
		return "MEDIUM"
	case from == StateHalfOpen && to == StateClosed:
		return "LOW"
	default:
		return "MEDIUM"
	}
}

// reportError reports an error to the ErrorManager
func (cb *CircuitBreaker) reportError(ctx context.Context, errorCode string, err error, context map[string]interface{}) {
	if cb.errorManager == nil {
		return
	}

	if context == nil {
		context = make(map[string]interface{})
	}

	// Add circuit breaker context
	context["circuit_breaker_id"] = cb.id
	context["circuit_breaker_name"] = cb.name
	context["total_requests"] = cb.totalRequests
	context["successful_requests"] = cb.successfulReqs
	context["failed_requests"] = cb.failedReqs
	context["rejected_requests"] = cb.rejectedReqs

	entry := ErrorEntry{
		ID:        uuid.New().String(),
		Module:    "circuit-breaker",
		Component: cb.name,
		ErrorCode: errorCode,
		Message:   err.Error(),
		Severity:  cb.getErrorSeverity(errorCode),
		Category:  "CIRCUIT_BREAKER",
		Context:   context,
		Timestamp: time.Now(),
	}

	if catalogErr := cb.errorManager.CatalogError(ctx, entry); catalogErr != nil {
		cb.logger.Error("Failed to catalog circuit breaker error",
			zap.String("name", cb.name),
			zap.String("error_code", errorCode),
			zap.Error(catalogErr))
	}
}

// getErrorSeverity determines error severity based on error code
func (cb *CircuitBreaker) getErrorSeverity(errorCode string) string {
	switch errorCode {
	case "CIRCUIT_BREAKER_OPEN":
		return "HIGH"
	case "OPERATION_FAILURE":
		return "MEDIUM"
	default:
		return "LOW"
	}
}

// State returns the current state
func (cb *CircuitBreaker) State() State {
	cb.mutex.RLock()
	defer cb.mutex.RUnlock()
	return cb.state
}

// Stats returns current statistics
func (cb *CircuitBreaker) Stats() map[string]interface{} {
	cb.mutex.RLock()
	defer cb.mutex.RUnlock()

	return map[string]interface{}{
		"id":                  cb.id,
		"name":                cb.name,
		"state":               cb.state.String(),
		"failures":            cb.failures,
		"successes":           cb.successes,
		"total_requests":      cb.totalRequests,
		"successful_requests": cb.successfulReqs,
		"failed_requests":     cb.failedReqs,
		"rejected_requests":   cb.rejectedReqs,
		"last_failure_time":   cb.lastFailureTime,
		"last_success_time":   cb.lastSuccessTime,
		"last_state_change":   cb.lastStateChange,
		"config":              cb.config,
	}
}

// SetStateChangeCallback sets a callback for state changes
func (cb *CircuitBreaker) SetStateChangeCallback(callback func(from, to State, reason string)) {
	cb.mutex.Lock()
	defer cb.mutex.Unlock()
	cb.onStateChange = callback
}

// ForceState forces the circuit breaker to a specific state (for testing)
func (cb *CircuitBreaker) ForceState(state State, reason string) {
	cb.mutex.Lock()
	defer cb.mutex.Unlock()
	cb.transitionTo(state, fmt.Sprintf("forced: %s", reason))
}

// Reset resets the circuit breaker to initial state
func (cb *CircuitBreaker) Reset() {
	cb.mutex.Lock()
	defer cb.mutex.Unlock()

	cb.state = StateClosed
	cb.failures = 0
	cb.successes = 0
	cb.totalRequests = 0
	cb.successfulReqs = 0
	cb.failedReqs = 0
	cb.rejectedReqs = 0
	cb.lastStateChange = time.Now()

	cb.logger.Info("Circuit breaker reset",
		zap.String("name", cb.name),
		zap.String("id", cb.id))
}
