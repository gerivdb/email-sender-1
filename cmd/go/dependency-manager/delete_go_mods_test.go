package delete_go_mods_test

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/gerivdb/email-sender-1/cmd/go/dependency-manager/delete_go_mods"
)

func TestDeleteGoMods(t *testing.T) {
	// Create a temporary directory for testing
	tmpDir, err := ioutil.TempDir("", "test_delete_go_mods")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create dummy go.mod files for deletion
	dummyRootGoMod := filepath.Join(tmpDir, "go.mod")
	dummySubmoduleGoMod := filepath.Join(tmpDir, "submodule", "go.mod")
	dummyAnotherModuleGoMod := filepath.Join(tmpDir, "another_module", "go.mod")
	dummySubmoduleGoSum := filepath.Join(tmpDir, "submodule", "go.sum")

	os.MkdirAll(filepath.Dir(dummySubmoduleGoMod), 0o755)
	os.MkdirAll(filepath.Dir(dummyAnotherModuleGoMod), 0o755)

	ioutil.WriteFile(dummyRootGoMod, []byte("module root"), 0o644)
	ioutil.WriteFile(dummySubmoduleGoMod, []byte("module submodule"), 0o644)
	ioutil.WriteFile(dummyAnotherModuleGoMod, []byte("module another_module"), 0o644)
	ioutil.WriteFile(dummySubmoduleGoSum, []byte("submodule sum"), 0o644)

	// List of files to delete (simulating output from plan_go_mod_deletion)
	filesToDelete := []string{
		filepath.Join("submodule", "go.mod"),
		filepath.Join("another_module", "go.mod"),
		filepath.Join("submodule", "go.sum"),
	}

	// Create a JSON input file for the delete script
	inputJSONPath := filepath.Join(tmpDir, "files_to_delete.json")
	jsonData, _ := json.MarshalIndent(filesToDelete, "", "  ")
	ioutil.WriteFile(inputJSONPath, jsonData, 0o644)

	// Define output report path
	outputReportPath := filepath.Join(tmpDir, "delete_report.json")

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

	// Run the delete function
	err = delete_go_mods.RunDelete(inputJSONPath, outputReportPath)
	if err != nil {
		t.Fatalf("RunDelete failed: %v", err)
	}

	// Verify files are deleted
	if _, err := os.Stat(dummySubmoduleGoMod); !os.IsNotExist(err) {
		t.Errorf("File %s was not deleted", dummySubmoduleGoMod)
	}
	if _, err := os.Stat(dummyAnotherModuleGoMod); !os.IsNotExist(err) {
		t.Errorf("File %s was not deleted", dummyAnotherModuleGoMod)
	}
	if _, err := os.Stat(dummySubmoduleGoSum); !os.IsNotExist(err) {
		t.Errorf("File %s was not deleted", dummySubmoduleGoSum)
	}
	if _, err := os.Stat(dummyRootGoMod); os.IsNotExist(err) {
		t.Errorf("Root go.mod %s was unexpectedly deleted", dummyRootGoMod)
	}

	// Read and validate the report
	reportData, err := ioutil.ReadFile(outputReportPath)
	if err != nil {
		t.Fatalf("Failed to read report file: %v", err)
	}
	var report delete_go_mods.DeletionReport
	err = json.Unmarshal(reportData, &report)
	if err != nil {
		t.Fatalf("Failed to unmarshal report data: %v", err)
	}

	if report.TotalAttempted != 3 {
		t.Errorf("Expected 3 attempted deletions, got %d", report.TotalAttempted)
	}
	if report.TotalDeleted != 3 {
		t.Errorf("Expected 3 successful deletions, got %d", report.TotalDeleted)
	}
	if len(report.Errors) != 0 {
		t.Errorf("Expected 0 errors, got %d: %v", len(report.Errors), report.Errors)
	}
}
