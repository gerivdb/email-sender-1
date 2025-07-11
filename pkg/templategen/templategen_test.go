// pkg/templategen/templategen_test.go
package main

import (
	"os"
	"testing"
)

func TestTemplatesGenerated(t *testing.T) {
	files := []string{"README.md", "plan.md", "config.yaml", "docmanager_test.go"}
	for _, f := range files {
		_ = os.Remove(f) // Nettoyage avant test
	}
	main()
	for _, f := range files {
		if _, err := os.Stat(f); os.IsNotExist(err) {
			t.Errorf("%s n'a pas été généré", f)
		}
	}
}
