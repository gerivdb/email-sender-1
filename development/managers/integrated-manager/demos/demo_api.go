package main

import (
	"fmt"
	"log"
	"time"

	integratedmanager "email_sender/development/managers/integrated-manager"
)

func main() {
	fmt.Println("=== EMAIL_SENDER_1 - Conformity API Demo ===")
	
	// Create IntegratedErrorManager instance
	fmt.Println("1. Creating IntegratedErrorManager...")
	manager := integratedmanager.NewIntegratedErrorManager()
	
	// Configure API server
	fmt.Println("2. Configuring API server on port 8082...")
	err := manager.SetAPIServerConfig(true, 8082)
	if err != nil {
		log.Fatalf("Failed to configure API server: %v", err)
	}
	
	// Start API server
	fmt.Println("3. Starting API server...")
	err = manager.StartAPIServer()
	if err != nil {
		log.Fatalf("Failed to start API server: %v", err)
	}
	
	// Show API server status
	enabled, port, err := manager.GetAPIServerStatus()
	if err != nil {
		log.Printf("Error getting API server status: %v", err)
	} else {
		fmt.Printf("4. API Server Status: Enabled=%v, Port=%d\n", enabled, port)
	}
	
	// Show API server URL
	url := manager.GetAPIServerURL()
	fmt.Printf("5. API Server URL: %s\n", url)
	
	// Display available endpoints
	fmt.Println("6. Available API Endpoints:")
	fmt.Println("   GET    /api/v1/health                     - Health check")
	fmt.Println("   GET    /api/v1/metrics                    - Conformity metrics")
	fmt.Println("   GET    /api/v1/managers                   - List all managers")
	fmt.Println("   GET    /api/v1/managers/{name}            - Get manager conformity")
	fmt.Println("   POST   /api/v1/managers/{name}/verify     - Verify manager conformity")
	fmt.Println("   PUT    /api/v1/managers/{name}            - Update manager conformity")
	fmt.Println("   GET    /api/v1/ecosystem                  - Get ecosystem conformity")
	fmt.Println("   POST   /api/v1/ecosystem/verify           - Verify ecosystem conformity")
	fmt.Println("   POST   /api/v1/reports/generate           - Generate conformity report")
	fmt.Println("   GET    /api/v1/reports/formats            - Get available report formats")
	fmt.Println("   GET    /api/v1/badges/{name}              - Generate manager badge")
	fmt.Println("   GET    /api/v1/badges/ecosystem           - Generate ecosystem badge")
	fmt.Println("   GET    /api/v1/config                     - Get conformity configuration")
	fmt.Println("   PUT    /api/v1/config                     - Update conformity configuration")
	fmt.Println("   GET    /api/v1/docs                       - API documentation")
	
	// Keep server running for demo
	fmt.Println("7. API server is running. You can test the endpoints using:")
	fmt.Printf("   curl %s/health\n", url)
	fmt.Printf("   curl %s/metrics\n", url)
	fmt.Printf("   curl %s/docs\n", url)
	fmt.Println("8. Press Ctrl+C to stop or wait for auto-shutdown in 30 seconds...")
	
	// Wait for 30 seconds
	time.Sleep(30 * time.Second)
	
	// Stop the API server
	fmt.Println("9. Stopping API server...")
	err = manager.StopAPIServer()
	if err != nil {
		log.Printf("Error stopping API server: %v", err)
	}
	
	// Stop the manager
	fmt.Println("10. Stopping IntegratedErrorManager...")
	manager.Stop()
	
	fmt.Println("=== Demo completed successfully! ===")
}
