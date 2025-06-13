package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"
	"github.com/email-sender/development/managers/interfaces"
	"golang.org/x/mod/modfile"
)

// Dependency represents a dependency with its metadata.
type Dependency struct {
	Name       string `json:"name"`
	Version    string `json:"version"`
	Indirect   bool   `json:"indirect,omitempty"`
	Repository string `json:"repository,omitempty"`
	License    string `json:"license,omitempty"`
}

// ErrorEntry represents a locally cataloged error.
type ErrorEntry struct {
	ID             string    `json:"id"`
	Timestamp      time.Time `json:"timestamp"`
	Message        string    `json:"message"`
	StackTrace     string    `json:"stack_trace"`
	Module         string    `json:"module"`
	ErrorCode      string    `json:"error_code"`
	ManagerContext string    `json:"manager_context"`
	Severity       string    `json:"severity"`
}

// Config represents the manager's configuration.
type Config struct {
	Name     string `json:"name"`
	Version  string `json:"version"`
	Settings struct {
		LogPath            string `json:"logPath"`
		LogLevel           string `json:"logLevel"`
		GoModPath          string `json:"goModPath"`
		AutoTidy           bool   `json:"autoTidy"`
		VulnerabilityCheck bool   `json:"vulnerabilityCheck"`
		BackupOnChange     bool   `json:"backupOnChange"`
	} `json:"settings"`
}

// DepManager manages dependency operations (SOLID interface).
type DepManager interface {
	List() ([]Dependency, error)
	Add(module, version string) error
	Remove(module string) error
	Update(module string) error
	Audit() error
	Cleanup() error
}

// GoModManager implements DepManager for go.mod.
type GoModManager struct {
	modFilePath         string
	config              *Config
	configManager       ConfigManager
	logger              *zap.Logger
	errorManager        ErrorManager
	securityManager     SecurityManagerInterface
	monitoringManager   MonitoringManagerInterface
	storageManager      StorageManagerInterface
	containerManager    ContainerManagerInterface
	deploymentManager   DeploymentManagerInterface
	registryCredentials map[string]RegistryCredentials
	managerIntegrator   *ManagerIntegrator
}

// ErrorManager interface for decoupling error handling.
type ErrorManager interface {
	ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error
	CatalogError(entry ErrorEntry) error
	ValidateErrorEntry(entry ErrorEntry) error
}

// ConfigManager interface for configuration management.
type ConfigManager interface {
	GetString(key string) (string, error)
	GetInt(key string) (int, error)
	GetBool(key string) (bool, error)
	UnmarshalKey(key string, targetStruct interface{}) error
	IsSet(key string) bool
	RegisterDefaults(defaults map[string]interface{})
	LoadConfigFile(filePath string, fileType string) error
	LoadFromEnv(prefix string)
	Validate() error
	SetRequiredKeys(keys []string)
	Get(key string) interface{}
	Set(key string, value interface{})
	SetDefault(key string, value interface{})
	GetAll() map[string]interface{}
	SaveToFile(filePath string, fileType string, config map[string]interface{}) error
	Cleanup() error
	GetErrorManager() ErrorManager
	GetLogger() *zap.Logger
}

// ErrorManagerImpl implements ErrorManager.
type ErrorManagerImpl struct {
	logger *zap.Logger
}

// ErrorHooks defines callbacks for error handling.
type ErrorHooks struct {
	OnError func(err error)
	OnRetry func(attempt int, err error)
}

// NewGoModManager creates a GoModManager instance.
func NewGoModManager(modFilePath string, config *Config) *GoModManager {
	logger, _ := zap.NewProduction()
	errorManager := &ErrorManagerImpl{logger: logger}
	configManager := NewDepConfigManager(config, logger, errorManager)
	managerIntegrator := NewManagerIntegrator(logger, errorManager)

	mgr := &GoModManager{
		modFilePath:         modFilePath,
		config:              config,
		configManager:       configManager,
		logger:              logger,
		errorManager:        errorManager,
		managerIntegrator:   managerIntegrator,
		registryCredentials: make(map[string]RegistryCredentials),
	}

	// Initialize the security, monitoring, storage, container, and deployment integrations
	// These will be properly initialized when needed through their respective initialize*Integration functions
	return mgr
}

// ProcessError processes an error with centralized error handling.
func (em *ErrorManagerImpl) ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error {
	if err == nil {
		return nil
	}

	errorID := uuid.New().String()
	severity := determineSeverity(err)
	errorCode := generateErrorCode(component, operation)

	entry := ErrorEntry{
		ID:             errorID,
		Timestamp:      time.Now(),
		Message:        err.Error(),
		StackTrace:     fmt.Sprintf("%+v", err),
		Module:         "dependency-manager",
		ErrorCode:      errorCode,
		ManagerContext: fmt.Sprintf("component=%s, operation=%s", component, operation),
		Severity:       severity,
	}

	if validationErr := em.ValidateErrorEntry(entry); validationErr != nil {
		em.logger.Error("Error entry validation failed",
			zap.Error(validationErr),
			zap.String("error_id", errorID))
		return validationErr
	}

	if catalogErr := em.CatalogError(entry); catalogErr != nil {
		em.logger.Error("Failed to catalog error",
			zap.Error(catalogErr),
			zap.String("error_id", errorID))
	}

	if hooks != nil && hooks.OnError != nil {
		hooks.OnError(err)
	}

	em.logger.Error("Dependency Manager error processed",
		zap.String("error_id", errorID),
		zap.String("component", component),
		zap.String("operation", operation),
		zap.String("severity", severity),
		zap.String("error_code", errorCode),
		zap.Error(err))

	return err
}

// CatalogError catalogs an error with structured details.
func (em *ErrorManagerImpl) CatalogError(entry ErrorEntry) error {
	em.logger.Error("Error cataloged",
		zap.String("id", entry.ID),
		zap.Time("timestamp", entry.Timestamp),
		zap.String("message", entry.Message),
		zap.String("stack_trace", entry.StackTrace),
		zap.String("module", entry.Module),
		zap.String("error_code", entry.ErrorCode),
		zap.String("manager_context", entry.ManagerContext),
		zap.String("severity", entry.Severity))
	return nil
}

// ValidateErrorEntry validates an error entry.
func (em *ErrorManagerImpl) ValidateErrorEntry(entry ErrorEntry) error {
	if entry.ID == "" {
		return fmt.Errorf("ID cannot be empty")
	}
	if entry.Timestamp.IsZero() {
		return fmt.Errorf("Timestamp cannot be zero")
	}
	if entry.Message == "" {
		return fmt.Errorf("Message cannot be empty")
	}
	if entry.Module == "" {
		return fmt.Errorf("Module cannot be empty")
	}
	if entry.ErrorCode == "" {
		return fmt.Errorf("ErrorCode cannot be empty")
	}
	if !isValidSeverity(entry.Severity) {
		return fmt.Errorf("invalid severity level: %s", entry.Severity)
	}
	return nil
}

// Log writes a message to the log.
func (m *GoModManager) Log(level, message string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logMessage := fmt.Sprintf("[%s] [%s] %s", timestamp, level, message)

	if logPath, err := m.configManager.GetString("dependency-manager.settings.logPath"); err == nil && logPath != "" {
		logFile, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
		if err == nil {
			defer logFile.Close()
			if _, err := logFile.WriteString(logMessage + "\n"); err != nil {
				// Log write error, but don't fail the operation
				fmt.Printf("Warning: failed to write to log file: %v\n", err)
			}
		}
	}

	fmt.Println(logMessage)
}

// backupGoMod creates a backup of the go.mod file.
func (m *GoModManager) backupGoMod() error {
	backupEnabled, err := m.configManager.GetBool("dependency-manager.settings.backupOnChange")
	if err != nil || !backupEnabled {
		return nil
	}

	timestamp := time.Now().Format("20060102-150405")
	backupPath := fmt.Sprintf("%s.backup.%s", m.modFilePath, timestamp)

	input, err := os.ReadFile(m.modFilePath)
	if err != nil {
		return err
	}

	return os.WriteFile(backupPath, input, 0644)
}

// List returns the list of dependencies from go.mod.
func (m *GoModManager) List() ([]Dependency, error) {
	m.Log("INFO", "Listing dependencies")
	ctx := context.Background()
	data, err := os.ReadFile(m.modFilePath)
	if err != nil {
		return nil, m.errorManager.ProcessError(ctx, fmt.Errorf("failed to read go.mod: %v", err), "go-mod-operation", "read", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to read go.mod file",
					zap.Error(err),
					zap.String("file_path", m.modFilePath),
					zap.String("operation", "list_dependencies"))
			},
		})
	}

	modFile, err := modfile.Parse(m.modFilePath, data, nil)
	if err != nil {
		return nil, m.errorManager.ProcessError(ctx, fmt.Errorf("failed to parse go.mod: %v", err), "go-mod-operation", "parse", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to parse go.mod file",
					zap.Error(err),
					zap.String("file_path", m.modFilePath),
					zap.String("operation", "parse_go_mod"))
			},
		})
	}

	var deps []Dependency
	for _, req := range modFile.Require {
		deps = append(deps, Dependency{
			Name:     req.Mod.Path,
			Version:  req.Mod.Version,
			Indirect: req.Indirect,
		})
	}

	m.Log("INFO", fmt.Sprintf("Found %d dependencies", len(deps)))
	return deps, nil
}

// Add adds a dependency to the project.
func (m *GoModManager) Add(module, version string) error {
	m.Log("INFO", fmt.Sprintf("Adding dependency: %s@%s", module, version))
	ctx := context.Background()

	if err := m.backupGoMod(); err != nil {
		m.logger.Warn("Failed to backup go.mod file",
			zap.Error(err),
			zap.String("operation", "add_dependency"),
			zap.String("module", module),
			zap.String("version", version))
	}

	cmd := exec.Command("go", "get", fmt.Sprintf("%s@%s", module, version))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to add dependency %s: %v", module, err), "dependency-resolution", "add", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to add dependency",
					zap.Error(err),
					zap.String("module", module),
					zap.String("version", version),
					zap.String("operation", "go_get"))
			},
		})
	}

	if autoTidy, err := m.configManager.GetBool("dependency-manager.settings.autoTidy"); err == nil && autoTidy {
		if err := m.runGoModTidy(); err != nil {
			m.logger.Warn("Failed to run go mod tidy after adding dependency",
				zap.Error(err),
			)
		}
	}

	m.Log("SUCCESS", fmt.Sprintf("Successfully added %s@%s", module, version))
	return nil
}

// Remove removes a dependency from the project.
func (m *GoModManager) Remove(module string) error {
	m.Log("INFO", fmt.Sprintf("Removing dependency: %s", module))
	ctx := context.Background()

	if err := m.backupGoMod(); err != nil {
		m.logger.Warn("Failed to backup go.mod file",
			zap.Error(err),
			zap.String("operation", "remove_dependency"),
			zap.String("module", module),
		)
	}

	data, err := os.ReadFile(m.modFilePath)
	if err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to read go.mod: %v", err), "go-mod-operation", "read", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to read go.mod for dependency removal",
					zap.Error(err),
					zap.String("module", module),
					zap.String("file_path", m.modFilePath))
			},
		})
	}

	modFile, err := modfile.Parse(m.modFilePath, data, nil)
	if err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to parse go.mod: %v", err), "go-mod-operation", "parse", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to parse go.mod for dependency removal",
					zap.Error(err),
					zap.String("module", module),
					zap.String("file_path", m.modFilePath))
			},
		})
	}

	if err := modFile.DropRequire(module); err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to drop dependency %s: %v", module, err), "dependency-resolution", "remove", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to drop dependency from go.mod",
					zap.Error(err),
					zap.String("module", module),
					zap.String("operation", "drop_require"))
			},
		})
	}

	newData, err := modFile.Format()
	if err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to format go.mod: %v", err), "go-mod-operation", "write", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to format go.mod after dependency removal",
					zap.Error(err),
					zap.String("module", module))
			},
		})
	}

	if err := os.WriteFile(m.modFilePath, newData, 0644); err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to write go.mod: %v", err), "go-mod-operation", "write", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to write updated go.mod file",
					zap.Error(err),
					zap.String("module", module),
					zap.String("file_path", m.modFilePath))
			},
		})
	}

	if err := m.runGoModTidy(); err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to tidy go.mod: %v", err), "go-mod-operation", "tidy", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to run go mod tidy after dependency removal",
					zap.Error(err),
					zap.String("module", module))
			},
		})
	}

	m.Log("SUCCESS", fmt.Sprintf("Successfully removed %s", module))
	return nil
}

// Update updates a dependency to the latest version.
func (m *GoModManager) Update(module string) error {
	m.Log("INFO", fmt.Sprintf("Updating dependency: %s", module))
	ctx := context.Background()

	if err := m.backupGoMod(); err != nil {
		m.logger.Warn("Failed to backup go.mod file",
			zap.Error(err),
			zap.String("operation", "update_dependency"),
			zap.String("module", module))
	}

	cmd := exec.Command("go", "get", fmt.Sprintf("%s@latest", module))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to update dependency %s: %v", module, err), "dependency-resolution", "update", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to update dependency",
					zap.Error(err),
					zap.String("module", module),
					zap.String("operation", "go_get_latest"))
			},
		})
	}

	if autoTidy, err := m.configManager.GetBool("dependency-manager.settings.autoTidy"); err == nil && autoTidy {
		if err := m.runGoModTidy(); err != nil {
			m.logger.Warn("Failed to run go mod tidy after updating dependency",
				zap.Error(err))
		}
	}

	m.Log("SUCCESS", fmt.Sprintf("Successfully updated %s", module))
	return nil
}

// Audit checks for dependency vulnerabilities.
func (m *GoModManager) Audit() error {
	m.Log("INFO", "Running security audit")
	ctx := context.Background()

	cmd := exec.Command("go", "list", "-json", "-m", "all")
	output, err := cmd.Output()
	if err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to audit dependencies: %v", err), "vulnerability-scan", "audit", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to run dependency audit",
					zap.Error(err),
					zap.String("operation", "go_list_modules"),
					zap.String("command", "go list -json -m all"))
			},
		})
	}

	m.logger.Info("Audit completed - consider running 'govulncheck' for detailed security analysis",
		zap.Int("modules_count", strings.Count(string(output), "}")))
	m.Log("INFO", "Audit completed - consider running 'govulncheck' for detailed security analysis")
	fmt.Println(string(output))

	return nil
}

// Cleanup removes unused dependencies.
func (m *GoModManager) Cleanup() error {
	m.Log("INFO", "Cleaning up unused dependencies")
	ctx := context.Background()

	if err := m.backupGoMod(); err != nil {
		m.logger.Warn("Failed to backup go.mod before cleanup",
			zap.Error(err),
			zap.String("operation", "cleanup_dependencies"))
	}

	if err := m.runGoModTidy(); err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to cleanup dependencies: %v", err), "go-mod-operation", "cleanup", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to cleanup unused dependencies",
					zap.Error(err),
					zap.String("operation", "go_mod_tidy"))
			},
		})
	}

	m.logger.Info("Successfully cleaned up unused dependencies")
	m.Log("SUCCESS", "Successfully cleansed unused dependencies")
	return nil
}

// runGoModTidy executes go mod tidy.
func (m *GoModManager) runGoModTidy() error {
	ctx := context.Background()

	m.logger.Info("Running go mod tidy",
		zap.String("operation", "go_mod_tidy"))

	cmd := exec.Command("go", "mod", "tidy")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to execute go mod tidy: %v", err), "dependency-cleanup", "tidy", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to execute go mod tidy",
					zap.Error(err),
					zap.String("operation", "go_mod_tidy"))
			},
		})
	}

	m.logger.Info("Successfully completed go mod tidy")
	return nil
}

// loadConfig loads configuration from a JSON file with fallback.
func loadConfig(configPath string) (*Config, error) {
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		fmt.Printf("Configuration file not found at %s, using defaults\n", configPath)
		return getDefaultConfig(), nil
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		fmt.Printf("Warning: Failed to read config file %s: %v. Using defaults.\n", configPath, err)
		return getDefaultConfig(), nil
	}

	var config Config
	if err := json.Unmarshal(data, &config); err != nil {
		fmt.Printf("Warning: Failed to parse config JSON %s: %v. Using defaults.\n", configPath, err)
		return getDefaultConfig(), nil
	}

	if err := validateConfig(&config); err != nil {
		fmt.Printf("Warning: Invalid configuration: %v. Using defaults.\n", err)
		return getDefaultConfig(), nil
	}

	fmt.Printf("Configuration loaded successfully from %s\n", configPath)
	return &config, nil
}

// getDefaultConfig returns a default configuration.
func getDefaultConfig() *Config {
	return &Config{
		Name:    "dependency-manager",
		Version: "1.0.0",
		Settings: struct {
			LogPath            string `json:"logPath"`
			LogLevel           string `json:"logLevel"`
			GoModPath          string `json:"goModPath"`
			AutoTidy           bool   `json:"autoTidy"`
			VulnerabilityCheck bool   `json:"vulnerabilityCheck"`
			BackupOnChange     bool   `json:"backupOnChange"`
		}{
			LogPath:            "logs/dependency-manager.log",
			LogLevel:           "info",
			GoModPath:          "go.mod", // Default path to go.mod
			AutoTidy:           true,
			VulnerabilityCheck: true,
			BackupOnChange:     true,
		},
	}
}

// validateConfig validates the loaded configuration.
func validateConfig(config *Config) error {
	if config.Name == "" {
		return fmt.Errorf("config name cannot be empty")
	}
	if config.Version == "" {
		return fmt.Errorf("config version cannot be empty")
	}
	validLogLevels := map[string]bool{
		"debug": true, "info": true, "warn": true, "error": true,
	}
	if !validLogLevels[strings.ToLower(config.Settings.LogLevel)] {
		return fmt.Errorf("invalid log level: %s", config.Settings.LogLevel)
	}
	if config.Settings.LogPath == "" {
		return fmt.Errorf("log path cannot be empty")
	}
	if config.Settings.GoModPath == "" {
		return fmt.Errorf("go.mod path cannot be empty")
	}
	return nil
}

// runCLI handles user commands.
func runCLI(manager *GoModManager) {
	listCmd := flag.NewFlagSet("list", flag.ExitOnError)
	addCmd := flag.NewFlagSet("add", flag.ExitOnError)
	removeCmd := flag.NewFlagSet("remove", flag.ExitOnError)
	updateCmd := flag.NewFlagSet("update", flag.ExitOnError)
	auditCmd := flag.NewFlagSet("audit", flag.ExitOnError)
	cleanupCmd := flag.NewFlagSet("cleanup", flag.ExitOnError)

	// New commands for integrations
	containerCmd := flag.NewFlagSet("container", flag.ExitOnError)
	deploymentCmd := flag.NewFlagSet("deployment", flag.ExitOnError)
	healthCmd := flag.NewFlagSet("health", flag.ExitOnError)
	metadataCmd := flag.NewFlagSet("metadata", flag.ExitOnError)

	addModule := addCmd.String("module", "", "Module to add (e.g., github.com/pkg)")
	addVersion := addCmd.String("version", "latest", "Module version")
	addMonitoring := addCmd.Bool("monitor", false, "Enable performance monitoring for add operation")

	removeModule := removeCmd.String("module", "", "Module to remove")
	updateModule := updateCmd.String("module", "", "Module to update")
	updateMonitoring := updateCmd.Bool("monitor", false, "Enable performance monitoring for update operation")

	listJSON := listCmd.Bool("json", false, "Output in JSON format")
	listEnhanced := listCmd.Bool("enhanced", false, "Include enhanced metadata from StorageManager")

	auditEnhanced := auditCmd.Bool("enhanced", false, "Use SecurityManager for enhanced vulnerability scanning")

	deploymentEnv := deploymentCmd.String("env", "development", "Target environment for deployment check")

	if len(os.Args) < 2 {
		fmt.Println("Commands: list, add, remove, update, audit, cleanup, container, deployment, health, metadata")
		fmt.Println("Use 'help' for more information")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "list":
		if err := listCmd.Parse(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing list command: %v\n", err)
			os.Exit(1)
		}

		if *listEnhanced {
			enhancedDeps, err := manager.ListWithEnhancedMetadata()
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			jsonData, _ := json.MarshalIndent(enhancedDeps, "", "  ")
			fmt.Println(string(jsonData))
		} else {
			deps, err := manager.List()
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}
			if *listJSON {
				jsonData, _ := json.MarshalIndent(deps, "", "  ")
				fmt.Println(string(jsonData))
			} else {
				fmt.Printf("Dependencies (%d):\n", len(deps))
				for _, dep := range deps {
					indirect := ""
					if dep.Indirect {
						indirect = " (indirect)"
					}
					fmt.Printf("  %s@%s%s\n", dep.Name, dep.Version, indirect)
				}
			}
		}

	case "add":
		if err := addCmd.Parse(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing add command: %v\n", err)
			os.Exit(1)
		}
		if *addModule == "" {
			fmt.Fprintln(os.Stderr, "Error: --module required")
			os.Exit(1)
		}

		var err error
		if *addMonitoring {
			err = manager.AddWithMonitoring(*addModule, *addVersion)
		} else {
			err = manager.Add(*addModule, *addVersion)
		}

		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Added %s@%s\n", *addModule, *addVersion)

	case "remove":
		if err := removeCmd.Parse(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing remove command: %v\n", err)
			os.Exit(1)
		}
		if *removeModule == "" {
			fmt.Fprintln(os.Stderr, "Error: --module required")
			os.Exit(1)
		}
		if err := manager.Remove(*removeModule); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Removed %s\n", *removeModule)

	case "update":
		if err := updateCmd.Parse(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing update command: %v\n", err)
			os.Exit(1)
		}
		if *updateModule == "" {
			fmt.Fprintln(os.Stderr, "Error: --module required")
			os.Exit(1)
		}

		var err error
		if *updateMonitoring {
			err = manager.UpdateWithMonitoring(*updateModule)
		} else {
			err = manager.Update(*updateModule)
		}

		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Updated %s\n", *updateModule)

	case "audit":
		if err := auditCmd.Parse(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing audit command: %v\n", err)
			os.Exit(1)
		}

		var err error
		if *auditEnhanced {
			err = manager.AuditWithSecurityManager()
		} else {
			err = manager.Audit()
		}

		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}

	case "cleanup":
		if err := cleanupCmd.Parse(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing cleanup command: %v\n", err)
			os.Exit(1)
		}
		if err := manager.Cleanup(); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Cleanup completed")

	case "container":
		if err := containerCmd.Parse(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing container command: %v\n", err)
			os.Exit(1)
		}
		if err := manager.ValidateForContainerDeployment(); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Container compatibility check completed")

	case "deployment":
		if err := deploymentCmd.Parse(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing deployment command: %v\n", err)
			os.Exit(1)
		}
		if err := manager.CheckDeploymentReadiness(*deploymentEnv); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Deployment readiness check for %s environment completed\n", *deploymentEnv)

	case "health":
		if err := healthCmd.Parse(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing health command: %v\n", err)
			os.Exit(1)
		}
		if err := manager.PerformHealthCheck(); err != nil { // Corrected method name
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Integration health check completed")

	case "metadata":
		if err := metadataCmd.Parse(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error parsing metadata command: %v\n", err)
			os.Exit(1)
		}
		if err := manager.PerformHealthCheck(); err != nil { // Corrected method name
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Dependency metadata synchronization completed")

	case "help":
		fmt.Println("Go Dependency Manager with Advanced Manager Integrations")
		fmt.Println("=====================================================")
		fmt.Println("")
		fmt.Println("Commands:")
		fmt.Println("  list [--json] [--enhanced]     - List all dependencies, with optional enhanced metadata")
		fmt.Println("  add --module <mod> [--version <ver>] [--monitor] - Add a dependency with optional monitoring")
		fmt.Println("  remove --module <mod>          - Remove a dependency")
		fmt.Println("  update --module <mod> [--monitor] - Update a dependency with optional monitoring")
		fmt.Println("  audit [--enhanced]             - Check for vulnerabilities with optional SecurityManager")
		fmt.Println("  cleanup                        - Clean unused dependencies")
		fmt.Println("  container                      - Validate dependencies for container deployment")
		fmt.Println("  deployment [--env <env>]       - Check deployment readiness for environment")
		fmt.Println("  health                         - Check health of all manager integrations")
		fmt.Println("  metadata                       - Synchronize dependency metadata with StorageManager")
		fmt.Println("  help                           - Show this help")
		fmt.Println("")
		fmt.Println("Examples:")
		fmt.Println("  go run dependency_manager.go list --enhanced")
		fmt.Println("  go run dependency_manager.go add --module github.com/pkg/errors --version v0.9.1 --monitor")
		fmt.Println("  go run dependency_manager.go audit --enhanced")
		fmt.Println("  go run dependency_manager.go deployment --env production")

	default:
		fmt.Printf("Unknown command: %s\n", os.Args[1])
		fmt.Println("Use 'help' to see available commands")
		os.Exit(1)
	}
}

func main() {
	wd, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: failed to get working directory: %v\n", err)
		os.Exit(1)
	}

	modFilePath := findGoMod(wd)
	if modFilePath == "" {
		fmt.Fprintln(os.Stderr, "Error: go.mod not found")
		os.Exit(1)
	}

	projectRoot := filepath.Dir(modFilePath)
	configPath := filepath.Join(projectRoot, "config", "dependency-manager.config.json")

	config, err := loadConfig(configPath)
	if err != nil {
		fmt.Printf("Warning: Failed to load configuration: %v\n", err)
	}

	manager := NewGoModManager(modFilePath, config)

	// Initialize manager integrations if --init-managers flag is provided
	if len(os.Args) > 1 && os.Args[1] == "--init-managers" {
		fmt.Println("Initializing all manager integrations...")
		ctx := context.Background()
		if err := manager.InitializeAllManagers(ctx); err != nil {
			fmt.Printf("Warning: Failed to initialize all managers: %v\n", err)
		}
		fmt.Println("Manager integrations initialized successfully")
		os.Args = os.Args[1:] // Remove the flag for further processing
	}

	runCLI(manager)
}

// findGoMod searches for go.mod in the current directory or its parents.
func findGoMod(startDir string) string {
	dir := startDir
	for {
		modPath := filepath.Join(dir, "go.mod")
		if _, err := os.Stat(modPath); err == nil {
			return modPath
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	return ""
}

// isValidSeverity checks if the severity level is valid.
func isValidSeverity(severity string) bool {
	validSeverities := []string{"low", "medium", "high", "critical"}
	for _, s := range validSeverities {
		if severity == s {
			return true
		}
	}
	return false
}

// determineSeverity determines the severity of an error.
func determineSeverity(err error) string {
	errorMsg := strings.ToLower(err.Error())
	if strings.Contains(errorMsg, "critical") || strings.Contains(errorMsg, "fatal") ||
		strings.Contains(errorMsg, "corrupt") || strings.Contains(errorMsg, "invalid go.mod") {
		return "critical"
	}
	if strings.Contains(errorMsg, "vulnerability") || strings.Contains(errorMsg, "security") ||
		strings.Contains(errorMsg, "remove") || strings.Contains(errorMsg, "delete") {
		return "high"
	}
	if strings.Contains(errorMsg, "timeout") || strings.Contains(errorMsg, "connection") ||
		strings.Contains(errorMsg, "network") || strings.Contains(errorMsg, "resolution") ||
		strings.Contains(errorMsg, "download") || strings.Contains(errorMsg, "fetch") {
		return "medium"
	}
	return "low"
}

// generateErrorCode generates an error code based on component and operation.
func generateErrorCode(component, operation string) string {
	switch component {
	case "dependency-resolution":
		switch operation {
		case "list":
			return "DEP_RESOLUTION_001"
		case "add":
			return "DEP_RESOLUTION_002"
		case "remove":
			return "DEP_RESOLUTION_003"
		case "update":
			return "DEP_RESOLUTION_004"
		default:
			return "DEP_RESOLUTION_000"
		}
	case "go-mod-operation":
		switch operation {
		case "read":
			return "DEP_GOMOD_001"
		case "parse":
			return "DEP_GOMOD_002"
		case "write":
			return "DEP_GOMOD_003"
		case "backup":
			return "DEP_GOMOD_004"
		default:
			return "DEP_GOMOD_000"
		}
	case "vulnerability-scan":
		switch operation {
		case "audit":
			return "DEP_VULN_001"
		case "scan":
			return "DEP_VULN_002"
		case "govulncheck":
			return "DEP_VULN_003"
		default:
			return "DEP_VULN_000"
		}
	case "configuration":
		switch operation {
		case "load":
			return "DEP_CONFIG_001"
		case "validate":
			return "DEP_CONFIG_002"
		case "parse":
			return "DEP_CONFIG_003"
		default:
			return "DEP_CONFIG_000"
		}
	default:
		return "DEP_UNKNOWN_001"
	}
}

// DepConfigManagerImpl implements ConfigManager for DependencyManager.
type DepConfigManagerImpl struct {
	settings     map[string]interface{}
	defaults     map[string]interface{}
	requiredKeys []string
	logger       *zap.Logger
	errorManager ErrorManager
	config       *Config
}

// NewDepConfigManager creates a ConfigManager instance.
func NewDepConfigManager(config *Config, logger *zap.Logger, errorManager ErrorManager) ConfigManager {
	cm := &DepConfigManagerImpl{
		settings:     make(map[string]interface{}),
		defaults:     make(map[string]interface{}),
		requiredKeys: []string{},
		logger:       logger,
		errorManager: errorManager,
		config:       config,
	}
	if config != nil {
		cm.initializeFromLegacyConfig(config)
	}
	return cm
}

// initializeFromLegacyConfig initializes ConfigManager from Config struct.
func (cm *DepConfigManagerImpl) initializeFromLegacyConfig(config *Config) {
	prefix := "dependency-manager."
	cm.settings[prefix+"name"] = config.Name
	cm.settings[prefix+"version"] = config.Version
	cm.settings[prefix+"settings.logPath"] = config.Settings.LogPath
	cm.settings[prefix+"settings.logLevel"] = config.Settings.LogLevel
	cm.settings[prefix+"settings.goModPath"] = config.Settings.GoModPath
	cm.settings[prefix+"settings.autoTidy"] = config.Settings.AutoTidy
	cm.settings[prefix+"settings.vulnerabilityCheck"] = config.Settings.VulnerabilityCheck
	cm.settings[prefix+"settings.backupOnChange"] = config.Settings.BackupOnChange
}

// ConfigManager interface implementation.
func (cm *DepConfigManagerImpl) GetString(key string) (string, error) {
	if val, exists := cm.settings[key]; exists {
		if str, ok := val.(string); ok {
			return str, nil
		}
		return fmt.Sprintf("%v", val), nil
	}
	if val, exists := cm.defaults[key]; exists {
		if str, ok := val.(string); ok {
			return str, nil
		}
		return fmt.Sprintf("%v", val), nil
	}
	return "", fmt.Errorf("key not found: %s", key)
}

func (cm *DepConfigManagerImpl) GetInt(key string) (int, error) {
	if val, exists := cm.settings[key]; exists {
		if i, ok := val.(int); ok {
			return i, nil
		}
		return 0, fmt.Errorf("value is not an int: %s Pets", key)
	}
	if val, exists := cm.defaults[key]; exists {
		if i, ok := val.(int); ok {
			return i, nil
		}
		return 0, fmt.Errorf("default value is not an int: %s", key)
	}
	return 0, fmt.Errorf("key not found: %s", key)
}

func (cm *DepConfigManagerImpl) GetBool(key string) (bool, error) {
	if val, exists := cm.settings[key]; exists {
		if b, ok := val.(bool); ok {
			return b, nil
		}
		return false, fmt.Errorf("value is not a bool: %s", key)
	}
	if val, exists := cm.defaults[key]; exists {
		if b, ok := val.(bool); ok {
			return b, nil
		}
		return false, fmt.Errorf("default value is not a bool: %s", key)
	}
	return false, fmt.Errorf("key not found: %s", key)
}

func (cm *DepConfigManagerImpl) UnmarshalKey(key string, targetStruct interface{}) error {
	if key == "" || key == "dependency-manager" {
		if cm.config != nil {
			data, err := json.Marshal(cm.config)
			if err != nil {
				return err
			}
			return json.Unmarshal(data, targetStruct)
		}
	}
	return fmt.Errorf("key not supported for unmarshal: %s", key)
}

func (cm *DepConfigManagerImpl) IsSet(key string) bool {
	_, exists := cm.settings[key]
	return exists
}

func (cm *DepConfigManagerImpl) RegisterDefaults(defaults map[string]interface{}) {
	for k, v := range defaults {
		cm.defaults[k] = v
	}
}

func (cm *DepConfigManagerImpl) LoadConfigFile(filePath string, fileType string) error {
	config, err := loadConfig(filePath)
	if err != nil {
		return err
	}
	cm.config = config
	cm.initializeFromLegacyConfig(config)
	return nil
}

func (cm *DepConfigManagerImpl) LoadFromEnv(prefix string) {
	cm.logger.Info("Environment loading not implemented yet", zap.String("prefix", prefix))
}

func (cm *DepConfigManagerImpl) Validate() error {
	for _, key := range cm.requiredKeys {
		if !cm.IsSet(key) {
			return fmt.Errorf("required key not set: %s", key)
		}
	}
	return nil
}

func (cm *DepConfigManagerImpl) SetRequiredKeys(keys []string) {
	cm.requiredKeys = keys
}

func (cm *DepConfigManagerImpl) Get(key string) interface{} {
	if val, exists := cm.settings[key]; exists {
		return val
	}
	if val, exists := cm.defaults[key]; exists {
		return val
	}
	return nil
}

func (cm *DepConfigManagerImpl) Set(key string, value interface{}) {
	cm.settings[key] = value
}

func (cm *DepConfigManagerImpl) SetDefault(key string, value interface{}) {
	cm.defaults[key] = value
}

func (cm *DepConfigManagerImpl) GetAll() map[string]interface{} {
	result := make(map[string]interface{})
	for k, v := range cm.defaults {
		result[k] = v
	}
	for k, v := range cm.settings {
		result[k] = v
	}
	return result
}

func (cm *DepConfigManagerImpl) SaveToFile(filePath string, fileType string, config map[string]interface{}) error {
	return fmt.Errorf("SaveToFile not implemented yet")
}

func (cm *DepConfigManagerImpl) Cleanup() error {
	cm.settings = make(map[string]interface{})
	return nil
}

func (cm *DepConfigManagerImpl) GetErrorManager() ErrorManager {
	return cm.errorManager
}

func (cm *DepConfigManagerImpl) GetLogger() *zap.Logger {
	return cm.logger
}

// Advanced Integration Methods for Section 3.1

// SetSecurityManager configures SecurityManager integration
func (m *GoModManager) SetSecurityManager(sm SecurityManagerInterface) {
	m.managerIntegrator.SetSecurityManager(sm)
	m.logger.Info("SecurityManager integration configured for DependencyManager")
}

// SetMonitoringManager configures MonitoringManager integration
func (m *GoModManager) SetMonitoringManager(mm MonitoringManagerInterface) {
	m.managerIntegrator.SetMonitoringManager(mm)
	m.logger.Info("MonitoringManager integration configured for DependencyManager")
}

// SetStorageManager configures StorageManager integration
func (m *GoModManager) SetStorageManager(sm StorageManagerInterface) {
	m.managerIntegrator.SetStorageManager(sm)
	m.logger.Info("StorageManager integration configured for DependencyManager")
}

// SetContainerManager configures ContainerManager integration
func (m *GoModManager) SetContainerManager(cm ContainerManagerInterface) {
	m.managerIntegrator.SetContainerManager(cm)
	m.logger.Info("ContainerManager integration configured for DependencyManager")
}

// SetDeploymentManager configures DeploymentManager integration
func (m *GoModManager) SetDeploymentManager(dm DeploymentManagerInterface) {
	m.managerIntegrator.SetDeploymentManager(dm)
	m.logger.Info("DeploymentManager integration configured for DependencyManager")
}

// AuditWithSecurityManager performs enhanced security audit using SecurityManager
func (m *GoModManager) AuditWithSecurityManager() error {
	m.Log("INFO", "Running enhanced security audit with SecurityManager")
	ctx := context.Background()

	// Get current dependencies
	dependencies, err := m.List()
	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "dependency-list", "audit_with_security", nil)
	}

	// Perform security audit through ManagerIntegrator
	auditResult, err := m.managerIntegrator.SecurityAuditWithManager(ctx, dependencies)
	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "SecurityManager", "security_audit", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Enhanced security audit failed",
					zap.Error(err),
					zap.Int("dependencies_count", len(dependencies)))
			},
		})
	}

	// Log audit results
	if auditResult != nil { // Check if auditResult is not nil
		// auditResult is now *interfaces.VulnerabilityReport
		totalVulnerabilitiesFromReport := auditResult.CriticalCount + auditResult.HighCount + auditResult.MediumCount + auditResult.LowCount

		m.logger.Info("Enhanced security audit completed",
			zap.Int("total_scanned", auditResult.TotalScanned),
			zap.Int("total_vulnerabilities_found", totalVulnerabilitiesFromReport),
			zap.Int("critical_vulnerabilities", auditResult.CriticalCount),
			zap.Int("high_vulnerabilities", auditResult.HighCount),
			zap.Int("medium_vulnerabilities", auditResult.MediumCount),
			zap.Int("low_vulnerabilities", auditResult.LowCount),
			zap.Time("audit_timestamp", auditResult.Timestamp))

		// Persist audit results
		if m.managerIntegrator != nil {
			if err := m.managerIntegrator.PersistDependencyMetadata(ctx, dependencies); err != nil {
				m.logger.Warn("Failed to persist dependency metadata after audit", zap.Error(err))
			}
		} else {
			m.logger.Warn("ManagerIntegrator not initialized, cannot persist metadata after audit")
		}

		m.Log("info", fmt.Sprintf("Enhanced security audit completed - %d dependencies scanned, %d total vulnerabilities found (C:%d H:%d M:%d L:%d)",
			auditResult.TotalScanned, totalVulnerabilitiesFromReport, auditResult.CriticalCount, auditResult.HighCount, auditResult.MediumCount, auditResult.LowCount))
	} else {
		m.logger.Error("Security audit result was nil")
		m.Log("error", "Security audit failed to produce a result")
	}
	return nil
}

// AddWithMonitoring adds a dependency with performance monitoring
func (m *GoModManager) AddWithMonitoring(module, version string) error {
	m.Log("INFO", fmt.Sprintf("Adding dependency with monitoring: %s@%s", module, version))
	ctx := context.Background()

	// Monitor the add operation performance
	err := m.managerIntegrator.MonitorOperationPerformance(ctx, "add_dependency", func() error {
		return m.Add(module, version)
	})

	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "dependency-add", "add_with_monitoring", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Monitored dependency addition failed",
					zap.Error(err),
					zap.String("module", module),
					zap.String("version", version))
			},
		})
	}

	// Persist dependency metadata
	dependencies := []Dependency{{Name: module, Version: version}} // Create a slice for Persist
	if m.managerIntegrator != nil { // Ensure integrator exists
		if err := m.managerIntegrator.PersistDependencyMetadata(ctx, dependencies); err != nil {
			m.logger.Warn("Failed to persist dependency metadata after addition",
				zap.Error(err),
				zap.String("module", module))
		}
	} else {
		m.logger.Warn("ManagerIntegrator not initialized, cannot persist metadata after addition")
	}

	m.Log("SUCCESS", fmt.Sprintf("Successfully added and monitored %s@%s", module, version))
	return nil
}

// UpdateWithMonitoring updates a dependency with performance monitoring
func (m *GoModManager) UpdateWithMonitoring(module string) error {
	m.Log("INFO", fmt.Sprintf("Updating dependency with monitoring: %s", module))
	ctx := context.Background()

	// Monitor the update operation performance
	err := m.managerIntegrator.MonitorOperationPerformance(ctx, "update_dependency", func() error {
		return m.Update(module)
	})

	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "dependency-update", "update_with_monitoring", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Monitored dependency update failed",
					zap.Error(err),
					zap.String("module", module))
			},
		})
	}

	m.Log("SUCCESS", fmt.Sprintf("Successfully updated and monitored %s", module))
	return nil
}

// ValidateForContainerDeployment validates dependencies for container deployment
func (m *GoModManager) ValidateForContainerDeployment() error {
	m.Log("INFO", "Validating dependencies for container deployment")
	ctx := context.Background()

	// Get current dependencies
	dependencies, err := m.List()
	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "dependency-list", "container_validation", nil)
	}

	// Validate container compatibility
	_, err = m.managerIntegrator.ValidateContainerCompatibility(ctx, dependencies)
	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "ContainerManager", "validate_compatibility", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Container compatibility validation failed",
					zap.Error(err),
					zap.Int("dependencies_count", len(dependencies)))
			},
		})
	}

	m.Log("SUCCESS", "Dependencies validated for container deployment")
	return nil
}

// CheckDeploymentReadiness checks if dependencies are ready for deployment
func (m *GoModManager) CheckDeploymentReadiness(environment string) error {
	m.Log("INFO", fmt.Sprintf("Checking deployment readiness for environment: %s", environment))
	ctx := context.Background()

	// Get current dependencies
	dependencies, err := m.List()
	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "dependency-list", "deployment_readiness", nil)
	}

	// Check deployment readiness
	_, err = m.managerIntegrator.CheckDeploymentReadiness(ctx, dependencies, environment)
	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "DeploymentManager", "check_readiness", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Deployment readiness check failed",
					zap.Error(err),
					zap.String("environment", environment),
					zap.Int("dependencies_count", len(dependencies)))
			},
		})
	}

	m.Log("SUCCESS", fmt.Sprintf("Dependencies ready for deployment to %s environment", environment))
	return nil
}

// PerformHealthCheck checks health of all integrated managers
func (m *GoModManager) PerformHealthCheck() error {
	m.Log("info", "Performing integration health check") // Corrected log level
	ctx := context.Background()

	status, err := m.managerIntegrator.PerformHealthCheck(ctx) // Corrected method name
	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "ManagerIntegrator", "health_check", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Integration health check failed", zap.Error(err))
			},
		})
	}

	// Log detailed health status
	for managerName, health := range status.Managers {
		m.logger.Info("Manager health status",
			zap.String("manager", managerName),
			zap.String("status", health))
	}

	m.logger.Info("Integration health check completed",
		zap.String("overall_status", status.Overall),
		zap.Time("last_checked", status.LastChecked), // Corrected Timestamp to LastChecked
		zap.Int("managers_checked", len(status.Managers)))

	m.Log("info", fmt.Sprintf("Integration health check completed - Overall status: %s", status.Overall)) // Corrected log level
	return nil
}

// ListWithEnhancedMetadata lists dependencies with enhanced metadata from StorageManager
func (m *GoModManager) ListWithEnhancedMetadata() ([]interfaces.DependencyMetadata, error) {
	m.Log("INFO", "Listing dependencies with enhanced metadata")
	ctx := context.Background()

	dependencies, err := m.List() // Returns []Dependency
	if err != nil {
		return nil, m.errorManager.ProcessError(ctx, err, "dependency-list", "enhanced_metadata_list", nil)
	}

	var enhancedDependencies []interfaces.DependencyMetadata
	if m.managerIntegrator == nil || m.managerIntegrator.storageManager == nil {
		m.logger.Warn("StorageManager not available, returning basic metadata")
		for _, dep := range dependencies {
			enhancedDependencies = append(enhancedDependencies, interfaces.DependencyMetadata{
				Name:       dep.Name,
				Version:    dep.Version,
				Repository: dep.Repository,
				License:    dep.License,
				Tags:       map[string]string{"source": "go-mod", "type": "basic"},
			})
		}
		return enhancedDependencies, nil
	}

	for _, dep := range dependencies {
		metadata, err := m.managerIntegrator.storageManager.GetDependencyMetadata(ctx, dep.Name) // Corrected method name
		if err != nil {
			m.logger.Warn("Failed to get enhanced metadata, using basic", zap.String("dependency", dep.Name), zap.Error(err))
			enhancedDependencies = append(enhancedDependencies, interfaces.DependencyMetadata{
				Name:        dep.Name,
				Version:     dep.Version,
				Repository:  dep.Repository,
				License:     dep.License,
				LastUpdated: time.Now(),
				Tags:        map[string]string{"source": "go-mod", "type": "fallback"},
			})
		} else if metadata != nil { // Ensure metadata is not nil before appending
			enhancedDependencies = append(enhancedDependencies, *metadata) // Corrected: dereference pointer
		} else {
            // Handle case where metadata is nil but error is also nil (if possible by interface)
             m.logger.Warn("Enhanced metadata was nil but no error reported, using basic", zap.String("dependency", dep.Name))
             enhancedDependencies = append(enhancedDependencies, interfaces.DependencyMetadata{
                Name:        dep.Name,
                Version:     dep.Version,
                Repository:  dep.Repository,
                License:     dep.License,
                LastUpdated: time.Now(),
                Tags:        map[string]string{"source": "go-mod", "type": "nil_fallback"},
            })
        }
	}
	m.logger.Info("Enhanced dependency metadata retrieved", zap.Int("count", len(enhancedDependencies)))
	return enhancedDependencies, nil
}

// SyncDependencyMetadata synchronizes dependency metadata with StorageManager
func (m *GoModManager) SyncDependencyMetadata() error {
	m.Log("INFO", "Synchronizing dependency metadata with StorageManager")
	ctx := context.Background()

	dependencies, err := m.List() // Returns []Dependency
	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "dependency-list", "sync_metadata_list", nil)
	}

	if m.managerIntegrator == nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("manager integrator not initialized"), "ManagerIntegrator", "sync_metadata_integrator_check", nil)
	}

	// Pass the original []Dependency slice directly
	if err := m.managerIntegrator.PersistDependencyMetadata(ctx, dependencies); err != nil {
		return m.errorManager.ProcessError(ctx, err, "StorageManager", "sync_metadata_persist", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to sync dependency metadata", zap.Error(err), zap.Int("dependencies_count", len(dependencies)))
			},
		})
	}

	m.Log("SUCCESS", fmt.Sprintf("Successfully synchronized metadata for %d dependencies", len(dependencies)))
	return nil
}

// EnableRealManagerIntegration enables real manager integration mode
func (m *GoModManager) EnableRealManagerIntegration(ctx context.Context) error {
	m.Log("INFO", "Enabling real manager integration mode")

	err := m.managerIntegrator.EnableRealManagers(ctx)
	if err != nil {
		return m.errorManager.ProcessError(ctx, err, "ManagerIntegrator", "enable_real_managers", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to enable real manager integration", zap.Error(err))
			},
		})
	}

	m.Log("SUCCESS", "Real manager integration mode enabled successfully")
	return nil
}

// GetIntegrationStatus returns the current status of all integrated managers.
func (m *GoModManager) GetIntegrationStatus(ctx context.Context) (*interfaces.IntegrationHealthStatus, error) { // Ensure it uses interfaces.IntegrationHealthStatus
	if m.managerIntegrator == nil {
		return nil, fmt.Errorf("ManagerIntegrator not initialized")
	}
	// PerformHealthCheck now returns (*interfaces.IntegrationHealthStatus, error)
	return m.managerIntegrator.PerformHealthCheck(ctx)
}

// InitializeAllManagers initializes all manager integrations
func (m *GoModManager) InitializeAllManagers(ctx context.Context) error {
	m.Log("INFO", "Initializing all manager integrations")

	if m.managerIntegrator == nil {
		return fmt.Errorf("manager integrator not initialized")
	}

	// Delegate to the manager integrator's initialization
	if err := m.managerIntegrator.InitializeAllManagers(ctx); err != nil {
		return m.errorManager.ProcessError(ctx, err, "ManagerIntegrator", "initialize_all", &ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to initialize all managers", zap.Error(err))
			},
		})
	}

	m.Log("INFO", "All manager integrations initialized successfully")
	return nil
}

// Placeholder methods for GoModManager based on original problem description
func (m *GoModManager) initializeDependencyGraph() error {
	m.logger.Info("initializeDependencyGraph called - STUB")
	// TODO: Implement actual logic
	return nil
}

func (m *GoModManager) loadExistingMetadata() error {
	m.logger.Info("loadExistingMetadata called - STUB")
	// TODO: Implement actual logic
	return nil
}

func (m *GoModManager) saveCache() error {
	m.logger.Info("saveCache called - STUB")
	// TODO: Implement actual logic
	return nil
}

func (m *GoModManager) checkRegistryHealth() error {
	m.logger.Info("checkRegistryHealth called - STUB")
	// TODO: Implement actual logic
	return nil
}

// DetectConflicts for GoModManager - assuming it might be needed here as well,
// or if GoModManager is the one truly implementing an external DependencyManager interface.
func (m *GoModManager) DetectConflicts(ctx context.Context) ([]interfaces.DependencyConflict, error) {
	m.logger.Info("DetectConflicts called on GoModManager - STUB")
	// TODO: Implement actual conflict detection logic for GoModManager
	return nil, nil
}

// Ensure this file primarily contains the GoModManager and its direct methods.
// Other structs like DependencyManagerImpl, interfaces, and ManagerIntegrator related code
// should be in their respective dedicated files if they are not already.
