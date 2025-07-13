package validate_monorepo_structure_test

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/gerivdb/email-sender-1/cmd/go/dependency-manager/validate_monorepo_structure"
)

func TestValidateMonorepoStructure(t *testing.T) {
	// Create a temporary directory for testing
	tmpDir, err := ioutil.TempDir("", "test_monorepo_validation")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Case 1: Valid monorepo structure (single go.mod at root)
	// Create dummy go.mod at root
	err = ioutil.WriteFile(filepath.Join(tmpDir, "go.mod"), []byte("module email_sender"), 0o644)
	if err != nil {
		t.Fatalf("Failed to write dummy go.mod: %v", err)
	}

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

	// Run validation for Case 1
	result, err := validate_monorepo_structure.RunValidation()
	if err != nil {
		t.Errorf("Case 1: RunValidation failed: %v", err)
	}
	if !result.IsValid {
		t.Errorf("Case 1: Expected monorepo to be valid, but it was not.")
	}
	if len(result.GoModPaths) != 1 {
		t.Errorf("Case 1: Expected 1 go.mod file, got %d", len(result.GoModPaths))
	}
	if result.GoModPaths[0] != "go.mod" {
		t.Errorf("Case 1: Expected go.mod path 'go.mod', got '%s'", result.GoModPaths[0])
	}

	// Clean up for Case 2
	os.Remove(filepath.Join(tmpDir, "go.mod"))

	// Case 2: Invalid monorepo structure (multiple go.mod files)
	// Create dummy go.mod at root
	err = ioutil.WriteFile(filepath.Join(tmpDir, "go.mod"), []byte("module email_sender"), 0o644)
	if err != nil {
		t.Fatalf("Failed to write dummy go.mod: %v", err)
	}
	// Create dummy go.mod in submodule
	submodulePath := filepath.Join(tmpDir, "submodule")
	os.MkdirAll(submodulePath, 0o755)
	err = ioutil.WriteFile(filepath.Join(submodulePath, "go.mod"), []byte("module github.com/gerivdb/email-sender-1/submodule"), 0o644)
	if err != nil {
		t.Fatalf("Failed to write dummy submodule go.mod: %v", err)
	}

	// Run validation for Case 2
	result, err = validate_monorepo_structure.RunValidation()
	if err == nil {
		t.Errorf("Case 2: Expected RunValidation to fail for multiple go.mod files, but it succeeded.")
	}
	if result.IsValid {
		t.Errorf("Case 2: Expected monorepo to be invalid, but it was valid.")
	}
	if len(result.GoModPaths) != 2 {
		t.Errorf("Case 2: Expected 2 go.mod files, got %d", len(result.GoModPaths))
	}

	// Clean up for Case 3
	os.Remove(filepath.Join(tmpDir, "go.mod"))
	os.RemoveAll(submodulePath)

	// Case 3: Invalid monorepo structure (no go.mod file)
	result, err = validate_monorepo_structure.RunValidation()
	if err == nil {
		t.Errorf("Case 3: Expected RunValidation to fail for no go.mod file, but it succeeded.")
	}
	if result.IsValid {
		t.Errorf("Case 3: Expected monorepo to be invalid, but it was valid.")
	}
	if len(result.GoModPaths) != 0 {
		t.Errorf("Case 3: Expected 0 go.mod files, got %d", len(result.GoModPaths))
	}
}
