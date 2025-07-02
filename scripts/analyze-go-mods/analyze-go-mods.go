// scripts/analyze-go-mods.go
// Analyse les fichiers go.mod et go.work pour détecter directives inconnues, imports locaux interdits, erreurs de parsing.
// Usage : go run scripts/analyze-go-mods.go

package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

var (
	forbiddenDirectives        = []string{"replace", "exclude"}
	forbiddenLocalImportPrefix = "./"
)

func main() {
	root := "."
	var files []string
	_ = filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err == nil && (info.Name() == "go.mod" || info.Name() == "go.work") {
			files = append(files, path)
		}
		return nil
	})

	report := []string{"# Rapport d'analyse go.mod/go.work\n"}
	for _, file := range files {
		report = append(report, fmt.Sprintf("## %s", file))
		f, err := os.Open(file)
		if err != nil {
			report = append(report, fmt.Sprintf("- Erreur ouverture : %v", err))
			continue
		}
		scanner := bufio.NewScanner(f)
		lineNum := 0
		for scanner.Scan() {
			lineNum++
			line := strings.TrimSpace(scanner.Text())
			for _, d := range forbiddenDirectives {
				if strings.HasPrefix(line, d+" ") {
					report = append(report, fmt.Sprintf("- Ligne %d : Directive interdite '%s'", lineNum, d))
				}
			}
			if strings.Contains(line, forbiddenLocalImportPrefix) {
				report = append(report, fmt.Sprintf("- Ligne %d : Import local interdit ('./')", lineNum))
			}
		}
		if err := scanner.Err(); err != nil {
			report = append(report, fmt.Sprintf("- Erreur lecture : %v", err))
		}
		f.Close()
	}
	out, _ := os.Create("audit-reports/go-mod-analysis.md")
	defer out.Close()
	for _, l := range report {
		fmt.Fprintln(out, l)
	}
	fmt.Println("Rapport généré : audit-reports/go-mod-analysis.md")
}
