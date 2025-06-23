// SPDX-License-Identifier: MIT
// Tests SRP pour ConflictResolver - TASK ATOMIQUE 3.1.1.4
package docmanager

import (
	"fmt"
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

// Test granularisé pour ConflictResolverImpl
type DummyStrategy struct{}

func (d *DummyStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) {
	return &Resolution{Strategy: "dummy", Confidence: 1.0}, nil
}

func TestConflictResolverImpl_Behavior(t *testing.T) {
	cr := NewConflictResolverImpl()
	cr.strategies[ContentConflict] = &DummyStrategy{}

	conflict := &DocumentConflict{
		ID:           "c1",
		Type:         ContentConflict,
		LocalDoc:     &Document{ID: "doc1", Version: 1},
		RemoteDoc:    &Document{ID: "doc1", Version: 2},
		ConflictedAt: time.Now(),
	}

	// Test Resolve
	res, err := cr.Resolve(conflict)
	if err != nil {
		t.Errorf("Resolve should not error: %v", err)
	}
	if res == nil || res.Strategy != "dummy" {
		t.Error("Expected dummy strategy resolution")
	}

	// Test Score
	score := cr.Score(conflict)
	if score != 1.0 {
		t.Errorf("Expected score 1.0, got %v", score)
	}

	// Test Detect (ici vide)
	conflicts, err := cr.Detect()
	if err != nil {
		t.Errorf("Detect should not error: %v", err)
	}
	if len(conflicts) != 0 {
		t.Errorf("Expected no conflicts, got %d", len(conflicts))
	}
}

func TestConflictAndResolutionGranular(t *testing.T) {
	c := Conflict{
		Type:         ConflictTypeContent,
		Severity:     Medium,
		Participants: []string{"user1", "user2"},
		Metadata:     map[string]interface{}{"key": "value"},
	}
	if c.Type != ConflictTypeContent || c.Severity != Medium {
		t.Error("Conflict struct fields not set correctly")
	}
	r := ResolutionGranular{
		Status:    Resolved,
		Strategy:  "auto",
		AppliedAt: time.Now(),
		Rollback:  func() error { return nil },
	}
	if r.Status != Resolved || r.Strategy != "auto" {
		t.Error("ResolutionGranular struct fields not set correctly")
	}
}

<<<<<<< HEAD
func TestLastModifiedWins(t *testing.T) {
	// Cas : timestamps identiques
	timestamp := time.Now()
	docA := &Document{ID: "A", Metadata: map[string]interface{}{"LastModified": timestamp, "tags": []string{"t1"}, "authors": []string{"a1"}}}
	docB := &Document{ID: "B", Metadata: map[string]interface{}{"LastModified": timestamp, "tags": []string{"t2"}, "authors": []string{"a2"}}}
	conflict := &DocumentConflict{LocalDoc: docA, RemoteDoc: docB}
	lmw := &LastModifiedWins{}
	res, err := lmw.Resolve(conflict)
	if err != nil {
		t.Fatalf("Erreur inattendue: %v", err)
	}
	if res.ResolvedDoc == nil {
		t.Error("Document résolu manquant")
	}
	if res.ResolvedDoc.ID != "B" && res.ResolvedDoc.ID != "A" {
		t.Errorf("Résolution inattendue: %v", res.ResolvedDoc.ID)
	}
	// Cas : différence microseconde
	delta := time.Microsecond
	docA.Metadata["LastModified"] = timestamp.Add(delta)
	res, err = lmw.Resolve(conflict)
	if err != nil {
		t.Fatalf("Erreur inattendue: %v", err)
	}
	if res.ResolvedDoc.ID != "A" {
		t.Errorf("A doit gagner (plus récent), obtenu: %v", res.ResolvedDoc.ID)
	}
	// Vérifier fusion métadonnées (tags, auteurs)
	tags, ok := res.ResolvedDoc.Metadata["tags"].([]string)
	if !ok || len(tags) < 2 {
		t.Error("Fusion des tags incomplète")
	}
	authors, ok := res.ResolvedDoc.Metadata["authors"].([]string)
	if !ok || len(authors) < 2 {
		t.Error("Fusion des auteurs incomplète")
	}
}

func TestQualityBasedStrategy(t *testing.T) {
	// Setup : docLowQuality (50 mots, pas de structure)
	lowText := "mot " + string(make([]byte, 49))
	docLow := &Document{
		ID:      "low",
		Content: []byte(lowText),
		Metadata: map[string]interface{}{"LastModified": time.Now().Add(-2 * time.Hour)},
	}
	// Setup : docHighQuality (500 mots, headers, liens, images)
	highText := "# Header\n" +
		"Ceci est un document de test avec beaucoup de contenu. " +
		string(make([]byte, 480)) +
		"\n## Sous-titre\n" +
		"Voir https://example.com et ![img](img.png)"
	docHigh := &Document{
		ID:      "high",
		Content: []byte(highText),
		Metadata: map[string]interface{}{"LastModified": time.Now()},
	}
	conflict := &DocumentConflict{LocalDoc: docLow, RemoteDoc: docHigh}
	strategy := &QualityBasedStrategy{MinScore: 100}

	scoreLow := calculateQualityScore(docLow)
	scoreHigh := calculateQualityScore(docHigh)
	if scoreHigh <= scoreLow*2 {
		t.Errorf("Le score high doit être au moins le double du low (got %v vs %v)", scoreHigh, scoreLow)
	}
	if scoreLow == 0 {
		t.Error("Le score low ne doit pas être nul")
	}
	if scoreHigh == 0 {
		t.Error("Le score high ne doit pas être nul")
	}
	// Résolution
	res, err := strategy.Resolve(conflict)
	if err != nil {
		t.Fatalf("Erreur inattendue: %v", err)
	}
	if res.ResolvedDoc.ID != "high" {
		t.Errorf("La version high quality doit gagner (got %v)", res.ResolvedDoc.ID)
	}
	if res.Strategy != "quality_based" {
		t.Errorf("Stratégie attendue: quality_based, obtenu: %v", res.Strategy)
	}
	if res.Confidence < 0.5 {
		t.Errorf("Confidence trop faible: %v", res.Confidence)
	}
	// Fallback : si les deux scores sont trop faibles
	strategy.MinScore = 1e6
	res, err = strategy.Resolve(conflict)
	if err != nil {
		t.Fatalf("Erreur fallback inattendue: %v", err)
	}
	if res.Strategy != "manual" {
		t.Errorf("Fallback attendu: manual, obtenu: %v", res.Strategy)
	}
}

// Test UserPromptStrategy avec un mock prompter
func TestUserPromptStrategy(t *testing.T) {
	mock := &MockPrompter{choice: "remote"}
	strategy := &UserPromptStrategy{Prompter: mock}
	docA := &Document{ID: "A", Content: []byte("A"), Metadata: map[string]interface{}{"LastModified": time.Now()}}
	docB := &Document{ID: "B", Content: []byte("B"), Metadata: map[string]interface{}{"LastModified": time.Now()}}
	conflict := &DocumentConflict{LocalDoc: docA, RemoteDoc: docB}
	res, err := strategy.Resolve(conflict)
	if err != nil {
		t.Fatalf("Erreur inattendue: %v", err)
	}
	if res.ResolvedDoc.ID != "B" {
		t.Errorf("La version remote doit gagner (got %v)", res.ResolvedDoc.ID)
	}
	if res.Strategy != "user_prompt" {
		t.Errorf("Stratégie attendue: user_prompt, obtenu: %v", res.Strategy)
	}
	// Test fallback si prompter nil
	strategy = &UserPromptStrategy{Prompter: nil}
	res, err = strategy.Resolve(conflict)
	if err != nil {
		t.Fatalf("Erreur fallback inattendue: %v", err)
	}
	if res.Strategy != "manual" {
		t.Errorf("Fallback attendu: manual, obtenu: %v", res.Strategy)
	}
}

type MockPrompter struct {
	choice string
}

func (m *MockPrompter) PromptUser(conflict *DocumentConflict) (string, error) {
	return m.choice, nil
}

// Test AutoMergeStrategy (fusion automatique et rollback)
func TestAutoMergeStrategy(t *testing.T) {
	strategy := &AutoMergeStrategy{}
	// Cas : contenus identiques
	docA := &Document{ID: "A", Content: []byte("ligne1\nligne2"), Metadata: map[string]interface{}{"LastModified": time.Now()}, Version: 1}
	docB := &Document{ID: "B", Content: []byte("ligne1\nligne2"), Metadata: map[string]interface{}{"LastModified": time.Now()}, Version: 2}
	conflict := &DocumentConflict{LocalDoc: docA, RemoteDoc: docB}
	res, err := strategy.Resolve(conflict)
	if err != nil {
		t.Fatalf("Erreur inattendue: %v", err)
	}
	if res.Strategy != "auto_merge" {
		t.Errorf("Stratégie attendue: auto_merge, obtenu: %v", res.Strategy)
	}
	// Cas : contenus sans lignes en commun (fusion)
	docA = &Document{ID: "A", Content: []byte("a1\na2"), Metadata: map[string]interface{}{"LastModified": time.Now()}, Version: 1}
	docB = &Document{ID: "B", Content: []byte("b1\nb2"), Metadata: map[string]interface{}{"LastModified": time.Now()}, Version: 2}
	conflict = &DocumentConflict{LocalDoc: docA, RemoteDoc: docB}
	res, err = strategy.Resolve(conflict)
	if err != nil {
		t.Fatalf("Erreur inattendue: %v", err)
	}
	if res.Strategy != "auto_merge" {
		t.Errorf("Stratégie attendue: auto_merge, obtenu: %v", res.Strategy)
	}
	if string(res.ResolvedDoc.Content) != "a1\na2\nb1\nb2" {
		t.Errorf("Fusion attendue: a1\na2\nb1\nb2, obtenu: %v", string(res.ResolvedDoc.Content))
	}
	// Cas : contenus avec conflit (ligne commune)
	docA = &Document{ID: "A", Content: []byte("x\ny"), Metadata: map[string]interface{}{"LastModified": time.Now()}, Version: 1}
	docB = &Document{ID: "B", Content: []byte("y\nz"), Metadata: map[string]interface{}{"LastModified": time.Now()}, Version: 2}
	conflict = &DocumentConflict{LocalDoc: docA, RemoteDoc: docB}
	res, err = strategy.Resolve(conflict)
	if err != nil {
		t.Fatalf("Erreur inattendue: %v", err)
	}
	if res.Strategy != "manual" {
		t.Errorf("Rollback attendu: manual, obtenu: %v", res.Strategy)
=======
func TestConflictResolver_StrategyRegistrationAndPriority(t *testing.T) {
	cr := NewConflictResolver()

	// Ajoute une stratégie custom avec priorité supérieure
	type HighPriorityStrategy struct{}
	func (hps *HighPriorityStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) {
		return &Resolution{ResolvedDoc: conflict.LocalDoc, Strategy: "high_priority", Confidence: 1.0}, nil
	}
	func (hps *HighPriorityStrategy) CanHandle(conflictType ConflictType) bool { return conflictType == ContentConflict }
	func (hps *HighPriorityStrategy) Priority() int { return 99 }

	cr.AddStrategy(ContentConflict, &HighPriorityStrategy{})

	local := &Document{ID: "1", Path: "/a", Content: []byte("A"), Metadata: nil, Version: 1}
	remote := &Document{ID: "1", Path: "/a", Content: []byte("B"), Metadata: nil, Version: 1}
	conflict := &DocumentConflict{
		ID:           "c1",
		Type:         ContentConflict,
		LocalDoc:     local,
		RemoteDoc:    remote,
		ConflictedAt: time.Now(),
		Context:      nil,
	}

	res, err := cr.ResolveConflict(conflict)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if res.Strategy != "high_priority" {
		t.Errorf("expected high_priority strategy, got %s", res.Strategy)
	}
}

func TestConflictResolver_ClassificationAndMetadata(t *testing.T) {
	cr := NewConflictResolver()
	local := &Document{ID: "1", Path: "/a", Content: []byte("A"), Metadata: nil, Version: 1}
	remote := &Document{ID: "1", Path: "/a", Content: []byte("B"), Metadata: nil, Version: 2}
	conflict := &DocumentConflict{
		ID:           "c2",
		Type:         ContentConflict,
		LocalDoc:     local,
		RemoteDoc:    remote,
		ConflictedAt: time.Now(),
		Context:      nil,
	}

	conflictType := cr.classifyConflict(conflict)
	if conflictType != ContentConflict {
		t.Errorf("expected ContentConflict, got %v", conflictType)
	}
	severity := cr.assessConflictSeverity(conflict)
	if severity != 1 {
		t.Errorf("expected severity 1, got %v", severity)
	}
	meta := cr.extractConflictMetadata(conflict)
	if meta["local_id"] != "1" || meta["remote_id"] != "1" {
		t.Errorf("metadata extraction failed: %v", meta)
	}
}

func TestConflictResolver_OptimalStrategySelection(t *testing.T) {
	cr := NewConflictResolver()
	// Ajoute une stratégie custom avec priorité supérieure
	type HighPriorityStrategy struct{}
	func (hps *HighPriorityStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) { return nil, nil }
	func (hps *HighPriorityStrategy) CanHandle(conflictType ConflictType) bool { return true }
	func (hps *HighPriorityStrategy) Priority() int { return 99 }
	cr.AddStrategy(ContentConflict, &HighPriorityStrategy{})

	selected := cr.selectOptimalStrategy(ContentConflict)
	if selected.Priority() != 99 {
		t.Errorf("expected priority 99, got %d", selected.Priority())
	}

	// Test fallback
	fallback := cr.selectOptimalStrategy("unknown")
	if fallback == nil {
		t.Error("expected fallback strategy, got nil")
	}
}

func TestConflictResolver_ExecuteAndValidateResolution(t *testing.T) {
	cr := NewConflictResolver()
	// Stratégie qui échoue
	type FailingStrategy struct{}
	func (fs *FailingStrategy) Resolve(conflict *DocumentConflict) (*Resolution, error) { return nil, fmt.Errorf("fail") }
	func (fs *FailingStrategy) CanHandle(conflictType ConflictType) bool { return true }
	func (fs *FailingStrategy) Priority() int { return 100 }
	cr.AddStrategy(ContentConflict, &FailingStrategy{})

	local := &Document{ID: "1", Path: "/a", Content: []byte("A"), Metadata: nil, Version: 1}
	remote := &Document{ID: "1", Path: "/a", Content: []byte("B"), Metadata: nil, Version: 1}
	conflict := &DocumentConflict{
		ID:           "c3",
		Type:         ContentConflict,
		LocalDoc:     local,
		RemoteDoc:    remote,
		ConflictedAt: time.Now(),
		Context:      nil,
	}

	selected := cr.selectOptimalStrategy(ContentConflict)
	res, err := cr.executeAndValidateResolution(selected, conflict)
	if err != nil {
		t.Errorf("expected fallback to succeed, got error: %v", err)
	}
	if res == nil || res.Strategy != "manual" {
		t.Errorf("expected fallback manual strategy, got %+v", res)
	}
}

func TestLastModifiedWinsStrategy(t *testing.T) {
	lmw := &LastModifiedWins{}
	t0 := time.Now().Truncate(time.Microsecond)
	t1 := t0.Add(1 * time.Microsecond)
	local := &Document{ID: "1", Path: "/a", Content: []byte("A"), Metadata: map[string]interface{}{ "last_modified": t0 }, Version: 1}
	remote := &Document{ID: "1", Path: "/a", Content: []byte("B"), Metadata: map[string]interface{}{ "last_modified": t1 }, Version: 1}
	conflict := &DocumentConflict{
		ID:           "c4",
		Type:         ContentConflict,
		LocalDoc:     local,
		RemoteDoc:    remote,
		ConflictedAt: time.Now(),
		Context:      nil,
	}
	res, err := lmw.Resolve(conflict)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if res.ResolvedDoc != remote {
		t.Errorf("expected remote to win, got %+v", res.ResolvedDoc)
	}
	// Test égalité stricte
	conflict.RemoteDoc.Metadata["last_modified"] = t0
	res, err = lmw.Resolve(conflict)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if res.Metadata["winner"] != "equal" {
		t.Errorf("expected winner=equal, got %v", res.Metadata["winner"])
	}
}

func TestMergeMetadataPreservesImportantFields(t *testing.T) {
	metaA := map[string]interface{}{
		"tags": []string{"a", "b"},
		"authors": []string{"alice"},
		"history": []string{"v1"},
		"foo": "bar",
	}
	metaB := map[string]interface{}{
		"tags": []string{"c"},
		"authors": []string{"bob"},
		"history": []string{"v2"},
		"baz": 42,
	}
	merged := mergeMetadata(metaA, metaB)
	if merged["foo"] != "bar" || merged["baz"] != 42 {
		t.Errorf("basic merge failed: %+v", merged)
	}
	if tags, ok := merged["tags"].([]string); !ok || len(tags) == 0 {
		t.Errorf("tags not preserved: %+v", merged["tags"])
	}
	if authors, ok := merged["authors"].([]string); !ok || len(authors) == 0 {
		t.Errorf("authors not preserved: %+v", merged["authors"])
	}
	if history, ok := merged["history"].([]string); !ok || len(history) == 0 {
		t.Errorf("history not preserved: %+v", merged["history"])
	}
}

func TestCalculateQualityScoreAndOptimalVersion(t *testing.T) {
	docA := &Document{Content: []byte("# Title\n- item\n[link](url)\n![](img.png)\nThis is a test.")}
	docB := &Document{Content: []byte("plain text")}
	scoreA := calculateQualityScore(docA)
	scoreB := calculateQualityScore(docB)
	if scoreA <= scoreB {
		t.Errorf("expected docA to have higher score, got %v <= %v", scoreA, scoreB)
	}
	minScore := 1.0
	selected := selectOptimalVersionByQuality(docA, docB, minScore, func() *Document { return docB })
	if selected != docA {
		t.Errorf("expected docA to be selected, got %+v", selected)
	}
	// Test fallback si aucun ne passe le seuil
	selected = selectOptimalVersionByQuality(docB, docB, 100.0, func() *Document { return docA })
	if selected != docA {
		t.Errorf("expected fallback to docA, got %+v", selected)
	}
}

func TestAutoMerge(t *testing.T) {
	cr := NewConflictResolver()
	docA := &Document{ID: "1", Path: "/a", Content: []byte("A"), Metadata: map[string]interface{}{ "foo": 1 }, Version: 1}
	docB := &Document{ID: "1", Path: "/a", Content: []byte("B"), Metadata: map[string]interface{}{ "bar": 2 }, Version: 2}
	merged, err := cr.autoMerge(docA, docB)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if string(merged.Content) != "AB" && string(merged.Content) != "BA" {
		t.Errorf("unexpected merged content: %s", string(merged.Content))
	}
	if merged.Metadata["foo"] != 1 || merged.Metadata["bar"] != 2 {
		t.Errorf("metadata not merged correctly: %+v", merged.Metadata)
	}
	if merged.Version != 2 {
		t.Errorf("expected version 2, got %d", merged.Version)
>>>>>>> diff-edit-implementation-v67
	}
}
