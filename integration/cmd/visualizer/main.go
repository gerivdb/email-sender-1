package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/gerivdb/email-sender-1/integration"
	"github.com/gerivdb/email-sender-1/integration/visualizer"
)

func main() {
	outputFile := flag.String("output", "", "Output file for the graph (default: stdout)")
	outputFormat := flag.String("format", "mermaid", "Output format: mermaid, plantuml, or graphviz")
	flag.Parse()

	// Example dependencies (replace with actual dependency mapping later)
	deps := []visualizer.Dependency{
		{Source: "ComponentA", Target: "ComponentB", Type: "uses"},
		{Source: "ComponentB", Target: "ComponentC", Type: "calls"},
		{Source: "ComponentA", Target: "ComponentC", Type: "generates"},
	}

	exporter := integration.NewExporter()
	var graphOutput string
	var err error

	switch *outputFormat {
	case "mermaid":
		graphOutput, err = exporter.ExportMermaid(deps, "graph")
	case "plantuml":
		graphOutput, err = exporter.ExportPlantUML(deps)
	case "graphviz":
		graphOutput, err = exporter.ExportGraphviz(deps)
	default:
		log.Fatalf("Unsupported output format: %s", *outputFormat)
	}

	if err != nil {
		log.Fatalf("Error generating graph: %v", err)
	}

	if *outputFile != "" {
		absOutputFile, err := filepath.Abs(*outputFile)
		if err != nil {
			log.Fatalf("Error getting absolute path for output file %s: %v", *outputFile, err)
		}
		log.Printf("Attempting to write graph to: %s", absOutputFile)

		err = os.WriteFile(*outputFile, []byte(graphOutput), 0o644)
		if err != nil {
			log.Fatalf("Error writing to output file %s: %v", *outputFile, err)
		}
		fmt.Printf("Graph written to %s in %s format\n", *outputFile, *outputFormat)
	} else {
		fmt.Print(graphOutput)
	}
}
