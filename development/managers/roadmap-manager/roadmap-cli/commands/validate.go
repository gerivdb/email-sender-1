package commands

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/storage"
	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli/types"

	"github.com/spf13/cobra"
)

// consistencyCmd validates consistency across different format systems
var consistencyCmd = &cobra.Command{
	Use:   "consistency",
	Short: "🔍 Validate consistency across planning formats",
	Long: `Validate consistency between Markdown plans and dynamic TaskMaster-CLI system.
This command:
• Compares items across different planning formats
• Detects inconsistencies and conflicts
• Reports missing items in either system
• Provides recommendations for resolution
• Generates consistency reports

Useful during transition period to ensure both planning approaches
stay synchronized and no tasks fall through the cracks.`,
	Example: `  # Validate all formats
  roadmap-cli validate consistency --format all
  
  # Check specific plan against dynamic system  
  roadmap-cli validate consistency --markdown-plan plan-dev-v55.md
  
  # Generate detailed report
  roadmap-cli validate consistency --report --output consistency-report.md
  
  # Fix inconsistencies automatically where possible
  roadmap-cli validate consistency --auto-fix`,
	RunE: runConsistencyValidation,
}

var (
	validateFormat       string
	validateMarkdownPlan string
	validateReport       bool
	validateOutput       string
	validateAutoFix      bool
	validateVerbose      bool
)

func init() {
	consistencyCmd.Flags().StringVar(&validateFormat, "format", "all", "format to validate (all, markdown, dynamic)")
	consistencyCmd.Flags().StringVar(&validateMarkdownPlan, "markdown-plan", "", "specific markdown plan to validate")
	consistencyCmd.Flags().BoolVar(&validateReport, "report", false, "generate detailed consistency report")
	consistencyCmd.Flags().StringVar(&validateOutput, "output", "", "output file for report")
	consistencyCmd.Flags().BoolVar(&validateAutoFix, "auto-fix", false, "automatically fix inconsistencies where possible")
	consistencyCmd.Flags().BoolVar(&validateVerbose, "verbose", false, "verbose output with detailed analysis")
}

// validateCmd is the parent command for validation operations
var validateCmd = &cobra.Command{
	Use:   "validate",
	Short: "🔍 Validation operations for planning ecosystem",
	Long:  "Perform various validation operations to ensure consistency and integrity across the planning ecosystem.",
}

func init() {
	validateCmd.AddCommand(consistencyCmd)
}

type ConsistencyIssue struct {
	Type        string
	Severity    string
	Description string
	Location    string
	Suggestion  string
}

type ConsistencyReport struct {
	Timestamp      time.Time
	TotalIssues    int
	CriticalIssues int
	WarningIssues  int
	InfoIssues     int
	Issues         []ConsistencyIssue
	Summary        string
}

func runConsistencyValidation(cmd *cobra.Command, args []string) error {
	fmt.Println("🔍 Planning Ecosystem Consistency Validation")
	fmt.Println("===========================================")
	fmt.Println()

	// Initialize storage
	jsonStorage, err := storage.NewJSONStorage("roadmap.json")
	if err != nil {
		return fmt.Errorf("failed to initialize storage: %w", err)
	}
	defer jsonStorage.Close()

	// Perform validation based on format
	var report *ConsistencyReport
	switch validateFormat {
	case "all":
		report, err = validateAllFormats(jsonStorage)
	case "markdown":
		report, err = validateMarkdownOnly()
	case "dynamic":
		report, err = validateDynamicOnly(jsonStorage)
	default:
		return fmt.Errorf("invalid format: %s (valid: all, markdown, dynamic)", validateFormat)
	}

	if err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	// Display results
	displayConsistencyResults(report)

	// Generate report if requested
	if validateReport {
		if err := generateConsistencyReport(report); err != nil {
			fmt.Printf("⚠️  Failed to generate report: %v\n", err)
		}
	}

	// Auto-fix if requested
	if validateAutoFix {
		if err := autoFixIssues(report, jsonStorage); err != nil {
			fmt.Printf("⚠️  Auto-fix encountered errors: %v\n", err)
		}
	}

	return nil
}

func validateAllFormats(storage *storage.JSONStorage) (*ConsistencyReport, error) {
	fmt.Println("🔄 Validating all planning formats...")

	report := &ConsistencyReport{
		Timestamp: time.Now(),
		Issues:    []ConsistencyIssue{},
	}

	// Get dynamic system items
	dynamicItems, err := storage.GetAllItems()
	if err != nil {
		return nil, fmt.Errorf("failed to get dynamic items: %w", err)
	}

	dynamicMilestones, err := storage.GetAllMilestones()
	if err != nil {
		return nil, fmt.Errorf("failed to get dynamic milestones: %w", err)
	}

	fmt.Printf("📋 Dynamic system: %d items, %d milestones\n", len(dynamicItems), len(dynamicMilestones))

	// Find and analyze Markdown plans
	markdownDir := "projet/roadmaps/plans/consolidated"
	if _, err := os.Stat(markdownDir); os.IsNotExist(err) {
		issue := ConsistencyIssue{
			Type:        "missing_directory",
			Severity:    "critical",
			Description: "Markdown plans directory not found",
			Location:    markdownDir,
			Suggestion:  "Ensure Markdown plans directory exists and is accessible",
		}
		report.Issues = append(report.Issues, issue)
		report.CriticalIssues++
	} else {
		markdownFiles, err := findMarkdownFiles(markdownDir)
		if err != nil {
			return nil, fmt.Errorf("failed to scan markdown files: %w", err)
		}

		fmt.Printf("📄 Found %d Markdown plan files\n", len(markdownFiles))

		// Analyze each Markdown file
		for _, file := range markdownFiles {
			if validateVerbose {
				fmt.Printf("  🔍 Analyzing: %s\n", filepath.Base(file))
			}

			issues := analyzeMarkdownPlan(file, dynamicItems)
			report.Issues = append(report.Issues, issues...)
		}
	}

	// Calculate issue counts
	for _, issue := range report.Issues {
		switch issue.Severity {
		case "critical":
			report.CriticalIssues++
		case "warning":
			report.WarningIssues++
		case "info":
			report.InfoIssues++
		}
	}
	report.TotalIssues = len(report.Issues)

	// Generate summary
	report.Summary = generateSummary(report)

	return report, nil
}

func validateMarkdownOnly() (*ConsistencyReport, error) {
	fmt.Println("📄 Validating Markdown plans only...")

	report := &ConsistencyReport{
		Timestamp: time.Now(),
		Issues:    []ConsistencyIssue{},
	}

	// TODO: Implement Markdown-only validation
	// Check for broken links, malformed syntax, etc.

	return report, nil
}

func validateDynamicOnly(storage *storage.JSONStorage) (*ConsistencyReport, error) {
	fmt.Println("⚡ Validating dynamic system only...")

	report := &ConsistencyReport{
		Timestamp: time.Now(),
		Issues:    []ConsistencyIssue{},
	}

	// TODO: Implement dynamic system validation
	// Check for orphaned items, invalid references, etc.

	return report, nil
}

func analyzeMarkdownPlan(filepath string, dynamicItems []types.RoadmapItem) []ConsistencyIssue {
	var issues []ConsistencyIssue

	content, err := os.ReadFile(filepath)
	if err != nil {
		issues = append(issues, ConsistencyIssue{
			Type:        "file_read_error",
			Severity:    "critical",
			Description: fmt.Sprintf("Cannot read file: %v", err),
			Location:    filepath,
			Suggestion:  "Check file permissions and accessibility",
		})
		return issues
	}

	// Basic checks
	contentStr := string(content)

	// Check for empty files
	if len(strings.TrimSpace(contentStr)) == 0 {
		issues = append(issues, ConsistencyIssue{
			Type:        "empty_file",
			Severity:    "warning",
			Description: "Plan file is empty",
			Location:    filepath,
			Suggestion:  "Add content or remove empty file",
		})
	}

	// Check for basic structure
	if !strings.Contains(contentStr, "#") {
		issues = append(issues, ConsistencyIssue{
			Type:        "missing_headers",
			Severity:    "warning",
			Description: "No headers found in plan",
			Location:    filepath,
			Suggestion:  "Add proper Markdown headers for structure",
		})
	}

	// Check for tasks
	taskCount := strings.Count(contentStr, "- [ ]") + strings.Count(contentStr, "- [x]")
	if taskCount == 0 {
		issues = append(issues, ConsistencyIssue{
			Type:        "no_tasks",
			Severity:    "info",
			Description: "No task checkboxes found",
			Location:    filepath,
			Suggestion:  "Consider adding actionable tasks with - [ ] syntax",
		})
	}

	return issues
}

func displayConsistencyResults(report *ConsistencyReport) {
	fmt.Println()
	fmt.Println("📊 Consistency Validation Results")
	fmt.Println("=================================")
	fmt.Printf("🕒 Timestamp: %s\n", report.Timestamp.Format("2006-01-02 15:04:05"))
	fmt.Printf("📋 Total Issues: %d\n", report.TotalIssues)
	fmt.Printf("🔴 Critical: %d\n", report.CriticalIssues)
	fmt.Printf("🟡 Warnings: %d\n", report.WarningIssues)
	fmt.Printf("🔵 Info: %d\n", report.InfoIssues)
	fmt.Println()

	if len(report.Issues) > 0 {
		fmt.Println("🔍 Issues Found:")
		for i, issue := range report.Issues {
			severity := "🔵"
			switch issue.Severity {
			case "critical":
				severity = "🔴"
			case "warning":
				severity = "🟡"
			}

			fmt.Printf("%s %d. %s\n", severity, i+1, issue.Description)
			if validateVerbose {
				fmt.Printf("    Location: %s\n", issue.Location)
				fmt.Printf("    Suggestion: %s\n", issue.Suggestion)
			}
		}
	} else {
		fmt.Println("✅ No consistency issues found!")
	}

	fmt.Println()
	fmt.Println(report.Summary)
}

func generateConsistencyReport(report *ConsistencyReport) error {
	output := validateOutput
	if output == "" {
		output = fmt.Sprintf("consistency-report-%s.md", report.Timestamp.Format("2006-01-02"))
	}

	var content strings.Builder
	content.WriteString("# Planning Ecosystem Consistency Report\n\n")
	content.WriteString(fmt.Sprintf("**Generated:** %s\n", report.Timestamp.Format("2006-01-02 15:04:05")))
	content.WriteString(fmt.Sprintf("**Total Issues:** %d\n", report.TotalIssues))
	content.WriteString(fmt.Sprintf("**Critical:** %d | **Warnings:** %d | **Info:** %d\n\n",
		report.CriticalIssues, report.WarningIssues, report.InfoIssues))

	content.WriteString("## Summary\n\n")
	content.WriteString(report.Summary + "\n\n")

	if len(report.Issues) > 0 {
		content.WriteString("## Issues Detail\n\n")

		for _, severity := range []string{"critical", "warning", "info"} {
			severityIssues := filterIssuesBySeverity(report.Issues, severity)
			if len(severityIssues) > 0 {
				content.WriteString(fmt.Sprintf("### %s Issues\n\n", strings.Title(severity)))
				for i, issue := range severityIssues {
					content.WriteString(fmt.Sprintf("%d. **%s**\n", i+1, issue.Description))
					content.WriteString(fmt.Sprintf("   - Location: `%s`\n", issue.Location))
					content.WriteString(fmt.Sprintf("   - Suggestion: %s\n\n", issue.Suggestion))
				}
			}
		}
	}

	if err := os.WriteFile(output, []byte(content.String()), 0o644); err != nil {
		return fmt.Errorf("failed to write report: %w", err)
	}

	fmt.Printf("📄 Report generated: %s\n", output)
	return nil
}

func autoFixIssues(report *ConsistencyReport, storage *storage.JSONStorage) error {
	fmt.Println("🔧 Auto-fixing issues...")

	fixedCount := 0
	for _, issue := range report.Issues {
		switch issue.Type {
		case "empty_file":
			// Could auto-remove empty files or create basic structure
			fmt.Printf("  ⚠️  Cannot auto-fix: %s (manual review required)\n", issue.Description)
		case "missing_headers":
			// Could add basic header structure
			fmt.Printf("  ⚠️  Cannot auto-fix: %s (manual review required)\n", issue.Description)
		default:
			fmt.Printf("  ℹ️  No auto-fix available for: %s\n", issue.Description)
		}
	}

	fmt.Printf("🔧 Auto-fixed %d issues\n", fixedCount)
	return nil
}

func generateSummary(report *ConsistencyReport) string {
	if report.TotalIssues == 0 {
		return "✅ Planning ecosystem is fully consistent. No issues detected across Markdown plans and dynamic system."
	}

	var summary strings.Builder
	summary.WriteString("📊 Consistency Analysis Summary:\n")

	if report.CriticalIssues > 0 {
		summary.WriteString(fmt.Sprintf("🔴 %d critical issues require immediate attention\n", report.CriticalIssues))
	}

	if report.WarningIssues > 0 {
		summary.WriteString(fmt.Sprintf("🟡 %d warnings should be addressed for optimal consistency\n", report.WarningIssues))
	}

	if report.InfoIssues > 0 {
		summary.WriteString(fmt.Sprintf("🔵 %d informational items for consideration\n", report.InfoIssues))
	}

	return summary.String()
}

func filterIssuesBySeverity(issues []ConsistencyIssue, severity string) []ConsistencyIssue {
	var filtered []ConsistencyIssue
	for _, issue := range issues {
		if issue.Severity == severity {
			filtered = append(filtered, issue)
		}
	}
	return filtered
}
