package validation_test

import (
	"os"
	"testing"
)

func RunTests() {
	// Create a testing.T instance for running the test
	t := &testing.T{}

	// Run the validation test
	TestValidationPhase1_1(t)

	// Check if test failed
	if t.Failed() {
		os.Exit(1)
	}
}
