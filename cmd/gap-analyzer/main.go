// cmd/gap-analyzer/main.go
// Script Go natif pour analyse d’écart entre besoins-personas.json et l’existant (AGENTS.md, modules)
// Phase 3.2 - Roadmap v105h
//
// Usage : go run cmd/gap-analyzer/main.go --input besoins-personas.json --output gap-analysis-report.md
//
// Documentation : README-gap-analysis.md

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
type BesoinPersona struct {
	Persona         string   `json:"persona"`
	Besoins         []string `json:"besoins"`
	Source          string   `json:"source"`
	DateRecensement string   `json:"date_recensement"`
}

type Ecart struct {
	Persona          string   `json:"persona"`
	BesoinsManquants []string `json:"besoins_manquants"`
	Commentaire      string   `json:"commentaire"`
}

// Extraction fictive de l’existant (à remplacer par parsing réel)
func extractExistant() map[string][]string {
	return map[string][]string{
		"Architecte":  {"Vision système", "Diagrammes"},
		"Développeur": {"Code modulaire", "Tests unitaires"},
		"Utilisateur": {"Interface claire"},
	}
}

// Analyse d’écart
func analyzeGap(besoins []BesoinPersona, existant map[string][]string) []Ecart {
	var ecarts []Ecart
	for _, b := range besoins {
		ex := existant[b.Persona]
		manquants := []string{}
		for _, besoin := range b.Besoins {
			found := false
			for _, exist := range ex {
				if besoin == exist {
					found = true
					break
				}
			}
			if !found {
				manquants = append(manquants, besoin)
			}
		}
		commentaire := "OK"
		if len(manquants) > 0 {
			commentaire = "Besoins non couverts"
		}
		ecarts = append(ecarts, Ecart{
			Persona:          b.Persona,
			BesoinsManquants: manquants,
			Commentaire:      commentaire,
		})
	}
	return ecarts
}

func main() {
	input := flag.String("input", "besoins-personas.json", "Fichier d’entrée JSON")
	output := flag.String("output", "gap-analysis-report.md", "Fichier de sortie Markdown")
	flag.Parse()

	log.Printf("Début de l’analyse d’écart (%s)", time.Now().Format(time.RFC3339))

	file, err := os.Open(*input)
	if err != nil {
		log.Fatalf("Erreur ouverture fichier : %v", err)
	}
	defer file.Close()

	var besoins []BesoinPersona
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(&besoins); err != nil {
		log.Fatalf("Erreur lecture JSON : %v", err)
	}

	existant := extractExistant()
	ecarts := analyzeGap(besoins, existant)

	fout, err := os.Create(*output)
	if err != nil {
		log.Fatalf("Erreur création fichier : %v", err)
	}
	defer fout.Close()

	fmt.Fprintf(fout, "# Rapport d’analyse d’écart – Personas\n\n")
	fmt.Fprintf(fout, "_Date de génération : %s_\n\n", time.Now().Format("2006-01-02 15:04:05"))
	fmt.Fprintf(fout, "| Persona      | Besoins manquants                    | Commentaire           |\n")
	fmt.Fprintf(fout, "|--------------|--------------------------------------|-----------------------|\n")
	for _, e := range ecarts {
		fmt.Fprintf(fout, "| %s | %s | %s |\n", e.Persona, fmt.Sprintf("%v", e.BesoinsManquants), e.Commentaire)
	}

	fmt.Fprintf(fout, "\n---\n\n## Log d’exécution\n")
	fmt.Fprintf(fout, "- Script utilisé : go run cmd/gap-analyzer/main.go --input %s --output %s\n", *input, *output)
	fmt.Fprintf(fout, "- Fichier d’entrée : %s\n", *input)
	fmt.Fprintf(fout, "- Fichier généré : %s\n", *output)
	fmt.Fprintf(fout, "- Horodatage : %s\n", time.Now().Format(time.RFC3339))

	log.Printf("Analyse d’écart terminée. Rapport généré : %s", *output)
	fmt.Printf("Succès : rapport d’écart généré\n")
}
