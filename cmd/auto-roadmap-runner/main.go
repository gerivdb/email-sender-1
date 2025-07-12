// cmd/auto-roadmap-runner/main.go
package main

import (
	"fmt"
	"os"
)

// Import de migrate.go
// (Go détectera automatiquement le package main si les fichiers sont dans le même dossier)

func main() {
	// Orchestration de tous les scans, analyses, tests, rapports, feedback, sauvegardes, notifications
	f, err := os.Create("auto_roadmap_runner.log")
	if err != nil {
		fmt.Println("Erreur création auto_roadmap_runner.log:", err)
		return
	}
	defer f.Close()
	_, err = f.WriteString("Orchestration globale : scans, analyses, tests, rapports, feedback, sauvegardes, notifications.\n")
	if err != nil {
		fmt.Println("Erreur écriture auto_roadmap_runner.log:", err)
		return
	}
	fmt.Println("auto_roadmap_runner.log généré.")

	// Appel de la migration
	RunMigration()
}
