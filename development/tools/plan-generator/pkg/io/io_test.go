package io

import (
	"os"
	"testing"

	"plan-generator/pkg/models"
)

func TestExportPlanToJSON(t *testing.T) {
	// Créer un plan fictif pour le test
	plan := &models.Plan{
		Version:     "v1",
		Title:       "Test Plan",
		Description: "Description de test",
		PhaseCount:  3,
		PhaseDetails: map[string]interface{}{
			"Phase1": "Details1",
			"Phase2": "Details2",
		},
	}

	// Répertoire temporaire pour le test
	tempDir := os.TempDir()
	outputDir := tempDir + "/plan-generator-test"
	os.MkdirAll(outputDir, 0755)
	defer os.RemoveAll(outputDir) // Nettoyer après le test

	// Appeler la fonction ExportPlanToJSON
	outputPath, err := ExportPlanToJSON(plan, outputDir, plan.Version, plan.Title)
	if err != nil {
		t.Fatalf("Erreur lors de l'export JSON: %v", err)
	}

	// Vérifier que le fichier a été créé
	if _, err := os.Stat(outputPath); os.IsNotExist(err) {
		t.Fatalf("Le fichier JSON n'a pas été créé: %s", outputPath)
	}

	// Vérifier le contenu du fichier
	content, err := os.ReadFile(outputPath)
	if err != nil {
		t.Fatalf("Erreur lors de la lecture du fichier JSON: %v", err)
	}

	if len(content) == 0 {
		t.Fatalf("Le fichier JSON est vide: %s", outputPath)
	}
}
