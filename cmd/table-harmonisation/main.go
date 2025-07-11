// cmd/table-harmonisation/main.go
package main

import (
	"fmt"
	"os"
)

func main() {
	// TODO: Générer la table harmonisée plans_harmonized.md
	f, err := os.Create("plans_harmonized.md")
	if err != nil {
		fmt.Println("Erreur création plans_harmonized.md:", err)
		return
	}
	defer f.Close()

	_, err = f.WriteString("# Table Harmonisée des Plans Dev\n\n| id_plan | titre | format | granularité | conformité | statut |\n|---------|-------|--------|-------------|------------|--------|\n| ...     | ...   | ...    | ...         | ...        | ...    |\n")
	if err != nil {
		fmt.Println("Erreur écriture plans_harmonized.md:", err)
		return
	}

	fmt.Println("plans_harmonized.md généré (squelette).")
}
