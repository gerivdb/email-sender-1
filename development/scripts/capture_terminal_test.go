// Test d’intégration — capture_terminal_test.go
// Vérifie la capture et l’envoi de logs via le pipeline CacheManager

package main

import (
	"os/exec"
	"strings"
	"testing"
)

func TestCaptureTerminalIntegration(t *testing.T) {
	cmd := exec.Command("go", "run", "capture_terminal.go", "echo", "hello")
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Erreur d’exécution: %v", err)
	}
	if !strings.Contains(string(output), "Log envoyé au CacheManager") {
		t.Error("Le log n’a pas été envoyé au CacheManager (stub)")
	}
}
