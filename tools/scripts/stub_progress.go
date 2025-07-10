// tools/scripts/stub_progress.go
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	total := 0
	stubs := 0
	var stubFiles []string
	filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if strings.HasSuffix(path, ".go") && !strings.HasSuffix(path, "_test.go") {
			total++
			f, _ := os.ReadFile(path)
			if strings.Contains(string(f), "TODO: Implémenter les fonctions nécessaires") ||
				strings.Contains(string(f), "Fichier neutralisé temporairement") {
				stubs++
				stubFiles = append(stubFiles, path)
			}
		}
		return nil
	})
	percent := 100
	if total > 0 {
		percent = 100 - (stubs * 100 / total)
	}
	report := fmt.Sprintf("# Progression du remplacement des stubs\n\n- Stubs restants : %d\n- Fichiers Go : %d\n- Progression : %d%%\n\n## Liste des stubs à remplacer\n\n", stubs, total, percent)
	report += "| Fichier | Statut |\n|---|---|\n"
	for _, f := range stubFiles {
		report += fmt.Sprintf("| %s | Stub à remplacer |\n", f)
	}
	os.WriteFile("stub_progress.md", []byte(report), 0o644)
	fmt.Println("Rapport de progression des stubs généré : stub_progress.md")
}
