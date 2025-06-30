package audit_modules_test

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"email_sender/cmd/go/dependency-manager/audit_modules"
)

func TestAuditModules(t *testing.T) {
	// Create a temporary directory for testing
	tmpDir, err := ioutil.TempDir("", "test_audit")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create dummy go.mod and go.sum files
	dummyGoModContent := `
module email_sender/core/testmodule
go 1.18
require (
	github.com/stretchr/testify v1.7.0
	golang.org/x/text v0.3.0
)
`
	dummyGoModPath := filepath.Join(tmpDir, "go.mod")
	err = ioutil.WriteFile(dummyGoModPath, []byte(dummyGoModContent), 0o644)
	if err != nil {
		t.Fatalf("Failed to write dummy go.mod: %v", err)
	}

	dummyGoModSubPath := filepath.Join(tmpDir, "submodule", "go.mod")
	os.MkdirAll(filepath.Dir(dummyGoModSubPath), 0o755)
	err = ioutil.WriteFile(dummyGoModSubPath, []byte("module submodule"), 0o644)
	if err != nil {
		t.Fatalf("Failed to write dummy submodule go.mod: %v", err)
	}

	dummyGoSumPath := filepath.Join(tmpDir, "go.sum")
	err = ioutil.WriteFile(dummyGoSumPath, []byte("example.com/some/dep v1.0.0 h1:checksum"), 0o644)
	if err != nil {
		t.Fatalf("Failed to write dummy go.sum: %v", err)
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

	// Define output paths for the test
	outputJSON := filepath.Join(tmpDir, "output.json")
	outputMD := filepath.Join(tmpDir, "output.md")

	// Capture stdout
	oldStdout := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	// Run the audit_modules function
	err = audit_modules.RunAudit(outputJSON, outputMD)
	if err != nil {
		t.Fatalf("RunAudit failed: %v", err)
	}

	w.Close()
	os.Stdout = oldStdout
	var buf bytes.Buffer
	buf.ReadFrom(r)
	output := buf.String()

	// Check if output files were created
	if _, err := os.Stat(outputJSON); os.IsNotExist(err) {
		t.Errorf("JSON output file not created at %s", outputJSON)
	}
	if _, err := os.Stat(outputMD); os.IsNotExist(err) {
		t.Errorf("Markdown output file not created at %s", outputMD)
	}

	// Read and parse JSON output
	jsonData, err := ioutil.ReadFile(outputJSON)
	if err != nil {
		t.Fatalf("Failed to read JSON output: %v", err)
	}

	var report audit_modules.AuditReport
	err = json.Unmarshal(jsonData, &report)
	if err != nil {
		t.Fatalf("Failed to unmarshal JSON data: %v", err)
	}

	// Validate report content
	if len(report.GoModFiles) != 2 {
		t.Errorf("Expected 2 go.mod files, got %d", len(report.GoModFiles))
	}
	if len(report.GoSumFiles) != 1 {
		t.Errorf("Expected 1 go.sum file, got %d", len(report.GoSumFiles))
	}

	// Validate specific go.mod file content
	foundMainModule := false
	foundSubModule := false
	for _, gm := range report.GoModFiles {
		if gm.Path == "go.mod" {
			foundMainModule = true
			if gm.ModuleName != "email_sender/core/testmodule" {
				t.Errorf("Main go.mod: Expected module name 'email_sender/core/testmodule', got '%s'", gm.ModuleName)
			}
			if gm.GoVersion != "1.18" {
				t.Errorf("Main go.mod: Expected go version '1.18', got '%s'", gm.GoVersion)
			}
			if len(gm.Dependencies) != 2 {
				t.Errorf("Main go.mod: Expected 2 dependencies, got %d", len(gm.Dependencies))
			}
		} else if gm.Path == filepath.Join("submodule", "go.mod") {
			foundSubModule = true
			if gm.ModuleName != "submodule" {
				t.Errorf("Submodule go.mod: Expected module name 'submodule', got '%s'", gm.ModuleName)
			}
			if len(report.NonConformantModules) != 1 {
				t.Errorf("Expected 1 non-conformant module, got %d", len(report.NonConformantModules))
			} else if report.NonConformantModules[0] != "submodule" {
				t.Errorf("Expected non-conformant module 'submodule', got '%s'", report.NonConformantModules[0])
			}
		}
	}
	if !foundMainModule {
		t.Error("Main go.mod not found in report")
	}
	if !foundSubModule {
		t.Error("Submodule go.mod not found in report")
	}

	// Check stdout for expected messages
	if !strings.Contains(output, "JSON report written to") {
		t.Errorf("Stdout did not contain expected JSON message: %s", output)
	}
	if !strings.Contains(output, "Markdown report written to") {
		t.Errorf("Stdout did not contain expected Markdown message: %s", output)
	}
}
