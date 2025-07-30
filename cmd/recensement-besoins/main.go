// cmd/recensement-besoins/main.go
// Recueil des besoins utilisateurs, techniques, d’intégration

package main

import (
	"encoding/json"
	"fmt"
	"os"
)

type Besoin struct {
	Type   string   `json:"type"`
	Items  []string `json:"items"`
	Source string   `json:"source"`
}

func main() {
	besoins := []Besoin{
		{Type: "utilisateur", Items: []string{"Interface claire", "Feedback", "Support"}, Source: "questionnaires"},
		{Type: "technique", Items: []string{"Tests unitaires", "Documentation", "API REST"}, Source: "AGENTS.md"},
		{Type: "intégration", Items: []string{"Interopérabilité", "Formats JSON/CSV"}, Source: "audit-modules"},
	}
	fjson, err := os.Create("besoins.json")
	if err != nil {
		fmt.Println("Erreur création besoins.json:", err)
		return
	}
	defer fjson.Close()
	json.NewEncoder(fjson).Encode(besoins)

	fmd, err := os.Create("besoins.md")
	if err != nil {
		fmt.Println("Erreur création besoins.md:", err)
		return
	}
	defer fmd.Close()
	fmt.Fprintf(fmd, "# Recueil des besoins\n\n")
	for _, b := range besoins {
		fmt.Fprintf(fmd, "## %s\n", b.Type)
		for _, item := range b.Items {
			fmt.Fprintf(fmd, "- %s\n", item)
		}
		fmt.Fprintf(fmd, "_Source : %s_\n\n", b.Source)
	}
	fmt.Println("Recueil des besoins généré : besoins.json, besoins.md")
}
