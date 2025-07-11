// cmd/manager-recensement/main.go
package main

import (
	"encoding/json"
	"fmt"
	"os"
)

type ManagerArtefact struct {
	Name  string   `json:"name"`
	Paths []string `json:"paths"`
}

type Recensement struct {
	Managers []ManagerArtefact `json:"managers"`
}

func main() {
	// TODO: Scanner AGENTS.md et l’arborescence du dépôt
	recensement := Recensement{
		Managers: []ManagerArtefact{
			{Name: "DocManager", Paths: []string{"docs/", "README.md"}},
			{Name: "ErrorManager", Paths: []string{"errors/", "error.log"}},
			// Ajouter les autres managers ici
		},
	}

	file, err := os.Create("recensement.json")
	if err != nil {
		fmt.Println("Erreur création fichier:", err)
		return
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(recensement); err != nil {
		fmt.Println("Erreur encodage JSON:", err)
		return
	}

	fmt.Println("recensement.json généré avec succès.")
}
