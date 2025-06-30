// plan_go_mod_deletion.go
//
// Génère la liste des go.mod et go.sum secondaires à supprimer (hors racine).
// Prend en entrée les fichiers JSON listant tous les go.mod et go.sum (générés en phase 1.1).
// Produit un plan JSON et un rapport Markdown.

package plan_go_mod_deletion

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

// PlanReport stores the list of go.mod/go.sum files to delete.
type PlanReport struct {
	GoModToDelete []string `json:"go_mod_to_delete"`
	Summary       string   `json:"summary"`
}

func main() {
	inputGoModList := flag.String("input-go-mod-list", "", "Fichier JSON listant tous les go.mod")
	inputGoSumList := flag.String("input-go-sum-list", "", "Fichier JSON listant tous les go.sum")
	outputJSON := flag.String("output-json", "go_mod_to_delete.json", "Chemin du rapport JSON")
	outputMD := flag.String("output-md", "go_mod_delete_plan.md", "Chemin du rapport Markdown")

	flag.Parse()

	if *inputGoModList == "" || *inputGoSumList == "" || *outputJSON == "" || *outputMD == "" {
		fmt.Fprintln(os.Stderr, "Usage: --input-go-mod-list <file> --input-go-sum-list <file> --output-json <file> --output-md <file>")
		os.Exit(1)
	}

	report, err := RunPlan(*inputGoModList, *inputGoSumList, *outputJSON, *outputMD)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error during planning: %v\n", err)
		os.Exit(1)
	}

	// Output messages
	fmt.Printf("Plan de suppression généré : %s, %s\n", *outputJSON, *outputMD)
	fmt.Println(report.Summary)
}

// RunPlan generates the plan for deleting secondary go.mod and go.sum files.
func RunPlan(inputGoModListPath, inputGoSumListPath, outputJSONPath, outputMDPath string) (PlanReport, error) {
	var report PlanReport

	goMods, err := loadList(inputGoModListPath)
	if err != nil {
		return report, fmt.Errorf("error loading go.mod list: %w", err)
	}
	goSums, err := loadList(inputGoSumListPath)
	if err != nil {
		return report, fmt.Errorf("error loading go.sum list: %w", err)
	}

	var toDelete []string
	for _, f := range append(goMods, goSums...) {
		if !isRootFile(f) {
			toDelete = append(toDelete, f)
		}
	}
	report.GoModToDelete = toDelete

	// Ensure output directories exist
	os.MkdirAll(filepath.Dir(outputJSONPath), 0o755)
	os.MkdirAll(filepath.Dir(outputMDPath), 0o755)

	// Write JSON report
	jsonData, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return report, fmt.Errorf("error marshalling JSON: %w", err)
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

	if len(toDelete) == 0 {
		report.Summary = "Aucun fichier à supprimer. Structure déjà centralisée."
	} else {
		report.Summary = fmt.Sprintf("Plan de suppression généré pour %d fichiers.", len(toDelete))
	}

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

// isRootFile retourne true si le fichier est à la racine du repo (pas de / dans le chemin)
func isRootFile(path string) bool {
	clean := filepath.ToSlash(path)
	return !strings.Contains(clean, "/") && (strings.HasSuffix(clean, "go.mod") || strings.HasSuffix(clean, "go.sum"))
}

func generateMarkdownReport(report PlanReport) string {
	var sb strings.Builder
	sb.WriteString("# Plan de suppression des go.mod/go.sum secondaires\n\n")
	if len(report.GoModToDelete) == 0 {
		sb.WriteString("Aucun fichier à supprimer. Structure déjà centralisée.\n")
	} else {
		sb.WriteString("Les fichiers suivants doivent être supprimés (hors racine) :\n\n")
		for _, f := range report.GoModToDelete {
			sb.WriteString(fmt.Sprintf("- `%s`\n", f))
		}
	}
	return sb.String()
}
