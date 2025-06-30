package gapanalyzer

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	// Ré-ajouter l'import strings
)

// GapAnalysisResult représente le résultat de l'analyse d'écart.
type GapAnalysisResult struct {
	GapFound        bool                   `json:"gap_found"`
	GapDetails      map[string]interface{} `json:"gap_details"`
	Timestamp       string                 `json:"timestamp"`
	ExistingModules []string               `json:"existing_modules"`
	ExpectedModules []string               `json:"expected_modules"`
	MissingModules  []string               `json:"missing_modules"`
	ExtraModules    []string               `json:"extra_modules"`
}

// AnalyzeGoModulesGap analyse les écarts entre les modules Go existants et attendus.
func AnalyzeGoModulesGap(existingModulesPath, expectedModulesPath string) (*GapAnalysisResult, error) {
	fmt.Printf("Analyse des écarts entre les modules Go existants et attendus...\n")

	// Lire les modules existants depuis le fichier JSON
	existingModulesBytes, err := ioutil.ReadFile(existingModulesPath)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la lecture des modules existants: %w", err)
	}
	var existingModules []string
	err = json.Unmarshal(existingModulesBytes, &existingModules)
	if err != nil {
		return nil, fmt.Errorf("erreur lors du décode des modules existants depuis JSON: %w", err)
	}

	var expectedModules []string
	if expectedModulesPath != "" {
		expectedModulesBytes, err := ioutil.ReadFile(expectedModulesPath)
		if err != nil {
			return nil, fmt.Errorf("erreur lors de la lecture des modules attendus: %w", err)
		}
		err = json.Unmarshal(expectedModulesBytes, &expectedModules)
		if err != nil {
			return nil, fmt.Errorf("erreur lors du décode des modules attendus depuis JSON: %w", err)
		}
	} else {
		// Valeurs par défaut pour les tests ou si le chemin n'est pas fourni
		expectedModules = []string{
			"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1",
			"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/core/scanmodules",
			"d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/core/gapanalyzer",
			// Ajoutez d'autres modules attendus ici pour les tests
		}
	}

	gapFound := false
	gapDetails := make(map[string]interface{})

	// Convertir les listes en maps pour une recherche plus rapide
	existingMap := make(map[string]bool)
	for _, module := range existingModules {
		existingMap[module] = true
	}

	expectedMap := make(map[string]bool)
	for _, module := range expectedModules {
		expectedMap[module] = true
	}

	var missingModules []string
	for _, expected := range expectedModules {
		if !existingMap[expected] {
			missingModules = append(missingModules, expected)
			gapFound = true
		}
	}

	var extraModules []string
	for _, existing := range existingModules {
		if !expectedMap[existing] {
			extraModules = append(extraModules, existing)
			gapFound = true
		}
	}

	if gapFound {
		if len(missingModules) > 0 {
			gapDetails["missing_modules"] = missingModules
		}
		if len(extraModules) > 0 {
			gapDetails["extra_modules"] = extraModules
		}
	} else {
		gapDetails["status"] = "Aucun écart détecté entre les modules existants et attendus."
	}

	result := &GapAnalysisResult{
		GapFound:        gapFound,
		GapDetails:      gapDetails,
		Timestamp:       "2025-06-30T00:00:00Z", // Utiliser un horodatage réel en production
		ExistingModules: existingModules,
		ExpectedModules: expectedModules,
		MissingModules:  missingModules,
		ExtraModules:    extraModules,
	}

	return result, nil
}

// GenerateGapAnalysisReport génère le rapport d'analyse d'écart au format JSON et Markdown.
func GenerateGapAnalysisReport(outputPathJSON, outputPathMD string, analysisResult *GapAnalysisResult) error {
	fmt.Printf("Génération du rapport d'analyse des écarts...\n")

	// Générer le rapport JSON
	jsonBytes, err := json.MarshalIndent(analysisResult, "", "  ")
	if err != nil {
		return fmt.Errorf("erreur lors de la sérialisation du rapport JSON: %w", err)
	}
	err = ioutil.WriteFile(outputPathJSON, jsonBytes, 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du fichier JSON: %w", err)
	}
	fmt.Printf("Rapport JSON généré : %s\n", outputPathJSON)

	// Générer le rapport Markdown
	markdownContent := fmt.Sprintf("# Rapport d'Analyse d'Écart des Modules Go\n\n")
	markdownContent += fmt.Sprintf("Date d'analyse : %s\n", analysisResult.Timestamp)
	markdownContent += fmt.Sprintf("Écarts détectés : %t\n\n", analysisResult.GapFound)

	if analysisResult.GapFound {
		markdownContent += "## Détails des Écarts :\n"
		if len(analysisResult.MissingModules) > 0 {
			markdownContent += "### Modules Manquants (Attendus mais non trouvés) :\n"
			for _, module := range analysisResult.MissingModules {
				markdownContent += fmt.Sprintf("- %s\n", module)
			}
			markdownContent += "\n"
		}
		if len(analysisResult.ExtraModules) > 0 {
			markdownContent += "### Modules Supplémentaires (Trouvés mais non attendus) :\n"
			for _, module := range analysisResult.ExtraModules {
				markdownContent += fmt.Sprintf("- %s\n", module)
			}
			markdownContent += "\n"
		}
	} else {
		markdownContent += "Aucun écart détecté entre les modules Go existants et attendus.\n"
	}

	markdownContent += "## Modules Existants :\n"
	for _, module := range analysisResult.ExistingModules {
		markdownContent += fmt.Sprintf("- %s\n", module)
	}
	markdownContent += "\n"

	markdownContent += "## Modules Attendus :\n"
	for _, module := range analysisResult.ExpectedModules {
		markdownContent += fmt.Sprintf("- %s\n", module)
	}
	markdownContent += "\n"

	err = ioutil.WriteFile(outputPathMD, []byte(markdownContent), 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du fichier Markdown: %w", err)
	}
	fmt.Printf("Rapport Markdown généré : %s\n", outputPathMD)

	return nil
}

// Pour permettre l'exécution directe via `go run`, nous incluons une fonction main.
func main() {
	// Exemple d'utilisation :
	// Exécuter d'abord scanmodules.go pour générer modules.json
	// go run core/scanmodules/scanmodules.go

	// Puis exécuter gapanalyzer.go
	// go run core/gapanalyzer/gapanalyzer.go

	analysisResult, err := AnalyzeGoModulesGap("modules.json", "") // Le chemin attendu est simulé dans la fonction
	if err != nil {
		fmt.Printf("Erreur lors de l'analyse des écarts: %s\n", err)
		os.Exit(1)
	}

	err = GenerateGapAnalysisReport("gap-analysis-initial.json", "GAP_ANALYSIS_INIT.md", analysisResult)
	if err != nil {
		fmt.Printf("Erreur lors de la génération des rapports: %s\n", err)
		os.Exit(1)
	}
	fmt.Println("Analyse d'écart initiale terminée.")
}
