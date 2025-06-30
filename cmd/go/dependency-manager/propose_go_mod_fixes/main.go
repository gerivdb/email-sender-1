// propose_go_mod_fixes.go
//
// Prend en entrée la liste des go.mod parasites (JSON), génère un script shell pour les supprimer,
// un plan d'action JSON, et (optionnel) un patch pour ajuster les imports si besoin.

package propose_go_mod_fixes

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

// FixPlanReport contains the proposed fixes.
type FixPlanReport struct {
	FilesToDelete []string `json:"files_to_delete"`
	FilesToModify []string `json:"files_to_modify"` // Not implemented yet, but good for future extension
	Summary       string   `json:"summary"`
}

func main() {
	inputJSONPath := flag.String("input-json", "", "JSON file listing parasitic go.mod files")
	outputScriptPath := flag.String("output-script", "fix_go_mod_parasites.sh", "Shell script for deletion")
	outputPatchPath := flag.String("output-patch", "fix_go_mod_parasites.patch", "Patch file for import adjustments (not implemented)")
	outputJSONReportPath := flag.String("output-json-report", "go_mod_fix_plan.json", "JSON report path")
	flag.Parse()

	if *inputJSONPath == "" || *outputScriptPath == "" || *outputJSONReportPath == "" {
		fmt.Fprintln(os.Stderr, "Usage: --input-json <file> --output-script <file> --output-json-report <file>")
		os.Exit(1)
	}

	report, err := RunProposeFixes(*inputJSONPath, *outputScriptPath, *outputPatchPath, *outputJSONReportPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error proposing fixes: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Script de suppression et plan générés: %s, %s\n", *outputScriptPath, *outputJSONReportPath)
	fmt.Println(report.Summary)
}

// RunProposeFixes reads parasitic go.mod files, generates a deletion script, and a fix plan.
func RunProposeFixes(inputJSONPath, outputScriptPath, outputPatchPath, outputJSONReportPath string) (FixPlanReport, error) {
	var report FixPlanReport

	// Read list of files to delete
	files, err := loadList(inputJSONPath)
	if err != nil {
		return report, fmt.Errorf("error loading input file: %w", err)
	}
	report.FilesToDelete = files

	// Generate shell script for deletion
	scriptContent := new(strings.Builder)
	scriptContent.WriteString("#!/bin/bash\nset -e\n\n")
	for _, file := range files {
		scriptContent.WriteString(fmt.Sprintf("echo \"Suppression de %s\"\n", file))
		scriptContent.WriteString(fmt.Sprintf("rm \"%s\"\n", file))
	}
	scriptContent.WriteString("echo \"Suppression terminée.\"\n")

	err = ioutil.WriteFile(outputScriptPath, []byte(scriptContent.String()), 0o755)
	if err != nil {
		return report, fmt.Errorf("error writing deletion script: %w", err)
	}

	// Generate dummy patch file (not implemented yet)
	if outputPatchPath != "" {
		err = ioutil.WriteFile(outputPatchPath, []byte("<!-- Patch content for import adjustments will go here -->"), 0o644)
		if err != nil {
			return report, fmt.Errorf("error writing patch file: %w", err)
		}
	}

	// Generate JSON report
	jsonData, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return report, fmt.Errorf("error marshalling JSON report: %w", err)
	}
	err = ioutil.WriteFile(outputJSONReportPath, jsonData, 0o644)
	if err != nil {
		return report, fmt.Errorf("error writing JSON report: %w", err)
	}

	report.Summary = fmt.Sprintf("Proposed fixes generated for %d files.", len(files))
	return report, nil
}

func loadList(path string) ([]string, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("error opening %s: %w", path, err)
	}
	defer f.Close()
	var list []string
	dec := json.NewDecoder(f)
	if err := dec.Decode(&list); err != nil {
		return nil, fmt.Errorf("error decoding JSON %s: %w", path, err)
	}
	return list, nil
}
