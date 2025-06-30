// generate_dep_report.go
//
// Génère un rapport détaillé des dépendances Go du monorepo (versions, chemins, licences si possible).
// Utilise "go list -m -json all" pour récupérer les infos de chaque module.

package generate_dep_report

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// GoModule represents a single Go module's information.
type GoModule struct {
	Path     string `json:"Path"`
	Version  string `json:"Version"`
	Main     bool   `json:"Main"`
	Indirect bool   `json:"Indirect,omitempty"`
	Dir      string `json:"Dir,omitempty"`
	GoMod    string `json:"GoMod,omitempty"`
}

// DependenciesReport contains the details of all Go dependencies.
type DependenciesReport struct {
	Timestamp    string     `json:"timestamp"`
	Dependencies []GoModule `json:"dependencies"`
	Summary      string     `json:"summary"`
}

func main() {
	outputJSON := flag.String("output-json", "dependencies_report.json", "Chemin du rapport JSON")
	outputMD := flag.String("output-md", "dependencies_report.md", "Chemin du rapport Markdown")
	outputSVG := flag.String("output-svg", "", "Chemin du graphique SVG (non implémenté)") // Added SVG output flag
	flag.Parse()

	if *outputJSON == "" || *outputMD == "" {
		fmt.Fprintln(os.Stderr, "Usage: --output-json <file> --output-md <file> [--output-svg <file>]")
		os.Exit(1)
	}

	report, err := RunGenerateReport(*outputJSON, *outputMD, *outputSVG)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error generating dependency report: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Rapport de dépendances généré: %s, %s\n", *outputJSON, *outputMD)
	if *outputSVG != "" {
		fmt.Printf("Graphique SVG (non implémenté) : %s\n", *outputSVG)
	}
	fmt.Println(report.Summary)
}

// RunGenerateReport generates a detailed report of Go dependencies.
func RunGenerateReport(outputJSONPath, outputMDPath, outputSVGPath string) (DependenciesReport, error) {
	var report DependenciesReport
	report.Timestamp = time.Now().Format("2006-01-02_15-04-05")

	modules, err := listGoModules()
	if err != nil {
		return report, fmt.Errorf("error retrieving Go modules: %w", err)
	}
	report.Dependencies = modules
	report.Summary = fmt.Sprintf("Report generated for %d dependencies.", len(modules))

	// Ensure output directories exist
	os.MkdirAll(filepath.Dir(outputJSONPath), 0o755)
	os.MkdirAll(filepath.Dir(outputMDPath), 0o755)
	if outputSVGPath != "" {
		os.MkdirAll(filepath.Dir(outputSVGPath), 0o755)
	}

	// Write JSON report
	jsonData, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return report, fmt.Errorf("error marshalling JSON report: %w", err)
	}
	err = ioutil.WriteFile(outputJSONPath, jsonData, 0o644)
	if err != nil {
		return report, fmt.Errorf("error writing JSON report: %w", err)
	}

	// Write Markdown report
	mdContent := generateMarkdownReport(report)
	err = ioutil.WriteFile(outputMDPath, []byte(mdContent), 0o644)
	if err != nil {
		return report, fmt.Errorf("error writing Markdown report: %w", err)
	}

	// SVG generation (placeholder)
	if outputSVGPath != "" {
		// Placeholder for SVG generation logic
		err = ioutil.WriteFile(outputSVGPath, []byte("<!-- SVG content will go here -->"), 0o644)
		if err != nil {
			return report, fmt.Errorf("error writing SVG placeholder: %w", err)
		}
	}

	return report, nil
}

// listGoModules executes "go list -m -json all" and parses the result.
func listGoModules() ([]GoModule, error) {
	cmd := exec.Command("go", "list", "-m", "-json", "all")
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("go list command failed: %w", err)
	}
	dec := json.NewDecoder(bytes.NewReader(out))
	var modules []GoModule
	for {
		var m GoModule
		if err := dec.Decode(&m); err != nil {
			if err.Error() == "EOF" { // Check for exact EOF error string
				break
			}
			return nil, fmt.Errorf("error decoding Go module JSON: %w", err)
		}
		modules = append(modules, m)
	}
	return modules, nil
}

func generateMarkdownReport(report DependenciesReport) string {
	var sb strings.Builder
	sb.WriteString("# Rapport des dépendances Go\n\n")
	sb.WriteString(fmt.Sprintf("## Résumé\n\n%s\n\n", report.Summary))
	sb.WriteString("## Dépendances\n\n")

	if len(report.Dependencies) == 0 {
		sb.WriteString("Aucune dépendance trouvée.\n")
	} else {
		for _, m := range report.Dependencies {
			mainStr := ""
			if m.Main {
				mainStr = " (module principal)"
			}
			indirectStr := ""
			if m.Indirect {
				indirectStr = " (indirect)"
			}
			sb.WriteString(fmt.Sprintf("- `%s` %s%s%s\n", m.Path, m.Version, mainStr, indirectStr))
			if m.Dir != "" {
				sb.WriteString(fmt.Sprintf("  - Répertoire: `%s`\n", m.Dir))
			}
			if m.GoMod != "" {
				sb.WriteString(fmt.Sprintf("  - Fichier go.mod: `%s`\n", m.GoMod))
			}
		}
	}
	return sb.String()
}
