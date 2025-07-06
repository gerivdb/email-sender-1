package main_test

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	roadmap_orchestrator "github.com/gerivdb/email-sender-1/cmd/go/roadmap-orchestrator" // Import the main package
)

func TestRunOrchestrator(t *testing.T) {
	// Create a temporary directory for testing
	tmpDir, err := ioutil.TempDir("", "test_orchestrator")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create dummy config file (for now, the orchestrator uses a hardcoded dummy config)
	dummyConfigPath := filepath.Join(tmpDir, "dummy_config.yaml")
	ioutil.WriteFile(dummyConfigPath, []byte(""), 0o644) // Content doesn't matter for now

	// Create dummy report directory
	reportDir := filepath.Join(tmpDir, "reports")
	os.MkdirAll(reportDir, 0o755)

	// Define output report path for the orchestrator
	outputReportPath := filepath.Join(reportDir, "global_orchestration_report.json")

	// Capture stdout and stderr
	oldStdout := os.Stdout
	oldStderr := os.Stderr
	rOut, wOut, _ := os.Pipe()
	rErr, wErr, _ := os.Pipe()
	os.Stdout = wOut
	os.Stderr = wErr

	// Run the orchestrator
	generatedReport, err := roadmap_orchestrator.RunOrchestrator(dummyConfigPath, "all", outputReportPath)
	if err != nil {
		t.Fatalf("RunOrchestrator failed: %v", err)
	}

	wOut.Close()
	wErr.Close()
	os.Stdout = oldStdout
	os.Stderr = oldStderr

	var stdoutBuf, stderrBuf bytes.Buffer
	stdoutBuf.ReadFrom(rOut)
	stderrBuf.ReadFrom(rErr)

	// Check if output report was created
	if _, err := os.Stat(outputReportPath); os.IsNotExist(err) {
		t.Errorf("Global orchestration report not created at %s", outputReportPath)
	}

	// Read and parse the generated report
	reportData, err := ioutil.ReadFile(outputReportPath)
	if err != nil {
		t.Fatalf("Failed to read orchestration report: %v", err)
	}
	err = json.Unmarshal(reportData, &generatedReport)
	if err != nil {
		t.Fatalf("Failed to unmarshal orchestration report: %v", err)
	}

	// Validate report content (basic checks)
	if !generatedReport.OverallSuccess {
		t.Errorf("Orchestration reported overall failure: %s", generatedReport.Summary)
		t.Logf("Stdout: %s\nStderr: %s\n", stdoutBuf.String(), stderrBuf.String())
		for _, res := range generatedReport.Results {
			if !res.Success {
				t.Logf("Failed Phase: %s, Error: %s, Output: %s\n", res.Phase, res.Error, res.Output)
			}
		}
	}
	if generatedReport.TotalPhases == 0 {
		t.Error("Expected total phases > 0, got 0")
	}
	if generatedReport.PassedPhases != generatedReport.TotalPhases {
		t.Errorf("Expected all phases to pass, got %d passed out of %d total", generatedReport.PassedPhases, generatedReport.TotalPhases)
	}
	if generatedReport.FailedPhases != 0 {
		t.Errorf("Expected 0 failed phases, got %d", generatedReport.FailedPhases)
	}
	if generatedReport.Summary == "" {
		t.Error("Expected a summary in the report, got empty")
	}
}
