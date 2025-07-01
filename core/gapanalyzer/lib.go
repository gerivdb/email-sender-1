package gapanalyzer

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"time"
)

// ModuleInfo représente les informations d'un module Go
type ModuleInfo struct {
	Name        string `json:"name"`
	Path        string `json:"path"`
	Description string `json:"description,omitempty"`
}

// RepositoryStructure représente la structure du dépôt
type RepositoryStructure struct {
	Modules      []ModuleInfo `json:"modules"`
	TotalModules int          `json:"total_modules"`
	GeneratedAt  time.Time    `json:"generated_at"`
	RootPath     string       `json:"root_path"`
}

// ExpectedModule représente un module attendu dans l'architecture
type ExpectedModule struct {
	Name        string `json:"name"`
	Path        string `json:"path"`
	Required    bool   `json:"required"`
	Description string `json:"description"`
	Category    string `json:"category"`
}

// GapAnalysis représente le résultat de l'analyse d'écart
type GapAnalysis struct {
	AnalysisDate    time.Time        `json:"analysis_date"`
	Summary         string           `json:"summary"`
	TotalExpected   int              `json:"total_expected"`
	TotalFound      int              `json:"total_found"`
	ComplianceRate  float64          `json:"compliance_rate"`
	MissingModules  []ExpectedModule `json:"missing_modules"`
	ExtraModules    []ModuleInfo     `json:"extra_modules"`
	MatchingModules []ModuleInfo     `json:"matching_modules"`
	Recommendations []string         `json:"recommendations"`
}

// GetExpectedModules retourne la liste des modules attendus
func GetExpectedModules() []ExpectedModule {
	return []ExpectedModule{
		{Name: "core/scanmodules", Path: "core/scanmodules", Required: true, Description: "Scanner de modules et structure", Category: "core"},
		{Name: "core/gapanalyzer", Path: "core/gapanalyzer", Required: true, Description: "Analyseur d'écarts", Category: "core"},
		{Name: "core/reporting", Path: "core/reporting", Required: true, Description: "Générateur de rapports", Category: "core"},
		{Name: "cmd/auto-roadmap-runner", Path: "cmd/auto-roadmap-runner", Required: true, Description: "Orchestrateur global", Category: "cmd"},
		{Name: "tests/validation", Path: "tests/validation", Required: false, Description: "Tests de validation", Category: "tests"},
		{Name: "projet/mcp/servers/gateway", Path: "projet/mcp/servers/gateway", Required: false, Description: "Gateway MCP", Category: "mcp"},
	}
}

// AnalyzeGaps analyse les écarts entre modules existants et attendus
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

	// Créer un map des modules existants pour une recherche rapide
	existingMap := make(map[string]ModuleInfo)
	for _, module := range repoStructure.Modules {
		existingMap[module.Name] = module
	}

	// Créer un map des modules attendus pour une recherche rapide
	expectedMap := make(map[string]ExpectedModule)
	for _, module := range expectedModules {
		expectedMap[module.Name] = module
	}

	// Trouver les modules manquants
	for _, expected := range expectedModules {
		if _, found := existingMap[expected.Name]; !found {
			analysis.MissingModules = append(analysis.MissingModules, expected)
		} else {
			analysis.MatchingModules = append(analysis.MatchingModules, existingMap[expected.Name])
		}
	}

	// Trouver les modules supplémentaires
	for _, existing := range repoStructure.Modules {
		if _, expected := expectedMap[existing.Name]; !expected {
			analysis.ExtraModules = append(analysis.ExtraModules, existing)
		}
	}

	// Calculer le taux de conformité (basé sur les modules requis trouvés)
	requiredModules := 0
	foundRequiredModules := 0
	for _, expected := range expectedModules {
		if expected.Required {
			requiredModules++
			if _, found := existingMap[expected.Name]; found {
				foundRequiredModules++
			}
		}
	}

	if requiredModules > 0 {
		analysis.ComplianceRate = float64(foundRequiredModules) / float64(requiredModules) * 100
	} else {
		analysis.ComplianceRate = 100.0
	}

	// Générer le résumé et les recommandations
	analysis.Summary = fmt.Sprintf("Analyse d'écart : %d/%d modules requis trouvés (%.1f%% de conformité)",
		foundRequiredModules, requiredModules, analysis.ComplianceRate)

	if len(analysis.MissingModules) > 0 {
		analysis.Recommendations = append(analysis.Recommendations,
			fmt.Sprintf("Implémenter les %d modules manquants", len(analysis.MissingModules)))
	}

	if len(analysis.ExtraModules) > 0 {
		analysis.Recommendations = append(analysis.Recommendations,
			fmt.Sprintf("Vérifier la nécessité des %d modules supplémentaires", len(analysis.ExtraModules)))
	}

	if analysis.ComplianceRate == 100.0 {
		analysis.Recommendations = append(analysis.Recommendations,
			"Architecture conforme aux spécifications")
	}

	return analysis
}

// GenerateMarkdownReport génère un rapport Markdown à partir de l'analyse
func GenerateMarkdownReport(analysis GapAnalysis) string {
	var content strings.Builder

	content.WriteString("# 📊 Analyse d'Écart des Modules\n\n")
	content.WriteString(fmt.Sprintf("**Date d'analyse :** %s\n\n", analysis.AnalysisDate.Format("2006-01-02 15:04:05")))
	content.WriteString(fmt.Sprintf("**Résumé :** %s\n\n", analysis.Summary))
	content.WriteString(fmt.Sprintf("**Taux de conformité :** %.1f%%\n\n", analysis.ComplianceRate))

	// Section des modules manquants
	if len(analysis.MissingModules) > 0 {
		content.WriteString("## ❌ Modules Manquants\n\n")
		for _, module := range analysis.MissingModules {
			reqStr := ""
			if module.Required {
				reqStr = "**REQUIS** "
			}
			content.WriteString(fmt.Sprintf("- %s`%s` (%s)\n", reqStr, module.Name, module.Path))
			content.WriteString(fmt.Sprintf("  - **Catégorie:** %s\n", module.Category))
			content.WriteString(fmt.Sprintf("  - **Description:** %s\n", module.Description))
		}
		content.WriteString("\n")
	}

	// Section des modules supplémentaires
	if len(analysis.ExtraModules) > 0 {
		content.WriteString("## ⚠️ Modules Supplémentaires\n\n")
		for _, module := range analysis.ExtraModules {
			content.WriteString(fmt.Sprintf("- `%s` - %s\n", module.Name, module.Description))
		}
		content.WriteString("\n")
	}

	// Section des modules trouvés
	if len(analysis.MatchingModules) > 0 {
		content.WriteString("## ✅ Modules Conformes\n\n")
		for _, module := range analysis.MatchingModules {
			content.WriteString(fmt.Sprintf("- `%s` - %s\n", module.Name, module.Description))
		}
		content.WriteString("\n")
	}

	// Section des recommandations
	if len(analysis.Recommendations) > 0 {
		content.WriteString("## 🎯 Recommandations\n\n")
		for i, rec := range analysis.Recommendations {
			content.WriteString(fmt.Sprintf("%d. %s\n", i+1, rec))
		}
		content.WriteString("\n")
	}

	return content.String()
}

// LoadRepositoryStructure charge la structure du dépôt depuis un fichier JSON
func LoadRepositoryStructure(filePath string) (RepositoryStructure, error) {
	var structure RepositoryStructure

	data, err := os.ReadFile(filePath)
	if err != nil {
		return structure, fmt.Errorf("erreur lecture fichier %s: %v", filePath, err)
	}

	err = json.Unmarshal(data, &structure)
	if err != nil {
		return structure, fmt.Errorf("erreur parsing JSON %s: %v", filePath, err)
	}

	return structure, nil
}

// SaveGapAnalysis sauvegarde l'analyse dans un fichier JSON
func SaveGapAnalysis(analysis GapAnalysis, filePath string) error {
	data, err := json.MarshalIndent(analysis, "", "  ")
	if err != nil {
		return fmt.Errorf("erreur marshalling analyse: %v", err)
	}

	err = os.WriteFile(filePath, data, 0o644)
	if err != nil {
		return fmt.Errorf("erreur écriture fichier %s: %v", filePath, err)
	}

	log.Printf("Analyse d'écart sauvegardée dans %s", filePath)
	return nil
}

// SaveMarkdownReport sauvegarde le rapport Markdown
func SaveMarkdownReport(content, filePath string) error {
	err := os.WriteFile(filePath, []byte(content), 0o644)
	if err != nil {
		return fmt.Errorf("erreur écriture rapport Markdown %s: %v", filePath, err)
	}

	log.Printf("Rapport Markdown sauvegardé dans %s", filePath)
	return nil
}
