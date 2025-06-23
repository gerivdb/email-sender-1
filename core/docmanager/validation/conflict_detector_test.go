// core/docmanager/validation/conflict_detector_test.go
// Tests unitaires pour la détection de conflits

package validation

import (
	"testing"
)

func TestDetectConflicts(t *testing.T) {
	conflicts, err := DetectConflicts(&Document{})
	if err != nil {
		t.Errorf("DetectConflicts a échoué : %v", err)
	}
	if len(conflicts) == 0 {
		t.Errorf("Aucun conflit détecté")
	}
}

func TestDetectCrossBranchConflicts(t *testing.T) {
	conflicts, err := DetectCrossBranchConflicts()
	if err != nil {
		t.Errorf("DetectCrossBranchConflicts a échoué : %v", err)
	}
	if len(conflicts) == 0 {
		t.Errorf("Aucun conflit cross-branch détecté")
	}
}
