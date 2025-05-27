// Code Generator CLI - executes the code generation framework
package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"email_sender/internal/codegen"
)

func main() {
	var (
		genType = flag.String("type", "", "Generation type: service, cli, handler")
		spec    = flag.String("spec", "", "Specification for generation")
		output  = flag.String("output", "generated", "Output directory")
	)
	flag.Parse()

	if *genType == "" {
		fmt.Println("Usage: codegen -type=<service|cli|handler> [-spec=<spec>] [-output=<dir>]")
		os.Exit(1)
	}
	config := &codegen.GeneratorConfig{
		OutputDir:     *output,
		PackageName:   "generated",
		TemplateDir:   "templates",
		EnableMetrics: true,
		EnableMocks:   true,
	}

	generator := codegen.NewGenerator(config)

	// Ensure output directory exists
	if err := os.MkdirAll(*output, 0755); err != nil {
		log.Fatalf("Failed to create output directory: %v", err)
	}
	switch *genType {
	case "service":
		if err := generator.GenerateRAGService(); err != nil {
			log.Fatalf("Service generation failed: %v", err)
		}
		fmt.Printf("✅ RAG Service generated successfully\n")
	case "cli":
		if err := generator.GenerateCLI(); err != nil {
			log.Fatalf("CLI generation failed: %v", err)
		}
		fmt.Printf("✅ CLI commands generated successfully\n")

	case "handler":
		if *spec == "" {
			log.Fatal("Handler generation requires -spec parameter")
		}
		// Create a simple component spec for handler generation
		componentSpec := codegen.ComponentSpec{
			Name:    *spec,
			Type:    "handler",
			Package: "handlers",
		}
		if err := generator.GenerateComponent(componentSpec); err != nil {
			log.Fatalf("Handler generation failed: %v", err)
		}
		fmt.Printf("✅ Handler %s generated successfully\n", *spec)

	default:
		log.Fatalf("Unknown generation type: %s", *genType)
	}
}
