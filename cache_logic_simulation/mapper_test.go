package cache_logic_simulation

import (
	"testing"
)

func TestMapDependencies(t *testing.T) {
	mapper := &DependencyMapper{}
	dependencies, err := mapper.MapDependencies("./testdata")
	if err != nil {
		t.Errorf("MapDependencies() a retourné une erreur: %v", err)
	}
	if len(dependencies) == 0 {
		t.Error("MapDependencies() n'a retourné aucune dépendance")
	}
	expected := []Dependency{
		{Name: "dependency1", Path: "path/to/dep1"},
		{Name: "dependency2", Path: "path/to/dep2"},
	}
	for i, dep := range expected {
		if dependencies[i] != dep {
			t.Errorf("Dépendance inattendue à l'index %d: attendu %+v, obtenu %+v", i, dep, dependencies[i])
		}
	}
}
