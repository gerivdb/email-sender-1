// Manager Toolkit - Test Runner
// Simple program to run tests on the tool registry

package main

import (
	"fmt"
	"os"
	
	"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/tools"
)

func main() {
	fmt.Println("Manager Toolkit v3.0.0 - Testing Tool Registry")
	fmt.Println("---------------------------------------------")
	
	tools.TestRegistryFunction()
	
	fmt.Println("\nTest complete.")
}
