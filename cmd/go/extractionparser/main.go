package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/gerivdb/email-sender-1/core/extraction"

	"github.com/gerivdb/email-sender-1/core/gapanalyzer"
)

func main() {
	fmt.Println("Démarrage de l'orchestration de la Phase 4 : Extraction et Parsing.")

	// Définir les chemins de sortie
	outputDir := "../../output/phase4"  // Un répertoire pour les sorties
	os.MkdirAll(outputDir, os.ModePerm) // Créer le répertoire si nécessaire

	extractionScanPath := filepath.Join(outputDir, "extraction-parsing-scan.json")
	gapAnalysisPath := filepath.Join(outputDir, "EXTRACTION_PARSING_GAP_ANALYSIS.md")
	phase4ReportPath := filepath.Join(outputDir, "EXTRACTION_PARSING_PHASE4_REPORT.md")

	// --- Étape 1: Extraction et Parsing ---
	fmt.Println("\nExécution de l'extraction et du parsing...")
	// Simuler un chemin source pour l'extraction. En réalité, ce serait un chemin vers des données réelles.
	// Pour ce test, nous allons créer un fichier temporaire.
	tempSourceFile := filepath.Join(outputDir, "simulated_source_data.txt")
	err := os.WriteFile(tempSourceFile, []byte("Ceci est un contenu de données simulées pour l'extraction."), 0o644)
	if err != nil {
		log.Fatalf("Erreur lors de la création du fichier source simulé : %v", err)
	}

	extractedData, err := extraction.ExtractAndParseData(tempSourceFile)
	if err != nil {
		log.Printf("Erreur lors de l'extraction et du parsing : %v", err)
		// Continuer si possible pour l'analyse des écarts même en cas d'erreur d'extraction
		extractedData = map[string]interface{}{"status": "failed", "error": err.Error()}
	} else {
		fmt.Println("Extraction et parsing terminés avec succès.")
	}

	// Générer le fichier de scan d'extraction
	err = extraction.GenerateExtractionParsingScan(extractionScanPath, extractedData)
	if err != nil {
		log.Fatalf("Erreur lors de la génération du scan d'extraction : %v", err)
	}
	fmt.Printf("Fichier de scan d'extraction généré : %s\n", extractionScanPath)

	// --- Étape 2: Analyse d'écart ---
	fmt.Println("\nExécution de l'analyse des écarts...")
	analysisResult, err := gapanalyzer.AnalyzeExtractionParsingGap(extractedData)
	if err != nil {
		log.Fatalf("Erreur lors de l'analyse des écarts : %v", err)
	}
	fmt.Println("Analyse des écarts terminée.")

	// Générer le rapport d'analyse des écarts
	err = gapanalyzer.GenerateExtractionParsingGapAnalysis(gapAnalysisPath, analysisResult)
	if err != nil {
		log.Fatalf("Erreur lors de la génération du rapport d'analyse des écarts : %v", err)
	}
	fmt.Printf("Rapport d'analyse des écarts généré : %s\n", gapAnalysisPath)

	// --- Étape 3: Génération du rapport de la Phase 4 ---
	fmt.Println("\nGénération du rapport de la Phase 4...")
	reportContent := fmt.Sprintf(`
# Rapport de la Phase 4 : Extraction et Parsing

## Résumé
Cette phase a couvert l'extraction et le parsing des données, suivi d'une analyse des écarts.

## Résultats de l'Extraction/Parsing
- Voir le fichier : [%s](%s)

## Résultats de l'Analyse des Écarts
- Voir le fichier : [%s](%s)

## Statut Global
Phase 4 complétée le %s.
Écarts détectés : %v
`,
		filepath.Base(extractionScanPath), extractionScanPath,
		filepath.Base(gapAnalysisPath), gapAnalysisPath,
		time.Now().Format(time.RFC3339), analysisResult["gap_found"])

	err = os.WriteFile(phase4ReportPath, []byte(reportContent), 0o644)
	if err != nil {
		log.Fatalf("Erreur lors de la génération du rapport de la Phase 4 : %v", err)
	}
	fmt.Printf("Rapport de la Phase 4 généré : %s\n", phase4ReportPath)

	fmt.Println("\nOrchestration de la Phase 4 terminée.")
}
