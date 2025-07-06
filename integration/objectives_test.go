package integration

import (
	"context"
	"testing"
)

func TestDefineObjectives(t *testing.T) {
	manager := &ObjectivesManager{}
	err := manager.DefineObjectives(context.Background())
	if err != nil {
		t.Errorf("DefineObjectives() a retourné une erreur: %v", err)
	}
	// Ajoutez ici d'autres assertions si DefineObjectives a des effets observables
}

func TestListDependencies(t *testing.T) {
	manager := &ObjectivesManager{}
	deps, err := manager.ListDependencies()
	if err != nil {
		t.Errorf("ListDependencies() a retourné une erreur: %v", err)
	}
	if deps == nil {
		t.Error("ListDependencies() a retourné nil au lieu d'une tranche vide")
	}
	// Ajoutez ici des assertions spécifiques sur le contenu de 'deps' si nécessaire
}
