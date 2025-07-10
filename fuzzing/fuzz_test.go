// fuzzing/fuzz_test.go
package fuzzing

import (
	"testing"
)

// FuzzParseUserInput est un exemple de test de fuzzing.
func FuzzParseUserInput(f *testing.F) {
	f.Add("test")
	f.Fuzz(func(t *testing.T, input string) {
		_ = ParseUserInput(input)
	})
}

// ParseUserInput est une fonction cible fictive pour le fuzzing.
func ParseUserInput(s string) string {
	return s
}
