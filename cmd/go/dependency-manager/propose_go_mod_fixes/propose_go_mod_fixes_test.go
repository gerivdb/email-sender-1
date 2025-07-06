package propose_go_mod_fixes_test

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gerivdb/email-sender-1/cmd/go/dependency-manager/propose_go_mod_fixes"
)

func TestProposeGoModFixes(t *testing.T) {
	// Create a temporary directory for testing
	tmpDir, err := ioutil.TempDir("", "test_propose_fixes")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create dummy go.mod files for testing
	dummyRootGoMod := filepath.Join(tmpDir, "go.mod")
	dummySubmoduleGoMod := filepath.Join(tmpDir, "submodule", "go.mod")
	dummyAnotherModuleGoMod := filepath.Join(tmpDir, "another_module", "go.mod")

	os.MkdirAll(filepath.Dir(dummySubmoduleGoMod), 0o755)
	os.MkdirAll(filepath.Dir(dummyAnotherModuleGoMod), 0o755)

	ioutil.WriteFile(dummyRootGoMod, []byte("module email_sender"), 0o644)
	ioutil.WriteFile(dummySubmoduleGoMod, []byte("module submodule"), 0o644)
	ioutil.WriteFile(dummyAnotherModuleGoMod, []byte("module another_module"), 0o644)

	// List of parasitic go.mod files (simulating output from scan_go_mods)
	parasiticGoMods := []string{
		filepath.Join("submodule", "go.mod"),
		filepath.Join("another_module", "go.mod"),
	}

	// Create a JSON input file for the propose fixes script
	inputJSONPath := filepath.Join(tmpDir, "parasitic_go_mods.json")
	jsonData, _ := json.MarshalIndent(parasiticGoMods, "", "  ")
	ioutil.WriteFile(inputJSONPath, jsonData, 0o644)

	// Define output paths for the test
	outputScriptPath := filepath.Join(tmpDir, "fix_go_mod_parasites.sh")
	outputPatchPath := filepath.Join(tmpDir, "fix_go_mod_parasites.patch")
	outputJSONReportPath := filepath.Join(tmpDir, "go_mod_fix_plan.json")

	// Change current working directory to the temporary directory
	originalWD, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get original working directory: %v", err)
	}
	err = os.Chdir(tmpDir)
	if err != nil {
		t.Fatalf("Failed to change working directory to temp dir: %v", err)
	}
	defer os.Chdir(originalWD) // Restore original working directory

	// Run the propose fixes function
	report, err := propose_go_mod_fixes.RunProposeFixes(inputJSONPath, outputScriptPath, outputPatchPath, outputJSONReportPath)
	if err != nil {
		t.Fatalf("RunProposeFixes failed: %v", err)
	}

	// Validate report content
	if len(report.FilesToModify) != 0 {
		t.Errorf("Expected 0 files to modify, got %d", len(report.FilesToModify))
	}
	if len(report.FilesToDelete) != 2 {
		t.Errorf("Expected 2 files to delete, got %d", len(report.FilesToDelete))
	}
	if !contains(report.FilesToDelete, "submodule/go.mod") {
		t.Errorf("Expected submodule/go.mod in files to delete")
	}
	if !contains(report.FilesToDelete, "another_module/go.mod") {
		t.Errorf("Expected another_module/go.mod in files to delete")
	}

	// Check if output files were created
	if _, err := os.Stat(outputScriptPath); os.IsNotExist(err) {
		t.Errorf("Output script file not created at %s", outputScriptPath)
	}
	if _, err := os.Stat(outputPatchPath); os.IsNotExist(err) {
		t.Errorf("Output patch file not created at %s", outputPatchPath)
	}
	if _, err := os.Stat(outputJSONReportPath); os.IsNotExist(err) {
		t.Errorf("Output JSON report file not created at %s", outputJSONReportPath)
	}

	// Read and validate the generated script content
	scriptContent, err := ioutil.ReadFile(outputScriptPath)
	if err != nil {
		t.Fatalf("Failed to read generated script: %v", err)
	}
	if !strings.Contains(string(scriptContent), "rm submodule/go.mod") || !strings.Contains(string(scriptContent), "rm another_module/go.mod") {
		t.Errorf("Generated script content is incorrect: %s", string(scriptContent))
	}
}

func contains(s []string, e string) bool {
	for _, a := range s {
		if a == e {
			return true
		}
	}
	return false
}
