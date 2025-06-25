package gapanalyzer

import (
	"encoding/json"
	"os"
	"testing"
)

func TestAnalyzeGaps(t *testing.T) {
	// Crée un fichier temporaire de scan JSON avec un module inconnu
	tmpFile, err := os.CreateTemp("", "scanmodules-*.json")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	modules := []map[string]interface{}{
		{"name": "test.unknown", "lang": "unknown"},
		{"name": "main.go", "lang": "Go"},
	}
	data, _ := json.Marshal(modules)
	tmpFile.Write(data)
	tmpFile.Close()

	gaps, err := AnalyzeGaps(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur AnalyzeGaps: %v", err)
	}
	if len(gaps) != 1 {
		t.Errorf("Attendu 1 gap, obtenu %d", len(gaps))
	}
	if gaps[0].Module != "test.unknown" {
		t.Errorf("Nom de module incorrect: %s", gaps[0].Module)
	}
}
