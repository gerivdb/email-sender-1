// Tests unitaires pour le package graphgen.
package graphgen

import (
	"os"
	"testing"
)

func TestScanGraph(t *testing.T) {
	tmpDir := t.TempDir()
	os.WriteFile(tmpDir+"/a.go", []byte("abc"), 0644)
	os.WriteFile(tmpDir+"/b.js", []byte("def"), 0644)

	nodes, err := ScanGraph(tmpDir)
	if err != nil {
		t.Fatalf("ScanGraph erreur: %v", err)
	}
	if len(nodes) != 2 {
		t.Errorf("ScanGraph retourne %d noeuds; attendu 2", len(nodes))
	}
}

func TestExportGraphJSON(t *testing.T) {
	nodes := []Node{
		{Name: "a.go", Type: ".go", Links: []string{}},
	}
	tmpFile, err := os.CreateTemp("", "graph-*.json")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	err = ExportGraphJSON(nodes, tmpFile.Name())
	if err != nil {
		t.Fatalf("ExportGraphJSON erreur: %v", err)
	}
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur lecture fichier JSON: %v", err)
	}
	if string(data) == "" {
		t.Error("Le fichier JSON généré est vide")
	}
}

func TestExportGraphGapAnalysis(t *testing.T) {
	nodes := []Node{
		{Name: "a.go", Type: ".go", Links: []string{}},
	}
	tmpFile, err := os.CreateTemp("", "gap-*.md")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	err = ExportGraphGapAnalysis(nodes, tmpFile.Name())
	if err != nil {
		t.Fatalf("ExportGraphGapAnalysis erreur: %v", err)
	}
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur lecture fichier markdown: %v", err)
	}
	if string(data) == "" {
		t.Error("Le fichier markdown généré est vide")
	}
}
