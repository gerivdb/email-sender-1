// scripts/aggregate-diagnostics.go
// Agrège les diagnostics Go/YAML/CI dans un rapport Markdown.
// Usage : go run scripts/aggregate-diagnostics.go

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	reportPath := "audit-reports/diagnostics-report.md"
	_ = os.MkdirAll("audit-reports", 0755)
	report, err := os.Create(reportPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur création rapport : %v\n", err)
		os.Exit(1)
	}
	defer report.Close()

	fmt.Fprintln(report, "# Rapport d’audit automatisé")
	fmt.Fprintln(report, "## Diagnostics Go (golangci-lint)")
	fmt.Fprintln(report, "```")
	runAndWrite(report, "golangci-lint", "run", "./...")
	fmt.Fprintln(report, "```")

	fmt.Fprintln(report, "## Diagnostics Go Vet")
	fmt.Fprintln(report, "```")
	runAndWrite(report, "go", "vet", "./...")
	fmt.Fprintln(report, "```")

	fmt.Fprintln(report, "## Diagnostics YAML")
	fmt.Fprintln(report, "```")
	filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err == nil && !info.IsDir() && (strings.HasSuffix(info.Name(), ".yaml") || strings.HasSuffix(info.Name(), ".yml")) {
			fmt.Fprintf(report, "Fichier : %s\n", path)
			runAndWrite(report, "go", "run", "scripts/lint-yaml.go")
		}
		return nil
	})
	fmt.Fprintln(report, "```")

	fmt.Printf("Rapport généré : %s\n", reportPath)
}

func runAndWrite(report *os.File, cmd string, args ...string) {
	c := cmd + " " + strings.Join(args, " ")
	out, err := os.Command(cmd, args...).CombinedOutput()
	if err != nil {
		fmt.Fprintf(report, "%s\n[ERREUR] %v\n", c, err)
	}
	report.Write(out)
}
