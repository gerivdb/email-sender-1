// Tests unitaires pour le package extraction.
package extraction

import (
	"os"
	"testing"
)

func TestScanExtraction(t *testing.T) {
	tmpDir := t.TempDir()
	os.WriteFile(tmpDir+"/a.txt", []byte("abc"), 0644)
	os.WriteFile(tmpDir+"/b.go", []byte(""), 0644)

	results, err := ScanExtraction(tmpDir)
	if err != nil {
		t.Fatalf("ScanExtraction erreur: %v", err)
	}
	if len(results) != 2 {
		t.Errorf("ScanExtraction retourne %d résultats; attendu 2", len(results))
	}
	if results[1].ParseStatus != "Vide" && results[0].ParseStatus != "Vide" {
		t.Error("ScanExtraction devrait détecter un fichier vide")
	}
}

func TestExportExtractionJSON(t *testing.T) {
	results := []ExtractionResult{
		{File: "a.txt", Type: ".txt", Size: 3, ParseStatus: "OK"},
	}
	tmpFile, err := os.CreateTemp("", "extract-*.json")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	err = ExportExtractionJSON(results, tmpFile.Name())
	if err != nil {
		t.Fatalf("ExportExtractionJSON erreur: %v", err)
	}
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur lecture fichier JSON: %v", err)
	}
	if string(data) == "" {
		t.Error("Le fichier JSON généré est vide")
	}
}

func TestExportExtractionGapAnalysis(t *testing.T) {
	results := []ExtractionResult{
		{File: "a.txt", Type: ".txt", Size: 3, ParseStatus: "OK"},
	}
	tmpFile, err := os.CreateTemp("", "gap-*.md")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	err = ExportExtractionGapAnalysis(results, tmpFile.Name())
	if err != nil {
		t.Fatalf("ExportExtractionGapAnalysis erreur: %v", err)
	}
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur lecture fichier markdown: %v", err)
	}
	if string(data) == "" {
		t.Error("Le fichier markdown généré est vide")
	}
}
