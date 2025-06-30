// delete_go_mods.go
//
// Supprime les fichiers go.mod et go.sum listés dans un fichier JSON.
// Génère un rapport JSON du succès/échec de chaque suppression.

package delete_go_mods

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
)

// DeletionResult represents the result of a single file deletion attempt.
type DeletionResult struct {
	File   string `json:"file"`
	Status string `json:"status"` // "deleted", "not_found", "error"
	Error  string `json:"error,omitempty"`
}

// DeletionReport summarizes the deletion process.
type DeletionReport struct {
	TotalAttempted int              `json:"total_attempted"`
	TotalDeleted   int              `json:"total_deleted"`
	Results        []DeletionResult `json:"results"`
	Errors         []string         `json:"errors"`
}

func main() {
	inputJSONPath := flag.String("input-json", "", "JSON file listing files to delete")
	outputReportPath := flag.String("report", "go_mod_deletion_report.json", "Path to the JSON report")
	flag.Parse()

	if *inputJSONPath == "" {
		fmt.Fprintln(os.Stderr, "Usage: --input-json <file> --report <file>")
		os.Exit(1)
	}

	err := RunDelete(*inputJSONPath, *outputReportPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error during deletion: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Deletion completed. Report: %s\n", *outputReportPath)
}

// RunDelete performs the deletion of files listed in inputJSONPath and generates a report.
func RunDelete(inputJSONPath, outputReportPath string) error {
	var report DeletionReport

	files, err := loadList(inputJSONPath)
	if err != nil {
		return fmt.Errorf("error loading file list: %w", err)
	}
	report.TotalAttempted = len(files)

	for _, f := range files {
		err := os.Remove(f)
		result := DeletionResult{File: f}
		if err == nil {
			result.Status = "deleted"
			report.TotalDeleted++
		} else if os.IsNotExist(err) {
			result.Status = "not_found"
			report.Errors = append(report.Errors, fmt.Sprintf("File %s not found: %v", f, err))
		} else {
			result.Status = "error"
			result.Error = err.Error()
			report.Errors = append(report.Errors, fmt.Sprintf("Error deleting %s: %v", f, err))
		}
		report.Results = append(report.Results, result)
	}

	// Write JSON report
	jsonData, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("error marshalling JSON report: %w", err)
	}
	err = ioutil.WriteFile(outputReportPath, jsonData, 0o644)
	if err != nil {
		return fmt.Errorf("error writing JSON report: %w", err)
	}

	if len(report.Errors) > 0 {
		return fmt.Errorf("encountered %d errors during deletion", len(report.Errors))
	}
	return nil
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
