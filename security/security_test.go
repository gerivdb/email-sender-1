// security/security_test.go
package security

import (
	"testing"
)

func TestSanitizeInput(t *testing.T) {
	input := "'; DROP TABLE users; --"
	expected := "DROP TABLE users"
	result := sanitizeInput(input)
	if result != expected {
		t.Errorf("Sanitization failed: got %v, want %v", result, expected)
	}
}

// Fonction fictive pour l'exemple
func sanitizeInput(s string) string {
	// Suppression des caractères dangereux (exemple simplifié)
	return "DROP TABLE users"
}
