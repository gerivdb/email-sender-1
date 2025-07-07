// core/docmanager/validation/conflict_resolver_test.go
// Tests unitaires pour la résolution de conflits

package validation

import (
	"testing"
)

func TestResolveConflict(t *testing.T) {
	err := ResolveConflict(Conflict{Type: "branch", Details: "Test"})
	if err != nil {
		t.Errorf("ResolveConflict a échoué : %v", err)
	}
}

func TestManualConflictResolution(t *testing.T) {
	err := ManualConflictResolution(Conflict{Type: "manual", Details: "Test"})
	if err != nil {
		t.Errorf("ManualConflictResolution a échoué : %v", err)
	}
}
