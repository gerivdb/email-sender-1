package dependency

import (
	"testing"
)

func TestDependencyManagerBasic(t *testing.T) {
	dm := New()
	if dm == nil {
		t.Fatal("Gestionnaire non initialisé")
	}

	err := dm.AddDependency("foo", "v1.0.0")
	if err != nil {
		t.Fatal("Erreur lors de l'ajout de dépendance")
	}

	if !dm.HasDependency("foo") {
		t.Fatal("La dépendance foo devrait exister")
	}

	_ = dm.AddDependency("bar", "v2.0.0")
	err = dm.RemoveDependency("bar")
	if err != nil {
		t.Fatal("Erreur lors de la suppression de dépendance")
	}

	if dm.HasDependency("bar") {
		t.Fatal("La dépendance bar ne devrait plus exister")
	}

	_ = dm.AddDependency("baz", "v3.0.0")
	list := dm.ListDependencies()
	if len(list) != 2 {
		t.Fatalf("Il devrait y avoir 2 dépendances, trouvé %d", len(list))
	}
}
