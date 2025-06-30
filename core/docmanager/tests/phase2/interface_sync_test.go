// core/docmanager/tests/phase2/interface_sync_test.go
// Tests unitaires pour SyncInterfaces

package phase2

import (
	"context"
	"testing"

	"email_sender/core/docmanager"
)

func TestSyncInterfaces(t *testing.T) {
	err := docmanager.SyncInterfaces(context.Background(), "security")
	if err != nil {
		t.Fatalf("Erreur SyncInterfaces: %v", err)
	}
}
