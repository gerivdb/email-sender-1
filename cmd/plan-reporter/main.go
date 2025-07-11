// cmd/plan-reporter/main.go
// Script Go minimal pour générer un rapport de reporting sur l’état des plans

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
	report := "# Rapport d’État des Plans\n\n| id_plan | titre | statut_migration |\n|---------|-------|------------------|\n"
	for _, l := range lines {
		if strings.HasPrefix(l, "|") && !strings.Contains(l, "id_plan") {
			report += l + "\n"
		}
	}
	ioutil.WriteFile("./projet/roadmaps/plans/consolidated/plans_report.md", []byte(report), 0o644)
	fmt.Println("Rapport d’état généré dans plans_report.md")
}
