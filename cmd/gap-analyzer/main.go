// cmd/gap-analyzer/main.go
// Analyse d’écart entre inventaire et besoins cibles

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

type GapAnalysis struct {
	MissingModules      []string `json:"missing_modules"`
	MissingDependencies []string `json:"missing_dependencies"`
	MissingArtefacts    []string `json:"missing_artefacts"`
}

func main() {
	f, err := os.Open("inventaire.json")
	if err != nil {
		fmt.Println("Erreur ouverture inventaire.json:", err)
		return
	}
	defer f.Close()
	var inv Inventory
	json.NewDecoder(f).Decode(&inv)

	// Besoins cibles fictifs
	targetModules := []string{"manager-recensement", "manager-gap-analysis", "spec-generator", "reporting-final", "validate_components", "backup-modified-files", "auto-roadmap-runner", "module-x"}
	targetDependencies := []string{"github.com/gorilla/websocket", "log", "os", "encoding/json", "fmt"}
	targetArtefacts := []string{"besoins-personas.json", "gap-analysis-report.md", "user-stories.md", "specs/personas-modes-spec.md", "reporting-final.md", "validation-report.md", ".bak", "module-x-output.json"}

	missing := GapAnalysis{
		MissingModules:      diff(targetModules, inv.Modules),
		MissingDependencies: diff(targetDependencies, inv.Dependencies),
		MissingArtefacts:    diff(targetArtefacts, inv.Artefacts),
	}

	fjson, err := os.Create("gap-analysis.json")
	if err != nil {
		fmt.Println("Erreur création gap-analysis.json:", err)
		return
	}
	defer fjson.Close()
	json.NewEncoder(fjson).Encode(missing)

	fmd, err := os.Create("gap-analysis.md")
	if err != nil {
		fmt.Println("Erreur création gap-analysis.md:", err)
		return
	}
	defer fmd.Close()
	fmt.Fprintf(fmd, "# Analyse d’écart\n\n")
	fmt.Fprintf(fmd, "## Modules manquants\n")
	for _, m := range missing.MissingModules {
		fmt.Fprintf(fmd, "- %s\n", m)
	}
	fmt.Fprintf(fmd, "\n## Dépendances manquantes\n")
	for _, d := range missing.MissingDependencies {
		fmt.Fprintf(fmd, "- %s\n", d)
	}
	fmt.Fprintf(fmd, "\n## Artefacts manquants\n")
	for _, a := range missing.MissingArtefacts {
		fmt.Fprintf(fmd, "- %s\n", a)
	}
	fmt.Println("Analyse d’écart générée : gap-analysis.json, gap-analysis.md")
}

func diff(target, actual []string) []string {
	m := make(map[string]bool)
	for _, a := range actual {
		m[a] = true
	}
	var missing []string
	for _, t := range target {
		if !m[t] {
			missing = append(missing, t)
		}
	}
	return missing
}
