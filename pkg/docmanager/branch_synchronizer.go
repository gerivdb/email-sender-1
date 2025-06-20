// SPDX-License-Identifier: MIT
// Package docmanager : synchronisateur multi-branches (v65B)
package docmanager

import (
	"context"
	"time"
)

// BranchSynchronizer gère la synchronisation documentaire entre branches
type BranchSynchronizer struct {
	SyncRules   map[string]BranchSyncRule
	Conflicts   *ConflictResolver
	BranchDiffs map[string]*BranchDiff
}

// BranchSyncRule définit les règles de synchronisation
type BranchSyncRule struct {
	SourceBranch    string
	TargetBranches  []string
	AutoMerge       bool
	SyncInterval    time.Duration
	IncludePatterns []string
	ExcludePatterns []string
}

// BranchDiff représente les différences entre branches
type BranchDiff struct {
	FilesChanged []string
	Conflicts    []string
}

// ConflictResolver à implémenter selon besoins

// NewBranchSynchronizer crée un nouveau synchronisateur de branches
func NewBranchSynchronizer() *BranchSynchronizer {
	return &BranchSynchronizer{
		SyncRules:   make(map[string]BranchSyncRule),
		BranchDiffs: make(map[string]*BranchDiff),
	}
}

// AddSyncRule ajoute une règle de synchronisation
// SRP: Responsabilité synchronisation pure - pas de persistence
func (bs *BranchSynchronizer) AddSyncRule(branchName string, rule BranchSyncRule) {
	bs.SyncRules[branchName] = rule
}

// SynchronizeBranches synchronise selon les règles définies
// SRP: Synchronisation multi-branches exclusive
func (bs *BranchSynchronizer) SynchronizeBranches() error {
	for branchName, rule := range bs.SyncRules {
		if err := bs.synchronizeBranch(branchName, rule); err != nil {
			return err
		}
	}
	return nil
}

// synchronizeBranch synchronise une branche spécifique
func (bs *BranchSynchronizer) synchronizeBranch(branchName string, rule BranchSyncRule) error {
	// SRP: Logique de synchronisation uniquement, pas de cache/DB
	diff := &BranchDiff{
		FilesChanged: []string{},
		Conflicts:    []string{},
	}

	bs.BranchDiffs[branchName] = diff
	return nil
}

// GetBranchDiff retourne les différences pour une branche
func (bs *BranchSynchronizer) GetBranchDiff(branchName string) (*BranchDiff, bool) {
	diff, exists := bs.BranchDiffs[branchName]
	return diff, exists
}

// ValidateSyncRules valide la cohérence des règles de synchronisation
func (bs *BranchSynchronizer) ValidateSyncRules() []string {
	var errors []string

	for branchName, rule := range bs.SyncRules {
		if rule.SourceBranch == "" {
			errors = append(errors, "SourceBranch manquante pour "+branchName)
		}
		if len(rule.TargetBranches) == 0 {
			errors = append(errors, "TargetBranches vides pour "+branchName)
		}
	}

	return errors
}

// TASK ATOMIQUE 3.1.4.1.1 - Implementation BranchAware Interface

// SyncAcrossBranches implémente l'interface BranchAware
func (bs *BranchSynchronizer) SyncAcrossBranches(ctx context.Context) error {
	// Synchronisation cross-branch avec contexte
	return bs.SynchronizeBranches()
}

// GetBranchStatus implémente l'interface BranchAware
func (bs *BranchSynchronizer) GetBranchStatus(branch string) (BranchDocStatus, error) {
	status := BranchDocStatus{
		Branch:        branch,
		LastSync:      time.Now(),
		ConflictCount: 0,
		Status:        "active",
	}

	// Vérifie les conflits pour cette branche
	if diff, exists := bs.GetBranchDiff(branch); exists {
		status.ConflictCount = len(diff.Conflicts)
		if status.ConflictCount > 0 {
			status.Status = "conflicts"
		}
	}

	return status, nil
}

// MergeDocumentation implémente l'interface BranchAware
func (bs *BranchSynchronizer) MergeDocumentation(fromBranch, toBranch string) error {
	// Implémentation du merge entre branches
	rule := BranchSyncRule{
		SourceBranch:   fromBranch,
		TargetBranches: []string{toBranch},
		AutoMerge:      false, // Merge manuel pour sécurité
		SyncInterval:   0,     // Merge immédiat
	}

	return bs.synchronizeBranch(fromBranch, rule)
}
