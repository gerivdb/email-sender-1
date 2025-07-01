package reporting

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"

	"email_sender/core/reporting"
)

func main() {
	// Définir les flags de ligne de commande
	inputFile := flag.String("input", "", "Fichier JSON d'entrée")
	outputFile := flag.String("output", "", "Fichier JSON de sortie")
	mode := flag.String("mode", "needs", "Mode d'exécution: 'needs' ou 'spec'")
	flag.Parse()

	if *inputFile == "" || *outputFile == "" {
		fmt.Println("❌ Erreur: fichiers d'entrée et de sortie requis")
		flag.Usage()
		os.Exit(1)
	}

	switch *mode {
	case "needs":
		runNeedsAnalysis(*inputFile, *outputFile)
	case "spec":
		runSpecGeneration(*inputFile, *outputFile)
	default:
		fmt.Printf("❌ Mode '%s' non reconnu. Utilisez 'needs' ou 'spec'\n", *mode)
		os.Exit(1)
	}
}

func runNeedsAnalysis(inputFile, outputFile string) {
	fmt.Println("=== Analyse des besoins ===")
	fmt.Printf("📂 Fichier d'entrée: %s\n", inputFile)
	fmt.Printf("📄 Fichier de sortie: %s\n", outputFile)

	// Parser les issues
	issues, err := reporting.ParseIssuesFromJSON(inputFile)
	if err != nil {
		log.Fatalf("❌ Erreur lors du parsing des issues: %v", err)
	}

	fmt.Printf("📋 Issues chargées: %d\n", len(issues))

	// Convertir en besoins
	requirements := reporting.ConvertIssuesToRequirements(issues)
	fmt.Printf("🎯 Besoins identifiés: %d\n", len(requirements))

	// Analyser les besoins
	analysis := reporting.AnalyzeRequirements(requirements)
	analysis.TotalIssues = len(issues)

	// Sauvegarder l'analyse en JSON
	analysisJSON, err := json.MarshalIndent(analysis, "", "  ")
	if err != nil {
		log.Fatalf("❌ Erreur lors de la sérialisation de l'analyse: %v", err)
	}

	err = ioutil.WriteFile(outputFile, analysisJSON, 0o644)
	if err != nil {
		log.Fatalf("❌ Erreur lors de l'écriture de %s: %v", outputFile, err)
	}

	// Générer le rapport Markdown
	markdownReport := reporting.GenerateMarkdownReport(analysis)
	markdownFile := "BESOINS_INITIAUX.md"
	err = ioutil.WriteFile(markdownFile, []byte(markdownReport), 0o644)
	if err != nil {
		log.Printf("⚠️ Erreur lors de l'écriture du rapport Markdown %s: %v", markdownFile, err)
	}

	// Afficher le résumé
	fmt.Printf("\n✅ Analyse terminée avec succès!\n")
	fmt.Printf("📊 %s\n", analysis.Summary)
	fmt.Printf("📄 Fichiers générés:\n")
	fmt.Printf("   - %s (analyse JSON)\n", outputFile)
	fmt.Printf("   - %s (rapport Markdown)\n", markdownFile)

	// Afficher les recommandations principales
	fmt.Printf("\n🎯 Recommandations principales:\n")
	for i, rec := range analysis.Recommendations {
		if i >= 3 {
			fmt.Printf("   ... et %d autres recommandations (voir le rapport complet)\n", len(analysis.Recommendations)-3)
			break
		}
		fmt.Printf("   %d. %s\n", i+1, rec)
	}

	fmt.Printf("\n📈 Distribution des besoins:\n")
	for category, count := range analysis.Categories {
		fmt.Printf("   - %s: %d besoins\n", category, count)
	}
}

func runSpecGeneration(inputFile, outputFile string) {
	fmt.Println("=== Génération de spécifications ===")
	fmt.Printf("📂 Fichier d'entrée: %s\n", inputFile)
	fmt.Printf("📄 Fichier de sortie: %s\n", outputFile)

	// Lire l'analyse des besoins
	jsonData, err := ioutil.ReadFile(inputFile)
	if err != nil {
		log.Fatalf("❌ Erreur lors de la lecture de %s: %v", inputFile, err)
	}

	var requirementsAnalysis reporting.RequirementsAnalysis
	err = json.Unmarshal(jsonData, &requirementsAnalysis)
	if err != nil {
		log.Fatalf("❌ Erreur lors de la désérialisation de %s: %v", inputFile, err)
	}

	fmt.Printf("📋 Besoins chargés: %d\n", len(requirementsAnalysis.Requirements))

	// Générer les spécifications
	specifications := reporting.GenerateSpecificationsFromRequirements(requirementsAnalysis.Requirements)
	fmt.Printf("📝 Spécifications générées: %d\n", len(specifications))

	// Analyser les spécifications
	specAnalysis := reporting.AnalyzeSpecifications(specifications)

	// Sauvegarder l'analyse en JSON
	analysisJSON, err := json.MarshalIndent(specAnalysis, "", "  ")
	if err != nil {
		log.Fatalf("❌ Erreur lors de la sérialisation de l'analyse: %v", err)
	}

	err = ioutil.WriteFile(outputFile, analysisJSON, 0o644)
	if err != nil {
		log.Fatalf("❌ Erreur lors de l'écriture de %s: %v", outputFile, err)
	}

	// Générer le rapport Markdown
	markdownReport := reporting.GenerateSpecMarkdownReport(specAnalysis)
	markdownFile := strings.TrimSuffix(outputFile, ".json") + ".md"
	err = ioutil.WriteFile(markdownFile, []byte(markdownReport), 0o644)
	if err != nil {
		log.Printf("⚠️ Erreur lors de l'écriture du rapport Markdown %s: %v", markdownFile, err)
	}

	// Afficher le résumé
	fmt.Printf("\n✅ Génération terminée avec succès!\n")
	fmt.Printf("📊 %s\n", specAnalysis.Summary)
	fmt.Printf("📄 Fichiers générés:\n")
	fmt.Printf("   - %s (spécifications JSON)\n", outputFile)
	fmt.Printf("   - %s (rapport Markdown)\n", markdownFile)

	// Afficher les métriques principales
	fmt.Printf("\n📈 Métriques:\n")
	fmt.Printf("   - Spécifications: %d\n", specAnalysis.TotalSpecifications)
	fmt.Printf("   - Tests prévus: %d\n", specAnalysis.TotalTestCases)
	fmt.Printf("   - Effort estimé: %.1f jours\n", specAnalysis.TotalEffort)

	fmt.Printf("\n📊 Distribution par complexité:\n")
	for complexity, count := range specAnalysis.ComplexityDistribution {
		fmt.Printf("   - %s: %d spécifications\n", complexity, count)
	}
}
