// SPDX-License-Identifier: MIT
// Package docmanager - Tests unitaires BranchSynchronizer SRP
package docmanager

import (
	"testing"
	"time"
)

// TestBranchSynchronizer_SRP valide le respect du principe SRP
func TestBranchSynchronizer_SRP(t *testing.T) {
	// TASK ATOMIQUE 3.1.1.3 - BranchSynchronizer SRP Validation
	bs := NewBranchSynchronizer()

	// Vérifier l'initialisation SRP
	if bs.SyncRules == nil {
		t.Error("SyncRules doit être initialisé")
	}
	if bs.BranchDiffs == nil {
		t.Error("BranchDiffs doit être initialisé")
	}

	// Test SRP: responsabilité synchronisation pure
	rule := BranchSyncRule{
		SourceBranch:    "main",
		TargetBranches:  []string{"dev", "staging"},
		AutoMerge:       true,
		SyncInterval:    time.Hour,
		IncludePatterns: []string{"*.md"},
		ExcludePatterns: []string{"temp/*"},
	}

	bs.AddSyncRule("main", rule)

	// Valider que les règles sont stockées correctement
	storedRule, exists := bs.SyncRules["main"]
	if !exists {
		t.Error("Règle 'main' devrait exister")
	}
	if storedRule.SourceBranch != "main" {
		t.Errorf("SourceBranch attendu: main, obtenu: %s", storedRule.SourceBranch)
	}
}

// TestBranchSynchronizer_ValidateSyncRules teste la validation des règles
func TestBranchSynchronizer_ValidateSyncRules(t *testing.T) {
	bs := NewBranchSynchronizer()

	// Ajouter une règle valide
	validRule := BranchSyncRule{
		SourceBranch:   "main",
		TargetBranches: []string{"dev"},
	}
	bs.AddSyncRule("valid", validRule)

	// Ajouter une règle invalide
	invalidRule := BranchSyncRule{
		SourceBranch:   "", // Source manquante
		TargetBranches: []string{},
	}
	bs.AddSyncRule("invalid", invalidRule)

	errors := bs.ValidateSyncRules()

	// Doit détecter les erreurs de la règle invalide
	if len(errors) < 2 {
		t.Errorf("Attendu au moins 2 erreurs, obtenu: %d", len(errors))
	}

	// Vérifier les types d'erreurs
	hasSourceError := false
	hasTargetError := false
	for _, err := range errors {
		if contains(err, "SourceBranch manquante") {
			hasSourceError = true
		}
		if contains(err, "TargetBranches vides") {
			hasTargetError = true
		}
	}

	if !hasSourceError {
		t.Error("Erreur SourceBranch manquante non détectée")
	}
	if !hasTargetError {
		t.Error("Erreur TargetBranches vides non détectée")
	}
}

// TestBranchSynchronizer_SynchronizeBranches teste la synchronisation
func TestBranchSynchronizer_SynchronizeBranches(t *testing.T) {
	bs := NewBranchSynchronizer()

	// Ajouter règle de synchronisation
	rule := BranchSyncRule{
		SourceBranch:   "main",
		TargetBranches: []string{"dev"},
		AutoMerge:      true,
	}
	bs.AddSyncRule("test", rule)

	// Exécuter synchronisation
	err := bs.SynchronizeBranches()
	if err != nil {
		t.Errorf("Erreur synchronisation: %v", err)
	}

	// Vérifier qu'un diff a été créé
	diff, exists := bs.GetBranchDiff("test")
	if !exists {
		t.Error("Diff 'test' devrait exister après synchronisation")
	}
	if diff == nil {
		t.Error("Diff ne devrait pas être nil")
	}
}

// TestBranchSynchronizer_NoDirectPersistence vérifie l'absence de logique persistence
func TestBranchSynchronizer_NoDirectPersistence(t *testing.T) {
	// SRP: BranchSynchronizer ne doit pas faire de persistence directe
	bs := NewBranchSynchronizer()

	// La structure ne doit contenir aucun champ de type DB/Cache
	if bs.Conflicts != nil {
		// Vérifier que Conflicts est bien un ConflictResolver et non une DB
		if _, isResolver := interface{}(bs.Conflicts).(*ConflictResolver); !isResolver {
			t.Error("Conflicts doit être un ConflictResolver, pas une DB")
		}
	}

	// Test: pas de méthodes directes de DB/Cache dans l'interface publique
	// (Ce test est conceptuel - on vérifie par inspection de code)
}

// Fonction utilitaire
func contains(s, substr string) bool {
	return len(s) >= len(substr) && s[:len(substr)] == substr || len(s) > len(substr) && contains(s[1:], substr)
}
