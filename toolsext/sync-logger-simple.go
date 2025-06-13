// Package toolsext provides sync logger functionality
package toolsext

import (
	"log"
	"os"
	"time"
)

// ExtSyncLogger represents a simple synchronization logger
type ExtSyncLogger struct {
	logger *log.Logger
	debug  bool
}

// NewExtSyncLogger creates a new sync logger
func NewExtSyncLogger(debug bool) *ExtSyncLogger {
	return &ExtSyncLogger{
		logger: log.New(os.Stdout, "[SYNC] ", log.LstdFlags),
		debug:  debug,
	}
}

// LogSync logs a synchronization event
func (sl *ExtSyncLogger) LogSync(component, message string) {
	sl.logger.Printf("[%s] %s", component, message)
}

// LogDebug logs a debug message if debug is enabled
func (sl *ExtSyncLogger) LogDebug(component, message string) {
	if sl.debug {
		sl.logger.Printf("[DEBUG:%s] %s", component, message)
	}
}

// LogError logs an error message
func (sl *ExtSyncLogger) LogError(component string, err error) {
	sl.logger.Printf("[ERROR:%s] %v", component, err)
}

// StartOperation logs the start of an operation and returns a function to log its completion
func (sl *ExtSyncLogger) StartOperation(name string) func(success bool) {
	startTime := time.Now()
	sl.logger.Printf("Starting operation: %s", name)

	return func(success bool) {
		duration := time.Since(startTime)
		if success {
			sl.logger.Printf("Operation completed successfully: %s (took %v)", name, duration)
		} else {
			sl.logger.Printf("Operation failed: %s (took %v)", name, duration)
		}
	}
}
