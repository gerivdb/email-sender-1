// cmd/doc-generator/main.go
package main

import (
	"fmt"
	"os"
)

func main() {
	// TODO: Générer les guides, FAQ, CONTRIBUTING, README centralisés
	files := []struct {
		name string
		text string
	}{
		{"GUIDE.md", "# Guide d’Usage\n\nInstructions pour l’utilisation et la contribution au template-manager.\n"},
		{"FAQ.md", "# FAQ\n\nQuestions fréquentes et réponses sur le template-manager.\n"},
		{"CONTRIBUTING.md", "# CONTRIBUTING\n\nRègles et conseils pour contribuer au projet.\n"},
		{"README.md", "# README\n\nPrésentation du template-manager, installation, usage, documentation.\n"},
		{"README_docmanager.md", "# README DocManager\n\nDocumentation technique et usage du DocManager.\n"},
		{"guide_docmanager.md", "# Guide DocManager\n\nGuide d’utilisation et d’intégration du DocManager.\n"},
	}

	for _, f := range files {
		file, err := os.Create(f.name)
		if err != nil {
			fmt.Println("Erreur création", f.name, ":", err)
			continue
		}
		defer file.Close()
		_, err = file.WriteString(f.text)
		if err != nil {
			fmt.Println("Erreur écriture", f.name, ":", err)
		}
	}

	fmt.Println("Documentation centralisée générée (squelettes).")
}
