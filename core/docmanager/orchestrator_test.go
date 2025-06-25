// core/docmanager/orchestrator_test.go
// Tests unitaires pour Orchestrator (Phase 1)

package docmanager

import "testing"

func TestOrchestrator_DefineAndValidateObjectives(t *testing.T) {
	o := &OrchestratorImpl{}
	objs := []Objective{
		{Name: "Cartographie", Description: "Cartographie exhaustive des dépendances"},
		{Name: "DocGen", Description: "Génération automatique de documentation"},
	}
	err := o.DefineObjectives(objs)
	if err != nil {
		t.Fatalf("Erreur DefineObjectives: %v", err)
	}
	if !o.ValidateObjectives() {
		t.Fatalf("ValidateObjectives doit retourner true")
	}
}
