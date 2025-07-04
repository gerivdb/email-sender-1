package ai_template_manager

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/ai-template-manager/interfaces"
	"github.com/gerivdb/email-sender-1/development/managers/ai-template-manager/internal/ai"
)

// AITemplateManager implements the AI-powered template management system
type AITemplateManager struct {
	// Base manager functionality
	initialized bool
	mu          sync.RWMutex

	// AI components
	patternProcessor *ai.PatternProcessor
	similarityScorer *ai.SimilarityScorer

	// Template storage and cache
	templates     map[string]*interfaces.Template
	templateCache map[string]*CachedTemplate

	// Configuration and state
	config           *Config
	performanceStats *PerformanceStats
}

// Config holds AITemplateManager configuration
type Config struct {
	CacheEnabled    bool          `json:"cache_enabled"`
	CacheExpiration time.Duration `json:"cache_expiration"`
	MaxCacheSize    int           `json:"max_cache_size"`
	AnalysisDepth   int           `json:"analysis_depth"`
	TemplateDir     string        `json:"template_dir"`
	EnableMetrics   bool          `json:"enable_metrics"`
}

// CachedTemplate represents a cached template with metadata
type CachedTemplate struct {
	Template    *interfaces.Template `json:"template"`
	CachedAt    time.Time            `json:"cached_at"`
	AccessCount int                  `json:"access_count"`
	LastAccess  time.Time            `json:"last_access"`
}

// PerformanceStats tracks performance metrics
type PerformanceStats struct {
	TotalProcessed int64         `json:"total_processed"`
	AverageTime    time.Duration `json:"average_time"`
	CacheHitRate   float64       `json:"cache_hit_rate"`
	ErrorRate      float64       `json:"error_rate"`
	LastReset      time.Time     `json:"last_reset"`
}

// NewAITemplateManager creates a new AI template manager instance
func NewAITemplateManager(config *Config) *AITemplateManager {
	if config == nil {
		config = &Config{
			CacheEnabled:    true,
			CacheExpiration: 30 * time.Minute,
			MaxCacheSize:    1000,
			AnalysisDepth:   5,
			EnableMetrics:   true,
		}
	}

	return &AITemplateManager{
		patternProcessor: ai.NewPatternProcessor(),
		similarityScorer: ai.NewSimilarityScorer(),
		templates:        make(map[string]*interfaces.Template),
		templateCache:    make(map[string]*CachedTemplate),
		config:           config,
		performanceStats: &PerformanceStats{
			LastReset: time.Now(),
		},
	}
}

// Initialize implements BaseManager.Initialize
func (atm *AITemplateManager) Initialize(ctx context.Context) error {
	atm.mu.Lock()
	defer atm.mu.Unlock()

	if atm.initialized {
		return nil
	}

	// Load existing templates
	if atm.config.TemplateDir != "" {
		if err := atm.loadTemplatesFromDirectory(atm.config.TemplateDir); err != nil {
			return fmt.Errorf("failed to load templates: %w", err)
		}
	}

	// Initialize performance tracking
	if atm.config.EnableMetrics {
		go atm.performanceMonitor(ctx)
	}

	atm.initialized = true
	return nil
}

// HealthCheck implements BaseManager.HealthCheck
func (atm *AITemplateManager) HealthCheck(ctx context.Context) error {
	atm.mu.RLock()
	defer atm.mu.RUnlock()

	if !atm.initialized {
		return fmt.Errorf("AITemplateManager not initialized")
	}

	// Check if components are responsive
	if atm.patternProcessor == nil {
		return fmt.Errorf("pattern processor not available")
	}

	if atm.similarityScorer == nil {
		return fmt.Errorf("similarity scorer not available")
	}

	// Check cache health
	if atm.config.CacheEnabled && len(atm.templateCache) > atm.config.MaxCacheSize {
		return fmt.Errorf("template cache size exceeded limit")
	}

	return nil
}

// Cleanup implements BaseManager.Cleanup
func (atm *AITemplateManager) Cleanup() error {
	atm.mu.Lock()
	defer atm.mu.Unlock()

	// Clear caches
	atm.templateCache = make(map[string]*CachedTemplate)
	atm.templates = make(map[string]*interfaces.Template)

	// Reset performance stats
	atm.performanceStats = &PerformanceStats{
		LastReset: time.Now(),
	}

	atm.initialized = false
	return nil
}

// ProcessTemplate implements AITemplateManager.ProcessTemplate
func (atm *AITemplateManager) ProcessTemplate(templatePath string, vars map[string]interface{}) (*interfaces.Template, error) {
	startTime := time.Now()
	atm.mu.Lock()
	defer atm.mu.Unlock()

	// Check cache first
	if atm.config.CacheEnabled {
		cacheKey := atm.generateCacheKey(templatePath, vars)
		if cached, exists := atm.templateCache[cacheKey]; exists {
			if time.Since(cached.CachedAt) < atm.config.CacheExpiration {
				cached.AccessCount++
				cached.LastAccess = time.Now()
				atm.updatePerformanceStats(startTime, true, false)
				return cached.Template, nil
			}
			// Cache expired, remove it
			delete(atm.templateCache, cacheKey)
		}
	}

	// Load template content
	content, err := os.ReadFile(templatePath)
	if err != nil {
		atm.updatePerformanceStats(startTime, false, true)
		return nil, fmt.Errorf("failed to read template file: %w", err)
	}

	// Create template instance
	template := &interfaces.Template{
		ID:        atm.generateTemplateID(templatePath),
		Name:      filepath.Base(templatePath),
		Content:   string(content),
		Variables: make(map[string]interfaces.VariableInfo),
		Metadata: interfaces.TemplateMetadata{
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
			Version:   "1.0.0",
			Category:  atm.inferCategory(templatePath),
			Tags:      atm.extractTags(string(content)),
		},
	}

	// Process variables
	if err := atm.processTemplateVariables(template, vars); err != nil {
		atm.updatePerformanceStats(startTime, false, true)
		return nil, fmt.Errorf("failed to process variables: %w", err)
	}

	// Apply AI optimizations
	if err := atm.optimizeTemplateContent(template); err != nil {
		// Non-critical error, log but continue
		fmt.Printf("Warning: failed to optimize template: %v\n", err)
	}

	// Cache the result
	if atm.config.CacheEnabled {
		atm.cacheTemplate(templatePath, vars, template)
	}

	// Store in templates map
	atm.templates[template.ID] = template

	atm.updatePerformanceStats(startTime, false, false)
	return template, nil
}

// AnalyzePatterns implements AITemplateManager.AnalyzePatterns
func (atm *AITemplateManager) AnalyzePatterns(projectPath string) (*interfaces.PatternAnalysis, error) {
	atm.mu.RLock()
	defer atm.mu.RUnlock()

	if !atm.initialized {
		return nil, fmt.Errorf("AITemplateManager not initialized")
	}

	return atm.patternProcessor.AnalyzeCodePatterns(projectPath)
}

// GenerateSuggestions implements AITemplateManager.GenerateSuggestions
func (atm *AITemplateManager) GenerateSuggestions(context *interfaces.ProjectContext) (*interfaces.Suggestions, error) {
	atm.mu.RLock()
	defer atm.mu.RUnlock()

	if !atm.initialized {
		return nil, fmt.Errorf("AITemplateManager not initialized")
	}

	suggestions := &interfaces.Suggestions{
		Templates:     []interfaces.TemplateSuggestion{},
		Variables:     []interfaces.VariableSuggestion{},
		Optimizations: []interfaces.OptimizationSuggestion{},
		BestPractices: []interfaces.BestPracticeSuggestion{},
		Confidence:    0.0,
		Reasoning:     "",
	}

	// Analyze project patterns first
	patterns, err := atm.patternProcessor.AnalyzeCodePatterns(context.ProjectPath)
	if err != nil {
		return nil, fmt.Errorf("failed to analyze patterns: %w", err)
	}

	// Generate template suggestions based on patterns
	atm.generateTemplateSuggestions(patterns, context, suggestions)

	// Generate variable suggestions
	atm.generateVariableSuggestions(patterns, context, suggestions)

	// Generate optimization suggestions
	atm.generateOptimizationSuggestions(patterns, suggestions)

	// Generate best practice suggestions
	atm.generateBestPracticeSuggestions(patterns, context, suggestions)

	// Calculate overall confidence
	suggestions.Confidence = atm.calculateSuggestionConfidence(suggestions)
	suggestions.Reasoning = atm.generateReasoningExplanation(patterns, suggestions)

	return suggestions, nil
}

// OptimizeTemplate implements AITemplateManager.OptimizeTemplate
func (atm *AITemplateManager) OptimizeTemplate(template *interfaces.Template, performance *interfaces.PerformanceMetrics) (*interfaces.Template, error) {
	atm.mu.Lock()
	defer atm.mu.Unlock()

	if template == nil {
		return nil, fmt.Errorf("template cannot be nil")
	}

	// Create optimized copy
	optimized := *template
	optimized.ID = template.ID + "_optimized"
	optimized.Metadata.UpdatedAt = time.Now()

	// Apply performance-based optimizations
	if performance != nil {
		if performance.ErrorRate > 0.1 { // 10% error rate threshold
			atm.optimizeForReliability(&optimized)
		}

		if performance.AverageProcessingTime > 5*time.Second {
			atm.optimizeForSpeed(&optimized)
		}

		if performance.OptimizationScore < 0.7 {
			atm.optimizeForQuality(&optimized)
		}
	}

	// Update performance info
	optimized.Metadata.PerformanceInfo = *performance
	optimized.Metadata.PerformanceInfo.OptimizationScore = atm.calculateOptimizationScore(&optimized)

	return &optimized, nil
}

// ValidateVariables implements AITemplateManager.ValidateVariables
func (atm *AITemplateManager) ValidateVariables(template *interfaces.Template, vars map[string]interface{}) (*interfaces.ValidationResult, error) {
	if template == nil {
		return nil, fmt.Errorf("template cannot be nil")
	}

	result := &interfaces.ValidationResult{
		Valid:       true,
		Errors:      []interfaces.ValidationError{},
		Warnings:    []interfaces.ValidationWarning{},
		Missing:     []string{},
		Unused:      []string{},
		Suggestions: []interfaces.VariableSuggestion{},
	}

	// Check for required variables
	for varName, varInfo := range template.Variables {
		if varInfo.Required {
			if _, exists := vars[varName]; !exists {
				result.Valid = false
				result.Missing = append(result.Missing, varName)
				result.Errors = append(result.Errors, interfaces.ValidationError{
					Variable: varName,
					Message:  fmt.Sprintf("Required variable '%s' is missing", varName),
					Code:     "MISSING_REQUIRED_VAR",
				})
			}
		}
	}

	// Check for unused variables
	for varName := range vars {
		if _, exists := template.Variables[varName]; !exists {
			result.Unused = append(result.Unused, varName)
			result.Warnings = append(result.Warnings, interfaces.ValidationWarning{
				Variable: varName,
				Message:  fmt.Sprintf("Variable '%s' is not used in template", varName),
				Code:     "UNUSED_VARIABLE",
				Severity: "low",
			})
		}
	}

	// Type validation
	for varName, value := range vars {
		if varInfo, exists := template.Variables[varName]; exists {
			if !atm.validateVariableType(value, varInfo.Type) {
				result.Valid = false
				result.Errors = append(result.Errors, interfaces.ValidationError{
					Variable: varName,
					Message:  fmt.Sprintf("Variable '%s' type mismatch: expected %s", varName, varInfo.Type),
					Code:     "TYPE_MISMATCH",
				})
			}
		}
	}

	// Generate suggestions for improvements
	atm.generateVariableValidationSuggestions(template, vars, result)

	return result, nil
}

// Helper methods

// generateCacheKey generates a unique cache key for template and variables
func (atm *AITemplateManager) generateCacheKey(templatePath string, vars map[string]interface{}) string {
	varStr, _ := json.Marshal(vars)
	return fmt.Sprintf("%s_%x", templatePath, varStr)
}

// generateTemplateID generates a unique ID for a template
func (atm *AITemplateManager) generateTemplateID(templatePath string) string {
	return fmt.Sprintf("template_%x_%d", templatePath, time.Now().UnixNano())
}

// inferCategory infers template category from file path
func (atm *AITemplateManager) inferCategory(templatePath string) string {
	dir := filepath.Dir(templatePath)
	if strings.Contains(dir, "api") {
		return "api"
	}
	if strings.Contains(dir, "web") {
		return "web"
	}
	if strings.Contains(dir, "database") || strings.Contains(dir, "db") {
		return "database"
	}
	if strings.Contains(dir, "util") {
		return "utility"
	}
	return "general"
}

// extractTags extracts tags from template content
func (atm *AITemplateManager) extractTags(content string) []string {
	tags := []string{}

	if strings.Contains(content, "func ") {
		tags = append(tags, "function")
	}
	if strings.Contains(content, "struct") {
		tags = append(tags, "struct")
	}
	if strings.Contains(content, "interface") {
		tags = append(tags, "interface")
	}
	if strings.Contains(content, "HTTP") || strings.Contains(content, "http") {
		tags = append(tags, "http")
	}
	if strings.Contains(content, "JSON") || strings.Contains(content, "json") {
		tags = append(tags, "json")
	}

	return tags
}

// processTemplateVariables processes and validates template variables
func (atm *AITemplateManager) processTemplateVariables(template *interfaces.Template, vars map[string]interface{}) error {
	// Extract variables from template content (simplified)
	for varName, value := range vars {
		varType := atm.inferTypeFromValue(value)
		template.Variables[varName] = interfaces.VariableInfo{
			Type:        varType,
			Default:     value,
			Required:    true, // Could be enhanced with more sophisticated analysis
			Description: fmt.Sprintf("Variable %s of type %s", varName, varType),
		}
	}
	return nil
}

// inferTypeFromValue infers variable type from its value
func (atm *AITemplateManager) inferTypeFromValue(value interface{}) string {
	switch value.(type) {
	case string:
		return "string"
	case int, int32, int64:
		return "int"
	case float32, float64:
		return "float"
	case bool:
		return "bool"
	case []interface{}:
		return "array"
	case map[string]interface{}:
		return "object"
	default:
		return "interface{}"
	}
}

// optimizeTemplateContent applies AI-based optimizations to template content
func (atm *AITemplateManager) optimizeTemplateContent(template *interfaces.Template) error {
	// Placeholder for AI optimization logic
	// Could include:
	// - Code formatting improvements
	// - Performance optimizations
	// - Best practice applications
	// - Redundancy removal

	template.Metadata.UpdatedAt = time.Now()
	return nil
}

// cacheTemplate stores a template in cache
func (atm *AITemplateManager) cacheTemplate(templatePath string, vars map[string]interface{}, template *interfaces.Template) {
	if len(atm.templateCache) >= atm.config.MaxCacheSize {
		// Simple LRU eviction
		atm.evictOldestCacheEntry()
	}

	cacheKey := atm.generateCacheKey(templatePath, vars)
	atm.templateCache[cacheKey] = &CachedTemplate{
		Template:    template,
		CachedAt:    time.Now(),
		AccessCount: 1,
		LastAccess:  time.Now(),
	}
}

// evictOldestCacheEntry removes the oldest cache entry
func (atm *AITemplateManager) evictOldestCacheEntry() {
	var oldestKey string
	var oldestTime time.Time

	for key, cached := range atm.templateCache {
		if oldestKey == "" || cached.CachedAt.Before(oldestTime) {
			oldestKey = key
			oldestTime = cached.CachedAt
		}
	}

	if oldestKey != "" {
		delete(atm.templateCache, oldestKey)
	}
}

// updatePerformanceStats updates performance statistics
func (atm *AITemplateManager) updatePerformanceStats(startTime time.Time, cacheHit, isError bool) {
	processingTime := time.Since(startTime)

	atm.performanceStats.TotalProcessed++

	// Update average time (moving average)
	if atm.performanceStats.TotalProcessed == 1 {
		atm.performanceStats.AverageTime = processingTime
	} else {
		atm.performanceStats.AverageTime = time.Duration(
			(int64(atm.performanceStats.AverageTime) + int64(processingTime)) / 2,
		)
	}

	// Update cache hit rate
	if cacheHit {
		hitRate := atm.performanceStats.CacheHitRate
		total := float64(atm.performanceStats.TotalProcessed)
		atm.performanceStats.CacheHitRate = (hitRate*(total-1) + 1) / total
	}

	// Update error rate
	if isError {
		errorRate := atm.performanceStats.ErrorRate
		total := float64(atm.performanceStats.TotalProcessed)
		atm.performanceStats.ErrorRate = (errorRate*(total-1) + 1) / total
	}
}

// loadTemplatesFromDirectory loads existing templates from a directory
func (atm *AITemplateManager) loadTemplatesFromDirectory(dir string) error {
	return filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && strings.HasSuffix(path, ".tmpl") {
			template, err := atm.ProcessTemplate(path, map[string]interface{}{})
			if err != nil {
				fmt.Printf("Warning: failed to load template %s: %v\n", path, err)
				return nil // Continue with other templates
			}
			atm.templates[template.ID] = template
		}

		return nil
	})
}

// performanceMonitor runs in background to monitor performance
func (atm *AITemplateManager) performanceMonitor(ctx context.Context) {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			atm.cleanupExpiredCache()
		}
	}
}

// cleanupExpiredCache removes expired entries from cache
func (atm *AITemplateManager) cleanupExpiredCache() {
	atm.mu.Lock()
	defer atm.mu.Unlock()

	for key, cached := range atm.templateCache {
		if time.Since(cached.CachedAt) > atm.config.CacheExpiration {
			delete(atm.templateCache, key)
		}
	}
}

// generateTemplateSuggestions generates template suggestions based on patterns
func (atm *AITemplateManager) generateTemplateSuggestions(patterns *interfaces.PatternAnalysis, context *interfaces.ProjectContext, suggestions *interfaces.Suggestions) {
	// Analyze existing templates for similarity
	for _, template := range atm.templates {
		similarity := atm.calculateContextSimilarity(template, context)
		if similarity > 0.7 {
			suggestions.Templates = append(suggestions.Templates, interfaces.TemplateSuggestion{
				Name:        template.Name,
				Description: fmt.Sprintf("Similar template based on %s patterns", context.Language),
				Content:     template.Content,
				Confidence:  similarity,
				Category:    template.Metadata.Category,
			})
		}
	}

	// Generate new template suggestions based on patterns
	if len(patterns.Functions) > 0 {
		suggestions.Templates = append(suggestions.Templates, interfaces.TemplateSuggestion{
			Name:        "Function Template",
			Description: "Template for creating new functions based on existing patterns",
			Content:     atm.generateFunctionTemplate(patterns.Functions[0]),
			Confidence:  0.8,
			Category:    "function",
		})
	}
}

// generateVariableSuggestions generates variable suggestions
func (atm *AITemplateManager) generateVariableSuggestions(patterns *interfaces.PatternAnalysis, context *interfaces.ProjectContext, suggestions *interfaces.Suggestions) {
	// Suggest common variables based on patterns
	variableFreq := make(map[string]int)
	for _, varPattern := range patterns.Variables {
		variableFreq[varPattern.Name]++
	}

	for varName, freq := range variableFreq {
		if freq > 1 { // Suggest frequently used variables
			suggestions.Variables = append(suggestions.Variables, interfaces.VariableSuggestion{
				Name:        varName,
				Type:        "string", // Default type, could be inferred
				Description: fmt.Sprintf("Commonly used variable (frequency: %d)", freq),
				Confidence:  float64(freq) / float64(len(patterns.Variables)),
				Source:      "pattern_analysis",
			})
		}
	}
}

// generateOptimizationSuggestions generates optimization suggestions
func (atm *AITemplateManager) generateOptimizationSuggestions(patterns *interfaces.PatternAnalysis, suggestions *interfaces.Suggestions) {
	// Suggest optimizations based on complexity
	if patterns.Complexity.CyclomaticComplexity > 50 {
		suggestions.Optimizations = append(suggestions.Optimizations, interfaces.OptimizationSuggestion{
			Type:        "complexity_reduction",
			Description: "High cyclomatic complexity detected. Consider refactoring into smaller functions.",
			Impact:      "Improved maintainability and testability",
			Effort:      "medium",
			Confidence:  0.9,
		})
	}

	if patterns.Complexity.TechnicalDebt > 50 {
		suggestions.Optimizations = append(suggestions.Optimizations, interfaces.OptimizationSuggestion{
			Type:        "technical_debt",
			Description: "High technical debt detected. Consider code cleanup and refactoring.",
			Impact:      "Reduced maintenance cost",
			Effort:      "high",
			Confidence:  0.8,
		})
	}
}

// generateBestPracticeSuggestions generates best practice suggestions
func (atm *AITemplateManager) generateBestPracticeSuggestions(patterns *interfaces.PatternAnalysis, context *interfaces.ProjectContext, suggestions *interfaces.Suggestions) {
	// Language-specific best practices
	switch context.Language {
	case "go":
		suggestions.BestPractices = append(suggestions.BestPractices, interfaces.BestPracticeSuggestion{
			Category:    "naming",
			Title:       "Go Naming Conventions",
			Description: "Use camelCase for unexported functions and PascalCase for exported ones",
			Priority:    1,
		})

		suggestions.BestPractices = append(suggestions.BestPractices, interfaces.BestPracticeSuggestion{
			Category:    "error_handling",
			Title:       "Explicit Error Handling",
			Description: "Always handle errors explicitly in Go",
			Priority:    1,
		})
	}

	// General best practices
	if len(patterns.Functions) > 20 {
		suggestions.BestPractices = append(suggestions.BestPractices, interfaces.BestPracticeSuggestion{
			Category:    "organization",
			Title:       "Code Organization",
			Description: "Consider splitting large files into smaller, focused modules",
			Priority:    2,
		})
	}
}

// calculateSuggestionConfidence calculates overall confidence score
func (atm *AITemplateManager) calculateSuggestionConfidence(suggestions *interfaces.Suggestions) float64 {
	totalConfidence := 0.0
	count := 0

	for _, template := range suggestions.Templates {
		totalConfidence += template.Confidence
		count++
	}

	for _, variable := range suggestions.Variables {
		totalConfidence += variable.Confidence
		count++
	}

	for _, optimization := range suggestions.Optimizations {
		totalConfidence += optimization.Confidence
		count++
	}

	if count == 0 {
		return 0.0
	}

	return totalConfidence / float64(count)
}

// generateReasoningExplanation generates reasoning for suggestions
func (atm *AITemplateManager) generateReasoningExplanation(patterns *interfaces.PatternAnalysis, suggestions *interfaces.Suggestions) string {
	reasons := []string{}

	if len(suggestions.Templates) > 0 {
		reasons = append(reasons, fmt.Sprintf("Found %d similar templates based on pattern analysis", len(suggestions.Templates)))
	}

	if len(suggestions.Optimizations) > 0 {
		reasons = append(reasons, fmt.Sprintf("Identified %d optimization opportunities", len(suggestions.Optimizations)))
	}

	if patterns.Complexity.CyclomaticComplexity > 20 {
		reasons = append(reasons, "High complexity detected in codebase")
	}

	return strings.Join(reasons, "; ")
}

// optimizeForReliability applies reliability optimizations
func (atm *AITemplateManager) optimizeForReliability(template *interfaces.Template) {
	// Add error handling patterns
	content := template.Content
	if !strings.Contains(content, "error") {
		// Suggest adding error handling
		template.Variables["errorHandling"] = interfaces.VariableInfo{
			Type:        "bool",
			Default:     true,
			Required:    false,
			Description: "Enable comprehensive error handling",
		}
	}
}

// optimizeForSpeed applies speed optimizations
func (atm *AITemplateManager) optimizeForSpeed(template *interfaces.Template) {
	// Add performance-related variables
	template.Variables["enableCaching"] = interfaces.VariableInfo{
		Type:        "bool",
		Default:     true,
		Required:    false,
		Description: "Enable caching for better performance",
	}

	template.Variables["poolSize"] = interfaces.VariableInfo{
		Type:        "int",
		Default:     10,
		Required:    false,
		Description: "Connection pool size for optimal performance",
	}
}

// optimizeForQuality applies quality optimizations
func (atm *AITemplateManager) optimizeForQuality(template *interfaces.Template) {
	// Add quality-related variables
	template.Variables["enableValidation"] = interfaces.VariableInfo{
		Type:        "bool",
		Default:     true,
		Required:    false,
		Description: "Enable input validation",
	}

	template.Variables["logLevel"] = interfaces.VariableInfo{
		Type:        "string",
		Default:     "info",
		Required:    false,
		Description: "Logging level for debugging",
		Enum:        []string{"debug", "info", "warn", "error"},
	}
}

// calculateOptimizationScore calculates optimization score for a template
func (atm *AITemplateManager) calculateOptimizationScore(template *interfaces.Template) float64 {
	score := 0.5 // Base score

	// Check for error handling
	if strings.Contains(template.Content, "error") {
		score += 0.2
	}

	// Check for documentation
	if strings.Contains(template.Content, "//") || strings.Contains(template.Content, "/*") {
		score += 0.1
	}

	// Check for testing patterns
	if strings.Contains(template.Content, "test") || strings.Contains(template.Content, "Test") {
		score += 0.1
	}

	// Check for proper structure
	if len(template.Variables) > 0 {
		score += 0.1
	}

	return score
}

// validateVariableType validates if a value matches the expected type
func (atm *AITemplateManager) validateVariableType(value interface{}, expectedType string) bool {
	actualType := atm.inferTypeFromValue(value)

	// Direct match
	if actualType == expectedType {
		return true
	}

	// Type compatibility checks
	switch expectedType {
	case "interface{}":
		return true // interface{} accepts any type	case "string":
		return actualType == "string"
	case "int", "int32", "int64":
		return actualType == "int"
	case "float", "float32", "float64":
		return actualType == "float" || actualType == "int"
	case "bool", "boolean":
		return actualType == "bool"
	default:
		return false
	}
}

// generateVariableValidationSuggestions generates suggestions for variable validation
func (atm *AITemplateManager) generateVariableValidationSuggestions(template *interfaces.Template, vars map[string]interface{}, result *interfaces.ValidationResult) {
	// Suggest default values for missing required variables
	for _, missing := range result.Missing {
		if varInfo, exists := template.Variables[missing]; exists {
			result.Suggestions = append(result.Suggestions, interfaces.VariableSuggestion{
				Name:        missing,
				Type:        varInfo.Type,
				Default:     varInfo.Default,
				Description: fmt.Sprintf("Default value for missing variable '%s'", missing),
				Confidence:  0.9,
				Source:      "validation",
			})
		}
	}

	// Suggest type corrections for mismatched variables
	for _, error := range result.Errors {
		if error.Code == "TYPE_MISMATCH" {
			if varInfo, exists := template.Variables[error.Variable]; exists {
				result.Suggestions = append(result.Suggestions, interfaces.VariableSuggestion{
					Name:        error.Variable,
					Type:        varInfo.Type,
					Default:     atm.getDefaultValueForType(varInfo.Type),
					Description: fmt.Sprintf("Correct type for variable '%s'", error.Variable),
					Confidence:  0.8,
					Source:      "validation",
				})
			}
		}
	}
}

// getDefaultValueForType returns a default value for a given type
func (atm *AITemplateManager) getDefaultValueForType(varType string) interface{} {
	switch varType {
	case "string":
		return ""
	case "int", "int32", "int64":
		return 0
	case "float", "float32", "float64":
		return 0.0
	case "bool", "boolean":
		return false
	case "array":
		return []interface{}{}
	case "object":
		return map[string]interface{}{}
	default:
		return nil
	}
}

// calculateContextSimilarity calculates similarity between template and project context
func (atm *AITemplateManager) calculateContextSimilarity(template *interfaces.Template, context *interfaces.ProjectContext) float64 {
	similarity := 0.0

	// Language similarity
	if template.Metadata.Category == context.Language {
		similarity += 0.3
	}

	// Framework similarity
	if template.Metadata.Category == context.Framework {
		similarity += 0.2
	}

	// Tag similarity
	contextTags := []string{context.Language, context.Framework}
	for _, dependency := range context.Dependencies {
		contextTags = append(contextTags, dependency)
	}

	tagSimilarity := atm.similarityScorer.CalculateJaccardSimilarity(template.Metadata.Tags, contextTags)
	similarity += tagSimilarity * 0.3

	// Usage pattern similarity (simplified)
	if template.Metadata.UsageCount > 0 {
		similarity += 0.2
	}

	return similarity
}

// generateFunctionTemplate generates a template for functions based on existing patterns
func (atm *AITemplateManager) generateFunctionTemplate(functionInfo interfaces.FunctionInfo) string {
	template := fmt.Sprintf(`// %s implements...
func %s(`, functionInfo.Name, functionInfo.Name)

	for i, param := range functionInfo.Parameters {
		if i > 0 {
			template += ", "
		}
		template += fmt.Sprintf("%s %s", param.Name, param.Type)
	}

	template += ") "
	if functionInfo.ReturnType != "void" {
		template += functionInfo.ReturnType + " "
	}
	template += "{\n\t// TODO: Implement function logic\n"

	if functionInfo.ReturnType != "void" {
		template += "\treturn // TODO: Return appropriate value\n"
	}

	template += "}"

	return template
}
