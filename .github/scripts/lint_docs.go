package scripts

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// LintReport represents the complete linting results
type LintReport struct {
	GeneratedAt	time.Time		`json:"generated_at"`
	ProjectName	string			`json:"project_name"`
	FilesLinted	int			`json:"files_linted"`
	TotalIssues	int			`json:"total_issues"`
	IssuesByLevel	map[string]int		`json:"issues_by_level"`
	FileResults	[]FileLintResult	`json:"file_results"`
	Summary		LintSummary		`json:"summary"`
	Configuration	LintConfiguration	`json:"configuration"`
}

// FileLintResult represents linting results for a single file
type FileLintResult struct {
	FilePath	string		`json:"file_path"`
	FileSize	int64		`json:"file_size"`
	LineCount	int		`json:"line_count"`
	Issues		[]LintIssue	`json:"issues"`
	Score		float64		`json:"score"`
	Status		string		`json:"status"`
}

// LintIssue represents a single linting issue
type LintIssue struct {
	Rule		string	`json:"rule"`
	Level		string	`json:"level"`
	Message		string	`json:"message"`
	Line		int	`json:"line"`
	Column		int	`json:"column"`
	Context		string	`json:"context"`
	Suggestion	string	`json:"suggestion"`
}

// LintSummary represents overall linting summary
type LintSummary struct {
	OverallScore	float64		`json:"overall_score"`
	PassedFiles	int		`json:"passed_files"`
	WarningFiles	int		`json:"warning_files"`
	FailedFiles	int		`json:"failed_files"`
	TopIssues	[]IssueCount	`json:"top_issues"`
	Recommendations	[]string	`json:"recommendations"`
}

// IssueCount represents issue frequency
type IssueCount struct {
	Rule	string	`json:"rule"`
	Count	int	`json:"count"`
}

// LintConfiguration represents linting configuration
type LintConfiguration struct {
	Rules		[]LintRule	`json:"rules"`
	ScoreWeights	ScoreWeights	`json:"score_weights"`
	Thresholds	Thresholds	`json:"thresholds"`
}

// LintRule represents a linting rule
type LintRule struct {
	Name		string	`json:"name"`
	Level		string	`json:"level"`
	Description	string	`json:"description"`
	Pattern		string	`json:"pattern"`
	Enabled		bool	`json:"enabled"`
}

// ScoreWeights represents score calculation weights
type ScoreWeights struct {
	Error	float64	`json:"error"`
	Warning	float64	`json:"warning"`
	Info	float64	`json:"info"`
}

// Thresholds represents quality thresholds
type Thresholds struct {
	Pass	float64	`json:"pass"`
	Warning	float64	`json:"warning"`
	Fail	float64	`json:"fail"`
}

func main() {
	projectRoot := "."
	if len(os.Args) > 1 {
		projectRoot = os.Args[1]
	}

	report, err := lintDocumentation(projectRoot)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error linting documentation: %v\n", err)
		os.Exit(1)
	}

	// Output JSON to stdout
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(report); err != nil {
		fmt.Fprintf(os.Stderr, "Error encoding JSON: %v\n", err)
		os.Exit(1)
	}
}

func lintDocumentation(root string) (*LintReport, error) {
	projectName := filepath.Base(root)
	if projectName == "." || projectName == "/" {
		projectName = "project"
	}

	config := getDefaultConfiguration()

	// Find all documentation files
	docFiles, err := findDocumentationFiles(root)
	if err != nil {
		return nil, err
	}

	var fileResults []FileLintResult
	issuesByLevel := make(map[string]int)
	totalIssues := 0

	// Lint each file
	for _, filePath := range docFiles {
		result, err := lintFile(filePath, config)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Warning: Failed to lint %s: %v\n", filePath, err)
			continue
		}

		fileResults = append(fileResults, result)
		for _, issue := range result.Issues {
			issuesByLevel[issue.Level]++
			totalIssues++
		}
	}

	// Generate summary
	summary := generateSummary(fileResults, config)

	report := &LintReport{
		GeneratedAt:	time.Now(),
		ProjectName:	projectName,
		FilesLinted:	len(fileResults),
		TotalIssues:	totalIssues,
		IssuesByLevel:	issuesByLevel,
		FileResults:	fileResults,
		Summary:	summary,
		Configuration:	config,
	}

	return report, nil
}

func getDefaultConfiguration() LintConfiguration {
	rules := []LintRule{
		{
			Name:		"missing_title",
			Level:		"error",
			Description:	"Document should have a title (# heading)",
			Pattern:	"^#\\s+.+",
			Enabled:	true,
		},
		{
			Name:		"long_lines",
			Level:		"warning",
			Description:	"Lines should be under 120 characters",
			Pattern:	"",
			Enabled:	true,
		},
		{
			Name:		"empty_headers",
			Level:		"warning",
			Description:	"Headers should not be empty",
			Pattern:	"^#+\\s*$",
			Enabled:	true,
		},
		{
			Name:		"broken_links",
			Level:		"error",
			Description:	"Links should be valid",
			Pattern:	"\\[([^\\]]+)\\]\\(([^\\)]+)\\)",
			Enabled:	true,
		},
		{
			Name:		"missing_description",
			Level:		"info",
			Description:	"Document should have a description after title",
			Pattern:	"",
			Enabled:	true,
		},
		{
			Name:		"inconsistent_heading_levels",
			Level:		"warning",
			Description:	"Heading levels should be consistent",
			Pattern:	"^#+",
			Enabled:	true,
		},
		{
			Name:		"missing_toc",
			Level:		"info",
			Description:	"Long documents should have a table of contents",
			Pattern:	"",
			Enabled:	true,
		},
		{
			Name:		"trailing_whitespace",
			Level:		"info",
			Description:	"Lines should not have trailing whitespace",
			Pattern:	"\\s+$",
			Enabled:	true,
		},
	}

	return LintConfiguration{
		Rules:	rules,
		ScoreWeights: ScoreWeights{
			Error:		10.0,
			Warning:	5.0,
			Info:		1.0,
		},
		Thresholds: Thresholds{
			Pass:		80.0,
			Warning:	60.0,
			Fail:		40.0,
		},
	}
}

func findDocumentationFiles(root string) ([]string, error) {
	var files []string

	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		// Get relative path
		relPath, err := filepath.Rel(root, path)
		if err != nil {
			relPath = path
		}

		// Check if it's a documentation file
		if isDocumentationFile(relPath, info.Name()) && !shouldSkipPath(relPath) {
			files = append(files, path)
		}

		return nil
	})

	return files, err
}

func lintFile(filePath string, config LintConfiguration) (FileLintResult, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return FileLintResult{}, err
	}
	defer file.Close()

	// Get file info
	info, err := file.Stat()
	if err != nil {
		return FileLintResult{}, err
	}

	// Read file content
	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		return FileLintResult{}, err
	}

	// Run linting rules
	var issues []LintIssue
	for _, rule := range config.Rules {
		if !rule.Enabled {
			continue
		}

		ruleIssues := applyRule(rule, lines, filePath)
		issues = append(issues, ruleIssues...)
	}

	// Calculate score
	score := calculateFileScore(issues, config.ScoreWeights, len(lines))

	// Determine status
	status := "pass"
	if score < config.Thresholds.Fail {
		status = "fail"
	} else if score < config.Thresholds.Warning {
		status = "warning"
	}

	result := FileLintResult{
		FilePath:	filePath,
		FileSize:	info.Size(),
		LineCount:	len(lines),
		Issues:		issues,
		Score:		score,
		Status:		status,
	}

	return result, nil
}

func applyRule(rule LintRule, lines []string, filePath string) []LintIssue {
	var issues []LintIssue

	switch rule.Name {
	case "missing_title":
		if !hasTitle(lines) {
			issues = append(issues, LintIssue{
				Rule:		rule.Name,
				Level:		rule.Level,
				Message:	"Document is missing a title (# heading)",
				Line:		1,
				Column:		1,
				Context:	"",
				Suggestion:	"Add a title at the beginning: # Document Title",
			})
		}

	case "long_lines":
		for i, line := range lines {
			if len(line) > 120 {
				issues = append(issues, LintIssue{
					Rule:		rule.Name,
					Level:		rule.Level,
					Message:	fmt.Sprintf("Line is too long (%d characters)", len(line)),
					Line:		i + 1,
					Column:		121,
					Context:	truncateString(line, 50),
					Suggestion:	"Break line into shorter segments",
				})
			}
		}

	case "empty_headers":
		for i, line := range lines {
			if matched, _ := regexp.MatchString(rule.Pattern, line); matched {
				issues = append(issues, LintIssue{
					Rule:		rule.Name,
					Level:		rule.Level,
					Message:	"Header is empty",
					Line:		i + 1,
					Column:		1,
					Context:	line,
					Suggestion:	"Add descriptive text after the header",
				})
			}
		}

	case "broken_links":
		for i, line := range lines {
			issues = append(issues, checkLinksInLine(line, i+1, rule)...)
		}

	case "missing_description":
		if !hasDescription(lines) {
			issues = append(issues, LintIssue{
				Rule:		rule.Name,
				Level:		rule.Level,
				Message:	"Document is missing a description after the title",
				Line:		2,
				Column:		1,
				Context:	"",
				Suggestion:	"Add a brief description after the title",
			})
		}

	case "inconsistent_heading_levels":
		issues = append(issues, checkHeadingConsistency(lines, rule)...)

	case "missing_toc":
		if shouldHaveTOC(lines) && !hasTOC(lines) {
			issues = append(issues, LintIssue{
				Rule:		rule.Name,
				Level:		rule.Level,
				Message:	"Long document should have a table of contents",
				Line:		1,
				Column:		1,
				Context:	"",
				Suggestion:	"Add a TOC after the title and description",
			})
		}

	case "trailing_whitespace":
		for i, line := range lines {
			if matched, _ := regexp.MatchString(rule.Pattern, line); matched {
				issues = append(issues, LintIssue{
					Rule:		rule.Name,
					Level:		rule.Level,
					Message:	"Line has trailing whitespace",
					Line:		i + 1,
					Column:		len(strings.TrimRightFunc(line, func(r rune) bool { return r != ' ' && r != '\t' })) + 1,
					Context:	line,
					Suggestion:	"Remove trailing whitespace",
				})
			}
		}
	}

	return issues
}

func hasTitle(lines []string) bool {
	for _, line := range lines[:min(5, len(lines))] {
		if strings.HasPrefix(strings.TrimSpace(line), "# ") {
			return true
		}
	}
	return false
}

func hasDescription(lines []string) bool {
	titleFound := false
	for _, line := range lines[:min(10, len(lines))] {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "# ") {
			titleFound = true
			continue
		}
		if titleFound && len(trimmed) > 20 && !strings.HasPrefix(trimmed, "#") {
			return true
		}
	}
	return false
}

func shouldHaveTOC(lines []string) bool {
	return len(lines) > 50	// Long documents should have TOC
}

func hasTOC(lines []string) bool {
	content := strings.ToLower(strings.Join(lines, "\n"))
	return strings.Contains(content, "table of contents") ||
		strings.Contains(content, "## contents") ||
		strings.Contains(content, "toc")
}

func checkLinksInLine(line string, lineNum int, rule LintRule) []LintIssue {
	var issues []LintIssue

	re := regexp.MustCompile(`\[([^\]]+)\]\(([^\)]+)\)`)
	matches := re.FindAllStringSubmatch(line, -1)

	for _, match := range matches {
		if len(match) >= 3 {
			linkText := match[1]
			linkURL := match[2]

			// Basic validation
			if linkText == "" {
				issues = append(issues, LintIssue{
					Rule:		rule.Name,
					Level:		rule.Level,
					Message:	"Link has empty text",
					Line:		lineNum,
					Column:		strings.Index(line, match[0]) + 1,
					Context:	match[0],
					Suggestion:	"Add descriptive text for the link",
				})
			}

			if linkURL == "" {
				issues = append(issues, LintIssue{
					Rule:		rule.Name,
					Level:		rule.Level,
					Message:	"Link has empty URL",
					Line:		lineNum,
					Column:		strings.Index(line, match[0]) + 1,
					Context:	match[0],
					Suggestion:	"Add a valid URL or file path",
				})
			}
		}
	}

	return issues
}

func checkHeadingConsistency(lines []string, rule LintRule) []LintIssue {
	var issues []LintIssue
	var headingLevels []int

	for i, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), "#") {
			level := 0
			for _, char := range line {
				if char == '#' {
					level++
				} else {
					break
				}
			}

			if level > 0 {
				headingLevels = append(headingLevels, level)

				// Check for skipped levels
				if len(headingLevels) > 1 {
					prevLevel := headingLevels[len(headingLevels)-2]
					if level > prevLevel+1 {
						issues = append(issues, LintIssue{
							Rule:		rule.Name,
							Level:		rule.Level,
							Message:	fmt.Sprintf("Heading level jumps from %d to %d", prevLevel, level),
							Line:		i + 1,
							Column:		1,
							Context:	line,
							Suggestion:	"Use consecutive heading levels",
						})
					}
				}
			}
		}
	}

	return issues
}

func calculateFileScore(issues []LintIssue, weights ScoreWeights, lineCount int) float64 {
	if lineCount == 0 {
		return 0.0
	}

	totalDeductions := 0.0
	for _, issue := range issues {
		switch issue.Level {
		case "error":
			totalDeductions += weights.Error
		case "warning":
			totalDeductions += weights.Warning
		case "info":
			totalDeductions += weights.Info
		}
	}

	// Base score of 100, with deductions normalized by file size
	score := 100.0 - (totalDeductions / float64(lineCount) * 100.0)
	if score < 0 {
		score = 0
	}

	return score
}

func generateSummary(fileResults []FileLintResult, config LintConfiguration) LintSummary {
	var passedFiles, warningFiles, failedFiles int
	var totalScore float64
	issueCount := make(map[string]int)

	for _, result := range fileResults {
		totalScore += result.Score

		switch result.Status {
		case "pass":
			passedFiles++
		case "warning":
			warningFiles++
		case "fail":
			failedFiles++
		}

		for _, issue := range result.Issues {
			issueCount[issue.Rule]++
		}
	}

	// Calculate overall score
	overallScore := 0.0
	if len(fileResults) > 0 {
		overallScore = totalScore / float64(len(fileResults))
	}

	// Get top issues
	var topIssues []IssueCount
	for rule, count := range issueCount {
		topIssues = append(topIssues, IssueCount{Rule: rule, Count: count})
	}

	// Sort by count (descending)
	for i := 0; i < len(topIssues); i++ {
		for j := i + 1; j < len(topIssues); j++ {
			if topIssues[j].Count > topIssues[i].Count {
				topIssues[i], topIssues[j] = topIssues[j], topIssues[i]
			}
		}
	}

	// Keep only top 5
	if len(topIssues) > 5 {
		topIssues = topIssues[:5]
	}

	// Generate recommendations
	var recommendations []string
	if overallScore < config.Thresholds.Warning {
		recommendations = append(recommendations, "Overall documentation quality needs improvement")
	}
	if failedFiles > 0 {
		recommendations = append(recommendations, fmt.Sprintf("Focus on %d failed files first", failedFiles))
	}
	if len(topIssues) > 0 {
		recommendations = append(recommendations, fmt.Sprintf("Most common issue: %s", topIssues[0].Rule))
	}

	return LintSummary{
		OverallScore:		overallScore,
		PassedFiles:		passedFiles,
		WarningFiles:		warningFiles,
		FailedFiles:		failedFiles,
		TopIssues:		topIssues,
		Recommendations:	recommendations,
	}
}

// Helper functions
func isDocumentationFile(path, name string) bool {
	ext := strings.ToLower(filepath.Ext(name))
	docExts := []string{".md", ".txt", ".rst", ".adoc", ".org"}

	for _, docExt := range docExts {
		if ext == docExt {
			return true
		}
	}

	baseName := strings.ToUpper(name)
	specialFiles := []string{"README", "CHANGELOG", "LICENSE", "AUTHORS", "CONTRIBUTORS"}
	for _, special := range specialFiles {
		if strings.HasPrefix(baseName, special) {
			return true
		}
	}

	pathLower := strings.ToLower(path)
	if strings.HasPrefix(pathLower, "docs/") || strings.Contains(pathLower, "/docs/") ||
		strings.HasPrefix(pathLower, ".github/") || strings.Contains(pathLower, "/.github/") {
		return ext == ".md" || ext == ".txt"
	}

	return false
}

func shouldSkipPath(path string) bool {
	skipPaths := []string{
		"node_modules", ".git", "vendor", "build", "dist",
		"coverage", "backup", ".avg-exclude", "bin", "tmp",
	}

	pathLower := strings.ToLower(path)
	for _, skip := range skipPaths {
		if strings.HasPrefix(pathLower, skip+"/") ||
			strings.Contains(pathLower, "/"+skip+"/") ||
			strings.HasSuffix(pathLower, "/"+skip) ||
			pathLower == skip {
			return true
		}
	}
	return false
}

func truncateString(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
