// scripts/report-unresolved-errors.go
// Génère un rapport Markdown/CSV listant tous les fichiers et lignes où la correction automatique a échoué.
// Usage : go run scripts/report-unresolved-errors.go

package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	root := "audit-reports"
	var files []string
	_ = filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err == nil && !info.IsDir() && (strings.HasSuffix(info.Name(), ".md") || strings.HasSuffix(info.Name(), ".txt")) {
			files = append(files, path)
		}
		return nil
	})

	report := []string{"# Rapport des erreurs non corrigées"}
	for _, file := range files {
		f, err := os.Open(file)
		if err != nil {
			continue
		}
		defer f.Close()
		scanner := bufio.NewScanner(f)
		for scanner.Scan() {
			line := scanner.Text()
			if strings.Contains(line, "Erreur") || strings.Contains(line, "non valide") || strings.Contains(line, "non corrigée") {
				report = append(report, fmt.Sprintf("- [%s] %s", file, line))
			}
		}
	}

	_ = os.MkdirAll("audit-reports", 0755)
	out, _ := os.Create("audit-reports/unresolved-errors.md")
	defer out.Close()
	for _, l := range report {
		fmt.Fprintln(out, l)
	}
	fmt.Println("Rapport généré : audit-reports/unresolved-errors.md")
}
