// cmd/auto-roadmap-runner/needs.go
// Recueil des besoins d’orchestration

package main

import (
	"encoding/json"
	"fmt"
	"os"
)

type Needs struct {
	Utilisateurs []string `json:"utilisateurs"`
	Techniques   []string `json:"techniques"`
	Integration  []string `json:"integration"`
	SyncRooKilo  []string `json:"sync_roo_kilo"`
	Reporting    []string `json:"reporting"`
	Rollback     []string `json:"rollback"`
	Notification []string `json:"notification"`
	Audits       []string `json:"audits"`
	Adaptation   []string `json:"adaptation"`
}

func main() {
	needs := Needs{
		Utilisateurs: []string{"dashboard CI/CD", "feedback automatisé", "logs centralisés"},
		Techniques:   []string{"Go natif", "pipeline YAML", "tests automatisés"},
		Integration:  []string{"API", "CLI", "PluginInterface"},
		SyncRooKilo:  []string{"état partagé", "notification croisée"},
		Reporting:    []string{"reporting consolidé", "badges"},
		Rollback:     []string{"sauvegarde .bak", "restauration automatisée"},
		Notification: []string{"hook notification", "alerte CI/CD"},
		Audits:       []string{"audit backup", "audit sync"},
		Adaptation:   []string{"adaptation dynamique", "phase d’ajustement"},
	}
	fjson, err := os.Create("besoins-orchestration.json")
	if err != nil {
		fmt.Println("Erreur création besoins-orchestration.json:", err)
		return
	}
	defer fjson.Close()
	json.NewEncoder(fjson).Encode(needs)

	fmd, err := os.Create("besoins-orchestration.md")
	if err != nil {
		fmt.Println("Erreur création besoins-orchestration.md:", err)
		return
	}
	defer fmd.Close()
	fmt.Fprintf(fmd, "# Recueil des besoins Orchestration\n\n")
	fmt.Fprintf(fmd, "## Utilisateurs\n")
	for _, u := range needs.Utilisateurs {
		fmt.Fprintf(fmd, "- %s\n", u)
	}
	fmt.Fprintf(fmd, "\n## Techniques\n")
	for _, t := range needs.Techniques {
		fmt.Fprintf(fmd, "- %s\n", t)
	}
	fmt.Fprintf(fmd, "\n## Intégration\n")
	for _, i := range needs.Integration {
		fmt.Fprintf(fmd, "- %s\n", i)
	}
	fmt.Fprintf(fmd, "\n## Synchronisation Roo/Kilo\n")
	for _, s := range needs.SyncRooKilo {
		fmt.Fprintf(fmd, "- %s\n", s)
	}
	fmt.Fprintf(fmd, "\n## Reporting\n")
	for _, r := range needs.Reporting {
		fmt.Fprintf(fmd, "- %s\n", r)
	}
	fmt.Fprintf(fmd, "\n## Rollback\n")
	for _, rb := range needs.Rollback {
		fmt.Fprintf(fmd, "- %s\n", rb)
	}
	fmt.Fprintf(fmd, "\n## Notification\n")
	for _, n := range needs.Notification {
		fmt.Fprintf(fmd, "- %s\n", n)
	}
	fmt.Fprintf(fmd, "\n## Audits\n")
	for _, a := range needs.Audits {
		fmt.Fprintf(fmd, "- %s\n", a)
	}
	fmt.Fprintf(fmd, "\n## Adaptation\n")
	for _, ad := range needs.Adaptation {
		fmt.Fprintf(fmd, "- %s\n", ad)
	}
	fmt.Println("Recueil des besoins orchestration généré : besoins-orchestration.json, besoins-orchestration.md")
}
