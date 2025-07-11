// cmd/test-runner/test_runner_test.go
package main

import (
	"os"
	"testing"
)

func TestTestRunnerOutput(t *testing.T) {
	f := "coverage_docmanager.out"
	_ = os.Remove(f) // Nettoyage avant test
	main()
	if _, err := os.Stat(f); os.IsNotExist(err) {
		t.Errorf("%s n'a pas été généré", f)
	}
}
