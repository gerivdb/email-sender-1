// cmd/reporting/main.go
package main

import (
	"fmt"
	"os"
)

func main() {
	// TODO: Générer le rapport de conformité et changelog
	f, err := os.Create("conformity_report.md")
	if err != nil {
		fmt.Println("Erreur création conformity_report.md:", err)
		return
	}
	defer f.Close()

	_, err = f.WriteString("# Rapport de Conformité\n\n- Taux de conformité des artefacts\n- Historique des validations\n- Changements majeurs\n")
	if err != nil {
		fmt.Println("Erreur écriture conformity_report.md:", err)
		return
	}

	fmt.Println("conformity_report.md généré (squelette).")
}
