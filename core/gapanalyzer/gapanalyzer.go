package gapanalyzer

import (
	"fmt"
	"strings"
	"time"

	sm "github.com/gerivdb/email-sender-1/core/scanmodules" // Import scanmodules
)

// RepositoryStructure représente la structure complète du repo (importé du scanner)
type RepositoryStructure = sm.RepositoryStructure

// ModuleInfo représente l'information d'un module (importé du scanner)
type ModuleInfo = sm.ModuleInfo

// ExpectedModule représente un module attendu
type ExpectedModule struct {
	Name        string `json:"name"`
	Path        string `json:"path"`
	Required    bool   `json:"required"`
	Category    string `json:"category"`
	Description string `json:"description"`
}

// GapAnalysis représente le résultat de l'analyse d'écart
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

type Analyzer struct{}

func NewAnalyzer() *Analyzer {
	return &Analyzer{}
}

func (a *Analyzer) GetExpectedModules() []ExpectedModule {
	return []ExpectedModule{
		// core modules
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

func (a *Analyzer) AnalyzeGaps(repoStructure sm.RepositoryStructure, expectedModules []ExpectedModule) GapAnalysis {
	analysis := GapAnalysis{
		AnalysisDate:    time.Now(),
		TotalExpected:   len(expectedModules),
		TotalFound:      len(repoStructure.Modules),
		MissingModules:  []ExpectedModule{},
		ExtraModules:    []sm.ModuleInfo{},
		MatchingModules: []sm.ModuleInfo{},
		Recommendations: []string{},
	}

	// Préparation
	foundModulesMap := make(map[string]sm.ModuleInfo)
	for _, module := range repoStructure.Modules {
		normalizedName := strings.ReplaceAll(module.Name, "\\", "/")
		foundModulesMap[normalizedName] = module
	}

	expectedModulesMap := make(map[string]ExpectedModule)
	for _, expected := range expectedModules {
		expectedModulesMap[expected.Name] = expected
	}

	// Modules manquants
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

	// Modules correspondants et extra
	for _, found := range repoStructure.Modules {
		normalizedName := strings.ReplaceAll(found.Name, "\\", "/")
		if _, expected := expectedModulesMap[normalizedName]; expected {
			analysis.MatchingModules = append(analysis.MatchingModules, found)
		} else {
			if !a.IsLegitimateExtraModule(normalizedName) {
				analysis.ExtraModules = append(analysis.ExtraModules, found)
				analysis.Recommendations = append(analysis.Recommendations,
					fmt.Sprintf("REVIEW: Unexpected module found '%s' - check if it is necessary", normalizedName))
			}
		}
	}

	// Calcul taux de conformité
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

	// Résumé
	analysis.Summary = fmt.Sprintf(
		"Gap analysis completed: %d/%d required modules found (%.1f%% compliance). "+
			"%d missing modules, %d extra modules, %d matching modules.",
		foundRequiredModules, requiredModules, analysis.ComplianceRate,
		len(analysis.MissingModules), len(analysis.ExtraModules), len(analysis.MatchingModules))

	// General Recommendations
	switch {
	case analysis.ComplianceRate < 80:
		analysis.Recommendations = append(analysis.Recommendations,
			"HIGH PRIORITY: Low compliance rate - implement the missing critical modules")
	case analysis.ComplianceRate < 100:
		analysis.Recommendations = append(analysis.Recommendations,
			"MEDIUM PRIORITY: Complete the missing modules for full compliance")
	default:
		analysis.Recommendations = append(analysis.Recommendations,
			"EXCELLENT: All required modules are present")
	}
	return analysis
}

// Vérifie si un module "extra" est légitime
func (a *Analyzer) IsLegitimateExtraModule(moduleName string) bool {
	legitimatePatterns := []string{
		"github.com/",                           // Modules externes
		"golang.org/",                           // Modules standards
		"go.uber.org/",                          // Tiers
		"development/managers/gateway-manager/", // MCP sous-modules légitimes
	}
	for _, pattern := range legitimatePatterns {
		if strings.HasPrefix(moduleName, pattern) {
			return true
		}
	}
	return false
}

// Génère un rapport Markdown
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
	for _, recommendation := range analysis.Recommendations {
		report.WriteString(fmt.Sprintf("1. %s\n", recommendation))
	}

	return report.String()
}
