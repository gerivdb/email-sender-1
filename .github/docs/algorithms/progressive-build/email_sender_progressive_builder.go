// email_sender_progressive_builder.go
// Algorithm 4: Progressive Build Strategy for EMAIL_SENDER_1
// Implements incremental layer-by-layer architecture building and validation

package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

// BuildLayer represents a layer in the EMAIL_SENDER_1 architecture
type BuildLayer struct {
	Name         string            `json:"name"`
	Priority     int               `json:"priority"`
	Components   []BuildComponent  `json:"components"`
	Dependencies []string          `json:"dependencies"`
	Status       string            `json:"status"`
	BuildTime    time.Duration     `json:"build_time"`
	TestResults  []TestResult      `json:"test_results"`
	Metadata     map[string]string `json:"metadata"`
}

// BuildComponent represents a component within a build layer
type BuildComponent struct {
	Name        string            `json:"name"`
	Type        string            `json:"type"`
	Path        string            `json:"path"`
	BuildCmd    string            `json:"build_cmd"`
	TestCmd     string            `json:"test_cmd"`
	Status      string            `json:"status"`
	BuildTime   time.Duration     `json:"build_time"`
	ErrorCount  int               `json:"error_count"`
	Warnings    []string          `json:"warnings"`
	Metadata    map[string]string `json:"metadata"`
}

// TestResult represents test execution results
type TestResult struct {
	Component string        `json:"component"`
	TestType  string        `json:"test_type"`
	Status    string        `json:"status"`
	Duration  time.Duration `json:"duration"`
	Output    string        `json:"output"`
	Errors    []string      `json:"errors"`
}

// BuildStrategy represents the overall build strategy
type BuildStrategy struct {
	ProjectPath    string                 `json:"project_path"`
	Layers         []BuildLayer           `json:"layers"`
	BuildOrder     []string               `json:"build_order"`
	TotalTime      time.Duration          `json:"total_time"`
	SuccessRate    float64                `json:"success_rate"`
	ErrorSummary   map[string]int         `json:"error_summary"`
	Recommendations []string              `json:"recommendations"`
	Timestamp      time.Time              `json:"timestamp"`
	Config         BuildConfig            `json:"config"`
}

// BuildConfig holds configuration for the build strategy
type BuildConfig struct {
	MaxParallelBuilds   int               `json:"max_parallel_builds"`
	BuildTimeout        time.Duration     `json:"build_timeout"`
	TestTimeout         time.Duration     `json:"test_timeout"`
	FailFast            bool              `json:"fail_fast"`
	ContinueOnError     bool              `json:"continue_on_error"`
	EnableTests         bool              `json:"enable_tests"`
	EnableOptimizations bool              `json:"enable_optimizations"`
	ComponentFilters    []string          `json:"component_filters"`
	LayerPriorities     map[string]int    `json:"layer_priorities"`
}

// EMAIL_SENDER_1 Build Layers Definition
var emailSenderLayers = []BuildLayer{
	{
		Name:         "foundation",
		Priority:     1,
		Dependencies: []string{},
		Components: []BuildComponent{
			{Name: "shared-types", Type: "go_module", Path: "internal/types", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "shared-utils", Type: "go_module", Path: "internal/utils", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "config-loader", Type: "go_module", Path: "internal/config", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "logger", Type: "go_module", Path: "internal/logger", BuildCmd: "go build", TestCmd: "go test"},
		},
		Metadata: map[string]string{
			"description": "Core foundation components and utilities",
			"criticality": "high",
		},
	},
	{
		Name:         "storage",
		Priority:     2,
		Dependencies: []string{"foundation"},
		Components: []BuildComponent{
			{Name: "qdrant-client", Type: "go_module", Path: "internal/storage/qdrant", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "vector-store", Type: "go_module", Path: "internal/storage/vectors", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "embedding-cache", Type: "go_module", Path: "internal/storage/cache", BuildCmd: "go build", TestCmd: "go test"},
		},
		Metadata: map[string]string{
			"description": "Vector storage and caching layer",
			"criticality": "high",
		},
	},
	{
		Name:         "rag_engine",
		Priority:     3,
		Dependencies: []string{"foundation", "storage"},
		Components: []BuildComponent{
			{Name: "embedding-service", Type: "go_module", Path: "internal/engine/embeddings", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "retrieval-service", Type: "go_module", Path: "internal/engine/retrieval", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "generation-service", Type: "go_module", Path: "internal/engine/generation", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "rag-pipeline", Type: "go_module", Path: "internal/engine/pipeline", BuildCmd: "go build", TestCmd: "go test"},
		},
		Metadata: map[string]string{
			"description": "Core RAG engine components",
			"criticality": "critical",
		},
	},
	{
		Name:         "integrations",
		Priority:     4,
		Dependencies: []string{"foundation", "rag_engine"},
		Components: []BuildComponent{
			{Name: "notion-client", Type: "go_module", Path: "internal/integrations/notion", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "gmail-processor", Type: "go_module", Path: "internal/integrations/gmail", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "n8n-connector", Type: "go_module", Path: "internal/integrations/n8n", BuildCmd: "go build", TestCmd: "go test"},
		},
		Metadata: map[string]string{
			"description": "External service integrations",
			"criticality": "medium",
		},
	},
	{
		Name:         "automation",
		Priority:     5,
		Dependencies: []string{"foundation", "integrations"},
		Components: []BuildComponent{
			{Name: "powershell-bridge", Type: "powershell", Path: "scripts/automation", BuildCmd: "pwsh -c Test-Path", TestCmd: "pwsh -File test.ps1"},
			{Name: "workflow-orchestrator", Type: "go_module", Path: "internal/automation/workflows", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "task-scheduler", Type: "go_module", Path: "internal/automation/scheduler", BuildCmd: "go build", TestCmd: "go test"},
		},
		Metadata: map[string]string{
			"description": "Automation and orchestration layer",
			"criticality": "medium",
		},
	},
	{
		Name:         "services",
		Priority:     6,
		Dependencies: []string{"rag_engine", "integrations", "automation"},
		Components: []BuildComponent{
			{Name: "api-server", Type: "go_module", Path: "cmd/server", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "cli-tool", Type: "go_module", Path: "cmd/cli", BuildCmd: "go build", TestCmd: "go test"},
			{Name: "web-interface", Type: "javascript", Path: "web", BuildCmd: "npm run build", TestCmd: "npm test"},
		},
		Metadata: map[string]string{
			"description": "User-facing services and interfaces",
			"criticality": "low",
		},
	},
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run email_sender_progressive_builder.go <project_path> [config_file] [output_file]")
		os.Exit(1)
	}

	projectPath := os.Args[1]
	configFile := ""
	outputFile := "progressive_build_results.json"

	if len(os.Args) > 2 {
		configFile = os.Args[2]
	}
	if len(os.Args) > 3 {
		outputFile = os.Args[3]
	}

	fmt.Printf("🏗️ EMAIL_SENDER_1 Progressive Build Starting...\n")
	fmt.Printf("📁 Project Path: %s\n", projectPath)
	fmt.Printf("⚙️ Config File: %s\n", if(configFile != "", configFile, "Default"))
	fmt.Printf("📄 Output File: %s\n", outputFile)

	builder := NewProgressiveBuilder(projectPath)

	// Load configuration
	if configFile != "" {
		err := builder.LoadConfig(configFile)
		if err != nil {
			log.Printf("Warning: Could not load config file %s: %v", configFile, err)
		}
	}

	// Step 1: Initialize build strategy
	fmt.Printf("\n🔧 Step 1: Initializing build strategy...\n")
	builder.InitializeBuildStrategy()

	// Step 2: Validate project structure
	fmt.Printf("\n🔍 Step 2: Validating project structure...\n")
	err := builder.ValidateProjectStructure()
	if err != nil {
		log.Fatalf("Project validation failed: %v", err)
	}

	// Step 3: Execute progressive build
	fmt.Printf("\n🚀 Step 3: Executing progressive build...\n")
	err = builder.ExecuteProgressiveBuild()
	if err != nil {
		log.Printf("Build completed with errors: %v", err)
	}

	// Step 4: Generate build report
	fmt.Printf("\n📊 Step 4: Generating build report...\n")
	err = builder.GenerateReport(outputFile)
	if err != nil {
		log.Fatalf("Failed to generate report: %v", err)
	}

	// Display summary
	builder.DisplaySummary()

	fmt.Printf("\n✅ Progressive build complete! Report saved to: %s\n", outputFile)
}

// NewProgressiveBuilder creates a new progressive builder
func NewProgressiveBuilder(projectPath string) *BuildStrategy {
	return &BuildStrategy{
		ProjectPath:     projectPath,
		Layers:          make([]BuildLayer, len(emailSenderLayers)),
		BuildOrder:      []string{},
		ErrorSummary:    make(map[string]int),
		Recommendations: []string{},
		Timestamp:       time.Now(),
		Config: BuildConfig{
			MaxParallelBuilds:   4,
			BuildTimeout:        5 * time.Minute,
			TestTimeout:         3 * time.Minute,
			FailFast:            false,
			ContinueOnError:     true,
			EnableTests:         true,
			EnableOptimizations: true,
			LayerPriorities:     make(map[string]int),
		},
	}
}

// LoadConfig loads build configuration from file
func (bs *BuildStrategy) LoadConfig(configFile string) error {
	data, err := ioutil.ReadFile(configFile)
	if err != nil {
		return err
	}

	return json.Unmarshal(data, &bs.Config)
}

// InitializeBuildStrategy initializes the build strategy with EMAIL_SENDER_1 layers
func (bs *BuildStrategy) InitializeBuildStrategy() {
	// Copy layer definitions
	copy(bs.Layers, emailSenderLayers)

	// Initialize layer metadata
	for i := range bs.Layers {
		bs.Layers[i].Status = "pending"
		bs.Layers[i].TestResults = []TestResult{}
		
		// Initialize component metadata
		for j := range bs.Layers[i].Components {
			bs.Layers[i].Components[j].Status = "pending"
			bs.Layers[i].Components[j].Warnings = []string{}
			bs.Layers[i].Components[j].Metadata = make(map[string]string)
		}

		// Set layer priorities
		bs.Config.LayerPriorities[bs.Layers[i].Name] = bs.Layers[i].Priority
	}

	// Calculate build order based on dependencies
	bs.calculateBuildOrder()

	fmt.Printf("✅ Build strategy initialized with %d layers\n", len(bs.Layers))
	fmt.Printf("   Build order: %s\n", strings.Join(bs.BuildOrder, " → "))
}

// calculateBuildOrder calculates the optimal build order based on dependencies
func (bs *BuildStrategy) calculateBuildOrder() {
	visited := make(map[string]bool)
	order := []string{}

	var visit func(layerName string)
	visit = func(layerName string) {
		if visited[layerName] {
			return
		}

		// Find layer by name
		var layer *BuildLayer
		for i := range bs.Layers {
			if bs.Layers[i].Name == layerName {
				layer = &bs.Layers[i]
				break
			}
		}

		if layer == nil {
			return
		}

		// Visit dependencies first
		for _, dep := range layer.Dependencies {
			visit(dep)
		}

		visited[layerName] = true
		order = append(order, layerName)
	}

	// Visit all layers
	for _, layer := range bs.Layers {
		visit(layer.Name)
	}

	bs.BuildOrder = order
}

// ValidateProjectStructure validates the EMAIL_SENDER_1 project structure
func (bs *BuildStrategy) ValidateProjectStructure() error {
	requiredPaths := []string{
		"internal",
		"cmd", 
		"scripts",
		"go.mod",
	}

	missingPaths := []string{}

	for _, path := range requiredPaths {
		fullPath := filepath.Join(bs.ProjectPath, path)
		if _, err := os.Stat(fullPath); os.IsNotExist(err) {
			missingPaths = append(missingPaths, path)
		}
	}

	if len(missingPaths) > 0 {
		return fmt.Errorf("missing required paths: %s", strings.Join(missingPaths, ", "))
	}

	// Validate component paths
	for layerIdx, layer := range bs.Layers {
		for compIdx, component := range layer.Components {
			componentPath := filepath.Join(bs.ProjectPath, component.Path)
			if _, err := os.Stat(componentPath); os.IsNotExist(err) {
				// Create placeholder warning
				bs.Layers[layerIdx].Components[compIdx].Warnings = append(
					bs.Layers[layerIdx].Components[compIdx].Warnings,
					fmt.Sprintf("Component path does not exist: %s", component.Path),
				)
			}
		}
	}

	fmt.Printf("✅ Project structure validation completed\n")
	return nil
}

// ExecuteProgressiveBuild executes the progressive build strategy
func (bs *BuildStrategy) ExecuteProgressiveBuild() error {
	startTime := time.Now()
	totalErrors := 0

	fmt.Printf("🏗️ Starting progressive build in order: %s\n", strings.Join(bs.BuildOrder, " → "))

	for _, layerName := range bs.BuildOrder {
		layerIdx := bs.findLayerIndex(layerName)
		if layerIdx == -1 {
			continue
		}

		layer := &bs.Layers[layerIdx]
		
		fmt.Printf("\n📦 Building Layer: %s (Priority %d)\n", layer.Name, layer.Priority)
		fmt.Printf("   Dependencies: %s\n", strings.Join(layer.Dependencies, ", "))
		fmt.Printf("   Components: %d\n", len(layer.Components))

		// Build layer
		layerStartTime := time.Now()
		layerErrors := bs.buildLayer(layer)
		layer.BuildTime = time.Since(layerStartTime)
		
		if layerErrors > 0 {
			layer.Status = "failed"
			totalErrors += layerErrors
			bs.ErrorSummary[layer.Name] = layerErrors
			
			fmt.Printf("   ❌ Layer %s failed with %d errors\n", layer.Name, layerErrors)
			
			if bs.Config.FailFast {
				fmt.Printf("   🛑 Fail-fast enabled, stopping build\n")
				break
			}
		} else {
			layer.Status = "success"
			fmt.Printf("   ✅ Layer %s completed successfully in %v\n", layer.Name, layer.BuildTime)
		}

		// Run tests if enabled
		if bs.Config.EnableTests {
			fmt.Printf("   🧪 Running tests for layer %s...\n", layer.Name)
			bs.runLayerTests(layer)
		}
	}

	bs.TotalTime = time.Since(startTime)
	
	// Calculate success rate
	successfulLayers := 0
	for _, layer := range bs.Layers {
		if layer.Status == "success" {
			successfulLayers++
		}
	}
	bs.SuccessRate = float64(successfulLayers) / float64(len(bs.Layers)) * 100

	fmt.Printf("\n📊 Build Summary:\n")
	fmt.Printf("   Total Time: %v\n", bs.TotalTime)
	fmt.Printf("   Success Rate: %.1f%%\n", bs.SuccessRate)
	fmt.Printf("   Total Errors: %d\n", totalErrors)

	if totalErrors > 0 {
		return fmt.Errorf("build completed with %d errors", totalErrors)
	}

	return nil
}

// buildLayer builds all components in a layer
func (bs *BuildStrategy) buildLayer(layer *BuildLayer) int {
	if bs.Config.MaxParallelBuilds > 1 {
		return bs.buildLayerParallel(layer)
	}
	return bs.buildLayerSequential(layer)
}

// buildLayerSequential builds layer components sequentially
func (bs *BuildStrategy) buildLayerSequential(layer *BuildLayer) int {
	totalErrors := 0

	for i := range layer.Components {
		component := &layer.Components[i]
		
		fmt.Printf("     🔨 Building %s (%s)...", component.Name, component.Type)
		
		startTime := time.Now()
		err := bs.buildComponent(component)
		component.BuildTime = time.Since(startTime)
		
		if err != nil {
			component.Status = "failed"
			component.ErrorCount++
			totalErrors++
			fmt.Printf(" ❌ Failed in %v\n", component.BuildTime)
			fmt.Printf("        Error: %v\n", err)
		} else {
			component.Status = "success"
			fmt.Printf(" ✅ Success in %v\n", component.BuildTime)
		}
	}

	return totalErrors
}

// buildLayerParallel builds layer components in parallel
func (bs *BuildStrategy) buildLayerParallel(layer *BuildLayer) int {
	var wg sync.WaitGroup
	var mu sync.Mutex
	totalErrors := 0

	semaphore := make(chan struct{}, bs.Config.MaxParallelBuilds)

	for i := range layer.Components {
		wg.Add(1)
		go func(component *BuildComponent) {
			defer wg.Done()
			
			semaphore <- struct{}{}
			defer func() { <-semaphore }()

			fmt.Printf("     🔨 Building %s (%s)...\n", component.Name, component.Type)
			
			startTime := time.Now()
			err := bs.buildComponent(component)
			component.BuildTime = time.Since(startTime)
			
			mu.Lock()
			if err != nil {
				component.Status = "failed"
				component.ErrorCount++
				totalErrors++
				fmt.Printf("     ❌ %s failed in %v: %v\n", component.Name, component.BuildTime, err)
			} else {
				component.Status = "success"
				fmt.Printf("     ✅ %s success in %v\n", component.Name, component.BuildTime)
			}
			mu.Unlock()
		}(&layer.Components[i])
	}

	wg.Wait()
	return totalErrors
}

// buildComponent builds a single component
func (bs *BuildStrategy) buildComponent(component *BuildComponent) error {
	if component.BuildCmd == "" {
		return fmt.Errorf("no build command specified")
	}

	// Change to component directory
	componentPath := filepath.Join(bs.ProjectPath, component.Path)
	
	// Parse build command
	cmdParts := strings.Fields(component.BuildCmd)
	if len(cmdParts) == 0 {
		return fmt.Errorf("empty build command")
	}

	// Create command
	cmd := exec.Command(cmdParts[0], cmdParts[1:]...)
	cmd.Dir = componentPath
	
	// Set timeout
	if bs.Config.BuildTimeout > 0 {
		// Note: timeout implementation would need context.WithTimeout in real scenario
	}

	// Execute command
	output, err := cmd.CombinedOutput()
	component.Metadata["build_output"] = string(output)
	
	if err != nil {
		return fmt.Errorf("build failed: %v\nOutput: %s", err, string(output))
	}

	return nil
}

// runLayerTests runs tests for all components in a layer
func (bs *BuildStrategy) runLayerTests(layer *BuildLayer) {
	for i := range layer.Components {
		component := &layer.Components[i]
		
		if component.TestCmd == "" {
			continue
		}

		fmt.Printf("       🧪 Testing %s...", component.Name)
		
		startTime := time.Now()
		result := bs.runComponentTest(component)
		result.Duration = time.Since(startTime)
		
		layer.TestResults = append(layer.TestResults, result)
		
		if result.Status == "passed" {
			fmt.Printf(" ✅ Passed in %v\n", result.Duration)
		} else {
			fmt.Printf(" ❌ Failed in %v\n", result.Duration)
			if len(result.Errors) > 0 {
				fmt.Printf("         Errors: %s\n", strings.Join(result.Errors, ", "))
			}
		}
	}
}

// runComponentTest runs tests for a single component
func (bs *BuildStrategy) runComponentTest(component *BuildComponent) TestResult {
	result := TestResult{
		Component: component.Name,
		TestType:  "unit",
		Status:    "failed",
		Errors:    []string{},
	}

	componentPath := filepath.Join(bs.ProjectPath, component.Path)
	
	// Parse test command
	cmdParts := strings.Fields(component.TestCmd)
	if len(cmdParts) == 0 {
		result.Errors = append(result.Errors, "empty test command")
		return result
	}

	// Create command
	cmd := exec.Command(cmdParts[0], cmdParts[1:]...)
	cmd.Dir = componentPath

	// Execute command
	output, err := cmd.CombinedOutput()
	result.Output = string(output)
	
	if err != nil {
		result.Errors = append(result.Errors, err.Error())
		return result
	}

	result.Status = "passed"
	return result
}

// findLayerIndex finds the index of a layer by name
func (bs *BuildStrategy) findLayerIndex(layerName string) int {
	for i, layer := range bs.Layers {
		if layer.Name == layerName {
			return i
		}
	}
	return -1
}

// GenerateReport generates a comprehensive build report
func (bs *BuildStrategy) GenerateReport(outputFile string) error {
	// Generate recommendations
	bs.generateRecommendations()

	jsonData, err := json.MarshalIndent(bs, "", "  ")
	if err != nil {
		return err
	}

	return ioutil.WriteFile(outputFile, jsonData, 0644)
}

// generateRecommendations generates build optimization recommendations
func (bs *BuildStrategy) generateRecommendations() {
	bs.Recommendations = []string{}

	// Analyze build performance
	if bs.TotalTime > 10*time.Minute {
		bs.Recommendations = append(bs.Recommendations, "Consider increasing parallel builds to reduce total build time")
	}

	// Analyze success rate
	if bs.SuccessRate < 80 {
		bs.Recommendations = append(bs.Recommendations, "Low success rate detected - review component dependencies and build commands")
	}

	// Analyze error patterns
	if len(bs.ErrorSummary) > 0 {
		bs.Recommendations = append(bs.Recommendations, "Focus on fixing errors in critical layers first (foundation, rag_engine)")
	}

	// EMAIL_SENDER_1 specific recommendations
	bs.Recommendations = append(bs.Recommendations, "Ensure Go modules are properly initialized with 'go mod tidy'")
	bs.Recommendations = append(bs.Recommendations, "Verify Qdrant connection before building storage layer")
	bs.Recommendations = append(bs.Recommendations, "Configure environment variables for N8N integration tests")
}

// DisplaySummary displays a summary of the build results
func (bs *BuildStrategy) DisplaySummary() {
	fmt.Printf("\n" + strings.Repeat("=", 70) + "\n")
	fmt.Printf("🏗️ EMAIL_SENDER_1 PROGRESSIVE BUILD SUMMARY\n")
	fmt.Printf(strings.Repeat("=", 70) + "\n")
	
	fmt.Printf("📁 Project: %s\n", bs.ProjectPath)
	fmt.Printf("🕐 Build Time: %s\n", bs.Timestamp.Format("2006-01-02 15:04:05"))
	fmt.Printf("⏱️ Total Duration: %v\n\n", bs.TotalTime)
	
	fmt.Printf("📈 BUILD STATISTICS:\n")
	fmt.Printf("  • Total Layers: %d\n", len(bs.Layers))
	fmt.Printf("  • Success Rate: %.1f%%\n", bs.SuccessRate)
	fmt.Printf("  • Failed Layers: %d\n", len(bs.ErrorSummary))
	
	// Layer-by-layer summary
	fmt.Printf("\n🏗️ LAYER RESULTS:\n")
	for _, layerName := range bs.BuildOrder {
		layerIdx := bs.findLayerIndex(layerName)
		if layerIdx == -1 {
			continue
		}
		
		layer := bs.Layers[layerIdx]
		statusIcon := "✅"
		if layer.Status == "failed" {
			statusIcon = "❌"
		} else if layer.Status == "pending" {
			statusIcon = "⏳"
		}
		
		fmt.Printf("  %s %s (Priority %d) - %v\n", statusIcon, layer.Name, layer.Priority, layer.BuildTime)
		
		// Component details for failed layers
		if layer.Status == "failed" {
			for _, component := range layer.Components {
				if component.Status == "failed" {
					fmt.Printf("      ❌ %s: %d errors\n", component.Name, component.ErrorCount)
				}
			}
		}
	}
	
	// Error summary
	if len(bs.ErrorSummary) > 0 {
		fmt.Printf("\n⚠️ ERROR SUMMARY:\n")
		
		// Sort by error count
		type layerError struct {
			layer string
			count int
		}
		
		var layerErrors []layerError
		for layer, count := range bs.ErrorSummary {
			layerErrors = append(layerErrors, layerError{layer, count})
		}
		
		sort.Slice(layerErrors, func(i, j int) bool {
			return layerErrors[i].count > layerErrors[j].count
		})
		
		for _, le := range layerErrors {
			fmt.Printf("  • %s: %d errors\n", le.layer, le.count)
		}
	}
	
	// Test results summary
	totalTests := 0
	passedTests := 0
	for _, layer := range bs.Layers {
		for _, result := range layer.TestResults {
			totalTests++
			if result.Status == "passed" {
				passedTests++
			}
		}
	}
	
	if totalTests > 0 {
		fmt.Printf("\n🧪 TEST RESULTS:\n")
		fmt.Printf("  • Total Tests: %d\n", totalTests)
		fmt.Printf("  • Passed: %d\n", passedTests)
		fmt.Printf("  • Failed: %d\n", totalTests-passedTests)
		fmt.Printf("  • Pass Rate: %.1f%%\n", float64(passedTests)/float64(totalTests)*100)
	}
	
	// Recommendations
	if len(bs.Recommendations) > 0 {
		fmt.Printf("\n💡 RECOMMENDATIONS:\n")
		for i, rec := range bs.Recommendations {
			fmt.Printf("  %d. %s\n", i+1, rec)
		}
	}
	
	fmt.Printf("\n" + strings.Repeat("=", 70) + "\n")
}

// if function for conditional string selection
func if(condition bool, trueVal, falseVal string) string {
	if condition {
		return trueVal
	}
	return falseVal
}
