package integration_manager

import (
	"fmt"
	"testing"
)

func TestSimple(t *testing.T) {
	fmt.Println("Simple test running...")

	// Create a new Integration Manager
	manager := NewIntegrationManager()
	if manager == nil {
		t.Fatal("Failed to create Integration Manager")
	}

	// Test basic functionality
	err := manager.Start()
	if err != nil {
		t.Fatalf("Failed to start Integration Manager: %v", err)
	}

	// Test status
	status := manager.GetStatus()
	fmt.Printf("Manager Status: %s\n", status.Status)

	// Stop the manager
	err = manager.Stop()
	if err != nil {
		t.Fatalf("Failed to stop Integration Manager: %v", err)
	}

	fmt.Println("Simple test completed successfully!")
}
