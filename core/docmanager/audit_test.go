// core/docmanager/audit_test.go
// Tests unitaires pour AuditExistingScripts (Phase 2)

package docmanager

import "testing"

func TestAuditExistingScripts(t *testing.T) {
	result, err := AuditExistingScripts(".")
	if err != nil {
		t.Fatalf("Erreur AuditExistingScripts: %v", err)
	}
	if len(result.FilesFound) == 0 {
		t.Errorf("Aucun fichier trouvé lors de l'audit")
	}
}
