
package main

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
)

type Inventory struct {
	Modes    []Mode    `json:"modes"`
	Personas []Persona `json:"personas"`
}

type Mode struct {
	Name string `json:"name"`
}

type Persona struct {
	Name string `json:"name"`
}

func main() {
	// Vérifier les arguments de la ligne de commande
	if len(os.Args) != 5 || os.Args[1] != "--input" || os.Args[3] != "--output" {
		fmt.Println("Usage: go run main.go --input <input-file.json> --output <output-file.csv>")
		os.Exit(1)
	}

	inputFile := os.Args[2]
	outputFile := os.Args[4]

	// Lire le fichier d'inventaire
	data, err := ioutil.ReadFile(inputFile)
	if err != nil {
		fmt.Printf("Erreur de lecture du fichier d'entrée : %v\n", err)
		os.Exit(1)
	}

	// Parser le JSON
	var inventory Inventory
	err = json.Unmarshal(data, &inventory)
	if err != nil {
		fmt.Printf("Erreur de parsing JSON : %v\n", err)
		os.Exit(1)
	}

	// Créer le fichier de sortie CSV
	file, err := os.Create(outputFile)
	if err != nil {
		fmt.Printf("Erreur de création du fichier de sortie : %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Écrire l'en-tête du CSV
	writer.Write([]string{"ElementType", "ElementName", "GapDescription"})

	// Analyser les écarts (logique à implémenter)
	// Pour l'instant, nous allons simplement écrire quelques exemples
	writer.Write([]string{"Mode", "Project Research", "Manquant dans AGENTS.md"})
	writer.Write([]string{"Persona", "Architecte", "Persona non listé dans AGENTS.md"})

	fmt.Printf("Rapport d'analyse des écarts généré dans %s\n", outputFile)
}

