// Tests unitaires pour le package gapanalyzer.
package gapanalyzer

import (
	"os"
	"testing"
)

func TestAnalyzeGaps(t *testing.T) {
	jsonData := `[{"name":"foo.go","lang":"Go"},{"name":"bar.txt","lang":"unknown"}]`
	tmpFile, err := os.CreateTemp("", "modules-*.json")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.WriteString(jsonData)
	tmpFile.Close()

	gaps, err := AnalyzeGaps(tmpFile.Name())
	if err != nil {
		t.Fatalf("AnalyzeGaps erreur: %v", err)
	}
	if len(gaps) != 1 {
		t.Errorf("AnalyzeGaps retourne %d gaps; attendu 1", len(gaps))
	}
	if gaps[0].Module != "bar.txt" {
		t.Errorf("Nom du module inattendu: %s", gaps[0].Module)
	}
}

func TestExportMarkdown(t *testing.T) {
	gaps := []Gap{
		{Module: "bar.txt", Ecart: "Langage non détecté", Risque: "Non analysé", Recommandation: "Compléter manuellement"},
	}
	tmpFile, err := os.CreateTemp("", "gaps-*.md")
	if err != nil {
		t.Fatalf("Erreur création fichier temporaire: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	err = ExportMarkdown(gaps, tmpFile.Name())
	if err != nil {
		t.Fatalf("ExportMarkdown erreur: %v", err)
	}
	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("Erreur lecture fichier markdown: %v", err)
	}
	if string(data) == "" {
		t.Error("Le fichier markdown généré est vide")
	}
}
