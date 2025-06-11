package main

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestConflictResolverCreation(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	
	config := &ResolverConfig{
		AutoResolveEnabled:  true,
		BackupBeforeResolve: true,
		BackupDirectory:     "./test_backups",
		DefaultStrategy:     StrategyAutoMerge,
	}

	resolver := NewConflictResolver(sqlStorage, detector, config)

	if resolver == nil {
		t.Fatal("ConflictResolver creation failed")
	}

	if !resolver.config.AutoResolveEnabled {
		t.Error("AutoResolveEnabled should be true")
	}

	if resolver.config.DefaultStrategy != StrategyAutoMerge {
		t.Errorf("Expected DefaultStrategy AutoMerge, got %s", resolver.config.DefaultStrategy)
	}

	t.Logf("✅ ConflictResolver creation test passed")
}

func TestResolveConflicts(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	resolver := NewConflictResolver(sqlStorage, detector, &ResolverConfig{
		BackupBeforeResolve: false, // Désactiver backup pour simplifier le test
		DefaultStrategy:     StrategyAutoMerge,
	})

	// Créer des conflits de test
	conflicts := []Conflict{
		{
			ID:          "test_conflict_1",
			PlanID:      "test_plan",
			Type:        ConflictTypeTasks,
			Description: "Task status conflict",
			Severity:    SeverityMedium,
			Details: map[string]interface{}{
				"task_id":         "task_1",
				"task_title":      "Test Task",
				"markdown_status": "completed",
				"dynamic_status":  "in_progress",
			},
			DetectedAt: time.Now(),
		},
		{
			ID:          "test_conflict_2",
			PlanID:      "test_plan",
			Type:        ConflictTypeMetadata,
			Description: "Version mismatch",
			Severity:    SeverityMedium,
			Details: map[string]interface{}{
				"markdown_version": "2.0",
				"dynamic_version":  "1.0",
			},
			DetectedAt: time.Now(),
		},
	}

	request := &ResolutionRequest{
		PlanID:    "test_plan",
		Conflicts: conflicts,
		Strategy:  StrategyAutoMerge,
		User:      "test_user",
	}

	result, err := resolver.ResolveConflicts(request)
	if err != nil {
		t.Fatalf("ResolveConflicts failed: %v", err)
	}

	if result == nil {
		t.Fatal("ResolutionResult should not be nil")
	}

	if result.PlanID != "test_plan" {
		t.Errorf("Expected PlanID 'test_plan', got '%s'", result.PlanID)
	}

	// Vérifier que les conflits ont été traités
	totalProcessed := len(result.ResolvedConflicts) + len(result.FailedConflicts)
	if totalProcessed != len(conflicts) {
		t.Errorf("Expected %d conflicts processed, got %d", len(conflicts), totalProcessed)
	}

	// Vérifier qu'au moins un conflit a été résolu
	if len(result.ResolvedConflicts) == 0 {
		t.Error("Expected at least one conflict to be resolved")
	}

	t.Logf("✅ ResolveConflicts test passed - %d resolved, %d failed", 
		len(result.ResolvedConflicts), len(result.FailedConflicts))
}

func TestMergeTaskConflict(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	resolver := NewConflictResolver(sqlStorage, detector, nil)

	conflict := Conflict{
		ID:          "task_conflict_test",
		PlanID:      "test_plan",
		Type:        ConflictTypeTasks,
		Description: "Task status conflict",
		Severity:    SeverityMedium,
		Details: map[string]interface{}{
			"task_id":         "task_1",
			"task_title":      "Test Task",
			"markdown_status": "completed",
			"dynamic_status":  "in_progress",
		},
	}

	resolution := ConflictResolution{
		Strategy:  StrategyAutoMerge,
		AppliedBy: "test_user",
		AppliedAt: time.Now(),
	}

	resolved := resolver.mergeTaskConflict(conflict, resolution)

	if !resolved.Success {
		t.Errorf("Task conflict merge should succeed: %s", resolved.Message)
	}

	if resolved.Resolution.Result != "completed" {
		t.Errorf("Expected merged status 'completed', got %v", resolved.Resolution.Result)
	}

	if !resolved.Resolution.Applied {
		t.Error("Resolution should be marked as applied")
	}

	t.Logf("✅ Task conflict merge test passed - Result: %s", resolved.Resolution.Result)
}

func TestMergeMetadataConflict(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	resolver := NewConflictResolver(sqlStorage, detector, nil)

	// Test version conflict
	versionConflict := Conflict{
		ID:          "version_conflict_test",
		PlanID:      "test_plan",
		Type:        ConflictTypeMetadata,
		Description: "Version mismatch: markdown=2.0, dynamic=1.0",
		Severity:    SeverityMedium,
		Details: map[string]interface{}{
			"markdown_version": "2.0",
			"dynamic_version":  "1.0",
		},
	}

	resolution := ConflictResolution{
		Strategy:  StrategyAutoMerge,
		AppliedBy: "test_user",
		AppliedAt: time.Now(),
	}

	resolved := resolver.mergeMetadataConflict(versionConflict, resolution)

	if !resolved.Success {
		t.Errorf("Version conflict merge should succeed: %s", resolved.Message)
	}

	if resolved.Resolution.Result != "2.0" {
		t.Errorf("Expected merged version '2.0', got %v", resolved.Resolution.Result)
	}

	// Test progression conflict
	progressionConflict := Conflict{
		ID:          "progression_conflict_test",
		PlanID:      "test_plan",
		Type:        ConflictTypeMetadata,
		Description: "Progression mismatch: 15.0% difference",
		Severity:    SeverityMedium,
		Details: map[string]interface{}{
			"markdown_progression": 75.0,
			"dynamic_progression":  60.0,
			"difference":           15.0,
		},
	}

	resolvedProgression := resolver.mergeMetadataConflict(progressionConflict, resolution)

	if !resolvedProgression.Success {
		t.Errorf("Progression conflict merge should succeed: %s", resolvedProgression.Message)
	}

	if resolvedProgression.Resolution.Result != 75.0 {
		t.Errorf("Expected merged progression 75.0, got %v", resolvedProgression.Resolution.Result)
	}

	t.Logf("✅ Metadata conflict merge test passed - Version: %s, Progression: %v", 
		resolved.Resolution.Result, resolvedProgression.Resolution.Result)
}

func TestMergeContentConflict(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	resolver := NewConflictResolver(sqlStorage, detector, nil)

	resolution := ConflictResolution{
		Strategy:  StrategyAutoMerge,
		AppliedBy: "test_user",
		AppliedAt: time.Now(),
	}

	// Test avec haute similarité (auto-merge possible)
	highSimilarityConflict := Conflict{
		ID:          "high_similarity_test",
		PlanID:      "test_plan",
		Type:        ConflictTypeContent,
		Description: "Content differs (similarity: 85.00%)",
		Severity:    SeverityLow,
		Details: map[string]interface{}{
			"content_similarity": 0.85,
			"markdown_tasks":     10,
			"dynamic_tasks":      9,
		},
	}

	resolved := resolver.mergeContentConflict(highSimilarityConflict, resolution)

	if !resolved.Success {
		t.Errorf("High similarity content merge should succeed: %s", resolved.Message)
	}

	// Test avec faible similarité (nécessite intervention manuelle)
	lowSimilarityConflict := Conflict{
		ID:          "low_similarity_test",
		PlanID:      "test_plan",
		Type:        ConflictTypeContent,
		Description: "Content differs (similarity: 45.00%)",
		Severity:    SeverityHigh,
		Details: map[string]interface{}{
			"content_similarity": 0.45,
			"markdown_tasks":     10,
			"dynamic_tasks":      5,
		},
	}

	resolvedLow := resolver.mergeContentConflict(lowSimilarityConflict, resolution)

	if resolvedLow.Success {
		t.Error("Low similarity content merge should not succeed automatically")
	}

	t.Logf("✅ Content conflict merge test passed - High similarity: %t, Low similarity: %t", 
		resolved.Success, resolvedLow.Success)
}

func TestDetermineStrategy(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	
	config := &ResolverConfig{
		DefaultStrategy: StrategyManual,
		StrategyPriority: map[ConflictType][]ResolutionStrategy{
			ConflictTypeTasks: {StrategyAutoMerge, StrategyUseDynamic},
			ConflictTypeMetadata: {StrategyUseDynamic, StrategyUseMarkdown},
		},
	}
	
	resolver := NewConflictResolver(sqlStorage, detector, config)

	// Test pour conflit de tâche
	taskConflict := Conflict{
		Type:     ConflictTypeTasks,
		Severity: SeverityMedium,
	}

	strategy := resolver.determineStrategy(taskConflict)
	if strategy != StrategyAutoMerge {
		t.Errorf("Expected StrategyAutoMerge for task conflict, got %s", strategy)
	}

	// Test pour conflit de métadonnées
	metadataConflict := Conflict{
		Type:     ConflictTypeMetadata,
		Severity: SeverityMedium,
	}

	strategy = resolver.determineStrategy(metadataConflict)
	if strategy != StrategyUseDynamic {
		t.Errorf("Expected StrategyUseDynamic for metadata conflict, got %s", strategy)
	}

	// Test pour type non configuré (devrait utiliser default)
	unknownConflict := Conflict{
		Type:     ConflictTypeStructure,
		Severity: SeverityHigh,
	}

	strategy = resolver.determineStrategy(unknownConflict)
	if strategy != StrategyManual {
		t.Errorf("Expected default strategy StrategyManual, got %s", strategy)
	}

	t.Logf("✅ Strategy determination test passed")
}

func TestDeterminePriorityStatus(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	resolver := NewConflictResolver(sqlStorage, detector, nil)

	tests := []struct {
		status1  string
		status2  string
		expected string
	}{
		{"completed", "in_progress", "completed"},
		{"in_progress", "pending", "in_progress"},
		{"blocked", "not_started", "blocked"},
		{"pending", "completed", "completed"},
		{"not_started", "blocked", "blocked"},
	}

	for _, test := range tests {
		result := resolver.determinePriorityStatus(test.status1, test.status2)
		if result != test.expected {
			t.Errorf("determinePriorityStatus(%s, %s) = %s, expected %s", 
				test.status1, test.status2, result, test.expected)
		}
	}

	t.Logf("✅ Priority status determination test passed")
}

func TestCompareVersions(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	resolver := NewConflictResolver(sqlStorage, detector, nil)

	tests := []struct {
		version1 string
		version2 string
		expected string
	}{
		{"2.0", "1.0", "2.0"},
		{"1.5", "2.0", "2.0"},
		{"3.0", "3.0", "3.0"},
		{"1.0", "1.1", "1.1"},
	}

	for _, test := range tests {
		result := resolver.compareVersions(test.version1, test.version2)
		if result != test.expected {
			t.Errorf("compareVersions(%s, %s) = %s, expected %s", 
				test.version1, test.version2, result, test.expected)
		}
	}

	t.Logf("✅ Version comparison test passed")
}

func TestCreateBackup(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	
	// Utiliser un répertoire temporaire pour les tests
	tempDir := filepath.Join(os.TempDir(), "conflict_resolver_test_backups")
	defer os.RemoveAll(tempDir)

	config := &ResolverConfig{
		BackupDirectory: tempDir,
	}
	
	resolver := NewConflictResolver(sqlStorage, detector, config)

	// Créer un plan de test
	testPlan := &DynamicPlan{
		ID: "backup_test_plan",
		Metadata: PlanMetadata{
			Title:       "Plan de Test Backup",
			Version:     "1.0",
			Progression: 50.0,
		},
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche de test", Status: "pending"},
		},
		UpdatedAt: time.Now(),
	}

	err := sqlStorage.StorePlan(testPlan)
	if err != nil {
		t.Fatalf("Failed to store test plan: %v", err)
	}

	// Créer la sauvegarde
	backupPath, err := resolver.createBackup("backup_test_plan")
	if err != nil {
		t.Fatalf("createBackup failed: %v", err)
	}

	if backupPath == "" {
		t.Error("Backup path should not be empty")
	}

	// Vérifier que le répertoire de sauvegarde existe
	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		t.Errorf("Backup directory should exist: %s", backupPath)
	}

	// Vérifier que le fichier de sauvegarde existe
	backupFile := filepath.Join(backupPath, "plan_backup.json")
	if _, err := os.Stat(backupFile); os.IsNotExist(err) {
		t.Errorf("Backup file should exist: %s", backupFile)
	}

	t.Logf("✅ Backup creation test passed - Path: %s", backupPath)
}

func TestAutoResolveConflicts(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	
	config := &ResolverConfig{
		AutoResolveEnabled: true,
		AutoResolveRules: []AutoResolveRule{
			{
				ConflictType: ConflictTypeTasks,
				Severity:     SeverityMedium,
				Strategy:     StrategyAutoMerge,
			},
		},
		BackupBeforeResolve: false,
	}
	
	resolver := NewConflictResolver(sqlStorage, detector, config)

	// Créer un plan de test
	testPlan := &DynamicPlan{
		ID: "auto_resolve_test_plan",
		Metadata: PlanMetadata{
			Title:       "Plan Auto Resolve Test",
			Version:     "1.0",
			Progression: 50.0,
		},
		Tasks: []Task{
			{ID: "task_1", Title: "Tâche auto-résolvable", Status: "pending"},
		},
		UpdatedAt: time.Now(),
	}

	err := sqlStorage.StorePlan(testPlan)
	if err != nil {
		t.Fatalf("Failed to store test plan: %v", err)
	}

	// Tester la résolution automatique
	result, err := resolver.AutoResolveConflicts("auto_resolve_test_plan")
	if err != nil {
		t.Fatalf("AutoResolveConflicts failed: %v", err)
	}

	if result == nil {
		t.Fatal("AutoResolve result should not be nil")
	}

	if result.PlanID != "auto_resolve_test_plan" {
		t.Errorf("Expected PlanID 'auto_resolve_test_plan', got '%s'", result.PlanID)
	}

	t.Logf("✅ Auto resolve test passed - Summary: %s", result.Summary)
}

func TestResolverStats(t *testing.T) {
	sqlStorage := createTestSQLStorage(t)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	resolver := NewConflictResolver(sqlStorage, detector, &ResolverConfig{
		BackupBeforeResolve: false,
	})

	// Vérifier les stats initiales
	stats := resolver.GetStats()
	if stats.TotalResolutions != 0 {
		t.Errorf("Expected initial TotalResolutions 0, got %d", stats.TotalResolutions)
	}

	// Créer des conflits de test et les résoudre
	conflicts := []Conflict{
		{
			ID:          "stats_test_conflict",
			PlanID:      "test_plan",
			Type:        ConflictTypeTasks,
			Description: "Test conflict for stats",
			Severity:    SeverityMedium,
			Details: map[string]interface{}{
				"task_id":         "task_1",
				"markdown_status": "completed",
				"dynamic_status":  "pending",
			},
		},
	}

	request := &ResolutionRequest{
		PlanID:    "test_plan",
		Conflicts: conflicts,
		Strategy:  StrategyAutoMerge,
		User:      "test_user",
	}

	_, err := resolver.ResolveConflicts(request)
	if err != nil {
		t.Fatalf("ResolveConflicts failed: %v", err)
	}

	// Vérifier les stats mises à jour
	statsAfter := resolver.GetStats()
	if statsAfter.TotalResolutions <= stats.TotalResolutions {
		t.Error("TotalResolutions should have increased")
	}

	if statsAfter.TotalResolutionTime <= 0 {
		t.Error("TotalResolutionTime should be positive")
	}

	// Test reset des stats
	resolver.ResetStats()
	resetStats := resolver.GetStats()
	if resetStats.TotalResolutions != 0 {
		t.Error("Stats should be reset to 0")
	}

	t.Logf("✅ Resolver stats test passed - Resolutions: %d, Time: %v", 
		statsAfter.TotalResolutions, statsAfter.TotalResolutionTime)
}

// BenchmarkResolveConflicts teste les performances de résolution de conflits
func BenchmarkResolveConflicts(b *testing.B) {
	sqlStorage := createTestSQLStorage(nil)
	defer sqlStorage.Close()

	detector := NewConflictDetector(sqlStorage, nil)
	resolver := NewConflictResolver(sqlStorage, detector, &ResolverConfig{
		BackupBeforeResolve: false, // Désactiver backup pour améliorer les performances
	})

	// Créer des conflits de test
	conflicts := make([]Conflict, 10)
	for i := 0; i < 10; i++ {
		conflicts[i] = Conflict{
			ID:          fmt.Sprintf("benchmark_conflict_%d", i),
			PlanID:      "benchmark_plan",
			Type:        ConflictTypeTasks,
			Description: fmt.Sprintf("Benchmark conflict %d", i),
			Severity:    SeverityMedium,
			Details: map[string]interface{}{
				"task_id":         fmt.Sprintf("task_%d", i),
				"markdown_status": "completed",
				"dynamic_status":  "pending",
			},
		}
	}

	request := &ResolutionRequest{
		PlanID:    "benchmark_plan",
		Conflicts: conflicts,
		Strategy:  StrategyAutoMerge,
		User:      "benchmark_user",
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		resolver.ResetStats() // Reset pour chaque iteration
		_, err := resolver.ResolveConflicts(request)
		if err != nil {
			b.Fatalf("ResolveConflicts failed: %v", err)
		}
	}
}
