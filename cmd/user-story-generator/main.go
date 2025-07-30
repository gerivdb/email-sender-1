// cmd/user-story-generator/main.go
// Script Go natif pour générer les user stories à partir des besoins-personas.json et gap-analysis-report.md
// Phase 3.3 - Roadmap v105h
//
// Usage : go run cmd/user-story-generator/main.go --input besoins-personas.json --output-md user-stories.md --output-json user-stories.json
//
// Documentation : README-user-stories.md

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"time"
)

// Structures
type UserStory struct {
	Persona     string   `json:"persona"`
	Story       string   `json:"story"`
	Priorite    string   `json:"priorite"`
	Dependances []string `json:"dependances"`
	DateGen     string   `json:"date_generation"`
}

// Extraction fictive des besoins (à remplacer par parsing réel)
func extractUserStories() []UserStory {
	return []UserStory{
		{
			Persona:     "Architecte",
			Story:       "En tant qu'architecte, je veux valider les specs pour garantir la cohérence du système.",
			Priorite:    "Haute",
			Dependances: []string{"Vision système", "Diagrammes"},
			DateGen:     time.Now().Format(time.RFC3339),
		},
		{
			Persona:     "Développeur",
			Story:       "En tant que développeur, je veux disposer de tests unitaires pour sécuriser le code.",
			Priorite:    "Haute",
			Dependances: []string{"Code modulaire", "Documentation"},
			DateGen:     time.Now().Format(time.RFC3339),
		},
		{
			Persona:     "Utilisateur",
			Story:       "En tant qu'utilisateur, je veux une interface claire pour faciliter mon expérience.",
			Priorite:    "Moyenne",
			Dependances: []string{"Feedback", "Support"},
			DateGen:     time.Now().Format(time.RFC3339),
		},
	}
}

func main() {
	input := flag.String("input", "besoins-personas.json", "Fichier d’entrée JSON")
	outputMD := flag.String("output-md", "user-stories.md", "Fichier de sortie Markdown")
	outputJSON := flag.String("output-json", "user-stories.json", "Fichier de sortie JSON")
	flag.Parse()

	log.Printf("Début de la génération des user stories (%s)", time.Now().Format(time.RFC3339))

	stories := extractUserStories()

	// Génération JSON
	fjson, err := os.Create(*outputJSON)
	if err != nil {
		log.Fatalf("Erreur création fichier JSON : %v", err)
	}
	defer fjson.Close()
	encoder := json.NewEncoder(fjson)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(stories); err != nil {
		log.Fatalf("Erreur écriture JSON : %v", err)
	}

	// Génération Markdown
	fmd, err := os.Create(*outputMD)
	if err != nil {
		log.Fatalf("Erreur création fichier Markdown : %v", err)
	}
	defer fmd.Close()
	fmt.Fprintf(fmd, "# User Stories – Personas\n\n")
	fmt.Fprintf(fmd, "_Date de génération : %s_\n\n", time.Now().Format("2006-01-02 15:04:05"))
	fmt.Fprintf(fmd, "| Persona      | User Story                                                        | Priorité | Dépendances                | Date génération         |\n")
	fmt.Fprintf(fmd, "|--------------|-------------------------------------------------------------------|----------|---------------------------|------------------------|\n")
	for _, s := range stories {
		fmt.Fprintf(fmd, "| %s | %s | %s | %v | %s |\n", s.Persona, s.Story, s.Priorite, s.Dependances, s.DateGen)
	}

	fmt.Fprintf(fmd, "\n---\n\n## Log d’exécution\n")
	fmt.Fprintf(fmd, "- Script utilisé : go run cmd/user-story-generator/main.go --input %s --output-md %s --output-json %s\n", *input, *outputMD, *outputJSON)
	fmt.Fprintf(fmd, "- Fichiers générés : %s, %s\n", *outputMD, *outputJSON)
	fmt.Fprintf(fmd, "- Horodatage : %s\n", time.Now().Format(time.RFC3339))

	log.Printf("Génération des user stories terminée. Fichiers générés : %s, %s", *outputMD, *outputJSON)
	fmt.Printf("Succès : user stories générées\n")
}
