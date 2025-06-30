package gapanalyzer

import (
	"fmt"
	"os"
)

// AnalyzeExtractionParsingGap simule l'analyse des écarts pour l'extraction et le parsing.
func AnalyzeExtractionParsingGap(extractedData map[string]interface{}) (map[string]interface{}, error) {
	fmt.Printf("Analyse des écarts pour l'extraction et le parsing...\n")

	// Simuler une logique d'analyse d'écart
	// Par exemple, vérifier si certaines clés sont présentes ou si les valeurs sont conformes
	gapFound := false
	gapDetails := make(map[string]interface{})

	if extractedData == nil || len(extractedData) == 0 {
		gapFound = true
		gapDetails["data_missing"] = "Aucune donnée d'extraction fournie ou les données sont vides."
	} else {
		if _, ok := extractedData["status"]; !ok {
			gapFound = true
			gapDetails["status_missing"] = "La clé 'status' est manquante dans les données extraites."
		}
		if status, ok := extractedData["status"].(string); ok && status != "success" {
			gapFound = true
			gapDetails["status_not_success"] = fmt.Sprintf("Le statut d'extraction n'est pas 'success', mais '%s'.", status)
		}
	}

	result := map[string]interface{}{
		"gap_found":   gapFound,
		"gap_details": gapDetails,
		"timestamp":   "2025-06-29T22:00:00Z", // Placeholder
	}

	return result, nil
}

// GenerateExtractionParsingGapAnalysis simule la génération du fichier EXTRACTION_PARSING_GAP_ANALYSIS.md
func GenerateExtractionParsingGapAnalysis(outputPath string, analysisResult map[string]interface{}) error {
	fmt.Printf("Génération du rapport d'analyse des écarts d'extraction/parsing : %s\n", outputPath)

	content := fmt.Sprintf("# Rapport d'Analyse des Écarts - Extraction et Parsing\n\n")
	content += fmt.Sprintf("Date d'analyse : %v\n\n", analysisResult["timestamp"])
	content += fmt.Sprintf("Écarts détectés : %v\n\n", analysisResult["gap_found"])

	if analysisResult["gap_found"].(bool) {
		content += "## Détails des Écarts :\n"
		if details, ok := analysisResult["gap_details"].(map[string]interface{}); ok {
			for k, v := range details {
				content += fmt.Sprintf("- %s: %v\n", k, v)
			}
		}
	} else {
		content += "Aucun écart majeur détecté lors de l'analyse de l'extraction et du parsing.\n"
	}

	err := os.WriteFile(outputPath, []byte(content), 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du fichier d'analyse des écarts : %w", err)
	}
	return nil
}

// AnalyzeGraphGenerationGap simule l'analyse des écarts pour la génération de graphes.
func AnalyzeGraphGenerationGap(graphData map[string]interface{}) (map[string]interface{}, error) {
	fmt.Printf("Analyse des écarts pour la génération de graphes...\n")

	gapFound := false
	gapDetails := make(map[string]interface{})

	if graphData == nil || len(graphData) == 0 {
		gapFound = true
		gapDetails["graph_data_missing"] = "Aucune donnée de graphe fournie ou les données sont vides."
	} else {
		// Exemple de vérification : s'assurer qu'il y a des nœuds et des arêtes
		nodes, nodesOk := graphData["nodes"].([]map[string]string)
		edges, edgesOk := graphData["edges"].([]map[string]string)

		if !nodesOk || len(nodes) == 0 {
			gapFound = true
			gapDetails["no_nodes"] = "Aucun nœud n'a été généré dans le graphe."
		}
		if !edgesOk || len(edges) == 0 {
			gapFound = true
			gapDetails["no_edges"] = "Aucune arête n'a été générée dans le graphe."
		}
		// Ajoutez d'autres logiques de validation ici, par exemple, la cohérence des ID, la présence de métadonnées, etc.
	}

	result := map[string]interface{}{
		"gap_found":   gapFound,
		"gap_details": gapDetails,
		"timestamp":   "2025-06-30T00:00:00Z", // Placeholder
	}

	return result, nil
}

// GenerateGraphGenerationGapAnalysis simule la génération du fichier GRAPHGEN_GAP_ANALYSIS.md.
func GenerateGraphGenerationGapAnalysis(outputPath string, analysisResult map[string]interface{}) error {
	fmt.Printf("Génération du rapport d'analyse des écarts de génération de graphes : %s\n", outputPath)

	content := fmt.Sprintf("# Rapport d'Analyse des Écarts - Génération de Graphes\n\n")
	content += fmt.Sprintf("Date d'analyse : %v\n\n", analysisResult["timestamp"])
	content += fmt.Sprintf("Écarts détectés : %v\n\n", analysisResult["gap_found"])

	if analysisResult["gap_found"].(bool) {
		content += "## Détails des Écarts :\n"
		if details, ok := analysisResult["gap_details"].(map[string]interface{}); ok {
			for k, v := range details {
				content += fmt.Sprintf("- %s: %v\n", k, v)
			}
		}
	} else {
		content += "Aucun écart majeur détecté lors de l'analyse de la génération de graphes.\n"
	}

	err := os.WriteFile(outputPath, []byte(content), 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du fichier d'analyse des écarts de graphes : %w", err)
	}
	return nil
}
