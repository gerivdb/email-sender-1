// Manager Toolkit - Test Runner
// Simple program to run tests on the tool registry

package main

import (
	"fmt"
	// "os" // Removed unused import

	// "github.com/email-sender/tools/core/registry" // Removed as TestRegistryFunction call is commented out
)

func main() {
	fmt.Println("Manager Toolkit v3.0.0 - Testing Tool Registry")
	fmt.Println("---------------------------------------------")
	
	// registry.TestRegistryFunction() // This function was moved to toolkit_integration_test.go (package main_test)
	// and is intended to be run via `go test`.
	// This main program is likely redundant for that specific test.
	fmt.Println("Test runner main completed. Run 'go test ./cmd/...' for integration tests.")
	
	fmt.Println("\nTest complete.")
}
