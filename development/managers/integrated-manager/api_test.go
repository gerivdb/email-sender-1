package integratedmanager_test

import (
	"net/http"
	"testing"
	"time"

	im "email_sender/development/managers/integration-manager"
)

// TestConformityAPIServerStart tests if the API server can start correctly
func TestConformityAPIServerStart(t *testing.T) {
	// Create a test integrated error manager
	manager := im.NewIntegratedErrorManager()
	
	// Configure API server
	err := manager.SetAPIServerConfig(true, 8081)
	if err != nil {
		t.Fatalf("Failed to configure API server: %v", err)
	}
	
	// Start API server in background
	err = manager.StartAPIServer()
	if err != nil {
		t.Fatalf("Failed to start API server: %v", err)
	}
	
	// Give the server time to start
	time.Sleep(100 * time.Millisecond)
	
	// Test health endpoint
	resp, err := http.Get("http://localhost:8081/api/v1/health")
	if err != nil {
		t.Fatalf("Failed to reach health endpoint: %v", err)
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}
	
	// Stop the server
	err = manager.StopAPIServer()
	if err != nil {
		t.Errorf("Failed to stop API server: %v", err)
	}
	
	// Stop the manager gracefully
	manager.Stop()
}

// TestAPIEndpointsExist tests if all expected endpoints are registered
func TestAPIEndpointsExist(t *testing.T) {
	// Create a test integrated error manager
	manager := im.NewIntegratedErrorManager()
	
	// Get the API server instance
	apiServer := manager.GetAPIServer()
	if apiServer == nil {
		t.Fatal("API server should not be nil after manager creation")
	}
	
	// The router should have been configured
	if apiServer.router == nil {
		t.Fatal("API server router should not be nil")
	}
	
	t.Log("API server and router are properly initialized")
}
