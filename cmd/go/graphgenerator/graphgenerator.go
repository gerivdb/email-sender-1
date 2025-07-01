package graphgenerator

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"email_sender/core/graphgen"

	"email_sender/core/gapanalyzer"
)

// findProjectRoot trouve le répertoire racine du projet en cherchant le fichier go.mod.
func findProjectRoot() (string, error) {
	exePath, err := os.Executable()
	if err != nil {
		return "", fmt.Errorf("impossible d'obtenir le chemin de l'exécutable : %w", err)
	}
	currentDir := filepath.Dir(exePath)	// Commence à partir du répertoire de l'exécutable

	for {
		goModPath := filepath.Join(currentDir, "go.mod")
		if _, err := os.Stat(goModPath); err == nil {
			return currentDir, nil
		}

		parentDir := filepath.Dir(currentDir)
		if parentDir == currentDir {	// At the root or reached filesystem root
			return "", fmt.Errorf("go.mod non trouvé dans aucun répertoire parent à partir de %s", filepath.Dir(exePath))
		}
		currentDir = parentDir
	}
}

func main() {
	fmt.Println("Démarrage de l'orchestration de la Phase 5 : Génération et Visualisation Graphes.")

	projectRoot, err := findProjectRoot()
	if err != nil {
		log.Fatalf("Erreur : %v", err)
	}

	// Définir les chemins de sortie
	outputDir := filepath.Join(projectRoot, "output", "phase5")	// Un répertoire pour les sorties
	fmt.Printf("Tentative de création du répertoire de sortie : %s\n", outputDir)
	err = os.MkdirAll(outputDir, os.ModePerm)	// Créer le répertoire si nécessaire
	if err != nil {
		log.Fatalf("Erreur lors de la création du répertoire de sortie %s: %v", outputDir, err)
	}

	graphScanPath := filepath.Join(outputDir, "graphgen-scan.json")
	gapAnalysisPath := filepath.Join(outputDir, "GRAPHGEN_GAP_ANALYSIS.md")
	phase5ReportPath := filepath.Join(outputDir, "GRAPHGEN_PHASE5_REPORT.md")

	// --- Étape 1: Génération des données de graphe ---
	fmt.Println("\nExécution de la génération des données de graphe...")
	// Simuler des chemins source pour la génération de graphe
	sourcePaths := []string{"./src/module1.go", "./src/config.json", "./docs/architecture.md"}
	graphData, err := graphgen.GenerateGraphData(sourcePaths)
	if err != nil {
		log.Fatalf("Erreur lors de la génération des données de graphe : %v", err)
	}
	fmt.Println("Génération des données de graphe terminée avec succès.")

	// Exporter le scan du graphe
	err = graphgen.ExportGraphScan(graphScanPath, graphData)
	if err != nil {
		log.Fatalf("Erreur lors de l'exportation du scan du graphe : %v", err)
	}
	fmt.Printf("Fichier de scan de graphe généré : %s\n", graphScanPath)

	// --- Étape 2: Analyse d'écart pour les graphes ---
	fmt.Println("\nExécution de l'analyse des écarts pour les graphes...")
	// Pour cette simulation, nous allons simplement vérifier si des données de graphe ont été générées.
	// En réalité, une analyse d'écart serait plus complexe (e.g., conformité aux standards, détection d'anomalies).
	gapAnalysisResult, err := gapanalyzer.AnalyzeGraphGenerationGap(graphData)	// Nouvelle fonction à ajouter au gapanalyzer
	if err != nil {
		log.Fatalf("Erreur lors de l'analyse des écarts pour les graphes : %v", err)
	}
	fmt.Println("Analyse des écarts pour les graphes terminée.")

	// Générer le rapport d'analyse des écarts pour les graphes
	err = gapanalyzer.GenerateGraphGenerationGapAnalysis(gapAnalysisPath, gapAnalysisResult)	// Nouvelle fonction à ajouter au gapanalyzer
	if err != nil {
		log.Fatalf("Erreur lors de la génération du rapport d'analyse des écarts pour les graphes : %v", err)
	}
	fmt.Printf("Rapport d'analyse des écarts pour les graphes généré : %s\n", gapAnalysisPath)

	// --- Étape 3: Génération du rapport de la Phase 5 ---
	fmt.Println("\nGénération du rapport de la Phase 5...")
	reportContent := fmt.Sprintf(`
# Rapport de la Phase 5 : Génération et Visualisation Graphes

## Résumé
Cette phase a couvert la génération des données de graphes à partir des sources, suivie d'une analyse des écarts.

## Résultats de la Génération de Graphes
- Voir le fichier : [%s](%s)

## Résultats de l'Analyse des Écarts
- Voir le fichier : [%s](%s)

## Statut Global
Phase 5 complétée le %s.
Écarts détectés : %v
`,
		filepath.Base(graphScanPath), graphScanPath,
		filepath.Base(gapAnalysisPath), gapAnalysisPath,
		time.Now().Format(time.RFC3339), gapAnalysisResult["gap_found"])

	err = os.WriteFile(phase5ReportPath, []byte(reportContent), 0o644)
	if err != nil {
		log.Fatalf("Erreur lors de la génération du rapport de la Phase 5 : %v", err)
	}
	fmt.Printf("Rapport de la Phase 5 généré : %s\n", phase5ReportPath)

	fmt.Println("\nOrchestration de la Phase 5 terminée.")
}
