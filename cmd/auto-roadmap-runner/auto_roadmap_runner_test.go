// cmd/auto-roadmap-runner/auto_roadmap_runner_test.go
package main

import (
	"os"
	"testing"
)

func TestAutoRoadmapRunnerOutput(t *testing.T) {
	f := "auto_roadmap_runner.log"
	_ = os.Remove(f) // Nettoyage avant test
	main()
	if _, err := os.Stat(f); os.IsNotExist(err) {
		t.Errorf("%s n'a pas été généré", f)
	}
}
