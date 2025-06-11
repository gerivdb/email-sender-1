package main

import (
	"testing"
	"time"
)

func TestConflictDetectorCreation(t *testing.T) {
	// Configuration de test
	config := &ConflictConfig{
		TimestampTolerance: 5 * time.Minute,
		ContentThreshold:   0.95,
		EnableAutoResolve:  true,
		BackupConflicts:    true,
	}

	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, config)

	if detector == nil {
		t.Fatal("ConflictDetector creation failed")
	}

	if detector.config.TimestampTolerance != 5*time.Minute {
		t.Errorf("Expected TimestampTolerance 5m, got %v", detector.config.TimestampTolerance)
	}

	if detector.config.ContentThreshold != 0.95 {
		t.Errorf("Expected ContentThreshold 0.95, got %f", detector.config.ContentThreshold)
	}

	t.Logf("✅ ConflictDetector creation test passed")
}

func TestDetectConflicts(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)

	// Créer un plan de test
	testPlan := &DynamicPlan{
		ID: "test_conflict_plan",
		Metadata: PlanMetadata{
			Title:       "Plan de Test Conflits",
			Version:     "1.0",
			Date:        "2025-06-11",
			Progression: 50.0,
		},
		Tasks: []Task{
			{
				ID:     "task_1",
				Title:  "Tâche de test 1",
				Status: "completed",
				Phase:  "Phase 1",
				Level:  1,
			},
			{
				ID:     "task_2",
				Title:  "Tâche de test 2",
				Status: "in_progress",
				Phase:  "Phase 1",
				Level:  2,
			},
		},
		UpdatedAt: time.Now(),
	}

	// Stocker le plan
	err := sqlStorage.StorePlan(testPlan)
	if err != nil {
		t.Fatalf("Failed to store test plan: %v", err)
	}

	// Détecter les conflits
	result, err := detector.DetectConflicts("test_conflict_plan")
	if err != nil {
		t.Fatalf("DetectConflicts failed: %v", err)
	}

	if result == nil {
		t.Fatal("DetectionResult should not be nil")
	}

	if result.PlanID != "test_conflict_plan" {
		t.Errorf("Expected PlanID 'test_conflict_plan', got '%s'", result.PlanID)
	}

	// Vérifier qu'au moins un conflit est détecté (car nous simulons des différences)
	if len(result.Conflicts) == 0 {
		t.Error("Expected at least one conflict to be detected")
	}

	// Vérifier les types de conflits
	conflictTypes := make(map[ConflictType]int)
	for _, conflict := range result.Conflicts {
		conflictTypes[conflict.Type]++
	}

	t.Logf("✅ DetectConflicts test passed - Found %d conflicts: %v", len(result.Conflicts), conflictTypes)
}

func TestTimestampConflictDetection(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, &ConflictConfig{
		TimestampTolerance: 1 * time.Minute, // Tolérance très faible pour forcer un conflit
	})

	// Créer deux plans avec des timestamps différents
	basePlan := &DynamicPlan{
		ID: "timestamp_test_plan",
		Metadata: PlanMetadata{
			Title:       "Plan Timestamp Test",
			Version:     "1.0",
			Progression: 50.0,
		},
		Tasks:     []Task{},
		UpdatedAt: time.Now(),
	}

	markdownPlan := &DynamicPlan{
		ID:        basePlan.ID + "_markdown",
		Metadata:  basePlan.Metadata,
		Tasks:     basePlan.Tasks,
		UpdatedAt: time.Now().Add(-10 * time.Minute), // 10 minutes de différence
	}

	conflicts := detector.detectTimestampConflicts("timestamp_test_plan", markdownPlan, basePlan)

	if len(conflicts) == 0 {
		t.Error("Expected timestamp conflict to be detected")
	}

	conflict := conflicts[0]
	if conflict.Type != ConflictTypeTimestamp {
		t.Errorf("Expected ConflictTypeTimestamp, got %s", conflict.Type)
	}

	if conflict.Severity != SeverityMedium {
		t.Errorf("Expected SeverityMedium, got %s", conflict.Severity)
	}

	t.Logf("✅ Timestamp conflict detection test passed - Conflict: %s", conflict.Description)
}

func TestContentConflictDetection(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)

	// Créer deux plans avec du contenu différent
	basePlan := &DynamicPlan{
		ID: "content_test_plan",
		Metadata: PlanMetadata{
			Title:       "Plan Original",
			Version:     "1.0",
			Progression: 50.0,
		},
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche 1", Status: "completed"},
			{ID: "task_2", Title: "Tâche 2", Status: "in_progress"},
		},
		UpdatedAt: time.Now(),
	}

	markdownPlan := &DynamicPlan{
		ID: basePlan.ID + "_markdown",
		Metadata: PlanMetadata{
			Title:       "Plan Modifié", // Titre différent
			Version:     "1.0",
			Progression: 75.0, // Progression différente
		},
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche 1", Status: "completed"},
			{ID: "task_2", Title: "Tâche 2", Status: "blocked"}, // Statut différent
		},
		UpdatedAt: time.Now(),
	}

	conflicts := detector.detectContentConflicts("content_test_plan", markdownPlan, basePlan)

	if len(conflicts) == 0 {
		t.Error("Expected content conflict to be detected")
	}

	conflict := conflicts[0]
	if conflict.Type != ConflictTypeContent {
		t.Errorf("Expected ConflictTypeContent, got %s", conflict.Type)
	}

	if conflict.MarkdownHash == conflict.DynamicHash {
		t.Error("Hashes should be different for content conflict")
	}

	t.Logf("✅ Content conflict detection test passed - Similarity: %v", conflict.Details["content_similarity"])
}

func TestMetadataConflictDetection(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)

	basePlan := &DynamicPlan{
		ID: "metadata_test_plan",
		Metadata: PlanMetadata{
			Title:       "Plan Test",
			Version:     "1.0",
			Progression: 50.0,
		},
		Tasks:     []Task{},
		UpdatedAt: time.Now(),
	}

	markdownPlan := &DynamicPlan{
		ID: basePlan.ID + "_markdown",
		Metadata: PlanMetadata{
			Title:       "Plan Test",
			Version:     "2.0",    // Version différente
			Progression: 75.0,    // Progression différente (>5% de différence)
		},
		Tasks:     []Task{},
		UpdatedAt: time.Now(),
	}

	conflicts := detector.detectMetadataConflicts("metadata_test_plan", markdownPlan, basePlan)

	// Devrait détecter 2 conflits: version et progression
	if len(conflicts) < 2 {
		t.Errorf("Expected at least 2 metadata conflicts, got %d", len(conflicts))
	}

	// Vérifier les conflits de version et progression
	hasVersionConflict := false
	hasProgressionConflict := false

	for _, conflict := range conflicts {
		if conflict.Type != ConflictTypeMetadata {
			t.Errorf("Expected ConflictTypeMetadata, got %s", conflict.Type)
		}

		if conflict.Details["markdown_version"] != nil {
			hasVersionConflict = true
		}
		if conflict.Details["difference"] != nil {
			hasProgressionConflict = true
		}
	}

	if !hasVersionConflict {
		t.Error("Expected version conflict to be detected")
	}

	if !hasProgressionConflict {
		t.Error("Expected progression conflict to be detected")
	}

	t.Logf("✅ Metadata conflict detection test passed - Found %d conflicts", len(conflicts))
}

func TestTaskConflictDetection(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)

	basePlan := &DynamicPlan{
		ID: "task_test_plan",
		Metadata: PlanMetadata{
			Title:       "Plan Task Test",
			Version:     "1.0",
			Progression: 50.0,
		},
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche 1", Status: "completed"},
			{ID: "task_2", Title: "Tâche 2", Status: "in_progress"},
			{ID: "task_3", Title: "Tâche 3", Status: "pending"},
		},
		UpdatedAt: time.Now(),
	}

	markdownPlan := &DynamicPlan{
		ID:       basePlan.ID + "_markdown",
		Metadata: basePlan.Metadata,
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche 1", Status: "completed"},    // Identique
			{ID: "task_2", Title: "Tâche 2", Status: "blocked"},     // Différent
			{ID: "task_3", Title: "Tâche 3", Status: "completed"},   // Différent
		},
		UpdatedAt: time.Now(),
	}

	conflicts := detector.detectTaskConflicts("task_test_plan", markdownPlan, basePlan)

	// Devrait détecter 2 conflits de tâches
	if len(conflicts) != 2 {
		t.Errorf("Expected 2 task conflicts, got %d", len(conflicts))
	}

	for _, conflict := range conflicts {
		if conflict.Type != ConflictTypeTasks {
			t.Errorf("Expected ConflictTypeTasks, got %s", conflict.Type)
		}

		taskID := conflict.Details["task_id"].(string)
		if taskID != "task_2" && taskID != "task_3" {
			t.Errorf("Unexpected task conflict for task: %s", taskID)
		}
	}

	t.Logf("✅ Task conflict detection test passed - Found conflicts for tasks: task_2, task_3")
}

func TestCalculatePlanHash(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)

	plan1 := &DynamicPlan{
		ID: "hash_test_plan_1",
		Metadata: PlanMetadata{
			Title:       "Plan Test",
			Version:     "1.0",
			Progression: 50.0,
		},
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche 1", Status: "completed"},
		},
	}

	plan2 := &DynamicPlan{
		ID: "hash_test_plan_2",
		Metadata: PlanMetadata{
			Title:       "Plan Test",
			Version:     "1.0",
			Progression: 50.0,
		},
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche 1", Status: "completed"},
		},
	}

	plan3 := &DynamicPlan{
		ID: "hash_test_plan_3",
		Metadata: PlanMetadata{
			Title:       "Plan Test Modifié", // Différent
			Version:     "1.0",
			Progression: 50.0,
		},
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche 1", Status: "completed"},
		},
	}

	hash1 := detector.calculatePlanHash(plan1)
	hash2 := detector.calculatePlanHash(plan2)
	hash3 := detector.calculatePlanHash(plan3)

	// Les plans identiques doivent avoir le même hash
	if hash1 != hash2 {
		t.Error("Identical plans should have the same hash")
	}

	// Les plans différents doivent avoir des hashes différents
	if hash1 == hash3 {
		t.Error("Different plans should have different hashes")
	}

	if len(hash1) != 16 {
		t.Errorf("Expected hash length 16, got %d", len(hash1))
	}

	t.Logf("✅ Plan hash calculation test passed - Hash1: %s, Hash3: %s", hash1, hash3)
}

func TestCalculateContentSimilarity(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)

	// Plans identiques
	plan1 := &DynamicPlan{
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche 1"},
			{ID: "task_2", Title: "Tâche 2"},
			{ID: "task_3", Title: "Tâche 3"},
		},
	}

	plan2 := &DynamicPlan{
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche 1"},
			{ID: "task_2", Title: "Tâche 2"},
			{ID: "task_3", Title: "Tâche 3"},
		},
	}

	// Plans partiellement similaires
	plan3 := &DynamicPlan{
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche 1"},
			{ID: "task_2", Title: "Tâche 2"},
			{ID: "task_4", Title: "Tâche 4"}, // Différent
		},
	}

	// Plans complètement différents
	plan4 := &DynamicPlan{
		Tasks: []Task{
			{ID: "task_x", Title: "Tâche X"},
			{ID: "task_y", Title: "Tâche Y"},
		},
	}

	similarity12 := detector.calculateContentSimilarity(plan1, plan2)
	similarity13 := detector.calculateContentSimilarity(plan1, plan3)
	similarity14 := detector.calculateContentSimilarity(plan1, plan4)

	// Plans identiques: similarité = 1.0
	if similarity12 != 1.0 {
		t.Errorf("Expected similarity 1.0 for identical plans, got %f", similarity12)
	}

	// Plans partiellement similaires: 0 < similarité < 1
	if similarity13 <= 0 || similarity13 >= 1.0 {
		t.Errorf("Expected similarity between 0 and 1 for partially similar plans, got %f", similarity13)
	}

	// Plans différents: similarité faible
	if similarity14 >= 0.5 {
		t.Errorf("Expected low similarity for different plans, got %f", similarity14)
	}

	t.Logf("✅ Content similarity test passed - Similarities: %.2f, %.2f, %.2f", similarity12, similarity13, similarity14)
}

func TestConflictStats(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)

	// Vérifier les stats initiales
	stats := detector.GetStats()
	if stats.ConflictsDetected != 0 {
		t.Errorf("Expected initial ConflictsDetected 0, got %d", stats.ConflictsDetected)
	}

	// Créer et stocker un plan de test
	testPlan := &DynamicPlan{
		ID: "stats_test_plan",
		Metadata: PlanMetadata{
			Title:       "Plan Stats Test",
			Version:     "1.0",
			Progression: 50.0,
		},
		Tasks:     []Task{{ID: "task_1", Title: "Test Task", Status: "pending"}},
		UpdatedAt: time.Now(),
	}

	err := sqlStorage.StorePlan(testPlan)
	if err != nil {
		t.Fatalf("Failed to store test plan: %v", err)
	}

	// Exécuter la détection de conflits
	_, err = detector.DetectConflicts("stats_test_plan")
	if err != nil {
		t.Fatalf("DetectConflicts failed: %v", err)
	}

	// Vérifier les stats mises à jour
	statsAfter := detector.GetStats()
	if statsAfter.ConflictsDetected <= stats.ConflictsDetected {
		t.Error("ConflictsDetected should have increased")
	}

	if statsAfter.TotalDetectionTime <= 0 {
		t.Error("TotalDetectionTime should be positive")
	}

	// Test reset des stats
	detector.ResetStats()
	resetStats := detector.GetStats()
	if resetStats.ConflictsDetected != 0 {
		t.Error("Stats should be reset to 0")
	}

	t.Logf("✅ Conflict stats test passed - Detected: %d, Time: %v", statsAfter.ConflictsDetected, statsAfter.TotalDetectionTime)
}

// BenchmarkDetectConflicts teste les performances de détection de conflits
func BenchmarkDetectConflicts(b *testing.B) {
	sqlStorage := createTestSQLStorage(nil)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)

	// Créer un plan de test avec plusieurs tâches
	testPlan := &DynamicPlan{
		ID: "benchmark_plan",
		Metadata: PlanMetadata{
			Title:       "Benchmark Plan",
			Version:     "1.0",
			Progression: 50.0,
		},
		Tasks:     make([]Task, 100), // 100 tâches pour le benchmark
		UpdatedAt: time.Now(),
	}

	// Remplir les tâches
	for i := 0; i < 100; i++ {
		testPlan.Tasks[i] = Task{
			ID:     fmt.Sprintf("task_%d", i),
			Title:  fmt.Sprintf("Tâche %d", i),
			Status: "pending",
			Phase:  fmt.Sprintf("Phase %d", i%5),
			Level:  1,
		}
	}

	err := sqlStorage.StorePlan(testPlan)
	if err != nil {
		b.Fatalf("Failed to store benchmark plan: %v", err)
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := detector.DetectConflicts("benchmark_plan")
		if err != nil {
			b.Fatalf("DetectConflicts failed: %v", err)
		}
	}
}
