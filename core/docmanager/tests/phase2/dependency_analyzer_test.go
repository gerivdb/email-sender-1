// core/docmanager/tests/phase2/dependency_analyzer_test.go
// Tests unitaires pour DetectDependencies

package phase2

import (
	"core/docmanager"
	"testing"
)

func TestDetectDependencies(t *testing.T) {
	deps, err := docmanager.DetectDependencies("security")
	if err != nil {
		t.Fatalf("Erreur DetectDependencies: %v", err)
	}
	if len(deps) == 0 {
		t.Errorf("Aucune dépendance détectée pour security")
	}
}
