// cmd/auto-roadmap-runner/specs.go
// Spécification détaillée des modules/fonctions d’orchestration

package main

import (
	"encoding/json"
	"fmt"
	"os"
)

type Spec struct {
	Module      string   `json:"module"`
	Description string   `json:"description"`
	Inputs      []string `json:"inputs"`
	Outputs     []string `json:"outputs"`
	Hooks       []string `json:"hooks"`
	Tests       []string `json:"tests"`
}

func main() {
	specs := []Spec{
		{
			Module:      "Inventory",
			Description: "Recense tous les artefacts, managers, workflows, logs, badges, extensions, interfaces, exceptions, synchronisations, audits.",
			Inputs:      []string{"projet/roadmaps/plans/consolidated/plan-dev-v105g.md"},
			Outputs:     []string{"inventaire-orchestration.json", "inventaire-orchestration.md"},
			Hooks:       []string{"CI/CD job inventory-orchestration"},
			Tests:       []string{"inventory_test.go"},
		},
		{
			Module:      "Gap",
			Description: "Analyse d’écart entre inventaire et besoins cibles, dépendances, synchronisations, interfaces, exceptions.",
			Inputs:      []string{"inventaire-orchestration.json", "besoins-orchestration.json"},
			Outputs:     []string{"gap-orchestration.json", "gap-orchestration.md"},
			Hooks:       []string{"CI/CD job gap-orchestration"},
			Tests:       []string{"gap_test.go"},
		},
		{
			Module:      "Needs",
			Description: "Recueil des besoins utilisateurs, techniques, d’intégration, synchronisation Roo/Kilo, reporting, rollback, notification, audits, adaptation.",
			Inputs:      []string{"projet/roadmaps/plans/consolidated/plan-dev-v105g.md"},
			Outputs:     []string{"besoins-orchestration.json", "besoins-orchestration.md"},
			Hooks:       []string{"CI/CD job needs-orchestration"},
			Tests:       []string{"needs_test.go"},
		},
		{
			Module:      "Specs",
			Description: "Spécification détaillée pour chaque besoin/module/fonction.",
			Inputs:      []string{"besoins-orchestration.json"},
			Outputs:     []string{"specs-orchestration.json", "specs-orchestration.md"},
			Hooks:       []string{"CI/CD job specs-orchestration"},
			Tests:       []string{"specs_test.go"},
		},
		{
			Module:      "Dev",
			Description: "Implémentation Go native des modules/fonctions, hooks, scripts de synchronisation.",
			Inputs:      []string{"specs-orchestration.json"},
			Outputs:     []string{"modules Go", "outputs JSON/MD", "hooks", "scripts de synchronisation"},
			Hooks:       []string{"CI/CD job build-orchestration"},
			Tests:       []string{"dev_test.go"},
		},
		{
			Module:      "Tests",
			Description: "Tests unitaires/intégration pour chaque module/fonction, synchronisation Roo/Kilo, pipeline CI/CD, audits.",
			Inputs:      []string{"modules Go"},
			Outputs:     []string{"rapports tests-orchestration.md/html", "badge coverage"},
			Hooks:       []string{"CI/CD job test-orchestration"},
			Tests:       []string{"tests_test.go"},
		},
	}

	fjson, err := os.Create("specs-orchestration.json")
	if err != nil {
		fmt.Println("Erreur création specs-orchestration.json:", err)
		return
	}
	defer fjson.Close()
	json.NewEncoder(fjson).Encode(specs)

	fmd, err := os.Create("specs-orchestration.md")
	if err != nil {
		fmt.Println("Erreur création specs-orchestration.md:", err)
		return
	}
	defer fmd.Close()
	fmt.Fprintf(fmd, "# Spécification des modules/fonctions Orchestration\n\n")
	for _, s := range specs {
		fmt.Fprintf(fmd, "## Module : %s\n", s.Module)
		fmt.Fprintf(fmd, "- Description : %s\n", s.Description)
		fmt.Fprintf(fmd, "- Inputs : %v\n", s.Inputs)
		fmt.Fprintf(fmd, "- Outputs : %v\n", s.Outputs)
		fmt.Fprintf(fmd, "- Hooks : %v\n", s.Hooks)
		fmt.Fprintf(fmd, "- Tests : %v\n\n", s.Tests)
	}
	fmt.Println("Spécification orchestration générée : specs-orchestration.json, specs-orchestration.md")
}
