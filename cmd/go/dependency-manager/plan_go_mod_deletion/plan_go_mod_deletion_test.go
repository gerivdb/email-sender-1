package plan_go_mod_deletion_test

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/gerivdb/email-sender-1/cmd/go/dependency-manager/plan_go_mod_deletion"
)

func TestPlanGoModDeletion(t *testing.T) {
	// Create a temporary directory for testing
	tmpDir, err := ioutil.TempDir("", "test_plan_deletion")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create dummy go.mod and go.sum lists from a previous audit
	initialGoModListContent := `[
		"go.mod",
		"submodule/go.mod",
		"another_module/go.mod"
	]`
	initialGoSumListContent := `[
		"go.sum",
		"submodule/go.sum",
		"another_module/go.sum"
	]`

	initialGoModListPath := filepath.Join(tmpDir, "initial_go_mod_list.json")
	initialGoSumListPath := filepath.Join(tmpDir, "initial_go_sum_list.json")

	err = ioutil.WriteFile(initialGoModListPath, []byte(initialGoModListContent), 0o644)
	if err != nil {
		t.Fatalf("Failed to write initial_go_mod_list.json: %v", err)
	}
	err = ioutil.WriteFile(initialGoSumListPath, []byte(initialGoSumListContent), 0o644)
	if err != nil {
		t.Fatalf("Failed to write initial_go_sum_list.json: %v", err)
	}

	// Define output paths for the test
	outputJSON := filepath.Join(tmpDir, "go_mod_to_delete.json")
	outputMD := filepath.Join(tmpDir, "go_mod_delete_plan.md")

	// Run the planning function
	report, err := plan_go_mod_deletion.RunPlan(initialGoModListPath, initialGoSumListPath, outputJSON, outputMD)
	if err != nil {
		t.Fatalf("RunPlan failed: %v", err)
	}

	// Validate report content
	if len(report.GoModToDelete) != 4 { // submodule/go.mod, submodule/go.sum, another_module/go.mod, another_module/go.sum
		t.Errorf("Expected 4 files to delete, got %d", len(report.GoModToDelete))
	}

	expectedFilesToDelete := map[string]bool{
		"submodule/go.mod":      true,
		"submodule/go.sum":      true,
		"another_module/go.mod": true,
		"another_module/go.sum": true,
	}

	for _, file := range report.GoModToDelete {
		if !expectedFilesToDelete[file] {
			t.Errorf("Unexpected file to delete: %s", file)
		}
		delete(expectedFilesToDelete, file)
	}

	if len(expectedFilesToDelete) != 0 {
		t.Errorf("Not all expected files were found in deletion plan: %v", expectedFilesToDelete)
	}

	// Check if output files were created
	if _, err := os.Stat(outputJSON); os.IsNotExist(err) {
		t.Errorf("JSON output file not created at %s", outputJSON)
	}
	if _, err := os.Stat(outputMD); os.IsNotExist(err) {
		t.Errorf("Markdown output file not created at %s", outputMD)
	}

	// Read and parse JSON output
	jsonData, err := ioutil.ReadFile(outputJSON)
	if err != nil {
		t.Fatalf("Failed to read JSON output: %v", err)
	}

	var jsonReport plan_go_mod_deletion.PlanReport
	err = json.Unmarshal(jsonData, &jsonReport)
	if err != nil {
		t.Fatalf("Failed to unmarshal JSON data: %v", err)
	}

	if len(jsonReport.GoModToDelete) != 4 {
		t.Errorf("Expected 4 files in JSON report, got %d", len(jsonReport.GoModToDelete))
	}
}
