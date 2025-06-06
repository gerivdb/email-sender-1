package main

import (
	"fmt"
	"os"

	"email_sender/development/managers/tools"
)

func main() {
	// Test simple pour vérifier que NewStructValidator fonctionne
	tempDir, err := os.MkdirTemp("", "test_validator")
	if err != nil {
		fmt.Printf("Error creating temp dir: %v\n", err)
		return
	}
	defer os.RemoveAll(tempDir)

	validator, err := tools.NewStructValidator(tempDir, nil, false)
	if err != nil {
		fmt.Printf("Error creating validator: %v\n", err)
		return
	}

	fmt.Printf("✅ SUCCESS: StructValidator created successfully\n")
	fmt.Printf("Base directory: %s\n", validator.BaseDir)
	fmt.Printf("Dry run: %v\n", validator.DryRun)
}
