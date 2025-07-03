package integration

import (
	"fmt"
	"strings"

	"github.com/gerivdb/email-sender-1/integration/visualizer" // Import the visualizer package
)

// IExporter defines the interface for exporting data to various standard formats.
type IExporter interface {
	// ExportMermaid exports a list of dependencies to Mermaid graph format.
	ExportMermaid(dependencies []visualizer.Dependency, graphType string) (string, error)
	// ExportPlantUML exports a list of dependencies to PlantUML format.
	ExportPlantUML(dependencies []visualizer.Dependency) (string, error)
	// ExportGraphviz exports a list of dependencies to Graphviz DOT format.
	ExportGraphviz(dependencies []visualizer.Dependency) (string, error)
}

// Exporter implements the IExporter interface.
type Exporter struct{}

// NewExporter creates a new instance of Exporter.
func NewExporter() IExporter {
	return &Exporter{}
}

// ExportMermaid exports a list of dependencies to Mermaid graph format.
func (e *Exporter) ExportMermaid(dependencies []visualizer.Dependency, graphType string) (string, error) {
	if len(dependencies) == 0 {
		return "", nil
	}
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("%s TD\n", graphType)) // Default to Graph TD for now

	for _, dep := range dependencies {
		// Example: A -->|uses| B
		sb.WriteString(fmt.Sprintf("    %s -- %s --> %s\n", dep.Source, dep.Type, dep.Target))
	}
	return sb.String(), nil
}

// ExportPlantUML exports a list of dependencies to PlantUML format.
func (e *Exporter) ExportPlantUML(dependencies []visualizer.Dependency) (string, error) {
	if len(dependencies) == 0 {
		return "", nil
	}
	var sb strings.Builder
	sb.WriteString("@startuml\n")
	for _, dep := range dependencies {
		// Example: [Source] --> (Target) : Type
		sb.WriteString(fmt.Sprintf("[%s] --> [%s] : %s\n", dep.Source, dep.Target, dep.Type))
	}
	sb.WriteString("@enduml\n")
	return sb.String(), nil
}

// ExportGraphviz exports a list of dependencies to Graphviz DOT format.
func (e *Exporter) ExportGraphviz(dependencies []visualizer.Dependency) (string, error) {
	if len(dependencies) == 0 {
		return "", nil
	}
	var sb strings.Builder
	sb.WriteString("digraph G {\n")
	for _, dep := range dependencies {
		// Example: "Source" -> "Target" [label="Type"];
		sb.WriteString(fmt.Sprintf("    \"%s\" -> \"%s\" [label=\"%s\"];\n", dep.Source, dep.Target, dep.Type))
	}
	sb.WriteString("}\n")
	return sb.String(), nil
}
