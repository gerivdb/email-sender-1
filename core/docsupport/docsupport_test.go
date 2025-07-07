// Tests unitaires pour le package docsupport.
package docsupport

import (
	"os"
	"testing"
)

func TestScanDocSupports(t *testing.T) {
	tmpDir := t.TempDir()
	os.WriteFile(tmpDir+"/a.md", []byte("doc"), 0644)
	os.WriteFile(tmpDir+"/b.pdf", []byte("pdf"), 0644)
	os.WriteFile(tmpDir+"/c.txt", []byte("txt"), 0644)

	docs, err := ScanDocSupports(tmpDir)
	if err != nil {
		t.Fatalf("ScanDocSupports erreur: %v", err)
	}
	if len(docs) != 3 {
		t.Errorf("ScanDocSupports retourne %d résultats; attendu 3", len(docs))
	}
}

func TestExportDocSupportsJSON(t *testing.T) {
	docs := []DocSupport{
		{File: "a.md", Type: "markdown", Size: 3, Coverage: "présent"},
	}
	tmpFile, err := os.CreateTemp("", "doc-*.json")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	err = ExportDocSupportsJSON(docs, tmpFile.Name())
	if err != nil {
		t.Fatalf("ExportDocSupportsJSON erreur: %v", err)
	}
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur lecture fichier JSON: %v", err)
	}
	if string(data) == "" {
		t.Error("Le fichier JSON généré est vide")
	}
}

func TestExportDocGapAnalysis(t *testing.T) {
	docs := []DocSupport{
		{File: "a.md", Type: "markdown", Size: 3, Coverage: "présent"},
	}
	tmpFile, err := os.CreateTemp("", "gap-*.md")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	err = ExportDocGapAnalysis(docs, tmpFile.Name())
	if err != nil {
		t.Fatalf("ExportDocGapAnalysis erreur: %v", err)
	}
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur lecture fichier markdown: %v", err)
	}
	if string(data) == "" {
		t.Error("Le fichier markdown généré est vide")
	}
}
