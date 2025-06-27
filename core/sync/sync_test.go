// Tests unitaires pour le package sync.
package sync

import (
	"os"
	"testing"
)

func TestScanSync(t *testing.T) {
	tmpDir := t.TempDir()
	os.WriteFile(tmpDir+"/a.txt", []byte("abc"), 0644)
	os.WriteFile(tmpDir+"/b.go", []byte(""), 0644)

	results, err := ScanSync(tmpDir)
	if err != nil {
		t.Fatalf("ScanSync erreur: %v", err)
	}
	if len(results) != 2 {
		t.Errorf("ScanSync retourne %d résultats; attendu 2", len(results))
	}
	if results[1].Status != "À synchroniser" && results[0].Status != "À synchroniser" {
		t.Error("ScanSync devrait détecter un fichier à synchroniser")
	}
}

func TestExportSyncJSON(t *testing.T) {
	results := []SyncResult{
		{File: "a.txt", Status: "À jour", SyncGroup: "default"},
	}
	tmpFile, err := os.CreateTemp("", "sync-*.json")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	err = ExportSyncJSON(results, tmpFile.Name())
	if err != nil {
		t.Fatalf("ExportSyncJSON erreur: %v", err)
	}
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur lecture fichier JSON: %v", err)
	}
	if string(data) == "" {
		t.Error("Le fichier JSON généré est vide")
	}
}

func TestExportSyncGapAnalysis(t *testing.T) {
	results := []SyncResult{
		{File: "a.txt", Status: "À jour", SyncGroup: "default"},
	}
	tmpFile, err := os.CreateTemp("", "gap-*.md")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	err = ExportSyncGapAnalysis(results, tmpFile.Name())
	if err != nil {
		t.Fatalf("ExportSyncGapAnalysis erreur: %v", err)
	}
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur lecture fichier markdown: %v", err)
	}
	if string(data) == "" {
		t.Error("Le fichier markdown généré est vide")
	}
}
