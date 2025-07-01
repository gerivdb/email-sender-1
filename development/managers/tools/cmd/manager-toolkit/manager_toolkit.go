package main

import (
	"EMAIL_SENDER_1/tools/core/toolkit"
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"time"
)

// Configuration constants specific to CLI
const (
	DefaultBaseDir = "d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers"
)

// OperationMapping maps CLI operation strings to toolkit.Operation constants
// This is crucial for decoupling CLI flags from internal operation representations.
var OperationMapping = map[string]toolkit.Operation{
	"analyze":              toolkit.Operation("analyze"),           // Assuming "analyze" is a custom/manual dispatch string
	"migrate":              toolkit.Operation("migrate"),           // Assuming "migrate" is a custom/manual dispatch string
	"fix-imports":          toolkit.Operation("fix-imports"),       // Custom/manual
	"remove-duplicates":    toolkit.Operation("remove-duplicates"), // Custom/manual
	"fix-syntax":           toolkit.Operation("fix-syntax"),        // Custom/manual
	"health-check":         toolkit.Operation("health-check"),      // Custom/manual
	"init-config":          toolkit.Operation("init-config"),       // Custom/manual
	"full-suite":           toolkit.Operation("full-suite"),        // Custom/manual
	"validate-structs":     toolkit.ValidateStructs,
	"resolve-imports":      toolkit.ResolveImports,
	"analyze-dependencies": toolkit.AnalyzeDeps,
	"detect-duplicates":    toolkit.DetectDuplicates,
	"check-syntax":         toolkit.SyntaxCheck, // Renamed from "syntax-check" to match toolkit
	"generate-typedefs":    toolkit.TypeDefGen,  // Renamed from "type-def-gen"
	"normalize-naming":     toolkit.NormalizeNaming,
}

func main() {
	var (
		operationStr = flag.String("op", "", "Operation to perform: analyze|migrate|fix-imports|remove-duplicates|fix-syntax|health-check|init-config|full-suite|validate-structs|resolve-imports|analyze-dependencies|detect-duplicates|check-syntax|generate-typedefs|normalize-naming")
		baseDir      = flag.String("dir", DefaultBaseDir, "Base directory to work with")
		configPath   = flag.String("config", "", "Path to configuration file (usually toolkit.config.json in basedir)")
		dryRun       = flag.Bool("dry-run", false, "Perform dry run without making changes")
		verbose      = flag.Bool("verbose", false, "Enable verbose logging")
		target       = flag.String("target", "", "Specific file or directory target")
		output       = flag.String("output", "", "Output file for reports")
		force        = flag.Bool("force", false, "Force operations without confirmation")
		help         = flag.Bool("help", false, "Show help information")
	)
	flag.Parse()

	if *help || *operationStr == "" {
		showHelp(*operationStr == "") // Pass true if op is empty to show full help
		return
	}

	// Map string operation to toolkit.Operation type
	op, ok := OperationMapping[*operationStr]
	if !ok {
		fmt.Printf("❌ ERROR: Unknown operation specified: %s\n\n", *operationStr)
		showHelp(true) // Show full help for unknown operation
		os.Exit(1)
	}

	// Initialize toolkit from the library
	// Note: configPath might be relative to baseDir or absolute.
	// NewManagerToolkit will handle default config creation if configPath is empty or not found.
	manager, err := toolkit.NewManagerToolkit(*baseDir, *configPath, *verbose)
	if err != nil {
		// NewManagerToolkit already logs, but CLI can add context
		log.Fatalf("Failed to initialize Manager Toolkit engine: %v", err)
	}
	defer manager.Close()

	// Set DryRun on the config if the flag is passed
	// The NewManagerToolkit already initializes Config.EnableDryRun to false.
	// If the config file sets it, that will be loaded. The CLI flag overrides.
	if *dryRun { // if CLI flag is true, it overrides config
		manager.Config.EnableDryRun = true
	}

	// Execute operation
	ctx := context.Background()
	opOptions := &toolkit.OperationOptions{
		Target:   *target,
		Output:   *output,
		Force:    *force,
		DryRun:   manager.Config.EnableDryRun, // Use the (potentially overridden) config value
		Verbose:  *verbose,                    // Pass verbose for operation-specific logging if needed
		Context:  ctx,                         // Pass context
		LogLevel: "INFO",                      // Default, could be configurable
		Workers:  manager.Config.MaxWorkers,   // Use from config
		Timeout:  30 * time.Minute,            // Example, could be configurable
	}

	if err := manager.ExecuteOperation(ctx, op, opOptions); err != nil {
		// Logger is part of manager, it would have logged details.
		// CLI can provide a simple exit message.
		fmt.Fprintf(os.Stderr, "Operation %s failed: %v\n", op, err)
		os.Exit(1)
	}

	manager.PrintFinalStats() // Uses the method now in toolkit package
	fmt.Println("Manager Toolkit operation completed successfully.")
}

// showHelp displays usage information
func showHelp(full bool) {
	// ToolVersion is now in toolkit package, access it if needed or define locally for CLI
	cliToolVersion := "3.0.0" // Can be distinct from library's ToolVersion if desired
	fmt.Printf(`Manager Toolkit CLI v%s - Professional Development Tools

Usage:
  manager-toolkit -op=<operation> [options]

Operations:
`, cliToolVersion)
	// Dynamically list operations from OperationMapping for better maintenance
	fmt.Println("  Available operations (use string value for -op flag):")
	for strOp := range OperationMapping {
		fmt.Printf("    %s\n", strOp)
	}
	fmt.Printf(`
  Examples:
    validate-structs    - Validates struct definitions.
    check-syntax        - Checks for syntax errors.
    analyze-dependencies- Analyzes project dependencies.
    ...and more.

Options:
  -dir string        Base directory (default: %s)
  -config string     Path to configuration file (e.g., toolkit.config.json)
  -dry-run           Perform dry run without making changes
  -verbose           Enable verbose logging
  -target string     Specific file or directory target for the operation
  -output string     Output file for reports
  -force             Force operations without confirmation
  -help              Show this help information

Examples:
  manager-toolkit -op=check-syntax -verbose
  manager-toolkit -op=fix-imports -dir=/path/to/project -dry-run
  manager-toolkit -op=full-suite -config=./myconfig.json
`, DefaultBaseDir)

	if full {
		// Potentially add more details if full help is requested
	}
}
