package scripts

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// OrchestrationReport represents the complete automation results
type OrchestrationReport struct {
	GeneratedAt     time.Time                  `json:"generated_at"`
	ProjectName     string                     `json:"project_name"`
	ExecutionMode   string                     `json:"execution_mode"`
	Operations      []OperationResult          `json:"operations"`
	Summary         OrchestrationSummary       `json:"summary"`
	Recommendations []string                   `json:"recommendations"`
	NextActions     []string                   `json:"next_actions"`
	Configuration   OrchestrationConfiguration `json:"configuration"`
}

// OperationResult represents the result of a single operation
type OperationResult struct {
	Name        string                 `json:"name"`
	Command     string                 `json:"command"`
	Status      string                 `json:"status"`
	Duration    float64                `json:"duration_seconds"`
	Output      string                 `json:"output,omitempty"`
	Error       string                 `json:"error,omitempty"`
	Timestamp   time.Time              `json:"timestamp"`
	OutputFiles []string               `json:"output_files"`
	Metrics     map[string]interface{} `json:"metrics,omitempty"`
}

// OrchestrationSummary represents overall execution summary
type OrchestrationSummary struct {
	TotalOperations int     `json:"total_operations"`
	SuccessfulOps   int     `json:"successful_operations"`
	FailedOps       int     `json:"failed_operations"`
	SkippedOps      int     `json:"skipped_operations"`
	TotalDuration   float64 `json:"total_duration_seconds"`
	OverallStatus   string  `json:"overall_status"`
	SuccessRate     float64 `json:"success_rate"`
}

// OrchestrationConfiguration represents configuration options
type OrchestrationConfiguration struct {
	DryRun          bool              `json:"dry_run"`
	ContinueOnError bool              `json:"continue_on_error"`
	Operations      []string          `json:"operations"`
	OutputDir       string            `json:"output_dir"`
	TimeoutSeconds  int               `json:"timeout_seconds"`
	Parallel        bool              `json:"parallel"`
	Environment     map[string]string `json:"environment"`
}

// Operation represents a documentation automation operation
type Operation struct {
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Command     []string `json:"command"`
	OutputFiles []string `json:"output_files"`
	Required    bool     `json:"required"`
	Timeout     int      `json:"timeout_seconds"`
}

func main() {
	projectRoot := "."
	dryRun := false
	operations := []string{"all"}

	// Parse command line arguments
	for i := 1; i < len(os.Args); i++ {
		arg := os.Args[i]
		switch arg {
		case "--dry-run":
			dryRun = true
		case "--root":
			if i+1 < len(os.Args) {
				projectRoot = os.Args[i+1]
				i++ // Skip next argument
			}
		case "--operations":
			if i+1 < len(os.Args) {
				operationsArg := os.Args[i+1]
				if operationsArg != "all" {
					operations = strings.Split(operationsArg, ",")
				}
				i++ // Skip next argument
			}
		case "--help":
			showHelp()
			return
		}
	}

	report, err := orchestrateDocumentation(projectRoot, dryRun, operations)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error orchestrating documentation: %v\n", err)
		os.Exit(1)
	}

	// Output JSON to stdout
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(report); err != nil {
		fmt.Fprintf(os.Stderr, "Error encoding JSON: %v\n", err)
		os.Exit(1)
	}

	// Print summary to stderr for visibility
	fmt.Fprintf(os.Stderr, "\n=== Documentation Orchestration Summary ===\n")
	fmt.Fprintf(os.Stderr, "Operations: %d total, %d successful, %d failed\n",
		report.Summary.TotalOperations, report.Summary.SuccessfulOps, report.Summary.FailedOps)
	fmt.Fprintf(os.Stderr, "Duration: %.2f seconds\n", report.Summary.TotalDuration)
	fmt.Fprintf(os.Stderr, "Status: %s\n", report.Summary.OverallStatus)

	if report.Summary.FailedOps > 0 {
		os.Exit(1)
	}
}

func showHelp() {
	fmt.Println("Documentation Automation Orchestrator")
	fmt.Println("")
	fmt.Println("Usage: go run auto-doc-orchestrator.go [options]")
	fmt.Println("")
	fmt.Println("Options:")
	fmt.Println("  --dry-run                 Simulate operations without executing")
	fmt.Println("  --root <path>             Project root directory (default: .)")
	fmt.Println("  --operations <list>       Comma-separated list of operations (default: all)")
	fmt.Println("  --help                    Show this help message")
	fmt.Println("")
	fmt.Println("Available operations:")
	fmt.Println("  inventory                 Scan and inventory documentation files")
	fmt.Println("  gap-analysis             Analyze documentation gaps")
	fmt.Println("  needs-survey             Survey documentation needs")
	fmt.Println("  specs-generator          Generate technical specifications")
	fmt.Println("  index-generation         Generate documentation index")
	fmt.Println("  lint                     Lint documentation for quality")
	fmt.Println("  coverage                 Generate coverage report")
	fmt.Println("  all                      Run all operations")
	fmt.Println("")
	fmt.Println("Examples:")
	fmt.Println("  go run auto-doc-orchestrator.go --dry-run")
	fmt.Println("  go run auto-doc-orchestrator.go --operations inventory,lint")
	fmt.Println("  go run auto-doc-orchestrator.go --root /path/to/project")
}

func orchestrateDocumentation(root string, dryRun bool, requestedOps []string) (*OrchestrationReport, error) {
	projectName := filepath.Base(root)
	if projectName == "." || projectName == "/" {
		projectName = "project"
	}

	// Define available operations
	operations := defineOperations(root)

	// Filter operations based on request
	selectedOps := selectOperations(operations, requestedOps)

	config := OrchestrationConfiguration{
		DryRun:          dryRun,
		ContinueOnError: true,
		Operations:      requestedOps,
		OutputDir:       filepath.Join(root, ".github"),
		TimeoutSeconds:  300,
		Parallel:        false,
		Environment:     map[string]string{"PROJECT_ROOT": root},
	}

	var results []OperationResult
	startTime := time.Now()

	// Execute operations
	for _, op := range selectedOps {
		result := executeOperation(op, config, root)
		results = append(results, result)

		// Stop on critical failures if not configured to continue
		if !config.ContinueOnError && result.Status == "failed" && op.Required {
			break
		}
	}

	totalDuration := time.Since(startTime).Seconds()

	// Calculate summary
	summary := calculateSummary(results, totalDuration)

	// Generate recommendations
	recommendations := generateOrchestrationRecommendations(results, summary)

	// Generate next actions
	nextActions := generateNextActions(results, summary)

	report := &OrchestrationReport{
		GeneratedAt:     time.Now(),
		ProjectName:     projectName,
		ExecutionMode:   getExecutionMode(dryRun),
		Operations:      results,
		Summary:         summary,
		Recommendations: recommendations,
		NextActions:     nextActions,
		Configuration:   config,
	}

	return report, nil
}

func defineOperations(root string) []Operation {
	scriptsDir := filepath.Join(root, ".github", "scripts")

	return []Operation{
		{
			Name:        "inventory",
			Description: "Scan and inventory all documentation files",
			Command:     []string{"go", "run", filepath.Join(scriptsDir, "inventory_docs.go"), root},
			OutputFiles: []string{"docs_inventory.json"},
			Required:    true,
			Timeout:     60,
		},
		{
			Name:        "gap-analysis",
			Description: "Analyze documentation gaps and missing files",
			Command:     []string{"go", "run", filepath.Join(scriptsDir, "gap_analysis_docs.go"), root},
			OutputFiles: []string{"gap_analysis_doc.md", "gap_matrix.csv"},
			Required:    true,
			Timeout:     60,
		},
		{
			Name:        "needs-survey",
			Description: "Survey documentation needs and user requirements",
			Command:     []string{"go", "run", filepath.Join(scriptsDir, "needs_survey_docs.go"), root},
			OutputFiles: []string{"needs_survey_docs.json", "needs_survey_docs.md"},
			Required:    false,
			Timeout:     30,
		},
		{
			Name:        "specs-generator",
			Description: "Generate detailed technical specifications",
			Command:     []string{"go", "run", filepath.Join(scriptsDir, "specs_generator_docs.go"), root},
			OutputFiles: []string{"specs_automatisation_doc.md"},
			Required:    false,
			Timeout:     30,
		},
		{
			Name:        "index-generation",
			Description: "Generate comprehensive documentation index",
			Command:     []string{"go", "run", filepath.Join(scriptsDir, "gen_docs_index.go"), root},
			OutputFiles: []string{".github/DOCS_INDEX.md", "docs_index.json"},
			Required:    true,
			Timeout:     120,
		},
		{
			Name:        "lint",
			Description: "Lint documentation for quality and consistency",
			Command:     []string{"go", "run", filepath.Join(scriptsDir, "lint_docs.go"), root},
			OutputFiles: []string{"lint_report.json"},
			Required:    false,
			Timeout:     180,
		},
		{
			Name:        "coverage",
			Description: "Generate documentation coverage report",
			Command:     []string{"go", "run", filepath.Join(scriptsDir, "gen_doc_coverage.go"), root},
			OutputFiles: []string{"docs_coverage_report.md"},
			Required:    true,
			Timeout:     90,
		},
	}
}

func selectOperations(available []Operation, requested []string) []Operation {
	if len(requested) == 1 && requested[0] == "all" {
		return available
	}

	var selected []Operation
	requestedMap := make(map[string]bool)
	for _, name := range requested {
		requestedMap[name] = true
	}

	for _, op := range available {
		if requestedMap[op.Name] {
			selected = append(selected, op)
		}
	}

	return selected
}

func executeOperation(op Operation, config OrchestrationConfiguration, root string) OperationResult {
	startTime := time.Now()

	result := OperationResult{
		Name:        op.Name,
		Command:     fmt.Sprintf("%s", op.Command),
		Status:      "running",
		Timestamp:   startTime,
		OutputFiles: op.OutputFiles,
		Metrics:     make(map[string]interface{}),
	}

	if config.DryRun {
		result.Status = "skipped"
		result.Output = "Skipped due to dry-run mode"
		result.Duration = time.Since(startTime).Seconds()
		return result
	}

	// Execute the command
	cmd := exec.Command(op.Command[0], op.Command[1:]...)
	cmd.Dir = root

	output, err := cmd.CombinedOutput()
	result.Output = string(output)
	result.Duration = time.Since(startTime).Seconds()

	if err != nil {
		result.Status = "failed"
		result.Error = err.Error()
	} else {
		result.Status = "success"

		// Extract metrics from output if it's JSON
		if len(output) > 0 && output[0] == '{' {
			var jsonData map[string]interface{}
			if json.Unmarshal(output, &jsonData) == nil {
				result.Metrics = extractMetrics(jsonData)
			}
		}
	}

	return result
}

func extractMetrics(jsonData map[string]interface{}) map[string]interface{} {
	metrics := make(map[string]interface{})

	// Extract common metrics
	if val, ok := jsonData["total_files"]; ok {
		metrics["total_files"] = val
	}
	if val, ok := jsonData["total_issues"]; ok {
		metrics["total_issues"] = val
	}
	if val, ok := jsonData["overall_coverage"]; ok {
		metrics["overall_coverage"] = val
	}
	if val, ok := jsonData["files_linted"]; ok {
		metrics["files_linted"] = val
	}
	if val, ok := jsonData["identified_gaps"]; ok {
		if gaps, ok := val.([]interface{}); ok {
			metrics["gap_count"] = len(gaps)
		}
	}

	return metrics
}

func calculateSummary(results []OperationResult, totalDuration float64) OrchestrationSummary {
	var successful, failed, skipped int

	for _, result := range results {
		switch result.Status {
		case "success":
			successful++
		case "failed":
			failed++
		case "skipped":
			skipped++
		}
	}

	total := len(results)
	successRate := 0.0
	if total > 0 {
		successRate = float64(successful) / float64(total) * 100.0
	}

	overallStatus := "success"
	if failed > 0 {
		if successful == 0 {
			overallStatus = "failed"
		} else {
			overallStatus = "partial"
		}
	} else if skipped == total {
		overallStatus = "skipped"
	}

	return OrchestrationSummary{
		TotalOperations: total,
		SuccessfulOps:   successful,
		FailedOps:       failed,
		SkippedOps:      skipped,
		TotalDuration:   totalDuration,
		OverallStatus:   overallStatus,
		SuccessRate:     successRate,
	}
}

func generateOrchestrationRecommendations(results []OperationResult, summary OrchestrationSummary) []string {
	var recommendations []string

	if summary.FailedOps > 0 {
		recommendations = append(recommendations,
			fmt.Sprintf("🔧 Address %d failed operations before proceeding", summary.FailedOps))
	}

	if summary.SuccessRate < 50 {
		recommendations = append(recommendations,
			"⚠️ Low success rate - check system dependencies and permissions")
	}

	// Operation-specific recommendations
	for _, result := range results {
		if result.Status == "success" && result.Metrics != nil {
			switch result.Name {
			case "coverage":
				if coverage, ok := result.Metrics["overall_coverage"].(float64); ok && coverage < 60 {
					recommendations = append(recommendations,
						"📊 Documentation coverage is low - prioritize creating missing files")
				}
			case "lint":
				if issues, ok := result.Metrics["total_issues"].(float64); ok && issues > 100 {
					recommendations = append(recommendations,
						"✨ High number of linting issues - consider automated fixes")
				}
			case "gap-analysis":
				if gaps, ok := result.Metrics["gap_count"].(int); ok && gaps > 5 {
					recommendations = append(recommendations,
						"📝 Multiple documentation gaps identified - create missing critical files")
				}
			}
		}
	}

	if len(recommendations) == 0 {
		recommendations = append(recommendations,
			"✅ All operations completed successfully - documentation automation is working well")
	}

	return recommendations
}

func generateNextActions(results []OperationResult, summary OrchestrationSummary) []string {
	var actions []string

	if summary.FailedOps > 0 {
		actions = append(actions, "🔍 Review failed operation logs and resolve issues")
	}

	actions = append(actions, "📋 Review generated reports and documentation index")
	actions = append(actions, "🔄 Set up automated scheduling for regular execution")
	actions = append(actions, "📈 Monitor documentation coverage trends over time")

	// Add specific actions based on results
	hasLintIssues := false
	hasGaps := false

	for _, result := range results {
		if result.Status == "success" && result.Metrics != nil {
			if result.Name == "lint" {
				if issues, ok := result.Metrics["total_issues"].(float64); ok && issues > 0 {
					hasLintIssues = true
				}
			}
			if result.Name == "gap-analysis" {
				if gaps, ok := result.Metrics["gap_count"].(int); ok && gaps > 0 {
					hasGaps = true
				}
			}
		}
	}

	if hasGaps {
		actions = append(actions, "📄 Create missing documentation files identified in gap analysis")
	}
	if hasLintIssues {
		actions = append(actions, "🧹 Address documentation quality issues found by linter")
	}

	actions = append(actions, "🚀 Consider setting up CI/CD integration for automatic execution")

	return actions
}

func getExecutionMode(dryRun bool) string {
	if dryRun {
		return "dry-run"
	}
	return "full-execution"
}
