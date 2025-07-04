package smart_variable_manager

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/smart-variable-manager/interfaces"
	"github.com/gerivdb/email-sender-1/development/managers/smart-variable-manager/internal/analyzer"
)

// SmartVariableSuggestionManager implements intelligent variable suggestion system
type SmartVariableSuggestionManager struct {
	// Base manager functionality
	initialized bool
	mu          sync.RWMutex

	// Core components
	contextAnalyzer  *analyzer.ContextAnalyzer
	suggestionEngine *SuggestionEngine
	validationEngine *ValidationEngine
	learningEngine   *LearningEngine

	// Data storage and caching
	analysisCache   map[string]*CachedAnalysis
	patternDatabase *PatternDatabase
	userPreferences *UserPreferencesStore

	// Configuration
	config             *Config
	performanceMetrics *PerformanceMetrics
}

// Config holds SmartVariableSuggestionManager configuration
type Config struct {
	CacheEnabled        bool          `json:"cache_enabled"`
	CacheExpiration     time.Duration `json:"cache_expiration"`
	MaxCacheSize        int           `json:"max_cache_size"`
	LearningEnabled     bool          `json:"learning_enabled"`
	SuggestionThreshold float64       `json:"suggestion_threshold"`
	MaxSuggestions      int           `json:"max_suggestions"`
	EnableValidation    bool          `json:"enable_validation"`
	EnableSecurity      bool          `json:"enable_security"`
}

// CachedAnalysis represents a cached context analysis
type CachedAnalysis struct {
	Analysis    *interfaces.ContextAnalysis `json:"analysis"`
	CachedAt    time.Time                   `json:"cached_at"`
	AccessCount int                         `json:"access_count"`
	LastAccess  time.Time                   `json:"last_access"`
}

// PatternDatabase stores and manages variable patterns
type PatternDatabase struct {
	patterns map[string]*interfaces.VariablePattern
	mu       sync.RWMutex
}

// UserPreferencesStore manages user preferences
type UserPreferencesStore struct {
	preferences map[string]*interfaces.UserPreferences
	mu          sync.RWMutex
}

// PerformanceMetrics tracks performance metrics
type PerformanceMetrics struct {
	TotalRequests       int64         `json:"total_requests"`
	AverageResponseTime time.Duration `json:"average_response_time"`
	CacheHitRate        float64       `json:"cache_hit_rate"`
	SuggestionAccuracy  float64       `json:"suggestion_accuracy"`
	LearningEfficiency  float64       `json:"learning_efficiency"`
	LastReset           time.Time     `json:"last_reset"`
}

// SuggestionEngine generates intelligent variable suggestions
type SuggestionEngine struct {
	patterns        *PatternDatabase
	preferences     *UserPreferencesStore
	contextAnalyzer *analyzer.ContextAnalyzer
}

// ValidationEngine validates variable usage and provides reports
type ValidationEngine struct {
	rules               []ValidationRule
	securityChecker     *SecurityChecker
	performanceAnalyzer *PerformanceAnalyzer
}

// LearningEngine learns from user feedback and usage patterns
type LearningEngine struct {
	patterns    *PatternDatabase
	preferences *UserPreferencesStore
	enabled     bool
}

// ValidationRule represents a validation rule
type ValidationRule struct {
	Name        string `json:"name"`
	Type        string `json:"type"` // naming, type, scope, security
	Rule        func(variable string, value interface{}, context *interfaces.ContextAnalysis) *interfaces.ValidationIssue
	Severity    string `json:"severity"`
	Enabled     bool   `json:"enabled"`
	Description string `json:"description"`
}

// SecurityChecker performs security analysis
type SecurityChecker struct {
	rules []SecurityRule
}

// SecurityRule represents a security validation rule
type SecurityRule struct {
	Name        string
	Check       func(variable string, value interface{}) *interfaces.SecurityVulnerability
	Severity    string
	Description string
}

// PerformanceAnalyzer analyzes performance implications
type PerformanceAnalyzer struct {
	metrics map[string]*PerformanceMetric
}

// PerformanceMetric represents a performance metric
type PerformanceMetric struct {
	Name      string
	Type      string // memory, cpu, io
	Threshold float64
	Impact    string // low, medium, high
}

// NewSmartVariableSuggestionManager creates a new smart variable suggestion manager
func NewSmartVariableSuggestionManager(config *Config) *SmartVariableSuggestionManager {
	if config == nil {
		config = &Config{
			CacheEnabled:        true,
			CacheExpiration:     30 * time.Minute,
			MaxCacheSize:        1000,
			LearningEnabled:     true,
			SuggestionThreshold: 0.7,
			MaxSuggestions:      10,
			EnableValidation:    true,
			EnableSecurity:      true,
		}
	}

	patternDB := &PatternDatabase{
		patterns: make(map[string]*interfaces.VariablePattern),
	}

	userPrefs := &UserPreferencesStore{
		preferences: make(map[string]*interfaces.UserPreferences),
	}

	suggestionEngine := &SuggestionEngine{
		patterns:        patternDB,
		preferences:     userPrefs,
		contextAnalyzer: analyzer.NewContextAnalyzer(),
	}

	validationEngine := &ValidationEngine{
		rules:               initializeValidationRules(),
		securityChecker:     NewSecurityChecker(),
		performanceAnalyzer: NewPerformanceAnalyzer(),
	}

	learningEngine := &LearningEngine{
		patterns:    patternDB,
		preferences: userPrefs,
		enabled:     config.LearningEnabled,
	}

	return &SmartVariableSuggestionManager{
		contextAnalyzer:  analyzer.NewContextAnalyzer(),
		suggestionEngine: suggestionEngine,
		validationEngine: validationEngine,
		learningEngine:   learningEngine,
		analysisCache:    make(map[string]*CachedAnalysis),
		patternDatabase:  patternDB,
		userPreferences:  userPrefs,
		config:           config,
		performanceMetrics: &PerformanceMetrics{
			LastReset: time.Now(),
		},
	}
}

// Initialize implements BaseManager.Initialize
func (svsm *SmartVariableSuggestionManager) Initialize(ctx context.Context) error {
	svsm.mu.Lock()
	defer svsm.mu.Unlock()

	if svsm.initialized {
		return nil
	}

	// Initialize pattern database with default patterns
	if err := svsm.initializePatternDatabase(); err != nil {
		return fmt.Errorf("failed to initialize pattern database: %w", err)
	}

	// Initialize user preferences with defaults
	if err := svsm.initializeUserPreferences(); err != nil {
		return fmt.Errorf("failed to initialize user preferences: %w", err)
	}

	// Start background tasks if enabled
	if svsm.config.LearningEnabled {
		go svsm.backgroundLearning(ctx)
	}

	go svsm.performanceMonitor(ctx)

	svsm.initialized = true
	return nil
}

// HealthCheck implements BaseManager.HealthCheck
func (svsm *SmartVariableSuggestionManager) HealthCheck(ctx context.Context) error {
	svsm.mu.RLock()
	defer svsm.mu.RUnlock()

	if !svsm.initialized {
		return fmt.Errorf("SmartVariableSuggestionManager not initialized")
	}

	// Check core components
	if svsm.contextAnalyzer == nil {
		return fmt.Errorf("context analyzer not available")
	}

	if svsm.suggestionEngine == nil {
		return fmt.Errorf("suggestion engine not available")
	}

	if svsm.validationEngine == nil {
		return fmt.Errorf("validation engine not available")
	}

	// Check cache health
	if svsm.config.CacheEnabled && len(svsm.analysisCache) > svsm.config.MaxCacheSize {
		return fmt.Errorf("analysis cache size exceeded limit")
	}

	return nil
}

// Cleanup implements BaseManager.Cleanup
func (svsm *SmartVariableSuggestionManager) Cleanup() error {
	svsm.mu.Lock()
	defer svsm.mu.Unlock()

	// Clear caches
	svsm.analysisCache = make(map[string]*CachedAnalysis)

	// Reset performance metrics
	svsm.performanceMetrics = &PerformanceMetrics{
		LastReset: time.Now(),
	}

	svsm.initialized = false
	return nil
}

// AnalyzeContext implements SmartVariableSuggestionManager.AnalyzeContext
func (svsm *SmartVariableSuggestionManager) AnalyzeContext(ctx context.Context, projectPath string) (*interfaces.ContextAnalysis, error) {
	startTime := time.Now()
	defer func() {
		svsm.updatePerformanceMetrics(time.Since(startTime))
	}()

	svsm.mu.RLock()
	if !svsm.initialized {
		svsm.mu.RUnlock()
		return nil, fmt.Errorf("SmartVariableSuggestionManager not initialized")
	}
	svsm.mu.RUnlock()

	// Check cache first
	if svsm.config.CacheEnabled {
		if cached := svsm.getCachedAnalysis(projectPath); cached != nil {
			return cached.Analysis, nil
		}
	}

	// Perform analysis
	analysis, err := svsm.contextAnalyzer.AnalyzeProject(ctx, projectPath)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze project context: %w", err)
	}

	// Cache the result
	if svsm.config.CacheEnabled {
		svsm.cacheAnalysis(projectPath, analysis)
	}

	return analysis, nil
}

// SuggestVariables implements SmartVariableSuggestionManager.SuggestVariables
func (svsm *SmartVariableSuggestionManager) SuggestVariables(ctx context.Context, context *interfaces.ContextAnalysis, template string) (*interfaces.VariableSuggestions, error) {
	startTime := time.Now()
	defer func() {
		svsm.updatePerformanceMetrics(time.Since(startTime))
	}()

	svsm.mu.RLock()
	if !svsm.initialized {
		svsm.mu.RUnlock()
		return nil, fmt.Errorf("SmartVariableSuggestionManager not initialized")
	}
	svsm.mu.RUnlock()

	return svsm.suggestionEngine.GenerateSuggestions(ctx, context, template)
}

// LearnFromUsage implements SmartVariableSuggestionManager.LearnFromUsage
func (svsm *SmartVariableSuggestionManager) LearnFromUsage(ctx context.Context, variables map[string]interface{}, outcome *interfaces.UsageOutcome) error {
	svsm.mu.RLock()
	if !svsm.initialized {
		svsm.mu.RUnlock()
		return fmt.Errorf("SmartVariableSuggestionManager not initialized")
	}
	learningEnabled := svsm.config.LearningEnabled
	svsm.mu.RUnlock()

	if !learningEnabled {
		return nil // Learning disabled
	}

	return svsm.learningEngine.LearnFromFeedback(ctx, variables, outcome)
}

// GetVariablePatterns implements SmartVariableSuggestionManager.GetVariablePatterns
func (svsm *SmartVariableSuggestionManager) GetVariablePatterns(ctx context.Context, filters *interfaces.PatternFilters) (*interfaces.VariablePatterns, error) {
	svsm.mu.RLock()
	if !svsm.initialized {
		svsm.mu.RUnlock()
		return nil, fmt.Errorf("SmartVariableSuggestionManager not initialized")
	}
	svsm.mu.RUnlock()

	return svsm.patternDatabase.GetPatterns(filters)
}

// ValidateVariableUsage implements SmartVariableSuggestionManager.ValidateVariableUsage
func (svsm *SmartVariableSuggestionManager) ValidateVariableUsage(ctx context.Context, variables map[string]interface{}) (*interfaces.ValidationReport, error) {
	startTime := time.Now()
	defer func() {
		svsm.updatePerformanceMetrics(time.Since(startTime))
	}()

	svsm.mu.RLock()
	if !svsm.initialized {
		svsm.mu.RUnlock()
		return nil, fmt.Errorf("SmartVariableSuggestionManager not initialized")
	}
	svsm.mu.RUnlock()

	return svsm.validationEngine.ValidateVariables(ctx, variables)
}

// Helper methods for internal functionality

func (svsm *SmartVariableSuggestionManager) getCachedAnalysis(projectPath string) *CachedAnalysis {
	svsm.mu.RLock()
	defer svsm.mu.RUnlock()

	cached, exists := svsm.analysisCache[projectPath]
	if !exists {
		return nil
	}

	// Check if cache is still valid
	if time.Since(cached.CachedAt) > svsm.config.CacheExpiration {
		delete(svsm.analysisCache, projectPath)
		return nil
	}

	// Update access statistics
	cached.AccessCount++
	cached.LastAccess = time.Now()

	return cached
}

func (svsm *SmartVariableSuggestionManager) cacheAnalysis(projectPath string, analysis *interfaces.ContextAnalysis) {
	svsm.mu.Lock()
	defer svsm.mu.Unlock()

	// Check cache size limit
	if len(svsm.analysisCache) >= svsm.config.MaxCacheSize {
		svsm.evictOldestCache()
	}

	svsm.analysisCache[projectPath] = &CachedAnalysis{
		Analysis:    analysis,
		CachedAt:    time.Now(),
		AccessCount: 0,
		LastAccess:  time.Now(),
	}
}

func (svsm *SmartVariableSuggestionManager) evictOldestCache() {
	var oldestKey string
	var oldestTime time.Time = time.Now()

	for key, cached := range svsm.analysisCache {
		if cached.LastAccess.Before(oldestTime) {
			oldestTime = cached.LastAccess
			oldestKey = key
		}
	}

	if oldestKey != "" {
		delete(svsm.analysisCache, oldestKey)
	}
}

func (svsm *SmartVariableSuggestionManager) updatePerformanceMetrics(responseTime time.Duration) {
	svsm.mu.Lock()
	defer svsm.mu.Unlock()

	svsm.performanceMetrics.TotalRequests++

	// Update average response time
	if svsm.performanceMetrics.AverageResponseTime == 0 {
		svsm.performanceMetrics.AverageResponseTime = responseTime
	} else {
		// Calculate running average
		total := float64(svsm.performanceMetrics.TotalRequests)
		avg := float64(svsm.performanceMetrics.AverageResponseTime)
		newAvg := (avg*(total-1) + float64(responseTime)) / total
		svsm.performanceMetrics.AverageResponseTime = time.Duration(newAvg)
	}
}

func (svsm *SmartVariableSuggestionManager) initializePatternDatabase() error {
	// Initialize with default patterns
	defaultPatterns := []*interfaces.VariablePattern{
		{
			Name:       "ConfigPattern",
			Type:       "config",
			Pattern:    "configuration",
			Context:    []string{"application"},
			Confidence: 0.9,
			Examples:   []string{"config", "cfg", "settings", "options"},
			Metadata:   map[string]interface{}{"category": "configuration"},
		},
		{
			Name:       "LoggerPattern",
			Type:       "logger",
			Pattern:    "logging",
			Context:    []string{"application"},
			Confidence: 0.95,
			Examples:   []string{"logger", "log", "logr"},
			Metadata:   map[string]interface{}{"category": "logging"},
		},
		{
			Name:       "DatabasePattern",
			Type:       "database",
			Pattern:    "data_access",
			Context:    []string{"persistence"},
			Confidence: 0.88,
			Examples:   []string{"db", "database", "conn", "connection"},
			Metadata:   map[string]interface{}{"category": "database"},
		},
	}

	for _, pattern := range defaultPatterns {
		svsm.patternDatabase.patterns[pattern.Name] = pattern
	}

	return nil
}

func (svsm *SmartVariableSuggestionManager) initializeUserPreferences() error { // Initialize with default user preferences
	defaultPrefs := &interfaces.UserPreferences{
		PreferredNaming:     "camelCase",
		PreferredTypes:      []string{"string", "int", "bool", "interface{}"},
		AvoidedPatterns:     []string{"temp", "tmp", "x", "y", "data"},
		CustomConventions:   []string{"go"},
		LearningEnabled:     true,
		SuggestionLevel:     "strict",
		PersonalizationData: map[string]interface{}{"initialized": true},
	}

	svsm.userPreferences.preferences["default"] = defaultPrefs
	return nil
}

func (svsm *SmartVariableSuggestionManager) backgroundLearning(ctx context.Context) {
	ticker := time.NewTicker(1 * time.Hour)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			svsm.learningEngine.PerformBatchLearning(ctx)
		}
	}
}

func (svsm *SmartVariableSuggestionManager) performanceMonitor(ctx context.Context) {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			svsm.updateCacheHitRate()
		}
	}
}

func (svsm *SmartVariableSuggestionManager) updateCacheHitRate() {
	svsm.mu.RLock()
	totalAccesses := int64(0)
	cacheHits := int64(0)

	for _, cached := range svsm.analysisCache {
		totalAccesses += int64(cached.AccessCount)
		if cached.AccessCount > 0 {
			cacheHits++
		}
	}
	svsm.mu.RUnlock()

	if totalAccesses > 0 {
		svsm.mu.Lock()
		svsm.performanceMetrics.CacheHitRate = float64(cacheHits) / float64(totalAccesses)
		svsm.mu.Unlock()
	}
}

// SuggestionEngine methods

func (se *SuggestionEngine) GenerateSuggestions(ctx context.Context, contextAnalysis *interfaces.ContextAnalysis, template string) (*interfaces.VariableSuggestions, error) {
	suggestions := &interfaces.VariableSuggestions{
		Suggestions: []interfaces.VariableSuggestion{},
		Context: interfaces.SuggestionContext{
			TemplateType:    "default",
			ProjectContext:  contextAnalysis.ProjectInfo.Name,
			UserPreferences: interfaces.UserPreferences{},
			CurrentVars:     []string{},
			Dependencies:    []string{},
			Framework:       contextAnalysis.ProjectInfo.Framework,
			Environment:     contextAnalysis.EnvironmentInfo.OperatingSystem,
		},
		GeneratedAt: time.Now(),
		Confidence:  0.0,
	}

	// Extract template variables
	templateVars := se.extractTemplateVariables(template)

	// Generate suggestions for each variable
	for _, varName := range templateVars {
		suggestion := se.generateVariableSuggestion(varName, contextAnalysis)
		if suggestion != nil {
			suggestions.Suggestions = append(suggestions.Suggestions, *suggestion)
		}
	}

	// Calculate overall confidence
	if len(suggestions.Suggestions) > 0 {
		totalConfidence := 0.0
		for _, sugg := range suggestions.Suggestions {
			totalConfidence += sugg.Confidence
		}
		suggestions.Confidence = totalConfidence / float64(len(suggestions.Suggestions))
	}

	return suggestions, nil
}

func (se *SuggestionEngine) extractTemplateVariables(template string) []string {
	var variables []string

	// Simple regex-based extraction for {{variable}} patterns
	start := 0
	for {
		openIdx := strings.Index(template[start:], "{{")
		if openIdx == -1 {
			break
		}
		openIdx += start

		closeIdx := strings.Index(template[openIdx:], "}}")
		if closeIdx == -1 {
			break
		}
		closeIdx += openIdx

		varName := strings.TrimSpace(template[openIdx+2 : closeIdx])
		if varName != "" {
			variables = append(variables, varName)
		}

		start = closeIdx + 2
	}

	return variables
}

func (se *SuggestionEngine) generateVariableSuggestion(varName string, context *interfaces.ContextAnalysis) *interfaces.VariableSuggestion {
	// Check if variable matches known patterns
	var bestPattern *interfaces.VariablePattern
	bestScore := 0.0

	for _, pattern := range se.patterns.patterns {
		score := se.calculatePatternMatch(varName, pattern)
		if score > bestScore {
			bestScore = score
			bestPattern = pattern
		}
	}

	if bestPattern == nil || bestScore < 0.5 {
		return nil
	}
	return &interfaces.VariableSuggestion{
		Name:        varName,
		Type:        bestPattern.Type,
		Confidence:  bestScore,
		Category:    bestPattern.Name,
		Description: fmt.Sprintf("Variable follows %s pattern", bestPattern.Name),
		Rationale:   fmt.Sprintf("Matched pattern with confidence %.2f", bestScore),
		Examples: []interfaces.UsageExample{
			{
				Code:        bestPattern.Examples[0],
				Description: "Example usage",
			},
		},
		Metadata: bestPattern.Metadata,
	}
}

func (se *SuggestionEngine) calculatePatternMatch(varName string, pattern *interfaces.VariablePattern) float64 {
	score := 0.0

	// Check direct name matches
	for _, example := range pattern.Examples {
		if strings.EqualFold(varName, example) {
			score += 0.9
		} else if strings.Contains(strings.ToLower(varName), strings.ToLower(example)) {
			score += 0.7
		}
	}

	// Normalize score
	if len(pattern.Examples) > 0 {
		score = score / float64(len(pattern.Examples))
	}

	return score
}

func (se *SuggestionEngine) generateAlternatives(varName string, pattern *interfaces.VariablePattern) []string {
	alternatives := make([]string, 0, len(pattern.Examples))

	for _, example := range pattern.Examples {
		if !strings.EqualFold(varName, example) {
			alternatives = append(alternatives, example)
		}
	}

	return alternatives
}

// ValidationEngine methods

func (ve *ValidationEngine) ValidateVariables(ctx context.Context, variables map[string]interface{}) (*interfaces.ValidationReport, error) {
	report := &interfaces.ValidationReport{
		Valid:       true,
		Issues:      []interfaces.ValidationIssue{},
		Suggestions: []interfaces.ImprovementSuggestion{},
		Performance: interfaces.PerformanceAnalysis{
			Issues: []interfaces.PerformanceIssue{},
		},
		Security:    interfaces.SecurityAnalysis{},
		GeneratedAt: time.Now(),
		Metadata:    make(map[string]interface{}),
	}

	// Run validation rules
	for _, rule := range ve.rules {
		if !rule.Enabled {
			continue
		}

		for varName, value := range variables {
			if issue := rule.Rule(varName, value, nil); issue != nil {
				report.Issues = append(report.Issues, *issue)
				if issue.Severity == "error" || issue.Severity == "critical" {
					report.Valid = false
				}
			}
		}
	}
	// Run security checks
	if ve.securityChecker != nil {
		for varName, value := range variables {
			if vulns := ve.securityChecker.CheckVariable(varName, value); len(vulns) > 0 {
				report.Security.Vulnerabilities = append(report.Security.Vulnerabilities, vulns...)
				report.Valid = false
			}
		}
	}
	// Run performance analysis
	if ve.performanceAnalyzer != nil {
		if perfIssues := ve.performanceAnalyzer.AnalyzeVariables(variables); len(perfIssues) > 0 {
			report.Performance.Issues = append(report.Performance.Issues, perfIssues...)
		}
	}

	return report, nil
}

// LearningEngine methods

func (le *LearningEngine) LearnFromFeedback(ctx context.Context, variables map[string]interface{}, outcome *interfaces.UsageOutcome) error {
	if !le.enabled {
		return nil
	}

	// Update patterns based on successful usage
	if outcome.Success {
		for varName, value := range variables {
			le.updatePatternSuccess(varName, value)
		}
	} else {
		// Learn from failures
		for varName, value := range variables {
			errorMsg := ""
			if len(outcome.ErrorMessages) > 0 {
				errorMsg = outcome.ErrorMessages[0]
			}
			le.updatePatternFailure(varName, value, errorMsg)
		}
	}

	return nil
}

func (le *LearningEngine) updatePatternSuccess(varName string, value interface{}) {
	// Implementation for learning from successful usage
	// This would update pattern confidence and usage statistics
}

func (le *LearningEngine) updatePatternFailure(varName string, value interface{}, errorMsg string) {
	// Implementation for learning from failures
	// This would adjust pattern weights and add negative examples
}

func (le *LearningEngine) PerformBatchLearning(ctx context.Context) error {
	// Implementation for batch learning from accumulated data
	return nil
}

// PatternDatabase methods

func (pdb *PatternDatabase) GetPatterns(filters *interfaces.PatternFilters) (*interfaces.VariablePatterns, error) {
	pdb.mu.RLock()
	defer pdb.mu.RUnlock()
	patterns := &interfaces.VariablePatterns{
		Patterns: []interfaces.VariablePattern{},
		Statistics: interfaces.PatternStatistics{
			TotalPatterns: len(pdb.patterns),
		},
		GeneratedAt: time.Now(),
		Metadata:    make(map[string]interface{}),
	}

	for _, pattern := range pdb.patterns {
		if filters == nil || pdb.matchesFilter(pattern, filters) {
			patterns.Patterns = append(patterns.Patterns, *pattern)
		}
	}

	return patterns, nil
}

func (pdb *PatternDatabase) matchesFilter(pattern *interfaces.VariablePattern, filters *interfaces.PatternFilters) bool {
	if len(filters.Categories) > 0 && !contains(filters.Categories, pattern.Type) {
		return false
	}
	if filters.MinConfidence > 0 && pattern.Confidence < filters.MinConfidence {
		return false
	}
	return true
}

// Factory functions

func initializeValidationRules() []ValidationRule {
	return []ValidationRule{
		{
			Name:        "NonEmptyNames",
			Type:        "naming",
			Severity:    "error",
			Enabled:     true,
			Description: "Variable names must not be empty",
			Rule: func(variable string, value interface{}, context *interfaces.ContextAnalysis) *interfaces.ValidationIssue {
				if variable == "" {
					return &interfaces.ValidationIssue{
						Variable:    variable,
						Type:        "naming",
						Severity:    "error",
						Message:     "Variable name cannot be empty",
						Suggestion:  "Provide a meaningful variable name",
						AutoFixable: false,
					}
				}
				return nil
			},
		},
		{
			Name:        "ReservedWords",
			Type:        "naming",
			Severity:    "warning",
			Enabled:     true,
			Description: "Variable names should not be reserved words",
			Rule: func(variable string, value interface{}, context *interfaces.ContextAnalysis) *interfaces.ValidationIssue {
				reserved := []string{"if", "for", "while", "func", "var", "const", "type", "package", "import"}
				for _, word := range reserved {
					if strings.EqualFold(variable, word) {
						return &interfaces.ValidationIssue{
							Variable: variable,
							Type:     "naming",
							Severity: "warning", Message: fmt.Sprintf("Variable name '%s' is a reserved word", variable),
							Suggestion:  fmt.Sprintf("Consider using '%s_var' or '%s_value'", variable, variable),
							AutoFixable: true,
						}
					}
				}
				return nil
			},
		},
	}
}

func NewSecurityChecker() *SecurityChecker {
	return &SecurityChecker{
		rules: []SecurityRule{
			{
				Name:        "SensitiveDataCheck",
				Severity:    "high",
				Description: "Check for sensitive data in variable names",
				Check: func(variable string, value interface{}) *interfaces.SecurityVulnerability {
					sensitive := []string{"password", "secret", "key", "token", "auth"}
					varLower := strings.ToLower(variable)
					for _, word := range sensitive {
						if strings.Contains(varLower, word) {
							return &interfaces.SecurityVulnerability{
								Variable: variable, Type: "sensitive_data",
								Severity:    "high",
								Description: fmt.Sprintf("Variable '%s' may contain sensitive data", variable),
								Impact:      "High risk of data exposure",
								Mitigation:  "Use secure storage mechanisms for sensitive data",
								CVSS:        7.5,
							}
						}
					}
					return nil
				},
			},
		},
	}
}

func (sc *SecurityChecker) CheckVariable(variable string, value interface{}) []interfaces.SecurityVulnerability {
	var vulnerabilities []interfaces.SecurityVulnerability

	for _, rule := range sc.rules {
		if vuln := rule.Check(variable, value); vuln != nil {
			vulnerabilities = append(vulnerabilities, *vuln)
		}
	}

	return vulnerabilities
}

func NewPerformanceAnalyzer() *PerformanceAnalyzer {
	return &PerformanceAnalyzer{
		metrics: map[string]*PerformanceMetric{
			"memory_usage": {
				Name:      "memory_usage",
				Type:      "memory",
				Threshold: 100.0, // MB
				Impact:    "medium",
			},
			"cpu_usage": {
				Name:      "cpu_usage",
				Type:      "cpu",
				Threshold: 80.0, // Percentage
				Impact:    "high",
			},
		},
	}
}

func (pa *PerformanceAnalyzer) AnalyzeVariables(variables map[string]interface{}) []interfaces.PerformanceIssue {
	var issues []interfaces.PerformanceIssue
	// Simple performance analysis based on variable count and types
	if len(variables) > 50 {
		issues = append(issues, interfaces.PerformanceIssue{
			Variable:    "multiple",
			Type:        "memory",
			Severity:    "medium",
			Description: fmt.Sprintf("High number of variables (%d) may impact performance", len(variables)),
			Impact:      "Medium impact on memory usage",
			Suggestion:  "Consider grouping related variables into structs",
			Confidence:  0.7,
		})
	}

	return issues
}

// Helper functions

// contains checks if a slice contains a specific string
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
