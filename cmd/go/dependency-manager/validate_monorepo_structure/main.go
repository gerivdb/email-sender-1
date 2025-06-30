// validate_monorepo_structure.go
//
// Vérifie qu'il ne reste qu'un seul go.mod à la racine, exécute go mod tidy et go build ./...,
// et génère un rapport JSON de validation.

package validate_monorepo_structure

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// ValidationReport stores the results of the monorepo validation.
type ValidationReport struct {
	GoModCount      int      `json:"go_mod_count"`
	GoModPaths      []string `json:"go_mod_paths"`
	GoModTidyOK     bool     `json:"go_mod_tidy_ok"`
	GoModTidyOutput string   `json:"go_mod_tidy_output"`
	GoBuildOK       bool     `json:"go_build_ok"`
	GoBuildOutput   string   `json:"go_build_output"`
	IsValid         bool     `json:"is_valid"`
}

func main() {
	outputJSON := flag.String("output-json", "monorepo_structure_validation.json", "Path to the JSON report")
	flag.Parse()

	report, err := RunValidation()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Validation failed: %v\n", err)
		os.Exit(1)
	}

	// Write JSON report
	f, err := os.Create(*outputJSON)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating JSON report: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()
	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	enc.Encode(report)

	if report.IsValid {
		fmt.Println("Validation OK: Monorepo structure is correct.")
	} else {
		fmt.Println("Validation failed. See report for details.")
		os.Exit(1)
	}
}

// RunValidation performs the monorepo structure validation.
func RunValidation() (ValidationReport, error) {
	var report ValidationReport

	// Search for go.mod files
	var goModPaths []string
	err := filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && filepath.Base(path) == "go.mod" {
			goModPaths = append(goModPaths, path)
		}
		return nil
	})
	if err != nil {
		return report, fmt.Errorf("error walking files: %w", err)
	}
	report.GoModPaths = goModPaths
	report.GoModCount = len(goModPaths)

	// Run go mod tidy
	tidyOut, tidyErr := runCmd("go", "mod", "tidy")
	report.GoModTidyOutput = tidyOut
	report.GoModTidyOK = tidyErr == nil

	// Run go build ./...
	buildOut, buildErr := runCmd("go", "build", "./...")
	report.GoBuildOutput = buildOut
	report.GoBuildOK = buildErr == nil

	// Success criteria
	report.IsValid = (report.GoModCount == 1 && report.GoModTidyOK && report.GoBuildOK)

	if !report.IsValid {
		return report, fmt.Errorf("monorepo structure validation failed")
	}

	return report, nil
}

func runCmd(name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	out, err := cmd.CombinedOutput()
	return strings.TrimSpace(string(out)), err
}
