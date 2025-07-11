// cmd/test-runner/main.go
package main

import (
	"fmt"
	"os"
)

func main() {
	// Lancer tous les tests et générer le rapport de couverture
	f, err := os.Create("coverage_docmanager.out")
	if err != nil {
		fmt.Println("Erreur création coverage_docmanager.out:", err)
		return
	}
	defer f.Close()
	_, err = f.WriteString("Test runner : exécution des tests et reporting (à compléter).\n")
	if err != nil {
		fmt.Println("Erreur écriture coverage_docmanager.out:", err)
		return
	}
	fmt.Println("coverage_docmanager.out généré.")
}
