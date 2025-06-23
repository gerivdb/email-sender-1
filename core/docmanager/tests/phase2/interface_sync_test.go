// core/docmanager/tests/phase2/interface_sync_test.go
// Tests unitaires pour SyncInterfaces

package phase2

import (
	"context"
	"core/docmanager"
	"testing"
)

func TestSyncInterfaces(t *testing.T) {
	err := docmanager.SyncInterfaces(context.Background(), "security")
	if err != nil {
		t.Fatalf("Erreur SyncInterfaces: %v", err)
	}
}
