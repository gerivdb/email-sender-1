package main

import (
	"fmt"
	"os"
	"os/exec"
)

func main() {
	fmt.Println("Starting FMOUA Integration Tests...")
	
	// Change to tests directory
	if err := os.Chdir("tests"); err != nil {
		fmt.Printf("Error changing to tests directory: %v\n", err)
		os.Exit(1)
	}
	
	// Run the integration tests
	cmd := exec.Command("go", "test", "-v", ".")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	
	if err := cmd.Run(); err != nil {
		fmt.Printf("Test execution failed: %v\n", err)
		os.Exit(1)
	}
	
	fmt.Println("FMOUA Integration Tests completed successfully!")
}
