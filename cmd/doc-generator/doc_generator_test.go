// cmd/doc-generator/doc_generator_test.go
package main

import (
	"os"
	"testing"
)

func TestDocGeneratorOutput(t *testing.T) {
	files := []string{"README_docmanager.md", "guide_docmanager.md"}
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
