// scripts/explain_error_causes.go
// Génère un fichier Markdown expliquant la cause de chaque catégorie d’erreur

package main

import (
	"encoding/json"
	"fmt"
	"os"
)

type Categorized struct {
	Category string `json:"category"`
	Error    struct {
		Message string `json:"message"`
	} `json:"error"`
}

var explanations = map[string]string{
	"cycle d'import":               "Dépendances croisées entre packages Go, causant un cycle d'import non autorisé. Solution : extraire les types partagés dans un package commun.",
	"fichier corrompu/EOF":         "Fichier Go incomplet, tronqué ou corrompu (souvent après un merge ou une suppression). Solution : compléter ou supprimer le fichier, vérifier la déclaration du package.",
	"import manquant ou incorrect": "Import d'un package inexistant, mal orthographié ou supprimé. Solution : corriger l'import ou restaurer le package.",
	"dépendance manquante":         "Module Go requis non présent dans go.mod. Solution : exécuter 'go get' pour ajouter la dépendance.",
	"autre":                        "Erreur non catégorisée automatiquement. Analyse manuelle requise.",
}

func main() {
	f, err := os.Open("errors-categorized.json")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur ouverture errors-categorized.json: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()

	var categorized []Categorized
	dec := json.NewDecoder(f)
	if err := dec.Decode(&categorized); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur parsing JSON: %v\n", err)
		os.Exit(1)
	}

	out, err := os.Create("causes-by-error.md")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création causes-by-error.md: %v\n", err)
		os.Exit(1)
	}
	defer out.Close()

	done := map[string]bool{}
	for _, c := range categorized {
		if !done[c.Category] {
			fmt.Fprintf(out, "### %s\n%s\n\n", c.Category, explanations[c.Category])
			done[c.Category] = true
		}
	}
	fmt.Println("Explications Markdown générées : causes-by-error.md")
}
