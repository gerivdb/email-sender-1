package templates

import (
	"embed"
	"fmt"
	"path/filepath"
)

// DefaultTemplates contains embedded default templates for common scenarios
//
//go:embed default_templates/*
var DefaultTemplates embed.FS

// Template categories
const (
	CategoryManager  = "manager"
	CategoryAPI      = "api"
	CategoryDatabase = "database"
	CategoryConfig   = "config"
	CategoryTest     = "test"
	CategoryDocker   = "docker"
	CategoryCI       = "ci"
)

// TemplateInfo describes a template
type TemplateInfo struct {
	Name        string            `json:"name"`
	Description string            `json:"description"`
	Category    string            `json:"category"`
	Path        string            `json:"path"`
	Variables   []VariableInfo    `json:"variables"`
	Actions     []ActionInfo      `json:"actions"`
	Conditions  map[string]string `json:"conditions"`
}

// VariableInfo describes template variables
type VariableInfo struct {
	Name        string `json:"name"`
	Type        string `json:"type"`
	Description string `json:"description"`
	Required    bool   `json:"required"`
	Default     string `json:"default,omitempty"`
}

// ActionInfo describes post-generation actions
type ActionInfo struct {
	Type        string            `json:"type"`
	Description string            `json:"description"`
	Command     string            `json:"command,omitempty"`
	Conditions  map[string]string `json:"conditions,omitempty"`
}

// GetDefaultTemplateRegistry returns the registry of all default templates
func GetDefaultTemplateRegistry() map[string]TemplateInfo {
	return map[string]TemplateInfo{
		"go-manager": {
			Name:        "Go Manager",
			Description: "Creates a new Go manager following ecosystem patterns",
			Category:    CategoryManager,
			Path:        "default_templates/go-manager",
			Variables: []VariableInfo{
				{Name: "name", Type: "string", Description: "Manager name", Required: true},
				{Name: "package", Type: "string", Description: "Go package name", Required: true},
				{Name: "port", Type: "number", Description: "Service port", Required: false, Default: "8080"},
				{Name: "hasStorage", Type: "boolean", Description: "Includes storage integration", Required: false, Default: "false"},
				{Name: "hasMonitoring", Type: "boolean", Description: "Includes monitoring", Required: false, Default: "true"},
				{Name: "hasSecurity", Type: "boolean", Description: "Includes security features", Required: false, Default: "true"},
			},
			Actions: []ActionInfo{
				{Type: "shell", Description: "Initialize Go module", Command: "go mod init {{.package}}"},
				{Type: "shell", Description: "Download dependencies", Command: "go mod tidy"},
				{Type: "shell", Description: "Format code", Command: "go fmt ./..."},
			},
			Conditions: map[string]string{
				"hasStorage":    "{{.hasStorage}}",
				"hasMonitoring": "{{.hasMonitoring}}",
				"hasSecurity":   "{{.hasSecurity}}",
			},
		},

		"rest-api": {
			Name:        "REST API",
			Description: "Creates a RESTful API with standard endpoints",
			Category:    CategoryAPI,
			Path:        "default_templates/rest-api",
			Variables: []VariableInfo{
				{Name: "service", Type: "string", Description: "Service name", Required: true},
				{Name: "version", Type: "string", Description: "API version", Required: false, Default: "v1"},
				{Name: "hasAuth", Type: "boolean", Description: "Includes authentication", Required: false, Default: "true"},
				{Name: "hasRateLimit", Type: "boolean", Description: "Includes rate limiting", Required: false, Default: "true"},
			},
			Actions: []ActionInfo{
				{Type: "shell", Description: "Generate OpenAPI spec", Command: "swagger generate spec -o api/swagger.yaml"},
			},
			Conditions: map[string]string{
				"hasAuth":      "{{.hasAuth}}",
				"hasRateLimit": "{{.hasRateLimit}}",
			},
		},

		"database-model": {
			Name:        "Database Model",
			Description: "Creates database models and migrations",
			Category:    CategoryDatabase,
			Path:        "default_templates/database-model",
			Variables: []VariableInfo{
				{Name: "model", Type: "string", Description: "Model name", Required: true},
				{Name: "table", Type: "string", Description: "Database table name", Required: true},
				{Name: "fields", Type: "array", Description: "Model fields", Required: true},
				{Name: "hasTimestamps", Type: "boolean", Description: "Include created/updated timestamps", Required: false, Default: "true"},
			},
			Actions: []ActionInfo{
				{Type: "shell", Description: "Run database migration", Command: "migrate -path migrations -database {{.dbURL}} up"},
			},
		},

		"config-manager": {
			Name:        "Configuration Manager",
			Description: "Creates configuration management with validation",
			Category:    CategoryConfig,
			Path:        "default_templates/config-manager",
			Variables: []VariableInfo{
				{Name: "service", Type: "string", Description: "Service name", Required: true},
				{Name: "configFormat", Type: "string", Description: "Config format (yaml|json|toml)", Required: false, Default: "yaml"},
				{Name: "hasEnvironment", Type: "boolean", Description: "Environment-specific configs", Required: false, Default: "true"},
			},
		},

		"unit-tests": {
			Name:        "Unit Tests",
			Description: "Creates comprehensive unit tests",
			Category:    CategoryTest,
			Path:        "default_templates/unit-tests",
			Variables: []VariableInfo{
				{Name: "package", Type: "string", Description: "Package to test", Required: true},
				{Name: "testType", Type: "string", Description: "Test type (unit|integration|e2e)", Required: false, Default: "unit"},
				{Name: "hasTestDB", Type: "boolean", Description: "Requires test database", Required: false, Default: "false"},
			},
			Actions: []ActionInfo{
				{Type: "shell", Description: "Run tests", Command: "go test -v ./..."},
				{Type: "shell", Description: "Generate coverage", Command: "go test -coverprofile=coverage.out ./..."},
			},
		},

		"docker-setup": {
			Name:        "Docker Setup",
			Description: "Creates Docker configuration for deployment",
			Category:    CategoryDocker,
			Path:        "default_templates/docker-setup",
			Variables: []VariableInfo{
				{Name: "service", Type: "string", Description: "Service name", Required: true},
				{Name: "baseImage", Type: "string", Description: "Base Docker image", Required: false, Default: "golang:1.21-alpine"},
				{Name: "port", Type: "number", Description: "Service port", Required: false, Default: "8080"},
				{Name: "hasDatabase", Type: "boolean", Description: "Includes database service", Required: false, Default: "false"},
			},
			Actions: []ActionInfo{
				{Type: "shell", Description: "Build Docker image", Command: "docker build -t {{.service}} ."},
				{Type: "shell", Description: "Start services", Command: "docker-compose up -d"},
			},
		},

		"ci-pipeline": {
			Name:        "CI/CD Pipeline",
			Description: "Creates CI/CD pipeline configuration",
			Category:    CategoryCI,
			Path:        "default_templates/ci-pipeline",
			Variables: []VariableInfo{
				{Name: "service", Type: "string", Description: "Service name", Required: true},
				{Name: "platform", Type: "string", Description: "CI platform (github|gitlab|jenkins)", Required: false, Default: "github"},
				{Name: "hasTests", Type: "boolean", Description: "Include test stage", Required: false, Default: "true"},
				{Name: "hasSecurity", Type: "boolean", Description: "Include security scanning", Required: false, Default: "true"},
				{Name: "hasDeployment", Type: "boolean", Description: "Include deployment stage", Required: false, Default: "true"},
			},
		},
	}
}

// GetTemplateByName returns a specific template by name
func GetTemplateByName(name string) (TemplateInfo, error) {
	registry := GetDefaultTemplateRegistry()
	if template, exists := registry[name]; exists {
		return template, nil
	}
	return TemplateInfo{}, fmt.Errorf("template not found: %s", name)
}

// GetTemplatesByCategory returns templates filtered by category
func GetTemplatesByCategory(category string) []TemplateInfo {
	registry := GetDefaultTemplateRegistry()
	var templates []TemplateInfo

	for _, template := range registry {
		if template.Category == category {
			templates = append(templates, template)
		}
	}

	return templates
}

// GetTemplateFile returns the content of a template file
func GetTemplateFile(templatePath, fileName string) ([]byte, error) {
	fullPath := filepath.Join(templatePath, fileName)
	return DefaultTemplates.ReadFile(fullPath)
}

// ListTemplateFiles returns all files in a template directory
func ListTemplateFiles(templatePath string) ([]string, error) {
	entries, err := DefaultTemplates.ReadDir(templatePath)
	if err != nil {
		return nil, err
	}

	var files []string
	for _, entry := range entries {
		if !entry.IsDir() {
			files = append(files, entry.Name())
		}
	}

	return files, nil
}

// ValidateTemplateVariables checks if all required variables are provided
func ValidateTemplateVariables(template TemplateInfo, variables map[string]interface{}) error {
	for _, varInfo := range template.Variables {
		if varInfo.Required {
			if _, exists := variables[varInfo.Name]; !exists {
				return fmt.Errorf("required variable missing: %s", varInfo.Name)
			}
		}
	}
	return nil
}

// GetTemplateDefaults returns default values for template variables
func GetTemplateDefaults(template TemplateInfo) map[string]interface{} {
	defaults := make(map[string]interface{})

	for _, varInfo := range template.Variables {
		if varInfo.Default != "" {
			switch varInfo.Type {
			case "boolean":
				defaults[varInfo.Name] = varInfo.Default == "true"
			case "number":
				defaults[varInfo.Name] = varInfo.Default
			default:
				defaults[varInfo.Name] = varInfo.Default
			}
		}
	}

	return defaults
}
