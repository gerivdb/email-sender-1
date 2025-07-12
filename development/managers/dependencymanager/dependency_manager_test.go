// development/managers/dependencymanager/dependency_manager_test.go
package dependency

import (
	"testing"
)

func TestDependencyManagerNonRegression(t *testing.T) {
	dm, err := New()
	if err != nil || dm == nil {
		t.Fatalf("Gestionnaire non initialisé : %v", err)
	}

	t.Run("Ajout de dépendance", func(t *testing.T) {
		err := dm.AddDependency("foo", "v1.0.0")
		if err != nil {
			t.Errorf("Erreur lors de l'ajout : %v", err)
		}
		if !dm.HasDependency("foo") {
			t.Error("La dépendance 'foo' n'a pas été ajoutée")
		}
	})

	t.Run("Suppression de dépendance", func(t *testing.T) {
		_ = dm.AddDependency("bar", "v2.0.0")
		err := dm.RemoveDependency("bar")
		if err != nil {
			t.Errorf("Erreur lors de la suppression : %v", err)
		}
		if dm.HasDependency("bar") {
			t.Error("La dépendance 'bar' n'a pas été supprimée")
		}
	})

	t.Run("Liste des dépendances", func(t *testing.T) {
		_ = dm.AddDependency("baz", "v3.0.0")
		list := dm.ListDependencies()
		found := false
		for _, dep := range list {
			if dep.Name == "baz" && dep.Version == "v3.0.0" {
				found = true
			}
		}
		if !found {
			t.Error("La dépendance 'baz' n'est pas présente dans la liste")
		}
	})
}
