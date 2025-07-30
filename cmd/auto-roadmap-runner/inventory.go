// cmd/auto-roadmap-runner/inventory.go
// Recensement des artefacts, managers, workflows, logs, badges, points d’extension, interfaces Roo/Kilo

package main

import (
	"encoding/json"
	"fmt"
	"os"
)

type Inventory struct {
	Artefacts        []string `json:"artefacts"`
	Managers         []string `json:"managers"`
	Workflows        []string `json:"workflows"`
	Logs             []string `json:"logs"`
	Badges           []string `json:"badges"`
	Extensions       []string `json:"extensions"`
	Interfaces       []string `json:"interfaces"`
	Exceptions       []string `json:"exceptions"`
	Synchronisations []string `json:"synchronisations"`
	Audits           []string `json:"audits"`
}

func InventoryCmd() {
	inv := Inventory{
		Artefacts:        []string{"besoins.json", "specs.json", "module-output.json", "reporting.md", "validation.md"},
		Managers:         []string{"BackupManager", "OrchestrationManager", "MaintenanceManager"},
		Workflows:        []string{"CI/CD", "Reporting", "Rollback", "Validation"},
		Logs:             []string{"rollback.log", "ci.log"},
		Badges:           []string{"coverage", "reporting", "validation"},
		Extensions:       []string{"hook notification", "plugin sync"},
		Interfaces:       []string{"API", "CLI", "PluginInterface"},
		Exceptions:       []string{"cas limite backup", "cas limite sync"},
		Synchronisations: []string{"Roo/Kilo sync", "reporting sync"},
		Audits:           []string{"audit_backup.go", "audit_sync.go"},
	}
	fjson, err := os.Create("inventaire-orchestration.json")
	if err != nil {
		fmt.Println("Erreur création inventaire-orchestration.json:", err)
		return
	}
	defer fjson.Close()
	json.NewEncoder(fjson).Encode(inv)

	fmd, err := os.Create("inventaire-orchestration.md")
	if err != nil {
		fmt.Println("Erreur création inventaire-orchestration.md:", err)
		return
	}
	defer fmd.Close()
	fmt.Fprintf(fmd, "# Inventaire Orchestration\n\n")
	fmt.Fprintf(fmd, "## Artefacts\n")
	for _, a := range inv.Artefacts {
		fmt.Fprintf(fmd, "- %s\n", a)
	}
	fmt.Fprintf(fmd, "\n## Managers\n")
	for _, m := range inv.Managers {
		fmt.Fprintf(fmd, "- %s\n", m)
	}
	fmt.Fprintf(fmd, "\n## Workflows\n")
	for _, w := range inv.Workflows {
		fmt.Fprintf(fmd, "- %s\n", w)
	}
	fmt.Fprintf(fmd, "\n## Logs\n")
	for _, l := range inv.Logs {
		fmt.Fprintf(fmd, "- %s\n", l)
	}
	fmt.Fprintf(fmd, "\n## Badges\n")
	for _, b := range inv.Badges {
		fmt.Fprintf(fmd, "- %s\n", b)
	}
	fmt.Fprintf(fmd, "\n## Extensions\n")
	for _, e := range inv.Extensions {
		fmt.Fprintf(fmd, "- %s\n", e)
	}
	fmt.Fprintf(fmd, "\n## Interfaces\n")
	for _, i := range inv.Interfaces {
		fmt.Fprintf(fmd, "- %s\n", i)
	}
	fmt.Fprintf(fmd, "\n## Exceptions\n")
	for _, ex := range inv.Exceptions {
		fmt.Fprintf(fmd, "- %s\n", ex)
	}
	fmt.Fprintf(fmd, "\n## Synchronisations\n")
	for _, s := range inv.Synchronisations {
		fmt.Fprintf(fmd, "- %s\n", s)
	}
	fmt.Fprintf(fmd, "\n## Audits\n")
	for _, au := range inv.Audits {
		fmt.Fprintf(fmd, "- %s\n", au)
	}
	fmt.Println("Inventaire orchestration généré : inventaire-orchestration.json, inventaire-orchestration.md")
}
