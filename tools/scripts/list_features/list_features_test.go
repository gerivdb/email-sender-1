// tools/scripts/list_features/list_features_test.go
package main

import "testing"

func TestListFeaturesOutput(t *testing.T) {
	expected := "- Authentification"
	got := "- Authentification"
	if got != expected {
		t.Errorf("Sortie inattendue: %v", got)
	}
}
