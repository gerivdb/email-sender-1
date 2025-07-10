// tools/scripts/gen_docs_and_archive.go
package main

import (
	"fmt"
	"os"
	"os/exec"
)

func main() {
	fmt.Println("=== Génération de la documentation technique ===")
	readme := "README.md"
	archi := "docs/architecture.md"
	os.MkdirAll("docs", 0o755)
	os.WriteFile(readme, []byte("# Documentation projet v101\n\nÀ compléter."), 0o644)
	os.WriteFile(archi, []byte("# Architecture v101\n\nÀ compléter."), 0o644)
	fmt.Println("README.md et docs/architecture.md générés.")

	fmt.Println("\n=== Archivage des livrables ===")
	os.MkdirAll("archive/v101", 0o755)
	files := []string{
		"neutralized_files_report.json",
		"gap_analysis_v101.md",
		"restauration_needs_v101.md",
		"restauration_specs_v101.md",
		"coverage_report.html",
		"build_report.md",
	}
	for _, f := range files {
		if _, err := os.Stat(f); err == nil {
			cmd := exec.Command("cp", f, "archive/v101/")
			cmd.Run()
			fmt.Println("Archivé :", f)
		}
	}
	fmt.Println("Archivage terminé.")
}
