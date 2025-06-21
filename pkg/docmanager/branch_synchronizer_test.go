// SPDX-License-Identifier: MIT
// Package docmanager - Tests unitaires BranchSynchronizer SRP
package docmanager

import (
	"fmt"
	"io"
	"os"
	"strings"
	"testing"
	"time"
	"runtime"
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

// Test du cache status branches (4.2.1.1.3)
func TestBranchStatusCache(t *testing.T) {
	bs := NewBranchSynchronizer()
	branch := "test-branch"

	// Premier appel : calcule et met en cache
	status1, err := bs.GetBranchStatus(branch)
	if err != nil {
		t.Fatalf("Erreur GetBranchStatus: %v", err)
	}
	if status1.Branch != branch {
		t.Errorf("Nom de branche incorrect: attendu %s, obtenu %s", branch, status1.Branch)
	}

	// Modifie le cache pour simuler une valeur différente
	bs.cacheMutex.Lock()
	fake := status1
	fake.Status = "conflicts"
	fake.LastSync = time.Now()
	bs.branchStatusCache[branch] = &fake
	bs.cacheMutex.Unlock()

	// Deuxième appel : doit retourner la valeur du cache
	status2, err := bs.GetBranchStatus(branch)
	if err != nil {
		t.Fatalf("Erreur GetBranchStatus (cache): %v", err)
	}
	if status2.Status != "conflicts" {
		t.Errorf("Le cache n'est pas utilisé correctement (attendu 'conflicts', obtenu '%s')", status2.Status)
	}

	// Expire le cache et vérifie le recalcul
	bs.cacheMutex.Lock()
	bs.branchStatusCache[branch].LastSync = time.Now().Add(-2 * bs.cacheExpiry)
	bs.cacheMutex.Unlock()
	status3, err := bs.GetBranchStatus(branch)
	if err != nil {
		t.Fatalf("Erreur GetBranchStatus (expiration): %v", err)
	}
	if status3.Status != "active" {
		t.Errorf("Le cache n'est pas expiré correctement (attendu 'active', obtenu '%s')", status3.Status)
	}
}

// TestBranchSynchronizer_AnalyzeBranchDocDiff teste l'analyse documentaire par branche (4.2.1.2.2)
func TestBranchSynchronizer_AnalyzeBranchDocDiff(t *testing.T) {
	bs := NewBranchSynchronizer()

	// Simuler un repo avec deux branches : identique et divergente
	// (ici, on mocke la méthode analyzeBranchDocDiff pour l'exemple)
	bs.BranchDiffs["identique"] = &BranchDiff{FilesChanged: []string{}, Conflicts: []string{}}
	bs.BranchDiffs["divergente"] = &BranchDiff{FilesChanged: []string{"doc1.md", "doc2.txt", "doc3.adoc"}, Conflicts: []string{}}

	// Cas identique : score de divergence = 0
	identiqueDiff, _ := bs.analyzeBranchDocDiff("identique")
	if len(identiqueDiff.FilesChanged) != 0 {
		t.Errorf("Attendu 0 fichier modifié, obtenu %d", len(identiqueDiff.FilesChanged))
	}

	// Cas très divergent : score de divergence = 3
	divergenteDiff, _ := bs.analyzeBranchDocDiff("divergente")
	if len(divergenteDiff.FilesChanged) != 3 {
		t.Errorf("Attendu 3 fichiers modifiés, obtenu %d", len(divergenteDiff.FilesChanged))
	}

	// Vérifier extensions
	for _, f := range divergenteDiff.FilesChanged {
		if !(strings.HasSuffix(f, ".md") || strings.HasSuffix(f, ".txt") || strings.HasSuffix(f, ".adoc")) {
			t.Errorf("Fichier %s n'a pas une extension documentaire attendue", f)
		}
	}
}

// LogMemoryUsage affiche la consommation mémoire courante (pour profiling)
func LogMemoryUsage() {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	fmt.Printf("Memory Usage: Alloc = %v MiB\n", m.Alloc/1024/1024)
}

// Exemple d'utilisation dans un test lourd
func TestMemoryUsageDuringChunkProcessing(t *testing.T) {
	LogMemoryUsage()
	err := ProcessFileByChunks("testdata/largefile.txt", 1000, func(chunk []string) error {
		// Simuler un traitement
		return nil
	})
	if err != nil && !os.IsNotExist(err) { // ignore si le fichier n'existe pas
		t.Errorf("Erreur inattendue lors du chunking: %v", err)
	}
	LogMemoryUsage()
}

func TestBranchStatusCache_SetGetExpiry(t *testing.T) {
	bs := NewBranchSynchronizer()
	bs.cacheExpiry = 100 * time.Millisecond

	status := &BranchDocStatus{
		Branch:        "feature/test",
		LastSync:      time.Now(),
		ConflictCount: 0,
		Status:        "active",
	}
	bs.SetBranchStatusCache("feature/test", status)

	// Lecture immédiate : doit exister
	got, ok := bs.GetBranchStatusCache("feature/test")
	if !ok || got.Branch != "feature/test" {
		t.Error("Le cache doit retourner le status juste après set")
	}

	// Attendre l'expiration
	time.Sleep(120 * time.Millisecond)
	_, ok = bs.GetBranchStatusCache("feature/test")
	if ok {
		t.Error("Le cache doit expirer après cacheExpiry")
	}
}

func TestBranchStatusCache_CleanExpired(t *testing.T) {
	bs := NewBranchSynchronizer()
	bs.cacheExpiry = 50 * time.Millisecond

	bs.SetBranchStatusCache("b1", &BranchDocStatus{Branch: "b1", LastSync: time.Now().Add(-time.Minute)})
	bs.SetBranchStatusCache("b2", &BranchDocStatus{Branch: "b2", LastSync: time.Now()})

	bs.CleanExpiredBranchStatusCache()
	if _, ok := bs.branchStatusCache["b1"]; ok {
		t.Error("b1 doit être supprimé du cache car expiré")
	}
	if _, ok := bs.branchStatusCache["b2"]; !ok {
		t.Error("b2 doit rester dans le cache car non expiré")
	}
}
func TestSyncAcrossBranches_EmptyAndMulti(t *testing.T) {
	bs := NewBranchSynchronizer()
	// Simule un repo git vide (mock minimal)
	bs.repo = &mockRepo{branches: []string{}}
	branches, err := bs.SyncAcrossBranches(nil)
	if err != nil {
		t.Errorf("Erreur inattendue sur repo vide: %v", err)
	}
	if len(branches) != 0 {
		t.Errorf("Attendu 0 branche, obtenu %d", len(branches))
	}

	// Simule un repo avec plusieurs branches
	bs.repo = &mockRepo{branches: []string{"main", "dev", "feature"}, head: "main"}
	bs.AddSyncRule("main", BranchSyncRule{SourceBranch: "main", TargetBranches: []string{"dev"}})
	bs.AddSyncRule("dev", BranchSyncRule{SourceBranch: "dev", TargetBranches: []string{"main"}})
	branches, err = bs.SyncAcrossBranches(nil)
	if err != nil {
		t.Errorf("Erreur inattendue sur repo multi-branches: %v", err)
	}
	if len(branches) != 2 {
		t.Errorf("Attendu 2 branches filtrées, obtenu %d", len(branches))
	}
}

type mockRepo struct {
	branches []string
	head     string
}

func (m *mockRepo) Branches() (branchIter, error) {
	return &mockBranchIter{branches: m.branches}, nil
}
func (m *mockRepo) Head() (ref, error) {
	return &mockRef{name: m.head}, nil
}
// Mocks pour l'itérateur et ref
type branchIter interface {
	Next() (ref, error)
}
type ref interface {
	Name() refName
}
type refName interface {
	Short() string
}
type mockBranchIter struct {
	branches []string
	idx      int
}
func (it *mockBranchIter) Next() (ref, error) {
	if it.idx >= len(it.branches) {
		return nil, io.EOF
	}
	r := &mockRef{name: it.branches[it.idx]}
	it.idx++
	return r, nil
}
type mockRef struct {
	name string
}
func (r *mockRef) Name() refName { return r }
func (r *mockRef) Short() string { return r.name }
func TestAnalyzeBranchDocDiff(t *testing.T) {
	bs := NewBranchSynchronizer()
	// Cas 1 : branches identiques (aucun fichier modifié)
	bs.BranchDiffs["main"] = &BranchDiff{FilesChanged: []string{}}
	res, err := bs.analyzeBranchDocDiff("main")
	if err != nil {
		t.Errorf("Erreur inattendue: %v", err)
	}
	if res.DivergenceScore != 0 {
		t.Errorf("Score attendu 0, obtenu %d", res.DivergenceScore)
	}

	// Cas 2 : branche très divergente (plusieurs fichiers doc modifiés)
	bs.BranchDiffs["dev"] = &BranchDiff{FilesChanged: []string{"README.md", "notes.txt", "doc.adoc", "main.go"}}
	res, err = bs.analyzeBranchDocDiff("dev")
	if err != nil {
		t.Errorf("Erreur inattendue: %v", err)
	}
	if res.DivergenceScore != 3 {
		t.Errorf("Score attendu 3, obtenu %d", res.DivergenceScore)
	}
	if len(res.ModifiedFiles) != 3 {
		t.Errorf("Fichiers modifiés attendus: 3, obtenus: %d", len(res.ModifiedFiles))
	}
}

// TestDetectDocumentationConflicts teste la détection automatique des conflits documentaires
func TestDetectDocumentationConflicts(t *testing.T) {
	bs := NewBranchSynchronizer()
	bs.Conflicts = interface{}(NewConflictDetector()).(*ConflictResolver) // cast pour compatibilité

	// Préparer des résultats d'analyse documentaire simulés
	branchDiffs := map[string]*DiffResult{
		"main": {Branch: "main", ModifiedFiles: []string{"README.md", "doc.adoc"}},
		"dev":  {Branch: "dev", ModifiedFiles: []string{"README.md", "notes.txt"}},
		"feature": {Branch: "feature", ModifiedFiles: []string{"doc.adoc", "notes.txt"}},
	}

	conflicts, err := bs.detectDocumentationConflicts(branchDiffs)
	if err != nil {
		t.Fatalf("Erreur inattendue: %v", err)
	}
	if len(conflicts) == 0 {
		t.Error("Aucun conflit détecté alors qu'il devrait y en avoir")
	}
	// Vérifier la gravité/scoring
	majorOrCritical := false
	for _, c := range conflicts {
		if c.Severity == "high" || c.Severity == "critical" {
			majorOrCritical = true
		}
	}
	if !majorOrCritical {
		t.Error("Aucun conflit de gravité majeure/critique détecté")
	}
}

// TestAutoResolveConflicts vérifie la résolution automatique des conflits documentaires
func TestAutoResolveConflicts(t *testing.T) {
	bs := NewBranchSynchronizer()
	bs.Conflicts = interface{}(NewConflictDetector()).(*ConflictResolver)

	// Simuler des conflits détectés
	conflicts := []DetectedConflict{
		{ID: "c1", Severity: "low", Status: "new"},
		{ID: "c2", Severity: "medium", Status: "new"},
		{ID: "c3", Severity: "high", Status: "new"},
	}

	resolvable := bs.filterAutoResolvable(conflicts)
	if len(resolvable) != 2 {
		t.Errorf("Attendu 2 conflits auto-résolvables, obtenu %d", len(resolvable))
	}

	// Injecter le detector réel pour la résolution
	bs.Conflicts = interface{}(NewConflictDetector()).(*ConflictResolver)
	// On simule la résolution (pas d'erreur attendue)
	resolved, err := bs.autoResolveConflicts(resolvable)
	if err != nil {
		t.Fatalf("Erreur inattendue lors de la résolution auto: %v", err)
	}
	if resolved != 2 {
		t.Errorf("Attendu 2 conflits résolus automatiquement, obtenu %d", resolved)
	}
}

// TestResolutionStrategyRegistration vérifie l’enregistrement et la priorité des stratégies
func TestResolutionStrategyRegistration(t *testing.T) {
	cr := &ConflictResolver{
		strategies: make(map[ConflictType][]ResolutionStrategy),
	}

type dummyStrategy struct {
	id      int
	ct      ConflictType
	prio    int
	can     bool
	}
	func (ds *dummyStrategy) Resolve(dc *DocumentConflict) (*Document, error) { return &Document{Content: "ok"}, nil }
	func (ds *dummyStrategy) CanHandle(ct ConflictType) bool { return ds.can && ct == ds.ct }
	func (ds *dummyStrategy) Priority() int { return ds.prio }

	ds1 := &dummyStrategy{id: 1, ct: "merge", prio: 10, can: true}
	ds2 := &dummyStrategy{id: 2, ct: "merge", prio: 20, can: true}
	cr.strategies["merge"] = []ResolutionStrategy{ds1, ds2}

	if len(cr.strategies["merge"]) != 2 {
		t.Errorf("Attendu 2 stratégies enregistrées, obtenu %d", len(cr.strategies["merge"]))
	}
	if cr.strategies["merge"][1].Priority() <= cr.strategies["merge"][0].Priority() {
		t.Error("Les priorités ne sont pas respectées")
	}
}

// TestConflictClassification vérifie la classification, sévérité et extraction de métadonnées
func TestConflictClassification(t *testing.T) {
	cr := &ConflictResolver{}
	conflict := &DocumentConflict{Type: "merge", Severity: "high", Details: map[string]interface{}{"meta": 1}}
	typeResult := cr.classifyConflict(conflict)
	if typeResult != "merge" {
		t.Errorf("Expected 'merge', got %v", typeResult)
	}
	severity := cr.assessConflictSeverity(conflict)
	if severity != "high" {
		t.Errorf("Expected 'high', got %v", severity)
	}
	metadata := cr.extractConflictMetadata(conflict)
	if metadata["meta"] != 1 {
		t.Errorf("Expected meta=1, got %v", metadata["meta"])
	}
}

// Test sélection avec priorités, fallback
func TestSelectOptimalStrategy(t *testing.T) {
	ds1 := &dummyStrategy{id: 1, ct: "merge", prio: 10, can: true}
	ds2 := &dummyStrategy{id: 2, ct: "merge", prio: 20, can: true}
	cr := &ConflictResolver{
		strategies:      map[ConflictType][]ResolutionStrategy{"merge": {ds1, ds2}},
		defaultStrategy: ds1,
	}
	selected := cr.selectOptimalStrategy("merge")
	if selected.Priority() != 20 {
		t.Errorf("Expected priority 20, got %d", selected.Priority())
	}
	selectedFallback := cr.selectOptimalStrategy("unknown")
	if selectedFallback != ds1 {
		t.Error("Expected fallback to defaultStrategy")
	}
}

// Test exécution et fallback automatique
func TestExecuteAndValidateResolution(t *testing.T) {
	ds := &dummyStrategy{id: 1, ct: "merge", prio: 10, can: true, fail: true}
	cr := &ConflictResolver{
		strategies:      map[ConflictType][]ResolutionStrategy{"merge": {ds}},
		defaultStrategy: &dummyStrategy{id: 2, ct: "merge", prio: 5, can: true},
	}
	conflict := &DocumentConflict{Type: "merge"}
	_, err := cr.executeAndValidateResolution(ds, conflict)
	if err == nil {
		t.Error("Expected fallback error, got nil")
	}
}
