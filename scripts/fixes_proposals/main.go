// scripts/fixes_proposals.go
// Génère fixes-proposals.md : proposition de correction minimale pour chaque fichier/catégorie

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

var proposals = map[string]string{
	"cycle d'import":                    "Extraire les types partagés dans un package commun pour casser le cycle d'import.",
	"fichier corrompu/EOF":              "Compléter ou supprimer le fichier, vérifier la déclaration du package.",
	"import manquant ou incorrect":      "Corriger l'import ou restaurer le package. Si besoin, exécuter la commande 'go get ...' indiquée dans le log.",
	"dépendance manquante":              "Exécuter la commande 'go get ...' indiquée dans le log pour ajouter la dépendance manquante.",
	"conflit de packages":               "Séparer les fichiers de packages différents dans des dossiers distincts.",
	"import local/relatif non supporté": "Remplacer les imports relatifs par des imports absolus compatibles Go modules.",
	"erreur de déclaration de package":  "Corriger la déclaration 'package' en tête de fichier.",
	"autre":                             "Analyse manuelle requise.",
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

	out, err := os.Create("fixes-proposals.md")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création fixes-proposals.md: %v\n", err)
		os.Exit(1)
	}
	defer out.Close()

	done := map[string]bool{}
	for _, c := range categorized {
		key := c.Category
		if !done[key] {
			fmt.Fprintf(out, "### %s\n%s\n\n", key, proposals[key])
			done[key] = true
		}
	}
	fmt.Println("Propositions de corrections générées : fixes-proposals.md")
}
