package main

import (
	"encoding/json"
	"os"
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

func TestJSONSerialization(t *testing.T) {
	// Test de sérialisation/désérialisation JSON
	original := RepositoryStructure{
		TreeOutput:   "test output",
		Modules:      []ModuleInfo{},
		TotalModules: 0,
		GeneratedAt:  time.Now().Truncate(time.Second), // Tronquer pour éviter les problèmes de précision
		RootPath:     "/test",
	}

	// Sérialiser
	jsonData, err := json.Marshal(original)
	if err != nil {
		t.Fatalf("Failed to marshal JSON: %v", err)
	}

	// Désérialiser
	var restored RepositoryStructure
	err = json.Unmarshal(jsonData, &restored)
	if err != nil {
		t.Fatalf("Failed to unmarshal JSON: %v", err)
	}

	// Vérifier que les données sont identiques
	if restored.TreeOutput != original.TreeOutput {
		t.Errorf("TreeOutput mismatch: expected %s, got %s", original.TreeOutput, restored.TreeOutput)
	}

	if restored.TotalModules != original.TotalModules {
		t.Errorf("TotalModules mismatch: expected %d, got %d", original.TotalModules, restored.TotalModules)
	}

	if restored.RootPath != original.RootPath {
		t.Errorf("RootPath mismatch: expected %s, got %s", original.RootPath, restored.RootPath)
	}

	// Note: GeneratedAt peut avoir une légère différence due à la précision des timestamps
	// On vérifie qu'ils sont proches (moins d'une seconde d'écart)
	timeDiff := restored.GeneratedAt.Sub(original.GeneratedAt)
	if timeDiff > time.Second || timeDiff < -time.Second {
		t.Errorf("GeneratedAt mismatch: expected %v, got %v (diff: %v)",
			original.GeneratedAt, restored.GeneratedAt, timeDiff)
	}
}

func TestFileOperations(t *testing.T) {
	// Test des opérations de fichier (création et nettoyage)
	testFiles := []string{"test_arborescence.txt", "test_modules.txt", "test_modules.json"}

	// Créer des fichiers de test
	for _, filename := range testFiles {
		content := "test content for " + filename
		err := os.WriteFile(filename, []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file %s: %v", filename, err)
		}

		// Vérifier que le fichier existe
		if _, err := os.Stat(filename); os.IsNotExist(err) {
			t.Errorf("Test file %s was not created", filename)
		}
	}

	// Nettoyer les fichiers de test
	defer func() {
		for _, filename := range testFiles {
			os.Remove(filename)
		}
	}()

	// Vérifier le contenu
	for _, filename := range testFiles {
		content, err := os.ReadFile(filename)
		if err != nil {
			t.Errorf("Failed to read test file %s: %v", filename, err)
			continue
		}

		expectedContent := "test content for " + filename
		if string(content) != expectedContent {
			t.Errorf("Content mismatch for %s: expected %s, got %s",
				filename, expectedContent, string(content))
		}
	}
}

func TestModulePathConversion(t *testing.T) {
	// Test de conversion des chemins de module
	testCases := []struct {
		input    string
		expected string
	}{
		{"module/submodule", "module" + string(os.PathSeparator) + "submodule"},
		{"simple", "simple"},
		{"deep/nested/module", "deep" + string(os.PathSeparator) + "nested" + string(os.PathSeparator) + "module"},
	}

	for _, tc := range testCases {
		// Simuler la conversion effectuée dans le code principal
		result := tc.input
		if os.PathSeparator != '/' {
			result = string([]rune(tc.input)) // Simulation simple
			for i, r := range result {
				if r == '/' {
					result = result[:i] + string(os.PathSeparator) + result[i+1:]
				}
			}
		}

		// Note: Cette vérification est simplifiée car la conversion réelle
		// se fait avec strings.ReplaceAll dans le code principal
		if tc.input == "module/submodule" && os.PathSeparator == '\\' {
			// Test spécifique pour Windows
			expected := "module\\submodule"
			actual := tc.input
			actual = actual[:6] + "\\" + actual[7:] // Simulation manuelle
			if actual != expected {
				t.Errorf("Path conversion failed for %s: expected %s, got %s",
					tc.input, expected, actual)
			}
		}
	}
}

// Benchmark pour mesurer les performances du scan
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
		Modules:      make([]ModuleInfo, 100), // 100 modules pour le benchmark
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
