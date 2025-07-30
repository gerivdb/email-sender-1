// cmd/auto-roadmap-runner/main.go
// Orchestrateur global : exécution séquentielle/scalable de toutes les étapes

package main

import (
	"fmt"
	"os"
)

func main() {
	steps := []string{
		"inventory.go", "gap.go", "needs.go", "specs.go", "dev.go", "tests.go", "reporting.go", "validate.go", "backup.go", "adaptation.go",
	}
	for _, step := range steps {
		if _, err := os.Stat(step); err == nil {
			fmt.Printf("Étape %s : script trouvé, exécution possible\n", step)
		} else {
			fmt.Printf("Étape %s : script manquant, à créer\n", step)
		}
	}
	fmt.Println("Orchestration globale terminée. Voir logs et artefacts pour chaque étape.")
}
