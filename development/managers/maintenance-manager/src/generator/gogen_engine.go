// Package generator provides advanced code generation capabilities for the maintenance manager
package generator

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"
	"time"

	"go.uber.org/zap"
	"github.com/email-sender/maintenance-manager/src/core"
)

// GoGenEngine provides comprehensive code generation capabilities
type GoGenEngine struct {
	logger    *zap.Logger
	config    *core.GeneratorConfig
	templates map[string]*template.Template
	context   context.Context
}

// GenerationRequest represents a code generation request
type GenerationRequest struct {
	Type        string                 `json:"type"`        // "component", "service", "handler", "test"
	Name        string                 `json:"name"`        // Component name
	Package     string                 `json:"package"`     // Target package
	OutputDir   string                 `json:"output_dir"`  // Output directory
	Template    string                 `json:"template"`    // Template name
	Variables   map[string]interface{} `json:"variables"`   // Template variables
	Options     GenerationOptions      `json:"options"`     // Generation options
}

// GenerationOptions controls generation behavior
type GenerationOptions struct {
	OverwriteExisting bool     `json:"overwrite_existing"`
	CreateTests       bool     `json:"create_tests"`
	CreateDocs        bool     `json:"create_docs"`
	AddInterfaces     bool     `json:"add_interfaces"`
	UseDefaults       bool     `json:"use_defaults"`
	Imports          []string  `json:"imports"`
}

// GenerationResult represents the result of a generation operation
type GenerationResult struct {
	Success     bool              `json:"success"`
	GeneratedFiles []GeneratedFile `json:"generated_files"`
	Errors      []string          `json:"errors"`
	Warnings    []string          `json:"warnings"`
	Duration    time.Duration     `json:"duration"`
	Metadata    map[string]interface{} `json:"metadata"`
}

// GeneratedFile represents a generated file
type GeneratedFile struct {
	Path        string    `json:"path"`
	Type        string    `json:"type"`
	Size        int64     `json:"size"`
	CreatedAt   time.Time `json:"created_at"`
	Template    string    `json:"template"`
	Checksum    string    `json:"checksum"`
}

// TemplateData holds data for template rendering
type TemplateData struct {
	Name        string                 `json:"name"`
	Package     string                 `json:"package"`
	Timestamp   string                 `json:"timestamp"`
	Author      string                 `json:"author"`
	Version     string                 `json:"version"`
	Description string                 `json:"description"`
	Imports     []string               `json:"imports"`
	Variables   map[string]interface{} `json:"variables"`
	Options     GenerationOptions      `json:"options"`
}

// NewGoGenEngine creates a new code generation engine
func NewGoGenEngine(logger *zap.Logger, config *core.GeneratorConfig) (*GoGenEngine, error) {
	if logger == nil {
		return nil, fmt.Errorf("logger is required")
	}
	if config == nil {
		return nil, fmt.Errorf("config is required")
	}

	engine := &GoGenEngine{
		logger:    logger,
		config:    config,
		templates: make(map[string]*template.Template),
		context:   context.Background(),
	}

	// Initialize templates
	if err := engine.loadTemplates(); err != nil {
		return nil, fmt.Errorf("failed to load templates: %w", err)
	}

	return engine, nil
}

// Generate executes a code generation request
func (e *GoGenEngine) Generate(req *GenerationRequest) (*GenerationResult, error) {
	startTime := time.Now()
	result := &GenerationResult{
		GeneratedFiles: []GeneratedFile{},
		Errors:        []string{},
		Warnings:      []string{},
		Metadata:      make(map[string]interface{}),
	}

	e.logger.Info("Starting code generation",
		zap.String("type", req.Type),
		zap.String("name", req.Name),
		zap.String("package", req.Package))

	// Validate request
	if err := e.validateRequest(req); err != nil {
		result.Errors = append(result.Errors, err.Error())
		result.Duration = time.Since(startTime)
		return result, err
	}

	// Prepare template data
	templateData := e.prepareTemplateData(req)

	// Generate main component
	if err := e.generateMainComponent(req, templateData, result); err != nil {
		result.Errors = append(result.Errors, err.Error())
	}

	// Generate tests if requested
	if req.Options.CreateTests {
		if err := e.generateTests(req, templateData, result); err != nil {
			result.Warnings = append(result.Warnings, fmt.Sprintf("Test generation failed: %v", err))
		}
	}

	// Generate documentation if requested
	if req.Options.CreateDocs {
		if err := e.generateDocs(req, templateData, result); err != nil {
			result.Warnings = append(result.Warnings, fmt.Sprintf("Documentation generation failed: %v", err))
		}
	}

	// Generate interfaces if requested
	if req.Options.AddInterfaces {
		if err := e.generateInterfaces(req, templateData, result); err != nil {
			result.Warnings = append(result.Warnings, fmt.Sprintf("Interface generation failed: %v", err))
		}
	}

	result.Success = len(result.Errors) == 0
	result.Duration = time.Since(startTime)
	result.Metadata["generated_count"] = len(result.GeneratedFiles)
	result.Metadata["template_used"] = req.Template

	e.logger.Info("Code generation completed",
		zap.Bool("success", result.Success),
		zap.Int("files_generated", len(result.GeneratedFiles)),
		zap.Duration("duration", result.Duration))

	return result, nil
}

// GenerateFromTemplate generates code using a specific template
func (e *GoGenEngine) GenerateFromTemplate(templateName string, data interface{}, outputPath string) error {
	tmpl, exists := e.templates[templateName]
	if !exists {
		return fmt.Errorf("template %s not found", templateName)
	}

	// Ensure output directory exists
	outputDir := filepath.Dir(outputPath)
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	// Create output file
	file, err := os.Create(outputPath)
	if err != nil {
		return fmt.Errorf("failed to create output file: %w", err)
	}
	defer file.Close()

	// Execute template
	if err := tmpl.Execute(file, data); err != nil {
		return fmt.Errorf("failed to execute template: %w", err)
	}

	e.logger.Info("Generated file from template",
		zap.String("template", templateName),
		zap.String("output", outputPath))

	return nil
}

// ListTemplates returns available templates
func (e *GoGenEngine) ListTemplates() []string {
	templates := make([]string, 0, len(e.templates))
	for name := range e.templates {
		templates = append(templates, name)
	}
	return templates
}

// ValidateTemplate validates a template
func (e *GoGenEngine) ValidateTemplate(templateName string) error {
	_, exists := e.templates[templateName]
	if !exists {
		return fmt.Errorf("template %s not found", templateName)
	}
	return nil
}

// loadTemplates loads all available templates
func (e *GoGenEngine) loadTemplates() error {
	e.logger.Info("Loading templates")

	// Load built-in templates
	e.templates["go_service"] = template.Must(template.New("go_service").Parse(goServiceTemplate))
	e.templates["go_handler"] = template.Must(template.New("go_handler").Parse(goHandlerTemplate))
	e.templates["go_interface"] = template.Must(template.New("go_interface").Parse(goInterfaceTemplate))
	e.templates["go_test"] = template.Must(template.New("go_test").Parse(goTestTemplate))
	e.templates["go_main"] = template.Must(template.New("go_main").Parse(goMainTemplate))
	e.templates["go_config"] = template.Must(template.New("go_config").Parse(goConfigTemplate))
	e.templates["readme"] = template.Must(template.New("readme").Parse(readmeTemplate))

	// Load custom templates from directory if specified
	if e.config.TemplateDir != "" {
		if err := e.loadCustomTemplates(); err != nil {
			e.logger.Warn("Failed to load custom templates", zap.Error(err))
		}
	}

	e.logger.Info("Templates loaded", zap.Int("count", len(e.templates)))
	return nil
}

// loadCustomTemplates loads custom templates from the template directory
func (e *GoGenEngine) loadCustomTemplates() error {
	return filepath.Walk(e.config.TemplateDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && strings.HasSuffix(path, ".tmpl") {
			content, err := os.ReadFile(path)
			if err != nil {
				return err
			}

			name := strings.TrimSuffix(filepath.Base(path), ".tmpl")
			tmpl, err := template.New(name).Parse(string(content))
			if err != nil {
				return err
			}

			e.templates[name] = tmpl
			e.logger.Debug("Loaded custom template", zap.String("name", name), zap.String("path", path))
		}

		return nil
	})
}

// validateRequest validates a generation request
func (e *GoGenEngine) validateRequest(req *GenerationRequest) error {
	if req.Name == "" {
		return fmt.Errorf("name is required")
	}
	if req.Package == "" {
		return fmt.Errorf("package is required")
	}
	if req.OutputDir == "" {
		return fmt.Errorf("output directory is required")
	}
	if req.Template == "" {
		req.Template = "go_service" // Default template
	}

	// Validate template exists
	if _, exists := e.templates[req.Template]; !exists {
		return fmt.Errorf("template %s not found", req.Template)
	}

	return nil
}

// prepareTemplateData prepares data for template rendering
func (e *GoGenEngine) prepareTemplateData(req *GenerationRequest) *TemplateData {
	data := &TemplateData{
		Name:        req.Name,
		Package:     req.Package,
		Timestamp:   time.Now().Format("2006-01-02 15:04:05"),
		Author:      e.config.Author,
		Version:     e.config.Version,
		Description: fmt.Sprintf("Generated %s for %s", req.Type, req.Name),
		Imports:     req.Options.Imports,
		Variables:   req.Variables,
		Options:     req.Options,
	}

	// Add default imports based on type
	switch req.Type {
	case "service":
		data.Imports = append(data.Imports, "context", "fmt", "time")
	case "handler":
		data.Imports = append(data.Imports, "net/http", "encoding/json", "fmt")
	case "test":
		data.Imports = append(data.Imports, "testing", "github.com/stretchr/testify/assert")
	}

	return data
}

// generateMainComponent generates the main component file
func (e *GoGenEngine) generateMainComponent(req *GenerationRequest, data *TemplateData, result *GenerationResult) error {
	filename := fmt.Sprintf("%s.go", strings.ToLower(req.Name))
	outputPath := filepath.Join(req.OutputDir, filename)

	// Check if file exists and overwrite is not allowed
	if !req.Options.OverwriteExisting {
		if _, err := os.Stat(outputPath); err == nil {
			return fmt.Errorf("file %s already exists and overwrite is disabled", outputPath)
		}
	}

	if err := e.GenerateFromTemplate(req.Template, data, outputPath); err != nil {
		return err
	}

	// Get file info
	info, err := os.Stat(outputPath)
	if err != nil {
		return err
	}

	generatedFile := GeneratedFile{
		Path:      outputPath,
		Type:      "main",
		Size:      info.Size(),
		CreatedAt: time.Now(),
		Template:  req.Template,
	}

	result.GeneratedFiles = append(result.GeneratedFiles, generatedFile)
	return nil
}

// generateTests generates test files
func (e *GoGenEngine) generateTests(req *GenerationRequest, data *TemplateData, result *GenerationResult) error {
	filename := fmt.Sprintf("%s_test.go", strings.ToLower(req.Name))
	outputPath := filepath.Join(req.OutputDir, filename)

	testData := *data
	testData.Name = req.Name + "Test"

	if err := e.GenerateFromTemplate("go_test", &testData, outputPath); err != nil {
		return err
	}

	// Get file info
	info, err := os.Stat(outputPath)
	if err != nil {
		return err
	}

	generatedFile := GeneratedFile{
		Path:      outputPath,
		Type:      "test",
		Size:      info.Size(),
		CreatedAt: time.Now(),
		Template:  "go_test",
	}

	result.GeneratedFiles = append(result.GeneratedFiles, generatedFile)
	return nil
}

// generateDocs generates documentation files
func (e *GoGenEngine) generateDocs(req *GenerationRequest, data *TemplateData, result *GenerationResult) error {
	filename := "README.md"
	outputPath := filepath.Join(req.OutputDir, filename)

	if err := e.GenerateFromTemplate("readme", data, outputPath); err != nil {
		return err
	}

	// Get file info
	info, err := os.Stat(outputPath)
	if err != nil {
		return err
	}

	generatedFile := GeneratedFile{
		Path:      outputPath,
		Type:      "docs",
		Size:      info.Size(),
		CreatedAt: time.Now(),
		Template:  "readme",
	}

	result.GeneratedFiles = append(result.GeneratedFiles, generatedFile)
	return nil
}

// generateInterfaces generates interface files
func (e *GoGenEngine) generateInterfaces(req *GenerationRequest, data *TemplateData, result *GenerationResult) error {
	filename := fmt.Sprintf("%s_interface.go", strings.ToLower(req.Name))
	outputPath := filepath.Join(req.OutputDir, filename)

	interfaceData := *data
	interfaceData.Name = req.Name + "Interface"

	if err := e.GenerateFromTemplate("go_interface", &interfaceData, outputPath); err != nil {
		return err
	}

	// Get file info
	info, err := os.Stat(outputPath)
	if err != nil {
		return err
	}

	generatedFile := GeneratedFile{
		Path:      outputPath,
		Type:      "interface",
		Size:      info.Size(),
		CreatedAt: time.Now(),
		Template:  "go_interface",
	}

	result.GeneratedFiles = append(result.GeneratedFiles, generatedFile)
	return nil
}
