// Package report provides report generation functionality
package report

import (
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"time"

	"email_sender/internal/report/diff"
	"email_sender/internal/report/stats"
)

// Format represents the output format of a report
type Format string

const (
	// FormatHTML generates HTML reports
	FormatHTML Format = "html"
	// FormatJSON generates JSON reports
	FormatJSON Format = "json"
	// FormatMarkdown generates Markdown reports
	FormatMarkdown Format = "md"
	// FormatText generates plain text reports
	FormatText Format = "txt"
)

// Report represents a report
type Report struct {
	Title      string
	Generated  time.Time
	Summary    string
	Sections   []Section
	Statistics *stats.ErrorStats
}

// Section represents a section in a report
type Section struct {
	Title    string
	Content  string
	Changes  *diff.UnifiedDiff
	Metadata map[string]interface{}
}

// ReportGenerator generates reports
type ReportGenerator struct {
	templates map[Format]*template.Template
}

// NewReportGenerator creates a new ReportGenerator instance
func NewReportGenerator() (*ReportGenerator, error) {
	rg := &ReportGenerator{
		templates: make(map[Format]*template.Template),
	}

	// Load default templates
	defaultTemplates := map[Format]string{
		FormatHTML:     defaultHTMLTemplate,
		FormatText:     defaultTextTemplate,
		FormatMarkdown: defaultMarkdownTemplate,
	}

	for format, tmpl := range defaultTemplates {
		t, err := template.New(string(format)).Parse(tmpl)
		if err != nil {
			return nil, fmt.Errorf("failed to parse template for format %s: %w", format, err)
		}
		rg.templates[format] = t
	}

	return rg, nil
}

// Generate generates a report in the specified format
func (rg *ReportGenerator) Generate(report *Report, format Format, w io.Writer) error {
	switch format {
	case FormatJSON:
		return json.NewEncoder(w).Encode(report)
	case FormatHTML, FormatText, FormatMarkdown:
		tmpl, ok := rg.templates[format]
		if !ok {
			return fmt.Errorf("no template found for format: %s", format)
		}
		return tmpl.Execute(w, report)
	default:
		return fmt.Errorf("unsupported format: %s", format)
	}
}

// Generator provides a simplified interface for template-based report generation
type Generator struct {
	format Format
}

// NewGenerator creates a new Generator instance for the specified format
func NewGenerator(format Format) *Generator {
	return &Generator{
		format: format,
	}
}

// Generate generates output using the provided template and data
func (g *Generator) Generate(w io.Writer, templateStr string, data interface{}) error {
	tmpl, err := template.New("generator").Parse(templateStr)
	if err != nil {
		return fmt.Errorf("failed to parse template: %w", err)
	}

	return tmpl.Execute(w, data)
}

// validateTemplate validates a template string
func (g *Generator) validateTemplate(templateStr string) error {
	_, err := template.New("validation").Parse(templateStr)
	return err
}

// Default templates
const (
	defaultHTMLTemplate = `<!DOCTYPE html>
<html>
<head>
    <title>{{.Title}}</title>
</head>
<body>
    <h1>{{.Title}}</h1>
    <p>Generated: {{.Generated}}</p>
    <p>{{.Summary}}</p>
    {{range .Sections}}
    <section>
        <h2>{{.Title}}</h2>
        <div>{{.Content}}</div>
    </section>
    {{end}}
</body>
</html>`

	defaultTextTemplate = `{{.Title}}
Generated: {{.Generated}}

{{.Summary}}

{{range .Sections}}
== {{.Title}} ==
{{.Content}}

{{end}}`

	defaultMarkdownTemplate = `# {{.Title}}

Generated: {{.Generated}}

{{.Summary}}

{{range .Sections}}
## {{.Title}}

{{.Content}}

{{end}}`
)
