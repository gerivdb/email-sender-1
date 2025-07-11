// cmd/manager-recensement/manager_recensement_test.go
package main

import (
	"os"
	"testing"
)

func TestRecensementFileCreated(t *testing.T) {
	_ = os.Remove("recensement.json") // Nettoyage avant test
	main()
	if _, err := os.Stat("recensement.json"); os.IsNotExist(err) {
		t.Error("recensement.json n'a pas été généré")
	}
}
