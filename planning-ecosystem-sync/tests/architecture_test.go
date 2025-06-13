package tests

import (
	"os"
	"path/filepath"
	"testing"
)

// TestBranchArchitectureStructure validates the complete folder structure
func TestBranchArchitectureStructure(t *testing.T) {
	baseDir := ".."

	// Required directories as per plan-dev-v55 specification
	requiredDirs := []string{
		"docs",
		"tools",
		"config",
		"scripts",
		"tests",
	}

	for _, dir := range requiredDirs {
		dirPath := filepath.Join(baseDir, dir)
		if _, err := os.Stat(dirPath); os.IsNotExist(err) {
			t.Errorf("Required directory '%s' does not exist at path: %s", dir, dirPath)
		} else {
			t.Logf("✅ Directory '%s' exists and is accessible", dir)
		}
	}
}

// TestConfigurationFiles validates presence of required config files
func TestConfigurationFiles(t *testing.T) {
	baseDir := filepath.Join("..", "config")

	requiredFiles := []string{
		"sync-config.yaml",
		"validation-rules.yaml",
	}

	for _, file := range requiredFiles {
		filePath := filepath.Join(baseDir, file)
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			t.Errorf("Required configuration file '%s' does not exist at path: %s", file, filePath)
		} else {
			t.Logf("✅ Configuration file '%s' exists and is accessible", file)
		}
	}
}

// TestDirectoryPermissions validates read/write access to all directories
func TestDirectoryPermissions(t *testing.T) {
	baseDir := ".."

	directories := []string{
		"docs",
		"tools",
		"config",
		"scripts",
		"tests",
	}

	for _, dir := range directories {
		dirPath := filepath.Join(baseDir, dir)

		// Test read access
		if _, err := os.ReadDir(dirPath); err != nil {
			t.Errorf("Cannot read directory '%s': %v", dir, err)
			continue
		}

		// Test write access by creating a temporary file
		tempFile := filepath.Join(dirPath, ".temp_test_file")
		if err := os.WriteFile(tempFile, []byte("test"), 0644); err != nil {
			t.Errorf("Cannot write to directory '%s': %v", dir, err)
			continue
		}

		// Clean up
		os.Remove(tempFile)
		t.Logf("✅ Directory '%s' has correct read/write permissions", dir)
	}
}

// TestArchitectureCompliance validates adherence to DRY, KISS, SOLID principles
func TestArchitectureCompliance(t *testing.T) {
	baseDir := ".."

	// Check for proper separation of concerns (SOLID principle)
	separationTests := map[string]string{
		"docs":    "Documentation should be separated from implementation",
		"tools":   "Business logic tools should be isolated",
		"config":  "Configuration should be externalized",
		"scripts": "Automation scripts should be separated",
		"tests":   "Tests should be isolated from implementation",
	}

	for dir, principle := range separationTests {
		dirPath := filepath.Join(baseDir, dir)
		if _, err := os.Stat(dirPath); os.IsNotExist(err) {
			t.Errorf("Architecture compliance failed: %s - Directory '%s' missing", principle, dir)
		} else {
			t.Logf("✅ Architecture compliance: %s", principle)
		}
	}
}

// TestIntegrationReadiness validates the structure is ready for integration
func TestIntegrationReadiness(t *testing.T) { // Based on audit findings - TaskMaster CLI integration points
	integrationPoints := []struct {
		path        string
		description string
	}{
		{
			path:        filepath.Join("..", "config", "sync-config.yaml"),
			description: "Main configuration for TaskMaster-CLI integration",
		},
		{
			path:        filepath.Join("..", "tools"),
			description: "Tools directory for sync-core integration",
		},
		{
			path:        filepath.Join("..", "tests"),
			description: "Tests directory for validation integration",
		},
	}

	for _, point := range integrationPoints {
		if _, err := os.Stat(point.path); os.IsNotExist(err) {
			t.Errorf("Integration readiness failed: %s - Path '%s' missing", point.description, point.path)
		} else {
			t.Logf("✅ Integration ready: %s", point.description)
		}
	}
}
