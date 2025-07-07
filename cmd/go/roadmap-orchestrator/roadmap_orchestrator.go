package roadmap_orchestrator

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

// PhaseResult stores the result of a single phase execution.
type PhaseResult struct {
	Phase   string `json:"phase"`
	Success bool   `json:"success"`
	Output  string `json:"output,omitempty"`
	Error   string `json:"error,omitempty"`
}

// OrchestrationReport summarizes the execution of all phases.
type OrchestrationReport struct {
	Timestamp      string        `json:"timestamp"`
	TotalPhases    int           `json:"total_phases"`
	PassedPhases   int           `json:"passed_phases"`
	FailedPhases   int           `json:"failed_phases"`
	Results        []PhaseResult `json:"results"`
	OverallSuccess bool          `json:"overall_success"`
	Summary        string        `json:"summary"`
}

// PhaseConfig defines a single phase to be executed by the orchestrator.
type PhaseConfig struct {
	Name    string   `yaml:"name"`
	Command []string `yaml:"command"`
	Enabled bool     `yaml:"enabled"`
}

// OrchestratorConfig defines the configuration for the orchestrator.
type OrchestratorConfig struct {
	Phases []PhaseConfig `yaml:"phases"`
}

func main() {
	configPath := flag.String("config", "config/orchestration_config.yaml", "Path to the orchestration config file")
	phaseToRun := flag.String("phase", "all", "Specific phase to run, or 'all' for all phases")
	outputReportPath := flag.String("output-report", "development/managers/dependency-manager/reports/global_orchestration_report.json", "Path to the global orchestration report")
	flag.Parse()

	report, err := RunOrchestrator(*configPath, *phaseToRun, *outputReportPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Orchestrator failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Println(report.Summary)
	if !report.OverallSuccess {
		os.Exit(1)
	}
}

// RunOrchestrator executes the configured phases and generates a global report.
func RunOrchestrator(configPath, phaseToRun, outputReportPath string) (OrchestrationReport, error) {
	var orchestrationReport OrchestrationReport
	orchestrationReport.Timestamp = time.Now().Format("2006-01-02_15-04-05")

	// Load configuration (simplified for now, assuming hardcoded for initial implementation)
	// In a real scenario, this would parse a YAML or JSON config file.
	// For now, we define a dummy config.
	dummyConfig := OrchestratorConfig{
		Phases: []PhaseConfig{
			{Name: "Phase 1: Audit Modules", Command: []string{"go", "run", "github.com/gerivdb/email-sender-1/cmd/go/dependency-manager/audit_modules", "--output-json", "development/managers/dependency-manager/reports/" + time.Now().Format("20060102-150405") + "/initial_go_mod_list.json", "--output-md", "development/managers/dependency-manager/reports/" + time.Now().Format("20060102-150405") + "/initial_module_audit.md"}, Enabled: true},
			{Name: "Phase 1: Scan Non-Compliant Imports", Command: []string{"go", "run", "github.com/gerivdb/email-sender-1/cmd/go/dependency-manager/scan_non_compliant_imports", "--output-json", "development/managers/dependency-manager/reports/" + time.Now().Format("20060102-150405") + "/non_compliant_imports.json", "--output-md", "development/managers/dependency-manager/reports/" + time.Now().Format("20060102-150405") + "/non_compliant_imports_report.md"}, Enabled: true},
			{Name: "Phase 2: Validate Monorepo Structure", Command: []string{"go", "run", "github.com/gerivdb/email-sender-1/cmd/go/dependency-manager/validate_monorepo_structure", "--output-json", "development/managers/dependency-manager/reports/" + time.Now().Format("20060102-150405") + "/monorepo_structure_validation.json"}, Enabled: true},
			// Add other phases here as needed
		},
	}

	orchestrationReport.TotalPhases = len(dummyConfig.Phases)
	orchestrationReport.OverallSuccess = true

	for _, phase := range dummyConfig.Phases {
		if !phase.Enabled {
			continue
		}
		if phaseToRun != "all" && phaseToRun != phase.Name {
			continue
		}

		fmt.Printf("--- Exécution de la phase: %s ---\n", phase.Name)
		cmd := exec.Command(phase.Command[0], phase.Command[1:]...)
		var stdout, stderr bytes.Buffer
		cmd.Stdout = &stdout
		cmd.Stderr = &stderr

		err := cmd.Run()

		phaseResult := PhaseResult{
			Phase:  phase.Name,
			Output: stdout.String(),
		}

		if err != nil {
			phaseResult.Success = false
			phaseResult.Error = stderr.String() + err.Error()
			orchestrationReport.FailedPhases++
			orchestrationReport.OverallSuccess = false
		} else {
			phaseResult.Success = true
			orchestrationReport.PassedPhases++
		}
		orchestrationReport.Results = append(orchestrationReport.Results, phaseResult)
	}

	orchestrationReport.Summary = fmt.Sprintf("Orchestration terminée. %d phases passées, %d phases échouées.",
		orchestrationReport.PassedPhases, orchestrationReport.FailedPhases)

	// Write global report
	os.MkdirAll(filepath.Dir(outputReportPath), 0o755)
	jsonData, err := json.MarshalIndent(orchestrationReport, "", "  ")
	if err != nil {
		return orchestrationReport, fmt.Errorf("error marshalling orchestration report: %w", err)
	}
	err = ioutil.WriteFile(outputReportPath, jsonData, 0o644)
	if err != nil {
		return orchestrationReport, fmt.Errorf("error writing orchestration report: %w", err)
	}

	return orchestrationReport, nil
}
