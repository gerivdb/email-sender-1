package main // Changed from package registry

import (
	"fmt"
	"os" // os is used for os.Exit

	reg "EMAIL_SENDER_1/tools/core/registry" // Added import for registry package
)

func main() {
	fmt.Println("Testing tool registry...")
	registryInstance := reg.GetGlobalRegistry() // Changed to reg.GetGlobalRegistry
	if registryInstance == nil {
		fmt.Println("ERROR: Registry is nil")
		os.Exit(1)
	}

	ops := registryInstance.ListOperations() // Use the instance here
	fmt.Printf("Found %d registered operations\n", len(ops))

	for _, op := range ops {
		fmt.Printf("- %s\n", op)
	}
}
