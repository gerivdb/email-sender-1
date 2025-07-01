package scanmodules

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestModuleInfo(t *testing.T) {
	// Test de création d'une structure ModuleInfo
	module := ModuleInfo{
		Name:         "test/module",
		Path:         "/path/to/module",
		Description:  "Test module",
		LastModified: time.Now(),
	}

	if module.Name != "test/module" {
		t.Errorf("Expected Name to be 'test/module', got %s", module.Name)
	}

	if module.Path != "/path/to/module" {
		t.Errorf("Expected Path to be '/path/to/module', got %s", module.Path)
	}

	if module.Description != "Test module" {
		t.Errorf("Expected Description to be 'Test module', got %s", module.Description)
	}
}

func TestRepositoryStructure(t *testing.T) {
	// Test de création d'une structure RepositoryStructure
	modules := []ModuleInfo{
		{
			Name:         "module1",
			Path:         "/path/1",
			Description:  "Module 1",
			LastModified: time.Now(),
		},
		{
			Name:         "module2",
			Path:         "/path/2",
			Description:  "Module 2",
			LastModified: time.Now(),
		},
	}

	repo := RepositoryStructure{
		TreeOutput:   "test tree output",
		Modules:      modules,
		TotalModules: len(modules),
		GeneratedAt:  time.Now(),
		RootPath:     "/test/root",
	}

	if repo.TotalModules != 2 {
		t.Errorf("Expected TotalModules to be 2, got %d", repo.TotalModules)
	}

	if len(repo.Modules) != 2 {
		t.Errorf("Expected 2 modules, got %d", len(repo.Modules))
	}

	if repo.RootPath != "/test/root" {
		t.Errorf("Expected RootPath to be '/test/root', got %s", repo.RootPath)
	}
}

func TestScanOptions(t *testing.T) {
	// Test de création d'une structure ScanOptions
	options := ScanOptions{
		TreeLevels: 3,
		OutputDir:  "/test/output",
	}

	if options.TreeLevels != 3 {
		t.Errorf("Expected TreeLevels to be 3, got %d", options.TreeLevels)
	}

	if options.OutputDir != "/test/output" {
		t.Errorf("Expected OutputDir to be '/test/output', got %s", options.OutputDir)
	}
}

func TestSaveToJSON(t *testing.T) {
	// Test de sauvegarde JSON
	tempDir := t.TempDir()

	structure := &RepositoryStructure{
		TreeOutput:   "test output",
		Modules:      []ModuleInfo{},
		TotalModules: 0,
		GeneratedAt:  time.Now().Truncate(time.Second),
		RootPath:     "/test",
	}

	err := SaveToJSON(structure, tempDir)
	if err != nil {
		t.Fatalf("SaveToJSON failed: %v", err)
	}

	// Vérifier que le fichier a été créé
	jsonFile := filepath.Join(tempDir, "modules.json")
	if _, err := os.Stat(jsonFile); os.IsNotExist(err) {
		t.Errorf("JSON file was not created")
	}

	// Vérifier le contenu
	data, err := os.ReadFile(jsonFile)
	if err != nil {
		t.Fatalf("Failed to read JSON file: %v", err)
	}

	var restored RepositoryStructure
	err = json.Unmarshal(data, &restored)
	if err != nil {
		t.Fatalf("Failed to unmarshal JSON: %v", err)
	}

	if restored.TreeOutput != structure.TreeOutput {
		t.Errorf("TreeOutput mismatch: expected %s, got %s", structure.TreeOutput, restored.TreeOutput)
	}

	if restored.RootPath != structure.RootPath {
		t.Errorf("RootPath mismatch: expected %s, got %s", structure.RootPath, restored.RootPath)
	}
}

func TestPrintSummary(t *testing.T) {
	// Test que PrintSummary ne panic pas
	structure := &RepositoryStructure{
		TreeOutput: "test output",
		Modules: []ModuleInfo{
			{Name: "test/module", Path: "/test", Description: "Test", LastModified: time.Now()},
		},
		TotalModules: 1,
		GeneratedAt:  time.Now(),
		RootPath:     "/test",
	}

	// Ce test vérifie juste que la fonction ne panic pas
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("PrintSummary panicked: %v", r)
		}
	}()

	PrintSummary(structure, ".")
}

// Benchmark pour mesurer les performances
func BenchmarkModuleInfoCreation(b *testing.B) {
	for i := 0; i < b.N; i++ {
		module := ModuleInfo{
			Name:         "benchmark/module",
			Path:         "/benchmark/path",
			Description:  "Benchmark module",
			LastModified: time.Now(),
		}
		_ = module // Éviter l'optimisation du compilateur
	}
}

func BenchmarkJSONMarshal(b *testing.B) {
	repo := RepositoryStructure{
		TreeOutput:   "benchmark tree output",
		Modules:      make([]ModuleInfo, 100),
		TotalModules: 100,
		GeneratedAt:  time.Now(),
		RootPath:     "/benchmark/root",
	}

	// Remplir avec des données de test
	for i := 0; i < 100; i++ {
		repo.Modules[i] = ModuleInfo{
			Name:         "benchmark/module",
			Path:         "/benchmark/path",
			Description:  "Benchmark module",
			LastModified: time.Now(),
		}
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, err := json.Marshal(repo)
		if err != nil {
			b.Fatalf("JSON marshaling failed: %v", err)
		}
	}
}
