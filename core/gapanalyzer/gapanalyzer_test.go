package gapanalyzer

import (
	"os"
	"path/filepath"
	"testing"
)

func TestAnalyzeExtractionParsingGap(t *testing.T) {
	// Cas 1 : Données valides (pas d'écart attendu)
	validData := map[string]interface{}{
		"status":  "success",
		"message": "Données extraites",
	}
	result, err := AnalyzeExtractionParsingGap(validData)
	if err != nil {
		t.Errorf("AnalyzeExtractionParsingGap a échoué pour des données valides : %v", err)
	}
	if result["gap_found"].(bool) != false {
		t.Errorf("Écart inattendu détecté pour des données valides. Résultat : %v", result)
	}

	// Cas 2 : Données manquantes (écart attendu)
	emptyData := map[string]interface{}{}
	result, err = AnalyzeExtractionParsingGap(emptyData)
	if err != nil {
		t.Errorf("AnalyzeExtractionParsingGap a échoué pour des données vides : %v", err)
	}
	if result["gap_found"].(bool) != true {
		t.Error("Aucun écart détecté pour des données vides, mais un écart était attendu.")
	}
	if _, ok := result["gap_details"].(map[string]interface{})["data_missing"]; !ok {
		t.Error("La clé 'data_missing' est manquante dans les détails de l'écart pour des données vides.")
	}

	// Cas 3 : Statut non 'success' (écart attendu)
	failedData := map[string]interface{}{
		"status":  "failed",
		"message": "Erreur d'extraction",
	}
	result, err = AnalyzeExtractionParsingGap(failedData)
	if err != nil {
		t.Errorf("AnalyzeExtractionParsingGap a échoué pour un statut 'failed' : %v", err)
	}
	if result["gap_found"].(bool) != true {
		t.Error("Aucun écart détecté pour un statut 'failed', mais un écart était attendu.")
	}
	if _, ok := result["gap_details"].(map[string]interface{})["status_not_success"]; !ok {
		t.Error("La clé 'status_not_success' est manquante dans les détails de l'écart pour un statut 'failed'.")
	}

	// Cas 4 : Statut manquant (écart attendu)
	noStatusData := map[string]interface{}{
		"message": "Juste un message",
	}
	result, err = AnalyzeExtractionParsingGap(noStatusData)
	if err != nil {
		t.Errorf("AnalyzeExtractionParsingGap a échoué pour un statut manquant : %v", err)
	}
	if result["gap_found"].(bool) != true {
		t.Error("Aucun écart détecté pour un statut manquant, mais un écart était attendu.")
	}
	if _, ok := result["gap_details"].(map[string]interface{})["status_missing"]; !ok {
		t.Error("La clé 'status_missing' est manquante dans les détails de l'écart pour un statut manquant.")
	}
}

func TestGenerateExtractionParsingGapAnalysis(t *testing.T) {
	tempDir := t.TempDir()
	outputPath := filepath.Join(tempDir, "EXTRACTION_PARSING_GAP_ANALYSIS.md")

	// Cas 1 : Aucun écart
	noGapResult := map[string]interface{}{
		"gap_found":   false,
		"timestamp":   "2025-06-29T22:00:00Z",
		"gap_details": map[string]interface{}{},
	}
	err := GenerateExtractionParsingGapAnalysis(outputPath, noGapResult)
	if err != nil {
		t.Errorf("GenerateExtractionParsingGapAnalysis a échoué pour aucun écart : %v", err)
	}
	content, _ := os.ReadFile(outputPath)
	if !containsSubstring(string(content), "Aucun écart majeur détecté") {
		t.Error("Le rapport ne contient pas le message 'Aucun écart majeur détecté' pour aucun écart.")
	}

	// Cas 2 : Écarts détectés
	gapResult := map[string]interface{}{
		"gap_found": true,
		"timestamp": "2025-06-29T22:00:00Z",
		"gap_details": map[string]interface{}{
			"data_missing":       "Données manquantes.",
			"status_not_success": "Statut non conforme.",
		},
	}
	err = GenerateExtractionParsingGapAnalysis(outputPath, gapResult)
	if err != nil {
		t.Errorf("GenerateExtractionParsingGapAnalysis a échoué pour des écarts détectés : %v", err)
	}
	content, _ = os.ReadFile(outputPath)
	if !containsSubstring(string(content), "Détails des Écarts") || !containsSubstring(string(content), "Données manquantes.") {
		t.Error("Le rapport ne contient pas les détails des écarts attendus.")
	}
}

// Fonction utilitaire pour vérifier si une sous-chaîne est présente
func containsSubstring(s, substring string) bool {
	return len(s) >= len(substring) && s[0:len(substring)] == substring
}

func TestAnalyzeGraphGenerationGap(t *testing.T) {
	// Cas 1 : Données de graphe valides (pas d'écart attendu)
	validGraphData := map[string]interface{}{
		"nodes": []map[string]string{{"id": "n1"}},
		"edges": []map[string]string{{"source": "n1", "target": "n2"}},
	}
	result, err := AnalyzeGraphGenerationGap(validGraphData)
	if err != nil {
		t.Errorf("AnalyzeGraphGenerationGap a échoué pour des données valides : %v", err)
	}
	if result["gap_found"].(bool) != false {
		t.Errorf("Écart inattendu détecté pour des données de graphe valides. Résultat : %v", result)
	}

	// Cas 2 : Données de graphe manquantes (écart attendu)
	emptyGraphData := map[string]interface{}{}
	result, err = AnalyzeGraphGenerationGap(emptyGraphData)
	if err != nil {
		t.Errorf("AnalyzeGraphGenerationGap a échoué pour des données vides : %v", err)
	}
	if result["gap_found"].(bool) != true {
		t.Error("Aucun écart détecté pour des données vides, mais un écart était attendu.")
	}
	if _, ok := result["gap_details"].(map[string]interface{})["graph_data_missing"]; !ok {
		t.Error("La clé 'graph_data_missing' est manquante dans les détails de l'écart pour des données vides.")
	}

	// Cas 3 : Pas de nœuds (écart attendu)
	noNodesData := map[string]interface{}{
		"nodes": []map[string]string{},
		"edges": []map[string]string{{"source": "n1", "target": "n2"}},
	}
	result, err = AnalyzeGraphGenerationGap(noNodesData)
	if err != nil {
		t.Errorf("AnalyzeGraphGenerationGap a échoué pour des données sans nœuds : %v", err)
	}
	if result["gap_found"].(bool) != true {
		t.Error("Aucun écart détecté pour des données sans nœuds, mais un écart était attendu.")
	}
	if _, ok := result["gap_details"].(map[string]interface{})["no_nodes"]; !ok {
		t.Error("La clé 'no_nodes' est manquante dans les détails de l'écart pour des données sans nœuds.")
	}

	// Cas 4 : Pas d'arêtes (écart attendu)
	noEdgesData := map[string]interface{}{
		"nodes": []map[string]string{{"id": "n1"}},
		"edges": []map[string]string{},
	}
	result, err = AnalyzeGraphGenerationGap(noEdgesData)
	if err != nil {
		t.Errorf("AnalyzeGraphGenerationGap a échoué pour des données sans arêtes : %v", err)
	}
	if result["gap_found"].(bool) != true {
		t.Error("Aucun écart détecté pour des données sans arêtes, mais un écart était attendu.")
	}
	if _, ok := result["gap_details"].(map[string]interface{})["no_edges"]; !ok {
		t.Error("La clé 'no_edges' est manquante dans les détails de l'écart pour des données sans arêtes.")
	}
}

func TestGenerateGraphGenerationGapAnalysis(t *testing.T) {
	tempDir := t.TempDir()
	outputPath := filepath.Join(tempDir, "GRAPHGEN_GAP_ANALYSIS.md")

	// Cas 1 : Aucun écart
	noGapResult := map[string]interface{}{
		"gap_found":   false,
		"timestamp":   "2025-06-30T00:00:00Z",
		"gap_details": map[string]interface{}{},
	}
	err := GenerateGraphGenerationGapAnalysis(outputPath, noGapResult)
	if err != nil {
		t.Errorf("GenerateGraphGenerationGapAnalysis a échoué pour aucun écart : %v", err)
	}
	content, _ := os.ReadFile(outputPath)
	if !containsSubstring(string(content), "Aucun écart majeur détecté") {
		t.Error("Le rapport ne contient pas le message 'Aucun écart majeur détecté' pour aucun écart.")
	}

	// Cas 2 : Écarts détectés
	gapResult := map[string]interface{}{
		"gap_found": true,
		"timestamp": "2025-06-30T00:00:00Z",
		"gap_details": map[string]interface{}{
			"no_nodes": "Aucun nœud.",
			"no_edges": "Aucune arête.",
		},
	}
	err = GenerateGraphGenerationGapAnalysis(outputPath, gapResult)
	if err != nil {
		t.Errorf("GenerateGraphGenerationGapAnalysis a échoué pour des écarts détectés : %v", err)
	}
	content, _ = os.ReadFile(outputPath)
	if !containsSubstring(string(content), "Détails des Écarts") || !containsSubstring(string(content), "Aucun nœud.") {
		t.Error("Le rapport ne contient pas les détails des écarts attendus.")
	}
}
