package scan_imports_test

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath" // Re-add strings import
	"testing"

	"github.com/gerivdb/email-sender-1/cmd/go/dependency-manager/scan_imports"
)

func TestRunScan(t *testing.T) {
	// Create a temporary directory for testing
	tmpDir, err := ioutil.TempDir("", "test_scan_imports")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create dummy Go files
	goFile1Content := `package main

import (
	"fmt"
	"github.com/gerivdb/email-sender-1/core/moduleA"
	"github.com/gerivdb/email-sender-1/core/moduleB"
)

func main() {
	fmt.Println("Hello")
	moduleA.DoSomething()
	moduleB.DoAnotherThing()
}
`
	goFile2Content := `package anothermodule

import (
	"log"
	"github.com/gerivdb/email-sender-1/core/moduleC"
)

func init() {
	log.Println("Init anothermodule")
	moduleC.Setup()
}
`
	// Write dummy Go files
	err = ioutil.WriteFile(filepath.Join(tmpDir, "file1.go"), []byte(goFile1Content), 0o644)
	if err != nil {
		t.Fatalf("Failed to write file1.go: %v", err)
	}
	err = ioutil.WriteFile(filepath.Join(tmpDir, "file2.go"), []byte(goFile2Content), 0o644)
	if err != nil {
		t.Fatalf("Failed to write file2.go: %v", err)
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
	outputJSON := filepath.Join(tmpDir, "imports_output.json")
	outputMD := filepath.Join(tmpDir, "imports_output.md")

	// Run the scan
	report, err := scan_imports.RunScan(tmpDir, outputJSON, outputMD)
	if err != nil {
		t.Fatalf("RunScan failed: %v", err)
	}

	// Validate report content
	if len(report.FileImports) != 2 {
		t.Errorf("Expected 2 files in report, got %d", len(report.FileImports))
	}

	// Check imports for file1.go
	file1Imports := report.FileImports[filepath.ToSlash(filepath.Clean(filepath.Join(tmpDir, "file1.go")))]
	if len(file1Imports.Imports) == 0 {
		t.Fatalf("Imports for file1.go not found in report")
	}
	if len(file1Imports.Imports) != 3 {
		t.Errorf("Expected 3 imports for file1.go, got %d", len(file1Imports.Imports))
	}
	if !contains(file1Imports.Imports, "fmt") || !contains(file1Imports.Imports, "github.com/gerivdb/email-sender-1/core/moduleA") || !contains(file1Imports.Imports, "github.com/gerivdb/email-sender-1/core/moduleB") {
		t.Errorf("Incorrect imports for file1.go: %v", file1Imports.Imports)
	}

	// Check imports for file2.go
	file2Imports := report.FileImports[filepath.ToSlash(filepath.Clean(filepath.Join(tmpDir, "file2.go")))]
	if len(file2Imports.Imports) == 0 {
		t.Fatalf("Imports for file2.go not found in report")
	}
	if len(file2Imports.Imports) != 2 {
		t.Errorf("Expected 2 imports for file2.go, got %d", len(file2Imports.Imports))
	}
	if !contains(file2Imports.Imports, "log") || !contains(file2Imports.Imports, "github.com/gerivdb/email-sender-1/core/moduleC") {
		t.Errorf("Incorrect imports for file2.go: %v", file2Imports.Imports)
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

	var jsonReport scan_imports.ScanReport
	err = json.Unmarshal(jsonData, &jsonReport)
	if err != nil {
		t.Fatalf("Failed to unmarshal JSON data: %v", err)
	}

	if jsonReport.Summary != "Scan completed. Found imports in 2 files." {
		t.Errorf("Expected summary 'Scan completed. Found imports in 2 files.', got '%s'", jsonReport.Summary)
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
