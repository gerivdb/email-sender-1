package scripts

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// GapAnalysisReport represents documentation gaps and recommendations
type GapAnalysisReport struct {
	GeneratedAt       time.Time        `json:"generated_at"`
	ProjectName       string           `json:"project_name"`
	TotalFilesScanned int              `json:"total_files_scanned"`
	IdentifiedGaps    []DocumentGap    `json:"identified_gaps"`
	Recommendations   []Recommendation `json:"recommendations"`
	CoverageScore     float64          `json:"coverage_score"`
	Priority          string           `json:"priority"`
	Summary           string           `json:"summary"`
}

// DocumentGap represents a missing or inadequate documentation area
type DocumentGap struct {
	Category     string   `json:"category"`
	Type         string   `json:"type"`
	Severity     string   `json:"severity"`
	Description  string   `json:"description"`
	MissingFiles []string `json:"missing_files"`
	Impact       string   `json:"impact"`
}

// Recommendation represents an actionable recommendation
type Recommendation struct {
	Priority    string   `json:"priority"`
	Action      string   `json:"action"`
	Description string   `json:"description"`
	Files       []string `json:"files"`
	Effort      string   `json:"effort"`
}

// ExpectedFiles defines the standard documentation files expected in a project
var ExpectedFiles = map[string][]string{
	"root": {
		"README.md", "CHANGELOG.md", "LICENSE", "CONTRIBUTING.md",
		"CODE_OF_CONDUCT.md", "SECURITY.md", "INSTALLATION.md",
	},
	"docs": {
		"docs/README.md", "docs/api.md", "docs/development.md",
		"docs/deployment.md", "docs/architecture.md", "docs/troubleshooting.md",
	},
	"github": {
		".github/README.md", ".github/CONTRIBUTING.md",
		".github/ISSUE_TEMPLATE.md", ".github/PULL_REQUEST_TEMPLATE.md",
	},
	"development": {
		"docs/development/setup.md", "docs/development/guidelines.md",
		"docs/development/testing.md", "docs/development/ci-cd.md",
	},
	"api": {
		"docs/api/README.md", "docs/api/endpoints.md",
		"docs/api/authentication.md", "docs/api/examples.md",
	},
}

func main() {
	projectRoot := "."
	if len(os.Args) > 1 {
		projectRoot = os.Args[1]
	}

	report, err := analyzeGaps(projectRoot)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error analyzing gaps: %v\n", err)
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

func analyzeGaps(root string) (*GapAnalysisReport, error) {
	// First, get existing files
	existingFiles, err := getExistingFiles(root)
	if err != nil {
		return nil, err
	}

	// Analyze gaps
	gaps := []DocumentGap{}
	recommendations := []Recommendation{}

	// Check for missing essential files
	for category, expectedFiles := range ExpectedFiles {
		for _, expectedFile := range expectedFiles {
			fullPath := filepath.Join(root, expectedFile)
			if !fileExists(fullPath) {
				gap := DocumentGap{
					Category:     category,
					Type:         "missing_file",
					Severity:     getSeverity(expectedFile),
					Description:  fmt.Sprintf("Missing %s file", expectedFile),
					MissingFiles: []string{expectedFile},
					Impact:       getImpact(expectedFile),
				}
				gaps = append(gaps, gap)

				// Add recommendation
				rec := Recommendation{
					Priority:    gap.Severity,
					Action:      "create",
					Description: fmt.Sprintf("Create %s file", expectedFile),
					Files:       []string{expectedFile},
					Effort:      getEffort(expectedFile),
				}
				recommendations = append(recommendations, rec)
			}
		}
	}

	// Check for outdated files
	for _, file := range existingFiles {
		if isOutdated(file) {
			gap := DocumentGap{
				Category:     "maintenance",
				Type:         "outdated_content",
				Severity:     "medium",
				Description:  fmt.Sprintf("File %s appears outdated", file),
				MissingFiles: []string{file},
				Impact:       "May contain incorrect information",
			}
			gaps = append(gaps, gap)

			rec := Recommendation{
				Priority:    "medium",
				Action:      "update",
				Description: fmt.Sprintf("Review and update %s", file),
				Files:       []string{file},
				Effort:      "medium",
			}
			recommendations = append(recommendations, rec)
		}
	}

	// Check for fragmented documentation
	fragmentationGaps := analyzeFragmentation(existingFiles)
	gaps = append(gaps, fragmentationGaps...)

	// Check for missing API documentation
	apiGaps := analyzeAPIDocumentation(root)
	gaps = append(gaps, apiGaps...)

	// Calculate coverage score
	coverageScore := calculateCoverageScore(gaps, len(existingFiles))

	report := &GapAnalysisReport{
		GeneratedAt:       time.Now(),
		ProjectName:       filepath.Base(root),
		TotalFilesScanned: len(existingFiles),
		IdentifiedGaps:    gaps,
		Recommendations:   recommendations,
		CoverageScore:     coverageScore,
		Priority:          getPriorityLevel(gaps, coverageScore),
		Summary:           generateGapSummary(gaps, recommendations, coverageScore),
	}

	return report, nil
}

func getExistingFiles(root string) ([]string, error) {
	var files []string

	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		// Get relative path for consistent processing
		relPath, err := filepath.Rel(root, path)
		if err != nil {
			relPath = path // fallback to absolute path
		}

		// Only consider documentation files
		if isDocumentationFile(relPath, info.Name()) && !shouldSkipPath(relPath) {
			files = append(files, relPath)
		}

		return nil
	})

	return files, err
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func isDocumentationFile(path, name string) bool {
	ext := strings.ToLower(filepath.Ext(name))
	docExts := []string{".md", ".txt", ".rst", ".adoc", ".org"}

	// Check extension
	for _, docExt := range docExts {
		if ext == docExt {
			return true
		}
	}

	// Check special files without extension
	baseName := strings.ToUpper(name)
	specialFiles := []string{"README", "CHANGELOG", "LICENSE", "AUTHORS", "CONTRIBUTORS"}
	for _, special := range specialFiles {
		if strings.HasPrefix(baseName, special) {
			return true
		}
	}

	// Check if in docs directory
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
		// Check if path starts with skip directory
		if strings.HasPrefix(pathLower, skip+"/") ||
			// Check if path contains skip directory
			strings.Contains(pathLower, "/"+skip+"/") ||
			// Check if path ends with skip directory
			strings.HasSuffix(pathLower, "/"+skip) ||
			// Check if path is exactly the skip directory
			pathLower == skip {
			return true
		}
	}
	return false
}

func getSeverity(filename string) string {
	critical := []string{"README.md", "LICENSE", "SECURITY.md"}
	high := []string{"CHANGELOG.md", "CONTRIBUTING.md", "INSTALLATION.md"}

	for _, file := range critical {
		if strings.Contains(filename, file) {
			return "critical"
		}
	}

	for _, file := range high {
		if strings.Contains(filename, file) {
			return "high"
		}
	}

	return "medium"
}

func getImpact(filename string) string {
	impacts := map[string]string{
		"README.md":          "Users cannot understand the project purpose and usage",
		"LICENSE":            "Legal implications for project usage",
		"SECURITY.md":        "Security vulnerabilities may go unreported",
		"CONTRIBUTING.md":    "Contributors don't know how to contribute",
		"CHANGELOG.md":       "Users cannot track changes between versions",
		"INSTALLATION.md":    "Users cannot install or set up the project",
		"CODE_OF_CONDUCT.md": "Community standards are unclear",
	}

	for key, impact := range impacts {
		if strings.Contains(filename, key) {
			return impact
		}
	}

	return "General documentation completeness affected"
}

func getEffort(filename string) string {
	lowEffort := []string{"LICENSE", "CODE_OF_CONDUCT.md"}
	highEffort := []string{"docs/api", "docs/architecture.md", "docs/development"}

	for _, file := range lowEffort {
		if strings.Contains(filename, file) {
			return "low"
		}
	}

	for _, file := range highEffort {
		if strings.Contains(filename, file) {
			return "high"
		}
	}

	return "medium"
}

func isOutdated(filename string) bool {
	// Simple heuristic: check file modification time
	info, err := os.Stat(filename)
	if err != nil {
		return false
	}

	// Consider files older than 6 months as potentially outdated
	sixMonthsAgo := time.Now().AddDate(0, -6, 0)
	return info.ModTime().Before(sixMonthsAgo)
}

func analyzeFragmentation(files []string) []DocumentGap {
	var gaps []DocumentGap

	// Check for scattered documentation
	docDirs := make(map[string]int)
	for _, file := range files {
		dir := filepath.Dir(file)
		docDirs[dir]++
	}

	// If documentation is spread across many directories, suggest consolidation
	if len(docDirs) > 5 {
		gap := DocumentGap{
			Category:     "organization",
			Type:         "fragmentation",
			Severity:     "medium",
			Description:  fmt.Sprintf("Documentation scattered across %d directories", len(docDirs)),
			MissingFiles: []string{},
			Impact:       "Difficult to find and maintain documentation",
		}
		gaps = append(gaps, gap)
	}

	return gaps
}

func analyzeAPIDocumentation(root string) []DocumentGap {
	var gaps []DocumentGap

	// Check if this is likely an API project
	hasAPICode := false
	apiIndicators := []string{"api", "server", "endpoint", "route"}

	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if strings.HasSuffix(path, ".go") || strings.HasSuffix(path, ".js") || strings.HasSuffix(path, ".py") {
			pathLower := strings.ToLower(path)
			for _, indicator := range apiIndicators {
				if strings.Contains(pathLower, indicator) {
					hasAPICode = true
					return filepath.SkipDir
				}
			}
		}

		return nil
	})

	if err == nil && hasAPICode {
		// Check for API documentation
		apiDocExists := false
		for _, file := range []string{"docs/api.md", "api.md", "docs/api/README.md"} {
			if fileExists(filepath.Join(root, file)) {
				apiDocExists = true
				break
			}
		}

		if !apiDocExists {
			gap := DocumentGap{
				Category:     "api",
				Type:         "missing_api_docs",
				Severity:     "high",
				Description:  "API project detected but no API documentation found",
				MissingFiles: []string{"docs/api.md", "docs/api/endpoints.md"},
				Impact:       "Developers cannot understand how to use the API",
			}
			gaps = append(gaps, gap)
		}
	}

	return gaps
}

func calculateCoverageScore(gaps []DocumentGap, totalFiles int) float64 {
	if totalFiles == 0 {
		return 0.0
	}

	// Calculate deductions based on gap severity
	deductions := 0.0
	for _, gap := range gaps {
		switch gap.Severity {
		case "critical":
			deductions += 15.0
		case "high":
			deductions += 8.0
		case "medium":
			deductions += 4.0
		default:
			deductions += 2.0
		}
	}

	// Base score: start at 100 and subtract deductions
	finalScore := 100.0 - deductions

	if finalScore < 0 {
		finalScore = 0
	}
	if finalScore > 100 {
		finalScore = 100
	}

	return finalScore
}

func getPriorityLevel(gaps []DocumentGap, coverageScore float64) string {
	criticalCount := 0
	highCount := 0

	for _, gap := range gaps {
		if gap.Severity == "critical" {
			criticalCount++
		} else if gap.Severity == "high" {
			highCount++
		}
	}

	if criticalCount > 0 || coverageScore < 30 {
		return "critical"
	}
	if highCount > 0 || coverageScore < 60 {
		return "high"
	}
	if coverageScore < 80 {
		return "medium"
	}

	return "low"
}

func generateGapSummary(gaps []DocumentGap, recommendations []Recommendation, coverageScore float64) string {
	summary := fmt.Sprintf("Documentation Coverage Score: %.1f%%\n\n", coverageScore)

	summary += fmt.Sprintf("Identified %d documentation gaps:\n", len(gaps))

	severityCount := make(map[string]int)
	for _, gap := range gaps {
		severityCount[gap.Severity]++
	}

	for severity, count := range severityCount {
		summary += fmt.Sprintf("- %s: %d gaps\n", strings.Title(severity), count)
	}

	summary += fmt.Sprintf("\nGenerated %d actionable recommendations for improvement.\n", len(recommendations))

	if coverageScore < 50 {
		summary += "\n⚠️  WARNING: Documentation coverage is critically low. Immediate attention required."
	} else if coverageScore < 75 {
		summary += "\n⚡ Moderate documentation gaps identified. Consider addressing high-priority items."
	} else {
		summary += "\n✅ Good documentation coverage. Focus on maintaining and updating existing content."
	}

	return summary
}
