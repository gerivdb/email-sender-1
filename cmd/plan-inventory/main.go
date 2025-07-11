// plan-inventory.go
// Script Go minimal pour générer un inventaire Markdown des plans du dossier consolidated/

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

	out := "| id_plan | titre | statut_migration |\n|---------|-------|------------------|\n"
	for _, file := range files {
		if strings.HasPrefix(file.Name(), "plan-dev-") && strings.HasSuffix(file.Name(), ".md") {
			id := strings.TrimSuffix(file.Name(), ".md")
			titre := id
			content, err := ioutil.ReadFile(dir + file.Name())
			if err == nil {
				lines := strings.Split(string(content), "\n")
				for _, l := range lines {
					if strings.HasPrefix(l, "# ") {
						titre = strings.TrimPrefix(l, "# ")
						break
					}
				}
			}
			out += fmt.Sprintf("| %s | %s | à compléter |\n", id, titre)
		}
	}
	ioutil.WriteFile(dir+"plans_inventory.md", []byte("# Inventaire Automatique\n\n"+out), 0o644)
	fmt.Println("Inventaire généré dans plans_inventory.md")
}
