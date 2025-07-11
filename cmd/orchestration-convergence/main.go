// orchestration-convergence.go
// Script Go minimal pour détecter les conflits d’orchestration dans les plans harmonisés

package main

import (
	"fmt"
	"io/ioutil"
	"strings"
)

func main() {
	file := "./projet/roadmaps/plans/consolidated/plans_harmonized.md"
	content, err := ioutil.ReadFile(file)
	if err != nil {
		fmt.Println("Erreur lecture plans_harmonized.md:", err)
		return
	}
	lines := strings.Split(string(content), "\n")
	conflicts := []string{}
	for _, l := range lines {
		if strings.Contains(strings.ToLower(l), "conflit") || strings.Contains(strings.ToLower(l), "doublon") {
			conflicts = append(conflicts, l)
		}
	}
	report := "# Rapport de Conflits d’Orchestration\n\n"
	if len(conflicts) == 0 {
		report += "Aucun conflit détecté dans la table harmonisée.\n"
	} else {
		report += "Conflits détectés :\n"
		for _, c := range conflicts {
			report += "- " + c + "\n"
		}
	}
	ioutil.WriteFile("./projet/roadmaps/plans/consolidated/orchestration_conflicts_report.md", []byte(report), 0o644)
	fmt.Println("Rapport de conflits généré dans orchestration_conflicts_report.md")
}
