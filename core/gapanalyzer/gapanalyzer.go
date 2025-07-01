package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// ModuleInfo représente les informations d'un module (importé du scanner)
type ModuleInfo struct {
	Name         string    `json:"name"`
	Path         string    `json:"path"`
	Description  string    `json:"description"`
	LastModified time.Time `json:"last_modified"`
}

// RepositoryStructure représente la structure complète du dépôt (importé du scanner)
type RepositoryStructure struct {
	TreeOutput   string       `json:"tree_output"`
	Modules      []ModuleInfo `json:"modules"`
	TotalModules int          `json:"total_modules"`
	GeneratedAt  time.Time    `json:"generated_at"`
	RootPath     string       `json:"root_path"`
}

// ExpectedModule représente un module attendu
type ExpectedModule struct {
	Name        string `json:"name"`
	Path        string `json:"path"`
	Required    bool   `json:"required"`
	Category    string `json:"category"`
	Description string `json:"description"`
}

// GapAnalysis représente le résultat de l'analyse d'écart
type GapAnalysis struct {
	AnalysisDate    time.Time        `json:"analysis_date"`
	TotalExpected   int              `json:"total_expected"`
	TotalFound      int              `json:"total_found"`
	MissingModules  []ExpectedModule `json:"missing_modules"`
	ExtraModules    []ModuleInfo     `json:"extra_modules"`
	MatchingModules []ModuleInfo     `json:"matching_modules"`
	ComplianceRate  float64          `json:"compliance_rate"`
	Recommendations []string         `json:"recommendations"`
	Summary         string           `json:"summary"`
}

// getExpectedModules retourne la liste des modules attendus selon l'architecture du projet
func getExpectedModules() []ExpectedModule {
	return []ExpectedModule{
		// Modules core
		{
			Name:        "core/scanmodules",
			Path:        "core/scanmodules",
			Required:    true,
			Category:    "core",
			Description: "Scanner de modules et structure du dépôt",
		},
		{
			Name:        "core/gapanalyzer",
			Path:        "core/gapanalyzer",
			Required:    true,
			Category:    "core",
			Description: "Analyseur d'écarts entre modules attendus et existants",
		},
		{
			Name:        "core/reporting",
			Path:        "core/reporting",
			Required:    true,
			Category:    "core",
			Description: "Générateur de rapports automatisés",
		},

		// Modules cmd
		{
			Name:        "cmd/auto-roadmap-runner",
			Path:        "cmd/auto-roadmap-runner",
			Required:    true,
			Category:    "cmd",
			Description: "Orchestrateur global de la roadmap",
		},
		{
			Name:        "cmd/configcli",
			Path:        "cmd/configcli",
			Required:    false,
			Category:    "cmd",
			Description: "Interface en ligne de commande pour la configuration",
		},
		{
			Name:        "cmd/configapi",
			Path:        "cmd/configapi",
			Required:    false,
			Category:    "cmd",
			Description: "API de configuration",
		},

		// Modules tests
		{
			Name:        "tests/validation",
			Path:        "tests/validation",
			Required:    true,
			Category:    "tests",
			Description: "Tests de validation globaux",
		},
		{
			Name:        "tests/test_runners",
			Path:        "tests/test_runners",
			Required:    false,
			Category:    "tests",
			Description: "Runners de tests spécialisés",
		},

		// Modules MCP Gateway (existants)
		{
			Name:        "projet/mcp/servers/gateway",
			Path:        "projet/mcp/servers/gateway",
			Required:    false,
			Category:    "mcp",
			Description: "Serveur de passerelle MCP",
		},
	}
}

// analyzeGaps effectue l'analyse d'écart entre modules attendus et trouvés
func analyzeGaps(repoStructure RepositoryStructure, expectedModules []ExpectedModule) GapAnalysis {
	analysis := GapAnalysis{
		AnalysisDate:    time.Now(),
		TotalExpected:   len(expectedModules),
		TotalFound:      len(repoStructure.Modules),
		MissingModules:  []ExpectedModule{},
		ExtraModules:    []ModuleInfo{},
		MatchingModules: []ModuleInfo{},
		Recommendations: []string{},
	}

	// Créer des maps pour faciliter la comparaison
	foundModulesMap := make(map[string]ModuleInfo)
	for _, module := range repoStructure.Modules {
		// Normaliser le nom du module pour la comparaison
		normalizedName := strings.ReplaceAll(module.Name, "\\", "/")
		foundModulesMap[normalizedName] = module
	}

	expectedModulesMap := make(map[string]ExpectedModule)
	for _, expected := range expectedModules {
		expectedModulesMap[expected.Name] = expected
	}

	// Identifier les modules manquants
	for _, expected := range expectedModules {
		if _, found := foundModulesMap[expected.Name]; !found {
			analysis.MissingModules = append(analysis.MissingModules, expected)
			if expected.Required {
				analysis.Recommendations = append(analysis.Recommendations,
					fmt.Sprintf("CRITIQUE: Créer le module requis '%s' (%s)", expected.Name, expected.Description))
			} else {
				analysis.Recommendations = append(analysis.Recommendations,
					fmt.Sprintf("OPTIONNEL: Considérer la création du module '%s' (%s)", expected.Name, expected.Description))
			}
		}
	}

	// Identifier les modules correspondants et supplémentaires
	for _, found := range repoStructure.Modules {
		normalizedName := strings.ReplaceAll(found.Name, "\\", "/")
		if _, expected := expectedModulesMap[normalizedName]; expected {
			analysis.MatchingModules = append(analysis.MatchingModules, found)
		} else {
			// Vérifier si c'est un module "extra" légitime ou non
			if !isLegitimateExtraModule(normalizedName) {
				analysis.ExtraModules = append(analysis.ExtraModules, found)
				analysis.Recommendations = append(analysis.Recommendations,
					fmt.Sprintf("RÉVISION: Module non-attendu trouvé '%s' - vérifier s'il est nécessaire", normalizedName))
			}
		}
	}

	// Calculer le taux de conformité
	requiredModules := 0
	foundRequiredModules := 0
	for _, expected := range expectedModules {
		if expected.Required {
			requiredModules++
			if _, found := foundModulesMap[expected.Name]; found {
				foundRequiredModules++
			}
		}
	}

	if requiredModules > 0 {
		analysis.ComplianceRate = float64(foundRequiredModules) / float64(requiredModules) * 100
	} else {
		analysis.ComplianceRate = 100.0
	}

	// Générer le résumé
	analysis.Summary = fmt.Sprintf(
		"Analyse d'écart terminée: %d/%d modules requis trouvés (%.1f%% de conformité). "+
			"%d modules manquants, %d modules supplémentaires, %d modules correspondants.",
		foundRequiredModules, requiredModules, analysis.ComplianceRate,
		len(analysis.MissingModules), len(analysis.ExtraModules), len(analysis.MatchingModules))

	// Ajouter des recommandations générales
	if analysis.ComplianceRate < 80 {
		analysis.Recommendations = append(analysis.Recommendations,
			"PRIORITÉ HAUTE: Taux de conformité faible - implémenter les modules critiques manquants")
	} else if analysis.ComplianceRate < 100 {
		analysis.Recommendations = append(analysis.Recommendations,
			"PRIORITÉ MOYENNE: Compléter les modules manquants pour une conformité complète")
	} else {
		analysis.Recommendations = append(analysis.Recommendations,
			"EXCELLENT: Tous les modules requis sont présents")
	}

	return analysis
}

// isLegitimateExtraModule vérifie si un module "extra" est légitime
func isLegitimateExtraModule(moduleName string) bool {
	legitimatePatterns := []string{
		"github.com/",                 // Modules externes
		"golang.org/",                 // Modules standard
		"go.uber.org/",                // Modules tiers légitimes
		"projet/mcp/servers/gateway/", // Sous-modules MCP légitimes
	}

	for _, pattern := range legitimatePatterns {
		if strings.HasPrefix(moduleName, pattern) {
			return true
		}
	}
	return false
}

// generateMarkdownReport génère un rapport Markdown
func generateMarkdownReport(analysis GapAnalysis) string {
	var report strings.Builder

	report.WriteString("# 📊 Analyse d'Écart des Modules\n\n")
	report.WriteString(fmt.Sprintf("**Date d'analyse:** %s\n\n", analysis.AnalysisDate.Format("2006-01-02 15:04:05")))
	report.WriteString(fmt.Sprintf("**Résumé:** %s\n\n", analysis.Summary))

	// Métriques
	report.WriteString("## 📈 Métriques\n\n")
	report.WriteString(fmt.Sprintf("- **Modules attendus:** %d\n", analysis.TotalExpected))
	report.WriteString(fmt.Sprintf("- **Modules trouvés:** %d\n", analysis.TotalFound))
	report.WriteString(fmt.Sprintf("- **Taux de conformité:** %.1f%%\n", analysis.ComplianceRate))
	report.WriteString(fmt.Sprintf("- **Modules manquants:** %d\n", len(analysis.MissingModules)))
	report.WriteString(fmt.Sprintf("- **Modules supplémentaires:** %d\n", len(analysis.ExtraModules)))
	report.WriteString(fmt.Sprintf("- **Modules correspondants:** %d\n\n", len(analysis.MatchingModules)))

	// Modules manquants
	if len(analysis.MissingModules) > 0 {
		report.WriteString("## ❌ Modules Manquants\n\n")
		for _, missing := range analysis.MissingModules {
			status := "OPTIONNEL"
			if missing.Required {
				status = "**REQUIS**"
			}
			report.WriteString(fmt.Sprintf("- %s `%s` (%s)\n  - **Catégorie:** %s\n  - **Description:** %s\n\n",
				status, missing.Name, missing.Path, missing.Category, missing.Description))
		}
	}

	// Modules correspondants
	if len(analysis.MatchingModules) > 0 {
		report.WriteString("## ✅ Modules Correspondants\n\n")
		for _, matching := range analysis.MatchingModules {
			report.WriteString(fmt.Sprintf("- `%s`\n", matching.Name))
		}
		report.WriteString("\n")
	}

	// Modules supplémentaires
	if len(analysis.ExtraModules) > 0 {
		report.WriteString("## ⚠️ Modules Supplémentaires\n\n")
		for _, extra := range analysis.ExtraModules {
			report.WriteString(fmt.Sprintf("- `%s` - %s\n", extra.Name, extra.Description))
		}
		report.WriteString("\n")
	}

	// Recommandations
	report.WriteString("## 🎯 Recommandations\n\n")
	for i, recommendation := range analysis.Recommendations {
		report.WriteString(fmt.Sprintf("%d. %s\n", i+1, recommendation))
	}

	return report.String()
}

func main() {
	// Définir les flags de ligne de commande
	inputFile := flag.String("input", "modules.json", "Fichier JSON d'entrée contenant la structure du dépôt")
	outputFile := flag.String("output", "gap-analysis-initial.json", "Fichier JSON de sortie pour l'analyse d'écart")
	flag.Parse()

	fmt.Println("=== Analyse d'écart des modules ===")
	fmt.Printf("📂 Fichier d'entrée: %s\n", *inputFile)
	fmt.Printf("📄 Fichier de sortie: %s\n", *outputFile)

	// Vérifier que le fichier d'entrée existe
	if _, err := os.Stat(*inputFile); os.IsNotExist(err) {
		log.Fatalf("❌ Fichier d'entrée '%s' introuvable. Exécutez d'abord le scanner de modules.", *inputFile)
	}

	// Lire la structure du dépôt
	jsonData, err := ioutil.ReadFile(*inputFile)
	if err != nil {
		log.Fatalf("❌ Erreur lors de la lecture de %s: %v", *inputFile, err)
	}

	var repoStructure RepositoryStructure
	err = json.Unmarshal(jsonData, &repoStructure)
	if err != nil {
		log.Fatalf("❌ Erreur lors de la désérialisation de %s: %v", *inputFile, err)
	}

	fmt.Printf("📦 Modules chargés: %d\n", len(repoStructure.Modules))

	// Obtenir les modules attendus
	expectedModules := getExpectedModules()
	fmt.Printf("🎯 Modules attendus: %d\n", len(expectedModules))

	// Effectuer l'analyse d'écart
	analysis := analyzeGaps(repoStructure, expectedModules)

	// Sauvegarder l'analyse en JSON
	analysisJSON, err := json.MarshalIndent(analysis, "", "  ")
	if err != nil {
		log.Fatalf("❌ Erreur lors de la sérialisation de l'analyse: %v", err)
	}

	err = ioutil.WriteFile(*outputFile, analysisJSON, 0644)
	if err != nil {
		log.Fatalf("❌ Erreur lors de l'écriture de %s: %v", *outputFile, err)
	}

	// Générer le rapport Markdown
	markdownReport := generateMarkdownReport(analysis)
	markdownFile := strings.TrimSuffix(*outputFile, filepath.Ext(*outputFile)) + ".md"
	err = ioutil.WriteFile(markdownFile, []byte(markdownReport), 0644)
	if err != nil {
		log.Printf("⚠️ Erreur lors de l'écriture du rapport Markdown %s: %v", markdownFile, err)
	}

	// Afficher le résumé
	fmt.Printf("\n✅ Analyse terminée avec succès!\n")
	fmt.Printf("📊 %s\n", analysis.Summary)
	fmt.Printf("📄 Fichiers générés:\n")
	fmt.Printf("   - %s (analyse JSON)\n", *outputFile)
	fmt.Printf("   - %s (rapport Markdown)\n", markdownFile)

	// Afficher les recommandations les plus importantes
	fmt.Printf("\n🎯 Recommandations principales:\n")
	for i, rec := range analysis.Recommendations {
		if i >= 3 { // Limiter à 3 recommandations principales
			fmt.Printf("   ... et %d autres recommandations (voir le rapport complet)\n", len(analysis.Recommendations)-3)
			break
		}
		fmt.Printf("   %d. %s\n", i+1, rec)
	}

	// Code de sortie basé sur le taux de conformité
	if analysis.ComplianceRate < 80 {
		fmt.Printf("\n⚠️ Taux de conformité faible (%.1f%%) - action requise\n", analysis.ComplianceRate)
		os.Exit(1)
	} else if analysis.ComplianceRate < 100 {
		fmt.Printf("\n👍 Taux de conformité acceptable (%.1f%%) - améliorations recommandées\n", analysis.ComplianceRate)
		os.Exit(0)
	} else {
		fmt.Printf("\n🎉 Conformité parfaite (%.1f%%) - excellent travail!\n", analysis.ComplianceRate)
		os.Exit(0)
	}
}
