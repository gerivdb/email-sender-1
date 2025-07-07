package sync_core

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// TestPlanSynchronizerCreation tests the creation of PlanSynchronizer
func TestPlanSynchronizerCreation(t *testing.T) {
	// Create test SQL storage
	config := DatabaseConfig{
		Driver:     "sqlite",
		Connection: "file:test_sync.db?mode=memory&cache=shared",
	}

	storage, err := NewSQLStorage(config)
	if err != nil {
		t.Fatalf("Failed to create SQL storage: %v", err)
	}
	defer storage.Close()
	// Create test QDrant client
	qdrantClient := NewQDrantClient("http://localhost:6333")
	// Create synchronizer
	syncConfig := &MarkdownSyncConfig{
		OutputDirectory:    "./test-output",
		PreserveFormatting: true,
		BackupOriginal:     true,
		OverwriteExisting:  false,
	}

	synchronizer := NewPlanSynchronizer(storage, qdrantClient, syncConfig)

	// Verify creation
	if synchronizer == nil {
		t.Fatal("Expected non-nil synchronizer")
	}

	if synchronizer.config.OutputDirectory != "./test-output" {
		t.Errorf("Expected output directory './test-output', got %s", synchronizer.config.OutputDirectory)
	}

	if !synchronizer.config.PreserveFormatting {
		t.Error("Expected PreserveFormatting to be true")
	}

	t.Logf("✅ PlanSynchronizer creation test passed")
}

// TestSyncToMarkdown tests the complete synchronization process
func TestSyncToMarkdown(t *testing.T) {
	// Setup test environment
	tempDir := t.TempDir()

	// Create test SQL storage
	config := DatabaseConfig{
		Driver:     "sqlite",
		Connection: "file:test_sync_full.db?mode=memory&cache=shared",
	}

	storage, err := NewSQLStorage(config)
	if err != nil {
		t.Fatalf("Failed to create SQL storage: %v", err)
	}
	defer storage.Close()

	// Create test plan
	testPlan := &DynamicPlan{
		ID: "test_sync_plan",
		Metadata: PlanMetadata{
			Title:       "Plan de Test Synchronisation",
			Version:     "v2.1",
			Description: "Plan de test pour la synchronisation inverse",
			Progression: 75.0,
		},
		Tasks: []Task{
			{
				ID:          "task_sync_1",
				Title:       "Tâche Phase 1 Complétée",
				Description: "Première tâche de test",
				Status:      "completed",
				Phase:       "Phase 1: Initialization",
				Level:       1,
				Priority:    "high",
				Completed:   true,
				CreatedAt:   time.Now().Add(-2 * time.Hour),
				UpdatedAt:   time.Now().Add(-1 * time.Hour),
			},
			{
				ID:          "task_sync_2",
				Title:       "Tâche Phase 1 En Cours",
				Description: "Deuxième tâche de test",
				Status:      "in_progress",
				Phase:       "Phase 1: Initialization",
				Level:       1,
				Priority:    "medium",
				Completed:   false,
				CreatedAt:   time.Now().Add(-1 * time.Hour),
				UpdatedAt:   time.Now().Add(-30 * time.Minute),
			},
			{
				ID:          "task_sync_3",
				Title:       "Sous-tâche Phase 2",
				Description: "Tâche de niveau 2",
				Status:      "pending",
				Phase:       "Phase 2: Implementation",
				Level:       2,
				Priority:    "low",
				Completed:   false,
				CreatedAt:   time.Now().Add(-30 * time.Minute),
				UpdatedAt:   time.Now(),
			},
		},
		CreatedAt: time.Now().Add(-3 * time.Hour),
		UpdatedAt: time.Now(),
	}

	// Store test plan
	err = storage.StorePlan(testPlan)
	if err != nil {
		t.Fatalf("Failed to store test plan: %v", err)
	}
	// Create synchronizer
	qdrantClient := NewQDrantClient("http://localhost:6333")
	syncConfig := &MarkdownSyncConfig{
		OutputDirectory:    tempDir,
		PreserveFormatting: true,
		BackupOriginal:     false,
		OverwriteExisting:  true,
	}

	synchronizer := NewPlanSynchronizer(storage, qdrantClient, syncConfig)

	// Test synchronization
	err = synchronizer.SyncToMarkdown("test_sync_plan")
	if err != nil {
		t.Fatalf("Failed to sync to markdown: %v", err)
	}

	// Verify output file was created
	expectedPath := filepath.Join(tempDir, "plan-de-test-synchronisation-v2.1.md")
	if !synchronizer.fileExists(expectedPath) {
		t.Fatalf("Expected output file not found: %s", expectedPath)
	}

	// Read and verify content
	content, err := os.ReadFile(expectedPath)
	if err != nil {
		t.Fatalf("Failed to read output file: %v", err)
	}

	contentStr := string(content)

	// Verify structure
	if !strings.Contains(contentStr, "# Plan de Test Synchronisation") {
		t.Error("Expected title not found in output")
	}

	if !strings.Contains(contentStr, "**Version v2.1") {
		t.Error("Expected version not found in output")
	}

	if !strings.Contains(contentStr, "Progression globale : 75%") {
		t.Error("Expected progression not found in output")
	}

	if !strings.Contains(contentStr, "## Phase 1: Initialization") {
		t.Error("Expected Phase 1 section not found")
	}

	if !strings.Contains(contentStr, "## Phase 2: Implementation") {
		t.Error("Expected Phase 2 section not found")
	}

	if !strings.Contains(contentStr, "- [x] Tâche Phase 1 Complétée") {
		t.Error("Expected completed task not found")
	}

	if !strings.Contains(contentStr, "- [ ] Tâche Phase 1 En Cours") {
		t.Error("Expected incomplete task not found")
	}

	if !strings.Contains(contentStr, "  - [ ] Sous-tâche Phase 2") {
		t.Error("Expected indented sub-task not found")
	}

	// Verify statistics
	stats := synchronizer.GetStats()
	if stats.FilesSynced != 1 {
		t.Errorf("Expected 1 file synced, got %d", stats.FilesSynced)
	}

	if stats.ErrorsEncounter != 0 {
		t.Errorf("Expected 0 errors, got %d", stats.ErrorsEncounter)
	}

	t.Logf("✅ SyncToMarkdown test passed - Generated file: %s (%d bytes)", expectedPath, len(content))
}

// TestMarkdownConversion tests the conversion logic
func TestMarkdownConversion(t *testing.T) {
	// Create test plan
	testPlan := &DynamicPlan{
		ID: "test_conversion_plan",
		Metadata: PlanMetadata{
			Title:       "Plan de Conversion Test",
			Version:     "v1.0",
			Description: "Test de conversion vers Markdown",
			Progression: 50.0,
		},
		Tasks: []Task{
			{
				ID:        "conv_task_1",
				Title:     "Tâche Niveau 1",
				Phase:     "Phase 1",
				Level:     1,
				Completed: true,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			},
			{
				ID:        "conv_task_2",
				Title:     "Sous-tâche Niveau 2",
				Phase:     "Phase 1",
				Level:     2,
				Completed: false,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			},
			{
				ID:        "conv_task_3",
				Title:     "Tâche Phase 2",
				Phase:     "Phase 2",
				Level:     1,
				Completed: false,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			},
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// Create synchronizer
	config := DatabaseConfig{Driver: "sqlite", Connection: "file:test.db?mode=memory"}
	storage, _ := NewSQLStorage(config)
	defer storage.Close()
	qdrantClient := NewQDrantClient("http://localhost:6333")
	synchronizer := NewPlanSynchronizer(storage, qdrantClient, nil)

	// Test conversion
	markdown := synchronizer.convertToMarkdown(testPlan)

	// Verify structure
	lines := strings.Split(markdown, "\n")

	// Check title
	if lines[0] != "# Plan de Conversion Test" {
		t.Errorf("Expected title line, got: %s", lines[0])
	}

	// Check version line
	found := false
	for _, line := range lines {
		if strings.Contains(line, "**Version v1.0") && strings.Contains(line, "Progression globale : 50%**") {
			found = true
			break
		}
	}
	if !found {
		t.Error("Version and progression line not found")
	}

	// Check phase sections
	if !strings.Contains(markdown, "## Phase 1") {
		t.Error("Phase 1 section not found")
	}

	if !strings.Contains(markdown, "## Phase 2") {
		t.Error("Phase 2 section not found")
	}

	// Check task formatting
	if !strings.Contains(markdown, "- [x] Tâche Niveau 1") {
		t.Error("Completed task not properly formatted")
	}

	if !strings.Contains(markdown, "  - [ ] Sous-tâche Niveau 2") {
		t.Error("Sub-task indentation not correct")
	}

	// Check footer
	if !strings.Contains(markdown, "*Synchronisé depuis le système dynamique") {
		t.Error("Sync footer not found")
	}

	if !strings.Contains(markdown, "*Plan ID: test_conversion_plan*") {
		t.Error("Plan ID footer not found")
	}

	t.Logf("✅ Markdown conversion test passed - Generated %d lines", len(lines))
}

// TestPhaseGrouping tests the phase grouping functionality
func TestPhaseGrouping(t *testing.T) {
	tasks := []Task{
		{ID: "t1", Title: "Task 1", Phase: "Phase 1", Level: 1, Completed: true, CreatedAt: time.Now()},
		{ID: "t2", Title: "Task 2", Phase: "Phase 1", Level: 2, Completed: false, CreatedAt: time.Now()},
		{ID: "t3", Title: "Task 3", Phase: "Phase 2", Level: 1, Completed: true, CreatedAt: time.Now()},
		{ID: "t4", Title: "Task 4", Phase: "Phase 3", Level: 1, Completed: false, CreatedAt: time.Now()},
		{ID: "t5", Title: "Task 5", Phase: "Phase 1", Level: 1, Completed: true, CreatedAt: time.Now()},
	}

	// Create synchronizer
	config := DatabaseConfig{Driver: "sqlite", Connection: "file:test.db?mode=memory"}
	storage, _ := NewSQLStorage(config)
	defer storage.Close()
	qdrantClient := NewQDrantClient("http://localhost:6333")
	synchronizer := NewPlanSynchronizer(storage, qdrantClient, nil)

	// Test grouping
	phaseGroups := synchronizer.groupTasksByPhase(tasks)

	// Verify number of phases
	if len(phaseGroups) != 3 {
		t.Errorf("Expected 3 phases, got %d", len(phaseGroups))
	}

	// Find Phase 1 and verify task count
	var phase1 *PhaseGroup
	for i := range phaseGroups {
		if phaseGroups[i].Name == "Phase 1" {
			phase1 = &phaseGroups[i]
			break
		}
	}

	if phase1 == nil {
		t.Fatal("Phase 1 not found")
	}

	if len(phase1.Tasks) != 3 {
		t.Errorf("Expected 3 tasks in Phase 1, got %d", len(phase1.Tasks))
	}

	// Verify progression calculation (2 completed out of 3 = 66.67%)
	expectedProgression := 66.67
	if phase1.Progression < expectedProgression-1 || phase1.Progression > expectedProgression+1 {
		t.Errorf("Expected progression around %.2f%%, got %.2f%%", expectedProgression, phase1.Progression)
	}

	// Verify task ordering (level 1 tasks should come before level 2)
	if phase1.Tasks[0].Level > phase1.Tasks[1].Level {
		t.Error("Tasks not properly ordered by level")
	}

	t.Logf("✅ Phase grouping test passed - %d phases created", len(phaseGroups))
}

// TestRoundtripConsistency tests Markdown → Dynamic → Markdown consistency
func TestRoundtripConsistency(t *testing.T) {
	// This test simulates the roundtrip workflow mentioned in the plan
	tempDir := t.TempDir()

	// Create test SQL storage
	config := DatabaseConfig{
		Driver:     "sqlite",
		Connection: "file:test_roundtrip.db?mode=memory&cache=shared",
	}

	storage, err := NewSQLStorage(config)
	if err != nil {
		t.Fatalf("Failed to create SQL storage: %v", err)
	}
	defer storage.Close()

	// Create original test plan
	originalPlan := &DynamicPlan{
		ID: "roundtrip_test_plan",
		Metadata: PlanMetadata{
			Title:       "Plan Roundtrip Test",
			Version:     "v1.5",
			Description: "Test de cohérence roundtrip",
			Progression: 80.0,
		},
		Tasks: []Task{
			{
				ID:        "rt_task_1",
				Title:     "Tâche Test 1",
				Phase:     "Phase 1",
				Level:     1,
				Completed: true,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			},
			{
				ID:        "rt_task_2",
				Title:     "Tâche Test 2",
				Phase:     "Phase 2",
				Level:     1,
				Completed: false,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			},
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// Store original plan
	err = storage.StorePlan(originalPlan)
	if err != nil {
		t.Fatalf("Failed to store original plan: %v", err)
	}
	// Step 1: Convert Dynamic → Markdown
	qdrantClient := NewQDrantClient("http://localhost:6333")
	syncConfig := &MarkdownSyncConfig{
		OutputDirectory:   tempDir,
		OverwriteExisting: true,
	}

	synchronizer := NewPlanSynchronizer(storage, qdrantClient, syncConfig)

	err = synchronizer.SyncToMarkdown("roundtrip_test_plan")
	if err != nil {
		t.Fatalf("Failed to sync to markdown: %v", err)
	}

	// Verify the generated markdown contains key elements
	outputPath := filepath.Join(tempDir, "plan-roundtrip-test-v1.5.md")
	content, err := os.ReadFile(outputPath)
	if err != nil {
		t.Fatalf("Failed to read generated markdown: %v", err)
	}

	contentStr := string(content)

	// Verify essential structure is preserved
	structuralChecks := []string{
		"# Plan Roundtrip Test",
		"**Version v1.5",
		"Progression globale : 80%",
		"## Phase 1",
		"## Phase 2",
		"- [x] Tâche Test 1",
		"- [ ] Tâche Test 2",
		"*Plan ID: roundtrip_test_plan*",
	}

	for _, check := range structuralChecks {
		if !strings.Contains(contentStr, check) {
			t.Errorf("Missing structural element in generated markdown: %s", check)
		}
	}

	// Step 2: Simulate parsing back (would be done by MarkdownParser from section 2.1.1)
	// For this test, we verify that essential information is preserved

	// Verify task completion status is correctly represented
	completedTaskMatches := strings.Count(contentStr, "- [x]")
	incompleteTaskMatches := strings.Count(contentStr, "- [ ]")

	if completedTaskMatches != 1 {
		t.Errorf("Expected 1 completed task marker, found %d", completedTaskMatches)
	}

	if incompleteTaskMatches != 1 {
		t.Errorf("Expected 1 incomplete task marker, found %d", incompleteTaskMatches)
	}

	// Verify metadata preservation
	if !strings.Contains(contentStr, "80%") {
		t.Error("Progression percentage not preserved")
	}

	if !strings.Contains(contentStr, "v1.5") {
		t.Error("Version not preserved")
	}

	t.Logf("✅ Roundtrip consistency test passed - %d bytes generated", len(content))
}

// TestFilenameSanitization tests filename cleaning functionality
func TestFilenameSanitization(t *testing.T) {
	config := DatabaseConfig{Driver: "sqlite", Connection: "file:test.db?mode=memory"}
	storage, _ := NewSQLStorage(config)
	defer storage.Close()

	qdrantClient := NewQDrantClient("http://localhost:6333")
	synchronizer := NewPlanSynchronizer(storage, qdrantClient, nil)

	testCases := []struct {
		input    string
		expected string
	}{
		{"Plan de Développement v2.0", "plan-de-developpement-v2-0"},
		{"Écosystème Synchronisation", "ecosysteme-synchronisation"},
		{"Plan with Special @#$% Characters!", "plan-with-special-characters"},
		{"UPPERCASE plan", "uppercase-plan"},
		{"Plan---with---multiple---dashes", "plan-with-multiple-dashes"},
		{"Plan à la française", "plan-a-la-francaise"},
	}

	for _, tc := range testCases {
		result := synchronizer.sanitizeFilename(tc.input)
		if result != tc.expected {
			t.Errorf("sanitizeFilename(%q) = %q, expected %q", tc.input, result, tc.expected)
		}
	}

	t.Logf("✅ Filename sanitization test passed - %d test cases", len(testCases))
}

// TestProgressionCalculation tests phase progression calculation
func TestProgressionCalculation(t *testing.T) {
	config := DatabaseConfig{Driver: "sqlite", Connection: "file:test.db?mode=memory"}
	storage, _ := NewSQLStorage(config)
	defer storage.Close()

	qdrantClient := NewQDrantClient("http://localhost:6333")
	synchronizer := NewPlanSynchronizer(storage, qdrantClient, nil)

	testCases := []struct {
		tasks       []Task
		expectedPct float64
		description string
	}{
		{
			tasks:       []Task{},
			expectedPct: 0,
			description: "empty task list",
		},
		{
			tasks: []Task{
				{Completed: true},
				{Completed: true},
				{Completed: true},
			},
			expectedPct: 100,
			description: "all tasks completed",
		},
		{
			tasks: []Task{
				{Completed: false},
				{Completed: false},
				{Completed: false},
			},
			expectedPct: 0,
			description: "no tasks completed",
		},
		{
			tasks: []Task{
				{Completed: true},
				{Completed: false},
				{Completed: true},
				{Completed: false},
			},
			expectedPct: 50,
			description: "half tasks completed",
		},
		{
			tasks: []Task{
				{Completed: true},
				{Completed: true},
				{Completed: false},
			},
			expectedPct: 66.67,
			description: "two thirds completed",
		},
	}

	for _, tc := range testCases {
		result := synchronizer.calculatePhaseProgression(tc.tasks)

		// Allow small floating point differences
		if result < tc.expectedPct-0.01 || result > tc.expectedPct+0.01 {
			t.Errorf("calculatePhaseProgression for %s: expected %.2f%%, got %.2f%%",
				tc.description, tc.expectedPct, result)
		}
	}

	t.Logf("✅ Progression calculation test passed - %d test cases", len(testCases))
}

// TestSyncAllPlans tests bulk synchronization functionality
func TestSyncAllPlans(t *testing.T) {
	tempDir := t.TempDir()

	// Create test SQL storage
	config := DatabaseConfig{
		Driver:     "sqlite",
		Connection: "file:test_sync_all.db?mode=memory&cache=shared",
	}

	storage, err := NewSQLStorage(config)
	if err != nil {
		t.Fatalf("Failed to create SQL storage: %v", err)
	}
	defer storage.Close()
	// Store multiple test plans
	testPlans := []*DynamicPlan{{
		ID:        "bulk_plan_1",
		Metadata:  PlanMetadata{Title: "Plan Bulk 1", Version: "v1.0", FilePath: "bulk/plan1.md", Progression: 25.0},
		Tasks:     []Task{{ID: "t1", Title: "Task 1", Phase: "Phase 1", Completed: false, Level: 1}},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	},
		{
			ID:        "bulk_plan_2",
			Metadata:  PlanMetadata{Title: "Plan Bulk 2", Version: "v2.0", FilePath: "bulk/plan2.md", Progression: 50.0},
			Tasks:     []Task{{ID: "t2", Title: "Task 2", Phase: "Phase 1", Completed: true, Level: 1}},
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		},
		{
			ID:        "bulk_plan_3",
			Metadata:  PlanMetadata{Title: "Plan Bulk 3", Version: "v3.0", FilePath: "bulk/plan3.md", Progression: 75.0},
			Tasks:     []Task{{ID: "t3", Title: "Task 3", Phase: "Phase 1", Completed: true, Level: 1}},
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		},
	}

	for _, plan := range testPlans {
		err = storage.StorePlan(plan)
		if err != nil {
			t.Fatalf("Failed to store plan %s: %v", plan.ID, err)
		}
	}
	// Create synchronizer and sync all
	qdrantClient := NewQDrantClient("http://localhost:6333")
	syncConfig := &MarkdownSyncConfig{
		OutputDirectory:   tempDir,
		OverwriteExisting: true,
	}

	synchronizer := NewPlanSynchronizer(storage, qdrantClient, syncConfig)

	err = synchronizer.SyncAllPlans()
	if err != nil {
		t.Fatalf("Failed to sync all plans: %v", err)
	}

	// Verify all files were created
	expectedFiles := []string{
		"plan-bulk-1-v1.0.md",
		"plan-bulk-2-v2.0.md",
		"plan-bulk-3-v3.0.md",
	}

	for _, filename := range expectedFiles {
		path := filepath.Join(tempDir, filename)
		if !synchronizer.fileExists(path) {
			t.Errorf("Expected file not created: %s", filename)
		}
	}

	// Verify statistics
	stats := synchronizer.GetStats()
	if stats.FilesSynced != 3 {
		t.Errorf("Expected 3 files synced, got %d", stats.FilesSynced)
	}

	t.Logf("✅ Sync all plans test passed - %d files created", len(expectedFiles))
}

// BenchmarkSyncToMarkdown benchmarks the synchronization performance
func BenchmarkSyncToMarkdown(b *testing.B) {
	// Setup
	config := DatabaseConfig{
		Driver:     "sqlite",
		Connection: "file:bench_sync.db?mode=memory&cache=shared",
	}

	storage, err := NewSQLStorage(config)
	if err != nil {
		b.Fatalf("Failed to create SQL storage: %v", err)
	}
	defer storage.Close()

	// Create test plan with many tasks
	tasks := make([]Task, 100)
	for i := 0; i < 100; i++ {
		tasks[i] = Task{
			ID:        fmt.Sprintf("bench_task_%d", i),
			Title:     fmt.Sprintf("Benchmark Task %d", i),
			Phase:     fmt.Sprintf("Phase %d", i%5+1),
			Level:     i%3 + 1,
			Completed: i%2 == 0,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}
	}

	testPlan := &DynamicPlan{
		ID:        "benchmark_plan",
		Metadata:  PlanMetadata{Title: "Benchmark Plan", Version: "v1.0", Progression: 50.0},
		Tasks:     tasks,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	err = storage.StorePlan(testPlan)
	if err != nil {
		b.Fatalf("Failed to store benchmark plan: %v", err)
	}
	tempDir := b.TempDir()
	qdrantClient := NewQDrantClient("http://localhost:6333")
	syncConfig := &MarkdownSyncConfig{
		OutputDirectory:   tempDir,
		OverwriteExisting: true,
	}

	synchronizer := NewPlanSynchronizer(storage, qdrantClient, syncConfig)

	// Reset timer and run benchmark
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		err := synchronizer.SyncToMarkdown("benchmark_plan")
		if err != nil {
			b.Fatalf("Benchmark sync failed: %v", err)
		}
	}
}
