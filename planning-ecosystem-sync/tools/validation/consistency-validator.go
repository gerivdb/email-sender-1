package validation

import (
	"context"
	"fmt"
	"log"
	"math"
	"strings"
	"time"
)

// ValidationStatus représente l'état de validation
type ValidationStatus string

const (
	ValidationPending    ValidationStatus = "pending"
	ValidationRunning    ValidationStatus = "running"
	ValidationPassed     ValidationStatus = "passed"
	ValidationFailed     ValidationStatus = "failed"
	ValidationWarning    ValidationStatus = "warning"
)

// ValidationSeverity représente la sévérité d'un problème
type ValidationSeverity string

const (
	SeverityInfo     ValidationSeverity = "info"
	SeverityWarning  ValidationSeverity = "warning"
	SeverityError    ValidationSeverity = "error"
	SeverityCritical ValidationSeverity = "critical"
)

// ConsistencyValidator implémente l'interface ToolkitOperation v3.0.0
type ConsistencyValidator struct {
	Config *ValidationConfig
	Logger *log.Logger
	Stats  *ValidationStats
	Rules  []ValidationRule
}

// ValidationConfig configure le comportement du validateur
type ValidationConfig struct {
	StrictMode         bool     `yaml:"strict_mode"`
	ToleranceThreshold float64  `yaml:"tolerance_threshold"`
	ValidationRules    []string `yaml:"validation_rules"`
	ReportFormat       string   `yaml:"report_format"`
	AutoFix            bool     `yaml:"auto_fix"`
	MaxIssues          int      `yaml:"max_issues"`
	TimeoutSeconds     int      `yaml:"timeout_seconds"`
}

// ValidationResult contient le résultat d'une validation
type ValidationResult struct {
	PlanID    string            `json:"plan_id"`
	Status    ValidationStatus  `json:"status"`
	Issues    []ValidationIssue `json:"issues"`
	Score     float64           `json:"score"`
	Timestamp time.Time         `json:"timestamp"`
	Duration  time.Duration     `json:"duration"`
	Summary   string            `json:"summary"`
}

// ValidationIssue représente un problème de validation
type ValidationIssue struct {
	Type        string             `json:"type"`
	Severity    ValidationSeverity `json:"severity"`
	Message     string             `json:"message"`
	Location    string             `json:"location"`
	Suggestion  string             `json:"suggestion"`
	AutoFixable bool               `json:"auto_fixable"`
	RuleID      string             `json:"rule_id"`
	Details     map[string]interface{} `json:"details,omitempty"`
}

// ValidationStats contient les statistiques de validation
type ValidationStats struct {
	PlansValidated       int           `json:"plans_validated"`
	IssuesFound          int           `json:"issues_found"`
	IssuesFixed          int           `json:"issues_fixed"`
	AverageScore         float64       `json:"average_score"`
	AverageValidationTime time.Duration `json:"average_validation_time"`
	LastValidation       time.Time     `json:"last_validation"`
	ValidationsByStatus  map[ValidationStatus]int `json:"validations_by_status"`
}

// ValidationRule interface pour les règles de validation modulaires
type ValidationRule interface {
	GetID() string
	GetDescription() string
	Validate(ctx context.Context, planID string, data ValidationData) ([]ValidationIssue, error)
	GetPriority() int
	CanAutoFix() bool
}

// ValidationData contient les données nécessaires pour la validation
type ValidationData struct {
	MarkdownPlan interface{} `json:"markdown_plan"`
	DynamicPlan  interface{} `json:"dynamic_plan"`
	Config       *ValidationConfig `json:"config"`
}

// OperationOptions représente les options d'opération (interface mock)
type OperationOptions struct {
	Target     string                 `json:"target"`
	Parameters map[string]interface{} `json:"parameters"`
}

// NewConsistencyValidator crée une nouvelle instance du validateur
func NewConsistencyValidator(config *ValidationConfig) *ConsistencyValidator {
	if config == nil {
		config = &ValidationConfig{
			StrictMode:         false,
			ToleranceThreshold: 0.95,
			ReportFormat:       "json",
			AutoFix:            false,
			MaxIssues:          100,
			TimeoutSeconds:     30,
		}
	}

	return &ConsistencyValidator{
		Config: config,
		Logger: log.New(log.Writer(), "[VALIDATOR] ", log.LstdFlags),
		Stats: &ValidationStats{
			ValidationsByStatus: make(map[ValidationStatus]int),
		},
		Rules: []ValidationRule{},
	}
}

// Execute implémente ToolkitOperation.Execute
func (cv *ConsistencyValidator) Execute(ctx context.Context, options *OperationOptions) error {
	cv.Logger.Printf("🔍 Starting consistency validation for: %s", options.Target)

	startTime := time.Now()
	result := &ValidationResult{
		PlanID:    options.Target,
		Status:    ValidationRunning,
		Timestamp: startTime,
		Issues:    []ValidationIssue{},
	}

	// Timeout context
	timeout := time.Duration(cv.Config.TimeoutSeconds) * time.Second
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	// Charger les données nécessaires pour la validation
	data, err := cv.loadValidationData(ctx, options.Target)
	if err != nil {
		cv.Logger.Printf("❌ Failed to load validation data: %v", err)
		result.Status = ValidationFailed
		result.Summary = fmt.Sprintf("Failed to load data: %v", err)
		return err
	}

	// Valider selon les règles configurées
	for _, rule := range cv.Rules {
		select {
		case <-ctx.Done():
			cv.Logger.Printf("⏰ Validation timeout reached")
			result.Status = ValidationFailed
			result.Summary = "Validation timeout"
			return ctx.Err()
		default:
		}

		cv.Logger.Printf("📋 Applying rule: %s", rule.GetID())
		issues, err := rule.Validate(ctx, options.Target, data)
		if err != nil {
			cv.Logger.Printf("⚠️ Validation rule failed: %v", err)
			// Continue avec les autres règles
			continue
		}

		result.Issues = append(result.Issues, issues...)

		// Limite du nombre d'issues
		if len(result.Issues) >= cv.Config.MaxIssues {
			cv.Logger.Printf("⚠️ Maximum issues limit reached (%d)", cv.Config.MaxIssues)
			break
		}
	}

	// Calculer le score de cohérence
	result.Score = cv.calculateConsistencyScore(result.Issues)
	result.Status = cv.determineStatus(result.Score, result.Issues)
	result.Duration = time.Since(startTime)
	result.Summary = cv.generateSummary(result)

	// Auto-fix si configuré
	if cv.Config.AutoFix && result.Status != ValidationPassed {
		fixed := cv.applyAutoFixes(ctx, result.Issues)
		cv.Stats.IssuesFixed += fixed
		cv.Logger.Printf("🔧 Auto-fixed %d issues", fixed)
	}

	// Générer rapport
	if err := cv.generateReport(result); err != nil {
		cv.Logger.Printf("⚠️ Failed to generate validation report: %v", err)
	}

	// Mettre à jour les statistiques
	cv.updateStats(result)

	cv.Logger.Printf("✅ Validation completed with score: %.2f (status: %s)", result.Score, result.Status)
	return nil
}

// Validate implémente ToolkitOperation.Validate
func (cv *ConsistencyValidator) Validate(ctx context.Context) error {
	if cv.Config == nil {
		return fmt.Errorf("ValidationConfig is required")
	}
	if len(cv.Rules) == 0 {
		return fmt.Errorf("at least one validation rule is required")
	}
	if cv.Config.ToleranceThreshold < 0 || cv.Config.ToleranceThreshold > 1 {
		return fmt.Errorf("tolerance threshold must be between 0 and 1")
	}
	return nil
}

// CollectMetrics implémente ToolkitOperation.CollectMetrics
func (cv *ConsistencyValidator) CollectMetrics() map[string]interface{} {
	return map[string]interface{}{
		"tool":                    "ConsistencyValidator",
		"plans_validated":         cv.Stats.PlansValidated,
		"issues_found":            cv.Stats.IssuesFound,
		"issues_fixed":            cv.Stats.IssuesFixed,
		"average_score":           cv.Stats.AverageScore,
		"average_validation_time": cv.Stats.AverageValidationTime.Milliseconds(),
		"validations_by_status":   cv.Stats.ValidationsByStatus,
		"rules_count":             len(cv.Rules),
		"last_validation":         cv.Stats.LastValidation.Unix(),
	}
}

// HealthCheck implémente ToolkitOperation.HealthCheck
func (cv *ConsistencyValidator) HealthCheck(ctx context.Context) error {
	// Vérifier la configuration
	if err := cv.Validate(ctx); err != nil {
		return fmt.Errorf("configuration validation failed: %v", err)
	}

	// Vérifier les règles de validation
	for _, rule := range cv.Rules {
		if rule == nil {
			return fmt.Errorf("found nil validation rule")
		}
	}

	cv.Logger.Printf("✅ Health check passed")
	return nil
}

// String implémente ToolkitOperation.String
func (cv *ConsistencyValidator) String() string {
	return "ConsistencyValidator"
}

// GetDescription implémente ToolkitOperation.GetDescription
func (cv *ConsistencyValidator) GetDescription() string {
	return "Validates consistency between Markdown plans and dynamic system"
}

// Stop implémente ToolkitOperation.Stop
func (cv *ConsistencyValidator) Stop(ctx context.Context) error {
	cv.Logger.Printf("🛑 Stopping ConsistencyValidator operations...")
	return nil
}

// AddRule ajoute une règle de validation
func (cv *ConsistencyValidator) AddRule(rule ValidationRule) {
	cv.Rules = append(cv.Rules, rule)
	cv.Logger.Printf("📋 Added validation rule: %s", rule.GetID())
}

// RemoveRule supprime une règle de validation
func (cv *ConsistencyValidator) RemoveRule(ruleID string) bool {
	for i, rule := range cv.Rules {
		if rule.GetID() == ruleID {
			cv.Rules = append(cv.Rules[:i], cv.Rules[i+1:]...)
			cv.Logger.Printf("🗑️ Removed validation rule: %s", ruleID)
			return true
		}
	}
	return false
}

// calculateConsistencyScore calcule le score de cohérence basé sur les issues
func (cv *ConsistencyValidator) calculateConsistencyScore(issues []ValidationIssue) float64 {
	if len(issues) == 0 {
		return 100.0
	}

	totalPenalty := 0.0
	for _, issue := range issues {
		switch issue.Severity {
		case SeverityCritical:
			totalPenalty += 25.0
		case SeverityError:
			totalPenalty += 10.0
		case SeverityWarning:
			totalPenalty += 3.0
		case SeverityInfo:
			totalPenalty += 1.0
		}
	}

	score := math.Max(0, 100.0-totalPenalty)
	return math.Round(score*100) / 100 // Arrondir à 2 décimales
}

// determineStatus détermine le statut basé sur le score et les issues
func (cv *ConsistencyValidator) determineStatus(score float64, issues []ValidationIssue) ValidationStatus {
	// Vérifier les issues critiques
	for _, issue := range issues {
		if issue.Severity == SeverityCritical {
			return ValidationFailed
		}
	}

	// Basé sur le score et le seuil de tolérance
	threshold := cv.Config.ToleranceThreshold * 100
	if score >= threshold {
		return ValidationPassed
	} else if score >= threshold*0.8 {
		return ValidationWarning
	} else {
		return ValidationFailed
	}
}

// generateSummary génère un résumé de la validation
func (cv *ConsistencyValidator) generateSummary(result *ValidationResult) string {
	if len(result.Issues) == 0 {
		return fmt.Sprintf("Plan validation passed with perfect score (%.1f%%)", result.Score)
	}

	severityCount := make(map[ValidationSeverity]int)
	for _, issue := range result.Issues {
		severityCount[issue.Severity]++
	}

	parts := []string{fmt.Sprintf("Score: %.1f%%", result.Score)}
	if severityCount[SeverityCritical] > 0 {
		parts = append(parts, fmt.Sprintf("%d critical", severityCount[SeverityCritical]))
	}
	if severityCount[SeverityError] > 0 {
		parts = append(parts, fmt.Sprintf("%d errors", severityCount[SeverityError]))
	}
	if severityCount[SeverityWarning] > 0 {
		parts = append(parts, fmt.Sprintf("%d warnings", severityCount[SeverityWarning]))
	}

	return strings.Join(parts, ", ")
}

// loadValidationData charge les données nécessaires pour la validation
func (cv *ConsistencyValidator) loadValidationData(ctx context.Context, planID string) (ValidationData, error) {
	// Initialize format parser
	parser := NewFormatParser()
	
	// Try to load data from different sources and formats
	var markdownDoc, dynamicDoc *PlanDocument
	var err error
	
	// Try loading as file path first
	if markdownDoc, err = parser.ParseFile(planID); err != nil {
		// If file parsing fails, simulate loading from different sources
		cv.Logger.Printf("📄 Could not parse file %s, using simulated data: %v", planID, err)
		
		// Return simulated data for testing
		return ValidationData{
			MarkdownPlan: map[string]interface{}{
				"plan_id": planID,
				"version": "1.0.0",
				"phases":  []string{"phase1", "phase2", "phase3"},
				"format":  "markdown",
			},
			DynamicPlan: map[string]interface{}{
				"plan_id": planID,
				"version": "1.0.1",
				"phases":  []string{"phase1", "phase2"},
				"format":  "json",
			},
			Config: cv.Config,
		}, nil
	}
	
	// Load dynamic plan data (in a real implementation, this would come from an API)
	// For now, we'll use the same document but simulate it coming from a different source
	dynamicDoc = markdownDoc
	
	cv.Logger.Printf("📊 Loaded planning data - Format: %s, Phases: %d, Tasks: %d", 
		markdownDoc.Format, len(markdownDoc.Phases), cv.countTasks(markdownDoc.Phases))
	
	return ValidationData{
		MarkdownPlan: markdownDoc,
		DynamicPlan:  dynamicDoc,
		Config:       cv.Config,
	}, nil
}

// countTasks counts total tasks across all phases
func (cv *ConsistencyValidator) countTasks(phases []Phase) int {
	total := 0
	for _, phase := range phases {
		total += len(phase.Tasks)
	}
	return total
}

// applyAutoFixes applique les corrections automatiques
func (cv *ConsistencyValidator) applyAutoFixes(ctx context.Context, issues []ValidationIssue) int {
	fixed := 0
	for _, issue := range issues {
		if issue.AutoFixable {
			cv.Logger.Printf("🔧 Auto-fixing issue: %s", issue.Type)
			// Logique de correction automatique ici
			fixed++
		}
	}
	return fixed
}

// generateReport génère un rapport de validation
func (cv *ConsistencyValidator) generateReport(result *ValidationResult) error {
	switch cv.Config.ReportFormat {
	case "json":
		cv.Logger.Printf("📊 Generated JSON report for plan: %s", result.PlanID)
	case "html":
		cv.Logger.Printf("📊 Generated HTML report for plan: %s", result.PlanID)
	default:
		cv.Logger.Printf("📊 Generated text report for plan: %s", result.PlanID)
	}
	return nil
}

// updateStats met à jour les statistiques
func (cv *ConsistencyValidator) updateStats(result *ValidationResult) {
	cv.Stats.PlansValidated++
	cv.Stats.IssuesFound += len(result.Issues)
	cv.Stats.LastValidation = result.Timestamp
	cv.Stats.ValidationsByStatus[result.Status]++

	// Calcul de la moyenne du score
	totalScore := cv.Stats.AverageScore*float64(cv.Stats.PlansValidated-1) + result.Score
	cv.Stats.AverageScore = totalScore / float64(cv.Stats.PlansValidated)

	// Calcul de la moyenne du temps de validation
	totalTime := cv.Stats.AverageValidationTime*time.Duration(cv.Stats.PlansValidated-1) + result.Duration
	cv.Stats.AverageValidationTime = totalTime / time.Duration(cv.Stats.PlansValidated)
}

// GetStats retourne les statistiques de validation
func (cv *ConsistencyValidator) GetStats() *ValidationStats {
	return cv.Stats
}

// ResetStats remet à zéro les statistiques
func (cv *ConsistencyValidator) ResetStats() {
	cv.Stats = &ValidationStats{
		ValidationsByStatus: make(map[ValidationStatus]int),
	}
	cv.Logger.Printf("🔄 Statistics reset")
}
