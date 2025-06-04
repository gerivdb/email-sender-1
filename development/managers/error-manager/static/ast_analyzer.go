// Analyseur Statique Go Intégré - Phase 9.1
// Plan de développement v42 - Gestionnaire d'erreurs avancé
package static

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"go/types"
	"strings"
	"sync"
	"time"

	"golang.org/x/tools/go/packages"
)

// AnalysisResult représente le résultat d'une analyse statique
type AnalysisResult struct {
	FilePath     string          `json:"file_path"`
	Issues       []StaticIssue   `json:"issues"`
	Metrics      CodeMetrics     `json:"metrics"`
	Suggestions  []FixSuggestion `json:"suggestions"`
	AnalyzedAt   time.Time       `json:"analyzed_at"`
	Duration     time.Duration   `json:"duration"`
	Success      bool            `json:"success"`
	ErrorMessage string          `json:"error_message,omitempty"`
}

// StaticIssue représente une erreur statique détectée
type StaticIssue struct {
	Type         IssueType              `json:"type"`
	Severity     IssueSeverity          `json:"severity"`
	Message      string                 `json:"message"`
	Line         int                    `json:"line"`
	Column       int                    `json:"column"`
	Rule         string                 `json:"rule"`
	Category     IssueCategory          `json:"category"`
	FixAvailable bool                   `json:"fix_available"`
	Context      map[string]interface{} `json:"context"`
}

// CodeMetrics contient les métriques de qualité du code
type CodeMetrics struct {
	LinesOfCode          int     `json:"lines_of_code"`
	CyclomaticComplexity int     `json:"cyclomatic_complexity"`
	CognitiveComplexity  int     `json:"cognitive_complexity"`
	MaintainabilityIndex float64 `json:"maintainability_index"`
	TechnicalDebt        int     `json:"technical_debt_minutes"`
	DuplicationRatio     float64 `json:"duplication_ratio"`
	TestCoverage         float64 `json:"test_coverage"`
	QualityScore         float64 `json:"quality_score"`
}

// FixSuggestion contient une suggestion de correction
type FixSuggestion struct {
	ID           string      `json:"id"`
	Type         FixType     `json:"type"`
	Title        string      `json:"title"`
	Description  string      `json:"description"`
	Confidence   float64     `json:"confidence"`
	OriginalCode string      `json:"original_code"`
	FixedCode    string      `json:"fixed_code"`
	LineStart    int         `json:"line_start"`
	LineEnd      int         `json:"line_end"`
	Impact       ImpactLevel `json:"impact"`
	Automated    bool        `json:"automated"`
}

// Types énumérés
type IssueType string
type IssueSeverity string
type IssueCategory string
type FixType string
type ImpactLevel string

const (
	// Types d'issues
	IssueTypeSyntax      IssueType = "syntax"
	IssueTypeType        IssueType = "type"
	IssueTypeImport      IssueType = "import"
	IssueTypeReference   IssueType = "reference"
	IssueTypeStyle       IssueType = "style"
	IssueTypeComplexity  IssueType = "complexity"
	IssueTypeSecurity    IssueType = "security"
	IssueTypePerformance IssueType = "performance"

	// Sévérités
	SeverityError   IssueSeverity = "error"
	SeverityWarning IssueSeverity = "warning"
	SeverityInfo    IssueSeverity = "info"
	SeverityHint    IssueSeverity = "hint"

	// Catégories
	CategoryBugRisk     IssueCategory = "bug_risk"
	CategoryMaintenance IssueCategory = "maintenance"
	CategoryPerformance IssueCategory = "performance"
	CategorySecurity    IssueCategory = "security"
	CategoryStyle       IssueCategory = "style"

	// Types de fix
	FixTypeAutomatic FixType = "automatic"
	FixTypeManual    FixType = "manual"
	FixTypeSuggested FixType = "suggested"

	// Niveaux d'impact
	ImpactLow    ImpactLevel = "low"
	ImpactMedium ImpactLevel = "medium"
	ImpactHigh   ImpactLevel = "high"
)

// ASTAnalyzer représente l'analyseur statique principal
type ASTAnalyzer struct {
	fileSet    *token.FileSet
	packages   []*packages.Package
	rules      []LintRule
	config     AnalyzerConfig
	mutex      sync.RWMutex
	cache      map[string]*AnalysisResult
	statistics AnalyzerStats
}

// AnalyzerConfig contient la configuration de l'analyseur
type AnalyzerConfig struct {
	EnabledRules       []string `json:"enabled_rules"`
	DisabledRules      []string `json:"disabled_rules"`
	MaxComplexity      int      `json:"max_complexity"`
	MinMaintainability float64  `json:"min_maintainability"`
	EnableCache        bool     `json:"enable_cache"`
	CacheSize          int      `json:"cache_size"`
	EnableMetrics      bool     `json:"enable_metrics"`
	IncludeTests       bool     `json:"include_tests"`
}

// AnalyzerStats contient les statistiques d'analyse
type AnalyzerStats struct {
	FilesAnalyzed   int           `json:"files_analyzed"`
	IssuesFound     int           `json:"issues_found"`
	TotalDuration   time.Duration `json:"total_duration"`
	AverageDuration time.Duration `json:"average_duration"`
	CacheHits       int           `json:"cache_hits"`
	CacheMisses     int           `json:"cache_misses"`
	LastAnalysis    time.Time     `json:"last_analysis"`
}

// LintRule représente une règle de lint personnalisée
type LintRule interface {
	Name() string
	Description() string
	Category() IssueCategory
	Severity() IssueSeverity
	Check(file *ast.File, fset *token.FileSet, info *types.Info) []StaticIssue
}

// NewASTAnalyzer crée une nouvelle instance de l'analyseur
func NewASTAnalyzer(config AnalyzerConfig) *ASTAnalyzer {
	analyzer := &ASTAnalyzer{
		fileSet:    token.NewFileSet(),
		rules:      make([]LintRule, 0),
		config:     config,
		cache:      make(map[string]*AnalysisResult),
		statistics: AnalyzerStats{},
	}

	// Charger les règles par défaut
	analyzer.loadDefaultRules()

	return analyzer
}

// AnalyzeFile analyse un fichier Go spécifique
func (a *ASTAnalyzer) AnalyzeFile(filePath string) (*AnalysisResult, error) {
	startTime := time.Now()

	// Vérifier le cache
	if a.config.EnableCache {
		if cached := a.getCachedResult(filePath); cached != nil {
			a.statistics.CacheHits++
			return cached, nil
		}
		a.statistics.CacheMisses++
	}

	// Parser le fichier
	src, err := parser.ParseFile(a.fileSet, filePath, nil, parser.ParseComments)
	if err != nil {
		return &AnalysisResult{
			FilePath:     filePath,
			Success:      false,
			ErrorMessage: fmt.Sprintf("Parse error: %v", err),
			AnalyzedAt:   time.Now(),
			Duration:     time.Since(startTime),
		}, err
	}

	// Analyser les types
	info := &types.Info{
		Types: make(map[ast.Expr]types.TypeAndValue),
		Defs:  make(map[*ast.Ident]types.Object),
		Uses:  make(map[*ast.Ident]types.Object),
	}

	// Exécuter les règles de lint
	issues := make([]StaticIssue, 0)
	for _, rule := range a.rules {
		if a.isRuleEnabled(rule.Name()) {
			ruleIssues := rule.Check(src, a.fileSet, info)
			issues = append(issues, ruleIssues...)
		}
	}

	// Calculer les métriques
	metrics := a.calculateMetrics(src, a.fileSet)

	// Générer les suggestions
	suggestions := a.generateSuggestions(src, issues, a.fileSet)

	result := &AnalysisResult{
		FilePath:    filePath,
		Issues:      issues,
		Metrics:     metrics,
		Suggestions: suggestions,
		AnalyzedAt:  time.Now(),
		Duration:    time.Since(startTime),
		Success:     true,
	}

	// Mettre en cache
	if a.config.EnableCache {
		a.setCachedResult(filePath, result)
	}

	// Mettre à jour les statistiques
	a.updateStatistics(result)

	return result, nil
}

// AnalyzeProject analyse tout un projet Go
func (a *ASTAnalyzer) AnalyzeProject(projectPath string) ([]*AnalysisResult, error) {
	// Charger le projet avec go/packages
	cfg := &packages.Config{
		Mode: packages.NeedFiles | packages.NeedSyntax | packages.NeedTypes | packages.NeedTypesInfo,
		Dir:  projectPath,
	}

	pkgs, err := packages.Load(cfg, "./...")
	if err != nil {
		return nil, fmt.Errorf("failed to load packages: %w", err)
	}

	a.packages = pkgs

	var results []*AnalysisResult
	var mutex sync.Mutex
	var wg sync.WaitGroup

	// Analyser chaque fichier en parallèle
	for _, pkg := range pkgs {
		for _, file := range pkg.GoFiles {
			if !a.config.IncludeTests && strings.HasSuffix(file, "_test.go") {
				continue
			}

			wg.Add(1)
			go func(filePath string) {
				defer wg.Done()

				result, err := a.AnalyzeFile(filePath)
				if err == nil {
					mutex.Lock()
					results = append(results, result)
					mutex.Unlock()
				}
			}(file)
		}
	}

	wg.Wait()
	return results, nil
}

// calculateMetrics calcule les métriques de qualité du code
func (a *ASTAnalyzer) calculateMetrics(file *ast.File, fset *token.FileSet) CodeMetrics {
	metrics := CodeMetrics{}

	// Compter les lignes de code
	start := fset.Position(file.Pos())
	end := fset.Position(file.End())
	metrics.LinesOfCode = end.Line - start.Line + 1

	// Calculer la complexité cyclomatique
	complexity := a.calculateCyclomaticComplexity(file)
	metrics.CyclomaticComplexity = complexity

	// Calculer la complexité cognitive
	metrics.CognitiveComplexity = a.calculateCognitiveComplexity(file)

	// Calculer l'indice de maintenabilité
	metrics.MaintainabilityIndex = a.calculateMaintainabilityIndex(metrics)

	// Estimer la dette technique
	metrics.TechnicalDebt = a.estimateTechnicalDebt(metrics)

	// Calculer le score de qualité global
	metrics.QualityScore = a.calculateQualityScore(metrics)

	return metrics
}

// calculateCyclomaticComplexity calcule la complexité cyclomatique
func (a *ASTAnalyzer) calculateCyclomaticComplexity(file *ast.File) int {
	complexity := 1 // Base complexity

	ast.Inspect(file, func(node ast.Node) bool {
		switch node.(type) {
		case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt, *ast.SwitchStmt,
			*ast.TypeSwitchStmt, *ast.SelectStmt:
			complexity++
		case *ast.CaseClause:
			complexity++
		}
		return true
	})

	return complexity
}

// calculateCognitiveComplexity calcule la complexité cognitive
func (a *ASTAnalyzer) calculateCognitiveComplexity(file *ast.File) int {
	complexity := 0
	nesting := 0

	ast.Inspect(file, func(node ast.Node) bool {
		switch n := node.(type) {
		case *ast.IfStmt:
			complexity += 1 + nesting
			nesting++
		case *ast.ForStmt, *ast.RangeStmt:
			complexity += 1 + nesting
			nesting++
		case *ast.SwitchStmt, *ast.TypeSwitchStmt:
			complexity += 1 + nesting
			nesting++
		case *ast.FuncDecl:
			if n.Body != nil {
				nesting = 0
			}
		}
		return true
	})

	return complexity
}

// calculateMaintainabilityIndex calcule l'indice de maintenabilité
func (a *ASTAnalyzer) calculateMaintainabilityIndex(metrics CodeMetrics) float64 {
	// Formule simplifiée de l'indice de maintenabilité
	// MI = 171 - 5.2 * ln(Halstead Volume) - 0.23 * (Cyclomatic Complexity) - 16.2 * ln(Lines of Code)

	// Approximation basée sur les métriques disponibles
	base := 100.0
	complexityPenalty := float64(metrics.CyclomaticComplexity) * 2.5
	sizePenalty := float64(metrics.LinesOfCode) * 0.1

	index := base - complexityPenalty - sizePenalty
	if index < 0 {
		index = 0
	}
	if index > 100 {
		index = 100
	}

	return index
}

// estimateTechnicalDebt estime la dette technique en minutes
func (a *ASTAnalyzer) estimateTechnicalDebt(metrics CodeMetrics) int {
	debt := 0

	// Pénalité pour complexité élevée
	if metrics.CyclomaticComplexity > 10 {
		debt += (metrics.CyclomaticComplexity - 10) * 30
	}

	// Pénalité pour maintenabilité faible
	if metrics.MaintainabilityIndex < 50 {
		debt += int((50 - metrics.MaintainabilityIndex) * 5)
	}

	return debt
}

// calculateQualityScore calcule un score de qualité global
func (a *ASTAnalyzer) calculateQualityScore(metrics CodeMetrics) float64 {
	score := 100.0

	// Facteurs de pénalité
	if metrics.CyclomaticComplexity > 10 {
		score -= float64(metrics.CyclomaticComplexity-10) * 5
	}

	if metrics.MaintainabilityIndex < 70 {
		score -= (70 - metrics.MaintainabilityIndex) * 0.5
	}

	if score < 0 {
		score = 0
	}

	return score
}

// generateSuggestions génère des suggestions de correction
func (a *ASTAnalyzer) generateSuggestions(file *ast.File, issues []StaticIssue, fset *token.FileSet) []FixSuggestion {
	suggestions := make([]FixSuggestion, 0)

	for _, issue := range issues {
		switch issue.Type {
		case IssueTypeComplexity:
			suggestions = append(suggestions, FixSuggestion{
				ID:          fmt.Sprintf("fix_%s_%d", issue.Type, issue.Line),
				Type:        FixTypeSuggested,
				Title:       "Reduce Complexity",
				Description: "Consider breaking this function into smaller functions",
				Confidence:  0.7,
				LineStart:   issue.Line,
				LineEnd:     issue.Line,
				Impact:      ImpactMedium,
				Automated:   false,
			})
		case IssueTypeStyle:
			suggestions = append(suggestions, FixSuggestion{
				ID:          fmt.Sprintf("fix_%s_%d", issue.Type, issue.Line),
				Type:        FixTypeAutomatic,
				Title:       "Fix Style Issue",
				Description: "Automatically format according to Go standards",
				Confidence:  0.95,
				LineStart:   issue.Line,
				LineEnd:     issue.Line,
				Impact:      ImpactLow,
				Automated:   true,
			})
		}
	}

	return suggestions
}

// Méthodes de cache
func (a *ASTAnalyzer) getCachedResult(filePath string) *AnalysisResult {
	a.mutex.RLock()
	defer a.mutex.RUnlock()

	result, exists := a.cache[filePath]
	if !exists {
		return nil
	}

	// Vérifier la fraîcheur du cache (par exemple, 1 heure)
	if time.Since(result.AnalyzedAt) > time.Hour {
		return nil
	}

	return result
}

func (a *ASTAnalyzer) setCachedResult(filePath string, result *AnalysisResult) {
	a.mutex.Lock()
	defer a.mutex.Unlock()

	// Limite de taille du cache
	if len(a.cache) >= a.config.CacheSize {
		// Supprimer l'entrée la plus ancienne
		var oldestKey string
		var oldestTime time.Time = time.Now()

		for key, cached := range a.cache {
			if cached.AnalyzedAt.Before(oldestTime) {
				oldestTime = cached.AnalyzedAt
				oldestKey = key
			}
		}

		if oldestKey != "" {
			delete(a.cache, oldestKey)
		}
	}

	a.cache[filePath] = result
}

// updateStatistics met à jour les statistiques de l'analyseur
func (a *ASTAnalyzer) updateStatistics(result *AnalysisResult) {
	a.mutex.Lock()
	defer a.mutex.Unlock()

	a.statistics.FilesAnalyzed++
	a.statistics.IssuesFound += len(result.Issues)
	a.statistics.TotalDuration += result.Duration
	a.statistics.AverageDuration = a.statistics.TotalDuration / time.Duration(a.statistics.FilesAnalyzed)
	a.statistics.LastAnalysis = result.AnalyzedAt
}

// isRuleEnabled vérifie si une règle est activée
func (a *ASTAnalyzer) isRuleEnabled(ruleName string) bool {
	// Vérifier les règles désactivées
	for _, disabled := range a.config.DisabledRules {
		if disabled == ruleName {
			return false
		}
	}

	// Si des règles spécifiques sont activées, vérifier la liste
	if len(a.config.EnabledRules) > 0 {
		for _, enabled := range a.config.EnabledRules {
			if enabled == ruleName {
				return true
			}
		}
		return false
	}

	return true
}

// loadDefaultRules charge les règles de lint par défaut
func (a *ASTAnalyzer) loadDefaultRules() {
	// Ajouter les règles par défaut ici
	// Ces règles seront implémentées dans les micro-étapes suivantes
}

// GetStatistics retourne les statistiques actuelles
func (a *ASTAnalyzer) GetStatistics() AnalyzerStats {
	a.mutex.RLock()
	defer a.mutex.RUnlock()
	return a.statistics
}

// ClearCache vide le cache d'analyse
func (a *ASTAnalyzer) ClearCache() {
	a.mutex.Lock()
	defer a.mutex.Unlock()
	a.cache = make(map[string]*AnalysisResult)
}

// DefaultConfig retourne une configuration par défaut
func DefaultConfig() AnalyzerConfig {
	return AnalyzerConfig{
		EnabledRules:       []string{},
		DisabledRules:      []string{},
		MaxComplexity:      10,
		MinMaintainability: 70.0,
		EnableCache:        true,
		CacheSize:          100,
		EnableMetrics:      true,
		IncludeTests:       false,
	}
}
