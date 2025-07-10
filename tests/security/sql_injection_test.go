package security

import (
	"testing"
)

func TestSQLInjection(t *testing.T) {
	// Simulation d'une requête avec injection SQL
	input := "' OR 1=1; --"
	expected := false // L'injection ne doit pas permettre l'accès
	result := simulateLogin(input)
	if result != expected {
		t.Errorf("Injection SQL non bloquée")
	}
}

// simulateLogin simule un contrôle naïf (à remplacer par la logique réelle)
func simulateLogin(userInput string) bool {
	if userInput == "' OR 1=1; --" {
		return true // Vulnérable (pour l'exemple)
	}
	return false
}
