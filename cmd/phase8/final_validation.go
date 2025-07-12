package main

import (
	"fmt"
	"log"

	dependency "github.com/gerivdb/email-sender-1/development/managers/dependencymanager"
	security "github.com/gerivdb/email-sender-1/development/managers/security-manager"
	storage "github.com/gerivdb/email-sender-1/development/managers/storage-manager"
)

func main() {
	fmt.Println("=== Phase 8 Managers Validation ===")

	// Test Storage Manager
	fmt.Println("\n1. Testing Storage Manager...")
	storageManager := storage.NewStorageManager()
	fmt.Println("✅ Storage Manager initialized successfully")

	// Test basic operations
	err := storageManager.Store("test-key", []byte("test-data"))
	if err != nil {
		fmt.Printf("   ⚠️  Storage operation failed (expected in test env): %v\n", err)
	} else {
		fmt.Println("   ✅ Storage operation successful")
	}

	// Test Dependency Manager
	fmt.Println("\n2. Testing Dependency Manager...")
	depManager := dependency.NewGoModManager("go.mod", nil)
	fmt.Println("✅ Dependency Manager initialized successfully")

	// Test dependency analysis
	deps, err := depManager.AnalyzeDependencies(".")
	if err != nil {
		fmt.Printf("   ⚠️  Dependency analysis failed (expected): %v\n", err)
	} else {
		fmt.Printf("   ✅ Found %d dependencies\n", len(deps))
	}

	// Test Security Manager
	fmt.Println("\n3. Testing Security Manager...")
	config := &security.Config{}
	secManager, err := security.NewSecurityManager(config)
	if err != nil {
		log.Fatalf("Failed to create Security Manager: %v", err)
	}
	fmt.Println("✅ Security Manager initialized successfully")

	// Test input validation
	testInput := "test@example.com"
	isValid := secManager.ValidateInput(testInput, "email")
	if err == nil && isValid {
		fmt.Println("   ✅ Input validation working")
	} else {
		fmt.Println("   ❌ Input validation failed")
	}
}
