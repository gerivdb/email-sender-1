// cmd/module/main.go
// Implémentation d'une spécification en module Go natif

package main

import (
	"encoding/json"
	"fmt"
	"os"
)

type Output struct {
	Type   string   `json:"type"`
	Status string   `json:"status"`
	Items  []string `json:"items"`
}

func main() {
	output := Output{
		Type:   "utilisateur",
		Status: "implémenté",
		Items:  []string{"Interface claire", "Feedback", "Support"},
	}
	fjson, err := os.Create("module-output.json")
	if err != nil {
		fmt.Println("Erreur création module-output.json:", err)
		return
	}
	defer fjson.Close()
	json.NewEncoder(fjson).Encode(output)

	fmd, err := os.Create("module-output.md")
	if err != nil {
		fmt.Println("Erreur création module-output.md:", err)
		return
	}
	defer fmd.Close()
	fmt.Fprintf(fmd, "# Module utilisateur\n\n")
	fmt.Fprintf(fmd, "Statut : %s\n", output.Status)
	for _, item := range output.Items {
		fmt.Fprintf(fmd, "- %s\n", item)
	}
	fmt.Println("Module Go natif généré : module-output.json, module-output.md")
}
