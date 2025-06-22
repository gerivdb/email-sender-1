package tools

import (
	"os"
	"strings"
	"testing"
)

func TestAGENTSMDGeneration(t *testing.T) {
	main() // Exécute le script principal

	data, err := os.ReadFile("../AGENTS.md")
	if err != nil {
		t.Fatalf("AGENTS.md non généré: %v", err)
	}
	content := string(data)

	if !strings.Contains(content, "# AGENTS.md") {
		t.Error("Titre principal manquant")
	}
	if !strings.Contains(content, "## Documentation générée automatiquement") {
		t.Error("Section d’intro manquante")
	}
	if !strings.Contains(content, "Package") {
		t.Error("Aucune section de package détectée")
	}
}
