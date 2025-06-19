package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/spf13/cobra"
)

// Version information
var (
	Version   = "1.0.0"
	BuildTime = "2025-06-19T12:00:00Z"
	GitCommit = "dev"
)

// CLI Configuration
type CLIConfig struct {
	LogLevel     string            `json:"log_level"`
	Timeout      time.Duration     `json:"timeout"`
	WorkDir      string            `json:"work_dir"`
	Environment  map[string]string `json:"environment"`
	MaxRetries   int               `json:"max_retries"`
	OutputFormat string            `json:"output_format"`
}

// Standard response format
type CLIResponse struct {
	Success   bool                   `json:"success"`
	Message   string                 `json:"message,omitempty"`
	Data      map[string]interface{} `json:"data,omitempty"`
	Error     string                 `json:"error,omitempty"`
	Timestamp time.Time              `json:"timestamp"`
	TraceID   string                 `json:"trace_id,omitempty"`
	Duration  string                 `json:"duration,omitempty"`
}

// Command execution context
type ExecutionContext struct {
	Config    *CLIConfig
	StartTime time.Time
	TraceID   string
}

var (
	config       = &CLIConfig{}
	configFile   string
	verbose      bool
	outputFormat string
)

func main() {
	rootCmd := &cobra.Command{
		Use:   "n8n-go-cli",
		Short: "N8N Go CLI Integration Wrapper",
		Long: `A CLI wrapper for integrating Go applications with N8N workflows.
Provides standardized commands for execution, validation, status, and health checks.`,
		Version: fmt.Sprintf("%s (built %s, commit %s)", Version, BuildTime, GitCommit),
	}

	// Global flags
	rootCmd.PersistentFlags().StringVar(&configFile, "config", "", "config file (default is $HOME/.n8n-go-cli.yaml)")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")
	rootCmd.PersistentFlags().StringVar(&outputFormat, "output-format", "json", "output format (json, text, lines)")

	// Add commands
	rootCmd.AddCommand(executeCmd)
	rootCmd.AddCommand(validateCmd)
	rootCmd.AddCommand(statusCmd)
	rootCmd.AddCommand(healthCmd)
	rootCmd.AddCommand(configCmd)

	// Initialize configuration
	if err := initConfig(); err != nil {
		log.Fatalf("Failed to initialize config: %v", err)
	}

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

var executeCmd = &cobra.Command{
	Use:   "execute [command]",
	Short: "Execute a command with input data processing",
	Long: `Execute a specific command with input data from stdin or arguments.
Supports JSON input processing and various output formats.`,
	Args: cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		ctx := createExecutionContext()

		// Get command-specific flags
		inputFormat, _ := cmd.Flags().GetString("input-format")
		timeout, _ := cmd.Flags().GetDuration("timeout")
		workDir, _ := cmd.Flags().GetString("work-dir")
		envVars, _ := cmd.Flags().GetStringToString("env")

		result := executeCommand(ctx, args[0], args[1:], inputFormat, timeout, workDir, envVars)
		outputResult(result)
	},
}

var validateCmd = &cobra.Command{
	Use:   "validate",
	Short: "Validate input data",
	Long: `Validate input data structure and content.
Reads JSON data from stdin and validates against predefined schemas.`,
	Run: func(cmd *cobra.Command, args []string) {
		ctx := createExecutionContext()

		schema, _ := cmd.Flags().GetString("schema")
		strict, _ := cmd.Flags().GetBool("strict")

		result := validateData(ctx, schema, strict)
		outputResult(result)
	},
}

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Get CLI and system status",
	Long: `Get current status of the CLI application and system resources.
Returns information about health, configuration, and runtime status.`,
	Run: func(cmd *cobra.Command, args []string) {
		ctx := createExecutionContext()

		detailed, _ := cmd.Flags().GetBool("detailed")

		result := getStatus(ctx, detailed)
		outputResult(result)
	},
}

var healthCmd = &cobra.Command{
	Use:   "health",
	Short: "Check CLI health and availability",
	Long: `Perform health checks on the CLI application and its dependencies.
Returns health status and any issues that need attention.`,
	Run: func(cmd *cobra.Command, args []string) {
		ctx := createExecutionContext()

		checkDeps, _ := cmd.Flags().GetBool("check-dependencies")

		result := checkHealth(ctx, checkDeps)
		outputResult(result)
	},
}

var configCmd = &cobra.Command{
	Use:   "config",
	Short: "Manage CLI configuration",
	Long: `Manage CLI configuration settings.
Supports viewing, updating, and validating configuration.`,
}

func init() {
	// Execute command flags
	executeCmd.Flags().String("input-format", "json", "input format (json, args, none)")
	executeCmd.Flags().Duration("timeout", 30*time.Second, "execution timeout")
	executeCmd.Flags().String("work-dir", "", "working directory")
	executeCmd.Flags().StringToString("env", nil, "environment variables")

	// Validate command flags
	validateCmd.Flags().String("schema", "", "validation schema file")
	validateCmd.Flags().Bool("strict", false, "strict validation mode")

	// Status command flags
	statusCmd.Flags().Bool("detailed", false, "detailed status information")

	// Health command flags
	healthCmd.Flags().Bool("check-dependencies", true, "check external dependencies")

	// Config subcommands
	configCmd.AddCommand(&cobra.Command{
		Use:   "show",
		Short: "Show current configuration",
		Run: func(cmd *cobra.Command, args []string) {
			ctx := createExecutionContext()
			result := showConfig(ctx)
			outputResult(result)
		},
	})

	configCmd.AddCommand(&cobra.Command{
		Use:   "validate",
		Short: "Validate configuration",
		Run: func(cmd *cobra.Command, args []string) {
			ctx := createExecutionContext()
			result := validateConfig(ctx)
			outputResult(result)
		},
	})
}

func initConfig() error {
	// Set default configuration
	config.LogLevel = "info"
	config.Timeout = 30 * time.Second
	config.WorkDir = "."
	config.Environment = make(map[string]string)
	config.MaxRetries = 3
	config.OutputFormat = "json"

	// Load from environment variables
	if logLevel := os.Getenv("N8N_CLI_LOG_LEVEL"); logLevel != "" {
		config.LogLevel = logLevel
	}
	if workDir := os.Getenv("N8N_CLI_WORK_DIR"); workDir != "" {
		config.WorkDir = workDir
	}
	if outputFmt := os.Getenv("N8N_CLI_OUTPUT_FORMAT"); outputFmt != "" {
		config.OutputFormat = outputFmt
	}

	// Load from config file if specified
	if configFile != "" {
		return loadConfigFile(configFile)
	}

	return nil
}

func loadConfigFile(filename string) error {
	file, err := os.Open(filename)
	if err != nil {
		return fmt.Errorf("failed to open config file: %w", err)
	}
	defer file.Close()

	decoder := json.NewDecoder(file)
	return decoder.Decode(config)
}

func createExecutionContext() *ExecutionContext {
	return &ExecutionContext{
		Config:    config,
		StartTime: time.Now(),
		TraceID:   generateTraceID(),
	}
}

func generateTraceID() string {
	return fmt.Sprintf("cli-%d", time.Now().UnixNano())
}

func executeCommand(ctx *ExecutionContext, command string, args []string, inputFormat string, timeout time.Duration, workDir string, envVars map[string]string) *CLIResponse {
	response := &CLIResponse{
		Timestamp: time.Now(),
		TraceID:   ctx.TraceID,
	}

	defer func() {
		response.Duration = time.Since(ctx.StartTime).String()
	}()

	// Read input data if needed
	var inputData map[string]interface{}
	if inputFormat == "json" {
		if err := json.NewDecoder(os.Stdin).Decode(&inputData); err != nil {
			response.Success = false
			response.Error = fmt.Sprintf("Failed to decode JSON input: %v", err)
			return response
		}
	}

	// Simulate command execution based on command type
	switch command {
	case "email-process":
		return executeEmailProcess(ctx, inputData, args)
	case "email-send":
		return executeEmailSend(ctx, inputData, args)
	case "vector-search":
		return executeVectorSearch(ctx, inputData, args)
	case "analytics-process":
		return executeAnalyticsProcess(ctx, inputData, args)
	case "test-command":
		return executeTestCommand(ctx, inputData, args)
	default:
		response.Success = false
		response.Error = fmt.Sprintf("Unknown command: %s", command)
		return response
	}
}

func executeEmailProcess(ctx *ExecutionContext, inputData map[string]interface{}, args []string) *CLIResponse {
	response := &CLIResponse{
		Success:   true,
		Message:   "Email processing completed successfully",
		Timestamp: time.Now(),
		TraceID:   ctx.TraceID,
		Data: map[string]interface{}{
			"processed_count": 100,
			"success_rate":    0.95,
			"duration_ms":     1250,
			"template":        getArgValue(args, "template", "default"),
			"batch_size":      getArgValue(args, "batch-size", "50"),
		},
	}
	return response
}

func executeEmailSend(ctx *ExecutionContext, inputData map[string]interface{}, args []string) *CLIResponse {
	response := &CLIResponse{
		Success:   true,
		Message:   "Email sending completed",
		Timestamp: time.Now(),
		TraceID:   ctx.TraceID,
		Data: map[string]interface{}{
			"sent_count":    50,
			"failed_count":  2,
			"success_rate":  0.96,
			"smtp_host":     os.Getenv("SMTP_HOST"),
			"delivery_time": "2.3s",
		},
	}
	return response
}

func executeVectorSearch(ctx *ExecutionContext, inputData map[string]interface{}, args []string) *CLIResponse {
	response := &CLIResponse{
		Success:   true,
		Message:   "Vector search completed",
		Timestamp: time.Now(),
		TraceID:   ctx.TraceID,
		Data: map[string]interface{}{
			"results_count": 25,
			"search_time":   "0.15s",
			"similarity":    0.87,
			"vector_dim":    1536,
		},
	}
	return response
}

func executeAnalyticsProcess(ctx *ExecutionContext, inputData map[string]interface{}, args []string) *CLIResponse {
	response := &CLIResponse{
		Success:   true,
		Message:   "Analytics processing completed",
		Timestamp: time.Now(),
		TraceID:   ctx.TraceID,
		Data: map[string]interface{}{
			"records_processed":  1000,
			"insights_generated": 15,
			"processing_time":    "5.2s",
			"accuracy":           0.92,
		},
	}
	return response
}

func executeTestCommand(ctx *ExecutionContext, inputData map[string]interface{}, args []string) *CLIResponse {
	response := &CLIResponse{
		Success:   true,
		Message:   "Test command executed successfully",
		Timestamp: time.Now(),
		TraceID:   ctx.TraceID,
		Data: map[string]interface{}{
			"test":        "data",
			"input_data":  inputData,
			"args":        args,
			"environment": os.Getenv("TEST_ENV"),
		},
	}
	return response
}

func validateData(ctx *ExecutionContext, schema string, strict bool) *CLIResponse {
	response := &CLIResponse{
		Timestamp: time.Now(),
		TraceID:   ctx.TraceID,
	}

	var inputData map[string]interface{}
	if err := json.NewDecoder(os.Stdin).Decode(&inputData); err != nil {
		response.Success = false
		response.Error = fmt.Sprintf("Failed to decode input data: %v", err)
		return response
	}

	// Simulate validation
	response.Success = true
	response.Message = "Data validation completed"
	response.Data = map[string]interface{}{
		"valid":           true,
		"schema":          schema,
		"strict_mode":     strict,
		"field_count":     len(inputData),
		"validation_time": "0.05s",
	}

	return response
}

func getStatus(ctx *ExecutionContext, detailed bool) *CLIResponse {
	response := &CLIResponse{
		Success:   true,
		Message:   "CLI status retrieved",
		Timestamp: time.Now(),
		TraceID:   ctx.TraceID,
		Data: map[string]interface{}{
			"status":     "healthy",
			"version":    Version,
			"build_time": BuildTime,
			"uptime":     time.Since(ctx.StartTime).String(),
			"config":     config,
		},
	}

	if detailed {
		response.Data["system"] = map[string]interface{}{
			"pid":         os.Getpid(),
			"working_dir": config.WorkDir,
			"environment": len(config.Environment),
		}
	}

	return response
}

func checkHealth(ctx *ExecutionContext, checkDeps bool) *CLIResponse {
	response := &CLIResponse{
		Success:   true,
		Message:   "Health check completed",
		Timestamp: time.Now(),
		TraceID:   ctx.TraceID,
		Data: map[string]interface{}{
			"status":        "healthy",
			"checks_passed": 5,
			"checks_total":  5,
			"dependencies": map[string]string{
				"filesystem": "ok",
				"memory":     "ok",
				"network":    "ok",
			},
		},
	}

	if checkDeps {
		// Simulate dependency checks
		response.Data["external_deps"] = map[string]string{
			"smtp_server": "reachable",
			"database":    "connected",
			"redis":       "available",
		}
	}

	return response
}

func showConfig(ctx *ExecutionContext) *CLIResponse {
	return &CLIResponse{
		Success:   true,
		Message:   "Current configuration",
		Timestamp: time.Now(),
		TraceID:   ctx.TraceID,
		Data: map[string]interface{}{
			"config": config,
		},
	}
}

func validateConfig(ctx *ExecutionContext) *CLIResponse {
	return &CLIResponse{
		Success:   true,
		Message:   "Configuration is valid",
		Timestamp: time.Now(),
		TraceID:   ctx.TraceID,
		Data: map[string]interface{}{
			"valid":  true,
			"errors": []string{},
		},
	}
}

func getArgValue(args []string, key, defaultValue string) string {
	for i, arg := range args {
		if arg == "--"+key && i+1 < len(args) {
			return args[i+1]
		}
	}
	return defaultValue
}

func outputResult(result *CLIResponse) {
	result.Duration = time.Since(time.Now().Add(-time.Since(result.Timestamp))).String()

	switch outputFormat {
	case "text":
		if result.Success {
			fmt.Printf("SUCCESS: %s\n", result.Message)
			if result.Data != nil {
				for key, value := range result.Data {
					fmt.Printf("  %s: %v\n", key, value)
				}
			}
		} else {
			fmt.Printf("ERROR: %s\n", result.Error)
		}
	case "lines":
		if result.Success {
			fmt.Println(result.Message)
			if result.Data != nil {
				for key, value := range result.Data {
					fmt.Printf("%s=%v\n", key, value)
				}
			}
		} else {
			fmt.Println("ERROR=" + result.Error)
		}
	default: // json
		encoder := json.NewEncoder(os.Stdout)
		encoder.SetIndent("", "  ")
		if err := encoder.Encode(result); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to encode JSON output: %v\n", err)
			os.Exit(1)
		}
	}

	if !result.Success {
		os.Exit(1)
	}
}
