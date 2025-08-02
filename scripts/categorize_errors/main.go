// scripts/categorize_errors.go
// Catégorisation des erreurs Go extraites pour diagnostic avancé

package main

import (
	"encoding/json"
	"fmt"
	"os"
	"regexp"
)

type BuildError struct {
	Message string `json:"message"`
}

type Categorized struct {
	Category string     `json:"category"`
	Error    BuildError `json:"error"`
}

func main() {
	f, err := os.Open("errors-extracted.json")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur ouverture errors-extracted.json: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()

	var raw []BuildError
	dec := json.NewDecoder(f)
	if err := dec.Decode(&raw); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur parsing JSON: %v\n", err)
		os.Exit(1)
	}

	var categorized []Categorized

	for _, e := range raw {
		cat := "autre"
		switch {
		case regexp.MustCompile(`import cycle not allowed`).MatchString(e.Message):
			cat = "cycle d'import"
		case regexp.MustCompile(`expected 'package'`).MatchString(e.Message):
			cat = "fichier corrompu/EOF"
		case regexp.MustCompile(`not in std`).MatchString(e.Message):
			cat = "import manquant ou incorrect"
		case regexp.MustCompile(`no required module provides package`).MatchString(e.Message):
			cat = "dépendance manquante"
		}
		categorized = append(categorized, Categorized{Category: cat, Error: e})
	}

	out, err := os.Create("errors-categorized.json")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création errors-categorized.json: %v\n", err)
		os.Exit(1)
	}
	defer out.Close()
	enc := json.NewEncoder(out)
	enc.SetIndent("", "  ")
	if err := enc.Encode(categorized); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur écriture JSON: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Catégorisation terminée. %d erreurs catégorisées.\n", len(categorized))
}
