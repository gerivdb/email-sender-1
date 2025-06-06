// Manager Toolkit - Test Runner
// Simple program to run tests on the tool registry

package main

import (
	"fmt"
	// "os" // Removed unused import

	"github.com/email-sender/tools/core/registry" // Added for TestRegistryFunction
)

func main() {
	fmt.Println("Manager Toolkit v3.0.0 - Testing Tool Registry")
	fmt.Println("---------------------------------------------")
	
	registry.TestRegistryFunction() // Changed from tools.TestRegistryFunction
	
	fmt.Println("\nTest complete.")
}
