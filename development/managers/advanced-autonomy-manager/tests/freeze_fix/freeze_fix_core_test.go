package advanced_autonomy_manager

import (
	"context"
	"testing"
	"time"
)

// TestFreezeFixCore tests the core freeze fix functionality
func TestFreezeFixCore(t *testing.T) {
	logger := &SimpleLogger{}
	logger.Info("=== STARTING FREEZE FIX VALIDATION TEST ===")

	// Create manager
	manager := NewSimpleAdvancedAutonomyManager(logger)

	// Test initialization
	ctx := context.Background()
	err := manager.Initialize(ctx)
	if err != nil {
		t.Fatalf("Failed to initialize manager: %v", err)
	}

	// Give workers time to start
	time.Sleep(500 * time.Millisecond)

	// Test health check
	err = manager.HealthCheck(ctx)
	if err != nil {
		t.Fatalf("Health check failed: %v", err)
	}

	// THE CRITICAL TEST: Cleanup should not freeze
	logger.Info("=== TESTING CLEANUP - THIS USED TO FREEZE ===")

	// Use a timeout to detect if cleanup freezes
	cleanupDone := make(chan error, 1)

	go func() {
		cleanupDone <- manager.Cleanup()
	}()

	select {
	case err := <-cleanupDone:
		if err != nil {
			t.Fatalf("Cleanup failed: %v", err)
		}
		logger.Info("=== SUCCESS: Cleanup completed without freeze! ===")
	case <-time.After(10 * time.Second):
		t.Fatal("=== FAILURE: Cleanup froze! The fix didn't work! ===")
	}

	logger.Info("=== FREEZE FIX VALIDATION TEST PASSED ===")
}
