// pkg/templategen/generate_templates.go
package main

import (
	"fmt"
	"os"
)

func main() {
	// TODO: Générer README, plan, config, test, script pour chaque manager
	files := []struct {
		name string
		text string
	}{
		{"README.md", "# README\n\nÀ compléter."},
		{"plan.md", "# Plan de développement\n\nÀ compléter."},
		{"config.yaml", "# Configuration\n\nÀ compléter."},
		{"docmanager_test.go", "// Test DocManager\n\npackage main\n\nfunc TestDocManager() {}\n"},
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

	fmt.Println("Templates générés (squelettes).")
}
