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

// Issue représente un ticket ou une demande
type Issue struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	Priority    string    `json:"priority"`
	Category    string    `json:"category"`
	Status      string    `json:"status"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
	Labels      []string  `json:"labels"`
}

// Requirement représente un besoin identifié
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

// RequirementsAnalysis représente l'analyse des besoins
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

// parseIssuesFromJSON parse les issues depuis un fichier JSON
func parseIssuesFromJSON(filename string) ([]Issue, error) {
	// Si le fichier n'existe pas, créer des issues par défaut basées sur le plan v72
	if _, err := os.Stat(filename); os.IsNotExist(err) {
		return getDefaultIssues(), nil
	}

	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la lecture du fichier %s: %v", filename, err)
	}

	var issues []Issue
	err = json.Unmarshal(data, &issues)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la désérialisation des issues: %v", err)
	}

	return issues, nil
}

// getDefaultIssues retourne des issues par défaut basées sur le plan v72
func getDefaultIssues() []Issue {
	return []Issue{
		{
			ID:          "ROADMAP-001",
			Title:       "Implémentation du module core/reporting",
			Description: "Créer le module de génération de rapports automatisés selon le plan v72",
			Priority:    "high",
			Category:    "core",
			Status:      "open",
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
			Labels:      []string{"roadmap", "core", "reporting"},
		},
		{
			ID:          "ROADMAP-002",
			Title:       "Développement de l'orchestrateur auto-roadmap-runner",
			Description: "Créer l'orchestrateur global qui exécute tous les scans, analyses, tests et rapports",
			Priority:    "high",
			Category:    "cmd",
			Status:      "open",
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
			Labels:      []string{"roadmap", "orchestration", "automation"},
		},
		{
			ID:          "ROADMAP-003",
			Title:       "Intégration CI/CD Pipeline",
			Description: "Créer le pipeline GitHub Actions pour l'automatisation complète",
			Priority:    "medium",
			Category:    "devops",
			Status:      "open",
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
			Labels:      []string{"ci-cd", "github-actions", "automation"},
		},
		{
			ID:          "ROADMAP-004",
			Title:       "Tests de validation globaux",
			Description: "Créer une suite de tests complète pour valider l'ensemble du système",
			Priority:    "high",
			Category:    "tests",
			Status:      "open",
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
			Labels:      []string{"testing", "validation", "quality"},
		},
		{
			ID:          "ROADMAP-005",
			Title:       "Documentation technique complète",
			Description: "Rédiger la documentation technique détaillée pour tous les modules",
			Priority:    "medium",
			Category:    "documentation",
			Status:      "open",
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
			Labels:      []string{"documentation", "technical", "guides"},
		},
		{
			ID:          "ROADMAP-006",
			Title:       "Scripts d'archivage et backup",
			Description: "Implémenter les scripts de sauvegarde automatique et d'archivage",
			Priority:    "medium",
			Category:    "devops",
			Status:      "open",
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
			Labels:      []string{"backup", "archival", "reliability"},
		},
	}
}

// convertIssuesToRequirements convertit les issues en exigences structurées
func convertIssuesToRequirements(issues []Issue) []Requirement {
	var requirements []Requirement

	for i, issue := range issues {
		requirement := Requirement{
			ID:           fmt.Sprintf("REQ-%03d", i+1),
			Name:         issue.Title,
			Description:  issue.Description,
			Priority:     issue.Priority,
			Category:     issue.Category,
			Source:       "issue",
			SourceID:     issue.ID,
			Status:       mapIssueStatusToRequirementStatus(issue.Status),
			CreatedAt:    issue.CreatedAt,
			Dependencies: extractDependencies(issue.Description),
		}
		requirements = append(requirements, requirement)
	}

	return requirements
}

// mapIssueStatusToRequirementStatus mappe le statut d'une issue vers le statut d'un besoin
func mapIssueStatusToRequirementStatus(issueStatus string) string {
	switch strings.ToLower(issueStatus) {
	case "open", "new":
		return "identified"
	case "in-progress", "assigned":
		return "in-development"
	case "closed", "resolved":
		return "implemented"
	case "blocked":
		return "blocked"
	default:
		return "identified"
	}
}

// extractDependencies extrait les dépendances d'une description (basique)
func extractDependencies(description string) []string {
	var dependencies []string

	// Rechercher des références simples comme "dépend de", "après", "requires"
	desc := strings.ToLower(description)
	if strings.Contains(desc, "core/scanmodules") {
		dependencies = append(dependencies, "REQ-001")
	}
	if strings.Contains(desc, "core/gapanalyzer") {
		dependencies = append(dependencies, "REQ-002")
	}
	if strings.Contains(desc, "tests") && strings.Contains(desc, "validation") {
		dependencies = append(dependencies, "REQ-004")
	}

	return dependencies
}

// analyzeRequirements effectue l'analyse des besoins
func analyzeRequirements(requirements []Requirement) RequirementsAnalysis {
	analysis := RequirementsAnalysis{
		AnalysisDate:      time.Now(),
		TotalRequirements: len(requirements),
		Requirements:      requirements,
		Categories:        make(map[string]int),
		Priorities:        make(map[string]int),
		Recommendations:   []string{},
	}

	// Analyser les catégories et priorités
	for _, req := range requirements {
		analysis.Categories[req.Category]++
		analysis.Priorities[req.Priority]++
	}

	// Générer des recommandations
	highPriorityCount := analysis.Priorities["high"]
	if highPriorityCount > 0 {
		analysis.Recommendations = append(analysis.Recommendations,
			fmt.Sprintf("PRIORITÉ: %d besoins haute priorité identifiés - traitement immédiat recommandé", highPriorityCount))
	}

	coreRequirements := analysis.Categories["core"]
	if coreRequirements > 0 {
		analysis.Recommendations = append(analysis.Recommendations,
			fmt.Sprintf("ARCHITECTURE: %d besoins core identifiés - base solide nécessaire", coreRequirements))
	}

	testRequirements := analysis.Categories["tests"]
	if testRequirements > 0 {
		analysis.Recommendations = append(analysis.Recommendations,
			fmt.Sprintf("QUALITÉ: %d besoins de tests identifiés - validation essentielle", testRequirements))
	}

	devopsRequirements := analysis.Categories["devops"]
	if devopsRequirements > 0 {
		analysis.Recommendations = append(analysis.Recommendations,
			fmt.Sprintf("DEVOPS: %d besoins d'infrastructure identifiés - automatisation clé", devopsRequirements))
	}

	// Générer le résumé
	analysis.Summary = fmt.Sprintf(
		"Analyse des besoins terminée: %d besoins identifiés. "+
			"Catégories principales: core(%d), tests(%d), devops(%d). "+
			"Priorités: haute(%d), moyenne(%d).",
		analysis.TotalRequirements,
		analysis.Categories["core"],
		analysis.Categories["tests"],
		analysis.Categories["devops"],
		analysis.Priorities["high"],
		analysis.Priorities["medium"])

	return analysis
}

// generateMarkdownReport génère un rapport Markdown des besoins
func generateMarkdownReport(analysis RequirementsAnalysis) string {
	var report strings.Builder

	report.WriteString("# 📋 Analyse des Besoins\n\n")
	report.WriteString(fmt.Sprintf("**Date d'analyse:** %s\n\n", analysis.AnalysisDate.Format("2006-01-02 15:04:05")))
	report.WriteString(fmt.Sprintf("**Résumé:** %s\n\n", analysis.Summary))

	// Métriques
	report.WriteString("## 📊 Métriques\n\n")
	report.WriteString(fmt.Sprintf("- **Total des besoins:** %d\n", analysis.TotalRequirements))
	report.WriteString(fmt.Sprintf("- **Issues analysées:** %d\n\n", analysis.TotalIssues))

	// Distribution par catégorie
	report.WriteString("### 📂 Distribution par catégorie\n\n")
	for category, count := range analysis.Categories {
		report.WriteString(fmt.Sprintf("- **%s:** %d besoins\n", category, count))
	}
	report.WriteString("\n")

	// Distribution par priorité
	report.WriteString("### ⚡ Distribution par priorité\n\n")
	for priority, count := range analysis.Priorities {
		report.WriteString(fmt.Sprintf("- **%s:** %d besoins\n", priority, count))
	}
	report.WriteString("\n")

	// Besoins détaillés
	report.WriteString("## 📝 Besoins Détaillés\n\n")
	for _, req := range analysis.Requirements {
		report.WriteString(fmt.Sprintf("### %s - %s\n\n", req.ID, req.Name))
		report.WriteString(fmt.Sprintf("- **Priorité:** %s\n", req.Priority))
		report.WriteString(fmt.Sprintf("- **Catégorie:** %s\n", req.Category))
		report.WriteString(fmt.Sprintf("- **Statut:** %s\n", req.Status))
		report.WriteString(fmt.Sprintf("- **Source:** %s (%s)\n", req.Source, req.SourceID))
		if len(req.Dependencies) > 0 {
			report.WriteString(fmt.Sprintf("- **Dépendances:** %s\n", strings.Join(req.Dependencies, ", ")))
		}
		report.WriteString(fmt.Sprintf("- **Description:** %s\n\n", req.Description))
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
	inputFile := flag.String("input", "issues.json", "Fichier JSON d'entrée contenant les issues")
	outputFile := flag.String("output", "besoins.json", "Fichier JSON de sortie pour les besoins")
	flag.Parse()

	fmt.Println("=== Analyse des besoins ===")
	fmt.Printf("📂 Fichier d'entrée: %s\n", *inputFile)
	fmt.Printf("📄 Fichier de sortie: %s\n", *outputFile)

	// Parser les issues
	issues, err := parseIssuesFromJSON(*inputFile)
	if err != nil {
		log.Fatalf("❌ Erreur lors du parsing des issues: %v", err)
	}

	fmt.Printf("📋 Issues chargées: %d\n", len(issues))

	// Convertir en besoins
	requirements := convertIssuesToRequirements(issues)
	fmt.Printf("🎯 Besoins identifiés: %d\n", len(requirements))

	// Analyser les besoins
	analysis := analyzeRequirements(requirements)
	analysis.TotalIssues = len(issues)

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
	markdownFile := "BESOINS_INITIAUX.md"
	err = ioutil.WriteFile(markdownFile, []byte(markdownReport), 0644)
	if err != nil {
		log.Printf("⚠️ Erreur lors de l'écriture du rapport Markdown %s: %v", markdownFile, err)
	}

	// Afficher le résumé
	fmt.Printf("\n✅ Analyse terminée avec succès!\n")
	fmt.Printf("📊 %s\n", analysis.Summary)
	fmt.Printf("📄 Fichiers générés:\n")
	fmt.Printf("   - %s (analyse JSON)\n", *outputFile)
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

	fmt.Printf("\n📈 Distribution des besoins:\n")
	for category, count := range analysis.Categories {
		fmt.Printf("   - %s: %d besoins\n", category, count)
	}
}
