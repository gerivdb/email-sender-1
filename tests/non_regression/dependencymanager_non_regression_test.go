package non_regression

import (
	"testing"

	dependency "github.com/gerivdb/email-sender-1/development/managers/dependencymanager"
)

func TestDependencyManagerNonRegression(t *testing.T) {
	dm := dependency.New()
	if dm == nil {
		t.Fatal("Gestionnaire non initialisé")
	}
	// Ajoutez ici des assertions supplémentaires si nécessaire
}
