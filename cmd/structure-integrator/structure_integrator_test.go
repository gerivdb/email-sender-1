// cmd/structure-integrator/structure_integrator_test.go
package main

import (
	"os"
	"testing"
)

func TestStructureIntegratorOutput(t *testing.T) {
	f := "structure_integrator.log"
	_ = os.Remove(f) // Nettoyage avant test
	main()
	if _, err := os.Stat(f); os.IsNotExist(err) {
		t.Errorf("%s n'a pas été généré", f)
	}
}
