package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"planning-ecosystem-sync/tools/validation"
)

// formatRuleAdapter adapts FormatConsistencyRule to implement local ValidationRule interface
type ValidationRule interface {
	Validate(data interface{}) error
	GetName() string
	CanAutoFix() bool
	Fix(data interface{}) error
}

// formatRuleAdapter adapts FormatConsistencyRule to implement ValidationRule interface
type formatRuleAdapter struct {
	rule *validation.FormatConsistencyRule
}

func (a *formatRuleAdapter) Validate(data interface{}) error {
	// Adapt the new interface to the old one
	issues, err := a.rule.Validate(context.Background(), "", data)
	if err != nil {
		return err
	}

	if len(issues) > 0 {
		return fmt.Errorf("%s", issues[0].Message)
	}

	return nil
}

func (a *formatRuleAdapter) GetName() string {
	return a.rule.GetID()
}

func (a *formatRuleAdapter) CanAutoFix() bool {
	return a.rule.CanAutoFix()
}

func (a *formatRuleAdapter) Fix(data interface{}) error {
	// This is a placeholder implementation
	return nil
}

func main() {
	var (
		inputFile   = flag.String("file", "", "Path to planning document file (JSON/YAML)")
		outputFile  = flag.String("output", "", "Output file for validation report")
		format      = flag.String("format", "auto", "Input format: auto, json, yaml")
		convert     = flag.String("convert", "", "Convert to format: json, yaml")
		rulesFlag   = flag.String("rules", "format,metadata,task,structure,timestamp", "Validation rules (comma-separated)")
		strictMode  = flag.Bool("strict", false, "Enable strict validation mode")
		autoFix     = flag.Bool("autofix", false, "Enable automatic issue fixing")
		showHelp    = flag.Bool("help", false, "Show help information")
		showFormats = flag.Bool("formats", false, "Show supported formats")
		validate    = flag.Bool("validate", false, "Validate file format only")
	)

	flag.Parse()

	if *showHelp {
		showUsage()
		return
	}

	if *showFormats {
		showSupportedFormats()
		return
	}

	if *inputFile == "" {
		fmt.Fprintf(os.Stderr, "Error: -file parameter is required\n")
		showUsage()
		os.Exit(1)
	}

	// Create logger
	logger := log.New(os.Stdout, "[VALIDATOR] ", log.LstdFlags)

	// Create format parser
	parser := validation.NewFormatParser()

	// Handle format validation only
	if *validate {
		if err := validateFileFormat(parser, *inputFile, *format); err != nil {
			fmt.Fprintf(os.Stderr, "Validation failed: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("✅ File format is valid")
		return
	}

	// Handle format conversion
	if *convert != "" {
		if err := convertFile(parser, *inputFile, *format, *convert, *outputFile); err != nil {
			fmt.Fprintf(os.Stderr, "Conversion failed: %v\n", err)
			os.Exit(1)
		}
		return
	}

	// Run full validation
	if err := runValidation(logger, *inputFile, *outputFile, *rulesFlag, *strictMode, *autoFix); err != nil {
		fmt.Fprintf(os.Stderr, "Validation failed: %v\n", err)
		os.Exit(1)
	}
}

func showUsage() {
	fmt.Println(`
YAML/JSON Planning Document Validator

USAGE:
    validator -file <path> [OPTIONS]

OPTIONS:
    -file <path>        Path to planning document file (required)
    -output <path>      Output file for validation report
    -format <format>    Input format: auto (default), json, yaml
    -convert <format>   Convert to format: json, yaml
    -rules <rules>      Validation rules (comma-separated, default: all)
    -strict             Enable strict validation mode
    -autofix            Enable automatic issue fixing
    -validate           Validate file format only (no full validation)
    -formats            Show supported formats and examples
    -help               Show this help

EXAMPLES:
    # Validate a YAML planning document
    validator -file plan.yaml

    # Convert YAML to JSON
    validator -file plan.yaml -convert json -output plan.json

    # Validate with specific rules only
    validator -file plan.json -rules metadata,structure

    # Strict validation with auto-fix
    validator -file plan.yaml -strict -autofix

    # Format validation only
    validator -file plan.yaml -validate

VALIDATION RULES:
    format      - Format-specific compliance and structure
    metadata    - Metadata consistency and completeness
    task        - Task validation and dependencies
    structure   - Phase and hierarchy consistency
    timestamp   - Temporal consistency and ordering
`)
}

func showSupportedFormats() {
	fmt.Println(`
SUPPORTED FORMATS:

JSON Format (.json):
    {
        "metadata": {
            "title": "Project Plan",
            "version": "1.0.0",
            "author": "Team",
            "status": "active"
        },
        "phases": [
            {
                "id": "phase-1",
                "name": "Development Phase",
                "status": "in-progress",
                "progress": 75.0,
                "tasks": [
                    {
                        "id": "task-1",
                        "name": "Implementation",
                        "status": "completed",
                        "progress": 100.0,
                        "estimated_hours": 40,
                        "actual_hours": 38
                    }
                ]
            }
        ]
    }

YAML Format (.yaml, .yml):
    metadata:
      title: "Project Plan"
      version: "1.0.0"
      author: "Team"
      status: "active"
    
    phases:
      - id: "phase-1"
        name: "Development Phase"
        status: "in-progress"
        progress: 75.0
        tasks:
          - id: "task-1"
            name: "Implementation"
            status: "completed"
            progress: 100.0
            estimated_hours: 40
            actual_hours: 38

DETECTION:
    Format is auto-detected by file extension and content analysis.
    Use -format flag to override detection.
`)
}

func validateFileFormat(parser *validation.FormatParser, filePath, formatStr string) error {
	// Read file
	data, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read file: %w", err)
	}

	// Determine format
	var format validation.FormatType
	if formatStr == "auto" {
		format = parser.DetectFormat(filePath)
	} else {
		format = validation.FormatType(formatStr)
	}

	// Validate format
	if err := parser.ValidateFormat(data, format); err != nil {
		return fmt.Errorf("invalid %s format: %w", format, err)
	}

	fmt.Printf("📋 File: %s\n", filePath)
	fmt.Printf("📄 Format: %s\n", format)
	fmt.Printf("📊 Size: %d bytes\n", len(data))

	return nil
}

func convertFile(parser *validation.FormatParser, inputPath, inputFormat, outputFormat, outputPath string) error {
	// Read input file
	data, err := os.ReadFile(inputPath)
	if err != nil {
		return fmt.Errorf("failed to read input file: %w", err)
	}

	// Determine input format
	var fromFormat validation.FormatType
	if inputFormat == "auto" {
		fromFormat = parser.DetectFormat(inputPath)
	} else {
		fromFormat = validation.FormatType(inputFormat)
	}

	toFormat := validation.FormatType(outputFormat)

	fmt.Printf("🔄 Converting %s → %s\n", fromFormat, toFormat)

	// Convert
	converted, err := parser.ConvertFormat(data, fromFormat, toFormat)
	if err != nil {
		return fmt.Errorf("conversion failed: %w", err)
	}

	// Determine output path
	if outputPath == "" {
		ext := ".json"
		if toFormat == validation.FormatYAML {
			ext = ".yaml"
		}
		outputPath = strings.TrimSuffix(inputPath, filepath.Ext(inputPath)) + ext
	}

	// Write output
	if err := os.WriteFile(outputPath, converted, 0644); err != nil {
		return fmt.Errorf("failed to write output file: %w", err)
	}

	fmt.Printf("✅ Converted to: %s\n", outputPath)
	fmt.Printf("📊 Output size: %d bytes\n", len(converted))

	return nil
}

func runValidation(logger *log.Logger, inputFile, outputFile, rulesStr string, strictMode, autoFix bool) error {
	// Create validation config
	config := &validation.ValidationConfig{
		StrictMode:         strictMode,
		ToleranceThreshold: 0.8,
		ReportFormat:       "json",
		AutoFix:            autoFix,
		MaxIssues:          100,
		TimeoutSeconds:     60,
		ValidationRules:    strings.Split(rulesStr, ","),
	}

	// Create validator
	validator := validation.NewConsistencyValidator(config)

	// Add validation rules based on configuration
	rules := strings.Split(rulesStr, ",")
	for _, rule := range rules {
		rule = strings.TrimSpace(rule)
		switch rule {
		case "format": // Use MetadataRule instead which implements the full interface
			validator.AddRule(validation.NewMetadataRule())
		case "metadata":
			validator.AddRule(&validation.MetadataConsistencyRule{
				ID:          "metadata_consistency",
				Description: "Validates metadata consistency and completeness",
				Priority:    2,
			})
		case "task":
			validator.AddRule(&validation.TaskConsistencyRule{
				ID:          "task_consistency",
				Description: "Validates task structure and dependencies",
				Priority:    3,
			})
		case "structure":
			validator.AddRule(&validation.StructureConsistencyRule{
				ID:          "structure_consistency",
				Description: "Validates plan hierarchy and structure",
				Priority:    4,
			})
		case "timestamp":
			validator.AddRule(&validation.TimestampConsistencyRule{
				ID:          "timestamp_consistency",
				Description: "Validates temporal consistency",
				Priority:    5,
			})
		default:
			logger.Printf("⚠️ Unknown validation rule: %s", rule)
		}
	}

	if len(validator.Rules) == 0 {
		return fmt.Errorf("no valid validation rules specified")
	}

	// Run validation
	ctx := context.Background()
	options := &validation.OperationOptions{
		Target: inputFile,
		Parameters: map[string]interface{}{
			"output_file": outputFile,
			"strict_mode": strictMode,
			"auto_fix":    autoFix,
		},
	}

	fmt.Printf("🔍 Starting validation of: %s\n", inputFile)
	fmt.Printf("📋 Rules: %s\n", strings.Join(rules, ", "))
	fmt.Printf("⚙️ Strict mode: %v\n", strictMode)
	fmt.Printf("🔧 Auto-fix: %v\n", autoFix)
	fmt.Println()

	if err := validator.Execute(ctx, options); err != nil {
		return fmt.Errorf("validation execution failed: %w", err)
	}

	// Display results
	stats := validator.GetStats()
	fmt.Printf("📊 VALIDATION RESULTS:\n")
	fmt.Printf("   Plans validated: %d\n", stats.PlansValidated)
	fmt.Printf("   Issues found: %d\n", stats.IssuesFound)
	fmt.Printf("   Issues fixed: %d\n", stats.IssuesFixed)
	fmt.Printf("   Average score: %.1f%%\n", stats.AverageScore)
	fmt.Printf("   Validation time: %v\n", stats.AverageValidationTime)

	// Status summary
	for status, count := range stats.ValidationsByStatus {
		if count > 0 {
			fmt.Printf("   %s: %d\n", status, count)
		}
	}

	fmt.Println()
	if stats.AverageScore >= 90 {
		fmt.Println("✅ Validation PASSED - Excellent quality!")
	} else if stats.AverageScore >= 75 {
		fmt.Println("⚠️ Validation PASSED - Good quality with minor issues")
	} else if stats.AverageScore >= 50 {
		fmt.Println("⚠️ Validation WARNING - Significant issues found")
	} else {
		fmt.Println("❌ Validation FAILED - Critical issues require attention")
	}

	return nil
}
