package auto_roadmap_runner

import (
	"bytes"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// Helper function to create dummy scripts for testing
func createDummyScript(t *testing.T, path, content string) {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatalf("Failed to create dir %s: %v", dir, err)
	}
	if err := ioutil.WriteFile(path, []byte(content), 0o755); err != nil {
		t.Fatalf("Failed to create dummy script %s: %v", path, err)
	}
}

// executeOrchestrator runs the main function of the orchestrator and captures its output
func executeOrchestrator(t *testing.T) string {
	oldStdout := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w

	main() // Run the orchestrator's main function

	w.Close()
	out, _ := ioutil.ReadAll(r)
	os.Stdout = oldStdout // Restore stdout
	return string(out)
}

func TestOrchestratorExecution(t *testing.T) {
	// Create a temporary directory for test scripts
	tempDir := t.TempDir()
	originalWd, _ := os.Getwd()
	os.Chdir(tempDir)
	defer func() {
		os.Chdir(originalWd)
		os.RemoveAll(tempDir)
	}()

	// Create dummy scripts
	createDummyScript(t, "cmd/audit_read_file/audit_read_file.go", `package main; import "fmt"; import "os"; func main(){ fmt.Println("audit_read_file executed"); os.Exit(0) }`)
	createDummyScript(t, "cmd/gap_analysis/gap_analysis.go", `package main; import "fmt"; import "os"; func main(){ fmt.Println("gap_analysis executed"); os.Exit(0) }`)
	createDummyScript(t, "scripts/gen_user_needs_template.sh", `#!/bin/bash; echo "gen_user_needs_template executed"; exit 0`)
	createDummyScript(t, "scripts/collect_user_needs.sh", `#!/bin/bash; echo "collect_user_needs executed"; exit 0`)
	createDummyScript(t, "scripts/validate_and_archive_user_needs.sh", `#!/bin/bash; echo "validate_and_archive_user_needs executed"; exit 0`)
	createDummyScript(t, "cmd/gen_read_file_spec/gen_read_file_spec.go", `package main; import "fmt"; import "os"; func main(){ fmt.Println("gen_read_file_spec executed"); os.Exit(0) }`)
	createDummyScript(t, "scripts/archive_spec.sh", `#!/bin/bash; echo "archive_spec executed"; exit 0`)
	createDummyScript(t, "pkg/common/read_file_test.go", `package common; import "testing"; func TestDummy(t *testing.T){ t.Log("read_file_lib_tests executed") }`)
	createDummyScript(t, "cmd/read_file_navigator/read_file_navigator.go", `package main; import "fmt"; import "os"; func main(){ fmt.Println("read_file_navigator executed"); os.Exit(0) }`)
	createDummyScript(t, "scripts/vscode_read_file_selection.js", `console.log("vscode_extension_validation executed"); process.exit(0);`)
	createDummyScript(t, "scripts/gen_read_file_report.go", `package main; import "fmt"; import "os"; func main(){ fmt.Println("gen_read_file_report executed"); os.Exit(0) }`)
	createDummyScript(t, "docs/read_file_README.md", `Documentation is updated.`) // This is a file, not a script, but included for completeness of the roadmap
	createDummyScript(t, "scripts/collect_user_feedback.sh", `#!/bin/bash; echo "collect_user_feedback_bash executed"; exit 0`)
	createDummyScript(t, "scripts/collect_user_feedback.ps1", `Write-Host "collect_user_feedback_powershell executed"; exit 0`)
	createDummyScript(t, "cmd/audit_rollback_points/audit_rollback_points.go", `package main; import "fmt"; import "os"; func main(){ fmt.Println("audit_rollback_points executed"); os.Exit(0) }`)
	createDummyScript(t, "cmd/gen_rollback_spec/gen_rollback_spec.go", `package main; import "fmt"; import "os"; func main(){ fmt.Println("gen_rollback_spec executed"); os.Exit(0) }`)
	createDummyScript(t, "scripts/backup/backup.go", `package main; import "fmt"; import "os"; func main(){ fmt.Println("backup executed"); os.Exit(0) }`)
	createDummyScript(t, "scripts/backup/backup_test.go", `package main; import "testing"; func TestDummyBackup(t *testing.T){ t.Log("backup_tests executed") }`)
	createDummyScript(t, "scripts/git_versioning.sh", `#!/bin/bash; echo "git_versioning executed"; exit 0`)
	createDummyScript(t, "scripts/gen_rollback_report/gen_rollback_report.go", `package main; import "fmt"; import "os"; func main(){ fmt.Println("gen_rollback_report executed"); os.Exit(0) }`)
	createDummyScript(t, "scripts/collect_rollback_feedback.sh", `#!/bin/bash; echo "collect_rollback_feedback_bash executed"; exit 0`)
	createDummyScript(t, "scripts/collect_rollback_feedback.ps1", `Write-Host "collect_rollback_feedback_powershell executed"; exit 0`)

	// Run the orchestrator
	output := executeOrchestrator(t)

	// Verify that all scripts were executed in a plausible order
	expectedExecutions := []string{
		"audit_read_file executed",
		"gap_analysis executed",
		"gen_user_needs_template executed",
		"collect_user_needs executed",
		"validate_and_archive_user_needs executed",
		"gen_read_file_spec executed",
		"archive_spec executed",
		"read_file_lib_tests executed", // Note: go test output might differ based on verbosity
		"read_file_navigator executed",
		"vscode_extension_validation executed",
		"gen_read_file_report executed",
		"Documentation is updated.", // From docs_update placeholder
		"collect_user_feedback_bash executed",
		"collect_user_feedback_powershell executed",
		"audit_rollback_points executed",
		"gen_rollback_spec executed",
		"backup executed",
		"backup_tests executed",
		"git_versioning executed",
		"gen_rollback_report executed",
		"collect_rollback_feedback_bash executed",
		"collect_rollback_feedback_powershell executed",
		"# Orchestration globale : terminée",
	}

	for _, expected := range expectedExecutions {
		if !strings.Contains(output, expected) {
			t.Errorf("Expected output '%s' not found in orchestrator output:\n%s", expected, output)
		}
	}

	// Test error handling (example: a script that fails)
	// Create a dummy failing Go script for better control over exit code and output
	createDummyScript(t, "scripts/failing_script.go", `package main; import "fmt"; import "os"; func main(){ fmt.Println("Failing script executed"); os.Exit(1) }`)

	// Simulate running a failing script using go run
	cmd := exec.Command("go", "run", "scripts/failing_script.go")
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err := cmd.Run()

	if err == nil {
		t.Errorf("Expected error for failing script, but got none.")
	}
	if !strings.Contains(stderr.String(), "Failing script executed") && !strings.Contains(stdout.String(), "Failing script executed") {
		t.Errorf("Expected output from failing script not found. Stderr: %s, Stdout: %s", stderr.String(), stdout.String())
	}
}
