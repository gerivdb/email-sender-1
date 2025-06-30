package scan_non_compliant_imports_test

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"email_sender/cmd/go/dependency-manager/scan_non_compliant_imports"
)

func TestRunScan(t *testing.T) {
	// Create a temporary directory for testing
	tmpDir, err := ioutil.TempDir("", "test_scan")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create dummy Go files with compliant and non-compliant imports
	compliantGoFile := `package main

import (
	"fmt"
	"email_sender/core/utils"
)

func main() {
	fmt.Println("Hello")
	utils.DoSomething()
}
`
	nonCompliantGoFileRelative := `package main

import (
	"fmt"
	"../another_module"
)

func main() {
	fmt.Println("Hello")
	another_module.DoSomething()
}
`
	nonCompliantGoFileInternal := `package main

import (
	"fmt"
	"email_sender/some_other_module"
)

func main() {
	fmt.Println("Hello")
	some_other_module.DoSomething()
}
`

	// Write compliant file
	err = ioutil.WriteFile(filepath.Join(tmpDir, "compliant.go"), []byte(compliantGoFile), 0o644)
	if err != nil {
		t.Fatalf("Failed to write compliant.go: %v", err)
	}

	// Write non-compliant relative import file
	err = ioutil.WriteFile(filepath.Join(tmpDir, "non_compliant_relative.go"), []byte(nonCompliantGoFileRelative), 0o644)
	if err != nil {
		t.Fatalf("Failed to write non_compliant_relative.go: %v", err)
	}

	// Write non-compliant internal module file
	err = ioutil.WriteFile(filepath.Join(tmpDir, "non_compliant_internal.go"), []byte(nonCompliantGoFileInternal), 0o644)
	if err != nil {
		t.Fatalf("Failed to write non_compliant_internal.go: %v", err)
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
	outputJSON := filepath.Join(tmpDir, "scan_output.json")
	outputMD := filepath.Join(tmpDir, "scan_output.md")

	// Run the scan
	report, err := scan_non_compliant_imports.RunScan(outputJSON, outputMD)
	if err != nil {
		t.Fatalf("RunScan failed: %v", err)
	}

	// Validate report content
	if len(report.NonCompliantImports) != 2 {
		t.Errorf("Expected 2 non-compliant imports, got %d", len(report.NonCompliantImports))
	}

	// Check for specific non-compliant imports
	foundRelative := false
	foundInternal := false
	for _, imp := range report.NonCompliantImports {
		if imp.ImportPath == "../another_module" {
			foundRelative = true
			if imp.FilePath != filepath.ToSlash(filepath.Clean(filepath.Join(tmpDir, "non_compliant_relative.go"))) {
				t.Errorf("Relative import: Expected file path %s, got %s", filepath.ToSlash(filepath.Clean(filepath.Join(tmpDir, "non_compliant_relative.go"))), imp.FilePath)
			}
			if imp.Line != 4 {
				t.Errorf("Relative import: Expected line 4, got %d", imp.Line)
			}
		} else if imp.ImportPath == "email_sender/some_other_module" {
			foundInternal = true
			if imp.FilePath != filepath.ToSlash(filepath.Clean(filepath.Join(tmpDir, "non_compliant_internal.go"))) {
				t.Errorf("Internal import: Expected file path %s, got %s", filepath.ToSlash(filepath.Clean(filepath.Join(tmpDir, "non_compliant_internal.go"))), imp.FilePath)
			}
			if imp.Line != 4 {
				t.Errorf("Internal import: Expected line 4, got %d", imp.Line)
			}
		}
	}

	if !foundRelative {
		t.Error("Relative non-compliant import not found in report")
	}
	if !foundInternal {
		t.Error("Internal non-compliant import not found in report")
	}

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

	var jsonReport scan_non_compliant_imports.ScanReport
	err = json.Unmarshal(jsonData, &jsonReport)
	if err != nil {
		t.Fatalf("Failed to unmarshal JSON data: %v", err)
	}

	if jsonReport.Summary != "Scan completed. Found 2 non-compliant imports." {
		t.Errorf("Expected summary 'Scan completed. Found 2 non-compliant imports.', got '%s'", jsonReport.Summary)
	}
}
