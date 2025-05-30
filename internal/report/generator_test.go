package report

import (
	"bytes"
	"strings"
	"testing"
	"time"
)

func TestNewGenerator(t *testing.T) {
	generator, err := NewReportGenerator()
	if err != nil {
		t.Fatalf("NewReportGenerator returned error: %v", err)
	}
	if generator == nil {
		t.Fatal("NewReportGenerator returned nil")
	}
}

func TestGenerator_Generate(t *testing.T) {
	tests := []struct {
		name     string
		format   Format
		data     interface{}
		template string
		wantErr  bool
	}{
		{
			name:   "HTML Report",
			format: FormatHTML,
			data: struct {
				Title string
				Date  time.Time
			}{
				Title: "Test Report",
				Date:  time.Now(),
			},
			template: `<html><body><h1>{{.Title}}</h1><p>{{.Date}}</p></body></html>`,
			wantErr:  false,
		},
		{
			name:     "Invalid Template",
			format:   FormatHTML,
			data:     struct{}{},
			template: `{{.InvalidField}}`,
			wantErr:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			g := NewGenerator(tt.format)
			var buf bytes.Buffer
			err := g.Generate(&buf, tt.template, tt.data)

			if (err != nil) != tt.wantErr {
				t.Errorf("Generate() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if !tt.wantErr && !strings.Contains(buf.String(), tt.data.(struct {
				Title string
				Date  time.Time
			}).Title) {
				t.Errorf("Generate() output doesn't contain expected content")
			}
		})
	}
}

func TestGenerator_GenerateWithStats(t *testing.T) {
	g := NewGenerator(FormatHTML)
	stats := struct {
		Total   int
		Success int
		Failed  int
	}{
		Total:   10,
		Success: 8,
		Failed:  2,
	}

	var buf bytes.Buffer
	template := `Total: {{.Total}}, Success: {{.Success}}, Failed: {{.Failed}}`

	err := g.Generate(&buf, template, stats)
	if err != nil {
		t.Fatalf("GenerateWithStats failed: %v", err)
	}

	output := buf.String()
	expected := "Total: 10, Success: 8, Failed: 2"
	if !strings.Contains(output, expected) {
		t.Errorf("GenerateWithStats output = %q, want to contain %q", output, expected)
	}
}

func TestGenerator_ValidateTemplate(t *testing.T) {
	g := NewGenerator(FormatHTML)
	tests := []struct {
		name     string
		template string
		wantErr  bool
	}{
		{
			name:     "Valid Template",
			template: `<h1>{{.Title}}</h1>`,
			wantErr:  false,
		},
		{
			name:     "Invalid Template",
			template: `<h1>{{.Title}</h1>`,
			wantErr:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := g.validateTemplate(tt.template)
			if (err != nil) != tt.wantErr {
				t.Errorf("validateTemplate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
