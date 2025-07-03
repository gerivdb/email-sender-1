package integration

import (
	"testing"

	"github.com/gerivdb/email-sender-1/integration/visualizer"
)

func TestNewExporter(t *testing.T) {
	exporter := NewExporter()
	if exporter == nil {
		t.Error("NewExporter should not return nil")
	}
}

func TestExporter_ExportMermaid(t *testing.T) {
	exporter := NewExporter()
	dependencies := []visualizer.Dependency{
		{Source: "A", Target: "B", Type: "uses"},
		{Source: "B", Target: "C", Type: "depends on"},
	}

	// Test with default graph type
	output, err := exporter.ExportMermaid(dependencies, "graph")
	if err != nil {
		t.Fatalf("ExportMermaid failed: %v", err)
	}
	expected := "graph TD\n    A -- uses --> B\n    B -- depends on --> C\n"
	if output != expected {
		t.Errorf("Mermaid output mismatch.\nExpected:\n%s\nGot:\n%s", expected, output)
	}

	// Test with empty dependencies
	output, err = exporter.ExportMermaid([]visualizer.Dependency{}, "graph")
	if err != nil {
		t.Fatalf("ExportMermaid failed: %v", err)
	}
	if output != "" {
		t.Errorf("Expected empty string for empty dependencies, got:\n%s", output)
	}
}

func TestExporter_ExportPlantUML(t *testing.T) {
	exporter := NewExporter()
	dependencies := []visualizer.Dependency{
		{Source: "Comp1", Target: "Comp2", Type: "calls"},
		{Source: "Comp2", Target: "DB", Type: "reads from"},
	}

	output, err := exporter.ExportPlantUML(dependencies)
	if err != nil {
		t.Fatalf("ExportPlantUML failed: %v", err)
	}
	expected := "@startuml\n[Comp1] --> [Comp2] : calls\n[Comp2] --> [DB] : reads from\n@enduml\n"
	if output != expected {
		t.Errorf("PlantUML output mismatch.\nExpected:\n%s\nGot:\n%s", expected, output)
	}

	// Test with empty dependencies
	output, err = exporter.ExportPlantUML([]visualizer.Dependency{})
	if err != nil {
		t.Fatalf("ExportPlantUML failed: %v", err)
	}
	if output != "" {
		t.Errorf("Expected empty string for empty dependencies, got:\n%s", output)
	}
}

func TestExporter_ExportGraphviz(t *testing.T) {
	exporter := NewExporter()
	dependencies := []visualizer.Dependency{
		{Source: "ServiceA", Target: "ServiceB", Type: "requests"},
		{Source: "ServiceB", Target: "Queue", Type: "publishes to"},
	}

	output, err := exporter.ExportGraphviz(dependencies)
	if err != nil {
		t.Fatalf("ExportGraphviz failed: %v", err)
	}
	expected := "digraph G {\n    \"ServiceA\" -> \"ServiceB\" [label=\"requests\"];\n    \"ServiceB\" -> \"Queue\" [label=\"publishes to\"];\n}\n"
	if output != expected {
		t.Errorf("Graphviz output mismatch.\nExpected:\n%s\nGot:\n%s", expected, output)
	}

	// Test with empty dependencies
	output, err = exporter.ExportGraphviz([]visualizer.Dependency{})
	if err != nil {
		t.Fatalf("ExportGraphviz failed: %v", err)
	}
	if output != "" {
		t.Errorf("Expected empty string for empty dependencies, got:\n%s", output)
	}
}

// Test with special characters in source/target/type
func TestExporter_SpecialCharacters(t *testing.T) {
	exporter := NewExporter()
	dependencies := []visualizer.Dependency{
		{Source: "A-1", Target: "B_2", Type: "depends on (critical)"},
	}

	output, err := exporter.ExportMermaid(dependencies, "graph")
	if err != nil {
		t.Fatalf("ExportMermaid failed: %v", err)
	}
	expectedMermaid := "graph TD\n    A-1 -- depends on (critical) --> B_2\n"
	if output != expectedMermaid {
		t.Errorf("Mermaid output with special characters mismatch.\nExpected:\n%s\nGot:\n%s", expectedMermaid, output)
	}

	output, err = exporter.ExportPlantUML(dependencies)
	if err != nil {
		t.Fatalf("ExportPlantUML failed: %v", err)
	}
	expectedPlantUML := "@startuml\n[A-1] --> [B_2] : depends on (critical)\n@enduml\n"
	if output != expectedPlantUML {
		t.Errorf("PlantUML output with special characters mismatch.\nExpected:\n%s\nGot:\n%s", expectedPlantUML, output)
	}

	output, err = exporter.ExportGraphviz(dependencies)
	if err != nil {
		t.Fatalf("ExportGraphviz failed: %v", err)
	}
	expectedGraphviz := "digraph G {\n    \"A-1\" -> \"B_2\" [label=\"depends on (critical)\"];\n}\n"
	if output != expectedGraphviz {
		t.Errorf("Graphviz output with special characters mismatch.\nExpected:\n%s\nGot:\n%s", expectedGraphviz, output)
	}
}
