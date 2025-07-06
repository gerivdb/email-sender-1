// cmd/roadmap-indexer/main.go
package main

import (
	"fmt"
	"io/ioutil"
	"os"
)

func main() {
	files, err := ioutil.ReadDir("projet/roadmaps/plans/consolidated")
	if err != nil {
		fmt.Println("Erreur de lecture du dossier consolidated :", err)
		os.Exit(1)
	}
	var plans []string
	for _, f := range files {
		if !f.IsDir() && len(f.Name()) > 10 && f.Name()[:8] == "plan-dev" {
			plans = append(plans, f.Name())
		}
	}
	fout, err := os.Create("roadmaps_index.md")
	if err != nil {
		fmt.Println("Erreur lors de la création de l'index des roadmaps :", err)
		os.Exit(1)
	}
	defer fout.Close()
	fmt.Fprintln(fout, "# Index des roadmaps consolidées\n")
	for _, plan := range plans {
		fmt.Fprintf(fout, "- %s\n", plan)
	}
	fmt.Println("Index généré dans roadmaps_index.md")
}
