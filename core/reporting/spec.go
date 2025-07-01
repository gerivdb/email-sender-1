package reporting

import (
	"fmt"
	"strings"
	"time"
)

// Specification représente une spécification technique
type Specification struct {
	ID                 string     `json:"id"`
	RequirementID      string     `json:"requirement_id"`
	Name               string     `json:"name"`
	Description        string     `json:"description"`
	TechnicalDetails   string     `json:"technical_details"`
	AcceptanceCriteria []string   `json:"acceptance_criteria"`
	TestCases          []TestCase `json:"test_cases"`
	Complexity         string     `json:"complexity"`
	EstimatedEffort    float64    `json:"estimated_effort"`
	Priority           string     `json:"priority"`
	Category           string     `json:"category"`
	Dependencies       []string   `json:"dependencies"`
	CreatedAt          time.Time  `json:"created_at"`
}

// TestCase représente un cas de test
type TestCase struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Type        string `json:"type"`
	Expected    string `json:"expected"`
	Automated   bool   `json:"automated"`
}

// SpecificationAnalysis représente l'analyse des spécifications
type SpecificationAnalysis struct {
	AnalysisDate           time.Time       `json:"analysis_date"`
	TotalSpecifications    int             `json:"total_specifications"`
	TotalTestCases         int             `json:"total_test_cases"`
	TotalEffort            float64         `json:"total_effort"`
	Specifications         []Specification `json:"specifications"`
	Summary                string          `json:"summary"`
	ComplexityDistribution map[string]int  `json:"complexity_distribution"`
	CategoryDistribution   map[string]int  `json:"category_distribution"`
	Recommendations        []string        `json:"recommendations"`
}

// GenerateSpecificationsFromRequirements génère des spécifications à partir des besoins
func GenerateSpecificationsFromRequirements(requirements []Requirement) []Specification {
	var specifications []Specification

	for i, req := range requirements {
		spec := Specification{
			ID:                 fmt.Sprintf("SPEC-%03d", i+1),
			RequirementID:      req.ID,
			Name:               fmt.Sprintf("Spécification pour %s", req.Name),
			Description:        generateSpecDescription(req),
			TechnicalDetails:   generateTechnicalDetails(req),
			AcceptanceCriteria: generateAcceptanceCriteria(req),
			TestCases:          generateTestCases(req, fmt.Sprintf("SPEC-%03d", i+1)),
			Complexity:         estimateComplexity(req),
			EstimatedEffort:    estimateEffort(req),
			Priority:           req.Priority,
			Category:           req.Category,
			Dependencies:       req.Dependencies,
			CreatedAt:          time.Now(),
		}
		specifications = append(specifications, spec)
	}

	return specifications
}

// generateSpecDescription génère une description de spécification
func generateSpecDescription(req Requirement) string {
	return fmt.Sprintf(
		"Cette spécification définit l'implémentation technique pour le besoin '%s'. "+
			"Elle inclut les détails d'architecture, les interfaces, et les critères d'acceptation "+
			"nécessaires pour satisfaire les exigences fonctionnelles et non-fonctionnelles.",
		req.Name)
}

// generateTechnicalDetails génère les détails techniques
func generateTechnicalDetails(req Requirement) string {
	var details strings.Builder

	switch req.Category {
	case "core":
		details.WriteString("**Architecture:**\n")
		details.WriteString("- Module Go avec interface claire\n")
		details.WriteString("- Tests unitaires et d'intégration\n")
		details.WriteString("- Documentation API complète\n")
		details.WriteString("- Gestion d'erreurs robuste\n\n")
		details.WriteString("**Technologies:**\n")
		details.WriteString("- Go 1.24+\n")
		details.WriteString("- Tests avec testing package\n")
		details.WriteString("- JSON pour la sérialisation\n")
	case "cmd":
		details.WriteString("**Architecture:**\n")
		details.WriteString("- Exécutable en ligne de commande\n")
		details.WriteString("- Gestion des arguments et flags\n")
		details.WriteString("- Codes de sortie appropriés\n")
		details.WriteString("- Logging structuré\n\n")
		details.WriteString("**Technologies:**\n")
		details.WriteString("- Go flag package\n")
		details.WriteString("- os/exec pour l'orchestration\n")
		details.WriteString("- Timeout et gestion d'erreurs\n")
	case "tests":
		details.WriteString("**Architecture:**\n")
		details.WriteString("- Suite de tests complète\n")
		details.WriteString("- Tests unitaires et d'intégration\n")
		details.WriteString("- Couverture de code > 80%\n")
		details.WriteString("- Tests de performance\n\n")
		details.WriteString("**Technologies:**\n")
		details.WriteString("- Go testing package\n")
		details.WriteString("- Benchmarks\n")
		details.WriteString("- Mocks et stubs\n")
	case "devops":
		details.WriteString("**Architecture:**\n")
		details.WriteString("- Scripts d'automatisation\n")
		details.WriteString("- Pipeline CI/CD\n")
		details.WriteString("- Monitoring et alertes\n")
		details.WriteString("- Documentation d'exploitation\n\n")
		details.WriteString("**Technologies:**\n")
		details.WriteString("- GitHub Actions\n")
		details.WriteString("- Docker\n")
		details.WriteString("- Scripts shell/PowerShell\n")
	default:
		details.WriteString("**Architecture générale:**\n")
		details.WriteString("- Implémentation selon les bonnes pratiques\n")
		details.WriteString("- Tests appropriés\n")
		details.WriteString("- Documentation complète\n")
	}

	return details.String()
}

// generateAcceptanceCriteria génère les critères d'acceptation
func generateAcceptanceCriteria(req Requirement) []string {
	var criteria []string

	// Critères généraux
	criteria = append(criteria, "Le module compile sans erreur")
	criteria = append(criteria, "Tous les tests passent avec succès")
	criteria = append(criteria, "La documentation est complète et à jour")
	criteria = append(criteria, "Le code respecte les standards de qualité")

	// Critères spécifiques par catégorie
	switch req.Category {
	case "core":
		criteria = append(criteria, "L'interface publique est stable et documentée")
		criteria = append(criteria, "La couverture de code est >= 80%")
		criteria = append(criteria, "Les erreurs sont gérées de manière appropriée")
		criteria = append(criteria, "Les performances sont acceptables")
	case "cmd":
		criteria = append(criteria, "L'aide en ligne de commande est claire")
		criteria = append(criteria, "Les codes de sortie sont corrects")
		criteria = append(criteria, "La gestion des arguments est robuste")
		criteria = append(criteria, "Les logs sont informatifs")
	case "tests":
		criteria = append(criteria, "Tous les cas de test sont couverts")
		criteria = append(criteria, "Les tests sont fiables et reproductibles")
		criteria = append(criteria, "Les tests d'intégration passent")
		criteria = append(criteria, "Les benchmarks montrent des performances acceptables")
	case "devops":
		criteria = append(criteria, "Le pipeline CI/CD fonctionne correctement")
		criteria = append(criteria, "Le déploiement est automatisé")
		criteria = append(criteria, "Le monitoring est en place")
		criteria = append(criteria, "La documentation d'exploitation est complète")
	}

	// Critères spécifiques par priorité
	if req.Priority == "high" {
		criteria = append(criteria, "La livraison respecte les délais critiques")
		criteria = append(criteria, "La solution est robuste et fiable")
	}

	return criteria
}

// generateTestCases génère les cas de test
func generateTestCases(req Requirement, specID string) []TestCase {
	var testCases []TestCase

	// Tests de base
	testCases = append(testCases, TestCase{
		ID:          fmt.Sprintf("%s-TC-001", specID),
		Name:        "Test de fonctionnement nominal",
		Description: "Vérifier le comportement normal du module",
		Type:        "functional",
		Expected:    "Le module fonctionne selon les spécifications",
		Automated:   true,
	})

	testCases = append(testCases, TestCase{
		ID:          fmt.Sprintf("%s-TC-002", specID),
		Name:        "Test de gestion d'erreurs",
		Description: "Vérifier la gestion des cas d'erreur",
		Type:        "error",
		Expected:    "Les erreurs sont gérées de manière appropriée",
		Automated:   true,
	})

	// Tests spécifiques par catégorie
	switch req.Category {
	case "core":
		testCases = append(testCases, TestCase{
			ID:          fmt.Sprintf("%s-TC-003", specID),
			Name:        "Test de performance",
			Description: "Vérifier les performances du module",
			Type:        "performance",
			Expected:    "Les performances sont dans les limites acceptables",
			Automated:   true,
		})
	case "cmd":
		testCases = append(testCases, TestCase{
			ID:          fmt.Sprintf("%s-TC-003", specID),
			Name:        "Test d'arguments",
			Description: "Vérifier la gestion des arguments en ligne de commande",
			Type:        "functional",
			Expected:    "Les arguments sont traités correctement",
			Automated:   true,
		})
	case "tests":
		testCases = append(testCases, TestCase{
			ID:          fmt.Sprintf("%s-TC-003", specID),
			Name:        "Test de couverture",
			Description: "Vérifier la couverture de code",
			Type:        "coverage",
			Expected:    "La couverture de code est >= 80%",
			Automated:   true,
		})
	}

	return testCases
}

// estimateComplexity estime la complexité d'une spécification
func estimateComplexity(req Requirement) string {
	score := 0

	// Facteurs de complexité
	if req.Priority == "high" {
		score += 2
	}
	if req.Category == "core" {
		score += 3
	}
	if req.Category == "cmd" {
		score += 2
	}
	if len(req.Dependencies) > 2 {
		score += 2
	}

	// Classification
	if score <= 2 {
		return "low"
	} else if score <= 4 {
		return "medium"
	} else {
		return "high"
	}
}

// estimateEffort estime l'effort en jours
func estimateEffort(req Requirement) float64 {
	baseEffort := 1.0

	// Facteurs d'effort
	switch req.Category {
	case "core":
		baseEffort = 3.0
	case "cmd":
		baseEffort = 2.0
	case "tests":
		baseEffort = 1.5
	case "devops":
		baseEffort = 2.5
	}

	// Multiplicateurs
	switch req.Priority {
	case "high":
		baseEffort *= 1.2 // Plus de temps pour la qualité
	case "medium":
		baseEffort *= 1.0
	case "low":
		baseEffort *= 0.8
	}

	// Complexité des dépendances
	if len(req.Dependencies) > 0 {
		baseEffort += float64(len(req.Dependencies)) * 0.5
	}

	return baseEffort
}

// AnalyzeSpecifications effectue l'analyse des spécifications
func AnalyzeSpecifications(specifications []Specification) SpecificationAnalysis {
	analysis := SpecificationAnalysis{
		AnalysisDate:           time.Now(),
		TotalSpecifications:    len(specifications),
		Specifications:         specifications,
		ComplexityDistribution: make(map[string]int),
		CategoryDistribution:   make(map[string]int),
		Recommendations:        []string{},
	}

	// Analyser les distributions et calculer les totaux
	for _, spec := range specifications {
		analysis.ComplexityDistribution[spec.Complexity]++
		analysis.CategoryDistribution[spec.Category]++
		analysis.TotalTestCases += len(spec.TestCases)
		analysis.TotalEffort += spec.EstimatedEffort
	}

	// Générer des recommandations
	highComplexityCount := analysis.ComplexityDistribution["high"]
	if highComplexityCount > 0 {
		analysis.Recommendations = append(analysis.Recommendations,
			fmt.Sprintf("ATTENTION: %d spécifications de haute complexité identifiées - prévoir des ressources supplémentaires", highComplexityCount))
	}

	if analysis.TotalEffort > 20 {
		analysis.Recommendations = append(analysis.Recommendations,
			fmt.Sprintf("PLANIFICATION: Effort total estimé %.1f jours - considérer une approche itérative", analysis.TotalEffort))
	}

	coreSpecs := analysis.CategoryDistribution["core"]
	if coreSpecs > 0 {
		analysis.Recommendations = append(analysis.Recommendations,
			fmt.Sprintf("PRIORITÉ: %d spécifications core - implémenter en premier", coreSpecs))
	}

	testSpecs := analysis.CategoryDistribution["tests"]
	if testSpecs > 0 {
		analysis.Recommendations = append(analysis.Recommendations,
			fmt.Sprintf("QUALITÉ: %d spécifications de tests - développer en parallèle", testSpecs))
	}

	// Générer le résumé
	analysis.Summary = fmt.Sprintf(
		"Analyse des spécifications terminée: %d spécifications générées avec %d cas de test. "+
			"Effort total estimé: %.1f jours. Complexité: haute(%d), moyenne(%d), faible(%d).",
		analysis.TotalSpecifications,
		analysis.TotalTestCases,
		analysis.TotalEffort,
		analysis.ComplexityDistribution["high"],
		analysis.ComplexityDistribution["medium"],
		analysis.ComplexityDistribution["low"])

	return analysis
}

// GenerateSpecMarkdownReport génère un rapport Markdown des spécifications
func GenerateSpecMarkdownReport(analysis SpecificationAnalysis) string {
	var report strings.Builder

	report.WriteString("# 📋 Spécifications Techniques\n\n")
	report.WriteString(fmt.Sprintf("**Date de génération:** %s\n\n", analysis.AnalysisDate.Format("2006-01-02 15:04:05")))
	report.WriteString(fmt.Sprintf("**Résumé:** %s\n\n", analysis.Summary))

	// Métriques
	report.WriteString("## 📊 Métriques\n\n")
	report.WriteString(fmt.Sprintf("- **Total des spécifications:** %d\n", analysis.TotalSpecifications))
	report.WriteString(fmt.Sprintf("- **Total des cas de test:** %d\n", analysis.TotalTestCases))
	report.WriteString(fmt.Sprintf("- **Effort total estimé:** %.1f jours\n\n", analysis.TotalEffort))

	// Distribution par complexité
	report.WriteString("### 🎯 Distribution par complexité\n\n")
	for complexity, count := range analysis.ComplexityDistribution {
		report.WriteString(fmt.Sprintf("- **%s:** %d spécifications\n", complexity, count))
	}
	report.WriteString("\n")

	// Distribution par catégorie
	report.WriteString("### 📂 Distribution par catégorie\n\n")
	for category, count := range analysis.CategoryDistribution {
		report.WriteString(fmt.Sprintf("- **%s:** %d spécifications\n", category, count))
	}
	report.WriteString("\n")

	// Spécifications détaillées
	report.WriteString("## 📝 Spécifications Détaillées\n\n")
	for _, spec := range analysis.Specifications {
		report.WriteString(fmt.Sprintf("### %s - %s\n\n", spec.ID, spec.Name))
		report.WriteString(fmt.Sprintf("- **Besoin associé:** %s\n", spec.RequirementID))
		report.WriteString(fmt.Sprintf("- **Complexité:** %s\n", spec.Complexity))
		report.WriteString(fmt.Sprintf("- **Effort estimé:** %.1f jours\n", spec.EstimatedEffort))
		report.WriteString(fmt.Sprintf("- **Priorité:** %s\n", spec.Priority))
		report.WriteString(fmt.Sprintf("- **Catégorie:** %s\n\n", spec.Category))

		report.WriteString("**Description:**\n")
		report.WriteString(fmt.Sprintf("%s\n\n", spec.Description))

		report.WriteString("**Détails techniques:**\n")
		report.WriteString(fmt.Sprintf("%s\n\n", spec.TechnicalDetails))

		report.WriteString("**Critères d'acceptation:**\n")
		for i, criteria := range spec.AcceptanceCriteria {
			report.WriteString(fmt.Sprintf("%d. %s\n", i+1, criteria))
		}
		report.WriteString("\n")

		report.WriteString("**Cas de test:**\n")
		for _, testCase := range spec.TestCases {
			report.WriteString(fmt.Sprintf("- **%s:** %s (Type: %s, Automatisé: %v)\n",
				testCase.Name, testCase.Description, testCase.Type, testCase.Automated))
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
