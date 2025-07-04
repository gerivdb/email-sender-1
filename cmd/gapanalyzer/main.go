package main

import (
	"fmt"
	"os"

	"github.com/gerivdb/email-sender-1/core/gapanalyzer"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: gapanalyzer <modules.json> [output_json] [output_md]")
		os.Exit(1)
	}
	modulesJSONPath := os.Args[1]
	outputJSONPath := "gap-analysis-initial.json"
	if len(os.Args) > 2 {
		outputJSONPath = os.Args[2]
	}
	outputMDPath := "GAP_ANALYSIS_INIT.md"
	if len(os.Args) > 3 {
		outputMDPath = os.Args[3]
	}

	analysisResult, err := gapanalyzer.AnalyzeGoModulesGap(modulesJSONPath, "") // "" for default expected modules
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors de l'analyse des écarts: %v\n", err)
		os.Exit(2)
	}

	err = gapanalyzer.GenerateGapAnalysisReport(outputJSONPath, outputMDPath, analysisResult)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors de la génération du rapport: %v\n", err)
		os.Exit(3)
	}
	fmt.Printf("Analyse d'écart générée dans %s et %s\n", outputJSONPath, outputMDPath)
}
