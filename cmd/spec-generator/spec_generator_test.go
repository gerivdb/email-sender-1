// cmd/spec-generator/spec_generator_test.go
package main

import (
	"os"
	"testing"
)

func TestSpecDocManagerCreated(t *testing.T) {
	_ = os.Remove("spec_docmanager.md") // Nettoyage avant test
	main()
	if _, err := os.Stat("spec_docmanager.md"); os.IsNotExist(err) {
		t.Error("spec_docmanager.md n'a pas été généré")
	}
}
