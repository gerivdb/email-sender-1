package integration

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func createTempDir(t *testing.T) string {
	dir, err := ioutil.TempDir("", "test_project_scanner")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	return dir
}

func createTestFile(t *testing.T, dir, filename, content string) {
	filePath := filepath.Join(dir, filename)
	err := ioutil.WriteFile(filePath, []byte(content), 0o644)
	if err != nil {
		t.Fatalf("Failed to create test file %s: %v", filePath, err)
	}
}

func createTestDir(t *testing.T, parentDir, dirName string) string {
	newDir := filepath.Join(parentDir, dirName)
	err := os.MkdirAll(newDir, 0o755)
	if err != nil {
		t.Fatalf("Failed to create test dir %s: %v", newDir, err)
	}
	return newDir
}

func TestLangScanner_Scan(t *testing.T) {
	tempRoot := createTempDir(t)
	defer os.RemoveAll(tempRoot) // Clean up after test

	// Create a Go project
	goDir := createTestDir(t, tempRoot, "my-go-app")
	createTestFile(t, goDir, "main.go", "package main\nfunc main(){}")
	createTestFile(t, goDir, "go.mod", "module my-go-app")

	// Create a Python project
	pythonDir := createTestDir(t, tempRoot, "my-python-script")
	createTestFile(t, pythonDir, "script.py", "print('Hello')")
	createTestFile(t, pythonDir, "__init__.py", "")

	// Create a Node.js project
	nodeDir := createTestDir(t, tempRoot, "my-node-app")
	createTestFile(t, nodeDir, "index.js", "console.log('Node');")
	createTestFile(t, nodeDir, "package.json", "{}")

	// Create a PowerShell project
	psDir := createTestDir(t, tempRoot, "my-ps-script")
	createTestFile(t, psDir, "run.ps1", "Write-Host 'PS'")

	// Create a mixed project (Go and Python, primarily Go)
	mixedDir := createTestDir(t, tempRoot, "mixed-project")
	createTestFile(t, mixedDir, "main.go", "package main")
	createTestFile(t, mixedDir, "util.py", "def func(): pass")

	// Create a directory with unknown files
	unknownDir := createTestDir(t, tempRoot, "unknown-project")
	createTestFile(t, unknownDir, "README.md", "# Readme")
	createTestFile(t, unknownDir, "config.txt", "settings")

	// Create a directory with node_modules to ensure it's skipped
	nodeModulesDir := createTestDir(t, tempRoot, "project-with-node_modules")
	createTestDir(t, nodeModulesDir, "node_modules")
	createTestFile(t, filepath.Join(nodeModulesDir, "node_modules"), "some-lib.js", "console.log('lib');")
	createTestFile(t, nodeModulesDir, "app.js", "console.log('app');")

	scanner := NewLangScanner()
	projects, err := scanner.Scan(tempRoot)
	if err != nil {
		t.Fatalf("Scan failed: %v", err)
	}

	expectedProjects := map[string]ProjectType{
		filepath.Join(goDir, "main.go"):         GoProject,
		filepath.Join(pythonDir, "script.py"):   PythonProject,
		filepath.Join(nodeDir, "index.js"):      NodeJSProject,
		filepath.Join(psDir, "run.ps1"):         PowerShellProject,
		filepath.Join(mixedDir, "main.go"):      GoProject,
		filepath.Join(mixedDir, "util.py"):      PythonProject,
		filepath.Join(nodeModulesDir, "app.js"): NodeJSProject, // app.js should be detected, node_modules skipped
	}

	if len(projects) != len(expectedProjects) {
		t.Errorf("Expected %d projects, got %d", len(expectedProjects), len(projects))
		for _, p := range projects {
			t.Logf("Found: %s (%s)", p.Path, p.Type)
		}
		t.FailNow()
	}

	for _, p := range projects {
		expectedType, ok := expectedProjects[p.Path]
		if !ok {
			t.Errorf("Found unexpected project: %s (%s)", p.Path, p.Type)
		} else if expectedType != p.Type {
			t.Errorf("Project %s: Expected type %s, got %s", p.Path, expectedType, p.Type)
		}
		delete(expectedProjects, p.Path) // Remove found project
	}

	if len(expectedProjects) > 0 {
		t.Errorf("Missing expected projects:")
		for path, typ := range expectedProjects {
			t.Errorf("- %s (%s)", path, typ)
		}
	}
}

func TestLangScanner_Scan_Error(t *testing.T) {
	scanner := NewLangScanner()
	_, err := scanner.Scan("/nonexistent/path/to/scan")
	if err == nil {
		t.Fatal("Scan should return an error for a nonexistent path")
	}
	expectedErrSubstring := "erreur de lecture du répertoire"
	if !strings.Contains(err.Error(), expectedErrSubstring) {
		t.Errorf("Expected error message to contain '%s', got '%s'", expectedErrSubstring, err.Error())
	}
}
