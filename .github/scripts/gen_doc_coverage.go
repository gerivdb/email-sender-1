package scripts

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// CoverageReport represents documentation coverage analysis
type CoverageReport struct {
	GeneratedAt        time.Time                 `json:"generated_at"`
	ProjectName        string                    `json:"project_name"`
	OverallCoverage    float64                   `json:"overall_coverage"`
	CoverageByCategory map[string]CoverageMetric `json:"coverage_by_category"`
	CoverageByType     map[string]CoverageMetric `json:"coverage_by_type"`
	ExpectedFiles      []ExpectedFile            `json:"expected_files"`
	ActualFiles        []ActualFile              `json:"actual_files"`
	MissingFiles       []MissingFile             `json:"missing_files"`
	Recommendations    []string                  `json:"recommendations"`
	Badges             []BadgeData               `json:"badges"`
	Trending           TrendingData              `json:"trending"`
	Summary            string                    `json:"summary"`
}

// CoverageMetric represents coverage metrics for a category/type
type CoverageMetric struct {
	Expected     int     `json:"expected"`
	Actual       int     `json:"actual"`
	Coverage     float64 `json:"coverage"`
	MissingCount int     `json:"missing_count"`
	ExtraCount   int     `json:"extra_count"`
	QualityScore float64 `json:"quality_score"`
}

// ExpectedFile represents a file that should exist
type ExpectedFile struct {
	Path         string   `json:"path"`
	Category     string   `json:"category"`
	Priority     string   `json:"priority"`
	Description  string   `json:"description"`
	Exists       bool     `json:"exists"`
	Alternatives []string `json:"alternatives,omitempty"`
}

// ActualFile represents a file that exists
type ActualFile struct {
	Path         string    `json:"path"`
	Category     string    `json:"category"`
	Size         int64     `json:"size"`
	LastModified time.Time `json:"last_modified"`
	QualityScore float64   `json:"quality_score"`
	HasTitle     bool      `json:"has_title"`
	HasContent   bool      `json:"has_content"`
}

// MissingFile represents a missing expected file
type MissingFile struct {
	Path       string `json:"path"`
	Category   string `json:"category"`
	Priority   string `json:"priority"`
	Impact     string `json:"impact"`
	Suggestion string `json:"suggestion"`
}

// BadgeData represents badge information
type BadgeData struct {
	Label   string `json:"label"`
	Message string `json:"message"`
	Color   string `json:"color"`
	URL     string `json:"url"`
	AltText string `json:"alt_text"`
}

// TrendingData represents trending information
type TrendingData struct {
	RecentChanges  int                `json:"recent_changes"`
	NewFiles       int                `json:"new_files"`
	UpdatedFiles   int                `json:"updated_files"`
	CoverageChange float64            `json:"coverage_change"`
	CategoryTrends map[string]float64 `json:"category_trends"`
}

func main() {
	projectRoot := "."
	if len(os.Args) > 1 {
		projectRoot = os.Args[1]
	}

	report, err := generateCoverageReport(projectRoot)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error generating coverage report: %v\n", err)
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

func generateCoverageReport(root string) (*CoverageReport, error) {
	projectName := filepath.Base(root)
	if projectName == "." || projectName == "/" {
		projectName = "project"
	}

	// Define expected files
	expectedFiles := defineExpectedFiles()

	// Find actual files
	actualFiles, err := findActualFiles(root)
	if err != nil {
		return nil, err
	}

	// Check which expected files exist
	checkExpectedFilesExistence(expectedFiles, actualFiles)

	// Calculate coverage metrics
	coverageByCategory := calculateCoverageByCategory(expectedFiles, actualFiles)
	coverageByType := calculateCoverageByType(actualFiles)
	overallCoverage := calculateOverallCoverage(expectedFiles)

	// Find missing files
	missingFiles := findMissingFiles(expectedFiles)

	// Generate badges
	badges := generateBadges(overallCoverage, len(missingFiles))

	// Generate trending data
	trending := generateTrendingData(actualFiles)

	// Generate recommendations
	recommendations := generateRecommendations(overallCoverage, missingFiles, coverageByCategory)

	report := &CoverageReport{
		GeneratedAt:        time.Now(),
		ProjectName:        projectName,
		OverallCoverage:    overallCoverage,
		CoverageByCategory: coverageByCategory,
		CoverageByType:     coverageByType,
		ExpectedFiles:      expectedFiles,
		ActualFiles:        actualFiles,
		MissingFiles:       missingFiles,
		Recommendations:    recommendations,
		Badges:             badges,
		Trending:           trending,
		Summary:            generateSummary(overallCoverage, len(actualFiles), len(missingFiles)),
	}

	return report, nil
}

func defineExpectedFiles() []ExpectedFile {
	return []ExpectedFile{
		{
			Path:         "README.md",
			Category:     "root",
			Priority:     "critical",
			Description:  "Main project overview and quick start guide",
			Alternatives: []string{"readme.txt", "README.rst"},
		},
		{
			Path:         "CHANGELOG.md",
			Category:     "root",
			Priority:     "high",
			Description:  "Version history and changes documentation",
			Alternatives: []string{"HISTORY.md", "CHANGES.md"},
		},
		{
			Path:         "LICENSE",
			Category:     "root",
			Priority:     "critical",
			Description:  "Software license information",
			Alternatives: []string{"LICENSE.md", "LICENSE.txt", "COPYING"},
		},
		{
			Path:         "CONTRIBUTING.md",
			Category:     "development",
			Priority:     "high",
			Description:  "Guidelines for project contributors",
			Alternatives: []string{".github/CONTRIBUTING.md"},
		},
		{
			Path:         "CODE_OF_CONDUCT.md",
			Category:     "development",
			Priority:     "medium",
			Description:  "Community behavior guidelines",
			Alternatives: []string{".github/CODE_OF_CONDUCT.md"},
		},
		{
			Path:         "SECURITY.md",
			Category:     "root",
			Priority:     "high",
			Description:  "Security policy and vulnerability reporting",
			Alternatives: []string{".github/SECURITY.md"},
		},
		{
			Path:        "docs/README.md",
			Category:    "documentation",
			Priority:    "medium",
			Description: "Documentation directory overview",
		},
		{
			Path:         "docs/installation.md",
			Category:     "documentation",
			Priority:     "high",
			Description:  "Installation and setup instructions",
			Alternatives: []string{"INSTALL.md", "docs/setup.md"},
		},
		{
			Path:         "docs/api.md",
			Category:     "api",
			Priority:     "high",
			Description:  "API documentation and reference",
			Alternatives: []string{"API.md", "docs/api/README.md"},
		},
		{
			Path:         "docs/architecture.md",
			Category:     "documentation",
			Priority:     "medium",
			Description:  "System architecture documentation",
			Alternatives: []string{"ARCHITECTURE.md", "docs/design.md"},
		},
		{
			Path:         "docs/development.md",
			Category:     "development",
			Priority:     "medium",
			Description:  "Development environment setup",
			Alternatives: []string{"DEVELOPMENT.md", "docs/dev-guide.md"},
		},
		{
			Path:         "docs/troubleshooting.md",
			Category:     "documentation",
			Priority:     "medium",
			Description:  "Common issues and solutions",
			Alternatives: []string{"TROUBLESHOOTING.md", "FAQ.md"},
		},
		{
			Path:         ".github/ISSUE_TEMPLATE.md",
			Category:     "github",
			Priority:     "medium",
			Description:  "GitHub issue template",
			Alternatives: []string{".github/ISSUE_TEMPLATE/"},
		},
		{
			Path:        ".github/PULL_REQUEST_TEMPLATE.md",
			Category:    "github",
			Priority:    "medium",
			Description: "GitHub pull request template",
		},
	}
}

func findActualFiles(root string) ([]ActualFile, error) {
	var files []ActualFile

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
		if !isDocumentationFile(relPath, info.Name()) {
			return nil
		}

		// Skip certain paths
		if shouldSkipPath(relPath) {
			return nil
		}

		// Analyze file quality
		qualityScore, hasTitle, hasContent := analyzeFileQuality(path)

		file := ActualFile{
			Path:         relPath,
			Category:     categorizeFile(relPath, info.Name()),
			Size:         info.Size(),
			LastModified: info.ModTime(),
			QualityScore: qualityScore,
			HasTitle:     hasTitle,
			HasContent:   hasContent,
		}

		files = append(files, file)
		return nil
	})

	return files, err
}

func analyzeFileQuality(filePath string) (float64, bool, bool) {
	file, err := os.Open(filePath)
	if err != nil {
		return 0.0, false, false
	}
	defer file.Close()

	// Read first 1KB to analyze structure
	buffer := make([]byte, 1024)
	n, err := file.Read(buffer)
	if err != nil {
		return 0.0, false, false
	}

	content := string(buffer[:n])
	lines := strings.Split(content, "\n")

	var hasTitle, hasContent bool
	var score float64 = 50.0 // Base score

	// Check for title
	for _, line := range lines[:min(5, len(lines))] {
		if strings.HasPrefix(strings.TrimSpace(line), "# ") {
			hasTitle = true
			score += 25.0
			break
		}
	}

	// Check for substantial content
	contentLines := 0
	for _, line := range lines {
		if len(strings.TrimSpace(line)) > 20 {
			contentLines++
		}
	}

	if contentLines >= 3 {
		hasContent = true
		score += 25.0
	}

	// Bonus for good structure
	if hasTitle && hasContent && len(lines) > 10 {
		score += 10.0
	}

	if score > 100.0 {
		score = 100.0
	}

	return score, hasTitle, hasContent
}

func checkExpectedFilesExistence(expectedFiles []ExpectedFile, actualFiles []ActualFile) {
	actualPaths := make(map[string]bool)
	for _, file := range actualFiles {
		actualPaths[strings.ToLower(file.Path)] = true
	}

	for i := range expectedFiles {
		expected := &expectedFiles[i]

		// Check main path
		if actualPaths[strings.ToLower(expected.Path)] {
			expected.Exists = true
			continue
		}

		// Check alternatives
		for _, alt := range expected.Alternatives {
			if actualPaths[strings.ToLower(alt)] {
				expected.Exists = true
				break
			}
		}
	}
}

func calculateCoverageByCategory(expectedFiles []ExpectedFile, actualFiles []ActualFile) map[string]CoverageMetric {
	categoryMetrics := make(map[string]CoverageMetric)

	// Count expected files by category
	expectedByCategory := make(map[string]int)
	existsByCategory := make(map[string]int)

	for _, expected := range expectedFiles {
		expectedByCategory[expected.Category]++
		if expected.Exists {
			existsByCategory[expected.Category]++
		}
	}

	// Count actual files by category
	actualByCategory := make(map[string]int)
	qualityByCategory := make(map[string][]float64)

	for _, actual := range actualFiles {
		actualByCategory[actual.Category]++
		qualityByCategory[actual.Category] = append(qualityByCategory[actual.Category], actual.QualityScore)
	}

	// Calculate metrics for each category
	for category, expected := range expectedByCategory {
		exists := existsByCategory[category]
		actual := actualByCategory[category]

		coverage := 0.0
		if expected > 0 {
			coverage = float64(exists) / float64(expected) * 100.0
		}

		// Calculate average quality score
		qualityScore := 0.0
		if len(qualityByCategory[category]) > 0 {
			sum := 0.0
			for _, score := range qualityByCategory[category] {
				sum += score
			}
			qualityScore = sum / float64(len(qualityByCategory[category]))
		}

		categoryMetrics[category] = CoverageMetric{
			Expected:     expected,
			Actual:       actual,
			Coverage:     coverage,
			MissingCount: expected - exists,
			ExtraCount:   actual - exists,
			QualityScore: qualityScore,
		}
	}

	return categoryMetrics
}

func calculateCoverageByType(actualFiles []ActualFile) map[string]CoverageMetric {
	typeMetrics := make(map[string]CoverageMetric)

	typeCount := make(map[string]int)
	qualityByType := make(map[string][]float64)

	for _, file := range actualFiles {
		fileType := getFileType(filepath.Ext(file.Path))
		typeCount[fileType]++
		qualityByType[fileType] = append(qualityByType[fileType], file.QualityScore)
	}

	for fileType, count := range typeCount {
		qualityScore := 0.0
		if len(qualityByType[fileType]) > 0 {
			sum := 0.0
			for _, score := range qualityByType[fileType] {
				sum += score
			}
			qualityScore = sum / float64(len(qualityByType[fileType]))
		}

		typeMetrics[fileType] = CoverageMetric{
			Actual:       count,
			QualityScore: qualityScore,
		}
	}

	return typeMetrics
}

func calculateOverallCoverage(expectedFiles []ExpectedFile) float64 {
	if len(expectedFiles) == 0 {
		return 0.0
	}

	existsCount := 0
	weightedScore := 0.0
	totalWeight := 0.0

	for _, expected := range expectedFiles {
		weight := 1.0
		switch expected.Priority {
		case "critical":
			weight = 3.0
		case "high":
			weight = 2.0
		case "medium":
			weight = 1.0
		default:
			weight = 0.5
		}

		totalWeight += weight
		if expected.Exists {
			existsCount++
			weightedScore += weight
		}
	}

	if totalWeight == 0 {
		return 0.0
	}

	return (weightedScore / totalWeight) * 100.0
}

func findMissingFiles(expectedFiles []ExpectedFile) []MissingFile {
	var missing []MissingFile

	for _, expected := range expectedFiles {
		if !expected.Exists {
			impact := "Low"
			switch expected.Priority {
			case "critical":
				impact = "High - Critical for project usability"
			case "high":
				impact = "Medium - Important for project quality"
			case "medium":
				impact = "Low - Recommended for completeness"
			}

			suggestion := fmt.Sprintf("Create %s with %s", expected.Path, expected.Description)
			if len(expected.Alternatives) > 0 {
				suggestion += fmt.Sprintf(" or use alternatives: %s", strings.Join(expected.Alternatives, ", "))
			}

			missing = append(missing, MissingFile{
				Path:       expected.Path,
				Category:   expected.Category,
				Priority:   expected.Priority,
				Impact:     impact,
				Suggestion: suggestion,
			})
		}
	}

	return missing
}

func generateBadges(coverage float64, missingCount int) []BadgeData {
	var badges []BadgeData

	// Coverage badge
	color := "red"
	if coverage >= 80 {
		color = "brightgreen"
	} else if coverage >= 60 {
		color = "yellow"
	} else if coverage >= 40 {
		color = "orange"
	}

	badges = append(badges, BadgeData{
		Label:   "docs-coverage",
		Message: fmt.Sprintf("%.1f%%", coverage),
		Color:   color,
		URL:     fmt.Sprintf("https://img.shields.io/badge/docs--coverage-%.1f%%25-%s", coverage, color),
		AltText: fmt.Sprintf("Documentation Coverage: %.1f%%", coverage),
	})

	// Missing files badge
	missingColor := "brightgreen"
	if missingCount > 5 {
		missingColor = "red"
	} else if missingCount > 2 {
		missingColor = "yellow"
	}

	badges = append(badges, BadgeData{
		Label:   "docs-missing",
		Message: fmt.Sprintf("%d files", missingCount),
		Color:   missingColor,
		URL:     fmt.Sprintf("https://img.shields.io/badge/docs--missing-%d%%20files-%s", missingCount, missingColor),
		AltText: fmt.Sprintf("Missing Documentation Files: %d", missingCount),
	})

	return badges
}

func generateTrendingData(actualFiles []ActualFile) TrendingData {
	now := time.Now()
	recentThreshold := now.AddDate(0, 0, -7) // Last 7 days

	var recentChanges, newFiles, updatedFiles int
	categoryTrends := make(map[string]float64)
	categoryCounts := make(map[string]int)

	for _, file := range actualFiles {
		categoryCounts[file.Category]++

		if file.LastModified.After(recentThreshold) {
			recentChanges++

			// Simple heuristic for new vs updated
			if file.Size < 1000 || time.Since(file.LastModified) < 24*time.Hour {
				newFiles++
			} else {
				updatedFiles++
			}
		}
	}

	// Calculate category trends (simplified)
	for category, count := range categoryCounts {
		categoryTrends[category] = float64(count) // Placeholder for trend calculation
	}

	return TrendingData{
		RecentChanges:  recentChanges,
		NewFiles:       newFiles,
		UpdatedFiles:   updatedFiles,
		CoverageChange: 0.0, // Would need historical data
		CategoryTrends: categoryTrends,
	}
}

func generateRecommendations(coverage float64, missingFiles []MissingFile, categoryMetrics map[string]CoverageMetric) []string {
	var recommendations []string

	if coverage < 50 {
		recommendations = append(recommendations, "📈 Priority: Improve overall documentation coverage (currently below 50%)")
	}

	// Critical missing files
	criticalMissing := 0
	for _, missing := range missingFiles {
		if missing.Priority == "critical" {
			criticalMissing++
		}
	}

	if criticalMissing > 0 {
		recommendations = append(recommendations, fmt.Sprintf("🚨 Urgent: Create %d critical documentation files", criticalMissing))
	}

	// Category-specific recommendations
	for category, metric := range categoryMetrics {
		if metric.Coverage < 60 && metric.Expected > 0 {
			recommendations = append(recommendations, fmt.Sprintf("📝 Focus on %s documentation (%.1f%% coverage)", category, metric.Coverage))
		}
	}

	// Quality recommendations
	lowQualityCategories := 0
	for _, metric := range categoryMetrics {
		if metric.QualityScore < 60 && metric.Actual > 0 {
			lowQualityCategories++
		}
	}

	if lowQualityCategories > 0 {
		recommendations = append(recommendations, "✨ Improve documentation quality by adding titles and detailed content")
	}

	if len(recommendations) == 0 {
		recommendations = append(recommendations, "✅ Documentation coverage looks good! Consider adding more detailed content.")
	}

	return recommendations
}

func generateSummary(coverage float64, totalFiles, missingFiles int) string {
	status := "needs improvement"
	if coverage >= 80 {
		status = "excellent"
	} else if coverage >= 60 {
		status = "good"
	} else if coverage >= 40 {
		status = "fair"
	}

	return fmt.Sprintf("Documentation coverage: %.1f%% (%s) - %d files documented, %d files missing",
		coverage, status, totalFiles, missingFiles)
}

// Helper functions (reused from previous scripts)
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

func categorizeFile(path, name string) string {
	pathLower := strings.ToLower(path)
	nameLower := strings.ToLower(name)

	if !strings.Contains(path, "/") && !strings.Contains(path, "\\") {
		return "root"
	}

	if strings.HasPrefix(pathLower, ".github/") || strings.Contains(pathLower, "/.github/") {
		return "github"
	}

	if strings.HasPrefix(pathLower, "docs/") || strings.Contains(pathLower, "/docs/") {
		return "documentation"
	}

	if strings.HasPrefix(pathLower, "development/") || strings.Contains(pathLower, "/development/") {
		return "development"
	}

	if strings.HasPrefix(pathLower, "projet/") || strings.Contains(pathLower, "/projet/") ||
		strings.HasPrefix(pathLower, "planning/") || strings.Contains(pathLower, "/planning/") {
		return "project-management"
	}

	if strings.Contains(nameLower, "api") || strings.Contains(pathLower, "/api/") || strings.HasPrefix(pathLower, "api/") {
		if strings.Contains(pathLower, "/docs/") || strings.HasPrefix(pathLower, "docs/") {
			return "documentation"
		}
		return "api"
	}

	if strings.Contains(pathLower, "/test") || strings.Contains(nameLower, "test") ||
		strings.HasPrefix(pathLower, "test") {
		return "testing"
	}

	if strings.Contains(nameLower, "config") || strings.Contains(nameLower, "setup") {
		return "configuration"
	}

	return "general"
}

func getFileType(ext string) string {
	switch strings.ToLower(ext) {
	case ".md":
		return "markdown"
	case ".txt":
		return "text"
	case ".rst":
		return "restructuredtext"
	case ".adoc":
		return "asciidoc"
	case ".org":
		return "org-mode"
	default:
		return "other"
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
