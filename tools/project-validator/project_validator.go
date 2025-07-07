package project_validator

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// ProjectValidator validates Go project setup and dependencies
type ProjectValidator struct {
	ProjectRoot string
	Verbose     bool
	Fix         bool
	CheckSec    bool
}

// ValidationResult represents the result of a validation check
type ValidationResult struct {
	Check    string        `json:"check"`
	Status   string        `json:"status"`
	Message  string        `json:"message"`
	Details  []string      `json:"details,omitempty"`
	Duration time.Duration `json:"duration"`
}

// ValidationReport contains all validation results
type ValidationReport struct {
	ProjectPath  string             `json:"project_path"`
	Timestamp    time.Time          `json:"timestamp"`
	TotalChecks  int                `json:"total_checks"`
	PassedChecks int                `json:"passed_checks"`
	FailedChecks int                `json:"failed_checks"`
	Results      []ValidationResult `json:"results"`
}

func main() {
	validator := &ProjectValidator{}

	// Parse command line flags
	flag.BoolVar(&validator.Verbose, "v", false, "Verbose output")
	flag.BoolVar(&validator.Fix, "fix", false, "Automatically fix issues where possible")
	flag.BoolVar(&validator.CheckSec, "security", true, "Run security checks")
	flag.Parse()

	// Get project root
	wd, err := os.Getwd()
	if err != nil {
		fmt.Printf("❌ Error getting working directory: %v\n", err)
		os.Exit(1)
	}

	// Go to project root (assuming we're in tools/project-validator)
	validator.ProjectRoot = filepath.Dir(filepath.Dir(wd))

	fmt.Println("🔍 Go Project Validator")
	fmt.Println("=======================")
	fmt.Printf("📁 Project root: %s\n", validator.ProjectRoot)

	// Change to project root
	if err := os.Chdir(validator.ProjectRoot); err != nil {
		fmt.Printf("❌ Error changing to project root: %v\n", err)
		os.Exit(1)
	}

	// Run validation
	report, err := runValidation(validator)
	if err != nil {
		fmt.Printf("❌ Validation failed: %v\n", err)
		os.Exit(1)
	}

	// Print summary
	printValidationSummary(report)

	// Save report
	if err := saveValidationReport(report); err != nil {
		fmt.Printf("⚠️  Failed to save validation report: %v\n", err)
	}

	// Exit with appropriate code
	if report.FailedChecks > 0 {
		os.Exit(1)
	}
}

func runValidation(validator *ProjectValidator) (*ValidationReport, error) {
	report := &ValidationReport{
		ProjectPath: validator.ProjectRoot,
		Timestamp:   time.Now(),
		Results:     []ValidationResult{},
	}

	// Define validation checks
	checks := []struct {
		name string
		fn   func(*ProjectValidator) ValidationResult
	}{
		{"Go Installation", checkGoInstallation},
		{"Go Modules", checkGoModules},
		{"Dependencies", checkDependencies},
		{"Project Structure", checkProjectStructure},
		{"Code Quality", checkCodeQuality},
		{"Tests", checkTests},
		{"Documentation", checkDocumentation},
		{"Git Setup", checkGitSetup},
	}

	if validator.CheckSec {
		checks = append(checks, struct {
			name string
			fn   func(*ProjectValidator) ValidationResult
		}{"Security", checkSecurity})
	}

	// Run checks
	for _, check := range checks {
		fmt.Printf("🔄 Running %s check...\n", check.name)
		result := check.fn(validator)
		report.Results = append(report.Results, result)

		// Print immediate result
		status := "✅"
		if result.Status == "FAIL" {
			status = "❌"
		} else if result.Status == "WARN" {
			status = "⚠️"
		}

		fmt.Printf("%s %s: %s\n", status, result.Check, result.Message)

		if validator.Verbose && len(result.Details) > 0 {
			for _, detail := range result.Details {
				fmt.Printf("   - %s\n", detail)
			}
		}
	}

	// Calculate totals
	report.TotalChecks = len(report.Results)
	for _, result := range report.Results {
		if result.Status == "PASS" {
			report.PassedChecks++
		} else if result.Status == "FAIL" {
			report.FailedChecks++
		}
	}

	return report, nil
}

func checkGoInstallation(validator *ProjectValidator) ValidationResult {
	start := time.Now()
	result := ValidationResult{
		Check:   "Go Installation",
		Status:  "FAIL",
		Details: []string{},
	}

	// Check Go version
	cmd := exec.Command("go", "version")
	output, err := cmd.Output()
	if err != nil {
		result.Message = "Go is not installed or not in PATH"
		result.Duration = time.Since(start)
		return result
	}

	version := strings.TrimSpace(string(output))
	result.Details = append(result.Details, version)

	// Check if version is recent enough
	if strings.Contains(version, "go1.21") || strings.Contains(version, "go1.22") || strings.Contains(version, "go1.23") {
		result.Status = "PASS"
		result.Message = "Go installation is valid and up-to-date"
	} else {
		result.Status = "WARN"
		result.Message = "Go version might be outdated"
	}

	result.Duration = time.Since(start)
	return result
}

func checkGoModules(validator *ProjectValidator) ValidationResult {
	start := time.Now()
	result := ValidationResult{
		Check:   "Go Modules",
		Status:  "FAIL",
		Details: []string{},
	}

	// Check if go.mod exists
	if !fileExists("go.mod") {
		result.Message = "go.mod file not found"

		if validator.Fix {
			if err := exec.Command("go", "mod", "init", "email-sender").Run(); err == nil {
				result.Status = "PASS"
				result.Message = "go.mod created successfully"
			}
		}

		result.Duration = time.Since(start)
		return result
	}

	// Validate go.mod
	cmd := exec.Command("go", "mod", "verify")
	if err := cmd.Run(); err != nil {
		result.Message = "Module verification failed"
		result.Details = append(result.Details, err.Error())

		if validator.Fix {
			if err := exec.Command("go", "mod", "tidy").Run(); err == nil {
				result.Status = "PASS"
				result.Message = "Module issues fixed with 'go mod tidy'"
			}
		}
	} else {
		result.Status = "PASS"
		result.Message = "Go modules are valid"
	}

	result.Duration = time.Since(start)
	return result
}

func checkDependencies(validator *ProjectValidator) ValidationResult {
	start := time.Now()
	result := ValidationResult{
		Check:   "Dependencies",
		Status:  "PASS",
		Details: []string{},
	}

	// Check for unused dependencies
	cmd := exec.Command("go", "mod", "tidy")
	if err := cmd.Run(); err != nil {
		result.Status = "WARN"
		result.Message = "Some dependency issues found"
		result.Details = append(result.Details, err.Error())
	} else {
		result.Message = "Dependencies are clean"
	}

	// List dependencies
	cmd = exec.Command("go", "list", "-m", "all")
	output, err := cmd.Output()
	if err == nil {
		deps := strings.Split(string(output), "\n")
		result.Details = append(result.Details, fmt.Sprintf("Total dependencies: %d", len(deps)-1))
	}

	result.Duration = time.Since(start)
	return result
}

func checkProjectStructure(validator *ProjectValidator) ValidationResult {
	start := time.Now()
	result := ValidationResult{
		Check:   "Project Structure",
		Status:  "PASS",
		Details: []string{},
		Message: "Project structure is valid",
	}

	// Check for required directories
	requiredDirs := []string{"cmd", "pkg", "internal"}
	recommendedDirs := []string{"docs", "scripts", "configs", "tests"}

	var missing []string
	var recommended []string

	for _, dir := range requiredDirs {
		if !dirExists(dir) {
			missing = append(missing, dir)
		}
	}

	for _, dir := range recommendedDirs {
		if !dirExists(dir) {
			recommended = append(recommended, dir)
		}
	}

	if len(missing) > 0 {
		result.Status = "FAIL"
		result.Message = "Missing required directories"
		result.Details = append(result.Details, "Missing: "+strings.Join(missing, ", "))

		if validator.Fix {
			for _, dir := range missing {
				if err := os.MkdirAll(dir, 0755); err == nil {
					result.Details = append(result.Details, "Created: "+dir)
				}
			}
		}
	}

	if len(recommended) > 0 {
		if result.Status == "PASS" {
			result.Status = "WARN"
			result.Message = "Some recommended directories are missing"
		}
		result.Details = append(result.Details, "Recommended: "+strings.Join(recommended, ", "))
	}

	result.Duration = time.Since(start)
	return result
}

func checkCodeQuality(validator *ProjectValidator) ValidationResult {
	start := time.Now()
	result := ValidationResult{
		Check:   "Code Quality",
		Status:  "PASS",
		Details: []string{},
	}

	// Run go fmt
	cmd := exec.Command("go", "fmt", "./...")
	if output, err := cmd.Output(); err != nil {
		result.Status = "WARN"
		result.Message = "Code formatting issues found"
		if len(output) > 0 {
			result.Details = append(result.Details, "Formatted files: "+string(output))
		}
	} else {
		result.Message = "Code formatting is good"
	}

	// Run go vet
	cmd = exec.Command("go", "vet", "./...")
	if output, err := cmd.CombinedOutput(); err != nil {
		result.Status = "FAIL"
		result.Message = "Go vet found issues"
		result.Details = append(result.Details, string(output))
	}

	result.Duration = time.Since(start)
	return result
}

func checkTests(validator *ProjectValidator) ValidationResult {
	start := time.Now()
	result := ValidationResult{
		Check:   "Tests",
		Status:  "PASS",
		Details: []string{},
	}

	// Find test files
	cmd := exec.Command("find", ".", "-name", "*_test.go")
	output, err := cmd.Output()
	if err != nil {
		// Fallback for Windows
		cmd = exec.Command("powershell", "-Command", "Get-ChildItem -Recurse -Name '*_test.go'")
		output, err = cmd.Output()
	}

	if err != nil || len(output) == 0 {
		result.Status = "WARN"
		result.Message = "No test files found"
	} else {
		testFiles := strings.Split(strings.TrimSpace(string(output)), "\n")
		result.Message = fmt.Sprintf("Found %d test files", len(testFiles))

		// Try to run tests quickly
		cmd = exec.Command("go", "test", "-short", "./...")
		if err := cmd.Run(); err != nil {
			result.Status = "FAIL"
			result.Message = "Some tests are failing"
		}
	}

	result.Duration = time.Since(start)
	return result
}

func checkDocumentation(validator *ProjectValidator) ValidationResult {
	start := time.Now()
	result := ValidationResult{
		Check:   "Documentation",
		Status:  "PASS",
		Details: []string{},
	}

	requiredDocs := []string{"README.md", "LICENSE"}
	var missing []string

	for _, doc := range requiredDocs {
		if !fileExists(doc) {
			missing = append(missing, doc)
		}
	}

	if len(missing) > 0 {
		result.Status = "WARN"
		result.Message = "Some documentation files are missing"
		result.Details = append(result.Details, "Missing: "+strings.Join(missing, ", "))
	} else {
		result.Message = "Basic documentation is present"
	}

	result.Duration = time.Since(start)
	return result
}

func checkGitSetup(validator *ProjectValidator) ValidationResult {
	start := time.Now()
	result := ValidationResult{
		Check:   "Git Setup",
		Status:  "PASS",
		Details: []string{},
	}

	if !dirExists(".git") {
		result.Status = "WARN"
		result.Message = "Not a git repository"
		result.Duration = time.Since(start)
		return result
	}

	// Check if .gitignore exists
	if !fileExists(".gitignore") {
		result.Status = "WARN"
		result.Message = ".gitignore file not found"

		if validator.Fix {
			gitignoreContent := `# Binaries for programs and plugins
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test binary, built with 'go test -c'
*.test

# Output of the go coverage tool
*.out

# Dependency directories
vendor/

# Go workspace file
go.work

# IDEs
.vscode/
.idea/

# OS generated files
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp
temp/

# Build artifacts
dist/
build/
bin/
`
			if err := os.WriteFile(".gitignore", []byte(gitignoreContent), 0644); err == nil {
				result.Status = "PASS"
				result.Message = ".gitignore created successfully"
			}
		}
	} else {
		result.Message = "Git setup is good"
	}

	result.Duration = time.Since(start)
	return result
}

func checkSecurity(validator *ProjectValidator) ValidationResult {
	start := time.Now()
	result := ValidationResult{
		Check:   "Security",
		Status:  "PASS",
		Details: []string{},
		Message: "No security tools available",
	}

	// Check if gosec is available
	if commandExists("gosec") {
		cmd := exec.Command("gosec", "./...")
		output, err := cmd.CombinedOutput()
		if err != nil {
			result.Status = "WARN"
			result.Message = "Security issues found"
			result.Details = append(result.Details, string(output))
		} else {
			result.Message = "No security issues found"
		}
	}

	result.Duration = time.Since(start)
	return result
}

func printValidationSummary(report *ValidationReport) {
	fmt.Println("\n📊 Validation Summary")
	fmt.Println("====================")
	fmt.Printf("📁 Project: %s\n", report.ProjectPath)
	fmt.Printf("⏱️  Timestamp: %s\n", report.Timestamp.Format("2006-01-02 15:04:05"))
	fmt.Printf("📋 Total checks: %d\n", report.TotalChecks)
	fmt.Printf("✅ Passed: %d\n", report.PassedChecks)
	fmt.Printf("❌ Failed: %d\n", report.FailedChecks)
	fmt.Printf("⚠️  Warnings: %d\n", report.TotalChecks-report.PassedChecks-report.FailedChecks)

	if report.FailedChecks > 0 {
		fmt.Println("\n❌ Failed Checks:")
		for _, result := range report.Results {
			if result.Status == "FAIL" {
				fmt.Printf("   - %s: %s\n", result.Check, result.Message)
			}
		}
	}

	// Show performance stats
	fmt.Println("\n⚡ Performance:")

	// Sort by duration
	sortedResults := make([]ValidationResult, len(report.Results))
	copy(sortedResults, report.Results)
	sort.Slice(sortedResults, func(i, j int) bool {
		return sortedResults[i].Duration > sortedResults[j].Duration
	})

	if len(sortedResults) > 0 {
		fmt.Printf("   Slowest check: %s (%.2fs)\n",
			sortedResults[0].Check, sortedResults[0].Duration.Seconds())
		fmt.Printf("   Fastest check: %s (%.2fs)\n",
			sortedResults[len(sortedResults)-1].Check,
			sortedResults[len(sortedResults)-1].Duration.Seconds())
	}
}

func saveValidationReport(report *ValidationReport) error {
	// Create reports directory
	reportsDir := "reports"
	if err := os.MkdirAll(reportsDir, 0755); err != nil {
		return fmt.Errorf("creating reports directory: %w", err)
	}

	// Save JSON report
	jsonFile := filepath.Join(reportsDir, fmt.Sprintf("validation-report-%s.json",
		time.Now().Format("2006-01-02-150405")))

	jsonData, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("marshaling validation report: %w", err)
	}

	if err := os.WriteFile(jsonFile, jsonData, 0644); err != nil {
		return fmt.Errorf("writing JSON report: %w", err)
	}

	// Save text report
	textFile := filepath.Join(reportsDir, fmt.Sprintf("validation-report-%s.txt",
		time.Now().Format("2006-01-02-150405")))

	f, err := os.Create(textFile)
	if err != nil {
		return fmt.Errorf("creating text report: %w", err)
	}
	defer f.Close()

	w := bufio.NewWriter(f)
	defer w.Flush()

	fmt.Fprintf(w, "Project Validation Report - %s\n", report.Timestamp.Format("2006-01-02 15:04:05"))
	fmt.Fprintf(w, "=========================================\n\n")
	fmt.Fprintf(w, "Project: %s\n", report.ProjectPath)
	fmt.Fprintf(w, "Total Checks: %d\n", report.TotalChecks)
	fmt.Fprintf(w, "Passed: %d\n", report.PassedChecks)
	fmt.Fprintf(w, "Failed: %d\n", report.FailedChecks)
	fmt.Fprintf(w, "\nDetailed Results:\n")

	for _, result := range report.Results {
		fmt.Fprintf(w, "%-20s %s: %s (%.2fs)\n",
			result.Check, result.Status, result.Message, result.Duration.Seconds())
		for _, detail := range result.Details {
			fmt.Fprintf(w, "  - %s\n", detail)
		}
	}

	fmt.Printf("📄 Validation reports saved:\n")
	fmt.Printf("   JSON: %s\n", jsonFile)
	fmt.Printf("   Text: %s\n", textFile)

	return nil
}

// Utility functions

func fileExists(filename string) bool {
	info, err := os.Stat(filename)
	return err == nil && !info.IsDir()
}

func dirExists(dirname string) bool {
	info, err := os.Stat(dirname)
	return err == nil && info.IsDir()
}

func commandExists(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}
