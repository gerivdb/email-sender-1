package validation

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

// FormatType represents the file format
type FormatType string

const (
	FormatJSON     FormatType = "json"
	FormatYAML     FormatType = "yaml"
	FormatMarkdown FormatType = "markdown"
	FormatUnknown  FormatType = "unknown"
)

// PlanDocument represents a parsed planning document
type PlanDocument struct {
	Format   FormatType             `json:"format" yaml:"format"`
	Metadata PlanMetadata           `json:"metadata" yaml:"metadata"`
	Phases   []Phase                `json:"phases" yaml:"phases"`
	Raw      map[string]interface{} `json:"raw" yaml:"raw"`
}

// PlanMetadata contains document metadata
type PlanMetadata struct {
	Title       string   `json:"title" yaml:"title"`
	Version     string   `json:"version" yaml:"version"`
	Description string   `json:"description" yaml:"description"`
	Author      string   `json:"author" yaml:"author"`
	Created     string   `json:"created" yaml:"created"`
	Updated     string   `json:"updated" yaml:"updated"`
	Tags        []string `json:"tags" yaml:"tags"`
	Category    string   `json:"category" yaml:"category"`
	Priority    string   `json:"priority" yaml:"priority"`
	Status      string   `json:"status" yaml:"status"`
}

// Phase represents a project phase
type Phase struct {
	ID           string      `json:"id" yaml:"id"`
	Name         string      `json:"name" yaml:"name"`
	Description  string      `json:"description" yaml:"description"`
	Status       string      `json:"status" yaml:"status"`
	Progress     float64     `json:"progress" yaml:"progress"`
	StartDate    string      `json:"start_date" yaml:"start_date"`
	EndDate      string      `json:"end_date" yaml:"end_date"`
	Dependencies []string    `json:"dependencies" yaml:"dependencies"`
	Tasks        []Task      `json:"tasks" yaml:"tasks"`
	Milestones   []Milestone `json:"milestones" yaml:"milestones"`
	Resources    []Resource  `json:"resources" yaml:"resources"`
}

// Task represents a task within a phase
type Task struct {
	ID           string   `json:"id" yaml:"id"`
	Name         string   `json:"name" yaml:"name"`
	Description  string   `json:"description" yaml:"description"`
	Status       string   `json:"status" yaml:"status"`
	Priority     string   `json:"priority" yaml:"priority"`
	Progress     float64  `json:"progress" yaml:"progress"`
	EstimatedHrs int      `json:"estimated_hours" yaml:"estimated_hours"`
	ActualHrs    int      `json:"actual_hours" yaml:"actual_hours"`
	Assignee     string   `json:"assignee" yaml:"assignee"`
	Dependencies []string `json:"dependencies" yaml:"dependencies"`
	Tags         []string `json:"tags" yaml:"tags"`
	StartDate    string   `json:"start_date" yaml:"start_date"`
	EndDate      string   `json:"end_date" yaml:"end_date"`
	CreatedAt    string   `json:"created_at" yaml:"created_at"`
	UpdatedAt    string   `json:"updated_at" yaml:"updated_at"`
}

// Milestone represents a milestone
type Milestone struct {
	ID          string `json:"id" yaml:"id"`
	Name        string `json:"name" yaml:"name"`
	Description string `json:"description" yaml:"description"`
	Date        string `json:"date" yaml:"date"`
	Status      string `json:"status" yaml:"status"`
	Type        string `json:"type" yaml:"type"`
}

// Resource represents a project resource
type Resource struct {
	ID           string  `json:"id" yaml:"id"`
	Name         string  `json:"name" yaml:"name"`
	Type         string  `json:"type" yaml:"type"`
	Allocation   float64 `json:"allocation" yaml:"allocation"`
	Cost         float64 `json:"cost" yaml:"cost"`
	Availability string  `json:"availability" yaml:"availability"`
}

// FormatParser handles parsing different file formats
type FormatParser struct {
	supportedFormats map[FormatType]bool
}

// NewFormatParser creates a new format parser
func NewFormatParser() *FormatParser {
	return &FormatParser{
		supportedFormats: map[FormatType]bool{
			FormatJSON: true,
			FormatYAML: true,
		},
	}
}

// DetectFormat detects the format of a file based on extension and content
func (fp *FormatParser) DetectFormat(filePath string) FormatType {
	ext := strings.ToLower(filepath.Ext(filePath))

	switch ext {
	case ".json":
		return FormatJSON
	case ".yaml", ".yml":
		return FormatYAML
	case ".md", ".markdown":
		return FormatMarkdown
	default:
		// Try to detect by content
		return fp.detectByContent(filePath)
	}
}

// detectByContent tries to detect format by analyzing file content
func (fp *FormatParser) detectByContent(filePath string) FormatType {
	file, err := os.Open(filePath)
	if err != nil {
		return FormatUnknown
	}
	defer file.Close()

	// Read first 1KB to analyze
	buffer := make([]byte, 1024)
	n, err := file.Read(buffer)
	if err != nil && err != io.EOF {
		return FormatUnknown
	}

	content := string(buffer[:n])
	content = strings.TrimSpace(content)

	// Check for JSON
	if strings.HasPrefix(content, "{") || strings.HasPrefix(content, "[") {
		var test interface{}
		if json.Unmarshal([]byte(content), &test) == nil {
			return FormatJSON
		}
	}

	// Check for YAML
	if strings.Contains(content, ":") && !strings.HasPrefix(content, "{") {
		var test interface{}
		if yaml.Unmarshal([]byte(content), &test) == nil {
			return FormatYAML
		}
	}

	return FormatUnknown
}

// ParseFile parses a planning document file
func (fp *FormatParser) ParseFile(filePath string) (*PlanDocument, error) {
	format := fp.DetectFormat(filePath)
	if !fp.supportedFormats[format] {
		return nil, fmt.Errorf("unsupported format: %s", format)
	}

	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read file: %w", err)
	}

	return fp.ParseContent(data, format)
}

// ParseContent parses planning document content based on format
func (fp *FormatParser) ParseContent(data []byte, format FormatType) (*PlanDocument, error) {
	switch format {
	case FormatJSON:
		return fp.parseJSON(data)
	case FormatYAML:
		return fp.parseYAML(data)
	default:
		return nil, fmt.Errorf("unsupported format: %s", format)
	}
}

// parseJSON parses JSON content into a PlanDocument
func (fp *FormatParser) parseJSON(data []byte) (*PlanDocument, error) {
	var doc PlanDocument
	if err := json.Unmarshal(data, &doc); err != nil {
		return nil, fmt.Errorf("failed to parse JSON: %w", err)
	}

	doc.Format = FormatJSON
	return &doc, nil
}

// parseYAML parses YAML content into a PlanDocument
func (fp *FormatParser) parseYAML(data []byte) (*PlanDocument, error) {
	var doc PlanDocument
	if err := yaml.Unmarshal(data, &doc); err != nil {
		return nil, fmt.Errorf("failed to parse YAML: %w", err)
	}

	doc.Format = FormatYAML
	return &doc, nil
}

// ValidateFormat checks if the content is valid for the given format
func (fp *FormatParser) ValidateFormat(data []byte, format FormatType) error {
	switch format {
	case FormatJSON:
		var test interface{}
		return json.Unmarshal(data, &test)
	case FormatYAML:
		var test interface{}
		return yaml.Unmarshal(data, &test)
	default:
		return fmt.Errorf("unsupported format: %s", format)
	}
}

// ConvertFormat converts content from one format to another
func (fp *FormatParser) ConvertFormat(data []byte, fromFormat, toFormat FormatType) ([]byte, error) {
	if fromFormat == toFormat {
		return data, nil
	}

	// Parse source format
	doc, err := fp.ParseContent(data, fromFormat)
	if err != nil {
		return nil, fmt.Errorf("failed to parse source format: %w", err)
	}

	// Convert to target format
	switch toFormat {
	case FormatJSON:
		return json.MarshalIndent(doc, "", "  ")
	case FormatYAML:
		return yaml.Marshal(doc)
	default:
		return nil, fmt.Errorf("unsupported target format: %s", toFormat)
	}
}

// ConvertToYAML converts a PlanDocument to YAML format
func (fp *FormatParser) ConvertToYAML(doc *PlanDocument) ([]byte, error) {
	return yaml.Marshal(doc)
}

// ConvertToJSON converts a PlanDocument to JSON format
func (fp *FormatParser) ConvertToJSON(doc *PlanDocument) ([]byte, error) {
	return json.MarshalIndent(doc, "", "  ")
}

// GetSupportedFormats returns list of supported formats
func (fp *FormatParser) GetSupportedFormats() []FormatType {
	formats := make([]FormatType, 0, len(fp.supportedFormats))
	for format := range fp.supportedFormats {
		formats = append(formats, format)
	}
	return formats
}
