// tools/scripts/gap_analysis.go
package main

import (
	"fmt"
	"os"
	"strings"
)

type NeutralizedFile struct {
	Path   string `json:"path"`
	Reason string `json:"reason"`
}

func main() {
	// Lecture du rapport généré par list_neutralized.go
	data, err := os.ReadFile("neutralized_files_report.json")
	if err != nil {
		fmt.Println("Erreur : impossible de lire neutralized_files_report.json")
		os.Exit(1)
	}
	lines := strings.Split(string(data), "\n")
	var files []NeutralizedFile
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		files = append(files, NeutralizedFile{
			Path:   line,
			Reason: "Fichier neutralisé temporairement (à restaurer ou réécrire)",
		})
	}

	// Génération du rapport d'écart en Markdown
	report := "# Rapport d'écart v101\n\n"
	report += "## Fichiers neutralisés à restaurer ou réécrire\n\n"
	report += "| Fichier | Raison |\n|---|---|\n"
	for _, f := range files {
		report += fmt.Sprintf("| %s | %s |\n", f.Path, f.Reason)
	}
	report += "\n*Généré automatiquement par gap_analysis.go*\n"

	// Sauvegarde du rapport
	err = os.WriteFile("gap_analysis_v101.md", []byte(report), 0o644)
	if err != nil {
		fmt.Println("Erreur : impossible d'écrire gap_analysis_v101.md")
		os.Exit(1)
	}
	fmt.Println("Rapport d'écart généré : gap_analysis_v101.md")
}
