// scripts/aggregate-diagnostics.go
// Agrège les diagnostics Go/YAML/CI dans un rapport Markdown.
// Usage : go run scripts/aggregate-diagnostics.go

package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// Implémentation minimale de runAndWrite : exécute une commande et écrit la sortie dans le rapport.
func runAndWrite(report *os.File, name string, args ...string) {
	cmd := exec.Command(name, args...)
	out, err := cmd.CombinedOutput()
	report.WriteString(">>> " + name + " " + strings.Join(args, " ") + "\n")
	report.Write(out)
	if err != nil {
		report.WriteString("Erreur d'exécution : " + err.Error() + "\n")
	}
	report.WriteString("\n")
}

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
