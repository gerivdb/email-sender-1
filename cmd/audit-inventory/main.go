// cmd/audit-inventory/main.go
// Recensement des modules, dépendances, artefacts du projet

package main

import (
	"encoding/json"
	"fmt"
	"os"
)

type Inventory struct {
	Modules      []string `json:"modules"`
	Dependencies []string `json:"dependencies"`
	Artefacts    []string `json:"artefacts"`
}

func main() {
	inv := Inventory{
		Modules:      []string{"manager-recensement", "manager-gap-analysis", "spec-generator", "reporting-final", "validate_components", "backup-modified-files", "auto-roadmap-runner"},
		Dependencies: []string{"github.com/gorilla/websocket", "log", "os", "encoding/json"},
		Artefacts:    []string{"besoins-personas.json", "gap-analysis-report.md", "user-stories.md", "specs/personas-modes-spec.md", "reporting-final.md", "validation-report.md", ".bak"},
	}
	fjson, err := os.Create("inventaire.json")
	if err != nil {
		fmt.Println("Erreur création inventaire.json:", err)
		return
	}
	defer fjson.Close()
	json.NewEncoder(fjson).Encode(inv)

	fmd, err := os.Create("inventaire.md")
	if err != nil {
		fmt.Println("Erreur création inventaire.md:", err)
		return
	}
	defer fmd.Close()
	fmt.Fprintf(fmd, "# Inventaire du projet\n\n")
	fmt.Fprintf(fmd, "## Modules\n")
	for _, m := range inv.Modules {
		fmt.Fprintf(fmd, "- %s\n", m)
	}
	fmt.Fprintf(fmd, "\n## Dépendances\n")
	for _, d := range inv.Dependencies {
		fmt.Fprintf(fmd, "- %s\n", d)
	}
	fmt.Fprintf(fmd, "\n## Artefacts\n")
	for _, a := range inv.Artefacts {
		fmt.Fprintf(fmd, "- %s\n", a)
	}
	fmt.Println("Inventaire généré : inventaire.json, inventaire.md")
}
