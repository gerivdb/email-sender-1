// cmd/global-tracker/main.go
package main

import (
	"fmt"
	"os"
)

func main() {
	// Générer le tableau de suivi global pour chaque manager et chaque étape
	f, err := os.Create("tableau_suivi_global.md")
	if err != nil {
		fmt.Println("Erreur création tableau_suivi_global.md:", err)
		return
	}
	defer f.Close()

	_, err = f.WriteString(`# Tableau de suivi global

| Manager      | Recensement | Gap Analysis | Spec | Templates | Dev Tools | Structure | Tests | Docs | Review | CI/CD | Dépendances | Archivage | Reporting |
|--------------|-------------|--------------|------|-----------|-----------|-----------|-------|------|--------|-------|-------------|-----------|-----------|
| DocManager   | [x]         | [x]          | [x]  | [x]       | [x]       | [x]       | [x]   | [x]  | [x]    | [x]   | [x]         | [ ]       | [ ]       |
| ErrorManager | [ ]         | [ ]          | [ ]  | [ ]       | [ ]       | [ ]       | [ ]   | [ ]  | [ ]    | [ ]   | [ ]         | [ ]       | [ ]       |
| ...          | ...         | ...          | ...  | ...       | ...       | ...       | ...   | ...  | ...    | ...   | ...         | ...       | ...       |

*(Compléter pour chaque manager et chaque étape)*
`)
	if err != nil {
		fmt.Println("Erreur écriture tableau_suivi_global.md:", err)
		return
	}

	fmt.Println("tableau_suivi_global.md généré (squelette).")
}
