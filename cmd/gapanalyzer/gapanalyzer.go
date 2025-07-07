package main

import (
	"github.com/gerivdb/email-sender-1/core/gapanalyzer"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
)

func main() {
	// Flags pour configurer l'analyse
	inputFile := flag.String("input", "modules.json", "Fichier JSON d'entrée contenant les modules existants")
	outputFile := flag.String("output", "gap-analysis.json", "Fichier JSON de sortie pour l'analyse")
	markdownFile := flag.String("markdown", "", "Fichier Markdown de sortie (optionnel)")
	help := flag.Bool("help", false, "Afficher l'aide")

	flag.Parse()

	if *help {
		fmt.Println("Usage: gapanalyzer [options]")
		fmt.Println("Options:")
		flag.PrintDefaults()
		os.Exit(0)
	}

	// Vérifier que le fichier d'entrée existe
	if _, err := os.Stat(*inputFile); os.IsNotExist(err) {
		log.Fatalf("Le fichier d'entrée %s n'existe pas", *inputFile)
	}

	// Charger la structure du dépôt
	repoStructure, err := gapanalyzer.LoadRepositoryStructure(*inputFile)
	if err != nil {
		log.Fatalf("Erreur chargement structure dépôt: %v", err)
	}

	// Obtenir les modules attendus
	expectedModules := gapanalyzer.GetExpectedModules()

	// Analyser les écarts
	analysis := gapanalyzer.AnalyzeGaps(repoStructure, expectedModules)

	// Sauvegarder l'analyse JSON
	err = gapanalyzer.SaveGapAnalysis(analysis, *outputFile)
	if err != nil {
		log.Fatalf("Erreur sauvegarde analyse: %v", err)
	}

	// Générer et sauvegarder le rapport Markdown si demandé
	if *markdownFile != "" {
		markdownContent := gapanalyzer.GenerateMarkdownReport(analysis)
		err = gapanalyzer.SaveMarkdownReport(markdownContent, *markdownFile)
		if err != nil {
			log.Printf("Attention: erreur sauvegarde rapport Markdown: %v", err)
		}
	} else {
		// Si pas de fichier Markdown spécifié, créer un par défaut
		defaultMarkdown := filepath.Join(filepath.Dir(*outputFile), "gap-analysis.md")
		markdownContent := gapanalyzer.GenerateMarkdownReport(analysis)
		err = gapanalyzer.SaveMarkdownReport(markdownContent, defaultMarkdown)
		if err != nil {
			log.Printf("Attention: erreur sauvegarde rapport Markdown par défaut: %v", err)
		}
	}

	// Afficher un résumé
	fmt.Printf("✅ Analyse d'écart terminée!\n")
	fmt.Printf("📊 Résumé: %s\n", analysis.Summary)
	fmt.Printf("📄 Analyse JSON: %s\n", *outputFile)
	if *markdownFile != "" {
		fmt.Printf("📝 Rapport Markdown: %s\n", *markdownFile)
	}

	// Exit avec code d'erreur si la conformité n'est pas à 100%
	if analysis.ComplianceRate < 100.0 {
		os.Exit(1)
	}
}
