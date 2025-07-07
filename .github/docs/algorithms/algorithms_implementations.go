// File: .github/docs/algorithms/algorithms_implementations.go
// EMAIL_SENDER_1 Algorithm Implementations for Go Orchestrator
// Native Go implementations that wrap existing algorithm executables
// Performance optimized: direct Go-to-Go communication

package algorithms

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

// ErrorTriageAlgorithm implements Algorithm 1 - Error Triage
type ErrorTriageAlgorithm struct{}

func (eta *ErrorTriageAlgorithm) ID() string   { return "error-triage" }
func (eta *ErrorTriageAlgorithm) Name() string { return "Error Triage & Classification" }

func (eta *ErrorTriageAlgorithm) Validate(config AlgorithmConfig) error {
	if config.Parameters["project_path"] == "" {
		return fmt.Errorf("project_path parameter required")
	}
	return nil
}

func (eta *ErrorTriageAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error) {
	projectPath := config.Parameters["project_path"]
	outputPath := config.Parameters["output_path"]
	if outputPath == "" {
		outputPath = "error_triage_results.json"
	}

	exePath := filepath.Join(config.Parameters["algorithms_path"], "error-triage", "email_sender_error_triager")

	// Build if executable doesn't exist
	if _, err := os.Stat(exePath + ".exe"); os.IsNotExist(err) {
		if err := eta.buildExecutable(config.Parameters["algorithms_path"]); err != nil {
			return nil, fmt.Errorf("failed to build error triage executable: %w", err)
		}
	}

	cmd := exec.CommandContext(ctx, exePath+".exe", projectPath, outputPath, "-output", "json")
	output, err := cmd.CombinedOutput()

	if err != nil {
		return nil, fmt.Errorf("error triage execution failed: %w\nOutput: %s", err, string(output))
	}

	// Parse results
	var result map[string]interface{}
	if err := json.Unmarshal(output, &result); err != nil {
		// If JSON parsing fails, return raw output
		result = map[string]interface{}{
			"raw_output": string(output),
			"success":    true,
		}
	}

	return result, nil
}

func (eta *ErrorTriageAlgorithm) buildExecutable(algorithmsPath string) error {
	sourceDir := filepath.Join(algorithmsPath, "error-triage")
	cmd := exec.Command("go", "build", "-o", "email_sender_error_triager.exe", "email_sender_error_triager.go")
	cmd.Dir = sourceDir

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("build failed: %w\nOutput: %s", err, string(output))
	}

	return nil
}

// BinarySearchAlgorithm implements Algorithm 2 - Binary Search Debug
type BinarySearchAlgorithm struct{}

func (bsa *BinarySearchAlgorithm) ID() string   { return "binary-search" }
func (bsa *BinarySearchAlgorithm) Name() string { return "Binary Search Debug Locator" }

func (bsa *BinarySearchAlgorithm) Validate(config AlgorithmConfig) error {
	if config.Parameters["project_path"] == "" {
		return fmt.Errorf("project_path parameter required")
	}
	return nil
}

func (bsa *BinarySearchAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error) {
	projectPath := config.Parameters["project_path"]
	component := config.Parameters["component"]
	if component == "" {
		component = "All"
	}

	exePath := filepath.Join(config.Parameters["algorithms_path"], "binary-search", "email_sender_binary_search")

	// Build if executable doesn't exist
	if _, err := os.Stat(exePath + ".exe"); os.IsNotExist(err) {
		if err := bsa.buildExecutable(config.Parameters["algorithms_path"]); err != nil {
			return nil, fmt.Errorf("failed to build binary search executable: %w", err)
		}
	}

	cmd := exec.CommandContext(ctx, exePath+".exe", projectPath, component, "-output", "json")
	output, err := cmd.CombinedOutput()

	if err != nil {
		return nil, fmt.Errorf("binary search execution failed: %w\nOutput: %s", err, string(output))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(output, &result); err != nil {
		result = map[string]interface{}{
			"raw_output": string(output),
			"success":    true,
		}
	}

	return result, nil
}

func (bsa *BinarySearchAlgorithm) buildExecutable(algorithmsPath string) error {
	sourceDir := filepath.Join(algorithmsPath, "binary-search")
	cmd := exec.Command("go", "build", "-o", "email_sender_binary_search.exe", "email_sender_binary_search.go")
	cmd.Dir = sourceDir

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("build failed: %w\nOutput: %s", err, string(output))
	}

	return nil
}

// DependencyAnalysisAlgorithm implements Algorithm 3 - Dependency Analysis
type DependencyAnalysisAlgorithm struct{}

func (daa *DependencyAnalysisAlgorithm) ID() string   { return "dependency-analysis" }
func (daa *DependencyAnalysisAlgorithm) Name() string { return "Dependency Analysis & Mapping" }

func (daa *DependencyAnalysisAlgorithm) Validate(config AlgorithmConfig) error {
	if config.Parameters["project_path"] == "" {
		return fmt.Errorf("project_path parameter required")
	}
	return nil
}

func (daa *DependencyAnalysisAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error) {
	projectPath := config.Parameters["project_path"]

	exePath := filepath.Join(config.Parameters["algorithms_path"], "dependency-analysis", "email_sender_dependency_analyzer")

	// Build if executable doesn't exist
	if _, err := os.Stat(exePath + ".exe"); os.IsNotExist(err) {
		if err := daa.buildExecutable(config.Parameters["algorithms_path"]); err != nil {
			return nil, fmt.Errorf("failed to build dependency analysis executable: %w", err)
		}
	}

	cmd := exec.CommandContext(ctx, exePath+".exe", projectPath, "-output", "json")
	output, err := cmd.CombinedOutput()

	if err != nil {
		return nil, fmt.Errorf("dependency analysis execution failed: %w\nOutput: %s", err, string(output))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(output, &result); err != nil {
		result = map[string]interface{}{
			"raw_output": string(output),
			"success":    true,
		}
	}

	return result, nil
}

func (daa *DependencyAnalysisAlgorithm) buildExecutable(algorithmsPath string) error {
	sourceDir := filepath.Join(algorithmsPath, "dependency-analysis")
	cmd := exec.Command("go", "build", "-o", "email_sender_dependency_analyzer.exe", "email_sender_dependency_analyzer.go")
	cmd.Dir = sourceDir

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("build failed: %w\nOutput: %s", err, string(output))
	}

	return nil
}

// ProgressiveBuildAlgorithm implements Algorithm 4 - Progressive Build
type ProgressiveBuildAlgorithm struct{}

func (pba *ProgressiveBuildAlgorithm) ID() string   { return "progressive-build" }
func (pba *ProgressiveBuildAlgorithm) Name() string { return "Progressive Build Strategy" }

func (pba *ProgressiveBuildAlgorithm) Validate(config AlgorithmConfig) error {
	if config.Parameters["project_path"] == "" {
		return fmt.Errorf("project_path parameter required")
	}
	return nil
}

func (pba *ProgressiveBuildAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error) {
	projectPath := config.Parameters["project_path"]
	outputPath := config.Parameters["output_path"]
	if outputPath == "" {
		outputPath = "progressive_build_results.json"
	}

	exePath := filepath.Join(config.Parameters["algorithms_path"], "progressive-build", "email_sender_progressive_builder")

	// Build if executable doesn't exist
	if _, err := os.Stat(exePath + ".exe"); os.IsNotExist(err) {
		if err := pba.buildExecutable(config.Parameters["algorithms_path"]); err != nil {
			return nil, fmt.Errorf("failed to build progressive build executable: %w", err)
		}
	}

	cmd := exec.CommandContext(ctx, exePath+".exe", projectPath, "", outputPath)
	output, err := cmd.CombinedOutput()

	if err != nil {
		return nil, fmt.Errorf("progressive build execution failed: %w\nOutput: %s", err, string(output))
	}

	// Read the generated JSON file
	if data, err := os.ReadFile(outputPath); err == nil {
		var result map[string]interface{}
		if err := json.Unmarshal(data, &result); err == nil {
			return result, nil
		}
	}

	// Fallback to raw output
	result := map[string]interface{}{
		"raw_output": string(output),
		"success":    true,
	}

	return result, nil
}

func (pba *ProgressiveBuildAlgorithm) buildExecutable(algorithmsPath string) error {
	sourceDir := filepath.Join(algorithmsPath, "progressive-build")
	cmd := exec.Command("go", "build", "-o", "email_sender_progressive_builder.exe", "email_sender_progressive_builder.go")
	cmd.Dir = sourceDir

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("build failed: %w\nOutput: %s", err, string(output))
	}

	return nil
}

// AutoFixAlgorithm implements Algorithm 5 - Auto-Fix Pattern Matching
type AutoFixAlgorithm struct{}

func (afa *AutoFixAlgorithm) ID() string   { return "auto-fix" }
func (afa *AutoFixAlgorithm) Name() string { return "Auto-Fix Pattern Matching" }

func (afa *AutoFixAlgorithm) Validate(config AlgorithmConfig) error {
	if config.Parameters["project_path"] == "" {
		return fmt.Errorf("project_path parameter required")
	}
	return nil
}

func (afa *AutoFixAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error) {
	projectPath := config.Parameters["project_path"]
	component := config.Parameters["component"]
	if component == "" {
		component = "All"
	}

	dryRun := config.Parameters["dry_run"] == "true"
	safeOnly := config.Parameters["safe_only"] == "true"

	exePath := filepath.Join(config.Parameters["algorithms_path"], "auto-fix", "email_sender_auto_fixer")

	// Build if executable doesn't exist
	if _, err := os.Stat(exePath + ".exe"); os.IsNotExist(err) {
		if err := afa.buildExecutable(config.Parameters["algorithms_path"]); err != nil {
			return nil, fmt.Errorf("failed to build auto-fix executable: %w", err)
		}
	}

	args := []string{"-project-path", projectPath, "-component", component, "-output", "json"}
	if dryRun {
		args = append(args, "-dry-run")
	}
	if safeOnly {
		args = append(args, "-safe-only")
	}

	cmd := exec.CommandContext(ctx, exePath+".exe", args...)
	output, err := cmd.CombinedOutput()

	if err != nil {
		return nil, fmt.Errorf("auto-fix execution failed: %w\nOutput: %s", err, string(output))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(output, &result); err != nil {
		result = map[string]interface{}{
			"raw_output": string(output),
			"success":    true,
		}
	}

	return result, nil
}

func (afa *AutoFixAlgorithm) buildExecutable(algorithmsPath string) error {
	sourceDir := filepath.Join(algorithmsPath, "auto-fix")
	cmd := exec.Command("go", "build", "-o", "email_sender_auto_fixer.exe", "email_sender_auto_fixer.go")
	cmd.Dir = sourceDir

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("build failed: %w\nOutput: %s", err, string(output))
	}

	return nil
}

// AnalysisPipelineAlgorithm implements Algorithm 6 - Analysis Pipeline
type AnalysisPipelineAlgorithm struct{}

func (apa *AnalysisPipelineAlgorithm) ID() string   { return "analysis-pipeline" }
func (apa *AnalysisPipelineAlgorithm) Name() string { return "Analysis Pipeline & Optimization" }

func (apa *AnalysisPipelineAlgorithm) Validate(config AlgorithmConfig) error {
	if config.Parameters["project_path"] == "" {
		return fmt.Errorf("project_path parameter required")
	}
	return nil
}

func (apa *AnalysisPipelineAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error) {
	projectPath := config.Parameters["project_path"]

	exePath := filepath.Join(config.Parameters["algorithms_path"], "analysis-pipeline", "email_sender_analysis_pipeline")

	// Build if executable doesn't exist
	if _, err := os.Stat(exePath + ".exe"); os.IsNotExist(err) {
		if err := apa.buildExecutable(config.Parameters["algorithms_path"]); err != nil {
			return nil, fmt.Errorf("failed to build analysis pipeline executable: %w", err)
		}
	}

	cmd := exec.CommandContext(ctx, exePath+".exe", projectPath, "-output", "json")
	output, err := cmd.CombinedOutput()

	if err != nil {
		return nil, fmt.Errorf("analysis pipeline execution failed: %w\nOutput: %s", err, string(output))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(output, &result); err != nil {
		result = map[string]interface{}{
			"raw_output": string(output),
			"success":    true,
		}
	}

	return result, nil
}

func (apa *AnalysisPipelineAlgorithm) buildExecutable(algorithmsPath string) error {
	sourceDir := filepath.Join(algorithmsPath, "analysis-pipeline")
	cmd := exec.Command("go", "build", "-o", "email_sender_analysis_pipeline.exe", "email_sender_analysis_pipeline.go")
	cmd.Dir = sourceDir

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("build failed: %w\nOutput: %s", err, string(output))
	}

	return nil
}

// ConfigValidatorAlgorithm implements Algorithm 7 - Config Validator
type ConfigValidatorAlgorithm struct{}

func (cva *ConfigValidatorAlgorithm) ID() string   { return "config-validator" }
func (cva *ConfigValidatorAlgorithm) Name() string { return "Configuration Validator" }

func (cva *ConfigValidatorAlgorithm) Validate(config AlgorithmConfig) error {
	if config.Parameters["project_path"] == "" {
		return fmt.Errorf("project_path parameter required")
	}
	return nil
}

func (cva *ConfigValidatorAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error) {
	projectPath := config.Parameters["project_path"]

	exePath := filepath.Join(config.Parameters["algorithms_path"], "config-validator", "email_sender_config_validator")

	// Build if executable doesn't exist
	if _, err := os.Stat(exePath + ".exe"); os.IsNotExist(err) {
		if err := cva.buildExecutable(config.Parameters["algorithms_path"]); err != nil {
			return nil, fmt.Errorf("failed to build config validator executable: %w", err)
		}
	}

	cmd := exec.CommandContext(ctx, exePath+".exe", projectPath, "-output", "json")
	output, err := cmd.CombinedOutput()

	if err != nil {
		return nil, fmt.Errorf("config validator execution failed: %w\nOutput: %s", err, string(output))
	}

	var result map[string]interface{}
	if err := json.Unmarshal(output, &result); err != nil {
		result = map[string]interface{}{
			"raw_output": string(output),
			"success":    true,
		}
	}

	return result, nil
}

func (cva *ConfigValidatorAlgorithm) buildExecutable(algorithmsPath string) error {
	sourceDir := filepath.Join(algorithmsPath, "config-validator")
	cmd := exec.Command("go", "build", "-o", "email_sender_config_validator.exe", "email_sender_config_validator.go")
	cmd.Dir = sourceDir

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("build failed: %w\nOutput: %s", err, string(output))
	}

	return nil
}

// DependencyResolutionAlgorithm implements Algorithm 8 - Dependency Resolution
type DependencyResolutionAlgorithm struct{}

func (dra *DependencyResolutionAlgorithm) ID() string { return "dependency-resolution" }
func (dra *DependencyResolutionAlgorithm) Name() string {
	return "Dependency Resolution & Optimization"
}

func (dra *DependencyResolutionAlgorithm) Validate(config AlgorithmConfig) error {
	if config.Parameters["project_path"] == "" {
		return fmt.Errorf("project_path parameter required")
	}
	return nil
}

func (dra *DependencyResolutionAlgorithm) Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error) {
	projectPath := config.Parameters["project_path"]
	outputPath := config.Parameters["output_path"]
	if outputPath == "" {
		outputPath = "dependency_resolution_results.json"
	}

	exePath := filepath.Join(config.Parameters["algorithms_path"], "dependency-resolution", "email_sender_dependency_resolver")

	// Build if executable doesn't exist
	if _, err := os.Stat(exePath + ".exe"); os.IsNotExist(err) {
		if err := dra.buildExecutable(config.Parameters["algorithms_path"]); err != nil {
			return nil, fmt.Errorf("failed to build dependency resolution executable: %w", err)
		}
	}

	// Create absolute path for output file
	absOutputPath, err := filepath.Abs(outputPath)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve output path: %w", err)
	}

	// Execute with correct arguments: <project_path> [output_file]
	cmd := exec.CommandContext(ctx, exePath+".exe", projectPath, absOutputPath)
	output, err := cmd.CombinedOutput()

	if err != nil {
		return nil, fmt.Errorf("dependency resolution execution failed: %w\nOutput: %s", err, string(output))
	}

	// Read the JSON output file that was generated
	var result map[string]interface{}
	if _, err := os.Stat(absOutputPath); err == nil {
		data, err := os.ReadFile(absOutputPath)
		if err != nil {
			return nil, fmt.Errorf("failed to read output file: %w", err)
		}

		if err := json.Unmarshal(data, &result); err != nil {
			return nil, fmt.Errorf("failed to parse JSON output: %w", err)
		}
	} else {
		// Fallback to stdout parsing if file wasn't created
		result = map[string]interface{}{
			"raw_output": string(output),
			"success":    true,
		}
	}

	return result, nil
}

func (dra *DependencyResolutionAlgorithm) buildExecutable(algorithmsPath string) error {
	sourceDir := filepath.Join(algorithmsPath, "dependency-resolution")
	cmd := exec.Command("go", "build", "-o", "email_sender_dependency_resolver.exe", "email_sender_dependency_resolver.go")
	cmd.Dir = sourceDir

	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("build failed: %w\nOutput: %s", err, string(output))
	}

	return nil
}
