package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/gerivdb/email-sender-1/integration/visualizer" // Adjust module path as needed
)

func main() {
	outputFile := flag.String("output", "", "Output file for the Mermaid graph (default: stdout)")
	flag.Parse()

	// Example dependencies (replace with actual dependency mapping later)
	deps := []visualizer.Dependency{
		{Source: "ComponentA", Target: "ComponentB", Type: "uses"},
		{Source: "ComponentB", Target: "ComponentC", Type: "calls"},
		{Source: "ComponentA", Target: "ComponentC", Type: "generates"},
	}

	mermaidGraph := visualizer.GenerateMermaidGraph(deps, "graph")

	if *outputFile != "" {
		absOutputFile, err := filepath.Abs(*outputFile)
		if err != nil {
			log.Fatalf("Error getting absolute path for output file %s: %v", *outputFile, err)
		}
		log.Printf("Attempting to write Mermaid graph to: %s", absOutputFile)

		err = os.WriteFile(*outputFile, []byte(mermaidGraph), 0o644)
		if err != nil {
			log.Fatalf("Error writing to output file %s: %v", *outputFile, err)
		}
		fmt.Printf("Mermaid graph written to %s\n", *outputFile)
	} else {
		fmt.Print(mermaidGraph)
	}
}
