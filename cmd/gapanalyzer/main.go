package main

import (
	"fmt"
	"os"

	"docmanager/core/gapanalyzer"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: gapanalyzer <scanmodules.json> [output_md]")
		os.Exit(1)
	}
	scanPath := os.Args[1]
	output := "INIT_GAP_ANALYSIS.md"
	if len(os.Args) > 2 {
		output = os.Args[2]
	}
	gaps, err := gapanalyzer.AnalyzeGaps(scanPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur AnalyzeGaps: %v\n", err)
		os.Exit(2)
	}
	err = gapanalyzer.ExportMarkdown(gaps, output)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur ExportMarkdown: %v\n", err)
		os.Exit(3)
	}
	fmt.Printf("Analyse d'écart générée dans %s\n", output)
}
