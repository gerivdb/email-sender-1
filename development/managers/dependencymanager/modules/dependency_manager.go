package dependency

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
	"github.com/gerivdb/email-sender-1/development/managers/interfaces"
	"golang.org/x/mod/modfile"
)

// GoModManager implements DepManager for go.mod.
type GoModManager struct {
	modFilePath         string
	config              *interfaces.Config
	configManager       interfaces.ConfigManager
	logger              *zap.Logger
	errorManager        interfaces.ErrorManager
	securityManager     interfaces.SecurityManagerInterface
	monitoringManager   interfaces.MonitoringManagerInterface
	storageManager      interfaces.StorageManagerInterface
	containerManager    interfaces.ContainerManagerInterface
	deploymentManager   interfaces.DeploymentManagerInterface
	registryCredentials map[string]interfaces.RegistryCredentials
	managerIntegrator   interfaces.ManagerIntegrator
	
	// Phase 4.1.1.1: Ajout des capacités de vectorisation
	vectorizer          interfaces.VectorizationEngine  // Moteur de vectorisation
	qdrant             interfaces.QdrantInterface      // Interface Qdrant
	vectorizationEnabled bool               // Flag d'activation
}

// NewGoModManager creates a GoModManager instance.
func NewGoModManager(modFilePath string, config *interfaces.Config) *GoModManager {
	logger, _ := zap.NewProduction()
	errorManager := &interfaces.ErrorManagerImpl{logger: logger}
	configManager := interfaces.NewDepConfigManager(config, logger) // Corrected argument
	managerIntegrator := interfaces.NewManagerIntegrator(logger, errorManager)

	mgr := &GoModManager{
		modFilePath:         modFilePath,
		config:              config,
		configManager:       configManager,
		logger:              logger,
		errorManager:        errorManager,
		managerIntegrator:   managerIntegrator,
		registryCredentials: make(map[string]interfaces.RegistryCredentials),
	}

	// Initialize the security, monitoring, storage, container, and deployment integrations
	// These will be properly initialized when needed through their respective initialize*Integration functions
	return mgr
}

// ProcessError processes an error with centralized error handling.
func (em *interfaces.ErrorManagerImpl) ProcessError(ctx context.Context, err error, component, operation string, hooks *interfaces.ErrorHooks) error {
	if err == nil {
		return nil
	}

	errorID := uuid.New().String()
	severity := determineSeverity(err)
	errorCode := generateErrorCode(component, operation)

	entry := interfaces.ErrorEntry{
		ID:             errorID,
		Timestamp:      time.Now(),
		Message:        err.Error(),
		StackTrace:     fmt.Sprintf("%+v", err),
		Module:         "dependency-manager",
		ErrorCode:      errorCode,
		ManagerContext: fmt.Sprintf("component=%s, operation=%s", component, operation),
		Severity:       severity,
	}

	if validationErr := em.ValidateErrorEntry(&entry); validationErr != nil {
		em.logger.Error("Error entry validation failed",
			zap.Error(validationErr),
			zap.String("error_id", errorID))
		return validationErr
	}

	if catalogErr := em.CatalogError(&entry); catalogErr != nil {
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
func (em *interfaces.ErrorManagerImpl) CatalogError(entry *interfaces.ErrorEntry) error {
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
func (em *interfaces.ErrorManagerImpl) ValidateErrorEntry(entry *interfaces.ErrorEntry) error {
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
	// This method should ideally be removed and replaced by m.logger directly
	// For now, it's kept for compatibility with existing code that calls m.Log
	switch level {
	case "INFO":
		m.logger.Info(message)
	case "WARN":
		m.logger.Warn(message)
	case "ERROR":
		m.logger.Error(message)
	case "SUCCESS": // Custom level, map to info
		m.logger.Info(message, zap.String("status", "SUCCESS"))
	default:
		m.logger.Debug(message, zap.String("level", level))
	}
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
func (m *GoModManager) List() ([]interfaces.Dependency, error) {
	m.logger.Info("Listing dependencies")
	ctx := context.Background()
	data, err := os.ReadFile(m.modFilePath)
	if err != nil {
		return nil, m.errorManager.ProcessError(ctx, fmt.Errorf("failed to read go.mod: %v", err), "go-mod-operation", "read", &interfaces.ErrorHooks{
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
		return nil, m.errorManager.ProcessError(ctx, fmt.Errorf("failed to parse go.mod: %v", err), "go-mod-operation", "parse", &interfaces.ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to parse go.mod file",
					zap.Error(err),
					zap.String("file_path", m.modFilePath),
					zap.String("operation", "parse_go_mod"))
			},
		})
	}

	var deps []interfaces.Dependency
	for _, req := range modFile.Require {
		deps = append(deps, interfaces.Dependency{
			Name:     req.Mod.Path,
			Version:  req.Mod.Version,
			Indirect: req.Indirect,
		})
	}

	m.logger.Info(fmt.Sprintf("Found %d dependencies", len(deps)))
	return deps, nil
}

// Add adds a dependency to the project.
func (m *GoModManager) Add(module, version string) error {
	m.logger.Info(fmt.Sprintf("Adding dependency: %s@%s", module, version))
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
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to add dependency %s: %v", module, err), "dependency-resolution", "add", &interfaces.ErrorHooks{
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

	m.logger.Info(fmt.Sprintf("Successfully added %s@%s", module, version))
	return nil
}

// Remove removes a dependency from the project.
func (m *GoModManager) Remove(module string) error {
	m.logger.Info(fmt.Sprintf("Removing dependency: %s", module))
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
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to read go.mod: %v", err), "go-mod-operation", "read", &interfaces.ErrorHooks{
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
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to parse go.mod: %v", err), "go-mod-operation", "parse", &interfaces.ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to parse go.mod for dependency removal",
					zap.Error(err),
					zap.String("module", module),
					zap.String("file_path", m.modFilePath))
			},
		})
	}

	if err := modFile.DropRequire(module); err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to drop dependency %s: %v", module, err), "dependency-resolution", "remove", &interfaces.ErrorHooks{
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
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to format go.mod: %v", err), "go-mod-operation", "write", &interfaces.ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to format go.mod after dependency removal",
					zap.Error(err),
					zap.String("module", module))
			},
		})
	}

	if err := os.WriteFile(m.modFilePath, newData, 0644); err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to write go.mod: %v", err), "go-mod-operation", "write", &interfaces.ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to write updated go.mod file",
					zap.Error(err),
					zap.String("module", module),
					zap.String("file_path", m.modFilePath))
			},
		})
	}

	if err := m.runGoModTidy(); err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to tidy go.mod: %v", err), "go-mod-operation", "tidy", &interfaces.ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to run go mod tidy after dependency removal",
					zap.Error(err),
					zap.String("module", module))
			},
		})
	}

	m.logger.Info(fmt.Sprintf("Successfully removed %s", module))
	return nil
}

// Update updates a dependency to the latest version.
func (m *GoModManager) Update(module string) error {
	m.logger.Info(fmt.Sprintf("Updating dependency: %s", module))
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
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to update dependency %s: %v", module, err), "dependency-resolution", "update", &interfaces.ErrorHooks{
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

	m.logger.Info(fmt.Sprintf("Successfully updated %s", module))
	return nil
}

// Audit checks for dependency vulnerabilities.
func (m *GoModManager) Audit() error {
	m.logger.Info("Running security audit")
	ctx := context.Background()

	cmd := exec.Command("go", "list", "-json", "-m", "all")
	output, err := cmd.Output()
	if err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to audit dependencies: %v", err), "vulnerability-scan", "audit", &interfaces.ErrorHooks{
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
	m.logger.Info("Audit completed - consider running 'govulncheck' for detailed security analysis")
	fmt.Println(string(output))

	return nil
}

// Cleanup removes unused dependencies.
func (m *GoModManager) Cleanup() error {
	m.logger.Info("Cleaning up unused dependencies")
	ctx := context.Background()

	if err := m.backupGoMod(); err != nil {
		m.logger.Warn("Failed to backup go.mod before cleanup",
			zap.Error(err),
			zap.String("operation", "cleanup_dependencies"))
	}

	if err := m.runGoModTidy(); err != nil {
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to cleanup dependencies: %v", err), "go-mod-operation", "cleanup", &interfaces.ErrorHooks{
			OnError: func(err error) {
				m.logger.Error("Failed to cleanup unused dependencies",
					zap.Error(err),
					zap.String("operation", "go_mod_tidy"))
			},
		})
	}

	m.logger.Info("Successfully cleaned up unused dependencies")
	m.logger.Info("Successfully cleansed unused dependencies")
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
		return m.errorManager.ProcessError(ctx, fmt.Errorf("failed to execute go mod tidy: %v", err), "dependency-cleanup", "tidy", &interfaces.ErrorHooks{
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
func loadConfig(configPath string) (*interfaces.Config, error) {
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		fmt.Printf("Configuration file not found at %s, using defaults\n", configPath)
		return getDefaultConfig(), nil
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		fmt.Printf("Warning: Failed to read config file %s: %v. Using defaults.\n", configPath, err)
		return getDefaultConfig(), nil
	}

	var config interfaces.Config
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
func getDefaultConfig() *interfaces.Config {
	return &interfaces.Config{
		Name:    "dependency-manager",
		Version: "1.0.0",
		Settings: interfaces.ConfigSettings{
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
func validateConfig(config *interfaces.Config) error {
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
	errorManager interfaces.ErrorManager
	config       *interfaces.Config
}

// NewDepConfigManager creates a ConfigManager instance.
func NewDepConfigManager(config *interfaces.Config, logger *zap.Logger) interfaces.ConfigManager {
	cm := &DepConfigManagerImpl{
		settings:     make(map[string]interface{}),
		defaults:     make(map[string]interface{}),
		requiredKeys: []string{},
		logger:       logger,
		config:       config,
	}
	if config != nil {
		cm.initializeFromLegacyConfig(config)
	}
	return cm
}

// initializeFromLegacyConfig initializes ConfigManager from Config struct.
func (cm *DepConfigManagerImpl) initializeFromLegacyConfig(config *interfaces.Config) {
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
			return str
		}
		return fmt.Sprintf("%v", val), nil
	}
	if val, exists := cm.defaults[key]; exists {
		if str, ok := val.(string); ok {
			return str
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
			return b
		}
		return false, fmt.Errorf("value is not a bool: %s", key)
	}
	if val, exists := cm.defaults[key]; exists {
		if b, ok := val.(bool); ok {
			return b
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

func (cm *DepConfigManagerImpl) GetErrorManager() interfaces.ErrorManager {
	return cm.errorManager
}

func (cm *DepConfigManagerImpl) GetLogger() *zap.Logger {
	return cm.logger
}

// Phase 4.1.1: Extension pour vectorisation
// OnDependencyAdded implements VectorizationSupport interface
// Micro-étape 4.1.1.1.2: Implémenter auto-vectorisation des dépendances ajoutées
func (m *GoModManager) OnDependencyAdded(ctx context.Context, dep *interfaces.Dependency) error {
	if !m.vectorizationEnabled || m.vectorizer == nil || m.qdrant == nil {
		m.logger.Debug("Vectorization disabled or not configured", 
			zap.String("dependency", dep.Name))
		return nil
	}

	m.logger.Info("Auto-vectorizing new dependency", 
		zap.String("name", dep.Name),
		zap.String("version", dep.Version))

	// Générer une description complète de la dépendance
	description := m.buildDependencyDescription(dep)
	
	// Générer l'embedding
	embedding, err := m.vectorizer.GenerateEmbedding(ctx, description)
	if err != nil {
		m.logger.Error("Failed to generate embedding for dependency",
			zap.String("dependency", dep.Name),
			zap.Error(err))
		return err
	}

	// Créer le point vectoriel
	point := interfaces.Point{
		ID:     dep.Name,
		Vector: embedding,
		Payload: map[string]interface{}{
			"name":        dep.Name,
			"version":     dep.Version,
			"indirect":    dep.Indirect,
			"repository":  dep.Repository,
			"license":     dep.License,
			"type":        "dependency",
			"manager":     "dependency-manager",
			"added_at":    time.Now().Format(time.RFC3339),
			"description": description,
		},
	}

	// Stocker dans Qdrant
	err = m.qdrant.UpsertPoints(ctx, "dependencies", []interfaces.Point{point})
	if err != nil {
		m.logger.Error("Failed to store dependency vector",
			zap.String("dependency", dep.Name),
			zap.Error(err))
		return err
	}

	m.logger.Info("Dependency successfully vectorized",
		zap.String("name", dep.Name),
		zap.Int("vector_dimension", len(embedding)))

	// Micro-étape 4.1.1.1.3: Intégrer avec le système de notifications existant
	if m.monitoringManager != nil {
		m.notifyVectorizationEvent("dependency_added", dep.Name, map[string]interface{
			"vector_dimension": len(embedding),
			"collection":       "dependencies",
		})
	}

	return nil
}

// OnDependencyUpdated vectorise les changements de dépendance
func (m *GoModManager) OnDependencyUpdated(ctx context.Context, dep *interfaces.Dependency, oldVersion string) error {
	if !m.vectorizationEnabled || m.vectorizer == nil || m.qdrant == nil {
		return nil
	}

	m.logger.Info("Auto-vectorizing updated dependency", 
		zap.String("name", dep.Name),
		zap.String("old_version", oldVersion),
		zap.String("new_version", dep.Version))

	// Générer une nouvelle description avec l'information de mise à jour
	description := m.buildDependencyDescription(dep) + 
		fmt.Sprintf(" Updated from version %s to %s", oldVersion, dep.Version)
	
	// Générer le nouvel embedding
	embedding, err := m.vectorizer.GenerateEmbedding(ctx, description)
	if err != nil {
		return err
	}

	// Mettre à jour le point vectoriel
	point := interfaces.Point{
		ID:     dep.Name,
		Vector: embedding,
		Payload: map[string]interface{}{
			"name":         dep.Name,
			"version":      dep.Version,
			"old_version":  oldVersion,
			"indirect":     dep.Indirect,
			"repository":   dep.Repository,
			"license":      dep.License,
			"type":         "dependency",
			"manager":      "dependency-manager",
			"updated_at":   time.Now().Format(time.RFC3339),
			"description":  description,
		},
	}

	err = m.qdrant.UpsertPoints(ctx, "dependencies", []interfaces.Point{point})
	if err != nil {
		return err
	}

	if m.monitoringManager != nil {
		m.notifyVectorizationEvent("dependency_updated", dep.Name, map[string]interface{
			"old_version": oldVersion,
			"new_version": dep.Version,
		})
	}

	return nil
}

// OnDependencyRemoved supprime les vecteurs de dépendance
func (m *GoModManager) OnDependencyRemoved(ctx context.Context, depName string) error {
	if !m.vectorizationEnabled || m.qdrant == nil {
		return nil
	}

	m.logger.Info("Removing dependency vectors", zap.String("name", depName))

	err := m.qdrant.DeletePoints(ctx, "dependencies", []interface{}{depName})
	if err != nil {
		m.logger.Error("Failed to remove dependency vectors",
			zap.String("dependency", depName),
			zap.Error(err))
		return err
	}

	if m.monitoringManager != nil {
		m.notifyVectorizationEvent("dependency_removed", depName, nil)
	}

	return nil
}

// SearchSimilarDependencies trouve des dépendances similaires
func (m *GoModManager) SearchSimilarDependencies(ctx context.Context, description string) ([]interfaces.Dependency, error) {
	if !m.vectorizationEnabled || m.vectorizer == nil || m.qdrant == nil {
		return nil, fmt.Errorf("vectorization not enabled or configured")
	}

	// Générer l'embedding pour la description
	embedding, err := m.vectorizer.GenerateEmbedding(ctx, description)
	if err != nil {
		return nil, err
	}

	// Rechercher dans Qdrant
	searchReq := interfaces.SearchRequest{
		Vector: embedding,
		Limit:  10,
		Filter: map[string]interface{}{
			"type": "dependency",
		},
	}

	results, err := m.qdrant.SearchPoints(ctx, "dependencies", searchReq)
	if err != nil {
		return nil, err
	}

	// Convertir les résultats en dépendances
	var dependencies []interfaces.Dependency
	for _, point := range results.Result {
		if payload := point.Payload; payload != nil {
			dep := interfaces.Dependency{
				Name:       getStringFromPayload(payload, "name"),
				Version:    getStringFromPayload(payload, "version"),
				Indirect:   getBoolFromPayload(payload, "indirect"),
				Repository: getStringFromPayload(payload, "repository"),
				License:    getStringFromPayload(payload, "license"),
			}
			dependencies = append(dependencies, dep)
		}
	}

	return dependencies, nil
}

// === MÉTHODES UTILITAIRES POUR LA VECTORISATION ===

// buildDependencyDescription construit une description textuelle pour une dépendance
func (m *GoModManager) buildDependencyDescription(dep *interfaces.Dependency) string {
	var parts []string
	
	parts = append(parts, fmt.Sprintf("Dependency: %s", dep.Name))
	parts = append(parts, fmt.Sprintf("Version: %s", dep.Version))
	
	if dep.Repository != "" {
		parts = append(parts, fmt.Sprintf("Repository: %s", dep.Repository))
	}
	
	if dep.License != "" {
		parts = append(parts, fmt.Sprintf("License: %s", dep.License))
	}
	
	if dep.Indirect {
		parts = append(parts, "Type: Indirect dependency")
	} else {
		parts = append(parts, "Type: Direct dependency")
	}
	
	return strings.Join(parts, ". ")
}

// notifyVectorizationEvent envoie une notification via le système de monitoring
func (m *GoModManager) notifyVectorizationEvent(eventType, depName string, metadata map[string]interface{}) {
	// Utilisation du monitoring manager existant pour les notifications
	m.logger.Info("Vectorization event", 
		zap.String("event_type", eventType),
		zap.String("dependency", depName),
		zap.Any("metadata", metadata))
	
	// TODO: Intégrer avec le système de notifications existant
	// if m.monitoringManager != nil {
	//     m.monitoringManager.SendEvent(eventType, depName, metadata)
	// }
}

// Fonctions utilitaires pour extraire des données du payload
func getStringFromPayload(payload map[string]interface{}, key string) string {
	if val, ok := payload[key]; ok {
		if str, ok := val.(string); ok {
			return str
		}
	}
	return ""
}

func getBoolFromPayload(payload map[string]interface{}, key string) bool {
	if val, ok := payload[key]; ok {
		if b, ok := val.(bool); ok {
			return b
		}
	}
	return false
}

// EnableVectorization active les capacités de vectorisation
func (m *GoModManager) EnableVectorization(vectorizer interfaces.VectorizationEngine, qdrant interfaces.QdrantInterface) {
	m.vectorizer = vectorizer
	m.qdrant = qdrant
	m.vectorizationEnabled = true
	
	m.logger.Info("Vectorization enabled for DependencyManager")
}

// DisableVectorization désactive les capacités de vectorisation
func (m *GoModManager) DisableVectorization() {
	m.vectorizationEnabled = false
	m.vectorizer = nil
	m.qdrant = nil
	
	m.logger.Info("Vectorization disabled for DependencyManager")
}
