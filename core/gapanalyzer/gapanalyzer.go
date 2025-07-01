package gapanalyzer

import (
	"fmt"
	"strings"
	"time"
)

// ModuleInfo représente les informations d'un module (importé du scanner)
type ModuleInfo struct {
	Name         string    `json:"name"`
	Path         string    `json:"path"`
	Description  string    `json:"description"`
	LastModified time.Time `json:"last_modified"`
}

// RepositoryStructure représente la structure complète du dépôt (importé du scanner)
type RepositoryStructure struct {
	TreeOutput   string       `json:"tree_output"`
	Modules      []ModuleInfo `json:"modules"`
	TotalModules int          `json:"total_modules"`
	GeneratedAt  time.Time    `json:"generated_at"`
	RootPath     string       `json:"root_path"`
}

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

// GetExpectedModules retourne la liste des modules attendus selon l'architecture du projet
func GetExpectedModules() []ExpectedModule {
	return []ExpectedModule{
		// Modules core
		{
			Name:        "core/scanmodules",
			Path:        "core/scanmodules",
			Required:    true,
			Category:    "core",
			Description: "Scanner de modules et structure du dépôt",
		},
		{
			Name:        "core/gapanalyzer",
			Path:        "core/gapanalyzer",
			Required:    true,
			Category:    "core",
			Description: "Analyseur d'écarts entre modules attendus et existants",
		},
		{
			Name:        "core/reporting",
			Path:        "core/reporting",
			Required:    true,
			Category:    "core",
			Description: "Générateur de rapports automatisés",
		},

		// Modules cmd
		{
			Name:        "cmd/auto-roadmap-runner",
			Path:        "cmd/auto-roadmap-runner",
			Required:    true,
			Category:    "cmd",
			Description: "Orchestrateur global de la roadmap",
		},
		{
			Name:        "cmd/configcli",
			Path:        "cmd/configcli",
			Required:    false,
			Category:    "cmd",
			Description: "Interface en ligne de commande pour la configuration",
		},
		{
			Name:        "cmd/configapi",
			Path:        "cmd/configapi",
			Required:    false,
			Category:    "cmd",
			Description: "API de configuration",
		},

		// Modules tests
		{
			Name:        "tests/validation",
			Path:        "tests/validation",
			Required:    true,
			Category:    "tests",
			Description: "Tests de validation globaux",
		},
		{
			Name:        "tests/test_runners",
			Path:        "tests/test_runners",
			Required:    false,
			Category:    "tests",
			Description: "Runners de tests spécialisés",
		},

		// Modules MCP Gateway (existants)
		{
			Name:        "projet/mcp/servers/gateway",
			Path:        "projet/mcp/servers/gateway",
			Required:    false,
			Category:    "mcp",
			Description: "Serveur de passerelle MCP",
		},
	}
}

// AnalyzeGaps effectue l'analyse d'écart entre modules attendus et trouvés
func AnalyzeGaps(repoStructure RepositoryStructure, expectedModules []ExpectedModule) GapAnalysis {
	analysis := GapAnalysis{
		AnalysisDate:    time.Now(),
		TotalExpected:   len(expectedModules),
		TotalFound:      len(repoStructure.Modules),
		MissingModules:  []ExpectedModule{},
		ExtraModules:    []ModuleInfo{},
		MatchingModules: []ModuleInfo{},
		Recommendations: []string{},
	}

	// Créer des maps pour faciliter la comparaison
	foundModulesMap := make(map[string]ModuleInfo)
	for _, module := range repoStructure.Modules {
		// Normaliser le nom du module pour la comparaison
		normalizedName := strings.ReplaceAll(module.Name, "\\", "/")
		foundModulesMap[normalizedName] = module
	}

	expectedModulesMap := make(map[string]ExpectedModule)
	for _, expected := range expectedModules {
		expectedModulesMap[expected.Name] = expected
	}

	// Identifier les modules manquants
	for _, expected := range expectedModules {
		if _, found := foundModulesMap[expected.Name]; !found {
			analysis.MissingModules = append(analysis.MissingModules, expected)
			if expected.Required {
				analysis.Recommendations = append(analysis.Recommendations,
					fmt.Sprintf("CRITIQUE: Créer le module requis '%s' (%s)", expected.Name, expected.Description))
			} else {
				analysis.Recommendations = append(analysis.Recommendations,
					fmt.Sprintf("OPTIONNEL: Considérer la création du module '%s' (%s)", expected.Name, expected.Description))
			}
		}
	}

	// Identifier les modules correspondants et supplémentaires
	for _, found := range repoStructure.Modules {
		normalizedName := strings.ReplaceAll(found.Name, "\\", "/")
		if _, expected := expectedModulesMap[normalizedName]; expected {
			analysis.MatchingModules = append(analysis.MatchingModules, found)
		} else {
			// Vérifier si c'est un module "extra" légitime ou non
			if !IsLegitimateExtraModule(normalizedName) {
				analysis.ExtraModules = append(analysis.ExtraModules, found)
				analysis.Recommendations = append(analysis.Recommendations,
					fmt.Sprintf("RÉVISION: Module non-attendu trouvé '%s' - vérifier s'il est nécessaire", normalizedName))
			}
		}
	}

	// Calculer le taux de conformité
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

	// Générer le résumé
	analysis.Summary = fmt.Sprintf(
		"Analyse d'écart terminée: %d/%d modules requis trouvés (%.1f%% de conformité). "+
			"%d modules manquants, %d modules supplémentaires, %d modules correspondants.",
		foundRequiredModules, requiredModules, analysis.ComplianceRate,
		len(analysis.MissingModules), len(analysis.ExtraModules), len(analysis.MatchingModules))

	// Ajouter des recommandations générales
	if analysis.ComplianceRate < 80 {
		analysis.Recommendations = append(analysis.Recommendations,
			"PRIORITÉ HAUTE: Taux de conformité faible - implémenter les modules critiques manquants")
	} else if analysis.ComplianceRate < 100 {
		analysis.Recommendations = append(analysis.Recommendations,
			"PRIORITÉ MOYENNE: Compléter les modules manquants pour une conformité complète")
	} else {
		analysis.Recommendations = append(analysis.Recommendations,
			"EXCELLENT: Tous les modules requis sont présents")
	}

	return analysis
}

// IsLegitimateExtraModule vérifie si un module "extra" est légitime
func IsLegitimateExtraModule(moduleName string) bool {
	legitimatePatterns := []string{
		"github.com/",                 // Modules externes
		"golang.org/",                 // Modules standard
		"go.uber.org/",                // Modules tiers légitimes
		"projet/mcp/servers/gateway/", // Sous-modules MCP légitimes
	}

	for _, pattern := range legitimatePatterns {
		if strings.HasPrefix(moduleName, pattern) {
			return true
		}
	}
	return false
}

// GenerateMarkdownReport génère un rapport Markdown
func GenerateMarkdownReport(analysis GapAnalysis) string {
	var report strings.Builder

	report.WriteString("# 📊 Analyse d'Écart des Modules\n\n")
	report.WriteString(fmt.Sprintf("**Date d'analyse:** %s\n\n", analysis.AnalysisDate.Format("2006-01-02 15:04:05")))
	report.WriteString(fmt.Sprintf("**Résumé:** %s\n\n", analysis.Summary))

	// Métriques
	report.WriteString("## 📈 Métriques\n\n")
	report.WriteString(fmt.Sprintf("- **Modules attendus:** %d\n", analysis.TotalExpected))
	report.WriteString(fmt.Sprintf("- **Modules trouvés:** %d\n", analysis.TotalFound))
	report.WriteString(fmt.Sprintf("- **Taux de conformité:** %.1f%%\n", analysis.ComplianceRate))
	report.WriteString(fmt.Sprintf("- **Modules manquants:** %d\n", len(analysis.MissingModules)))
	report.WriteString(fmt.Sprintf("- **Modules supplémentaires:** %d\n", len(analysis.ExtraModules)))
	report.WriteString(fmt.Sprintf("- **Modules correspondants:** %d\n\n", len(analysis.MatchingModules)))

	// Modules manquants
	if len(analysis.MissingModules) > 0 {
		report.WriteString("## ❌ Modules Manquants\n\n")
		for _, missing := range analysis.MissingModules {
			status := "OPTIONNEL"
			if missing.Required {
				status = "**REQUIS**"
			}
			report.WriteString(fmt.Sprintf("- %s `%s` (%s)\n  - **Catégorie:** %s\n  - **Description:** %s\n\n",
				status, missing.Name, missing.Path, missing.Category, missing.Description))
		}
	}

	// Modules correspondants
	if len(analysis.MatchingModules) > 0 {
		report.WriteString("## ✅ Modules Correspondants\n\n")
		for _, matching := range analysis.MatchingModules {
			report.WriteString(fmt.Sprintf("- `%s`\n", matching.Name))
		}
		report.WriteString("\n")
	}

	// Modules supplémentaires
	if len(analysis.ExtraModules) > 0 {
		report.WriteString("## ⚠️ Modules Supplémentaires\n\n")
		for _, extra := range analysis.ExtraModules {
			report.WriteString(fmt.Sprintf("- `%s` - %s\n", extra.Name, extra.Description))
		}
		report.WriteString("\n")
	}

	// Recommandations
	report.WriteString("## 🎯 Recommandations\n\n")
	for i, recommendation := range analysis.Recommendations {
		report.WriteString(fmt.Sprintf("%d. %s\n", i+1, recommendation))
	}

	return report.String()
}

// main function is removed from here and will be in core/gapanalyzer/main.go
