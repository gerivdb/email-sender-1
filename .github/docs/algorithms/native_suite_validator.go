// native_suite_validator.go
// Complete Native Go Suite Validator for EMAIL_SENDER_1
// Replaces all PowerShell validation scripts with pure Go implementation
// Provides comprehensive validation of the 8-algorithm native Go ecosystem

package main

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// ValidationSuite represents the complete validation suite
type ValidationSuite struct {
	ProjectPath     string                   `json:"project_path"`
	AlgorithmsPath  string                   `json:"algorithms_path"`
	Timestamp       time.Time                `json:"timestamp"`
	ValidationTests []ValidationTest         `json:"validation_tests"`
	AlgorithmStatus map[string]AlgorithmInfo `json:"algorithm_status"`
	ComplianceScore float64                  `json:"compliance_score"`
	Summary         ValidationSummary        `json:"summary"`
	Recommendations []string                 `json:"recommendations"`
}

// ValidationTest represents a single validation test
type ValidationTest struct {
	Name        string        `json:"name"`
	Category    string        `json:"category"`
	Status      string        `json:"status"`
	Duration    time.Duration `json:"duration"`
	Message     string        `json:"message"`
	Details     []string      `json:"details"`
	Criticality string        `json:"criticality"`
}

// AlgorithmInfo contains information about each algorithm
type AlgorithmInfo struct {
	ID              string   `json:"id"`
	Name            string   `json:"name"`
	HasGoImpl       bool     `json:"has_go_implementation"`
	HasPowerShell   bool     `json:"has_powershell_files"`
	PowerShellFiles []string `json:"powershell_files"`
	GoFiles         []string `json:"go_files"`
	Compilable      bool     `json:"compilable"`
	TestsPresent    bool     `json:"tests_present"`
	Documentation   bool     `json:"documentation"`
	Status          string   `json:"status"`
}

// ValidationSummary provides overall validation statistics
type ValidationSummary struct {
	TotalTests          int           `json:"total_tests"`
	PassedTests         int           `json:"passed_tests"`
	FailedTests         int           `json:"failed_tests"`
	SkippedTests        int           `json:"skipped_tests"`
	PassRate            float64       `json:"pass_rate"`
	GoNativeCompliance  float64       `json:"go_native_compliance"`
	PowerShellRemaining int           `json:"powershell_remaining"`
	AlgorithmsCovered   int           `json:"algorithms_covered"`
	TotalDuration       time.Duration `json:"total_duration"`
}

// Expected 8 algorithms for EMAIL_SENDER_1
var expectedAlgorithms = []string{
	"error-triage",
	"binary-search",
	"dependency-analysis",
	"progressive-build",
	"config-validator",
	"auto-fix",
	"analysis-pipeline",
	"dependency-resolution",
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run native_suite_validator.go <project_path> [output_file]")
		fmt.Println("Example: go run native_suite_validator.go . validation_report.json")
		os.Exit(1)
	}

	projectPath := os.Args[1]
	outputFile := "native_validation_report.json"

	if len(os.Args) > 2 {
		outputFile = os.Args[2]
	}

	fmt.Printf("🔍 EMAIL_SENDER_1 Native Go Suite Validator\n")
	fmt.Printf("=" + strings.Repeat("=", 50) + "\n")
	fmt.Printf("📁 Project Path: %s\n", projectPath)
	fmt.Printf("📄 Output File: %s\n", outputFile)
	fmt.Printf("🕐 Started: %s\n\n", time.Now().Format("2006-01-02 15:04:05"))

	validator := NewValidationSuite(projectPath)

	// Execute all validation tests
	validator.RunAllValidations()

	// Generate comprehensive report
	err := validator.GenerateReport(outputFile)
	if err != nil {
		log.Fatalf("Failed to generate report: %v", err)
	}

	// Display results
	validator.DisplayResults()

	fmt.Printf("\n✅ Validation complete! Report saved to: %s\n", outputFile)

	// Exit with appropriate code
	if validator.Summary.GoNativeCompliance < 100.0 {
		fmt.Printf("⚠️ Warning: Go native compliance is %.1f%% (target: 100%%)\n", validator.Summary.GoNativeCompliance)
		os.Exit(1)
	}
}

// NewValidationSuite creates a new validation suite
func NewValidationSuite(projectPath string) *ValidationSuite {
	algorithmsPath := filepath.Join(projectPath, ".github", "docs", "algorithms")

	return &ValidationSuite{
		ProjectPath:     projectPath,
		AlgorithmsPath:  algorithmsPath,
		Timestamp:       time.Now(),
		ValidationTests: []ValidationTest{},
		AlgorithmStatus: make(map[string]AlgorithmInfo),
		Recommendations: []string{},
	}
}

// RunAllValidations executes all validation tests
func (vs *ValidationSuite) RunAllValidations() {
	startTime := time.Now()

	// 1. Validate project structure
	vs.runTest("Project Structure", "structure", vs.validateProjectStructure)

	// 2. Scan for PowerShell files
	vs.runTest("PowerShell Elimination", "compliance", vs.validatePowerShellElimination)

	// 3. Validate Go implementations
	vs.runTest("Go Implementation Coverage", "coverage", vs.validateGoImplementations)

	// 4. Test Go compilation
	vs.runTest("Go Compilation", "compilation", vs.validateGoCompilation)

	// 5. Validate orchestrator
	vs.runTest("Native Orchestrator", "orchestrator", vs.validateNativeOrchestrator)

	// 6. Check algorithm dependencies
	vs.runTest("Algorithm Dependencies", "dependencies", vs.validateAlgorithmDependencies)

	// 7. Validate configuration
	vs.runTest("Configuration Files", "configuration", vs.validateConfigurationFiles)

	// 8. Verify documentation
	vs.runTest("Documentation", "documentation", vs.validateDocumentation)

	vs.Summary.TotalDuration = time.Since(startTime)
	vs.calculateSummary()
}

// runTest executes a single validation test
func (vs *ValidationSuite) runTest(name, category string, testFunc func() (bool, string, []string)) {
	fmt.Printf("🔍 Running: %s...", name)

	startTime := time.Now()
	success, message, details := testFunc()
	duration := time.Since(startTime)

	status := "PASS"
	criticality := "medium"

	if !success {
		status = "FAIL"
		criticality = "high"
		fmt.Printf(" ❌ FAIL\n")
	} else {
		fmt.Printf(" ✅ PASS\n")
	}

	test := ValidationTest{
		Name:        name,
		Category:    category,
		Status:      status,
		Duration:    duration,
		Message:     message,
		Details:     details,
		Criticality: criticality,
	}

	vs.ValidationTests = append(vs.ValidationTests, test)
}

// validateProjectStructure validates the basic project structure
func (vs *ValidationSuite) validateProjectStructure() (bool, string, []string) {
	requiredPaths := []string{
		".github/docs/algorithms",
		".github/docs/algorithms/email_sender_orchestrator.go",
		".github/docs/algorithms/algorithms_implementations.go",
		".github/docs/algorithms/email_sender_orchestrator_config.json",
		".github/docs/algorithms/go.mod",
		".github/docs/algorithms/shared",
	}

	missingPaths := []string{}
	details := []string{}

	for _, path := range requiredPaths {
		fullPath := filepath.Join(vs.ProjectPath, path)
		if _, err := os.Stat(fullPath); os.IsNotExist(err) {
			missingPaths = append(missingPaths, path)
			details = append(details, fmt.Sprintf("Missing: %s", path))
		} else {
			details = append(details, fmt.Sprintf("Found: %s", path))
		}
	}

	if len(missingPaths) > 0 {
		return false, fmt.Sprintf("Missing %d required paths", len(missingPaths)), details
	}

	return true, "All required project structure components found", details
}

// validatePowerShellElimination checks for remaining PowerShell files
func (vs *ValidationSuite) validatePowerShellElimination() (bool, string, []string) {
	details := []string{}
	powerShellFiles := []string{}

	err := filepath.WalkDir(vs.AlgorithmsPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if strings.HasSuffix(strings.ToLower(d.Name()), ".ps1") {
			relPath, _ := filepath.Rel(vs.AlgorithmsPath, path)
			powerShellFiles = append(powerShellFiles, relPath)
			details = append(details, fmt.Sprintf("PowerShell file found: %s", relPath))
		}

		return nil
	})

	if err != nil {
		return false, fmt.Sprintf("Error scanning for PowerShell files: %v", err), details
	}

	if len(powerShellFiles) > 0 {
		return false, fmt.Sprintf("Found %d PowerShell files (target: 0)", len(powerShellFiles)), details
	}

	details = append(details, "✅ No PowerShell files found - Complete Go native implementation achieved")
	return true, "PowerShell elimination complete", details
}

// validateGoImplementations validates that all algorithms have Go implementations
func (vs *ValidationSuite) validateGoImplementations() (bool, string, []string) {
	details := []string{}
	allValid := true

	for _, algorithmID := range expectedAlgorithms {
		algorithmPath := filepath.Join(vs.AlgorithmsPath, algorithmID)

		info := AlgorithmInfo{
			ID:              algorithmID,
			Name:            algorithmID,
			HasGoImpl:       false,
			HasPowerShell:   false,
			PowerShellFiles: []string{},
			GoFiles:         []string{},
			Status:          "unknown",
		}

		// Check if algorithm directory exists
		if _, err := os.Stat(algorithmPath); os.IsNotExist(err) {
			info.Status = "missing"
			details = append(details, fmt.Sprintf("❌ %s: Directory not found", algorithmID))
			allValid = false
		} else {
			// Scan for Go and PowerShell files
			err := filepath.WalkDir(algorithmPath, func(path string, d fs.DirEntry, err error) error {
				if err != nil {
					return err
				}

				fileName := strings.ToLower(d.Name())
				if strings.HasSuffix(fileName, ".go") {
					info.GoFiles = append(info.GoFiles, d.Name())
					info.HasGoImpl = true
				} else if strings.HasSuffix(fileName, ".ps1") {
					info.PowerShellFiles = append(info.PowerShellFiles, d.Name())
					info.HasPowerShell = true
				}

				return nil
			})

			if err != nil {
				info.Status = "error"
				details = append(details, fmt.Sprintf("❌ %s: Error scanning directory: %v", algorithmID, err))
				allValid = false
			} else {
				// Determine status
				if info.HasGoImpl && !info.HasPowerShell {
					info.Status = "go_native"
					details = append(details, fmt.Sprintf("✅ %s: Go native (%d Go files)", algorithmID, len(info.GoFiles)))
				} else if info.HasGoImpl && info.HasPowerShell {
					info.Status = "mixed"
					details = append(details, fmt.Sprintf("⚠️ %s: Mixed (%d Go, %d PS1)", algorithmID, len(info.GoFiles), len(info.PowerShellFiles)))
					allValid = false
				} else if !info.HasGoImpl && info.HasPowerShell {
					info.Status = "powershell_only"
					details = append(details, fmt.Sprintf("❌ %s: PowerShell only (%d PS1 files)", algorithmID, len(info.PowerShellFiles)))
					allValid = false
				} else {
					info.Status = "no_implementation"
					details = append(details, fmt.Sprintf("❌ %s: No implementation found", algorithmID))
					allValid = false
				}
			}
		}

		vs.AlgorithmStatus[algorithmID] = info
	}

	message := fmt.Sprintf("Go implementation coverage: %d/%d algorithms", vs.countGoNativeAlgorithms(), len(expectedAlgorithms))
	return allValid, message, details
}

// validateGoCompilation tests that Go files can be compiled
func (vs *ValidationSuite) validateGoCompilation() (bool, string, []string) {
	details := []string{}
	allCompilable := true

	// Test main orchestrator compilation
	orchestratorPath := filepath.Join(vs.AlgorithmsPath, "email_sender_orchestrator.go")
	if vs.testGoFileCompilation(orchestratorPath) {
		details = append(details, "✅ Main orchestrator compiles successfully")
	} else {
		details = append(details, "❌ Main orchestrator compilation failed")
		allCompilable = false
	}

	// Test algorithm implementations compilation
	implPath := filepath.Join(vs.AlgorithmsPath, "algorithms_implementations.go")
	if vs.testGoFileCompilation(implPath) {
		details = append(details, "✅ Algorithm implementations compile successfully")
	} else {
		details = append(details, "❌ Algorithm implementations compilation failed")
		allCompilable = false
	}

	// Test individual algorithm compilation
	for algorithmID, info := range vs.AlgorithmStatus {
		if info.HasGoImpl {
			algorithmPath := filepath.Join(vs.AlgorithmsPath, algorithmID)
			if vs.testAlgorithmCompilation(algorithmPath) {
				details = append(details, fmt.Sprintf("✅ %s compiles successfully", algorithmID))

				// Update algorithm info
				updatedInfo := info
				updatedInfo.Compilable = true
				vs.AlgorithmStatus[algorithmID] = updatedInfo
			} else {
				details = append(details, fmt.Sprintf("❌ %s compilation failed", algorithmID))
				allCompilable = false
			}
		}
	}

	message := "Go compilation validation complete"
	if !allCompilable {
		message = "Some Go files failed to compile"
	}

	return allCompilable, message, details
}

// testGoFileCompilation tests if a single Go file compiles
func (vs *ValidationSuite) testGoFileCompilation(filePath string) bool {
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return false
	}

	// Try to parse the file (basic syntax check)
	cmd := exec.Command("go", "run", "-check", filePath)
	cmd.Dir = filepath.Dir(filePath)

	err := cmd.Run()
	return err == nil
}

// testAlgorithmCompilation tests if an algorithm directory compiles
func (vs *ValidationSuite) testAlgorithmCompilation(algorithmPath string) bool {
	// Look for main Go files in the algorithm directory
	entries, err := os.ReadDir(algorithmPath)
	if err != nil {
		return false
	}

	for _, entry := range entries {
		if strings.HasSuffix(entry.Name(), ".go") && !strings.HasSuffix(entry.Name(), "_test.go") {
			filePath := filepath.Join(algorithmPath, entry.Name())

			// Basic syntax check
			cmd := exec.Command("go", "run", "-check", filePath)
			cmd.Dir = algorithmPath

			if cmd.Run() == nil {
				return true
			}
		}
	}

	return false
}

// validateNativeOrchestrator validates the native Go orchestrator
func (vs *ValidationSuite) validateNativeOrchestrator() (bool, string, []string) {
	details := []string{}

	orchestratorPath := filepath.Join(vs.AlgorithmsPath, "email_sender_orchestrator.go")
	configPath := filepath.Join(vs.AlgorithmsPath, "email_sender_orchestrator_config.json")
	implPath := filepath.Join(vs.AlgorithmsPath, "algorithms_implementations.go")

	requiredFiles := map[string]string{
		orchestratorPath: "Main orchestrator",
		configPath:       "Orchestrator configuration",
		implPath:         "Algorithm implementations",
	}

	allPresent := true

	for filePath, description := range requiredFiles {
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			details = append(details, fmt.Sprintf("❌ %s missing: %s", description, filePath))
			allPresent = false
		} else {
			details = append(details, fmt.Sprintf("✅ %s found", description))
		}
	}

	// Validate orchestrator configuration
	if allPresent {
		configValid := vs.validateOrchestratorConfig(configPath)
		if configValid {
			details = append(details, "✅ Orchestrator configuration is valid")
		} else {
			details = append(details, "❌ Orchestrator configuration has issues")
			allPresent = false
		}
	}

	message := "Native orchestrator validation complete"
	if !allPresent {
		message = "Native orchestrator has missing components"
	}

	return allPresent, message, details
}

// validateOrchestratorConfig validates the orchestrator configuration file
func (vs *ValidationSuite) validateOrchestratorConfig(configPath string) bool {
	data, err := ioutil.ReadFile(configPath)
	if err != nil {
		return false
	}

	var config map[string]interface{}
	err = json.Unmarshal(data, &config)
	if err != nil {
		return false
	}

	// Check for required configuration sections
	requiredSections := []string{"algorithms", "execution", "reporting"}
	for _, section := range requiredSections {
		if _, exists := config[section]; !exists {
			return false
		}
	}

	return true
}

// validateAlgorithmDependencies validates algorithm dependencies
func (vs *ValidationSuite) validateAlgorithmDependencies() (bool, string, []string) {
	details := []string{}

	// Check shared directory
	sharedPath := filepath.Join(vs.AlgorithmsPath, "shared")
	if _, err := os.Stat(sharedPath); os.IsNotExist(err) {
		details = append(details, "❌ Shared directory missing")
		return false, "Algorithm dependencies validation failed", details
	}

	// Check for shared types and utils
	requiredSharedFiles := []string{"types.go", "utils.go"}
	for _, file := range requiredSharedFiles {
		filePath := filepath.Join(sharedPath, file)
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			details = append(details, fmt.Sprintf("❌ Missing shared file: %s", file))
		} else {
			details = append(details, fmt.Sprintf("✅ Found shared file: %s", file))
		}
	}

	// Check Go module
	goModPath := filepath.Join(vs.AlgorithmsPath, "go.mod")
	if _, err := os.Stat(goModPath); os.IsNotExist(err) {
		details = append(details, "❌ go.mod missing")
		return false, "Go module not found", details
	} else {
		details = append(details, "✅ go.mod found")
	}

	return true, "Algorithm dependencies validation complete", details
}

// validateConfigurationFiles validates configuration files
func (vs *ValidationSuite) validateConfigurationFiles() (bool, string, []string) {
	details := []string{}
	allValid := true

	configFiles := map[string]string{
		"email_sender_orchestrator_config.json": "Main orchestrator config",
		"go.mod":                                "Go module definition",
	}

	for fileName, description := range configFiles {
		filePath := filepath.Join(vs.AlgorithmsPath, fileName)
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			details = append(details, fmt.Sprintf("❌ %s missing: %s", description, fileName))
			allValid = false
		} else {
			details = append(details, fmt.Sprintf("✅ %s found", description))
		}
	}

	return allValid, "Configuration files validation complete", details
}

// validateDocumentation validates algorithm documentation
func (vs *ValidationSuite) validateDocumentation() (bool, string, []string) {
	details := []string{}
	documentedAlgorithms := 0

	for _, algorithmID := range expectedAlgorithms {
		algorithmPath := filepath.Join(vs.AlgorithmsPath, algorithmID)
		readmePath := filepath.Join(algorithmPath, "README.md")

		if _, err := os.Stat(readmePath); os.IsNotExist(err) {
			details = append(details, fmt.Sprintf("⚠️ %s: No README.md found", algorithmID))
		} else {
			details = append(details, fmt.Sprintf("✅ %s: README.md present", algorithmID))
			documentedAlgorithms++

			// Update algorithm info
			if info, exists := vs.AlgorithmStatus[algorithmID]; exists {
				info.Documentation = true
				vs.AlgorithmStatus[algorithmID] = info
			}
		}
	}

	documentationRate := float64(documentedAlgorithms) / float64(len(expectedAlgorithms)) * 100
	message := fmt.Sprintf("Documentation coverage: %.1f%% (%d/%d algorithms)",
		documentationRate, documentedAlgorithms, len(expectedAlgorithms))

	return documentationRate >= 80.0, message, details
}

// countGoNativeAlgorithms counts algorithms that are fully Go native
func (vs *ValidationSuite) countGoNativeAlgorithms() int {
	count := 0
	for _, info := range vs.AlgorithmStatus {
		if info.Status == "go_native" {
			count++
		}
	}
	return count
}

// calculateSummary calculates validation summary statistics
func (vs *ValidationSuite) calculateSummary() {
	vs.Summary.TotalTests = len(vs.ValidationTests)

	for _, test := range vs.ValidationTests {
		switch test.Status {
		case "PASS":
			vs.Summary.PassedTests++
		case "FAIL":
			vs.Summary.FailedTests++
		case "SKIP":
			vs.Summary.SkippedTests++
		}
	}

	if vs.Summary.TotalTests > 0 {
		vs.Summary.PassRate = float64(vs.Summary.PassedTests) / float64(vs.Summary.TotalTests) * 100
	}

	// Calculate Go native compliance
	goNativeCount := vs.countGoNativeAlgorithms()
	vs.Summary.AlgorithmsCovered = goNativeCount
	vs.Summary.GoNativeCompliance = float64(goNativeCount) / float64(len(expectedAlgorithms)) * 100

	// Count remaining PowerShell files
	powerShellCount := 0
	for _, info := range vs.AlgorithmStatus {
		powerShellCount += len(info.PowerShellFiles)
	}
	vs.Summary.PowerShellRemaining = powerShellCount

	// Calculate overall compliance score
	vs.ComplianceScore = (vs.Summary.PassRate + vs.Summary.GoNativeCompliance) / 2

	// Generate recommendations
	vs.generateRecommendations()
}

// generateRecommendations generates improvement recommendations
func (vs *ValidationSuite) generateRecommendations() {
	vs.Recommendations = []string{}

	if vs.Summary.GoNativeCompliance < 100.0 {
		vs.Recommendations = append(vs.Recommendations,
			"Complete migration of remaining algorithms to pure Go implementation")
	}

	if vs.Summary.PowerShellRemaining > 0 {
		vs.Recommendations = append(vs.Recommendations,
			fmt.Sprintf("Remove %d remaining PowerShell files for complete Go native compliance", vs.Summary.PowerShellRemaining))
	}

	if vs.Summary.PassRate < 100.0 {
		vs.Recommendations = append(vs.Recommendations,
			"Address failed validation tests for improved system reliability")
	}

	// Check for missing documentation
	undocumentedCount := 0
	for _, info := range vs.AlgorithmStatus {
		if !info.Documentation {
			undocumentedCount++
		}
	}

	if undocumentedCount > 0 {
		vs.Recommendations = append(vs.Recommendations,
			fmt.Sprintf("Add documentation (README.md) for %d algorithms", undocumentedCount))
	}

	// Performance recommendations
	if vs.ComplianceScore >= 95.0 {
		vs.Recommendations = append(vs.Recommendations,
			"Excellent compliance achieved! Consider implementing performance benchmarks")
	}
}

// GenerateReport generates a comprehensive validation report
func (vs *ValidationSuite) GenerateReport(outputFile string) error {
	jsonData, err := json.MarshalIndent(vs, "", "  ")
	if err != nil {
		return err
	}

	return ioutil.WriteFile(outputFile, jsonData, 0644)
}

// DisplayResults displays validation results in the terminal
func (vs *ValidationSuite) DisplayResults() {
	fmt.Printf("\n" + strings.Repeat("=", 70) + "\n")
	fmt.Printf("🔍 EMAIL_SENDER_1 NATIVE GO VALIDATION RESULTS\n")
	fmt.Printf(strings.Repeat("=", 70) + "\n")

	fmt.Printf("🕐 Validation Time: %s\n", vs.Timestamp.Format("2006-01-02 15:04:05"))
	fmt.Printf("⏱️ Total Duration: %v\n\n", vs.Summary.TotalDuration)

	// Overall compliance
	fmt.Printf("📊 COMPLIANCE SCORE: %.1f%%\n", vs.ComplianceScore)
	complianceStatus := "🟡 PARTIAL"
	if vs.ComplianceScore >= 95.0 {
		complianceStatus = "🟢 EXCELLENT"
	} else if vs.ComplianceScore >= 80.0 {
		complianceStatus = "🟡 GOOD"
	} else {
		complianceStatus = "🔴 NEEDS WORK"
	}
	fmt.Printf("Status: %s\n\n", complianceStatus)

	// Test results summary
	fmt.Printf("🧪 TEST RESULTS:\n")
	fmt.Printf("  • Total Tests: %d\n", vs.Summary.TotalTests)
	fmt.Printf("  • Passed: %d\n", vs.Summary.PassedTests)
	fmt.Printf("  • Failed: %d\n", vs.Summary.FailedTests)
	fmt.Printf("  • Pass Rate: %.1f%%\n\n", vs.Summary.PassRate)

	// Go native compliance
	fmt.Printf("🚀 GO NATIVE COMPLIANCE:\n")
	fmt.Printf("  • Algorithms Coverage: %d/%d (%.1f%%)\n",
		vs.Summary.AlgorithmsCovered, len(expectedAlgorithms), vs.Summary.GoNativeCompliance)
	fmt.Printf("  • PowerShell Files Remaining: %d\n", vs.Summary.PowerShellRemaining)

	nativeStatus := "🔴 NOT ACHIEVED"
	if vs.Summary.GoNativeCompliance == 100.0 && vs.Summary.PowerShellRemaining == 0 {
		nativeStatus = "🟢 ACHIEVED"
	} else if vs.Summary.GoNativeCompliance >= 80.0 {
		nativeStatus = "🟡 NEARLY ACHIEVED"
	}
	fmt.Printf("  • Native Status: %s\n\n", nativeStatus)

	// Algorithm status details
	fmt.Printf("📦 ALGORITHM STATUS:\n")

	// Sort algorithms by status for better display
	type algStatus struct {
		id   string
		info AlgorithmInfo
	}

	var algorithms []algStatus
	for id, info := range vs.AlgorithmStatus {
		algorithms = append(algorithms, algStatus{id, info})
	}

	sort.Slice(algorithms, func(i, j int) bool {
		statusOrder := map[string]int{
			"go_native":         1,
			"mixed":             2,
			"powershell_only":   3,
			"no_implementation": 4,
			"missing":           5,
			"error":             6,
		}
		return statusOrder[algorithms[i].info.Status] < statusOrder[algorithms[j].info.Status]
	})

	for _, alg := range algorithms {
		statusIcon := "❓"
		switch alg.info.Status {
		case "go_native":
			statusIcon = "✅"
		case "mixed":
			statusIcon = "⚠️"
		case "powershell_only":
			statusIcon = "❌"
		case "no_implementation":
			statusIcon = "❌"
		case "missing":
			statusIcon = "❌"
		case "error":
			statusIcon = "💥"
		}

		fmt.Printf("  %s %s", statusIcon, alg.id)
		if len(alg.info.GoFiles) > 0 {
			fmt.Printf(" (%d Go)", len(alg.info.GoFiles))
		}
		if len(alg.info.PowerShellFiles) > 0 {
			fmt.Printf(" (%d PS1)", len(alg.info.PowerShellFiles))
		}
		fmt.Printf("\n")
	}

	// Test details for failed tests
	failedTests := []ValidationTest{}
	for _, test := range vs.ValidationTests {
		if test.Status == "FAIL" {
			failedTests = append(failedTests, test)
		}
	}

	if len(failedTests) > 0 {
		fmt.Printf("\n❌ FAILED TESTS:\n")
		for _, test := range failedTests {
			fmt.Printf("  • %s: %s\n", test.Name, test.Message)
			if len(test.Details) > 0 {
				for _, detail := range test.Details {
					fmt.Printf("    - %s\n", detail)
				}
			}
		}
	}

	// Recommendations
	if len(vs.Recommendations) > 0 {
		fmt.Printf("\n💡 RECOMMENDATIONS:\n")
		for i, rec := range vs.Recommendations {
			fmt.Printf("  %d. %s\n", i+1, rec)
		}
	}

	// Final status
	fmt.Printf("\n" + strings.Repeat("=", 70) + "\n")
	if vs.Summary.GoNativeCompliance == 100.0 && vs.Summary.PowerShellRemaining == 0 {
		fmt.Printf("🎉 SUCCESS: 100%% Go Native Implementation Achieved!\n")
		fmt.Printf("🚀 Performance optimization through PowerShell elimination complete.\n")
	} else {
		fmt.Printf("⚠️ IN PROGRESS: %.1f%% Go Native Implementation\n", vs.Summary.GoNativeCompliance)
		fmt.Printf("🎯 Target: 100%% Go Native for maximum performance\n")
	}
	fmt.Printf(strings.Repeat("=", 70) + "\n")
}
