// plan-harmonizer.go
// Script Go minimal pour migrer les plans existants vers la table harmonisée (plans_harmonized.md)

package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

func main() {
	dir := "./projet/roadmaps/plans/consolidated/"
	files, err := ioutil.ReadDir(dir)
	if err != nil {
		fmt.Println("Erreur lecture dossier:", err)
		os.Exit(1)
	}

	out := "| id_plan | titre | résumé | statut_migration |\n|---------|-------|--------|------------------|\n"
	for _, file := range files {
		if strings.HasPrefix(file.Name(), "plan-dev-") && strings.HasSuffix(file.Name(), ".md") {
			id := strings.TrimSuffix(file.Name(), ".md")
			titre := id
			resume := ""
			content, err := ioutil.ReadFile(dir + file.Name())
			if err == nil {
				lines := strings.Split(string(content), "\n")
				for _, l := range lines {
					if strings.HasPrefix(l, "# ") {
						titre = strings.TrimPrefix(l, "# ")
					}
					if strings.Contains(strings.ToLower(l), "objectif") || strings.Contains(strings.ToLower(l), "description") {
						resume = strings.TrimSpace(l)
					}
				}
			}
			out += fmt.Sprintf("| %s | %s | %s | à compléter |\n", id, titre, resume)
		}
	}
	ioutil.WriteFile(dir+"plans_harmonized.md", []byte("# Table Harmonisée Automatique\n\n"+out), 0o644)
	fmt.Println("Table harmonisée générée dans plans_harmonized.md")
}
