// cmd/spec-generator/main.go
// Génération des spécifications détaillées à partir des besoins

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

type Spec struct {
	Type        string   `json:"type"`
	Description string   `json:"description"`
	Items       []string `json:"items"`
}

func main() {
	f, err := os.Open("besoins.json")
	if err != nil {
		fmt.Println("Erreur ouverture besoins.json:", err)
		return
	}
	defer f.Close()
	var besoins []Besoin
	json.NewDecoder(f).Decode(&besoins)

	var specs []Spec
	for _, b := range besoins {
		desc := fmt.Sprintf("Spécification pour %s (%s)", b.Type, b.Source)
		specs = append(specs, Spec{Type: b.Type, Description: desc, Items: b.Items})
	}

	fjson, err := os.Create("specs.json")
	if err != nil {
		fmt.Println("Erreur création specs.json:", err)
		return
	}
	defer fjson.Close()
	json.NewEncoder(fjson).Encode(specs)

	fmd, err := os.Create("specs.md")
	if err != nil {
		fmt.Println("Erreur création specs.md:", err)
		return
	}
	defer fmd.Close()
	fmt.Fprintf(fmd, "# Spécifications détaillées\n\n")
	for _, s := range specs {
		fmt.Fprintf(fmd, "## %s\n", s.Type)
		fmt.Fprintf(fmd, "%s\n", s.Description)
		for _, item := range s.Items {
			fmt.Fprintf(fmd, "- %s\n", item)
		}
		fmt.Fprintf(fmd, "\n")
	}
	fmt.Println("Spécifications générées : specs.json, specs.md")
}
