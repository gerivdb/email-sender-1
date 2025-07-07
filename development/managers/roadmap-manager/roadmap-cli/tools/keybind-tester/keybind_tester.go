// keybind-tester - Tool for testing and validating TaskMaster CLI key bindings
package keybind_tester

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/keybinds"
)

var (
	configDir = flag.String("config", "", "Path to key binding configuration directory")
	profile   = flag.String("profile", "default", "Key binding profile to test")
	validate  = flag.Bool("validate", false, "Validate key bindings for conflicts")
	export    = flag.String("export", "", "Export validation report to file")
	benchmark = flag.Bool("benchmark", false, "Run performance benchmarks")
	verbose   = flag.Bool("verbose", false, "Enable verbose output")
)

// TestResult represents the result of a key binding test
type TestResult struct {
	Profile     string                 `json:"profile"`
	Timestamp   time.Time              `json:"timestamp"`
	Conflicts   []keybinds.KeyConflict `json:"conflicts"`
	Warnings    []string               `json:"warnings"`
	Suggestions []string               `json:"suggestions"`
	Performance PerformanceMetrics     `json:"performance"`
	Coverage    CoverageReport         `json:"coverage"`
}

// PerformanceMetrics tracks performance of key binding operations
type PerformanceMetrics struct {
	LoadTime       time.Duration `json:"load_time"`
	ValidationTime time.Duration `json:"validation_time"`
	MemoryUsage    int64         `json:"memory_usage"`
	ConflictCount  int           `json:"conflict_count"`
	BindingCount   int           `json:"binding_count"`
}

// CoverageReport provides coverage analysis of key bindings
type CoverageReport struct {
	TotalActions    int      `json:"total_actions"`
	MappedActions   int      `json:"mapped_actions"`
	CoveragePercent float64  `json:"coverage_percent"`
	UnmappedActions []string `json:"unmapped_actions"`
	DuplicateKeys   []string `json:"duplicate_keys"`
}

// TesterModel represents the TUI model for interactive testing
type TesterModel struct {
	configManager  *keybinds.KeyConfigManager
	validator      *keybinds.KeyValidator
	currentProfile *keybinds.KeyProfile
	testResult     *TestResult
	activeTest     string
	logs           []string
	width          int
	height         int
	quitting       bool
}

func main() {
	flag.Parse()

	if *configDir == "" {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			log.Fatal("Failed to get home directory:", err)
		}
		*configDir = filepath.Join(homeDir, ".taskmaster", "keybinds")
	}

	// Initialize key configuration manager
	configManager := keybinds.NewKeyConfigManager(*configDir)
	if err := configManager.Initialize(); err != nil {
		log.Fatal("Failed to initialize config manager:", err)
	}

	// Load specified profile
	if err := configManager.LoadProfile(*profile); err != nil {
		log.Fatal("Failed to load profile:", err)
	}
	// Initialize validator
	validator := keybinds.NewKeyValidator(configManager)

	if *validate {
		runValidation(configManager, validator)
		return
	}

	if *benchmark {
		runBenchmarks(configManager, validator)
		return
	}

	// Run interactive TUI
	runInteractiveTester(configManager, validator)
}

// runValidation performs validation of key bindings
func runValidation(configManager *keybinds.KeyConfigManager, validator *keybinds.KeyValidator) {
	fmt.Printf("🔍 Validating key bindings for profile: %s\n\n", *profile)

	start := time.Now()

	// Get current profile
	currentProfile := configManager.GetCurrentProfile()
	if currentProfile == nil {
		log.Fatal("No current profile loaded")
	}

	// Collect all bindings for validation
	var allBindings []keybinds.KeyBinding
	for _, keyMap := range currentProfile.KeyMaps {
		allBindings = append(allBindings, keyMap.Bindings...)
	}
	// Run validation
	result := validator.ValidateProfile(currentProfile)

	// Generate test result
	testResult := &TestResult{
		Profile:     *profile,
		Timestamp:   time.Now(),
		Conflicts:   result.Conflicts,
		Warnings:    result.Warnings,
		Suggestions: result.Suggestions,
		Performance: PerformanceMetrics{
			ValidationTime: time.Since(start),
			ConflictCount:  len(result.Conflicts),
			BindingCount:   len(allBindings),
		},
		Coverage: generateCoverageReport(allBindings),
	}

	// Display results
	displayValidationResults(testResult)

	// Export if requested
	if *export != "" {
		exportResults(testResult, *export)
	}
}

// runBenchmarks performs performance benchmarks
func runBenchmarks(configManager *keybinds.KeyConfigManager, validator *keybinds.KeyValidator) {
	fmt.Printf("⚡ Running performance benchmarks for profile: %s\n\n", *profile)

	// Load benchmark
	start := time.Now()
	configManager.LoadProfile(*profile)
	loadTime := time.Since(start)

	// Validation benchmark
	currentProfile := configManager.GetCurrentProfile()
	var allBindings []keybinds.KeyBinding
	for _, keyMap := range currentProfile.KeyMaps {
		allBindings = append(allBindings, keyMap.Bindings...)
	}
	start = time.Now()
	result := validator.ValidateProfile(currentProfile)
	validationTime := time.Since(start)

	// Memory usage simulation (simplified)
	memoryUsage := int64(len(allBindings) * 256) // Rough estimate

	metrics := PerformanceMetrics{
		LoadTime:       loadTime,
		ValidationTime: validationTime,
		MemoryUsage:    memoryUsage,
		ConflictCount:  len(result.Conflicts),
		BindingCount:   len(allBindings),
	}

	displayBenchmarkResults(metrics)
}

// runInteractiveTester starts the interactive TUI tester
func runInteractiveTester(configManager *keybinds.KeyConfigManager, validator *keybinds.KeyValidator) {
	model := &TesterModel{
		configManager:  configManager,
		validator:      validator,
		currentProfile: configManager.GetCurrentProfile(),
		logs:           []string{"🚀 Key Binding Tester initialized"},
	}

	program := tea.NewProgram(model, tea.WithAltScreen())
	if _, err := program.Run(); err != nil {
		log.Fatal("Error running program:", err)
	}
}

// TUI Implementation
func (m *TesterModel) Init() tea.Cmd {
	return nil
}

func (m *TesterModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			m.quitting = true
			return m, tea.Quit

		case "v":
			m.activeTest = "validation"
			m.runValidationTest()

		case "b":
			m.activeTest = "benchmark"
			m.runBenchmarkTest()

		case "c":
			m.activeTest = "coverage"
			m.runCoverageTest()

		case "r":
			m.logs = []string{"🔄 Refreshed"}
			m.configManager.LoadProfile(*profile)
			m.currentProfile = m.configManager.GetCurrentProfile()

		case "h":
			m.showHelp()
		}
	}

	return m, nil
}

func (m *TesterModel) View() string {
	if m.quitting {
		return "👋 Thanks for using Key Binding Tester!\n"
	}

	var sections []string

	// Header
	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("62")).
		Border(lipgloss.RoundedBorder()).
		Padding(0, 1)

	header := headerStyle.Render("🔧 TaskMaster Key Binding Tester")
	sections = append(sections, header)

	// Profile info
	if m.currentProfile != nil {
		profileInfo := fmt.Sprintf("📋 Profile: %s | Keymaps: %d | Created: %s",
			m.currentProfile.Name,
			len(m.currentProfile.KeyMaps),
			m.currentProfile.CreatedAt.Format("2006-01-02"))
		sections = append(sections, profileInfo)
	}

	// Active test info
	if m.activeTest != "" {
		testInfo := fmt.Sprintf("🧪 Active Test: %s", strings.Title(m.activeTest))
		sections = append(sections, testInfo)
	}

	// Test results
	if m.testResult != nil {
		sections = append(sections, m.formatTestResults())
	}

	// Logs
	logStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("240")).
		Padding(1).
		Height(8)

	logContent := strings.Join(m.logs[max(0, len(m.logs)-5):], "\n")
	logSection := logStyle.Render("📝 Logs:\n" + logContent)
	sections = append(sections, logSection)

	// Controls
	controls := "⌨️  Controls: [v]alidate | [b]enchmark | [c]overage | [r]efresh | [h]elp | [q]uit"
	sections = append(sections, controls)

	return strings.Join(sections, "\n\n")
}

// Test methods
func (m *TesterModel) runValidationTest() {
	m.logs = append(m.logs, "🔍 Running validation test...")

	var allBindings []keybinds.KeyBinding
	for _, keyMap := range m.currentProfile.KeyMaps {
		allBindings = append(allBindings, keyMap.Bindings...)
	}
	start := time.Now()
	result := m.validator.ValidateProfile(m.currentProfile)
	duration := time.Since(start)

	m.testResult = &TestResult{
		Profile:     m.currentProfile.Name,
		Timestamp:   time.Now(),
		Conflicts:   result.Conflicts,
		Warnings:    result.Warnings,
		Suggestions: result.Suggestions,
		Performance: PerformanceMetrics{
			ValidationTime: duration,
			ConflictCount:  len(result.Conflicts),
			BindingCount:   len(allBindings),
		},
		Coverage: generateCoverageReport(allBindings),
	}

	m.logs = append(m.logs, fmt.Sprintf("✅ Validation completed in %v", duration))
}

func (m *TesterModel) runBenchmarkTest() {
	m.logs = append(m.logs, "⚡ Running benchmark test...")

	start := time.Now()

	// Simulate load test
	m.configManager.LoadProfile(*profile)
	loadTime := time.Since(start)

	var allBindings []keybinds.KeyBinding
	for _, keyMap := range m.currentProfile.KeyMaps {
		allBindings = append(allBindings, keyMap.Bindings...)
	}
	start = time.Now()
	result := m.validator.ValidateProfile(m.currentProfile)
	validationTime := time.Since(start)

	metrics := PerformanceMetrics{
		LoadTime:       loadTime,
		ValidationTime: validationTime,
		MemoryUsage:    int64(len(allBindings) * 256),
		ConflictCount:  len(result.Conflicts),
		BindingCount:   len(allBindings),
	}

	if m.testResult == nil {
		m.testResult = &TestResult{Profile: m.currentProfile.Name, Timestamp: time.Now()}
	}
	m.testResult.Performance = metrics

	m.logs = append(m.logs, fmt.Sprintf("⚡ Benchmark completed: Load=%v, Validation=%v", loadTime, validationTime))
}

func (m *TesterModel) runCoverageTest() {
	m.logs = append(m.logs, "📊 Running coverage analysis...")

	var allBindings []keybinds.KeyBinding
	for _, keyMap := range m.currentProfile.KeyMaps {
		allBindings = append(allBindings, keyMap.Bindings...)
	}

	coverage := generateCoverageReport(allBindings)

	if m.testResult == nil {
		m.testResult = &TestResult{Profile: m.currentProfile.Name, Timestamp: time.Now()}
	}
	m.testResult.Coverage = coverage

	m.logs = append(m.logs, fmt.Sprintf("📊 Coverage: %.1f%% (%d/%d actions mapped)",
		coverage.CoveragePercent, coverage.MappedActions, coverage.TotalActions))
}

func (m *TesterModel) showHelp() {
	m.logs = append(m.logs, "❓ Help: Use keys to run tests, 'r' to refresh, 'q' to quit")
}

func (m *TesterModel) formatTestResults() string {
	if m.testResult == nil {
		return ""
	}

	var parts []string

	// Conflicts
	if len(m.testResult.Conflicts) > 0 {
		parts = append(parts, fmt.Sprintf("❌ Conflicts: %d", len(m.testResult.Conflicts)))
	} else {
		parts = append(parts, "✅ No conflicts found")
	}

	// Performance
	if m.testResult.Performance.ValidationTime > 0 {
		parts = append(parts, fmt.Sprintf("⏱️  Validation: %v", m.testResult.Performance.ValidationTime))
	}

	// Coverage
	if m.testResult.Coverage.TotalActions > 0 {
		parts = append(parts, fmt.Sprintf("📈 Coverage: %.1f%%", m.testResult.Coverage.CoveragePercent))
	}

	return strings.Join(parts, " | ")
}

// Helper functions
func displayValidationResults(result *TestResult) {
	fmt.Printf("📊 Validation Results\n")
	fmt.Printf("===================\n\n")

	fmt.Printf("Profile: %s\n", result.Profile)
	fmt.Printf("Timestamp: %s\n", result.Timestamp.Format("2006-01-02 15:04:05"))
	fmt.Printf("Bindings: %d\n", result.Performance.BindingCount)
	fmt.Printf("Validation Time: %v\n\n", result.Performance.ValidationTime)

	if len(result.Conflicts) == 0 {
		fmt.Printf("✅ No conflicts found!\n\n")
	} else {
		fmt.Printf("❌ Found %d conflicts:\n", len(result.Conflicts))
		for i, conflict := range result.Conflicts {
			fmt.Printf("  %d. %s ↔ %s (Key: %s)\n", i+1,
				conflict.Binding1.ID, conflict.Binding2.ID, conflict.Binding1.Key)
		}
		fmt.Printf("\n")
	}

	if len(result.Warnings) > 0 {
		fmt.Printf("⚠️  Warnings:\n")
		for _, warning := range result.Warnings {
			fmt.Printf("  • %s\n", warning)
		}
		fmt.Printf("\n")
	}

	if len(result.Suggestions) > 0 {
		fmt.Printf("💡 Suggestions:\n")
		for _, suggestion := range result.Suggestions {
			fmt.Printf("  • %s\n", suggestion)
		}
		fmt.Printf("\n")
	}

	// Coverage report
	fmt.Printf("📈 Coverage: %.1f%% (%d/%d actions mapped)\n",
		result.Coverage.CoveragePercent,
		result.Coverage.MappedActions,
		result.Coverage.TotalActions)

	if len(result.Coverage.UnmappedActions) > 0 {
		fmt.Printf("🔍 Unmapped actions: %s\n", strings.Join(result.Coverage.UnmappedActions, ", "))
	}
}

func displayBenchmarkResults(metrics PerformanceMetrics) {
	fmt.Printf("⚡ Performance Benchmarks\n")
	fmt.Printf("========================\n\n")

	fmt.Printf("Load Time: %v\n", metrics.LoadTime)
	fmt.Printf("Validation Time: %v\n", metrics.ValidationTime)
	fmt.Printf("Memory Usage: %d bytes\n", metrics.MemoryUsage)
	fmt.Printf("Binding Count: %d\n", metrics.BindingCount)
	fmt.Printf("Conflict Count: %d\n", metrics.ConflictCount)
	fmt.Printf("\n")

	// Performance rating
	totalTime := metrics.LoadTime + metrics.ValidationTime
	if totalTime < 10*time.Millisecond {
		fmt.Printf("🚀 Performance: Excellent (<%v)\n", totalTime)
	} else if totalTime < 50*time.Millisecond {
		fmt.Printf("✅ Performance: Good (<%v)\n", totalTime)
	} else if totalTime < 100*time.Millisecond {
		fmt.Printf("⚠️  Performance: Fair (<%v)\n", totalTime)
	} else {
		fmt.Printf("🐌 Performance: Needs optimization (<%v)\n", totalTime)
	}
}

func generateCoverageReport(bindings []keybinds.KeyBinding) CoverageReport {
	// Get all possible actions from keybinds package
	allActions := []string{
		string(keybinds.ActionMoveUp), string(keybinds.ActionMoveDown),
		string(keybinds.ActionMoveLeft), string(keybinds.ActionMoveRight),
		string(keybinds.ActionSelectItem), string(keybinds.ActionDeselectItem),
		string(keybinds.ActionToggleExpand), string(keybinds.ActionToggleCollapse),
		string(keybinds.ActionSwitchToKanban), string(keybinds.ActionSwitchToList),
		string(keybinds.ActionSwitchToCalendar), string(keybinds.ActionSwitchToMatrix),
		string(keybinds.ActionSwitchToTimeline), string(keybinds.ActionSwitchToGantt),
		string(keybinds.ActionCreateTask), string(keybinds.ActionEditTask),
		string(keybinds.ActionDeleteTask), string(keybinds.ActionCompleteTask),
		string(keybinds.ActionCopyTask), string(keybinds.ActionMoveTask),
		string(keybinds.ActionSetPriority), string(keybinds.ActionSetDeadline),
		string(keybinds.ActionAddTag), string(keybinds.ActionRemoveTag),
		string(keybinds.ActionSave), string(keybinds.ActionUndo),
		string(keybinds.ActionRedo), string(keybinds.ActionCut),
		string(keybinds.ActionCopy), string(keybinds.ActionPaste),
		string(keybinds.ActionSearch), string(keybinds.ActionFilter),
		string(keybinds.ActionSort), string(keybinds.ActionHelp),
		string(keybinds.ActionQuit), string(keybinds.ActionRefresh),
	}

	// Count mapped actions
	mappedActions := make(map[string]bool)
	keyUsage := make(map[string]int)

	for _, binding := range bindings {
		if binding.Enabled {
			mappedActions[binding.Action] = true
			keyUsage[binding.Key]++
		}
	}

	// Find unmapped actions
	var unmappedActions []string
	for _, action := range allActions {
		if !mappedActions[action] {
			unmappedActions = append(unmappedActions, action)
		}
	}

	// Find duplicate keys
	var duplicateKeys []string
	for key, count := range keyUsage {
		if count > 1 {
			duplicateKeys = append(duplicateKeys, key)
		}
	}

	coverage := float64(len(mappedActions)) / float64(len(allActions)) * 100

	return CoverageReport{
		TotalActions:    len(allActions),
		MappedActions:   len(mappedActions),
		CoveragePercent: coverage,
		UnmappedActions: unmappedActions,
		DuplicateKeys:   duplicateKeys,
	}
}

func exportResults(result *TestResult, filename string) {
	data, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		log.Printf("Failed to marshal results: %v", err)
		return
	}

	if err := os.WriteFile(filename, data, 0o644); err != nil {
		log.Printf("Failed to write results to %s: %v", filename, err)
		return
	}

	fmt.Printf("📄 Results exported to: %s\n", filename)
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
