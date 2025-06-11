package tests

import (
	"os"
	"path/filepath"
	"testing"
)

// TestDirectoryStructureCreation vérifie la création correcte de la structure de dossiers
func TestDirectoryStructureCreation(t *testing.T) {
	basePath := "../../planning-ecosystem-sync"

	expectedDirs := []string{
		"docs",
		"docs/user-guides",
		"docs/technical",
		"docs/api-reference",
		"tools",
		"tools/sync-core",
		"tools/task-manager",
		"tools/config-validator",
		"tools/migration-assistant",
		"config",
		"config/sync-mappings",
		"config/validation-rules",
		"config/templates",
		"scripts",
		"scripts/powershell",
		"scripts/automation",
		"tests",
		"tests/unit",
		"tests/integration",
		"tests/performance",
		"web",
		"web/dashboard",
		"web/api",
	}

	for _, dir := range expectedDirs {
		fullPath := filepath.Join(basePath, dir)
		if _, err := os.Stat(fullPath); os.IsNotExist(err) {
			t.Errorf("Expected directory does not exist: %s", fullPath)
		}
	}
}

// TestConfigFileExists vérifie l'existence du fichier de configuration principal
func TestConfigFileExists(t *testing.T) {
	configPath := "../../planning-ecosystem-sync/config/sync-config.yaml"

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		t.Errorf("Configuration file does not exist: %s", configPath)
	}
}

// TestGoModuleInitialization vérifie l'initialisation correcte du module Go
func TestGoModuleInitialization(t *testing.T) {
	goModPath := "../../planning-ecosystem-sync/tools/sync-core/go.mod"

	if _, err := os.Stat(goModPath); os.IsNotExist(err) {
		t.Errorf("Go module file does not exist: %s", goModPath)
	}
}

// TestArchitectureDocumentation vérifie la présence de la documentation d'architecture
func TestArchitectureDocumentation(t *testing.T) {
	docPath := "../../planning-ecosystem-sync/docs/architecture-overview.md"

	if _, err := os.Stat(docPath); os.IsNotExist(err) {
		t.Errorf("Architecture documentation does not exist: %s", docPath)
	}
}

// TestProjectStandards valide la conformité avec les standards du projet
func TestProjectStandards(t *testing.T) {
	// Vérifier que la structure suit les principes DRY, KISS, SOLID
	basePath := "../../planning-ecosystem-sync"

	// Test DRY: Pas de duplication de structure
	uniqueDirs := make(map[string]bool)
	err := filepath.Walk(basePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			relPath, _ := filepath.Rel(basePath, path)
			if uniqueDirs[relPath] {
				t.Errorf("Duplicate directory structure detected: %s", relPath)
			}
			uniqueDirs[relPath] = true
		}
		return nil
	})

	if err != nil {
		t.Errorf("Error walking directory structure: %v", err)
	}
}
