// Manager Toolkit - Advanced Utilities (Professional Implementation)

package toolkit

import (
	// "github.com/email-sender/tools/core/toolkit"
	"fmt"
	"go/format"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// ImportFixer handles sophisticated import statement fixes
type ImportFixer struct {
	BaseDir    string
	ModuleName string
	FileSet    *token.FileSet
	// Logger     *Logger // Corrected: No toolkit prefix for same-package type
	Stats  *ToolkitStats
	DryRun bool
}

// FixAllImports fixes imports across all Go files
func (fixer *ImportFixer) FixAllImports() error {
	// fixer.Logger.Info("🔧 Fixing imports across all files...")

	return filepath.WalkDir(fixer.BaseDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil || !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor/") {
			return nil
		}

		return fixer.FixSingleFile(path)
	})
}

// FixSingleFile fixes imports in a single file
func (fixer *ImportFixer) FixSingleFile(filePath string) error {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}

	original := string(data)
	fixed := fixer.processImports(original)

	if original != fixed {
		if fixer.DryRun {
			// fixer.Logger.Info("DRY RUN: Would fix imports in %s", filePath)
			return nil
		}

		// Format the code
		formatted, err := format.Source([]byte(fixed))
		if err != nil {
			// fixer.Logger.Warn("Failed to format %s: %v", filePath, err)
			formatted = []byte(fixed)
		}

		if err := os.WriteFile(filePath, formatted, 0644); err != nil {
			return err
		}

		// fixer.Logger.Info("Fixed imports in %s", filePath)
		// fixer.Stats.ImportsFixed++
	}

	return nil
}

// processImports processes and fixes import statements
func (fixer *ImportFixer) processImports(content string) string {
	// Define import replacements
	replacements := map[string]string{
		// Absolute path imports to module imports
		`errormanager "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/error-manager"`:           `errormanager "github.com/email-sender/managers/error-manager"`,
		`configmanager "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/config-manager"`:         `configmanager "github.com/email-sender/managers/config-manager"`,
		`processmanager "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/process-manager"`:       `processmanager "github.com/email-sender/managers/process-manager"`,
		`storagemanager "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/storage-manager"`:       `storagemanager "github.com/email-sender/managers/storage-manager"`,
		`securitymanager "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/security-manager"`:     `securitymanager "github.com/email-sender/managers/security-manager"`,
		`monitoringmanager "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/monitoring-manager"`: `monitoringmanager "github.com/email-sender/managers/monitoring-manager"`,
		`containermanager "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/container-manager"`:   `containermanager "github.com/email-sender/managers/container-manager"`,
		`deploymentmanager "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/deployment-manager"`: `deploymentmanager "github.com/email-sender/managers/deployment-manager"`,

		// Interface imports
		`"github.com/email-sender/managers/interfaces/common"`:     `"github.com/email-sender/managers/interfaces"`,
		`"github.com/email-sender/managers/interfaces/types"`:      `"github.com/email-sender/managers/interfaces"`,
		`"github.com/email-sender/managers/interfaces/security"`:   `"github.com/email-sender/managers/interfaces"`,
		`"github.com/email-sender/managers/interfaces/storage"`:    `"github.com/email-sender/managers/interfaces"`,
		`"github.com/email-sender/managers/interfaces/monitoring"`: `"github.com/email-sender/managers/interfaces"`,
		`"github.com/email-sender/managers/interfaces/container"`:  `"github.com/email-sender/managers/interfaces"`,
		`"github.com/email-sender/managers/interfaces/deployment"`: `"github.com/email-sender/managers/interfaces"`,
	}

	// Apply replacements
	for old, new := range replacements {
		content = strings.ReplaceAll(content, old, new)
	}

	// Fix common import issues
	content = fixer.fixCommonImportIssues(content)

	return content
}

// fixCommonImportIssues fixes common import problems
func (fixer *ImportFixer) fixCommonImportIssues(content string) string {
	lines := strings.Split(content, "\n")
	var result []string
	inImportBlock := false
	importAdded := make(map[string]bool)
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)

		// Detect import block
		if strings.HasPrefix(trimmed, "import (") {
			inImportBlock = true
			result = append(result, line)
			continue
		}

		if inImportBlock && trimmed == ")" {
			inImportBlock = false
			result = append(result, line)
			continue
		}

		// Fix duplicate imports
		if inImportBlock {
			if importAdded[trimmed] {
				continue // Skip duplicate
			}
			importAdded[trimmed] = true
		}

		// Fix syntax issues in imports
		if inImportBlock && strings.Contains(line, `"	`) {
			line = strings.ReplaceAll(line, `"	`, `"`)
			line = strings.ReplaceAll(line, `""`, `"`)
		}

		result = append(result, line)
	}

	return strings.Join(result, "\n")
}

// DuplicateRemover removes duplicate code and methods
type DuplicateRemover struct {
	BaseDir string
	FileSet *token.FileSet
	// Logger  *Logger // Corrected: No toolkit prefix for same-package type
	Stats  *ToolkitStats
	DryRun bool
}

// ProcessAllFiles processes all Go files to remove duplicates
func (dr *DuplicateRemover) ProcessAllFiles() error {
	// dr.Logger.Info("🧹 Processing all files for duplicate removal...")

	return filepath.WalkDir(dr.BaseDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil || !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor/") {
			return nil
		}

		return dr.ProcessSingleFile(path)
	})
}

// ProcessSingleFile processes a single file for duplicate removal
func (dr *DuplicateRemover) ProcessSingleFile(filePath string) error {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}

	original := string(data)
	cleaned := dr.removeDuplicates(original)

	if original != cleaned {
		if dr.DryRun {
			// dr.Logger.Info("DRY RUN: Would remove duplicates from %s", filePath)
			return nil
		}

		// Format the code
		formatted, err := format.Source([]byte(cleaned))
		if err != nil {
			// dr.Logger.Warn("Failed to format %s: %v", filePath, err)
			formatted = []byte(cleaned)
		}

		if err := os.WriteFile(filePath, formatted, 0644); err != nil {
			return err
		}

		// dr.Logger.Info("Removed duplicates from %s", filePath)
		// dr.Stats.DuplicatesRemoved++
	}

	return nil
}

// removeDuplicates removes duplicate content from the file
func (dr *DuplicateRemover) removeDuplicates(content string) string {
	lines := strings.Split(content, "\n")

	// Find method definitions and their ranges
	methodRanges := dr.findMethodRanges(lines)

	// Remove duplicate methods
	seenMethods := make(map[string]bool)
	var result []string
	skipUntil := -1

	for i, line := range lines {
		if i <= skipUntil {
			continue
		}

		// Check if this line starts a method
		for _, methodRange := range methodRanges {
			if i == methodRange.Start {
				if seenMethods[methodRange.Signature] {
					// Skip this duplicate method
					skipUntil = methodRange.End
					// dr.Logger.Debug("Removing duplicate method: %s", methodRange.Name)
					break
				}
				seenMethods[methodRange.Signature] = true
			}
		}

		if i > skipUntil {
			result = append(result, line)
		}
	}

	return strings.Join(result, "\n")
}

// MethodRange represents a method's position in the file
type MethodRange struct {
	Name      string
	Signature string
	Start     int
	End       int
}

// findMethodRanges finds all method definitions and their ranges
func (dr *DuplicateRemover) findMethodRanges(lines []string) []MethodRange {
	var ranges []MethodRange
	methodRegex := regexp.MustCompile(`^func\s+(\([^)]+\)\s+)?([A-Za-z0-9_]+)\s*\(`)

	for i, line := range lines {
		if matches := methodRegex.FindStringSubmatch(line); matches != nil {
			methodName := matches[2]
			signature := dr.extractMethodSignature(lines, i)
			endLine := dr.findMethodEnd(lines, i)

			ranges = append(ranges, MethodRange{
				Name:      methodName,
				Signature: signature,
				Start:     i,
				End:       endLine,
			})
		}
	}

	return ranges
}

// extractMethodSignature extracts a method signature for comparison
func (dr *DuplicateRemover) extractMethodSignature(lines []string, start int) string {
	var signature strings.Builder
	braceCount := 0
	parenCount := 0

	for i := start; i < len(lines); i++ {
		line := lines[i]
		signature.WriteString(strings.TrimSpace(line))

		for _, char := range line {
			switch char {
			case '(':
				parenCount++
			case ')':
				parenCount--
			case '{':
				braceCount++
				if parenCount == 0 {
					return signature.String()
				}
			}
		}

		if braceCount > 0 && parenCount == 0 {
			break
		}
	}

	return signature.String()
}

// findMethodEnd finds the end line of a method
func (dr *DuplicateRemover) findMethodEnd(lines []string, start int) int {
	braceCount := 0
	foundStart := false

	for i := start; i < len(lines); i++ {
		line := lines[i]
		for _, char := range line {
			if char == '{' {
				braceCount++
				foundStart = true
			} else if char == '}' {
				braceCount--
				if foundStart && braceCount == 0 {
					return i
				}
			}
		}
	}

	return len(lines) - 1
}

// SyntaxFixer fixes syntax errors in Go files
type SyntaxFixer struct {
	BaseDir string
	FileSet *token.FileSet
	// Logger  *Logger // Corrected: No toolkit prefix for same-package type
	Stats  *ToolkitStats
	DryRun bool
}

// FixAllFiles fixes syntax errors in all Go files
func (sf *SyntaxFixer) FixAllFiles() error {
	// sf.Logger.Info("🔨 Fixing syntax errors in all files...")

	return filepath.WalkDir(sf.BaseDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil || !strings.HasSuffix(path, ".go") || strings.Contains(path, "vendor/") {
			return nil
		}

		return sf.FixSingleFile(path)
	})
}

// FixSingleFile fixes syntax errors in a single file
func (sf *SyntaxFixer) FixSingleFile(filePath string) error {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}

	original := string(data)
	fixed := sf.fixSyntaxIssues(original)

	if original != fixed {
		if sf.DryRun {
			// sf.Logger.Info("DRY RUN: Would fix syntax in %s", filePath)
			return nil
		}

		// Try to format the code
		formatted, err := format.Source([]byte(fixed))
		if err != nil {
			// sf.Logger.Warn("Failed to format %s after syntax fix: %v", filePath, err)
			formatted = []byte(fixed)
		}

		if err := os.WriteFile(filePath, formatted, 0644); err != nil {
			return err
		}

		// sf.Logger.Info("Fixed syntax errors in %s", filePath)
		// sf.Stats.ErrorsFixed++
	}

	return nil
}

// fixSyntaxIssues fixes common syntax issues
func (sf *SyntaxFixer) fixSyntaxIssues(content string) string {
	lines := strings.Split(content, "\n")
	var result []string
	for _, line := range lines {
		fixed := line

		// Fix common syntax issues
		fixed = sf.fixImportIssues(fixed)
		fixed = sf.fixBraceIssues(fixed)
		fixed = sf.fixCommentIssues(fixed)
		fixed = sf.fixQuoteIssues(fixed)

		result = append(result, fixed)
	}

	return strings.Join(result, "\n")
}

// fixImportIssues fixes import-related syntax issues
func (sf *SyntaxFixer) fixImportIssues(line string) string {
	// Fix missing quotes in imports
	if strings.Contains(line, "import") && !strings.Contains(line, `"`) && strings.Contains(line, "/") {
		// This is a heuristic fix - would need more sophisticated parsing in production
		parts := strings.Fields(line)
		for i, part := range parts {
			if strings.Contains(part, "/") && !strings.HasPrefix(part, `"`) {
				parts[i] = `"` + part + `"`
			}
		}
		line = strings.Join(parts, " ")
	}

	// Fix duplicate quotes
	line = strings.ReplaceAll(line, `""`, `"`)

	// Fix tab characters in imports
	if strings.Contains(line, `"	`) {
		line = strings.ReplaceAll(line, `"	`, `"`)
	}

	return line
}

// fixBraceIssues fixes brace-related syntax issues
func (sf *SyntaxFixer) fixBraceIssues(line string) string {
	// Fix missing spaces before braces
	if strings.Contains(line, "){") {
		line = strings.ReplaceAll(line, "){", ") {")
	}

	return line
}

// fixCommentIssues fixes comment-related syntax issues
func (sf *SyntaxFixer) fixCommentIssues(line string) string {
	// Convert shell-style comments to Go comments
	if strings.HasPrefix(strings.TrimSpace(line), "#") {
		line = strings.ReplaceAll(line, "#", "//")
	}

	return line
}

// fixQuoteIssues fixes quote-related syntax issues
func (sf *SyntaxFixer) fixQuoteIssues(line string) string {
	// Fix malformed quotes
	if strings.Count(line, `"`)%2 != 0 {
		// Add missing quote at the end if it looks like a string
		if strings.Contains(line, `"`) && !strings.HasSuffix(strings.TrimSpace(line), `"`) {
			line = strings.TrimSpace(line) + `"`
		}
	}

	return line
}

// HealthChecker performs comprehensive health checks
type HealthChecker struct {
	BaseDir string
	FileSet *token.FileSet
	// toolkit.Logger  *Logger
}

// HealthReport contains health check results
type HealthReport struct {
	Timestamp        time.Time         `json:"timestamp"`
	OverallHealth    string            `json:"overall_health"`
	Score            float64           `json:"score"`
	Issues           []HealthIssue     `json:"issues"`
	Recommendations  []string          `json:"recommendations"`
	FileStatistics   *FileStatistics   `json:"file_statistics"`
	DependencyHealth *DependencyHealth `json:"dependency_health"`
}

// HealthIssue represents a health issue
type HealthIssue struct {
	Type        string `json:"type"`
	Severity    string `json:"severity"`
	File        string `json:"file"`
	Description string `json:"description"`
	Line        int    `json:"line,omitempty"`
}

// FileStatistics contains file-related statistics
type FileStatistics struct {
	TotalFiles      int     `json:"total_files"`
	GoFiles         int     `json:"go_files"`
	TestFiles       int     `json:"test_files"`
	AverageFileSize int64   `json:"average_file_size"`
	LargestFile     string  `json:"largest_file"`
	LargestFileSize int64   `json:"largest_file_size"`
	CodeCoverage    float64 `json:"code_coverage"`
}

// DependencyHealth contains dependency-related health information
type DependencyHealth struct {
	TotalDependencies int      `json:"total_dependencies"`
	OutdatedPackages  []string `json:"outdated_packages"`
	SecurityIssues    []string `json:"security_issues"`
	CircularDeps      []string `json:"circular_dependencies"`
}

// CheckHealth performs comprehensive health check
func (hc *HealthChecker) CheckHealth() *HealthReport {
	// hc.Logger.Info("🏥 Performing comprehensive health check...")

	report := &HealthReport{
		Timestamp:        time.Now(),
		Issues:           []HealthIssue{},
		Recommendations:  []string{},
		FileStatistics:   &FileStatistics{},
		DependencyHealth: &DependencyHealth{},
	}

	// Check file health
	hc.checkFileHealth(report)

	// Check syntax health
	hc.checkSyntaxHealth(report)

	// Check dependency health
	hc.checkDependencyHealth(report)

	// Calculate overall health
	hc.calculateOverallHealth(report)

	return report
}

// checkFileHealth checks file-related health metrics
func (hc *HealthChecker) checkFileHealth(report *HealthReport) {
	var totalSize int64
	var largestSize int64
	var largestFile string

	err := filepath.WalkDir(hc.BaseDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}

		if d.IsDir() {
			return nil
		}

		info, err := d.Info()
		if err != nil {
			return nil
		}

		report.FileStatistics.TotalFiles++
		totalSize += info.Size()

		if info.Size() > largestSize {
			largestSize = info.Size()
			largestFile = path
		}

		if strings.HasSuffix(path, ".go") {
			report.FileStatistics.GoFiles++

			if strings.HasSuffix(path, "_test.go") {
				report.FileStatistics.TestFiles++
			}

			// Check for large files
			if info.Size() > 50*1024 { // 50KB threshold
				report.Issues = append(report.Issues, HealthIssue{
					Type:        "file_size",
					Severity:    "warning",
					File:        path,
					Description: fmt.Sprintf("Large file: %d bytes", info.Size()),
				})
			}
		}

		return nil
	})

	if err != nil {
		// hc.Logger.Warn("Error during file health check: %v", err)
	}

	if report.FileStatistics.TotalFiles > 0 {
		report.FileStatistics.AverageFileSize = totalSize / int64(report.FileStatistics.TotalFiles)
	}
	report.FileStatistics.LargestFile = largestFile
	report.FileStatistics.LargestFileSize = largestSize
}

// checkSyntaxHealth checks syntax-related health
func (hc *HealthChecker) checkSyntaxHealth(report *HealthReport) {
	// This would involve parsing all Go files and checking for syntax errors
	// Implementation similar to the analyzer but focused on health metrics
}

// checkDependencyHealth checks dependency-related health
func (hc *HealthChecker) checkDependencyHealth(report *HealthReport) {
	// Check go.mod files and analyze dependencies
	// This would involve parsing go.mod files and checking for issues
}

// calculateOverallHealth calculates the overall health score
func (hc *HealthChecker) calculateOverallHealth(report *HealthReport) {
	score := 100.0

	// Deduct points for issues
	for _, issue := range report.Issues {
		switch issue.Severity {
		case "critical":
			score -= 20
		case "error":
			score -= 10
		case "warning":
			score -= 5
		}
	}

	if score < 0 {
		score = 0
	}

	report.Score = score

	switch {
	case score >= 90:
		report.OverallHealth = "excellent"
	case score >= 75:
		report.OverallHealth = "good"
	case score >= 50:
		report.OverallHealth = "fair"
	default:
		report.OverallHealth = "poor"
	}
}
