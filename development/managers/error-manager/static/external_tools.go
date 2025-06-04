// Intégration Outils Externes - Phase 9.1.3
// Plan de développement v42 - Gestionnaire d'erreurs avancé
package static

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// ExternalTool représente un outil d'analyse externe
type ExternalTool struct {
	Name         string        `json:"name"`
	Command      string        `json:"command"`
	Args         []string      `json:"args"`
	WorkingDir   string        `json:"working_dir"`
	Timeout      time.Duration `json:"timeout"`
	OutputFormat string        `json:"output_format"` // json, text, sarif
	Enabled      bool          `json:"enabled"`
	Priority     int           `json:"priority"`
}

// ExternalToolResult représente le résultat d'un outil externe
type ExternalToolResult struct {
	Tool        string          `json:"tool"`
	Success     bool            `json:"success"`
	Duration    time.Duration   `json:"duration"`
	Issues      []ExternalIssue `json:"issues"`
	RawOutput   string          `json:"raw_output"`
	ErrorOutput string          `json:"error_output,omitempty"`
	ExitCode    int             `json:"exit_code"`
	ExecutedAt  time.Time       `json:"executed_at"`
}

// ExternalIssue représente une issue détectée par un outil externe
type ExternalIssue struct {
	File       string  `json:"file"`
	Line       int     `json:"line"`
	Column     int     `json:"column"`
	Rule       string  `json:"rule"`
	Message    string  `json:"message"`
	Severity   string  `json:"severity"`
	Category   string  `json:"category"`
	Source     string  `json:"source"`
	Confidence float64 `json:"confidence"`
	Suggestion string  `json:"suggestion,omitempty"`
}

// UnifiedReport représente un rapport consolidé de tous les outils
type UnifiedReport struct {
	ProjectPath        string                         `json:"project_path"`
	GeneratedAt        time.Time                      `json:"generated_at"`
	TotalDuration      time.Duration                  `json:"total_duration"`
	ToolResults        map[string]*ExternalToolResult `json:"tool_results"`
	ConsolidatedIssues []ConsolidatedIssue            `json:"consolidated_issues"`
	QualityMetrics     QualityMetrics                 `json:"quality_metrics"`
	Summary            ReportSummary                  `json:"summary"`
}

// ConsolidatedIssue représente une issue consolidée de plusieurs outils
type ConsolidatedIssue struct {
	File           string   `json:"file"`
	Line           int      `json:"line"`
	Column         int      `json:"column"`
	PrimaryRule    string   `json:"primary_rule"`
	PrimaryMessage string   `json:"primary_message"`
	Severity       string   `json:"severity"`
	Category       string   `json:"category"`
	Sources        []string `json:"sources"`
	Confidence     float64  `json:"confidence"`
	Suggestions    []string `json:"suggestions"`
	RelatedIssues  []string `json:"related_issues"`
}

// QualityMetrics représente les métriques de qualité globales
type QualityMetrics struct {
	OverallScore         float64            `json:"overall_score"`
	ComplexityScore      float64            `json:"complexity_score"`
	MaintainabilityIndex float64            `json:"maintainability_index"`
	TechnicalDebt        time.Duration      `json:"technical_debt"`
	TestCoverage         float64            `json:"test_coverage"`
	LinesOfCode          int                `json:"lines_of_code"`
	CyclomaticComplexity int                `json:"cyclomatic_complexity"`
	TotalIssues          int                `json:"total_issues"`
	IssuesBySeverity     map[string]int     `json:"issues_by_severity"`
	IssuesByCategory     map[string]int     `json:"issues_by_category"`
	TrendMetrics         map[string]float64 `json:"trend_metrics"`
}

// ReportSummary résume les résultats du rapport
type ReportSummary struct {
	ToolsExecuted   int            `json:"tools_executed"`
	ToolsSuccessful int            `json:"tools_successful"`
	TotalIssues     int            `json:"total_issues"`
	CriticalIssues  int            `json:"critical_issues"`
	HighIssues      int            `json:"high_issues"`
	MediumIssues    int            `json:"medium_issues"`
	LowIssues       int            `json:"low_issues"`
	TopCategories   []CategoryStat `json:"top_categories"`
	Recommendations []string       `json:"recommendations"`
}

// CategoryStat représente une statistique par catégorie
type CategoryStat struct {
	Category string `json:"category"`
	Count    int    `json:"count"`
	Severity string `json:"avg_severity"`
}

// ExternalToolsManager gère l'intégration avec les outils externes
type ExternalToolsManager struct {
	tools       map[string]*ExternalTool
	projectPath string
	outputDir   string
	timeout     time.Duration
}

// NewExternalToolsManager crée un nouveau gestionnaire d'outils externes
func NewExternalToolsManager(projectPath, outputDir string) *ExternalToolsManager {
	etm := &ExternalToolsManager{
		tools:       make(map[string]*ExternalTool),
		projectPath: projectPath,
		outputDir:   outputDir,
		timeout:     5 * time.Minute,
	}

	// Configuration des outils par défaut
	etm.setupDefaultTools()
	return etm
}

// setupDefaultTools configure les outils d'analyse par défaut
func (etm *ExternalToolsManager) setupDefaultTools() {
	// golangci-lint
	etm.tools["golangci-lint"] = &ExternalTool{
		Name:         "golangci-lint",
		Command:      "golangci-lint",
		Args:         []string{"run", "--out-format", "json", "./..."},
		WorkingDir:   etm.projectPath,
		Timeout:      3 * time.Minute,
		OutputFormat: "json",
		Enabled:      true,
		Priority:     1,
	}

	// staticcheck
	etm.tools["staticcheck"] = &ExternalTool{
		Name:         "staticcheck",
		Command:      "staticcheck",
		Args:         []string{"-f", "json", "./..."},
		WorkingDir:   etm.projectPath,
		Timeout:      2 * time.Minute,
		OutputFormat: "json",
		Enabled:      true,
		Priority:     2,
	}

	// go vet
	etm.tools["go-vet"] = &ExternalTool{
		Name:         "go-vet",
		Command:      "go",
		Args:         []string{"vet", "-json", "./..."},
		WorkingDir:   etm.projectPath,
		Timeout:      1 * time.Minute,
		OutputFormat: "json",
		Enabled:      true,
		Priority:     3,
	}

	// govulncheck pour sécurité
	etm.tools["govulncheck"] = &ExternalTool{
		Name:         "govulncheck",
		Command:      "govulncheck",
		Args:         []string{"-json", "./..."},
		WorkingDir:   etm.projectPath,
		Timeout:      2 * time.Minute,
		OutputFormat: "json",
		Enabled:      false, // Désactivé par défaut car optionnel
		Priority:     4,
	}

	// gosec pour sécurité
	etm.tools["gosec"] = &ExternalTool{
		Name:         "gosec",
		Command:      "gosec",
		Args:         []string{"-fmt", "json", "./..."},
		WorkingDir:   etm.projectPath,
		Timeout:      2 * time.Minute,
		OutputFormat: "json",
		Enabled:      false, // Désactivé par défaut car optionnel
		Priority:     5,
	}
}

// RunAllTools exécute tous les outils activés
func (etm *ExternalToolsManager) RunAllTools(ctx context.Context) (*UnifiedReport, error) {
	report := &UnifiedReport{
		ProjectPath: etm.projectPath,
		GeneratedAt: time.Now(),
		ToolResults: make(map[string]*ExternalToolResult),
		QualityMetrics: QualityMetrics{
			IssuesBySeverity: make(map[string]int),
			IssuesByCategory: make(map[string]int),
			TrendMetrics:     make(map[string]float64),
		},
	}

	startTime := time.Now()

	// Exécuter les outils par ordre de priorité
	for _, tool := range etm.getToolsByPriority() {
		if !tool.Enabled {
			continue
		}

		result, err := etm.runTool(ctx, tool)
		if err != nil {
			// Log l'erreur mais continue avec les autres outils
			result = &ExternalToolResult{
				Tool:        tool.Name,
				Success:     false,
				ErrorOutput: err.Error(),
				ExecutedAt:  time.Now(),
			}
		}

		report.ToolResults[tool.Name] = result
	}

	report.TotalDuration = time.Since(startTime)

	// Consolider les résultats
	err := etm.consolidateResults(report)
	if err != nil {
		return nil, fmt.Errorf("failed to consolidate results: %w", err)
	}

	// Calculer les métriques de qualité
	etm.calculateQualityMetrics(report)

	// Générer le résumé
	etm.generateSummary(report)

	return report, nil
}

// runTool exécute un outil spécifique
func (etm *ExternalToolsManager) runTool(ctx context.Context, tool *ExternalTool) (*ExternalToolResult, error) {
	result := &ExternalToolResult{
		Tool:       tool.Name,
		ExecutedAt: time.Now(),
	}

	startTime := time.Now()

	// Créer le contexte avec timeout
	toolCtx, cancel := context.WithTimeout(ctx, tool.Timeout)
	defer cancel()

	// Préparer la commande
	cmd := exec.CommandContext(toolCtx, tool.Command, tool.Args...)
	cmd.Dir = tool.WorkingDir

	// Capturer la sortie
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return result, fmt.Errorf("failed to create stdout pipe: %w", err)
	}

	stderr, err := cmd.StderrPipe()
	if err != nil {
		return result, fmt.Errorf("failed to create stderr pipe: %w", err)
	}

	// Démarrer la commande
	if err := cmd.Start(); err != nil {
		return result, fmt.Errorf("failed to start command: %w", err)
	}

	// Lire la sortie
	var stdoutOutput, stderrOutput strings.Builder

	go func() {
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			stdoutOutput.WriteString(scanner.Text() + "\n")
		}
	}()

	go func() {
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			stderrOutput.WriteString(scanner.Text() + "\n")
		}
	}()

	// Attendre la fin de la commande
	err = cmd.Wait()
	result.Duration = time.Since(startTime)
	result.RawOutput = stdoutOutput.String()
	result.ErrorOutput = stderrOutput.String()

	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			result.ExitCode = exitError.ExitCode()
		}
		// Certains outils retournent un code d'erreur même en cas de succès avec issues
		if result.ExitCode <= 2 && result.RawOutput != "" {
			result.Success = true
		} else {
			return result, fmt.Errorf("tool failed: %w", err)
		}
	} else {
		result.Success = true
		result.ExitCode = 0
	}

	// Parser la sortie selon le format
	if result.Success {
		issues, err := etm.parseToolOutput(tool, result.RawOutput)
		if err != nil {
			// Log l'erreur mais marque comme succès partiel
			result.ErrorOutput = fmt.Sprintf("Parse error: %v", err)
		} else {
			result.Issues = issues
		}
	}

	return result, nil
}

// parseToolOutput parse la sortie d'un outil selon son format
func (etm *ExternalToolsManager) parseToolOutput(tool *ExternalTool, output string) ([]ExternalIssue, error) {
	if strings.TrimSpace(output) == "" {
		return []ExternalIssue{}, nil
	}

	switch tool.Name {
	case "golangci-lint":
		return etm.parseGolangciLintOutput(output)
	case "staticcheck":
		return etm.parseStaticcheckOutput(output)
	case "go-vet":
		return etm.parseGoVetOutput(output)
	case "govulncheck":
		return etm.parseGovulncheckOutput(output)
	case "gosec":
		return etm.parseGosecOutput(output)
	default:
		return etm.parseGenericOutput(output)
	}
}

// parseGolangciLintOutput parse la sortie de golangci-lint
func (etm *ExternalToolsManager) parseGolangciLintOutput(output string) ([]ExternalIssue, error) {
	var result struct {
		Issues []struct {
			FromLinter  string   `json:"FromLinter"`
			Text        string   `json:"Text"`
			Severity    string   `json:"Severity"`
			SourceLines []string `json:"SourceLines"`
			Pos         struct {
				Filename string `json:"Filename"`
				Line     int    `json:"Line"`
				Column   int    `json:"Column"`
			} `json:"Pos"`
		} `json:"Issues"`
	}

	if err := json.Unmarshal([]byte(output), &result); err != nil {
		return nil, fmt.Errorf("failed to parse golangci-lint output: %w", err)
	}

	issues := make([]ExternalIssue, 0, len(result.Issues))
	for _, issue := range result.Issues {
		issues = append(issues, ExternalIssue{
			File:       issue.Pos.Filename,
			Line:       issue.Pos.Line,
			Column:     issue.Pos.Column,
			Rule:       issue.FromLinter,
			Message:    issue.Text,
			Severity:   etm.normalizeSeverity(issue.Severity),
			Category:   etm.categorizeLinterRule(issue.FromLinter),
			Source:     "golangci-lint",
			Confidence: 0.8,
		})
	}

	return issues, nil
}

// parseStaticcheckOutput parse la sortie de staticcheck
func (etm *ExternalToolsManager) parseStaticcheckOutput(output string) ([]ExternalIssue, error) {
	lines := strings.Split(strings.TrimSpace(output), "\n")
	issues := make([]ExternalIssue, 0, len(lines))

	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}

		var issue struct {
			Code     string `json:"code"`
			Severity string `json:"severity"`
			Location struct {
				File   string `json:"file"`
				Line   int    `json:"line"`
				Column int    `json:"column"`
			} `json:"location"`
			Message string `json:"message"`
		}

		if err := json.Unmarshal([]byte(line), &issue); err != nil {
			continue // Skip malformed lines
		}

		issues = append(issues, ExternalIssue{
			File:       issue.Location.File,
			Line:       issue.Location.Line,
			Column:     issue.Location.Column,
			Rule:       issue.Code,
			Message:    issue.Message,
			Severity:   etm.normalizeSeverity(issue.Severity),
			Category:   "static-analysis",
			Source:     "staticcheck",
			Confidence: 0.9,
		})
	}

	return issues, nil
}

// parseGoVetOutput parse la sortie de go vet
func (etm *ExternalToolsManager) parseGoVetOutput(output string) ([]ExternalIssue, error) {
	lines := strings.Split(strings.TrimSpace(output), "\n")
	issues := make([]ExternalIssue, 0, len(lines))

	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}

		var issue struct {
			Posn    string `json:"posn"`
			Message string `json:"message"`
		}

		if err := json.Unmarshal([]byte(line), &issue); err != nil {
			continue
		}

		// Parser la position (format: file:line:column)
		parts := strings.Split(issue.Posn, ":")
		if len(parts) < 2 {
			continue
		}

		file := parts[0]
		line := 0
		column := 0

		if len(parts) >= 2 {
			fmt.Sscanf(parts[1], "%d", &line)
		}
		if len(parts) >= 3 {
			fmt.Sscanf(parts[2], "%d", &column)
		}

		issues = append(issues, ExternalIssue{
			File:       file,
			Line:       line,
			Column:     column,
			Rule:       "vet",
			Message:    issue.Message,
			Severity:   "medium",
			Category:   "correctness",
			Source:     "go-vet",
			Confidence: 0.85,
		})
	}

	return issues, nil
}

// parseGovulncheckOutput parse la sortie de govulncheck
func (etm *ExternalToolsManager) parseGovulncheckOutput(output string) ([]ExternalIssue, error) {
	// Implémentation simplifiée pour govulncheck
	// En réalité, govulncheck a un format JSON complexe
	issues := make([]ExternalIssue, 0)

	if strings.Contains(output, "No vulnerabilities found") {
		return issues, nil
	}

	// TODO: Implémenter le parsing complet de govulncheck
	return issues, nil
}

// parseGosecOutput parse la sortie de gosec
func (etm *ExternalToolsManager) parseGosecOutput(output string) ([]ExternalIssue, error) {
	var result struct {
		Issues []struct {
			Severity   string `json:"severity"`
			Confidence string `json:"confidence"`
			RuleID     string `json:"rule_id"`
			Details    string `json:"details"`
			File       string `json:"file"`
			Code       string `json:"code"`
			Line       string `json:"line"`
			Column     string `json:"column"`
		} `json:"Issues"`
	}

	if err := json.Unmarshal([]byte(output), &result); err != nil {
		return nil, fmt.Errorf("failed to parse gosec output: %w", err)
	}

	issues := make([]ExternalIssue, 0, len(result.Issues))
	for _, issue := range result.Issues {
		line := 0
		column := 0
		fmt.Sscanf(issue.Line, "%d", &line)
		fmt.Sscanf(issue.Column, "%d", &column)

		confidence := 0.5
		switch issue.Confidence {
		case "HIGH":
			confidence = 0.9
		case "MEDIUM":
			confidence = 0.7
		case "LOW":
			confidence = 0.5
		}

		issues = append(issues, ExternalIssue{
			File:       issue.File,
			Line:       line,
			Column:     column,
			Rule:       issue.RuleID,
			Message:    issue.Details,
			Severity:   etm.normalizeSeverity(issue.Severity),
			Category:   "security",
			Source:     "gosec",
			Confidence: confidence,
		})
	}

	return issues, nil
}

// parseGenericOutput parse une sortie générique
func (etm *ExternalToolsManager) parseGenericOutput(output string) ([]ExternalIssue, error) {
	// Implémentation basique pour formats non reconnus
	lines := strings.Split(strings.TrimSpace(output), "\n")
	issues := make([]ExternalIssue, 0)

	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}

		// Essayer de détecter un format basique file:line:message
		if strings.Contains(line, ":") {
			parts := strings.SplitN(line, ":", 3)
			if len(parts) >= 3 {
				file := parts[0]
				line := 0
				fmt.Sscanf(parts[1], "%d", &line)
				message := parts[2]

				issues = append(issues, ExternalIssue{
					File:       file,
					Line:       line,
					Column:     0,
					Rule:       "unknown",
					Message:    strings.TrimSpace(message),
					Severity:   "medium",
					Category:   "unknown",
					Source:     "generic",
					Confidence: 0.3,
				})
			}
		}
	}

	return issues, nil
}

// getToolsByPriority retourne les outils triés par priorité
func (etm *ExternalToolsManager) getToolsByPriority() []*ExternalTool {
	tools := make([]*ExternalTool, 0, len(etm.tools))
	for _, tool := range etm.tools {
		tools = append(tools, tool)
	}

	// Tri par priorité (plus bas = plus prioritaire)
	for i := 0; i < len(tools)-1; i++ {
		for j := i + 1; j < len(tools); j++ {
			if tools[i].Priority > tools[j].Priority {
				tools[i], tools[j] = tools[j], tools[i]
			}
		}
	}

	return tools
}

// consolidateResults consolide les résultats de tous les outils
func (etm *ExternalToolsManager) consolidateResults(report *UnifiedReport) error {
	// Carte pour regrouper les issues par position
	issueMap := make(map[string][]ExternalIssue)

	// Collecter toutes les issues
	for _, result := range report.ToolResults {
		if !result.Success {
			continue
		}

		for _, issue := range result.Issues {
			key := fmt.Sprintf("%s:%d:%d", issue.File, issue.Line, issue.Column)
			issueMap[key] = append(issueMap[key], issue)
		}
	}

	// Consolider les issues par position
	consolidated := make([]ConsolidatedIssue, 0, len(issueMap))
	for _, issues := range issueMap {
		if len(issues) == 0 {
			continue
		}

		// Prendre la première issue comme primaire
		primary := issues[0]

		// Collecter les sources et suggestions
		sources := make([]string, 0, len(issues))
		suggestions := make([]string, 0)
		confidence := 0.0

		for _, issue := range issues {
			sources = append(sources, issue.Source)
			if issue.Suggestion != "" {
				suggestions = append(suggestions, issue.Suggestion)
			}
			confidence += issue.Confidence
		}

		confidence /= float64(len(issues))

		consolidated = append(consolidated, ConsolidatedIssue{
			File:           primary.File,
			Line:           primary.Line,
			Column:         primary.Column,
			PrimaryRule:    primary.Rule,
			PrimaryMessage: primary.Message,
			Severity:       etm.consolidateSeverity(issues),
			Category:       primary.Category,
			Sources:        sources,
			Confidence:     confidence,
			Suggestions:    suggestions,
		})
	}

	report.ConsolidatedIssues = consolidated
	return nil
}

// consolidateSeverity détermine la sévérité consolidée
func (etm *ExternalToolsManager) consolidateSeverity(issues []ExternalIssue) string {
	severityRank := map[string]int{
		"critical": 4,
		"high":     3,
		"medium":   2,
		"low":      1,
		"info":     0,
	}

	maxRank := 0
	maxSeverity := "info"

	for _, issue := range issues {
		if rank, exists := severityRank[issue.Severity]; exists && rank > maxRank {
			maxRank = rank
			maxSeverity = issue.Severity
		}
	}

	return maxSeverity
}

// calculateQualityMetrics calcule les métriques de qualité
func (etm *ExternalToolsManager) calculateQualityMetrics(report *UnifiedReport) {
	metrics := &report.QualityMetrics

	// Compter les issues par sévérité et catégorie
	for _, issue := range report.ConsolidatedIssues {
		metrics.IssuesBySeverity[issue.Severity]++
		metrics.IssuesByCategory[issue.Category]++
	}

	metrics.TotalIssues = len(report.ConsolidatedIssues)

	// Calculer le score de qualité global (0-100)
	criticalWeight := 10.0
	highWeight := 5.0
	mediumWeight := 2.0
	lowWeight := 1.0

	totalWeight := float64(metrics.IssuesBySeverity["critical"])*criticalWeight +
		float64(metrics.IssuesBySeverity["high"])*highWeight +
		float64(metrics.IssuesBySeverity["medium"])*mediumWeight +
		float64(metrics.IssuesBySeverity["low"])*lowWeight
	// Score inversement proportionnel au nombre d'issues pondérées
	if totalWeight == 0 {
		metrics.OverallScore = 100.0
	} else {
		metrics.OverallScore = Max(0, 100.0-totalWeight*2)
	}

	// Calculer la dette technique estimée (en minutes)
	debtMinutes := float64(metrics.IssuesBySeverity["critical"])*30 +
		float64(metrics.IssuesBySeverity["high"])*15 +
		float64(metrics.IssuesBySeverity["medium"])*5 +
		float64(metrics.IssuesBySeverity["low"])*2

	metrics.TechnicalDebt = time.Duration(debtMinutes) * time.Minute

	// TODO: Intégrer avec les métriques du AST analyzer pour complexity et maintainability
}

// generateSummary génère le résumé du rapport
func (etm *ExternalToolsManager) generateSummary(report *UnifiedReport) {
	summary := &report.Summary

	// Compter les outils
	summary.ToolsExecuted = len(report.ToolResults)
	for _, result := range report.ToolResults {
		if result.Success {
			summary.ToolsSuccessful++
		}
	}

	// Compter les issues par sévérité
	summary.TotalIssues = len(report.ConsolidatedIssues)
	for _, issue := range report.ConsolidatedIssues {
		switch issue.Severity {
		case "critical":
			summary.CriticalIssues++
		case "high":
			summary.HighIssues++
		case "medium":
			summary.MediumIssues++
		case "low":
			summary.LowIssues++
		}
	}

	// Top catégories
	categoryCount := make(map[string]int)
	for _, issue := range report.ConsolidatedIssues {
		categoryCount[issue.Category]++
	}

	summary.TopCategories = make([]CategoryStat, 0, len(categoryCount))
	for category, count := range categoryCount {
		summary.TopCategories = append(summary.TopCategories, CategoryStat{
			Category: category,
			Count:    count,
			Severity: "medium", // TODO: Calculer la sévérité moyenne
		})
	}

	// Générer des recommandations
	summary.Recommendations = etm.generateRecommendations(report)
}

// generateRecommendations génère des recommandations basées sur les résultats
func (etm *ExternalToolsManager) generateRecommendations(report *UnifiedReport) []string {
	recommendations := make([]string, 0)

	// Recommandations basées sur le score de qualité
	if report.QualityMetrics.OverallScore < 50 {
		recommendations = append(recommendations, "La qualité du code est critique. Priorisez la correction des erreurs de haute sévérité.")
	} else if report.QualityMetrics.OverallScore < 75 {
		recommendations = append(recommendations, "La qualité du code peut être améliorée. Focalisez sur les erreurs de sévérité moyenne et haute.")
	}

	// Recommandations basées sur la dette technique
	if report.QualityMetrics.TechnicalDebt > 2*time.Hour {
		recommendations = append(recommendations, "La dette technique est élevée. Planifiez du temps de refactoring.")
	}

	// Recommandations basées sur les catégories d'erreurs
	for category, count := range report.QualityMetrics.IssuesByCategory {
		if count > 10 {
			switch category {
			case "security":
				recommendations = append(recommendations, "Nombreuses issues de sécurité détectées. Auditez les pratiques de sécurité.")
			case "performance":
				recommendations = append(recommendations, "Issues de performance détectées. Considérez l'optimisation.")
			case "maintainability":
				recommendations = append(recommendations, "Issues de maintenabilité détectées. Améliorez la structure du code.")
			}
		}
	}

	return recommendations
}

// normalizeSeverity normalise les niveaux de sévérité
func (etm *ExternalToolsManager) normalizeSeverity(severity string) string {
	switch strings.ToLower(severity) {
	case "error", "critical", "blocker":
		return "critical"
	case "warning", "major", "high":
		return "high"
	case "info", "minor", "medium":
		return "medium"
	case "hint", "trivial", "low":
		return "low"
	default:
		return "medium"
	}
}

// categorizeLinterRule catégorise une règle de linter
func (etm *ExternalToolsManager) categorizeLinterRule(rule string) string {
	securityRules := []string{"gosec", "gas", "security"}
	performanceRules := []string{"prealloc", "maligned", "ineffassign"}
	styleRules := []string{"gofmt", "goimports", "golint", "revive"}
	bugRules := []string{"vet", "errcheck", "gocritic"}

	ruleLower := strings.ToLower(rule)

	for _, secRule := range securityRules {
		if strings.Contains(ruleLower, secRule) {
			return "security"
		}
	}

	for _, perfRule := range performanceRules {
		if strings.Contains(ruleLower, perfRule) {
			return "performance"
		}
	}

	for _, styleRule := range styleRules {
		if strings.Contains(ruleLower, styleRule) {
			return "style"
		}
	}

	for _, bugRule := range bugRules {
		if strings.Contains(ruleLower, bugRule) {
			return "bug_risk"
		}
	}

	return "maintenance"
}

// SaveReport sauvegarde le rapport dans un fichier
func (etm *ExternalToolsManager) SaveReport(report *UnifiedReport, format string) error {
	if err := os.MkdirAll(etm.outputDir, 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	timestamp := report.GeneratedAt.Format("20060102-150405")

	switch format {
	case "json":
		return etm.saveJSONReport(report, timestamp)
	case "html":
		return etm.saveHTMLReport(report, timestamp)
	default:
		return fmt.Errorf("unsupported format: %s", format)
	}
}

// saveJSONReport sauvegarde le rapport en JSON
func (etm *ExternalToolsManager) saveJSONReport(report *UnifiedReport, timestamp string) error {
	filename := filepath.Join(etm.outputDir, fmt.Sprintf("unified-report-%s.json", timestamp))

	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal report: %w", err)
	}

	return os.WriteFile(filename, data, 0644)
}

// saveHTMLReport sauvegarde le rapport en HTML
func (etm *ExternalToolsManager) saveHTMLReport(report *UnifiedReport, timestamp string) error {
	filename := filepath.Join(etm.outputDir, fmt.Sprintf("unified-report-%s.html", timestamp))

	// Template HTML basique
	htmlTemplate := `<!DOCTYPE html>
<html>
<head>
    <title>Unified Static Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f5f5f5; padding: 20px; border-radius: 5px; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background-color: #e9e9e9; border-radius: 5px; }
        .critical { color: #d32f2f; }
        .high { color: #f57c00; }
        .medium { color: #fbc02d; }
        .low { color: #388e3c; }
        .issue { margin: 10px 0; padding: 10px; border-left: 4px solid #ccc; }
        .issue.critical { border-left-color: #d32f2f; }
        .issue.high { border-left-color: #f57c00; }
        .issue.medium { border-left-color: #fbc02d; }
        .issue.low { border-left-color: #388e3c; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Unified Static Analysis Report</h1>
        <p>Generated: %s</p>
        <p>Project: %s</p>
        <p>Duration: %s</p>
    </div>

    <h2>Quality Metrics</h2>
    <div class="metric">Overall Score: %.1f/100</div>
    <div class="metric">Total Issues: %d</div>
    <div class="metric">Technical Debt: %s</div>

    <h2>Issues Summary</h2>
    <div class="metric critical">Critical: %d</div>
    <div class="metric high">High: %d</div>
    <div class="metric medium">Medium: %d</div>
    <div class="metric low">Low: %d</div>

    <h2>Issues</h2>
    %s

    <h2>Recommendations</h2>
    <ul>
    %s
    </ul>
</body>
</html>`

	// Générer le HTML des issues
	var issuesHTML strings.Builder
	for _, issue := range report.ConsolidatedIssues {
		issuesHTML.WriteString(fmt.Sprintf(
			`<div class="issue %s">
				<strong>%s:%d:%d</strong> - %s<br>
				<small>Rule: %s | Sources: %s | Confidence: %.2f</small>
			</div>`,
			issue.Severity,
			issue.File,
			issue.Line,
			issue.Column,
			issue.PrimaryMessage,
			issue.PrimaryRule,
			strings.Join(issue.Sources, ", "),
			issue.Confidence,
		))
	}

	// Générer le HTML des recommandations
	var recommendationsHTML strings.Builder
	for _, rec := range report.Summary.Recommendations {
		recommendationsHTML.WriteString(fmt.Sprintf("<li>%s</li>", rec))
	}

	html := fmt.Sprintf(
		htmlTemplate,
		report.GeneratedAt.Format("2006-01-02 15:04:05"),
		report.ProjectPath,
		report.TotalDuration,
		report.QualityMetrics.OverallScore,
		report.QualityMetrics.TotalIssues,
		report.QualityMetrics.TechnicalDebt,
		report.Summary.CriticalIssues,
		report.Summary.HighIssues,
		report.Summary.MediumIssues,
		report.Summary.LowIssues,
		issuesHTML.String(),
		recommendationsHTML.String(),
	)

	return os.WriteFile(filename, []byte(html), 0644)
}

// Max simulation pour éviter l'import math
func Max(a, b float64) float64 {
	if a > b {
		return a
	}
	return b
}
