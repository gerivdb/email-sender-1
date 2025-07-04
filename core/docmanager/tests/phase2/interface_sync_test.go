// core/docmanager/tests/phase2/interface_sync_test.go
// Tests unitaires pour SyncInterfaces

package phase2

import (
	"context"
	"testing"

	"github.com/gerivdb/email-sender-1/core/docmanager"
)

func TestSyncInterfaces(t *testing.T) {
	err := docmanager.SyncInterfaces(context.Background(), "security")
	if err != nil {
		t.Fatalf("Erreur SyncInterfaces: %v", err)
	}
}
