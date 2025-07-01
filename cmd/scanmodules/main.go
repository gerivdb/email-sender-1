package main

import (
	"core/scanmodules"
	"fmt"
	"log"
)

func main() {
	fmt.Println("=== Scan des modules et structure du dépôt ===")

	// Configuration du scan
	options := scanmodules.ScanOptions{
		TreeLevels: 3,
		OutputDir:  ".",
	}

	// Effectuer le scan
	structure, err := scanmodules.ScanModules(options)
	if err != nil {
		log.Fatalf("❌ Erreur lors du scan: %v", err)
	}

	// Sauvegarder en JSON
	err = scanmodules.SaveToJSON(structure, options.OutputDir)
	if err != nil {
		log.Fatalf("❌ Erreur lors de la sauvegarde: %v", err)
	}

	// Afficher le résumé
	scanmodules.PrintSummary(structure, options.OutputDir)
}
