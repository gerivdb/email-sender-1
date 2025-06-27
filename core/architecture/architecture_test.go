// Tests unitaires pour le package architecture.
package architecture

import (
	"os"
	"testing"
)

func TestScanPatterns(t *testing.T) {
	tmpDir := t.TempDir()
	os.WriteFile(tmpDir+"/a.go", []byte("test"), 0644)
	os.WriteFile(tmpDir+"/b.js", []byte("test"), 0644)

	patterns, err := ScanPatterns(tmpDir)
	if err != nil {
		t.Fatalf("ScanPatterns erreur: %v", err)
	}
	if len(patterns) == 0 {
		t.Error("ScanPatterns retourne 0 pattern; attendu au moins 1")
	}
	if len(patterns[0].Files) != 2 {
		t.Errorf("ScanPatterns retourne %d fichiers; attendu 2", len(patterns[0].Files))
	}
}

func TestExportPatternsJSON(t *testing.T) {
	patterns := []Pattern{
		{Name: "TestPattern", Files: []string{"a.go"}, Description: "desc"},
	}
	tmpFile, err := os.CreateTemp("", "patterns-*.json")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	err = ExportPatternsJSON(patterns, tmpFile.Name())
	if err != nil {
		t.Fatalf("ExportPatternsJSON erreur: %v", err)
	}
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur lecture fichier JSON: %v", err)
	}
	if string(data) == "" {
		t.Error("Le fichier JSON généré est vide")
	}
}

func TestExportGapAnalysis(t *testing.T) {
	patterns := []Pattern{
		{Name: "TestPattern", Files: []string{"a.go"}, Description: "desc"},
	}
	tmpFile, err := os.CreateTemp("", "gap-*.md")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	err = ExportGapAnalysis(patterns, tmpFile.Name())
	if err != nil {
		t.Fatalf("ExportGapAnalysis erreur: %v", err)
	}
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur lecture fichier markdown: %v", err)
	}
	if string(data) == "" {
		t.Error("Le fichier markdown généré est vide")
	}
}
