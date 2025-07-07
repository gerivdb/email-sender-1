package scripts

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestGenerateInventory(t *testing.T) {
	// Create temporary test directory
	tmpDir, err := ioutil.TempDir("", "inventory_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create test files
	testFiles := []string{
		"README.md",
		"docs/api.md",
		"docs/guide.txt",
		".github/CONTRIBUTING.md",
		"src/main.go",               // Should be ignored
		"node_modules/package.json", // Should be ignored
	}

	for _, file := range testFiles {
		fullPath := filepath.Join(tmpDir, file)
		dir := filepath.Dir(fullPath)
		if err := os.MkdirAll(dir, 0755); err != nil {
			t.Fatalf("Failed to create dir %s: %v", dir, err)
		}
		if err := ioutil.WriteFile(fullPath, []byte("test content"), 0644); err != nil {
			t.Fatalf("Failed to create file %s: %v", fullPath, err)
		}
	}

	// Generate inventory
	report, err := generateInventory(tmpDir)
	if err != nil {
		t.Fatalf("Failed to generate inventory: %v", err)
	}

	// Validate results
	if report.TotalFiles == 0 {
		t.Error("Expected to find some documentation files")
	}

	// Should find markdown and text files, but not Go files or node_modules
	expectedFiles := 4 // README.md, docs/api.md, docs/guide.txt, .github/CONTRIBUTING.md
	if report.TotalFiles != expectedFiles {
		t.Errorf("Expected %d files, got %d", expectedFiles, report.TotalFiles)
	}

	// Check categories
	if _, ok := report.Categories["root"]; !ok {
		t.Error("Expected 'root' category")
	}
	if _, ok := report.Categories["documentation"]; !ok {
		t.Error("Expected 'documentation' category")
	}
	if _, ok := report.Categories["github"]; !ok {
		t.Error("Expected 'github' category")
	}

	// Check extensions
	if _, ok := report.Extensions[".md"]; !ok {
		t.Error("Expected '.md' extension")
	}
	if _, ok := report.Extensions[".txt"]; !ok {
		t.Error("Expected '.txt' extension")
	}

	// Validate summary
	if report.Summary == "" {
		t.Error("Expected non-empty summary")
	}

	// Validate timestamp
	if time.Since(report.GeneratedAt) > time.Minute {
		t.Error("Report timestamp seems incorrect")
	}
}

func TestIsDocumentationFile(t *testing.T) {
	tests := []struct {
		path     string
		name     string
		expected bool
	}{
		{"README.md", "README.md", true},
		{"docs/api.md", "api.md", true},
		{"CHANGELOG", "CHANGELOG", true},
		{"src/main.go", "main.go", false},
		{"docs/guide.txt", "guide.txt", true},
		{".github/README.md", "README.md", true},
		{"node_modules/package.json", "package.json", false},
	}

	for _, test := range tests {
		result := isDocumentationFile(test.path, test.name)
		if result != test.expected {
			t.Errorf("isDocumentationFile(%s, %s) = %v, expected %v",
				test.path, test.name, result, test.expected)
		}
	}
}

func TestShouldSkipPath(t *testing.T) {
	tests := []struct {
		path     string
		expected bool
	}{
		{"README.md", false},
		{"docs/api.md", false},
		{"node_modules/package.json", true},
		{".git/config", true},
		{"vendor/deps", true},
		{"build/output", true},
		{"backup/old", true},
	}

	for _, test := range tests {
		result := shouldSkipPath(test.path)
		if result != test.expected {
			t.Errorf("shouldSkipPath(%s) = %v, expected %v",
				test.path, result, test.expected)
		}
	}
}

func TestCategorizeFile(t *testing.T) {
	tests := []struct {
		path     string
		name     string
		expected string
	}{
		{"README.md", "README.md", "root"},
		{"docs/api.md", "api.md", "documentation"},
		{".github/README.md", "README.md", "github"},
		{"development/guide.md", "guide.md", "development"},
		{"projet/roadmap.md", "roadmap.md", "project-management"},
		{"src/api/docs.md", "docs.md", "api"},
		{"tests/README.md", "README.md", "testing"},
	}

	for _, test := range tests {
		result := categorizeFile(test.path, test.name)
		if result != test.expected {
			t.Errorf("categorizeFile(%s, %s) = %s, expected %s",
				test.path, test.name, result, test.expected)
		}
	}
}

func TestExtractTags(t *testing.T) {
	tests := []struct {
		path     string
		name     string
		expected []string
	}{
		{"roadmap/plan.md", "plan.md", []string{"roadmap", "plan"}},
		{"README.md", "README.md", []string{"readme"}},
		{"CHANGELOG.md", "CHANGELOG.md", []string{"changelog"}},
		{"docs/spec.md", "spec.md", []string{"specification"}},
		{"guides/tutorial.md", "tutorial.md", []string{"guide", "tutorial"}},
	}

	for _, test := range tests {
		result := extractTags(test.path, test.name)

		// Check if all expected tags are present
		for _, expectedTag := range test.expected {
			found := false
			for _, tag := range result {
				if tag == expectedTag {
					found = true
					break
				}
			}
			if !found {
				t.Errorf("extractTags(%s, %s) missing expected tag: %s",
					test.path, test.name, expectedTag)
			}
		}
	}
}

func TestGetFileType(t *testing.T) {
	tests := []struct {
		ext      string
		expected string
	}{
		{".md", "markdown"},
		{".txt", "text"},
		{".rst", "restructuredtext"},
		{".adoc", "asciidoc"},
		{".org", "org-mode"},
		{".xyz", "other"},
	}

	for _, test := range tests {
		result := getFileType(test.ext)
		if result != test.expected {
			t.Errorf("getFileType(%s) = %s, expected %s",
				test.ext, result, test.expected)
		}
	}
}

func TestJSONOutput(t *testing.T) {
	// Create a minimal test report
	report := &InventoryReport{
		GeneratedAt: time.Now(),
		TotalFiles:  1,
		TotalSize:   100,
		Categories:  map[string]int{"test": 1},
		Extensions:  map[string]int{".md": 1},
		Files: []DocumentFile{
			{
				Path:         "test.md",
				Name:         "test.md",
				Extension:    ".md",
				Size:         100,
				LastModified: time.Now(),
				Type:         "markdown",
				Category:     "test",
				Tags:         []string{"test"},
				Metadata:     map[string]string{"depth": "0"},
			},
		},
		Summary: "Test summary",
	}

	// Test JSON encoding
	data, err := json.Marshal(report)
	if err != nil {
		t.Fatalf("Failed to marshal JSON: %v", err)
	}

	// Test JSON decoding
	var decoded InventoryReport
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal JSON: %v", err)
	}

	// Validate key fields
	if decoded.TotalFiles != report.TotalFiles {
		t.Errorf("TotalFiles mismatch: got %d, expected %d",
			decoded.TotalFiles, report.TotalFiles)
	}
	if decoded.Summary != report.Summary {
		t.Errorf("Summary mismatch: got %s, expected %s",
			decoded.Summary, report.Summary)
	}
}
