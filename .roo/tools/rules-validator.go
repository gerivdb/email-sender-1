package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Println("Validation sémantique des règles Roo-Code...")

	rulesFiles := []string{
		".roo/rules/rules.md",
		".roo/rules/rules-agents.md",
		".roo/rules/rules-code.md",
		".roo/rules/rules-debug.md",
		".roo/rules/rules-documentation.md",
		".roo/rules/rules-maintenance.md",
		".roo/rules/rules-migration.md",
		".roo/rules/rules-orchestration.md",
		".roo/rules/rules-plugins.md",
		".roo/rules/rules-security.md",
		".roo/rules/workflows-matrix.md",
	}

	allFilesExist := true
	for _, file := range rulesFiles {
		if _, err := os.Stat(file); os.IsNotExist(err) {
			fmt.Printf("Erreur : Le fichier de règles '%s' n'existe pas.\n", file)
			allFilesExist = false
		}
	}

	if !allFilesExist {
		os.Exit(1)
	}

	fmt.Println("Tous les fichiers de règles existent. Validation de base réussie.")
	// D'autres logiques de validation sémantique plus complexes peuvent être ajoutées ici.
}
