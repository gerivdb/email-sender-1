package test_runner

import (
	"bufio"
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"sync"
	"time"
)

// TestConfig holds test configuration
type TestConfig struct {
	ProjectRoot    string
	Verbose        bool
	Parallel       bool
	Timeout        time.Duration
	RunBenchmarks  bool
	RunIntegration bool
	Coverage       bool
	Race           bool
	FailFast       bool
}

// TestResult represents a test result
type TestResult struct {
	Package  string        `json:"package"`
	Passed   bool          `json:"passed"`
	Duration time.Duration `json:"duration"`
	Output   string        `json:"output"`
	Coverage float64       `json:"coverage,omitempty"`
}

// TestSuite represents all test results
type TestSuite struct {
	StartTime   time.Time     `json:"start_time"`
	EndTime     time.Time     `json:"end_time"`
	Duration    time.Duration `json:"duration"`
	TotalTests  int           `json:"total_tests"`
	PassedTests int           `json:"passed_tests"`
	FailedTests int           `json:"failed_tests"`
	Coverage    float64       `json:"coverage"`
	Results     []TestResult  `json:"results"`
}

func main() {
	config := &TestConfig{}

	// Parse command line flags
	flag.BoolVar(&config.Verbose, "v", false, "Verbose test output")
	flag.BoolVar(&config.Parallel, "parallel", true, "Run tests in parallel")
	flag.DurationVar(&config.Timeout, "timeout", 10*time.Minute, "Test timeout")
	flag.BoolVar(&config.RunBenchmarks, "bench", false, "Run benchmarks")
	flag.BoolVar(&config.RunIntegration, "integration", false, "Run integration tests")
	flag.BoolVar(&config.Coverage, "cover", true, "Generate coverage report")
	flag.BoolVar(&config.Race, "race", true, "Enable race detection")
	flag.BoolVar(&config.FailFast, "failfast", false, "Stop at first test failure")
	flag.Parse()

	// Get project root
	wd, err := os.Getwd()
	if err != nil {
		fmt.Printf("❌ Error getting working directory: %v\n", err)
		os.Exit(1)
	}

	// Go to project root (assuming we're in tools/test-runner)
	config.ProjectRoot = filepath.Dir(filepath.Dir(wd))

	fmt.Println("🧪 Fast Go Test Runner")
	fmt.Println("======================")
	fmt.Printf("📁 Project root: %s\n", config.ProjectRoot)

	// Change to project root
	if err := os.Chdir(config.ProjectRoot); err != nil {
		fmt.Printf("❌ Error changing to project root: %v\n", err)
		os.Exit(1)
	}

	// Run tests
	suite, err := runTestSuite(config)
	if err != nil {
		fmt.Printf("❌ Test suite failed: %v\n", err)
		os.Exit(1)
	}

	// Print summary
	printSummary(suite)

	// Save results
	if err := saveResults(suite); err != nil {
		fmt.Printf("⚠️  Failed to save results: %v\n", err)
	}

	// Exit with appropriate code
	if suite.FailedTests > 0 {
		os.Exit(1)
	}
}

func runTestSuite(config *TestConfig) (*TestSuite, error) {
	startTime := time.Now()

	suite := &TestSuite{
		StartTime: startTime,
		Results:   []TestResult{},
	}

	// Find all packages with tests
	packages, err := findTestPackages()
	if err != nil {
		return nil, fmt.Errorf("finding test packages: %w", err)
	}

	if len(packages) == 0 {
		fmt.Println("⚠️  No test packages found")
		return suite, nil
	}

	fmt.Printf("🔍 Found %d packages with tests\n", len(packages))

	// Run tests
	if config.Parallel && len(packages) > 1 {
		err = runTestsParallel(config, packages, suite)
	} else {
		err = runTestsSequential(config, packages, suite)
	}

	if err != nil {
		return nil, fmt.Errorf("running tests: %w", err)
	}

	// Calculate totals
	suite.EndTime = time.Now()
	suite.Duration = suite.EndTime.Sub(suite.StartTime)
	suite.TotalTests = len(suite.Results)

	var totalCoverage float64
	coverageCount := 0

	for _, result := range suite.Results {
		if result.Passed {
			suite.PassedTests++
		} else {
			suite.FailedTests++
		}

		if result.Coverage > 0 {
			totalCoverage += result.Coverage
			coverageCount++
		}
	}

	if coverageCount > 0 {
		suite.Coverage = totalCoverage / float64(coverageCount)
	}

	return suite, nil
}

func findTestPackages() ([]string, error) {
	cmd := exec.Command("go", "list", "./...")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("listing packages: %w", err)
	}

	packages := strings.Fields(string(output))
	var testPackages []string

	for _, pkg := range packages {
		// Check if package has test files
		if hasTestFiles(pkg) {
			testPackages = append(testPackages, pkg)
		}
	}

	return testPackages, nil
}

func hasTestFiles(pkg string) bool {
	// Convert package name to directory path
	pkgPath := strings.TrimPrefix(pkg, "email-sender/")
	if pkgPath == "email-sender" {
		pkgPath = "."
	}

	files, err := filepath.Glob(filepath.Join(pkgPath, "*_test.go"))
	return err == nil && len(files) > 0
}

func runTestsParallel(config *TestConfig, packages []string, suite *TestSuite) error {
	fmt.Printf("🚀 Running tests in parallel (max %d goroutines)\n", runtime.NumCPU())

	var wg sync.WaitGroup
	results := make(chan TestResult, len(packages))
	semaphore := make(chan struct{}, runtime.NumCPU())

	for _, pkg := range packages {
		wg.Add(1)
		go func(packageName string) {
			defer wg.Done()

			semaphore <- struct{}{} // Acquire
			result := runSingleTest(config, packageName)
			<-semaphore // Release

			results <- result

			if config.FailFast && !result.Passed {
				return // Early exit for fail-fast mode
			}
		}(pkg)
	}

	// Collect results
	go func() {
		wg.Wait()
		close(results)
	}()

	for result := range results {
		suite.Results = append(suite.Results, result)

		if result.Passed {
			fmt.Printf("✅ %s (%.2fs)\n", result.Package, result.Duration.Seconds())
		} else {
			fmt.Printf("❌ %s (%.2fs)\n", result.Package, result.Duration.Seconds())
			if config.Verbose {
				fmt.Printf("   Output: %s\n", result.Output)
			}
		}

		if config.FailFast && !result.Passed {
			break
		}
	}

	return nil
}

func runTestsSequential(config *TestConfig, packages []string, suite *TestSuite) error {
	fmt.Printf("🔄 Running tests sequentially\n")

	for _, pkg := range packages {
		result := runSingleTest(config, pkg)
		suite.Results = append(suite.Results, result)

		if result.Passed {
			fmt.Printf("✅ %s (%.2fs)\n", result.Package, result.Duration.Seconds())
		} else {
			fmt.Printf("❌ %s (%.2fs)\n", result.Package, result.Duration.Seconds())
			if config.Verbose {
				fmt.Printf("   Output: %s\n", result.Output)
			}
		}

		if config.FailFast && !result.Passed {
			break
		}
	}

	return nil
}

func runSingleTest(config *TestConfig, packageName string) TestResult {
	startTime := time.Now()

	result := TestResult{
		Package: packageName,
		Passed:  false,
	}

	// Build test command
	args := []string{"test"}

	if config.Verbose {
		args = append(args, "-v")
	}

	if config.Race && runtime.GOOS != "windows" { // Race detector doesn't work well on Windows
		args = append(args, "-race")
	}

	if config.Coverage {
		args = append(args, "-cover")
	}

	if config.RunBenchmarks {
		args = append(args, "-bench=.")
	}

	if config.Timeout > 0 {
		args = append(args, "-timeout", config.Timeout.String())
	}

	args = append(args, packageName)

	// Run the test
	cmd := exec.Command("go", args...)

	var output bytes.Buffer
	cmd.Stdout = &output
	cmd.Stderr = &output

	err := cmd.Run()

	result.Duration = time.Since(startTime)
	result.Output = output.String()
	result.Passed = err == nil

	// Extract coverage if available
	if config.Coverage {
		result.Coverage = extractCoverage(result.Output)
	}

	return result
}

func extractCoverage(output string) float64 {
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		if strings.Contains(line, "coverage:") && strings.Contains(line, "%") {
			// Parse coverage line like "coverage: 85.2% of statements"
			parts := strings.Fields(line)
			for i, part := range parts {
				if strings.HasSuffix(part, "%") && i > 0 {
					coverageStr := strings.TrimSuffix(part, "%")
					var coverage float64
					if _, err := fmt.Sscanf(coverageStr, "%f", &coverage); err == nil {
						return coverage
					}
				}
			}
		}
	}
	return 0
}

func printSummary(suite *TestSuite) {
	fmt.Println("\n📊 Test Results Summary")
	fmt.Println("=======================")
	fmt.Printf("⏱️  Total time: %.2fs\n", suite.Duration.Seconds())
	fmt.Printf("📦 Total packages: %d\n", suite.TotalTests)
	fmt.Printf("✅ Passed: %d\n", suite.PassedTests)
	fmt.Printf("❌ Failed: %d\n", suite.FailedTests)

	if suite.Coverage > 0 {
		fmt.Printf("📈 Average coverage: %.1f%%\n", suite.Coverage)
	}

	// Show failed tests
	if suite.FailedTests > 0 {
		fmt.Println("\n❌ Failed Tests:")
		for _, result := range suite.Results {
			if !result.Passed {
				fmt.Printf("   - %s\n", result.Package)
			}
		}
	}

	// Performance stats
	fmt.Println("\n⚡ Performance:")

	// Sort by duration
	sortedResults := make([]TestResult, len(suite.Results))
	copy(sortedResults, suite.Results)
	sort.Slice(sortedResults, func(i, j int) bool {
		return sortedResults[i].Duration > sortedResults[j].Duration
	})

	// Show slowest tests
	fmt.Printf("   Slowest tests:\n")
	for i, result := range sortedResults {
		if i >= 3 { // Show top 3 slowest
			break
		}
		fmt.Printf("   %d. %s (%.2fs)\n", i+1, result.Package, result.Duration.Seconds())
	}

	// Show fastest tests
	if len(sortedResults) > 3 {
		fmt.Printf("   Fastest: %s (%.2fs)\n",
			sortedResults[len(sortedResults)-1].Package,
			sortedResults[len(sortedResults)-1].Duration.Seconds())
	}
}

func saveResults(suite *TestSuite) error {
	// Create reports directory
	reportsDir := "reports"
	if err := os.MkdirAll(reportsDir, 0755); err != nil {
		return fmt.Errorf("creating reports directory: %w", err)
	}

	// Save JSON report
	jsonFile := filepath.Join(reportsDir, fmt.Sprintf("test-results-%s.json",
		time.Now().Format("2006-01-02-150405")))

	jsonData, err := json.MarshalIndent(suite, "", "  ")
	if err != nil {
		return fmt.Errorf("marshaling test results: %w", err)
	}

	if err := os.WriteFile(jsonFile, jsonData, 0644); err != nil {
		return fmt.Errorf("writing JSON report: %w", err)
	}

	// Save text report
	textFile := filepath.Join(reportsDir, fmt.Sprintf("test-report-%s.txt",
		time.Now().Format("2006-01-02-150405")))

	f, err := os.Create(textFile)
	if err != nil {
		return fmt.Errorf("creating text report: %w", err)
	}
	defer f.Close()

	w := bufio.NewWriter(f)
	defer w.Flush()

	fmt.Fprintf(w, "Test Report - %s\n", suite.StartTime.Format("2006-01-02 15:04:05"))
	fmt.Fprintf(w, "================================\n\n")
	fmt.Fprintf(w, "Duration: %.2fs\n", suite.Duration.Seconds())
	fmt.Fprintf(w, "Total Tests: %d\n", suite.TotalTests)
	fmt.Fprintf(w, "Passed: %d\n", suite.PassedTests)
	fmt.Fprintf(w, "Failed: %d\n", suite.FailedTests)
	if suite.Coverage > 0 {
		fmt.Fprintf(w, "Coverage: %.1f%%\n", suite.Coverage)
	}
	fmt.Fprintf(w, "\nDetailed Results:\n")

	for _, result := range suite.Results {
		status := "PASS"
		if !result.Passed {
			status = "FAIL"
		}
		fmt.Fprintf(w, "%-50s %s (%.2fs)\n", result.Package, status, result.Duration.Seconds())
		if !result.Passed && result.Output != "" {
			fmt.Fprintf(w, "   Output: %s\n", strings.ReplaceAll(result.Output, "\n", "\n   "))
		}
	}

	fmt.Printf("📄 Reports saved:\n")
	fmt.Printf("   JSON: %s\n", jsonFile)
	fmt.Printf("   Text: %s\n", textFile)

	return nil
}
