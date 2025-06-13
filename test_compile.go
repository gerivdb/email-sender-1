package main

import (
	"fmt"

	"github.com/email-sender/tools/core/toolkit"
	"github.com/email-sender/tools/pkg/manager"
)

func main() {
	fmt.Println("Testing package imports...")

	// Test that we can create a logger from core toolkit
	logger := &toolkit.Logger{
		Level:      toolkit.LogLevelInfo,
		OutputPath: "test.log",
		Verbose:    false,
	}
	fmt.Printf("Logger created: %+v\n", logger)

	// Test that we can create a manager toolkit
	mgr, err := manager.NewManagerToolkit(".", "", false)
	if err != nil {
		fmt.Printf("Error creating manager: %v\n", err)
		return
	}
	fmt.Printf("Manager created successfully: %+v\n", mgr.Config)

	fmt.Println("✅ All imports working correctly! No duplicate type declarations.")
}
