// cmd/inventory-generator/main.go
package main

import (
	"fmt"
	"os"
)

func main() {
	// TODO: Générer l’inventaire dynamique plans_inventory.md
	f, err := os.Create("plans_inventory.md")
	if err != nil {
		fmt.Println("Erreur création plans_inventory.md:", err)
		return
	}
	defer f.Close()

	_, err = f.WriteString("# Inventaire Dynamique des Plans Dev\n\n| id_plan | titre | format | granularité | conformité | statut |\n|---------|-------|--------|-------------|------------|--------|\n| ...     | ...   | ...    | ...         | ...        | ...    |\n")
	if err != nil {
		fmt.Println("Erreur écriture plans_inventory.md:", err)
		return
	}

	fmt.Println("plans_inventory.md généré (squelette).")
}
