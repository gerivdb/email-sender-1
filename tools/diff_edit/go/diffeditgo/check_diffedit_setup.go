// Go
// Package diffeditgo fournit des outils pour automatiser l'application de patchs.
package diffeditgo

import (
	"fmt"
	"os"
)

// CheckDiffEditSetup vérifie la présence et l’activation des outils d’automatisation diff Edit.
func CheckDiffEditSetup() {
	checks := []struct {
		name, path string
	}{
		{"Hook Git pre-commit", ".git/hooks/pre-commit"},
		{"Bibliothèque Go", "tools/diff_edit/go/diffeditgo/"},
		{"Exécutable Go", "tools/diff_edit/go/main.go"},
		{"Tâches VS Code", ".vscode/tasks.json"},
	}
	fmt.Println("# Rapport d’état automatisation diff Edit")
	fmt.Println()
	for _, c := range checks {
		if _, err := os.Stat(c.path); err == nil {
			fmt.Printf("- [x] %s : OK (%s)\n", c.name, c.path)
		} else {
			fmt.Printf("- [ ] %s : Manquant (%s)\n", c.name, c.path)
		}
	}
}
