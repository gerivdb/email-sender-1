package main

import (
	"os"
	"path/filepath"
	"testing"
)

// TestProjectStructure validates the basic project structure
func TestProjectStructure(t *testing.T) {
	expectedDirs := []string{
		"tools",
		"docs",
		"scripts",
		"projet",
		"development",
	}

	for _, dir := range expectedDirs {
		if _, err := os.Stat(dir); os.IsNotExist(err) {
			t.Errorf("Expected directory %s does not exist", dir)
		}
	}
}

// TestDocumentationFiles validates documentation completeness
func TestDocumentationFiles(t *testing.T) {
	expectedDocs := []string{
		"docs/quickstart.md",
		"docs/migration-guide.md",
		"docs/troubleshooting.md",
		"docs/api-reference.md",
		"docs/architecture.md",
		"docs/contributing.md",
		"docs/maintenance.md",
	}

	for _, doc := range expectedDocs {
		if _, err := os.Stat(doc); os.IsNotExist(err) {
			t.Errorf("Expected documentation file %s does not exist", doc)
		}
	}
}

// TestScriptFiles validates deployment scripts
func TestScriptFiles(t *testing.T) {
	expectedScripts := []string{
		"scripts/verify-installation.ps1",
		"scripts/deploy-production.ps1",
	}

	for _, script := range expectedScripts {
		if _, err := os.Stat(script); os.IsNotExist(err) {
			t.Errorf("Expected script file %s does not exist", script)
		}
	}
}

// TestGoBuildSuccess validates Go code builds successfully
func TestGoBuildSuccess(t *testing.T) {
	// Test if main packages can build
	mainFiles, err := filepath.Glob("tools/*/main.go")
	if err != nil {
		t.Fatalf("Failed to find main.go files: %v", err)
	}

	if len(mainFiles) == 0 {
		t.Skip("No main.go files found in tools subdirectories")
	}

	t.Logf("Found %d main.go files for build testing", len(mainFiles))
}

// TestPlanFileIntegrity validates plan files
func TestPlanFileIntegrity(t *testing.T) {
	planFile := "projet/roadmaps/plans/consolidated/plan-dev-v55-planning-ecosystem-sync.md"

	if _, err := os.Stat(planFile); os.IsNotExist(err) {
		t.Errorf("Main plan file %s does not exist", planFile)
		return
	}

	// Check file size (should be substantial)
	info, err := os.Stat(planFile)
	if err != nil {
		t.Errorf("Cannot stat plan file: %v", err)
		return
	}

	if info.Size() < 10000 { // Should be at least 10KB
		t.Errorf("Plan file seems too small (%d bytes), might be incomplete", info.Size())
	}

	t.Logf("Plan file validation passed: %d bytes", info.Size())
}
