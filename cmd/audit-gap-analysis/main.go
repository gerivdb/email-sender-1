// cmd/audit-gap-analysis/main.go
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
)

// Inventory représente la structure de l'inventaire.
type Inventory struct {
	Modes    []Mode    `json:"modes"`
	Personas []Persona `json:"personas"`
}

// Mode représente un mode dans l'inventaire.
type Mode struct {
	Name string `json:"name"`
}

// Persona représente un persona dans l'inventaire.
type Persona struct {
	Name string `json:"name"`
}

func main() {
	// Définir et parser les arguments de la ligne de commande
	inputPath := flag.String("input", "inventory-personas-modes.json", "Chemin du fichier d'entrée JSON")
	outputPath := flag.String("output", "gap-analysis-report.md", "Chemin du fichier de sortie Markdown")
	flag.Parse()

	// Lire le fichier d'inventaire
	data, err := ioutil.ReadFile(*inputPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur de lecture du fichier d'entrée: %v\n", err)
		os.Exit(1)
	}

	// Parser le JSON
	var inventory Inventory
	err = json.Unmarshal(data, &inventory)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur de parsing JSON: %v\n", err)
		os.Exit(1)
	}

	// Débogage : afficher le contenu de l'inventaire
	fmt.Printf("Inventaire chargé : %+v\n", inventory)

	// Ensembles de référence (codés en dur pour l'instant)
	refModes := map[string]bool{"Architect": true, "Code": true, "Ask": true, "Debug": true, "Orchestrator": true}
	refPersonas := map[string]bool{"Architecte": true, "Développeur": true, "Utilisateur": true}

	// Créer le rapport d'analyse des écarts
	report, err := os.Create(*outputPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur de création du fichier de sortie: %v\n", err)
		os.Exit(1)
	}
	defer report.Close()

	fmt.Fprintln(report, "# Rapport d'analyse des écarts")
	fmt.Fprintln(report, "")

	// Analyser les modes
	fmt.Fprintln(report, "## Modes")
	for _, mode := range inventory.Modes {
		if !refModes[mode.Name] {
			fmt.Fprintf(report, "- [Écart] Mode non standard: %s\n", mode.Name)
		}
	}

	// Analyser les personas
	fmt.Fprintln(report, "")
	fmt.Fprintln(report, "## Personas")
	for _, persona := range inventory.Personas {
		if !refPersonas[persona.Name] {
			fmt.Fprintf(report, "- [Écart] Persona non standard: %s\n", persona.Name)
		}
	}

	fmt.Printf("Rapport d'analyse des écarts généré dans : %s\n", *outputPath)
}
