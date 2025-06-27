// Tests unitaires pour le package scanmodules.
package scanmodules

import (
	"os"
	"path/filepath"
	"testing"
)

// Test de la fonction DetectLang.
func TestDetectLang(t *testing.T) {
	tests := []struct {
		filename string
		expected string
	}{
		{"main.go", "Go"},
		{"script.js", "Node.js"},
		{"module.py", "Python"},
		{"README.md", "unknown"},
	}

	for _, tt := range tests {
		result := DetectLang(tt.filename)
		if result != tt.expected {
			t.Errorf("DetectLang(%q) = %q; want %q", tt.filename, result, tt.expected)
		}
	}
}

// Test de la fonction ScanDir sur un dossier temporaire.
func TestScanDir(t *testing.T) {
	tmpDir := t.TempDir()
	files := []string{"a.go", "b.js", "c.py", "d.txt"}
	for _, f := range files {
		os.WriteFile(filepath.Join(tmpDir, f), []byte("test"), 0644)
	}

	modules, err := ScanDir(tmpDir)
	if err != nil {
		t.Fatalf("ScanDir error: %v", err)
	}
	if len(modules) != len(files) {
		t.Errorf("ScanDir found %d modules; want %d", len(modules), len(files))
	}
}
