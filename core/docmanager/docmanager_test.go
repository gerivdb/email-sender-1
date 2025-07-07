// core/docmanager/docmanager_test.go
// Tests unitaires de base pour DocManager v66

package docmanager

import (
	"context"
	"testing"
)

func TestCreateDocument(t *testing.T) {
	manager := NewDocManager(Config{}, nil, nil)
	err := manager.CreateDocument(context.Background(), &Document{})
	if err != nil {
		t.Errorf("CreateDocument a échoué : %v", err)
	}
}

func TestSyncAcrossBranches(t *testing.T) {
	manager := NewDocManager(Config{}, nil, nil)
	err := manager.SyncAcrossBranches(context.Background())
	if err != nil {
		t.Errorf("SyncAcrossBranches a échoué : %v", err)
	}
}
