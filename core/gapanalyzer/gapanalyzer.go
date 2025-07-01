package gapanalyzer

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"

	"email_sender/core/gapanalyzer"	// Import the gapanalyzer package
	"email_sender/core/scanmodules"	// Import scanmodules for RepositoryStructure
)

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

	var repoStructure scanmodules.RepositoryStructure	// Use RepositoryStructure from scanmodules
	err = json.Unmarshal(jsonData, &repoStructure)
	if err != nil {
		log.Fatalf("❌ Erreur lors de la désérialisation de %s: %v", *inputFile, err)
	}

	fmt.Printf("📦 Modules chargés: %d\n", len(repoStructure.Modules))

	// Obtenir les modules attendus
	expectedModules := gapanalyzer.GetExpectedModules()	// Use exported function
	fmt.Printf("🎯 Modules attendus: %d\n", len(expectedModules))

	// Effectuer l'analyse d'écart
	analysis := gapanalyzer.AnalyzeGaps(repoStructure, expectedModules)	// Use exported function

	// Sauvegarder l'analyse en JSON
	analysisJSON, err := json.MarshalIndent(analysis, "", "  ")
	if err != nil {
		log.Fatalf("❌ Erreur lors de la sérialisation de l'analyse: %v", err)
	}

	err = ioutil.WriteFile(*outputFile, analysisJSON, 0o644)
	if err != nil {
		log.Fatalf("❌ Erreur lors de l'écriture de %s: %v", *outputFile, err)
	}

	// Générer le rapport Markdown
	markdownReport := gapanalyzer.GenerateMarkdownReport(analysis)	// Use exported function
	markdownFile := strings.TrimSuffix(*outputFile, filepath.Ext(*outputFile)) + ".md"
	err = ioutil.WriteFile(markdownFile, []byte(markdownReport), 0o644)
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
		if i >= 3 {	// Limiter à 3 recommandations principales
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
