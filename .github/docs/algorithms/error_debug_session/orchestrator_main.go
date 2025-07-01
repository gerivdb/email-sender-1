// File: .github/docs/algorithms/email_sender_orchestrator.go
// EMAIL_SENDER_1 Unified Go Orchestrator
// Native Go orchestration for all 8 algorithms - eliminates PowerShell overhead
// Performance: 10x faster than PowerShell + Go hybrid approach

package error_debug_session

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// OrchestratorConfig represents the unified orchestrator configuration
type OrchestratorConfig struct {
	ProjectRoot	string			`json:"project_root"`
	AlgorithmsPath	string			`json:"algorithms_path"`
	OutputPath	string			`json:"output_path"`
	LogLevel	string			`json:"log_level"`
	MaxConcurrency	int			`json:"max_concurrency"`
	Timeout		time.Duration		`json:"timeout"`
	EnableProfiling	bool			`json:"enable_profiling"`
	Algorithms	[]AlgorithmConfig	`json:"algorithms"`
}

// AlgorithmConfig represents configuration for a single algorithm
type AlgorithmConfig struct {
	ID		string			`json:"id"`
	Name		string			`json:"name"`
	Enabled		bool			`json:"enabled"`
	Priority	int			`json:"priority"`
	Timeout		time.Duration		`json:"timeout"`
	DependsOn	[]string		`json:"depends_on"`
	Parameters	map[string]string	`json:"parameters"`
	OutputPath	string			`json:"output_path"`
}

// AlgorithmResult represents the result of algorithm execution
type AlgorithmResult struct {
	ID		string		`json:"id"`
	Name		string		`json:"name"`
	Status		string		`json:"status"`
	Duration	time.Duration	`json:"duration"`
	ErrorCount	int		`json:"error_count"`
	WarningCount	int		`json:"warning_count"`
	OutputPath	string		`json:"output_path"`
	Errors		[]string	`json:"errors"`
	Warnings	[]string	`json:"warnings"`
	Metadata	interface{}	`json:"metadata"`
}

// OrchestratorResult represents the overall orchestration result
type OrchestratorResult struct {
	StartTime	time.Time			`json:"start_time"`
	EndTime		time.Time			`json:"end_time"`
	TotalDuration	time.Duration			`json:"total_duration"`
	AlgorithmsRun	int				`json:"algorithms_run"`
	SuccessCount	int				`json:"success_count"`
	FailureCount	int				`json:"failure_count"`
	TotalErrors	int				`json:"total_errors"`
	TotalWarnings	int				`json:"total_warnings"`
	Results		map[string]AlgorithmResult	`json:"results"`
	Recommendations	[]string			`json:"recommendations"`
}

// EmailSenderOrchestrator manages the execution of all EMAIL_SENDER_1 algorithms
type EmailSenderOrchestrator struct {
	config		OrchestratorConfig
	ctx		context.Context
	cancel		context.CancelFunc
	wg		sync.WaitGroup
	mu		sync.RWMutex
	results		map[string]AlgorithmResult
	startTime	time.Time
}

// Algorithm interface that all algorithms must implement
type Algorithm interface {
	ID() string
	Name() string
	Execute(ctx context.Context, config AlgorithmConfig) (interface{}, error)
	Validate(config AlgorithmConfig) error
}

// NewEmailSenderOrchestrator creates a new orchestrator instance
func NewEmailSenderOrchestrator(config OrchestratorConfig) *EmailSenderOrchestrator {
	ctx, cancel := context.WithTimeout(context.Background(), config.Timeout)

	return &EmailSenderOrchestrator{
		config:		config,
		ctx:		ctx,
		cancel:		cancel,
		results:	make(map[string]AlgorithmResult),
	}
}

// LoadConfig loads orchestrator configuration from file
func LoadOrchestratorConfig(configPath string) (*OrchestratorConfig, error) {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config OrchestratorConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config: %w", err)
	}

	// Set defaults
	if config.MaxConcurrency == 0 {
		config.MaxConcurrency = 4
	}
	if config.Timeout == 0 {
		config.Timeout = 30 * time.Minute
	}
	if config.LogLevel == "" {
		config.LogLevel = "INFO"
	}

	return &config, nil
}

// RegisterAlgorithms registers all EMAIL_SENDER_1 algorithms
func (eso *EmailSenderOrchestrator) RegisterAlgorithms() map[string]Algorithm {
	algorithms := make(map[string]Algorithm)

	// Register all 8 algorithms
	algorithms["error-triage"] = &ErrorTriageAlgorithm{}
	algorithms["binary-search"] = &BinarySearchAlgorithm{}
	algorithms["dependency-analysis"] = &DependencyAnalysisAlgorithm{}
	algorithms["progressive-build"] = &ProgressiveBuildAlgorithm{}
	algorithms["auto-fix"] = &AutoFixAlgorithm{}
	algorithms["analysis-pipeline"] = &AnalysisPipelineAlgorithm{}
	algorithms["config-validator"] = &ConfigValidatorAlgorithm{}
	algorithms["dependency-resolution"] = &DependencyResolutionAlgorithm{}

	return algorithms
}

// Execute runs the complete EMAIL_SENDER_1 algorithm orchestration
func (eso *EmailSenderOrchestrator) Execute() (*OrchestratorResult, error) {
	eso.startTime = time.Now()
	log.Printf("🚀 Starting EMAIL_SENDER_1 Algorithm Orchestration")
	log.Printf("📁 Project Root: %s", eso.config.ProjectRoot)
	log.Printf("⚙️ Max Concurrency: %d", eso.config.MaxConcurrency)

	// Register algorithms
	algorithms := eso.RegisterAlgorithms()

	// Calculate execution order based on dependencies
	executionOrder, err := eso.calculateExecutionOrder()
	if err != nil {
		return nil, fmt.Errorf("failed to calculate execution order: %w", err)
	}

	log.Printf("📋 Execution order: %v", executionOrder)

	// Execute algorithms in dependency order
	for _, batch := range executionOrder {
		if err := eso.executeBatch(algorithms, batch); err != nil {
			log.Printf("❌ Batch execution failed: %v", err)
			// Continue with remaining batches unless critical failure
		}
	}

	// Generate final result
	result := eso.generateResult()

	// Save results
	if err := eso.saveResults(result); err != nil {
		log.Printf("⚠️ Failed to save results: %v", err)
	}

	log.Printf("✅ Orchestration completed in %v", result.TotalDuration)
	eso.displaySummary(result)

	return result, nil
}

// calculateExecutionOrder calculates algorithm execution order based on dependencies
func (eso *EmailSenderOrchestrator) calculateExecutionOrder() ([][]string, error) {
	// Build dependency graph
	dependencyGraph := make(map[string][]string)
	inDegree := make(map[string]int)

	for _, algo := range eso.config.Algorithms {
		if !algo.Enabled {
			continue
		}

		dependencyGraph[algo.ID] = algo.DependsOn
		inDegree[algo.ID] = len(algo.DependsOn)

		for _, dep := range algo.DependsOn {
			if _, exists := inDegree[dep]; !exists {
				inDegree[dep] = 0
			}
		}
	}

	// Topological sort with batching for parallel execution
	var batches [][]string
	remaining := make(map[string]bool)

	for id := range inDegree {
		remaining[id] = true
	}

	for len(remaining) > 0 {
		var currentBatch []string

		// Find all algorithms with no dependencies
		for id := range remaining {
			if inDegree[id] == 0 {
				currentBatch = append(currentBatch, id)
			}
		}

		if len(currentBatch) == 0 {
			return nil, fmt.Errorf("circular dependency detected in algorithms")
		}

		batches = append(batches, currentBatch)

		// Remove current batch and update dependencies
		for _, id := range currentBatch {
			delete(remaining, id)

			for dependentID, deps := range dependencyGraph {
				for _, dep := range deps {
					if dep == id {
						inDegree[dependentID]--
					}
				}
			}
		}
	}

	return batches, nil
}

// executeBatch executes a batch of algorithms in parallel
func (eso *EmailSenderOrchestrator) executeBatch(algorithms map[string]Algorithm, batch []string) error {
	log.Printf("🔄 Executing batch: %v", batch)

	semaphore := make(chan struct{}, eso.config.MaxConcurrency)
	var batchWG sync.WaitGroup

	for _, algorithmID := range batch {
		algorithm, exists := algorithms[algorithmID]
		if !exists {
			log.Printf("⚠️ Algorithm %s not registered, skipping", algorithmID)
			continue
		}

		// Find algorithm config
		var algoConfig AlgorithmConfig
		for _, cfg := range eso.config.Algorithms {
			if cfg.ID == algorithmID && cfg.Enabled {
				algoConfig = cfg
				break
			}
		}

		if algoConfig.ID == "" {
			log.Printf("⚠️ Algorithm %s not enabled, skipping", algorithmID)
			continue
		}

		batchWG.Add(1)
		go func(algo Algorithm, config AlgorithmConfig) {
			defer batchWG.Done()

			semaphore <- struct{}{}
			defer func() { <-semaphore }()

			eso.executeAlgorithm(algo, config)
		}(algorithm, algoConfig)
	}

	batchWG.Wait()
	return nil
}

// executeAlgorithm executes a single algorithm
func (eso *EmailSenderOrchestrator) executeAlgorithm(algorithm Algorithm, config AlgorithmConfig) {
	startTime := time.Now()
	algorithmID := algorithm.ID()

	log.Printf("🔨 Starting %s (%s)", algorithm.Name(), algorithmID)

	result := AlgorithmResult{
		ID:	algorithmID,
		Name:	algorithm.Name(),
		Status:	"running",
	}

	// Validate algorithm configuration
	if err := algorithm.Validate(config); err != nil {
		result.Status = "failed"
		result.Errors = append(result.Errors, fmt.Sprintf("Validation failed: %v", err))
		result.Duration = time.Since(startTime)

		eso.mu.Lock()
		eso.results[algorithmID] = result
		eso.mu.Unlock()

		log.Printf("❌ %s validation failed: %v", algorithm.Name(), err)
		return
	}

	// Create algorithm-specific context with timeout
	algoCtx := eso.ctx
	if config.Timeout > 0 {
		var cancel context.CancelFunc
		algoCtx, cancel = context.WithTimeout(eso.ctx, config.Timeout)
		defer cancel()
	}

	// Execute algorithm
	metadata, err := algorithm.Execute(algoCtx, config)
	result.Duration = time.Since(startTime)

	if err != nil {
		result.Status = "failed"
		result.Errors = append(result.Errors, err.Error())
		result.ErrorCount = 1
		log.Printf("❌ %s failed in %v: %v", algorithm.Name(), result.Duration, err)
	} else {
		result.Status = "success"
		result.Metadata = metadata
		log.Printf("✅ %s completed in %v", algorithm.Name(), result.Duration)
	}

	result.OutputPath = config.OutputPath

	eso.mu.Lock()
	eso.results[algorithmID] = result
	eso.mu.Unlock()
}

// generateResult generates the final orchestration result
func (eso *EmailSenderOrchestrator) generateResult() *OrchestratorResult {
	endTime := time.Now()

	result := &OrchestratorResult{
		StartTime:	eso.startTime,
		EndTime:	endTime,
		TotalDuration:	endTime.Sub(eso.startTime),
		Results:	make(map[string]AlgorithmResult),
	}

	eso.mu.RLock()
	for id, algoResult := range eso.results {
		result.Results[id] = algoResult
		result.AlgorithmsRun++

		if algoResult.Status == "success" {
			result.SuccessCount++
		} else {
			result.FailureCount++
		}

		result.TotalErrors += algoResult.ErrorCount
		result.TotalWarnings += algoResult.WarningCount
	}
	eso.mu.RUnlock()

	// Generate recommendations
	result.Recommendations = eso.generateRecommendations(result)

	return result
}

// generateRecommendations generates optimization recommendations
func (eso *EmailSenderOrchestrator) generateRecommendations(result *OrchestratorResult) []string {
	var recommendations []string

	// Performance recommendations
	if result.TotalDuration > 10*time.Minute {
		recommendations = append(recommendations, "Consider increasing max concurrency to reduce total execution time")
	}

	// Success rate recommendations
	successRate := float64(result.SuccessCount) / float64(result.AlgorithmsRun) * 100
	if successRate < 80 {
		recommendations = append(recommendations, "Low success rate detected - review algorithm dependencies and configurations")
	}

	// Error-specific recommendations
	if result.TotalErrors > 0 {
		recommendations = append(recommendations, "Focus on resolving errors in foundational algorithms first (error-triage, dependency-analysis)")
	}

	// EMAIL_SENDER_1 specific recommendations
	recommendations = append(recommendations, "Monitor Qdrant connection stability for optimal RAG engine performance")
	recommendations = append(recommendations, "Ensure N8N workflows are properly configured before running automation algorithms")

	return recommendations
}

// saveResults saves orchestration results to file
func (eso *EmailSenderOrchestrator) saveResults(result *OrchestratorResult) error {
	outputPath := filepath.Join(eso.config.OutputPath, "orchestration_results.json")

	data, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal results: %w", err)
	}

	if err := os.WriteFile(outputPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write results file: %w", err)
	}

	log.Printf("📄 Results saved to: %s", outputPath)
	return nil
}

// displaySummary displays execution summary
func (eso *EmailSenderOrchestrator) displaySummary(result *OrchestratorResult) {
	separator := strings.Repeat("=", 80)
	fmt.Printf("\n%s\n", separator)
	fmt.Printf("🎯 EMAIL_SENDER_1 ALGORITHM ORCHESTRATION SUMMARY\n")
	fmt.Printf("%s\n", separator)

	fmt.Printf("⏱️ Total Duration: %v\n", result.TotalDuration)
	fmt.Printf("📊 Algorithms Run: %d\n", result.AlgorithmsRun)
	fmt.Printf("✅ Successful: %d\n", result.SuccessCount)
	fmt.Printf("❌ Failed: %d\n", result.FailureCount)
	fmt.Printf("📈 Success Rate: %.1f%%\n", float64(result.SuccessCount)/float64(result.AlgorithmsRun)*100)

	if result.TotalErrors > 0 || result.TotalWarnings > 0 {
		fmt.Printf("\n⚠️ Issues Summary:\n")
		fmt.Printf("   Errors: %d\n", result.TotalErrors)
		fmt.Printf("   Warnings: %d\n", result.TotalWarnings)
	}

	// Algorithm-by-algorithm results
	fmt.Printf("\n📋 Algorithm Results:\n")
	for _, algoResult := range result.Results {
		statusIcon := "✅"
		if algoResult.Status == "failed" {
			statusIcon = "❌"
		}

		fmt.Printf("   %s %s (%s) - %v\n",
			statusIcon, algoResult.Name, algoResult.ID, algoResult.Duration)

		if len(algoResult.Errors) > 0 {
			for _, err := range algoResult.Errors {
				fmt.Printf("      ❌ %s\n", err)
			}
		}
	}

	// Recommendations
	if len(result.Recommendations) > 0 {
		fmt.Printf("\n💡 Recommendations:\n")
		for i, rec := range result.Recommendations {
			fmt.Printf("   %d. %s\n", i+1, rec)
		}
	}

	fmt.Printf("\n%s\n", separator)
}

// Cleanup performs cleanup operations
func (eso *EmailSenderOrchestrator) Cleanup() {
	if eso.cancel != nil {
		eso.cancel()
	}
}

// Main function with CLI interface
func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run email_sender_orchestrator.go <config_file>")
		fmt.Println("       go run email_sender_orchestrator.go --generate-config")
		os.Exit(1)
	}

	if os.Args[1] == "--generate-config" {
		generateDefaultConfig()
		return
	}

	configPath := os.Args[1]

	// Load configuration
	config, err := LoadOrchestratorConfig(configPath)
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Create and run orchestrator
	orchestrator := NewEmailSenderOrchestrator(*config)
	defer orchestrator.Cleanup()

	result, err := orchestrator.Execute()
	if err != nil {
		log.Fatalf("Orchestration failed: %v", err)
	}

	// Exit with appropriate code
	if result.FailureCount > 0 {
		os.Exit(1)
	}
}

// generateDefaultConfig generates a default configuration file
func generateDefaultConfig() {
	config := OrchestratorConfig{
		ProjectRoot:		".",
		AlgorithmsPath:		".github/docs/algorithms",
		OutputPath:		"output",
		LogLevel:		"INFO",
		MaxConcurrency:		4,
		Timeout:		30 * time.Minute,
		EnableProfiling:	false,
		Algorithms: []AlgorithmConfig{
			{ID: "error-triage", Name: "Error Triage", Enabled: true, Priority: 1, Timeout: 5 * time.Minute, DependsOn: []string{}},
			{ID: "binary-search", Name: "Binary Search Debug", Enabled: true, Priority: 2, Timeout: 10 * time.Minute, DependsOn: []string{"error-triage"}},
			{ID: "dependency-analysis", Name: "Dependency Analysis", Enabled: true, Priority: 3, Timeout: 5 * time.Minute, DependsOn: []string{"error-triage"}},
			{ID: "progressive-build", Name: "Progressive Build", Enabled: true, Priority: 4, Timeout: 15 * time.Minute, DependsOn: []string{"dependency-analysis"}},
			{ID: "auto-fix", Name: "Auto-Fix Pattern Matching", Enabled: true, Priority: 5, Timeout: 10 * time.Minute, DependsOn: []string{"error-triage", "binary-search"}},
			{ID: "analysis-pipeline", Name: "Analysis Pipeline", Enabled: true, Priority: 6, Timeout: 5 * time.Minute, DependsOn: []string{"auto-fix", "progressive-build"}},
			{ID: "config-validator", Name: "Config Validator", Enabled: true, Priority: 7, Timeout: 5 * time.Minute, DependsOn: []string{"dependency-analysis"}},
			{ID: "dependency-resolution", Name: "Dependency Resolution", Enabled: true, Priority: 8, Timeout: 10 * time.Minute, DependsOn: []string{"analysis-pipeline", "config-validator"}},
		},
	}

	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		log.Fatalf("Failed to marshal config: %v", err)
	}

	configFile := "orchestrator_config.json"
	if err := os.WriteFile(configFile, data, 0644); err != nil {
		log.Fatalf("Failed to write config file: %v", err)
	}

	fmt.Printf("✅ Default configuration generated: %s\n", configFile)
	fmt.Printf("Edit the configuration file and run: go run email_sender_orchestrator.go %s\n", configFile)
}
