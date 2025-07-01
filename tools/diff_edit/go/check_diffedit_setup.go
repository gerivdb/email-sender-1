package go

import (
	"fmt"
	"os"
)

// check_diffedit_setup.go : vérifie la présence et l’activation des outils d’automatisation diff Edit
func main() {
	checks := []struct {
		name, path string
	}{
		{"Hook Git pre-commit", ".git/hooks/pre-commit"},
		{"Script Go diffedit", "tools/diff_edit/go/diffedit.go"},
		{"Script Go undo", "tools/diff_edit/go/undo.go"},
		{"Script Go batch", "tools/diff_edit/go/batch_diffedit.go"},
		{"Tâches VS Code", ".vscode/tasks.json"},
	}
	fmt.Println("# Rapport d’état automatisation diff Edit\n")
	for _, c := range checks {
		if _, err := os.Stat(c.path); err == nil {
			fmt.Printf("- [x] %s : OK (%s)\n", c.name, c.path)
		} else {
			fmt.Printf("- [ ] %s : Manquant (%s)\n", c.name, c.path)
		}
	}
}
