// Test d’intégration LMCacheAdapter — phase 4.3

package cachemanager

import (
	"testing"
)

func TestLMCacheAdapter_ContextIntegration(t *testing.T) {
	lmc := NewLMCacheAdapter()
	key := "session-llm"
	value := map[string]interface{}{"user": "cliner", "state": "active"}

	if err := lmc.StoreContext(key, value); err != nil {
		t.Fatalf("StoreContext LMCacheAdapter a échoué: %v", err)
	}

	got, err := lmc.GetContext(key)
	if err != nil {
		t.Fatalf("GetContext LMCacheAdapter a échoué: %v", err)
	}
	if got == nil {
		t.Error("GetContext LMCacheAdapter retourne nil")
	}
}
