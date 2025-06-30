package reporting

import (
	"encoding/json"
	"fmt"
	"os"

	"email_sender/core/gapanalyzer" // Import the gapanalyzer package
)

// ReportData représente la structure des données pour le rapport global.
type ReportData struct {
	GapAnalysis   *gapanalyzer.GapAnalysisResult `json:"gap_analysis"`
	Needs         []Need                         `json:"needs"`
	Specs         []Specification                `json:"specs"`
	OverallStatus string                         `json:"overall_status"`
	Summary       string                         `json:"summary"`
}

// GenerateGlobalReport génère un rapport global consolidé.
func GenerateGlobalReport(gapAnalysisPath, needsPath, specsPath, outputPathJSON, outputPathMD string) error {
	fmt.Printf("Génération du rapport global...\n")

	var gapAnalysisResult gapanalyzer.GapAnalysisResult
	var needs []Need
	var specs []Specification

	// Lire le rapport d'analyse d'écart
	if gapAnalysisPath != "" {
		gapBytes, err := os.ReadFile(gapAnalysisPath)
		if err != nil {
			return fmt.Errorf("erreur lors de la lecture du rapport d'analyse d'écart: %w", err)
		}
		err = json.Unmarshal(gapBytes, &gapAnalysisResult)
		if err != nil {
			return fmt.Errorf("erreur lors du décode du JSON d'analyse d'écart: %w", err)
		}
	}

	// Lire le rapport des besoins
	if needsPath != "" {
		needsBytes, err := os.ReadFile(needsPath)
		if err != nil {
			return fmt.Errorf("erreur lors de la lecture du rapport des besoins: %w", err)
		}
		err = json.Unmarshal(needsBytes, &needs)
		if err != nil {
			return fmt.Errorf("erreur lors du décode du JSON des besoins: %w", err)
		}
	}

	// Lire le rapport des spécifications
	if specsPath != "" {
		specsBytes, err := os.ReadFile(specsPath)
		if err != nil {
			return fmt.Errorf("erreur lors de la lecture du rapport des spécifications: %w", err)
		}
		err = json.Unmarshal(specsBytes, &specs)
		if err != nil {
			return fmt.Errorf("erreur lors du décode du JSON des spécifications: %w", err)
		}
	}

	// Déterminer le statut global et le résumé
	overallStatus := "SUCCESS"
	summary := "Tous les rapports ont été générés et analysés avec succès."

	if gapAnalysisResult.GapFound {
		overallStatus = "WARNING"
		summary = "Des écarts ont été détectés dans l'analyse des modules Go."
	}
	// Vous pouvez ajouter d'autres logiques de détermination du statut global ici
	// en fonction des besoins et des spécifications.

	reportData := ReportData{
		GapAnalysis:   &gapAnalysisResult,
		Needs:         needs,
		Specs:         specs,
		OverallStatus: overallStatus,
		Summary:       summary,
	}

	// Générer le rapport JSON
	jsonBytes, err := json.MarshalIndent(reportData, "", "  ")
	if err != nil {
		return fmt.Errorf("erreur lors de la sérialisation du rapport global JSON: %w", err)
	}
	err = os.WriteFile(outputPathJSON, jsonBytes, 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du fichier JSON du rapport global: %w", err)
	}
	fmt.Printf("Rapport global JSON généré : %s\n", outputPathJSON)

	// Générer le rapport Markdown
	markdownContent := "# Rapport Global du Projet\n\n"
	markdownContent += fmt.Sprintf("## Statut Général : %s\n\n", reportData.OverallStatus)
	markdownContent += fmt.Sprintf("### Résumé : %s\n\n", reportData.Summary)

	if reportData.GapAnalysis != nil {
		markdownContent += "## Rapport d'Analyse d'Écart des Modules Go :\n"
		markdownContent += fmt.Sprintf("- Écarts détectés: %t\n", reportData.GapAnalysis.GapFound)
		if reportData.GapAnalysis.GapFound {
			if len(reportData.GapAnalysis.MissingModules) > 0 {
				markdownContent += "  - Modules Manquants: " + fmt.Sprintf("%v", reportData.GapAnalysis.MissingModules) + "\n"
			}
			if len(reportData.GapAnalysis.ExtraModules) > 0 {
				markdownContent += "  - Modules Supplémentaires: " + fmt.Sprintf("%v", reportData.GapAnalysis.ExtraModules) + "\n"
			}
		}
		markdownContent += "\n"
	}

	if len(reportData.Needs) > 0 {
		markdownContent += "## Rapports des Besoins :\n"
		for _, need := range reportData.Needs {
			markdownContent += fmt.Sprintf("- **%s**: %s (Statut: %s, Priorité: %s)\n", need.ID, need.Description, need.Status, need.Priority)
		}
		markdownContent += "\n"
	}

	if len(reportData.Specs) > 0 {
		markdownContent += "## Rapports des Spécifications :\n"
		for _, spec := range reportData.Specs {
			markdownContent += fmt.Sprintf("- **%s**: %s (Statut: %s, Complétude: %s)\n", spec.ID, spec.Description, spec.Status, spec.Completeness)
		}
		markdownContent += "\n"
	}

	err = os.WriteFile(outputPathMD, []byte(markdownContent), 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du fichier Markdown du rapport global: %w", err)
	}
	fmt.Printf("Rapport global Markdown généré : %s\n", outputPathMD)

	return nil
}

// Pas de fonction main ici car ce fichier sera appelé par l'orchestrateur.
