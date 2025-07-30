// cmd/recensement-besoins/main.go
// Script Go natif pour recenser les besoins utilisateurs/personas et générer besoins-personas.json
// Phase 3 - Roadmap v105h
//
// Usage : go run cmd/recensement-besoins/main.go --output besoins-personas.json
//
// Documentation : README-recueil-besoins.md

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"time"
)

// BesoinPersona structure
type BesoinPersona struct {
	Persona         string   `json:"persona"`
	Besoins         []string `json:"besoins"`
	Source          string   `json:"source"`
	DateRecensement string   `json:"date_recensement"`
}

// Extraction fictive des besoins (à remplacer par parsing réel)
func extractBesoins() []BesoinPersona {
	return []BesoinPersona{
		{
			Persona:         "Architecte",
			Besoins:         []string{"Vision système", "Diagrammes", "Validation specs"},
			Source:          "AGENTS.md",
			DateRecensement: time.Now().Format(time.RFC3339),
		},
		{
			Persona:         "Développeur",
			Besoins:         []string{"Code modulaire", "Tests unitaires", "Documentation"},
			Source:          "AGENTS.md",
			DateRecensement: time.Now().Format(time.RFC3339),
		},
		{
			Persona:         "Utilisateur",
			Besoins:         []string{"Interface claire", "Feedback", "Support"},
			Source:          "Questionnaires",
			DateRecensement: time.Now().Format(time.RFC3339),
		},
	}
}

func main() {
	output := flag.String("output", "besoins-personas.json", "Fichier de sortie JSON")
	flag.Parse()

	log.Printf("Début du recensement des besoins (%s)", time.Now().Format(time.RFC3339))

	besoins := extractBesoins()

	file, err := os.Create(*output)
	if err != nil {
		log.Fatalf("Erreur création fichier : %v", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(besoins); err != nil {
		log.Fatalf("Erreur écriture JSON : %v", err)
	}

	log.Printf("Recensement terminé. Fichier généré : %s", *output)
	fmt.Printf("Succès : %d personas recensés\n", len(besoins))
}
