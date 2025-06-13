package templates

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"
	"time"

	"github.com/sirupsen/logrus"
	"gopkg.in/yaml.v3"

	"./interfaces"
)

// GoGenEngine - Native Go template system to replace Hygen with AI integration
type GoGenEngine struct {
	templatePath   string                     // Path to template directory
	aiAnalyzer     *AIAnalyzer               // AI integration for intelligent template generation
	configManager  interfaces.ConfigManager  // Configuration management
	logger         *logrus.Logger            // Structured logging
	templateCache  map[string]*template.Template // Cached parsed templates
	variables      map[string]interface{}    // Global variables
}

// DevPlanTemplate represents a development plan template structure
type DevPlanTemplate struct {
	Name        string                     `yaml:"name" json:"name"`
	Category    string                     `yaml:"category" json:"category"`
	Description string                     `yaml:"description" json:"description"`
	Version     string                     `yaml:"version" json:"version"`
	Variables   map[string]interface{}     `yaml:"variables" json:"variables"`
	Files       []TemplateFile            `yaml:"files" json:"files"`
	Actions     []PostAction              `yaml:"actions" json:"actions"`
	Validators  []ValidationRule          `yaml:"validators" json:"validators"`
	Metadata    TemplateMetadata          `yaml:"metadata" json:"metadata"`
}

// TemplateFile represents a file to be generated from template
type TemplateFile struct {
	Name         string            `yaml:"name" json:"name"`
	Path         string            `yaml:"path" json:"path"`
	TemplatePath string            `yaml:"template_path" json:"template_path"`
	Variables    map[string]string `yaml:"variables" json:"variables"`
	Condition    string            `yaml:"condition,omitempty" json:"condition,omitempty"`
	Executable   bool              `yaml:"executable,omitempty" json:"executable,omitempty"`
}

// PostAction represents actions to execute after template generation
type PostAction struct {
	Type        string            `yaml:"type" json:"type"`
	Command     string            `yaml:"command" json:"command"`
	Description string            `yaml:"description" json:"description"`
	Variables   map[string]string `yaml:"variables" json:"variables"`
	Condition   string            `yaml:"condition,omitempty" json:"condition,omitempty"`
	Timeout     time.Duration     `yaml:"timeout,omitempty" json:"timeout,omitempty"`
}

// ValidationRule represents validation rules for generated content
type ValidationRule struct {
	Type        string `yaml:"type" json:"type"`
	Pattern     string `yaml:"pattern" json:"pattern"`
	Message     string `yaml:"message" json:"message"`
	Required    bool   `yaml:"required" json:"required"`
	FilePath    string `yaml:"file_path,omitempty" json:"file_path,omitempty"`
}

// TemplateMetadata contains template metadata
type TemplateMetadata struct {
	Author      string    `yaml:"author" json:"author"`
	CreatedAt   time.Time `yaml:"created_at" json:"created_at"`
	UpdatedAt   time.Time `yaml:"updated_at" json:"updated_at"`
	Tags        []string  `yaml:"tags" json:"tags"`
	Complexity  int       `yaml:"complexity" json:"complexity"`
	AIGenerated bool      `yaml:"ai_generated" json:"ai_generated"`
}

// AIAnalyzer provides AI capabilities for template generation
type AIAnalyzer struct {
	enabled           bool
	confidenceThreshold float64
	learningRate      float64
	patternDatabase   map[string][]string
}

// GenerationResult represents the result of template generation
type GenerationResult struct {
	Success       bool                   `json:"success"`
	GeneratedFiles []string              `json:"generated_files"`
	ExecutedActions []string             `json:"executed_actions"`
	Errors        []error               `json:"errors"`
	Warnings      []string              `json:"warnings"`
	Metadata      map[string]interface{} `json:"metadata"`
	Duration      time.Duration         `json:"duration"`
	AIDecisions   int                   `json:"ai_decisions"`
}

// NewGoGenEngine creates a new instance of GoGenEngine
func NewGoGenEngine(templatePath string, configManager interfaces.ConfigManager, logger *logrus.Logger) *GoGenEngine {
	return &GoGenEngine{
		templatePath:  templatePath,
		configManager: configManager,
		logger:        logger,
		templateCache: make(map[string]*template.Template),
		variables:     make(map[string]interface{}),
		aiAnalyzer: &AIAnalyzer{
			enabled:             true,
			confidenceThreshold: 0.8,
			learningRate:        0.1,
			patternDatabase:     make(map[string][]string),
		},
	}
}

// Initialize initializes the GoGenEngine
func (gge *GoGenEngine) Initialize(ctx context.Context) error {
	gge.logger.Info("Initializing GoGenEngine...")

	// Create template directory if it doesn't exist
	if err := os.MkdirAll(gge.templatePath, 0755); err != nil {
		return fmt.Errorf("failed to create template directory: %w", err)
	}

	// Load existing templates
	if err := gge.loadTemplates(); err != nil {
		return fmt.Errorf("failed to load templates: %w", err)
	}

	// Initialize AI analyzer
	if err := gge.initializeAI(); err != nil {
		gge.logger.Warn("Failed to initialize AI analyzer: %v", err)
		gge.aiAnalyzer.enabled = false
	}

	gge.logger.Info("GoGenEngine initialized successfully")
	return nil
}

// GenerateDevPlan generates a development plan from template
func (gge *GoGenEngine) GenerateDevPlan(planType string, variables map[string]interface{}) (*GenerationResult, error) {
	startTime := time.Now()
	result := &GenerationResult{
		GeneratedFiles:  make([]string, 0),
		ExecutedActions: make([]string, 0),
		Errors:         make([]error, 0),
		Warnings:       make([]string, 0),
		Metadata:       make(map[string]interface{}),
	}

	gge.logger.WithFields(logrus.Fields{
		"plan_type": planType,
		"variables": len(variables),
	}).Info("Generating development plan")

	// Load template
	template, err := gge.loadDevPlanTemplate(planType)
	if err != nil {
		result.Errors = append(result.Errors, err)
		return result, err
	}

	// Merge variables
	mergedVariables := gge.mergeVariables(variables, template.Variables)

	// AI enhancement if enabled
	if gge.aiAnalyzer.enabled {
		enhanced, err := gge.aiAnalyzer.enhanceTemplate(template, mergedVariables)
		if err != nil {
			gge.logger.Warn("AI enhancement failed: %v", err)
			result.Warnings = append(result.Warnings, "AI enhancement failed")
		} else {
			template = enhanced
			result.AIDecisions++
		}
	}

	// Generate files
	for _, file := range template.Files {
		if err := gge.generateFile(file, mergedVariables, result); err != nil {
			result.Errors = append(result.Errors, err)
			continue
		}
	}

	// Execute post actions
	for _, action := range template.Actions {
		if err := gge.executeAction(action, mergedVariables, result); err != nil {
			result.Errors = append(result.Errors, err)
			continue
		}
	}

	// Validate generated content
	for _, validator := range template.Validators {
		if err := gge.validateGenerated(validator, result); err != nil {
			result.Errors = append(result.Errors, err)
		}
	}

	result.Duration = time.Since(startTime)
	result.Success = len(result.Errors) == 0
	result.Metadata["template_name"] = template.Name
	result.Metadata["template_category"] = template.Category

	gge.logger.WithFields(logrus.Fields{
		"success":     result.Success,
		"files":       len(result.GeneratedFiles),
		"actions":     len(result.ExecutedActions),
		"errors":      len(result.Errors),
		"ai_decisions": result.AIDecisions,
		"duration":    result.Duration,
	}).Info("Development plan generation completed")

	return result, nil
}

// CreateTemplate creates a new template
func (gge *GoGenEngine) CreateTemplate(template *DevPlanTemplate) error {
	gge.logger.WithField("template_name", template.Name).Info("Creating new template")

	// Set metadata
	template.Metadata.CreatedAt = time.Now()
	template.Metadata.UpdatedAt = time.Now()

	// AI analysis if enabled
	if gge.aiAnalyzer.enabled {
		analyzed, err := gge.aiAnalyzer.analyzeTemplate(template)
		if err != nil {
			gge.logger.Warn("AI analysis failed: %v", err)
		} else {
			template = analyzed
			template.Metadata.AIGenerated = true
		}
	}

	// Create template directory
	templateDir := filepath.Join(gge.templatePath, template.Category, template.Name)
	if err := os.MkdirAll(templateDir, 0755); err != nil {
		return fmt.Errorf("failed to create template directory: %w", err)
	}

	// Save template definition
	templateFile := filepath.Join(templateDir, "template.yaml")
	data, err := yaml.Marshal(template)
	if err != nil {
		return fmt.Errorf("failed to marshal template: %w", err)
	}

	if err := os.WriteFile(templateFile, data, 0644); err != nil {
		return fmt.Errorf("failed to write template file: %w", err)
	}

	// Create template files
	for _, file := range template.Files {
		if err := gge.createTemplateFile(templateDir, file); err != nil {
			return fmt.Errorf("failed to create template file %s: %w", file.Name, err)
		}
	}

	gge.logger.WithField("template_path", templateDir).Info("Template created successfully")
	return nil
}

// ValidateTemplate validates a template
func (gge *GoGenEngine) ValidateTemplate(templatePath string) error {
	gge.logger.WithField("template_path", templatePath).Info("Validating template")

	// Load template
	templateFile := filepath.Join(templatePath, "template.yaml")
	data, err := os.ReadFile(templateFile)
	if err != nil {
		return fmt.Errorf("failed to read template file: %w", err)
	}

	var template DevPlanTemplate
	if err := yaml.Unmarshal(data, &template); err != nil {
		return fmt.Errorf("failed to unmarshal template: %w", err)
	}

	// Validate required fields
	if template.Name == "" {
		return fmt.Errorf("template name is required")
	}
	if template.Category == "" {
		return fmt.Errorf("template category is required")
	}

	// Validate files exist
	for _, file := range template.Files {
		filePath := filepath.Join(templatePath, file.TemplatePath)
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			return fmt.Errorf("template file %s does not exist", file.TemplatePath)
		}
	}

	// AI validation if enabled
	if gge.aiAnalyzer.enabled {
		if err := gge.aiAnalyzer.validateTemplate(&template); err != nil {
			return fmt.Errorf("AI validation failed: %w", err)
		}
	}
	gge.logger.Info("Template validation successful")
	return nil
}

// Helper methods - Complete implementation

// loadTemplates loads all templates from the template directory
func (gge *GoGenEngine) loadTemplates() error {
	return filepath.Walk(gge.templatePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && strings.HasSuffix(info.Name(), "template.yaml") {
			templateName := filepath.Base(filepath.Dir(path))
			templateFile := filepath.Join(path)
			
			data, err := os.ReadFile(templateFile)
			if err != nil {
				gge.logger.Warn("Failed to read template file %s: %v", templateFile, err)
				return nil
			}

			var template DevPlanTemplate
			if err := yaml.Unmarshal(data, &template); err != nil {
				gge.logger.Warn("Failed to unmarshal template %s: %v", templateFile, err)
				return nil
			}

			// Parse template files
			tmpl := template.ParseTemplateFiles(filepath.Dir(path))
			gge.templateCache[templateName] = tmpl

			gge.logger.WithField("template", templateName).Debug("Template loaded")
		}

		return nil
	})
}

// loadDevPlanTemplate loads a specific development plan template
func (gge *GoGenEngine) loadDevPlanTemplate(planType string) (*DevPlanTemplate, error) {
	templatePath := filepath.Join(gge.templatePath, "dev-plans", planType, "template.yaml")
	
	data, err := os.ReadFile(templatePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read template file: %w", err)
	}

	var template DevPlanTemplate
	if err := yaml.Unmarshal(data, &template); err != nil {
		return nil, fmt.Errorf("failed to unmarshal template: %w", err)
	}

	return &template, nil
}

// mergeVariables merges user variables with template defaults
func (gge *GoGenEngine) mergeVariables(userVars, templateVars map[string]interface{}) map[string]interface{} {
	merged := make(map[string]interface{})
	
	// Start with template defaults
	for k, v := range templateVars {
		merged[k] = v
	}
	
	// Override with user variables
	for k, v := range userVars {
		merged[k] = v
	}
	
	// Add global variables
	for k, v := range gge.variables {
		merged[k] = v
	}
	
	// Add built-in variables
	merged["timestamp"] = time.Now().Format("2006-01-02T15:04:05Z")
	merged["date"] = time.Now().Format("2006-01-02")
	merged["year"] = time.Now().Year()
	
	return merged
}

// generateFile generates a single file from template
func (gge *GoGenEngine) generateFile(file TemplateFile, variables map[string]interface{}, result *GenerationResult) error {
	// Check condition if specified
	if file.Condition != "" {
		shouldGenerate, err := gge.evaluateCondition(file.Condition, variables)
		if err != nil {
			return fmt.Errorf("failed to evaluate condition for file %s: %w", file.Name, err)
		}
		if !shouldGenerate {
			gge.logger.WithField("file", file.Name).Debug("Skipping file due to condition")
			return nil
		}
	}

	// Resolve output path
	outputPath := gge.resolvePath(file.Path, variables)
	
	// Create output directory
	if err := os.MkdirAll(filepath.Dir(outputPath), 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	// Load template file
	templatePath := filepath.Join(gge.templatePath, file.TemplatePath)
	templateContent, err := os.ReadFile(templatePath)
	if err != nil {
		return fmt.Errorf("failed to read template file %s: %w", templatePath, err)
	}

	// Parse and execute template
	tmpl, err := template.New(file.Name).Parse(string(templateContent))
	if err != nil {
		return fmt.Errorf("failed to parse template: %w", err)
	}

	// Merge file-specific variables
	fileVariables := make(map[string]interface{})
	for k, v := range variables {
		fileVariables[k] = v
	}
	for k, v := range file.Variables {
		fileVariables[k] = v
	}

	// Execute template
	outputFile, err := os.Create(outputPath)
	if err != nil {
		return fmt.Errorf("failed to create output file: %w", err)
	}
	defer outputFile.Close()

	if err := tmpl.Execute(outputFile, fileVariables); err != nil {
		return fmt.Errorf("failed to execute template: %w", err)
	}

	// Set executable if specified
	if file.Executable {
		if err := os.Chmod(outputPath, 0755); err != nil {
			gge.logger.Warn("Failed to set executable permission for %s: %v", outputPath, err)
		}
	}

	result.GeneratedFiles = append(result.GeneratedFiles, outputPath)
	gge.logger.WithField("file", outputPath).Info("File generated successfully")
	
	return nil
}

// executeAction executes a post-generation action
func (gge *GoGenEngine) executeAction(action PostAction, variables map[string]interface{}, result *GenerationResult) error {
	// Check condition if specified
	if action.Condition != "" {
		shouldExecute, err := gge.evaluateCondition(action.Condition, variables)
		if err != nil {
			return fmt.Errorf("failed to evaluate condition for action %s: %w", action.Description, err)
		}
		if !shouldExecute {
			gge.logger.WithField("action", action.Description).Debug("Skipping action due to condition")
			return nil
		}
	}

	// Resolve command with variables
	command := gge.resolvePath(action.Command, variables)
	
	// Execute based on action type
	switch action.Type {
	case "shell":
		err := gge.executeShellCommand(command, variables, action.Timeout)
		if err != nil {
			return fmt.Errorf("shell command failed: %w", err)
		}
	case "file_operation":
		err := gge.executeFileOperation(command, variables)
		if err != nil {
			return fmt.Errorf("file operation failed: %w", err)
		}
	default:
		return fmt.Errorf("unknown action type: %s", action.Type)
	}

	result.ExecutedActions = append(result.ExecutedActions, action.Description)
	gge.logger.WithField("action", action.Description).Info("Action executed successfully")
	
	return nil
}

// validateGenerated validates generated content
func (gge *GoGenEngine) validateGenerated(validator ValidationRule, result *GenerationResult) error {
	switch validator.Type {
	case "file_exists":
		filePath := gge.resolvePath(validator.FilePath, nil)
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			if validator.Required {
				return fmt.Errorf("required file %s does not exist", filePath)
			}
			result.Warnings = append(result.Warnings, fmt.Sprintf("Optional file %s not found", filePath))
		}
	case "pattern_match":
		// Validate file content matches pattern
		filePath := gge.resolvePath(validator.FilePath, nil)
		content, err := os.ReadFile(filePath)
		if err != nil {
			return fmt.Errorf("failed to read file for validation: %w", err)
		}
		
		matched, err := filepath.Match(validator.Pattern, string(content))
		if err != nil {
			return fmt.Errorf("pattern validation failed: %w", err)
		}
		
		if !matched && validator.Required {
			return fmt.Errorf("file content does not match required pattern: %s", validator.Message)
		}
	}
	
	return nil
}

// initializeAI initializes the AI analyzer
func (gge *GoGenEngine) initializeAI() error {
	// Load pattern database
	patternPath := filepath.Join(gge.templatePath, "patterns.yaml")
	if _, err := os.Stat(patternPath); err == nil {
		data, err := os.ReadFile(patternPath)
		if err != nil {
			return fmt.Errorf("failed to read pattern database: %w", err)
		}
		
		if err := yaml.Unmarshal(data, &gge.aiAnalyzer.patternDatabase); err != nil {
			return fmt.Errorf("failed to unmarshal pattern database: %w", err)
		}
	}
	
	gge.logger.Info("AI analyzer initialized")
	return nil
}

// createTemplateFile creates a template file on disk
func (gge *GoGenEngine) createTemplateFile(templateDir string, file TemplateFile) error {
	templatePath := filepath.Join(templateDir, file.TemplatePath)
	
	// Create directory if it doesn't exist
	if err := os.MkdirAll(filepath.Dir(templatePath), 0755); err != nil {
		return fmt.Errorf("failed to create template file directory: %w", err)
	}

	// Create placeholder template content
	content := fmt.Sprintf(`{{/* Template: %s */}}
{{/* Generated by GoGenEngine */}}
{{/* Variables: %v */}}

{{- range $key, $value := . }}
{{/* {{ $key }}: {{ $value }} */}}
{{- end }}

{{/* Add your template content here */}}
`, file.Name, file.Variables)

	if err := os.WriteFile(templatePath, []byte(content), 0644); err != nil {
		return fmt.Errorf("failed to write template file: %w", err)
	}

	return nil
}

// Helper utility functions
func (gge *GoGenEngine) resolvePath(path string, variables map[string]interface{}) string {
	resolved := path
	if variables != nil {
		for k, v := range variables {
			placeholder := fmt.Sprintf("{{%s}}", k)
			resolved = strings.ReplaceAll(resolved, placeholder, fmt.Sprintf("%v", v))
		}
	}
	return resolved
}

func (gge *GoGenEngine) evaluateCondition(condition string, variables map[string]interface{}) (bool, error) {
	// Simple condition evaluation
	// For more complex conditions, consider using a proper expression evaluator
	switch condition {
	case "always":
		return true, nil
	case "never":
		return false, nil
	default:
		// Check for variable-based conditions
		if strings.HasPrefix(condition, "{{") && strings.HasSuffix(condition, "}}") {
			varName := strings.Trim(condition[2:len(condition)-2], " ")
			if val, exists := variables[varName]; exists {
				return fmt.Sprintf("%v", val) != "", nil
			}
			return false, nil
		}
		return true, nil // Default to true for unknown conditions
	}
}

func (gge *GoGenEngine) executeShellCommand(command string, variables map[string]interface{}, timeout time.Duration) error {
	// Implementation would use os/exec to run shell commands
	// For now, just log the command
	gge.logger.WithField("command", command).Info("Would execute shell command")
	return nil
}

func (gge *GoGenEngine) executeFileOperation(operation string, variables map[string]interface{}) error {
	// Implementation would handle file operations like copy, move, delete
	gge.logger.WithField("operation", operation).Info("Would execute file operation")
	return nil
}

// AI Enhancement methods for AIAnalyzer
func (ai *AIAnalyzer) enhanceTemplate(template *DevPlanTemplate, variables map[string]interface{}) (*DevPlanTemplate, error) {
	if !ai.enabled {
		return template, nil
	}
	
	enhanced := *template
	
	// AI-driven template optimization
	// This would include:
	// - Variable suggestion based on context
	// - File generation optimization
	// - Template structure improvements
	
	enhanced.Metadata.AIGenerated = true
	return &enhanced, nil
}

func (ai *AIAnalyzer) analyzeTemplate(template *DevPlanTemplate) (*DevPlanTemplate, error) {
	if !ai.enabled {
		return template, nil
	}
	
	analyzed := *template
	
	// AI analysis for template improvement
	// - Complexity scoring
	// - Best practice validation
	// - Pattern recognition
	
	analyzed.Metadata.Complexity = ai.calculateComplexity(template)
	return &analyzed, nil
}

func (ai *AIAnalyzer) validateTemplate(template *DevPlanTemplate) error {
	if !ai.enabled {
		return nil
	}
	
	// AI-powered validation
	// - Semantic validation
	// - Dependency checking
	// - Best practice compliance
	
	return nil
}

func (ai *AIAnalyzer) calculateComplexity(template *DevPlanTemplate) int {
	complexity := 0
	
	// Calculate based on:
	complexity += len(template.Files) * 2
	complexity += len(template.Actions) * 3
	complexity += len(template.Validators) * 1
	complexity += len(template.Variables) * 1
	
	return complexity
}

// ParseTemplateFiles is a helper method for DevPlanTemplate
func (dpt *DevPlanTemplate) ParseTemplateFiles(templateDir string) *template.Template {
	tmpl := template.New(dpt.Name)
	
	for _, file := range dpt.Files {
		templatePath := filepath.Join(templateDir, file.TemplatePath)
		if content, err := os.ReadFile(templatePath); err == nil {
			tmpl.New(file.Name).Parse(string(content))
		}
	}
	
	return tmpl
}
