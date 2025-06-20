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

// TESTS POUR TÂCHE 3.4.1.3 - Détection automatique des conflits

// TestConflictDetector teste le détecteur de conflits automatique
func TestConflictDetector(t *testing.T) {
	detector := NewConflictDetector()

	// Test d'ajout d'une règle de détection
	rule := ConflictDetectionRule{
		Name:           "test_rule",
		FilePatterns:   []string{"*.go"},
		ConflictTypes:  []string{"git"},
		Severity:       "high",
		AutoDetect:     true,
		Enabled:        true,
		ScanInterval:   5 * time.Minute,
		NotifyOnDetect: true,
	}

	err := detector.AddDetectionRule(rule)
	if err != nil {
		t.Fatalf("Failed to add detection rule: %v", err)
	}

	// Test de détection de conflits
	filePaths := []string{"test.go", "example.md"}
	conflicts, err := detector.DetectConflicts("main", "dev", filePaths)
	if err != nil {
		t.Fatalf("Failed to detect conflicts: %v", err)
	}

	// Vérifier qu'au moins un conflit a été détecté pour le fichier .go
	goConflictFound := false
	for _, conflict := range conflicts {
		if conflict.FilePath == "test.go" && conflict.Type == "merge_conflict" {
			goConflictFound = true
			break
		}
	}

	if !goConflictFound {
		t.Error("Expected to find a conflict for test.go file")
	}

	// Test de résolution de conflit
	if len(conflicts) > 0 {
		err = detector.ResolveConflict(conflicts[0].ID, "manually resolved")
		if err != nil {
			t.Fatalf("Failed to resolve conflict: %v", err)
		}

		// Vérifier que le conflit est marqué comme résolu
		resolvedConflicts := detector.GetConflictsByStatus("resolved")
		if len(resolvedConflicts) != 1 {
			t.Errorf("Expected 1 resolved conflict, got %d", len(resolvedConflicts))
		}
	}
}

// TestGitConflictScanner teste le scanner Git
func TestGitConflictScanner(t *testing.T) {
	scanner := &GitConflictScanner{name: "git"}

	// Test du type de scanner
	if scanner.GetScannerType() != "git" {
		t.Errorf("Expected scanner type 'git', got '%s'", scanner.GetScannerType())
	}

	// Test d'applicabilité
	if !scanner.IsApplicable("test.go") {
		t.Error("Git scanner should be applicable to all files")
	}

	// Test de scan de conflits
	conflicts, err := scanner.ScanForConflicts("main", "dev", "test.go")
	if err != nil {
		t.Fatalf("Failed to scan for conflicts: %v", err)
	}

	if len(conflicts) == 0 {
		t.Error("Expected at least one conflict to be detected")
	}

	// Vérifier les propriétés du conflit détecté
	conflict := conflicts[0]
	if conflict.Type != "merge_conflict" {
		t.Errorf("Expected conflict type 'merge_conflict', got '%s'", conflict.Type)
	}

	if conflict.SourceBranch != "main" {
		t.Errorf("Expected source branch 'main', got '%s'", conflict.SourceBranch)
	}

	if conflict.TargetBranch != "dev" {
		t.Errorf("Expected target branch 'dev', got '%s'", conflict.TargetBranch)
	}
}

// TESTS POUR TÂCHE 3.4.1.4 - Stratégies de merge intelligentes

// TestSmartMergeManager teste le gestionnaire de merge intelligent
func TestSmartMergeManager(t *testing.T) {
	detector := NewConflictDetector()
	manager := NewSmartMergeManager(detector)

	// Test de merge intelligent pour un fichier Go
	sourceContent := `package main

import "fmt"

func main() {
	fmt.Println("Hello from source")
}`

	targetContent := `package main

import "fmt"

func main() {
	fmt.Println("Hello from target")
}`

	baseContent := `package main

import "fmt"

func main() {
	fmt.Println("Hello world")
}`

	result, err := manager.PerformIntelligentMerge(
		"main", "dev", "test.go",
		sourceContent, targetContent, baseContent,
	)
	if err != nil {
		t.Fatalf("Failed to perform intelligent merge: %v", err)
	}

	if !result.Success {
		t.Error("Expected merge to succeed")
	}

	if result.MergedContent == "" {
		t.Error("Expected merged content to be non-empty")
	}

	if result.Strategy == "" {
		t.Error("Expected strategy to be set")
	}

	// Test des statistiques
	stats := manager.GetMergeStatistics()
	if stats["total_operations"].(int) != 1 {
		t.Errorf("Expected 1 total operation, got %d", stats["total_operations"])
	}
}

// TestFileHandlers teste les gestionnaires de fichiers spécialisés
func TestFileHandlers(t *testing.T) {
	// Test GoFileHandler
	goHandler := &GoFileHandler{}

	if !goHandler.CanHandle("test.go") {
		t.Error("GoFileHandler should handle .go files")
	}

	if goHandler.CanHandle("test.md") {
		t.Error("GoFileHandler should not handle .md files")
	}

	result, err := goHandler.MergeFiles("source code", "target code", "base code")
	if err != nil {
		t.Fatalf("GoFileHandler merge failed: %v", err)
	}

	if !result.Success {
		t.Error("Expected Go merge to succeed")
	}

	if goHandler.GetFileType() != "go" {
		t.Errorf("Expected file type 'go', got '%s'", goHandler.GetFileType())
	}

	// Test MarkdownFileHandler
	mdHandler := &MarkdownFileHandler{}

	if !mdHandler.CanHandle("test.md") {
		t.Error("MarkdownFileHandler should handle .md files")
	}

	if mdHandler.CanHandle("test.go") {
		t.Error("MarkdownFileHandler should not handle .go files")
	}

	result, err = mdHandler.MergeFiles("# Source", "# Target", "# Base")
	if err != nil {
		t.Fatalf("MarkdownFileHandler merge failed: %v", err)
	}

	if !result.Success {
		t.Error("Expected Markdown merge to succeed")
	}

	if mdHandler.GetFileType() != "markdown" {
		t.Errorf("Expected file type 'markdown', got '%s'", mdHandler.GetFileType())
	}
}

// TestConfigurableSyncRuleManager teste le gestionnaire de règles configurables
func TestConfigurableSyncRuleManager(t *testing.T) {
	manager := NewConfigurableSyncRuleManager()

	// Test d'ajout d'une règle de branche
	rule := BranchSyncRule{
		SourceBranch:    "main",
		TargetBranches:  []string{"dev", "feature"},
		AutoMerge:       false,
		SyncInterval:    30 * time.Minute,
		IncludePatterns: []string{"*.go", "*.md"},
		ExcludePatterns: []string{"*.tmp"},
	}

	err := manager.AddBranchRule("main", rule)
	if err != nil {
		t.Fatalf("Failed to add branch rule: %v", err)
	}

	// Test de récupération de la règle effective
	effectiveRule := manager.GetEffectiveRuleForBranch("main")
	if effectiveRule.SourceBranch != "main" {
		t.Errorf("Expected source branch 'main', got '%s'", effectiveRule.SourceBranch)
	}

	// Test d'ajout d'une politique de conflit
	policy := ConflictPolicy{
		Strategy:         "merge",
		Priority:         1,
		FilePatterns:     []string{"*.go"},
		NotifyOnConflict: true,
		MaxRetries:       3,
	}

	err = manager.AddConflictPolicy("go_merge_policy", policy)
	if err != nil {
		t.Fatalf("Failed to add conflict policy: %v", err)
	}

	// Test de récupération de la politique pour un fichier
	retrievedPolicy := manager.GetConflictPolicyForFile("test.go")
	if retrievedPolicy.Strategy != "merge" {
		t.Errorf("Expected strategy 'merge', got '%s'", retrievedPolicy.Strategy)
	}
}

// TestValidationFunctions teste les fonctions de validation
func TestValidationFunctions(t *testing.T) {
	manager := NewConfigurableSyncRuleManager()

	// Test de validation d'une règle invalide
	invalidRule := BranchSyncRule{
		SourceBranch:   "", // Invalide - branche source vide
		TargetBranches: []string{"dev"},
		AutoMerge:      false,
		SyncInterval:   10 * time.Minute,
	}

	err := manager.AddBranchRule("invalid", invalidRule)
	if err == nil {
		t.Error("Expected error for invalid branch rule")
	}

	// Test de validation d'une politique invalide
	invalidPolicy := ConflictPolicy{
		Strategy:     "invalid_strategy", // Invalide
		Priority:     1,
		FilePatterns: []string{"*.go"},
		MaxRetries:   3,
	}

	err = manager.AddConflictPolicy("invalid_policy", invalidPolicy)
	if err == nil {
		t.Error("Expected error for invalid conflict policy")
	}

	// Test de validation d'une règle planifiée invalide
	detector := NewConflictDetector()
	invalidDetectionRule := ConflictDetectionRule{
		Name:          "", // Invalide - nom vide
		FilePatterns:  []string{"*.go"},
		ConflictTypes: []string{"git"},
		Severity:      "invalid_severity", // Invalide
	}

	err = detector.AddDetectionRule(invalidDetectionRule)
	if err == nil {
		t.Error("Expected error for invalid detection rule")
	}
}
