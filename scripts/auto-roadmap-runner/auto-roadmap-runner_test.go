// scripts/auto-roadmap-runner_test.go
// Test basique pour vérifier l’exécution de l’orchestrateur global.

package main

import (
	"os/exec"
	"testing"
)

func TestAutoRoadmapRunner_ExecutesWithoutError(t *testing.T) {
	cmd := exec.Command("go", "run", "scripts/auto-roadmap-runner.go")
	if err := cmd.Run(); err != nil {
		t.Errorf("auto-roadmap-runner.go a échoué : %v", err)
	}
}
