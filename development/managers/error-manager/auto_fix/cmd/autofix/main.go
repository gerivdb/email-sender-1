package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	autofix "github.com/gerivdb/email-sender-1/managers/error-manager/auto_fix"
)

const (
	version = "1.0.0"
	appName = "autofix-cli"
)

// Command-line flags
var (
	projectPath        = flag.String("project", ".", "Path to the project to analyze")
	interactive        = flag.Bool("interactive", true, "Enable interactive mode")
	autoApplyThreshold = flag.Float64("auto-threshold", 0.9, "Auto-apply threshold (0.0-1.0)")
	showDiffs          = flag.Bool("diffs", true, "Show code diffs")
	backupFiles        = flag.Bool("backup", true, "Create backup files before applying fixes")
	outputFormat       = flag.String("format", "colored", "Output format (text, json, colored)")
	maxSuggestions     = flag.Int("max-suggestions", 50, "Maximum number of suggestions to process")
	configFile         = flag.String("config", "", "Configuration file path")
	sandboxTimeout     = flag.Duration("timeout", 5*time.Minute, "Sandbox timeout")
	enableTests        = flag.Bool("tests", true, "Enable test execution in sandbox")
	enableStaticCheck  = flag.Bool("static-check", true, "Enable static analysis")
	preserveArtifacts  = flag.Bool("preserve", false, "Preserve sandbox artifacts for debugging")
	showVersion        = flag.Bool("version", false, "Show version information")
	showHelp           = flag.Bool("help", false, "Show help information")
)

func main() {
	flag.Parse()

	if *showVersion {
		fmt.Printf("%s version %s\n", appName, version)
		os.Exit(0)
	}

	if *showHelp {
		printHelp()
		os.Exit(0)
	}

	// Validate project path
	if _, err := os.Stat(*projectPath); os.IsNotExist(err) {
		log.Fatalf("Project path does not exist: %s", *projectPath)
	}

	// Convert to absolute path
	absProjectPath, err := filepath.Abs(*projectPath)
	if err != nil {
		log.Fatalf("Failed to get absolute path: %v", err)
	}

	fmt.Printf("🔧 %s v%s\n", appName, version)
	fmt.Printf("📁 Project: %s\n", absProjectPath)
	fmt.Println()
	// Initialize components
	engineConfig := autofix.EngineConfig{
		EnableAutoFix:        *interactive,
		MaxConfidenceForAuto: *autoApplyThreshold,
		EnabledCategories:    []autofix.FixCategory{autofix.CategoryBugFix, autofix.CategoryCodeQuality},
		SafetyLevel:          autofix.SafetyLevelHigh,
		BackupEnabled:        *backupFiles,
		ValidationEnabled:    *enableStaticCheck,
	}

	suggestionEngine := autofix.NewSuggestionEngine(engineConfig)

	sandboxConfig := autofix.SandboxConfig{
		Timeout:           *sandboxTimeout,
		EnableTests:       *enableTests,
		EnableStaticCheck: *enableStaticCheck,
		PreserveArtifacts: *preserveArtifacts,
		AllowNetworking:   false,
	}

	validationSystem := autofix.NewValidationSystem(sandboxConfig)

	cliConfig := autofix.CLIConfig{
		AutoApplyThreshold: *autoApplyThreshold,
		InteractiveMode:    *interactive,
		ShowDiffs:          *showDiffs,
		BackupFiles:        *backupFiles,
		OutputFormat:       *outputFormat,
		MaxSuggestions:     *maxSuggestions,
		LogActions:         true,
		Timeout:            *sandboxTimeout,
	}

	// Load configuration file if specified
	if *configFile != "" {
		if err := loadConfigFile(*configFile, &cliConfig); err != nil {
			log.Printf("Warning: Failed to load config file: %v", err)
		}
	}
	cli := autofix.NewCLIInterface(suggestionEngine, validationSystem, cliConfig)

	// Start review session
	ctx := context.Background()
	session, err := cli.StartReviewSession(ctx, absProjectPath)
	if err != nil {
		log.Fatalf("Review session failed: %v", err)
	}

	// Save session results
	sessionFile := fmt.Sprintf("autofix_session_%d.json", time.Now().Unix())
	if err := cli.SaveSession(session, sessionFile); err != nil {
		log.Printf("Warning: Failed to save session: %v", err)
	} else {
		fmt.Printf("📊 Session saved to: %s\n", sessionFile)
	}

	// Exit with appropriate code
	if session.SuggestionsApplied > 0 {
		fmt.Printf("\n✅ Successfully applied %d fixes!\n", session.SuggestionsApplied)
		os.Exit(0)
	} else if session.SuggestionsTotal == 0 {
		fmt.Println("\n🎉 No fixes needed - code looks great!")
		os.Exit(0)
	} else {
		fmt.Printf("\n⚠️  No fixes were applied (%d suggestions available)\n", session.SuggestionsTotal)
		os.Exit(1)
	}
}

// printHelp prints help information
func printHelp() {
	fmt.Printf(`%s v%s - Automated Go Code Fix Tool

USAGE:
    %s [OPTIONS] [PROJECT_PATH]

OPTIONS:
    -project PATH           Path to the project to analyze (default: ".")
    -interactive            Enable interactive mode (default: true)
    -auto-threshold FLOAT   Auto-apply threshold 0.0-1.0 (default: 0.9)
    -diffs                  Show code diffs (default: true)
    -backup                 Create backup files (default: true)
    -format FORMAT          Output format: text, json, colored (default: "colored")
    -max-suggestions INT    Maximum suggestions to process (default: 50)
    -config FILE            Configuration file path
    -timeout DURATION       Sandbox timeout (default: 5m)
    -tests                  Enable test execution (default: true)
    -static-check           Enable static analysis (default: true)
    -preserve               Preserve sandbox artifacts (default: false)
    -version                Show version information
    -help                   Show this help

EXAMPLES:
    # Analyze current directory interactively
    %s

    # Analyze specific project with auto-apply
    %s -project ./my-project -auto-threshold 0.8

    # Non-interactive mode with JSON output
    %s -interactive=false -format json

    # Quick fixes only (no tests)
    %s -tests=false -timeout 1m

CONFIGURATION:
    You can use a JSON configuration file to set default options:
    
    {
        "auto_apply_threshold": 0.9,
        "interactive_mode": true,
        "show_diffs": true,
        "backup_files": true,
        "output_format": "colored",
        "max_suggestions": 50
    }

EXIT CODES:
    0    Success (fixes applied or no fixes needed)
    1    No fixes applied (suggestions available)
    2    Error occurred

For more information, visit: https://github.com/your-org/autofix-cli
`, appName, version, appName, appName, appName, appName, appName)
}

// loadConfigFile loads configuration from a JSON file
func loadConfigFile(configPath string, config *autofix.CLIConfig) error {
	// Implementation would load and parse JSON config file
	// This is a placeholder - actual implementation would use json.Unmarshal
	return nil
}
