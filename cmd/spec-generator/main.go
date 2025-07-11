// cmd/spec-generator/main.go
package main

import (
	"fmt"
	"os"
)

func main() {
	// TODO: Générer spec_<manager>.md pour chaque manager
	f, err := os.Create("spec_docmanager.md")
	if err != nil {
		fmt.Println("Erreur création spec_docmanager.md:", err)
		return
	}
	defer f.Close()

	_, err = f.WriteString("# Spécification DocManager\n\nObjectifs, artefacts requis, formats, critères de validation à compléter.\n")
	if err != nil {
		fmt.Println("Erreur écriture spec_docmanager.md:", err)
		return
	}

	fmt.Println("spec_docmanager.md généré (squelette).")
}
