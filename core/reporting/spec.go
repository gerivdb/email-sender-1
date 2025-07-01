package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"time"
)

// Requirement représente un besoin (importé du module needs)
type Requirement struct {
	ID           string    `json:"id"`
	Name         string    `json:"name"`
	Description  string    `json:"description"`
	Priority     string    `json:"priority"`
	Category     string    `json:"category"`
	Source       string    `json:"source"`
	SourceID     string    `json:"source_id"`
	Status       string    `json:"status"`
	CreatedAt    time.Time `json:"created_at"`
	Dependencies []string  `json:"dependencies"`
}

// RequirementsAnalysis représente l'analyse des besoins (importé du module needs)
type RequirementsAnalysis struct {
	AnalysisDate      time.Time      `json:"analysis_date"`
	TotalIssues       int            `json:"total_issues"`
	TotalRequirements int            `json:"total_requirements"`
	Requirements      []Requirement  `json:"requirements"`
	Summary           string         `json:"summary"`
	Categories        map[string]int `json:"categories"`
	Priorities        map[string]int `json:"priorities"`
	Recommendations   []string       `json:"recommendations"`
}

// Specification représente une spécification technique détaillée
type Specification struct {
	ID                 string                 `json:"id"`
	RequirementID      string                 `json:"requirement_id"`
	Title              string                 `json:"title"`
	Description        string                 `json:"description"`
	TechnicalDetails   map[string]interface{} `json:"technical_details"`
	AcceptanceCriteria []string               `json:"acceptance_criteria"`
	TestCases          []TestCase             `json:"test_cases"`
	Dependencies       []string               `json:"dependencies"`
	Priority           string                 `json:"priority"`
	EstimatedEffort    string                 `json:"estimated_effort"`
	Status             string                 `json:"status"`
	CreatedAt          time.Time              `json:"created_at"`
	UpdatedAt          time.Time              `json:"updated_at"`
}

// TestCase représente un cas de test
type TestCase struct {
	ID            string   `json:"id"`
	Name          string   `json:"name"`
	Description   string   `json:"description"`
	PreConditions []string `json:"pre_conditions"`
	Steps         []string `json:"steps"`
	Expected      string   `json:"expected_result"`
	Type          string   `json:"type"` // unit, integration, e2e
	Priority      string   `json:"priority"`
}

// SpecificationAnalysis représente l'analyse complète des spécifications
type SpecificationAnalysis struct {
	AnalysisDate       time.Time       `json:"analysis_date"`
	TotalRequirements  int             `json:"total_requirements"`
	TotalSpecs         int             `json:"total_specs"`
	Specifications     []Specification `json:"specifications"`
	ComplianceRate     float64         `json:"compliance_rate"`
	CoverageByCategory map[string]int  `json:"coverage_by_category"`
	CoverageByPriority map[string]int  `json:"coverage_by_priority"`
	MissingSpecs       []Requirement   `json:"missing_specs"`
	Summary            string          `json:"summary"`
	Recommendations    []string        `json:"recommendations"`
}

// generateSpecificationsFromRequirements génère des spécifications à partir des besoins
func generateSpecificationsFromRequirements(requirements []Requirement) []Specification {
	var specs []Specification

	for i, req := range requirements {
		spec := Specification{
			ID:                 fmt.Sprintf("SPEC-%03d", i+1),
			RequirementID:      req.ID,
			Title:              fmt.Sprintf("Spécification pour %s", req.Name),
			Description:        generateSpecDescription(req),
			TechnicalDetails:   generateTechnicalDetails(req),
			AcceptanceCriteria: generateAcceptanceCriteria(req),
			TestCases:          generateTestCases(req, i+1),
			Dependencies:       req.Dependencies,
			Priority:           req.Priority,
			EstimatedEffort:    estimateEffort(req),
			Status:             "draft",
			CreatedAt:          time.Now(),
			UpdatedAt:          time.Now(),
		}
		specs = append(specs, spec)
	}

	return specs
}

// generateSpecDescription génère une description détaillée de la spécification
func generateSpecDescription(req Requirement) string {
	baseDesc := fmt.Sprintf("Cette spécification détaille l'implémentation du besoin '%s'.\n\n", req.Name)

	baseDesc += fmt.Sprintf("**Contexte:** %s\n\n", req.Description)

	switch req.Category {
	case "core":
		baseDesc += "**Type:** Module core - fonctionnalité fondamentale du système\n"
		baseDesc += "**Criticité:** Haute - requis pour le fonctionnement global\n"
	case "cmd":
		baseDesc += "**Type:** Module commande - outil exécutable\n"
		baseDesc += "**Criticité:** Moyenne - améliore l'expérience utilisateur\n"
	case "tests":
		baseDesc += "**Type:** Module de tests - validation et qualité\n"
		baseDesc += "**Criticité:** Haute - essentiel pour la fiabilité\n"
	case "devops":
		baseDesc += "**Type:** Module DevOps - automatisation et déploiement\n"
		baseDesc += "**Criticité:** Moyenne - optimise les processus\n"
	default:
		baseDesc += "**Type:** Module général\n"
		baseDesc += "**Criticité:** À déterminer\n"
	}

	baseDesc += fmt.Sprintf("**Priorité:** %s\n", strings.ToUpper(req.Priority))

	return baseDesc
}

// generateTechnicalDetails génère les détails techniques selon le type de besoin
func generateTechnicalDetails(req Requirement) map[string]interface{} {
	details := make(map[string]interface{})

	// Détails communs
	details["language"] = "Go"
	details["architecture"] = "Module-based"
	details["testing_framework"] = "go test"

	// Détails spécifiques selon la catégorie
	switch req.Category {
	case "core":
		details["type"] = "library_module"
		details["package"] = "main"
		details["cli_interface"] = true
		details["config_file"] = false
		details["dependencies"] = []string{"encoding/json", "flag", "fmt", "os", "time"}
	case "cmd":
		details["type"] = "executable"
		details["package"] = "main"
		details["cli_interface"] = true
		details["config_file"] = true
		details["dependencies"] = []string{"flag", "fmt", "os", "os/exec"}
	case "tests":
		details["type"] = "test_module"
		details["package"] = "main"
		details["test_types"] = []string{"unit", "integration", "benchmark"}
		details["coverage_target"] = "90%"
	case "devops":
		details["type"] = "automation_script"
		details["platform"] = []string{"github_actions", "bash"}
		details["triggers"] = []string{"push", "pull_request", "schedule"}
	}

	// Performance et scalabilité
	details["performance"] = map[string]interface{}{
		"max_execution_time": "5m",
		"memory_limit":       "512MB",
		"concurrent_safe":    true,
	}

	return details
}

// generateAcceptanceCriteria génère les critères d'acceptation
func generateAcceptanceCriteria(req Requirement) []string {
	var criteria []string

	// Critères de base
	criteria = append(criteria, "Le module compile sans erreur avec `go build`")
	criteria = append(criteria, "Tous les tests unitaires passent avec `go test`")
	criteria = append(criteria, "Le code respecte les conventions Go (gofmt, golint)")
	criteria = append(criteria, "La documentation est complète et à jour")

	// Critères spécifiques selon la priorité
	switch req.Priority {
	case "high":
		criteria = append(criteria, "Couverture de tests >= 90%")
		criteria = append(criteria, "Validation manuelle par l'équipe")
		criteria = append(criteria, "Tests de performance validés")
	case "medium":
		criteria = append(criteria, "Couverture de tests >= 70%")
		criteria = append(criteria, "Revue de code approuvée")
	case "low":
		criteria = append(criteria, "Couverture de tests >= 50%")
		criteria = append(criteria, "Tests d'intégration de base")
	}

	// Critères spécifiques selon la catégorie
	switch req.Category {
	case "core":
		criteria = append(criteria, "Interface CLI fonctionnelle et documentée")
		criteria = append(criteria, "Génération des fichiers de sortie attendus")
		criteria = append(criteria, "Gestion d'erreurs robuste")
	case "cmd":
		criteria = append(criteria, "Exécution en ligne de commande réussie")
		criteria = append(criteria, "Options et flags documentés")
		criteria = append(criteria, "Codes de sortie appropriés")
	case "tests":
		criteria = append(criteria, "Tests automatisés intégrés dans le pipeline")
		criteria = append(criteria, "Rapports de tests générés")
	case "devops":
		criteria = append(criteria, "Pipeline CI/CD fonctionnel")
		criteria = append(criteria, "Déploiement automatique validé")
	}

	return criteria
}

// generateTestCases génère les cas de test
func generateTestCases(req Requirement, index int) []TestCase {
	var testCases []TestCase

	// Test cas de base - Succès nominal
	testCases = append(testCases, TestCase{
		ID:          fmt.Sprintf("TC-%03d-001", index),
		Name:        "Exécution nominale réussie",
		Description: fmt.Sprintf("Teste l'exécution normale du module %s", req.Name),
		PreConditions: []string{
			"Environnement Go configuré",
			"Fichiers d'entrée présents si requis",
			"Permissions d'écriture appropriées",
		},
		Steps: []string{
			"Compiler le module avec `go build`",
			"Exécuter le module avec les paramètres par défaut",
			"Vérifier la sortie standard",
			"Vérifier les fichiers générés",
		},
		Expected: "Module exécuté avec succès, fichiers de sortie générés correctement",
		Type:     "integration",
		Priority: "high",
	})

	// Test cas d'erreur
	testCases = append(testCases, TestCase{
		ID:          fmt.Sprintf("TC-%03d-002", index),
		Name:        "Gestion des erreurs",
		Description: "Teste la gestion des cas d'erreur",
		PreConditions: []string{
			"Environnement Go configuré",
			"Fichiers d'entrée absents ou corrompus",
		},
		Steps: []string{
			"Exécuter le module avec des entrées invalides",
			"Vérifier les messages d'erreur",
			"Vérifier le code de sortie",
		},
		Expected: "Messages d'erreur clairs, code de sortie non-zéro",
		Type:     "unit",
		Priority: "medium",
	})

	// Test cas de performance (pour modules critiques)
	if req.Priority == "high" {
		testCases = append(testCases, TestCase{
			ID:          fmt.Sprintf("TC-%03d-003", index),
			Name:        "Performance et scalabilité",
			Description: "Teste les performances du module",
			PreConditions: []string{
				"Environnement Go configuré",
				"Jeux de données de test volumineux",
			},
			Steps: []string{
				"Exécuter le module avec des données volumineuses",
				"Mesurer le temps d'exécution",
				"Mesurer l'utilisation mémoire",
				"Vérifier la stabilité",
			},
			Expected: "Exécution en moins de 5 minutes, utilisation mémoire < 512MB",
			Type:     "performance",
			Priority: "medium",
		})
	}

	return testCases
}

// estimateEffort estime l'effort de développement
func estimateEffort(req Requirement) string {
	baseEffort := 1 // jour

	// Ajustement selon la priorité
	switch req.Priority {
	case "high":
		baseEffort += 2
	case "medium":
		baseEffort += 1
	case "low":
		baseEffort += 0
	}

	// Ajustement selon la catégorie
	switch req.Category {
	case "core":
		baseEffort += 3 // Modules core plus complexes
	case "cmd":
		baseEffort += 2 // Outils avec interface
	case "tests":
		baseEffort += 1 // Tests plus simples mais nombreux
	case "devops":
		baseEffort += 2 // Configuration et validation
	}

	// Ajustement selon les dépendances
	baseEffort += len(req.Dependencies)

	if baseEffort <= 2 {
		return "1-2 jours"
	} else if baseEffort <= 4 {
		return "3-4 jours"
	} else if baseEffort <= 7 {
		return "1 semaine"
	} else {
		return "1-2 semaines"
	}
}

// analyzeSpecifications effectue l'analyse de complétude des spécifications
func analyzeSpecifications(requirements []Requirement, specs []Specification) SpecificationAnalysis {
	analysis := SpecificationAnalysis{
		AnalysisDate:       time.Now(),
		TotalRequirements:  len(requirements),
		TotalSpecs:         len(specs),
		Specifications:     specs,
		CoverageByCategory: make(map[string]int),
		CoverageByPriority: make(map[string]int),
		MissingSpecs:       []Requirement{},
		Recommendations:    []string{},
	}

	// Créer un map des specs par requirement ID
	specsByReqID := make(map[string]Specification)
	for _, spec := range specs {
		specsByReqID[spec.RequirementID] = spec
	}

	// Identifier les besoins sans spécification
	for _, req := range requirements {
		if _, hasSpec := specsByReqID[req.ID]; !hasSpec {
			analysis.MissingSpecs = append(analysis.MissingSpecs, req)
		}
	}

	// Analyser la couverture par catégorie et priorité
	for _, req := range requirements {
		if _, hasSpec := specsByReqID[req.ID]; hasSpec {
			analysis.CoverageByCategory[req.Category]++
			analysis.CoverageByPriority[req.Priority]++
		}
	}

	// Calculer le taux de conformité
	if analysis.TotalRequirements > 0 {
		analysis.ComplianceRate = float64(analysis.TotalSpecs) / float64(analysis.TotalRequirements) * 100
	} else {
		analysis.ComplianceRate = 100.0
	}

	// Générer des recommandations
	if analysis.ComplianceRate < 80 {
		analysis.Recommendations = append(analysis.Recommendations,
			"PRIORITÉ HAUTE: Taux de couverture faible - créer les spécifications manquantes")
	}

	if len(analysis.MissingSpecs) > 0 {
		analysis.Recommendations = append(analysis.Recommendations,
			fmt.Sprintf("SPÉCIFICATIONS: %d besoins sans spécifications détaillées", len(analysis.MissingSpecs)))
	}

	// Recommandations par catégorie
	if analysis.CoverageByCategory["core"] < analysis.CoverageByCategory["tests"] {
		analysis.Recommendations = append(analysis.Recommendations,
			"ARCHITECTURE: Prioriser les spécifications des modules core")
	}

	// Générer le résumé
	analysis.Summary = fmt.Sprintf(
		"Analyse des spécifications terminée: %d spécifications pour %d besoins (%.1f%% de couverture). "+
			"Couverture par priorité: haute(%d), moyenne(%d), faible(%d).",
		analysis.TotalSpecs, analysis.TotalRequirements, analysis.ComplianceRate,
		analysis.CoverageByPriority["high"], analysis.CoverageByPriority["medium"], analysis.CoverageByPriority["low"])

	return analysis
}

// generateMarkdownReport génère un rapport Markdown des spécifications
func generateMarkdownReport(analysis SpecificationAnalysis) string {
	var report strings.Builder

	report.WriteString("# 📋 Spécifications Techniques Détaillées\n\n")
	report.WriteString(fmt.Sprintf("**Date de génération:** %s\n\n", analysis.AnalysisDate.Format("2006-01-02 15:04:05")))
	report.WriteString(fmt.Sprintf("**Résumé:** %s\n\n", analysis.Summary))

	// Métriques
	report.WriteString("## 📊 Métriques de Couverture\n\n")
	report.WriteString(fmt.Sprintf("- **Besoins analysés:** %d\n", analysis.TotalRequirements))
	report.WriteString(fmt.Sprintf("- **Spécifications générées:** %d\n", analysis.TotalSpecs))
	report.WriteString(fmt.Sprintf("- **Taux de couverture:** %.1f%%\n\n", analysis.ComplianceRate))

	// Couverture par catégorie
	report.WriteString("### 📂 Couverture par Catégorie\n\n")
	for category, count := range analysis.CoverageByCategory {
		report.WriteString(fmt.Sprintf("- **%s:** %d spécifications\n", category, count))
	}
	report.WriteString("\n")

	// Couverture par priorité
	report.WriteString("### ⚡ Couverture par Priorité\n\n")
	for priority, count := range analysis.CoverageByPriority {
		report.WriteString(fmt.Sprintf("- **%s:** %d spécifications\n", priority, count))
	}
	report.WriteString("\n")

	// Spécifications détaillées
	report.WriteString("## 📝 Spécifications Détaillées\n\n")
	for _, spec := range analysis.Specifications {
		report.WriteString(fmt.Sprintf("### %s - %s\n\n", spec.ID, spec.Title))
		report.WriteString(fmt.Sprintf("- **Besoin source:** %s\n", spec.RequirementID))
		report.WriteString(fmt.Sprintf("- **Priorité:** %s\n", spec.Priority))
		report.WriteString(fmt.Sprintf("- **Effort estimé:** %s\n", spec.EstimatedEffort))
		report.WriteString(fmt.Sprintf("- **Statut:** %s\n\n", spec.Status))

		report.WriteString("**Description:**\n")
		report.WriteString(fmt.Sprintf("%s\n\n", spec.Description))

		// Critères d'acceptation
		if len(spec.AcceptanceCriteria) > 0 {
			report.WriteString("**Critères d'acceptation:**\n")
			for i, criteria := range spec.AcceptanceCriteria {
				report.WriteString(fmt.Sprintf("%d. %s\n", i+1, criteria))
			}
			report.WriteString("\n")
		}

		// Cas de test
		if len(spec.TestCases) > 0 {
			report.WriteString("**Cas de test:**\n")
			for _, testCase := range spec.TestCases {
				report.WriteString(fmt.Sprintf("- **%s** (%s): %s\n", testCase.Name, testCase.Type, testCase.Description))
			}
			report.WriteString("\n")
		}

		report.WriteString("---\n\n")
	}

	// Spécifications manquantes
	if len(analysis.MissingSpecs) > 0 {
		report.WriteString("## ⚠️ Spécifications Manquantes\n\n")
		for _, missing := range analysis.MissingSpecs {
			report.WriteString(fmt.Sprintf("- **%s** (%s) - %s\n", missing.ID, missing.Priority, missing.Name))
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

func main() {
	// Définir les flags de ligne de commande
	inputFile := flag.String("input", "besoins.json", "Fichier JSON d'entrée contenant les besoins")
	outputFile := flag.String("output", "spec.json", "Fichier JSON de sortie pour les spécifications")
	flag.Parse()

	fmt.Println("=== Générateur de spécifications détaillées ===")
	fmt.Printf("📂 Fichier d'entrée: %s\n", *inputFile)
	fmt.Printf("📄 Fichier de sortie: %s\n", *outputFile)

	// Vérifier que le fichier d'entrée existe
	if _, err := os.Stat(*inputFile); os.IsNotExist(err) {
		log.Fatalf("❌ Fichier d'entrée '%s' introuvable. Exécutez d'abord l'analyse des besoins.", *inputFile)
	}

	// Lire l'analyse des besoins
	jsonData, err := ioutil.ReadFile(*inputFile)
	if err != nil {
		log.Fatalf("❌ Erreur lors de la lecture de %s: %v", *inputFile, err)
	}

	var requirementsAnalysis RequirementsAnalysis
	err = json.Unmarshal(jsonData, &requirementsAnalysis)
	if err != nil {
		log.Fatalf("❌ Erreur lors de la désérialisation de %s: %v", *inputFile, err)
	}

	fmt.Printf("📋 Besoins chargés: %d\n", len(requirementsAnalysis.Requirements))

	// Générer les spécifications
	specifications := generateSpecificationsFromRequirements(requirementsAnalysis.Requirements)
	fmt.Printf("📝 Spécifications générées: %d\n", len(specifications))

	// Analyser la complétude
	analysis := analyzeSpecifications(requirementsAnalysis.Requirements, specifications)

	// Sauvegarder l'analyse en JSON
	analysisJSON, err := json.MarshalIndent(analysis, "", "  ")
	if err != nil {
		log.Fatalf("❌ Erreur lors de la sérialisation de l'analyse: %v", err)
	}

	err = ioutil.WriteFile(*outputFile, analysisJSON, 0644)
	if err != nil {
		log.Fatalf("❌ Erreur lors de l'écriture de %s: %v", *outputFile, err)
	}

	// Générer le rapport Markdown
	markdownReport := generateMarkdownReport(analysis)
	markdownFile := "SPEC_INIT.md"
	err = ioutil.WriteFile(markdownFile, []byte(markdownReport), 0644)
	if err != nil {
		log.Printf("⚠️ Erreur lors de l'écriture du rapport Markdown %s: %v", markdownFile, err)
	}

	// Afficher le résumé
	fmt.Printf("\n✅ Génération terminée avec succès!\n")
	fmt.Printf("📊 %s\n", analysis.Summary)
	fmt.Printf("📄 Fichiers générés:\n")
	fmt.Printf("   - %s (spécifications JSON)\n", *outputFile)
	fmt.Printf("   - %s (rapport Markdown)\n", markdownFile)

	// Afficher les recommandations principales
	fmt.Printf("\n🎯 Recommandations principales:\n")
	for i, rec := range analysis.Recommendations {
		if i >= 3 {
			fmt.Printf("   ... et %d autres recommandations (voir le rapport complet)\n", len(analysis.Recommendations)-3)
			break
		}
		fmt.Printf("   %d. %s\n", i+1, rec)
	}

	// Code de sortie basé sur le taux de couverture
	if analysis.ComplianceRate < 80 {
		fmt.Printf("\n⚠️ Couverture faible (%.1f%%) - action requise\n", analysis.ComplianceRate)
		os.Exit(1)
	} else {
		fmt.Printf("\n🎉 Spécifications générées avec succès (%.1f%% de couverture)!\n", analysis.ComplianceRate)
		os.Exit(0)
	}
}
