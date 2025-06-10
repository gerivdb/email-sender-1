package advanced_autonomy_manager

import (
	"context"
	"fmt"
	"sync"
	"time"
)

// SimpleLogger basic logger implementation for testing
type SimpleLogger struct{}

func (s *SimpleLogger) Info(msg string)            { fmt.Printf("[INFO] %s\n", msg) }
func (s *SimpleLogger) Debug(msg string)           { fmt.Printf("[DEBUG] %s\n", msg) }
func (s *SimpleLogger) Warn(msg string)            { fmt.Printf("[WARN] %s\n", msg) }
func (s *SimpleLogger) Error(msg string)           { fmt.Printf("[ERROR] %s\n", msg) }
func (s *SimpleLogger) WithError(err error) Logger { return s }

// SimpleAdvancedAutonomyManager minimal implementation focusing on freeze fix
type SimpleAdvancedAutonomyManager struct {
	logger        Logger
	isInitialized bool
	isRunning     bool
	mu            sync.RWMutex
	ctx           context.Context
	cancel        context.CancelFunc
	workers       []*Worker
}

// Worker represents a worker goroutine that could cause freeze
type Worker struct {
	id     int
	ctx    context.Context
	cancel context.CancelFunc
	done   chan struct{}
}

// NewSimpleAdvancedAutonomyManager creates a minimal manager for freeze testing
func NewSimpleAdvancedAutonomyManager(logger Logger) *SimpleAdvancedAutonomyManager {
	ctx, cancel := context.WithCancel(context.Background())

	return &SimpleAdvancedAutonomyManager{
		logger:  logger,
		ctx:     ctx,
		cancel:  cancel,
		workers: make([]*Worker, 0),
	}
}

// Initialize starts the manager with workers
func (sam *SimpleAdvancedAutonomyManager) Initialize(ctx context.Context) error {
	sam.mu.Lock()
	defer sam.mu.Unlock()

	if sam.isInitialized {
		return fmt.Errorf("manager already initialized")
	}

	sam.logger.Info("Initializing Simple Advanced Autonomy Manager with workers")

	// Start some worker goroutines (similar to what caused the original freeze)
	for i := 0; i < 3; i++ {
		worker := sam.startWorker(i)
		sam.workers = append(sam.workers, worker)
	}

	sam.isInitialized = true
	sam.isRunning = true
	sam.logger.Info("Simple manager initialized successfully")

	return nil
}

// startWorker starts a worker goroutine
func (sam *SimpleAdvancedAutonomyManager) startWorker(id int) *Worker {
	ctx, cancel := context.WithCancel(sam.ctx)

	worker := &Worker{
		id:     id,
		ctx:    ctx,
		cancel: cancel,
		done:   make(chan struct{}),
	}

	go func() {
		defer close(worker.done)
		sam.logger.Info(fmt.Sprintf("Worker %d started", id))

		ticker := time.NewTicker(100 * time.Millisecond)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				sam.logger.Info(fmt.Sprintf("Worker %d shutting down due to context cancellation", id))
				return
			case <-ticker.C:
				// Simulate work that was causing infinite loops before the fix
				sam.logger.Debug(fmt.Sprintf("Worker %d doing work", id))
			}
		}
	}()

	return worker
}

// HealthCheck checks if the manager is healthy
func (sam *SimpleAdvancedAutonomyManager) HealthCheck(ctx context.Context) error {
	sam.mu.RLock()
	defer sam.mu.RUnlock()

	if !sam.isInitialized {
		return fmt.Errorf("manager not initialized")
	}

	sam.logger.Debug("Health check passed")
	return nil
}

// Cleanup shuts down the manager - THIS IS WHERE THE FREEZE FIX IS CRITICAL
func (sam *SimpleAdvancedAutonomyManager) Cleanup() error {
	sam.mu.Lock()
	defer sam.mu.Unlock()

	sam.logger.Info("Starting cleanup - testing freeze fix")

	// CRITICAL FIX: Cancel context first to signal all workers to stop
	if sam.cancel != nil {
		sam.logger.Info("Cancelling context to signal workers shutdown")
		sam.cancel()
	}

	// CRITICAL FIX: Wait for workers to finish with timeout
	sam.logger.Info("Waiting for workers to finish")

	workersDone := make(chan struct{})
	go func() {
		defer close(workersDone)

		for _, worker := range sam.workers {
			select {
			case <-worker.done:
				sam.logger.Info(fmt.Sprintf("Worker %d finished cleanly", worker.id))
			case <-time.After(2 * time.Second):
				sam.logger.Warn(fmt.Sprintf("Worker %d timed out, forcing shutdown", worker.id))
				worker.cancel() // Force cancel individual worker
			}
		}
	}()

	// Wait for all workers to finish or timeout
	select {
	case <-workersDone:
		sam.logger.Info("All workers finished cleanly")
	case <-time.After(5 * time.Second):
		sam.logger.Error("FREEZE DETECTED: Workers didn't finish in time")
		return fmt.Errorf("cleanup timeout - workers didn't finish")
	}

	sam.isInitialized = false
	sam.isRunning = false

	sam.logger.Info("Cleanup completed successfully - NO FREEZE!")
	return nil
}
