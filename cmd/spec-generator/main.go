package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
)

type PersonaNeeds struct {
	Persona string   `json:"persona"`
	Needs   []string `json:"needs"`
}

func main() {
	// Lire le fichier besoins-personas.json
	needsFile, err := ioutil.ReadFile("besoins-personas.json")
	if err != nil {
		fmt.Printf("Erreur lors de la lecture de besoins-personas.json: %v\n", err)
		os.Exit(1)
	}

	var personaNeedsList []PersonaNeeds
	err = json.Unmarshal(needsFile, &personaNeedsList)
	if err != nil {
		fmt.Printf("Erreur lors de la conversion JSON: %v\n", err)
		os.Exit(1)
	}

	// Créer le fichier de spécifications
	specFile, err := os.Create("personas-modes-spec.md")
	if err != nil {
		fmt.Printf("Erreur lors de la création de personas-modes-spec.md: %v\n", err)
		os.Exit(1)
	}
	defer specFile.Close()

	specFile.WriteString("# Spécifications des Personas et Modes\n\n")

	for _, personaNeeds := range personaNeedsList {
		specFile.WriteString(fmt.Sprintf("## Persona: %s\n\n", personaNeeds.Persona))
		specFile.WriteString("### Besoins\n\n")
		for _, need := range personaNeeds.Needs {
			specFile.WriteString(fmt.Sprintf("- %s\n", need))
		}
		specFile.WriteString("\n")
	}

	fmt.Println("Spécifications générées dans personas-modes-spec.md")
}