package main

import (
	"core/reporting"
	"flag"
	"log"
)

func main() {
	// Définir les flags de ligne de commande
	inputFile := flag.String("input", "issues.json", "Fichier JSON d'entrée contenant les issues")
	outputFile := flag.String("output", "besoins.json", "Fichier JSON de sortie pour les besoins")
	flag.Parse()

	// Exécuter l'analyse des besoins
	err := reporting.RunNeedsAnalysis(*inputFile, *outputFile)
	if err != nil {
		log.Fatalf("❌ Erreur lors de l'analyse des besoins: %v", err)
	}
}
