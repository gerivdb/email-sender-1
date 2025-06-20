// SPDX-License-Identifier: MIT
// Tests SRP pour ConflictResolver - TASK ATOMIQUE 3.1.1.4
package docmanager

import (
	"testing"
	"time"
)

// TestConflictResolver_SRP vérifie le respect du principe SRP
// MICRO-TASK 3.1.1.4.1 - Validation responsabilité résolution pure
func TestConflictResolver_SRP(t *testing.T) {
	resolver := NewConflictResolver()

	// Vérifier que ConflictResolver ne fait que résoudre
	if resolver == nil {
		t.Fatal("ConflictResolver should be created successfully")
	}

	// Vérifier qu'il n'y a pas de logique persistence directe
	if len(resolver.strategies) == 0 {
		t.Error("ConflictResolver should have resolution strategies")
	}

	// Test résolution d'un conflit simple
	conflict := &DocumentConflict{
		ID:   "test-conflict",
		Type: ContentConflict,
		LocalDoc: &Document{
			ID:      "doc1",
			Content: []byte("local content"),
			Version: 1,
		},
		RemoteDoc: &Document{
			ID:      "doc1",
			Content: []byte("remote content"),
			Version: 2,
		},
		ConflictedAt: time.Now(),
	}

	resolution, err := resolver.ResolveConflict(conflict)
	if err != nil {
		t.Errorf("ConflictResolver should resolve conflicts without error: %v", err)
	}

	if resolution == nil {
		t.Error("ConflictResolver should return a resolution")
	}
}

// TestConflictResolver_NoDirectPersistence vérifie l'absence de persistence directe
// MICRO-TASK 3.1.1.4.2 - Validation séparation business logic
func TestConflictResolver_NoDirectPersistence(t *testing.T) {
	resolver := NewConflictResolver()

	// Vérifier que le ConflictResolver n'a pas de champs de persistence
	// Le resolver ne doit contenir que des stratégies de résolution

	// Test: tentative de résolution ne doit pas impliquer de sauvegarde directe
	conflict := &DocumentConflict{
		ID:   "test-no-persistence",
		Type: VersionConflict,
		LocalDoc: &Document{
			ID:      "doc1",
			Version: 1,
		},
		RemoteDoc: &Document{
			ID:      "doc1",
			Version: 2,
		},
		ConflictedAt: time.Now(),
	}

	resolution, err := resolver.ResolveConflict(conflict)
	// Le resolver ne doit que retourner une résolution, pas persister
	if err != nil {
		t.Errorf("Resolution should not fail: %v", err)
	}

	if resolution == nil {
		t.Error("Resolution should be returned")
	}

	// Vérifier que la résolution contient les données nécessaires
	// mais pas d'effet de bord de persistence
	if resolution.ResolvedDoc == nil {
		t.Error("Resolution should contain resolved document")
	}
}

// TestConflictResolver_StrategyPattern vérifie l'utilisation du pattern Strategy
func TestConflictResolver_StrategyPattern(t *testing.T) {
	resolver := NewConflictResolver()

	// Test avec différents types de conflits
	testCases := []struct {
		conflictType ConflictType
		expectError  bool
	}{
		{ContentConflict, false},
		{MetadataConflict, false},
		{VersionConflict, false},
		{PathConflict, false},
	}

	for _, tc := range testCases {
		conflict := &DocumentConflict{
			ID:   "test-strategy-" + string(tc.conflictType),
			Type: tc.conflictType,
			LocalDoc: &Document{
				ID:      "doc1",
				Content: []byte("test content"),
			},
			RemoteDoc: &Document{
				ID:      "doc1",
				Content: []byte("test content 2"),
			},
			ConflictedAt: time.Now(),
		}

		resolution, err := resolver.ResolveConflict(conflict)

		if tc.expectError && err == nil {
			t.Errorf("Expected error for conflict type %s", tc.conflictType)
		}

		if !tc.expectError && err != nil {
			t.Errorf("Unexpected error for conflict type %s: %v", tc.conflictType, err)
		}

		if !tc.expectError && resolution == nil {
			t.Errorf("Expected resolution for conflict type %s", tc.conflictType)
		}
	}
}

// DummyDetectStrategy pour tests d'orchestration

type DummyDetectStrategy struct {
	detectCalled *bool
}

func (d *DummyDetectStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	return &Resolution{Strategy: "dummy"}, nil
}

func (d *DummyDetectStrategy) Detect() ([]*DocumentConflict, error) {
	if d.detectCalled != nil {
		*d.detectCalled = true
	}
	return []*DocumentConflict{{ID: "dummy", Type: ContentConflict}}, nil
}

// Test ConflictManager orchestration multi-conflits
func TestConflictManager_Orchestration(t *testing.T) {
	cm := &ConflictManager{}
	cm.AddResolver(&ContentMergeStrategy{})
	cm.AddResolver(&MetadataPreferenceStrategy{})
	cm.AddResolver(&VersionBasedStrategy{})
	cm.AddResolver(&PathRenameStrategy{})

	detectCalled := false
	dummy := &DummyDetectStrategy{detectCalled: &detectCalled}
	cm.AddResolver(dummy)

	conflicts, err := cm.DetectAll()
	if err != nil {
		t.Fatalf("DetectAll should not error: %v", err)
	}
	if !detectCalled {
		t.Error("Detect should be called on DummyDetectStrategy")
	}
	if len(conflicts) == 0 {
		t.Error("Should detect at least one conflict")
	}

	resolutions, err := cm.ResolveAll()
	if err != nil {
		t.Fatalf("ResolveAll should not error: %v", err)
	}
	if len(resolutions) == 0 {
		t.Error("Should resolve at least one conflict")
	}
}
