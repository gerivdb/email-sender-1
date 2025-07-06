package gapanalyzer

import (
	"fmt"
	"strings"
	"time"
	"os"
)

// ModuleInfo represents the information of a module (imported from the scanner)
type ModuleInfo struct {
	Name         string    `json:"name"`
	Path         string    `json:"path"`
	Description  string    `json:"description"`
	LastModified time.Time `json:"last_modified"`
}

// RepositoryStructure represents the complete repository structure (imported from the scanner)
type RepositoryStructure struct {
	TreeOutput   string       `json:"tree_output"`
	Modules      []ModuleInfo `json:"modules"`
	TotalModules int          `json:"total_modules"`
	GeneratedAt  time.Time    `json:"generated_at"`
	RootPath     string       `json:"root_path"`
}

// ExpectedModule represents an expected module
type ExpectedModule struct {
	Name        string `json:"name"`
	Path        string `json:"path"`
	Required    bool   `json:"required"`
	Category    string `json:"category"`
	Description string `json:"description"`
}

// GapAnalysis represents the result of the gap analysis
type GapAnalysis struct {
	AnalysisDate    time.Time        `json:"analysis_date"`
	TotalExpected   int              `json:"total_expected"`
	TotalFound      int              `json:"total_found"`
	MissingModules  []ExpectedModule `json:"missing_modules"`
	ExtraModules    []ModuleInfo     `json:"extra_modules"`
	MatchingModules []ModuleInfo     `json:"matching_modules"`
	ComplianceRate  float64          `json:"compliance_rate"`
	Recommendations []string         `json:"recommendations"`
	Summary         string           `json:"summary"`
}

// Analyzer is the implementation of the GapAnalyzer interface.
type Analyzer struct{}

// NewAnalyzer creates a new Analyzer.
func NewAnalyzer() *Analyzer {
	return &Analyzer{}
}

// GetExpectedModules returns the list of expected modules according to the project architecture
func (a *Analyzer) GetExpectedModules() []ExpectedModule {
	return []ExpectedModule{
		// Core modules
		{
			Name:        "core/scanmodules",
			Path:        "core/scanmodules",
			Required:    true,
			Category:    "core",
			Description: "Module and repository structure scanner",
		},
		{
			Name:        "core/gapanalyzer",
			Path:        "core/gapanalyzer",
			Required:    true,
			Category:    "core",
			Description: "Gap analyzer between expected and existing modules",
		},
		{
			Name:        "core/reporting",
			Path:        "core/reporting",
			Required:    true,
			Category:    "core",
			Description: "Automated report generator",
		},

		// cmd modules
		{
			Name:        "cmd/auto-roadmap-runner",
			Path:        "cmd/auto-roadmap-runner",
			Required:    true,
			Category:    "cmd",
			Description: "Global roadmap orchestrator",
		},
		{
			Name:        "cmd/configcli",
			Path:        "cmd/configcli",
			Required:    false,
			Category:    "cmd",
			Description: "Command line interface for configuration",
		},
		{
			Name:        "cmd/configapi",
			Path:        "cmd/configapi",
			Required:    false,
			Category:    "cmd",
			Description: "Configuration API",
		},

		// tests modules
		{
			Name:        "tests/validation",
			Path:        "tests/validation",
			Required:    true,
			Category:    "tests",
			Description: "Global validation tests",
		},
		{
			Name:        "tests/test_runners",
			Path:        "tests/test_runners",
			Required:    false,
			Category:    "tests",
			Description: "Specialized test runners",
		},

		// MCP Gateway modules (existing)
		{
			Name:        "development/managers/gateway-manager",
			Path:        "development/managers/gateway-manager",
			Required:    false,
			Category:    "mcp",
			Description: "MCP gateway server",
		},
	}
}

// AnalyzeGaps performs the gap analysis between expected and found modules
func (a *Analyzer) AnalyzeGaps(repoStructure RepositoryStructure, expectedModules []ExpectedModule) GapAnalysis {
	analysis := GapAnalysis{
		AnalysisDate:    time.Now(),
		TotalExpected:   len(expectedModules),
		TotalFound:      len(repoStructure.Modules),
		MissingModules:  []ExpectedModule{},
		ExtraModules:    []ModuleInfo{},
		MatchingModules: []ModuleInfo{},
		Recommendations: []string{},
	}

	// Create maps for easier comparison
	foundModulesMap := make(map[string]ModuleInfo)
	for _, module := range repoStructure.Modules {
		// Normalize module name for comparison
		normalizedName := strings.ReplaceAll(module.Name, "\\", "/")
		foundModulesMap[normalizedName] = module
	}

	expectedModulesMap := make(map[string]ExpectedModule)
	for _, expected := range expectedModules {
		expectedModulesMap[expected.Name] = expected
	}

	// Identify missing modules
	for _, expected := range expectedModules {
		if _, found := foundModulesMap[expected.Name]; !found {
			analysis.MissingModules = append(analysis.MissingModules, expected)
			if expected.Required {
				analysis.Recommendations = append(analysis.Recommendations,
					fmt.Sprintf("CRITICAL: Create the required module '%s' (%s)", expected.Name, expected.Description))
			} else {
				analysis.Recommendations = append(analysis.Recommendations,
					fmt.Sprintf("OPTIONAL: Consider creating the module '%s' (%s)", expected.Name, expected.Description))
			}
		}
	}

	// Identify matching and extra modules
	for _, found := range repoStructure.Modules {
		normalizedName := strings.ReplaceAll(found.Name, "\\", "/")
		if _, expected := expectedModulesMap[normalizedName]; expected {
			analysis.MatchingModules = append(analysis.MatchingModules, found)
		} else {
			// Check if it's a legitimate extra module or not
			if !a.IsLegitimateExtraModule(normalizedName) {
				analysis.ExtraModules = append(analysis.ExtraModules, found)
				analysis.Recommendations = append(analysis.Recommendations,
					fmt.Sprintf("REVIEW: Unexpected module found '%s' - check if it is necessary", normalizedName))
			}
		}
	}

	// Calculate compliance rate
	requiredModules := 0
	foundRequiredModules := 0
	for _, expected := range expectedModules {
		if expected.Required {
			requiredModules++
			if _, found := foundModulesMap[expected.Name]; found {
				foundRequiredModules++
			}
		}
	}

	if requiredModules > 0 {
		analysis.ComplianceRate = float64(foundRequiredModules) / float64(requiredModules) * 100
	} else {
		analysis.ComplianceRate = 100.0
	}

	// Generate summary
	analysis.Summary = fmt.Sprintf(
		"Gap analysis completed: %d/%d required modules found (%.1f%% compliance). "+
			"%d missing modules, %d extra modules, %d matching modules.",
		foundRequiredModules, requiredModules, analysis.ComplianceRate,
		len(analysis.MissingModules), len(analysis.ExtraModules), len(analysis.MatchingModules))

	// Add general recommendations
	if analysis.ComplianceRate < 80 {
		analysis.Recommendations = append(analysis.Recommendations,
			"HIGH PRIORITY: Low compliance rate - implement the missing critical modules")
	} else if analysis.ComplianceRate < 100 {
		analysis.Recommendations = append(analysis.Recommendations,
			"MEDIUM PRIORITY: Complete the missing modules for full compliance")
	} else {
		analysis.Recommendations = append(analysis.Recommendations,
			"EXCELLENT: All required modules are present")
	}

	return analysis
}

// IsLegitimateExtraModule checks if an "extra" module is legitimate
func (a *Analyzer) IsLegitimateExtraModule(moduleName string) bool {
	legitimatePatterns := []string{
		"github.com/",                 // External modules
		"golang.org/",                 // Standard modules
		"go.uber.org/",                // Legitimate third-party modules
		"development/managers/gateway-manager/", // Legitimate MCP sub-modules
	}

	for _, pattern := range legitimatePatterns {
		if strings.HasPrefix(moduleName, pattern) {
			return true
		}
	}
	return false
}

// GenerateMarkdownReport generates a Markdown report
func (a *Analyzer) GenerateMarkdownReport(analysis GapAnalysis) string {
	var report strings.Builder

	report.WriteString("# 📊 Module Gap Analysis\n\n")
	report.WriteString(fmt.Sprintf("**Analysis date:** %s\n\n", analysis.AnalysisDate.Format("2006-01-02 15:04:05")))
	report.WriteString(fmt.Sprintf("**Summary:** %s\n\n", analysis.Summary))

	// Metrics
	report.WriteString("## 📈 Metrics\n\n")
	report.WriteString(fmt.Sprintf("- **Expected modules:** %d\n", analysis.TotalExpected))
	report.WriteString(fmt.Sprintf("- **Found modules:** %d\n", analysis.TotalFound))
	report.WriteString(fmt.Sprintf("- **Compliance rate:** %.1f%%\n", analysis.ComplianceRate))
	report.WriteString(fmt.Sprintf("- **Missing modules:** %d\n", len(analysis.MissingModules)))
	report.WriteString(fmt.Sprintf("- **Extra modules:** %d\n", len(analysis.ExtraModules)))
	report.WriteString(fmt.Sprintf("- **Matching modules:** %d\n\n", len(analysis.MatchingModules)))

	// Missing modules
	if len(analysis.MissingModules) > 0 {
		report.WriteString("## ❌ Missing Modules\n\n")
		for _, missing := range analysis.MissingModules {
			status := "OPTIONAL"
			if missing.Required {
				status = "**REQUIRED**"
			}
			report.WriteString(fmt.Sprintf("- %s `%s` (%s)\n  - **Category:** %s\n  - **Description:** %s\n\n",
				status, missing.Name, missing.Path, missing.Category, missing.Description))
		}
	}

	// Matching modules
	if len(analysis.MatchingModules) > 0 {
		report.WriteString("## ✅ Matching Modules\n\n")
		for _, matching := range analysis.MatchingModules {
			report.WriteString(fmt.Sprintf("- `%s`\n", matching.Name))
		}
		report.WriteString("\n")
	}

	// Extra modules
	if len(analysis.ExtraModules) > 0 {
		report.WriteString("## ⚠️ Extra Modules\n\n")
		for _, extra := range analysis.ExtraModules {
			report.WriteString(fmt.Sprintf("- `%s` - %s\n", extra.Name, extra.Description))
		}
		report.WriteString("\n")
	}

	// Recommendations
	report.WriteString("## 🎯 Recommendations\n\n")
	for i, recommendation := range analysis.Recommendations {
		report.WriteString(fmt.Sprintf("%d. %s\n", i+1, recommendation))
	}

	return report.String()
}

// AnalyzeExtractionParsingGap analyzes the gaps for extraction and parsing
func (a *Analyzer) AnalyzeExtractionParsingGap(extractedData map[string]interface{}) (map[string]interface{}, error) {
	// Simulate a gap analysis based on the extracted data
	analysisResult := make(map[string]interface{})
	analysisResult["analysis_date"] = time.Now()

	if status, ok := extractedData["status"]; ok && status == "failed" {
		analysisResult["gap_found"] = true
		analysisResult["details"] = "Extraction failed, so a major gap exists."
		analysisResult["error"] = extractedData["error"]
	} else {
		// Simulate a check for data completeness
		if _, ok := extractedData["content"]; !ok || extractedData["content"] == "" {
			analysisResult["gap_found"] = true
			analysisResult["details"] = "Extracted content is empty or missing."
		} else {
			analysisResult["gap_found"] = false
			analysisResult["details"] = "Extracted data seems complete."
		}
	}

	return analysisResult, nil
}

// GenerateExtractionParsingGapAnalysis generates the gap analysis report
func (a *Analyzer) GenerateExtractionParsingGapAnalysis(filePath string, analysisResult map[string]interface{}) error {
	var report strings.Builder

	report.WriteString("# Gap Analysis - Extraction and Parsing\n\n")
	report.WriteString(fmt.Sprintf("**Analysis date:** %s\n\n", analysisResult["analysis_date"]))

	if gapFound, ok := analysisResult["gap_found"].(bool); ok && gapFound {
		report.WriteString("## ❌ Gap Detected\n\n")
		report.WriteString(fmt.Sprintf("**Details:** %s\n", analysisResult["details"]))
		if err, ok := analysisResult["error"]; ok {
			report.WriteString(fmt.Sprintf("**Error:** %v\n", err))
		}
	} else {
		report.WriteString("## ✅ No Gap Detected\n\n")
		report.WriteString(fmt.Sprintf("**Details:** %s\n", analysisResult["details"]))
	}

	return os.WriteFile(filePath, []byte(report.String()), 0644)
}