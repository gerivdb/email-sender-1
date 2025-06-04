package configmanager

import (
	"fmt"
	"path/filepath"
)

// RealIntegratedErrorManager defines the interface that matches the actual IntegratedErrorManager
// This allows us to integrate with the real integrated-manager package without circular imports
type RealIntegratedErrorManager interface {
	PropagateError(module string, err error, context map[string]interface{})
	AddHook(module string, hook func(module string, err error, context map[string]interface{}))
}

// RealIntegratedManagerConnector provides connection to the real IntegratedManager
type RealIntegratedManagerConnector struct {
	errorManager  RealIntegratedErrorManager
	configManager ConfigManager
	isConnected   bool
}

// NewRealIntegratedManagerConnector creates a new connector for the real IntegratedManager
func NewRealIntegratedManagerConnector(errorMgr RealIntegratedErrorManager) *RealIntegratedManagerConnector {
	connector := &RealIntegratedManagerConnector{
		errorManager: errorMgr,
		isConnected:  false,
	}

	// Add config-manager specific error hook to the real error manager
	if errorMgr != nil {
		errorMgr.AddHook("config-manager", func(module string, err error, context map[string]interface{}) {
			connector.handleConfigError(module, err, context)
		})
	}

	return connector
}

// InitializeWithRealManager initializes the config manager and connects it to the real IntegratedManager
func (rimc *RealIntegratedManagerConnector) InitializeWithRealManager() (ConfigManager, error) {
	// Create the config manager
	cm, err := New()
	if err != nil {
		rimc.propagateError("config-manager", err, map[string]interface{}{
			"operation": "initialization",
			"phase":     "config_manager_creation",
			"connector": "real_integrated_manager",
		})
		return nil, fmt.Errorf("failed to create config manager with real integration: %w", err)
	}

	// Set up project-specific defaults for EMAIL_SENDER_1
	err = rimc.setupProjectDefaults(cm)
	if err != nil {
		rimc.propagateError("config-manager", err, map[string]interface{}{
			"operation": "initialization",
			"phase":     "default_configuration",
			"connector": "real_integrated_manager",
		})
		return nil, fmt.Errorf("failed to setup project defaults: %w", err)
	}

	rimc.configManager = cm
	rimc.isConnected = true

	return cm, nil
}

// setupProjectDefaults configures default settings for EMAIL_SENDER_1 project
func (rimc *RealIntegratedManagerConnector) setupProjectDefaults(cm ConfigManager) error {
	defaults := map[string]interface{}{
		// Application settings
		"app.name":        "EMAIL_SENDER_1",
		"app.version":     "1.0.0",
		"app.environment": "development",
		"app.debug":       true,

		// Logging configuration
		"logging.level":       "Info",
		"logging.file":        "logs/application.log",
		"logging.max_size":    100, // MB
		"logging.max_backups": 5,
		"logging.max_age":     30, // days
		"logging.console":     true,

		// Manager settings - enabled by default
		"managers.enabled":                    true,
		"managers.config_manager.enabled":     true,
		"managers.error_manager.enabled":      true,
		"managers.dependency_manager.enabled": true,
		"managers.process_manager.enabled":    true,
		"managers.script_manager.enabled":     true,
		"managers.roadmap_manager.enabled":    true,
		"managers.mode_manager.enabled":       true,
		"managers.integrated_manager.enabled": true,

		// Database configuration
		"database.driver":          "sqlite",
		"database.host":            "localhost",
		"database.port":            5432,
		"database.name":            "email_sender",
		"database.username":        "app_user",
		"database.password":        "",
		"database.ssl_mode":        "disable",
		"database.max_connections": 10,
		"database.timeout":         30,

		// Email configuration defaults
		"email.smtp.host":     "localhost",
		"email.smtp.port":     587,
		"email.smtp.username": "",
		"email.smtp.password": "",
		"email.smtp.tls":      true,
		"email.from":          "noreply@email-sender.local",
		"email.max_retries":   3,
		"email.timeout":       30,

		// Security settings
		"security.encryption_key":  "default-key-change-in-production",
		"security.jwt_secret":      "default-jwt-secret",
		"security.session_timeout": 3600,

		// File paths
		"paths.logs":      "logs/",
		"paths.config":    "config/",
		"paths.templates": "templates/",
		"paths.uploads":   "uploads/",
		"paths.backups":   "backups/",
	}

	for key, value := range defaults {
		cm.SetDefault(key, value)
	}

	return nil
}

// GetConfigManager returns the connected config manager
func (rimc *RealIntegratedManagerConnector) GetConfigManager() ConfigManager {
	return rimc.configManager
}

// IsConnected returns whether the connector is properly connected to the real manager
func (rimc *RealIntegratedManagerConnector) IsConnected() bool {
	return rimc.isConnected && rimc.errorManager != nil
}

// LoadManagerConfig loads configuration for a specific manager through the real integration
func (rimc *RealIntegratedManagerConnector) LoadManagerConfig(managerName, configPath, fileType string) error {
	if !rimc.isConnected || rimc.configManager == nil {
		return fmt.Errorf("connector not properly initialized")
	}

	err := rimc.configManager.LoadConfigFile(configPath, fileType)
	if err != nil {
		rimc.propagateError("config-manager", err, map[string]interface{}{
			"operation":   "load_manager_config",
			"manager":     managerName,
			"config_path": configPath,
			"file_type":   fileType,
			"connector":   "real_integrated_manager",
		})
		return fmt.Errorf("failed to load config file for %s: %w", managerName, err)
	}

	return nil
}

// ValidateManagerConfig validates configuration for a specific manager
func (rimc *RealIntegratedManagerConnector) ValidateManagerConfig(managerName string, requiredKeys []string) error {
	if !rimc.isConnected || rimc.configManager == nil {
		return fmt.Errorf("connector not properly initialized")
	}

	// Add manager prefix to required keys
	prefixedKeys := make([]string, len(requiredKeys))
	for i, key := range requiredKeys {
		prefixedKeys[i] = fmt.Sprintf("managers.%s.%s", managerName, key)
	}

	// Store current required keys and temporarily set new ones for validation
	originalRequiredKeys := rimc.configManager.(*configManagerImpl).requiredKeys
	rimc.configManager.SetRequiredKeys(prefixedKeys)

	err := rimc.configManager.Validate()

	// Restore original required keys
	rimc.configManager.SetRequiredKeys(originalRequiredKeys)

	if err != nil {
		rimc.propagateError("config-manager", err, map[string]interface{}{
			"operation":     "validate_manager_config",
			"manager":       managerName,
			"required_keys": requiredKeys,
			"connector":     "real_integrated_manager",
		})
		return fmt.Errorf("validation failed for %s manager: %w", managerName, err)
	}

	return nil
}

// GetManagerConfig retrieves configuration for a specific manager
func (rimc *RealIntegratedManagerConnector) GetManagerConfig(managerName string) (map[string]interface{}, error) {
	if !rimc.isConnected || rimc.configManager == nil {
		return nil, fmt.Errorf("connector not properly initialized")
	}

	// Return empty config for empty manager name
	if managerName == "" {
		return make(map[string]interface{}), nil
	}

	managerPrefix := fmt.Sprintf("managers.%s", managerName)
	config := make(map[string]interface{})

	// Get all configuration keys and filter for this manager
	allConfig := rimc.configManager.GetAll()
	for key, value := range allConfig {
		if len(key) > len(managerPrefix) && key[:len(managerPrefix)] == managerPrefix {
			// Remove the manager prefix to get the clean key
			cleanKey := key[len(managerPrefix)+1:] // +1 for the dot
			config[cleanKey] = value
		}
	}

	return config, nil
}

// propagateError safely propagates errors to the real IntegratedErrorManager
func (rimc *RealIntegratedManagerConnector) propagateError(module string, err error, context map[string]interface{}) {
	if rimc.errorManager != nil {
		rimc.errorManager.PropagateError(module, err, context)
	}
}

// handleConfigError handles config-manager specific errors
func (rimc *RealIntegratedManagerConnector) handleConfigError(module string, err error, context map[string]interface{}) {
	// Log the error with specific context
	if operation, ok := context["operation"]; ok {
		switch operation {
		case "load_manager_config":
			if manager, ok := context["manager"]; ok {
				fmt.Printf("🔧 Config loading error for %s manager: %s\n", manager, err.Error())
			}
		case "validate_manager_config":
			if manager, ok := context["manager"]; ok {
				fmt.Printf("✅ Config validation error for %s manager: %s\n", manager, err.Error())
			}
		case "initialization":
			fmt.Printf("🚀 Config manager initialization error: %s\n", err.Error())
		default:
			fmt.Printf("⚙️ Config manager error [%s]: %s\n", operation, err.Error())
		}
	} else {
		fmt.Printf("⚙️ Config manager error: %s\n", err.Error())
	}
}

// SetupManagerDefaults sets up default configurations for all managers
func (rimc *RealIntegratedManagerConnector) SetupManagerDefaults() error {
	if !rimc.isConnected || rimc.configManager == nil {
		return fmt.Errorf("connector not properly initialized")
	}

	// Additional manager-specific defaults
	managerDefaults := map[string]interface{}{
		// Error Manager
		"managers.error_manager.max_errors":      1000,
		"managers.error_manager.retention_days":  30,
		"managers.error_manager.severity_levels": []string{"DEBUG", "INFO", "WARN", "ERROR", "CRITICAL"},

		// Dependency Manager
		"managers.dependency_manager.package_timeout": 60,
		"managers.dependency_manager.retry_attempts":  3,
		"managers.dependency_manager.cache_enabled":   true,

		// Process Manager
		"managers.process_manager.max_processes":      10,
		"managers.process_manager.process_timeout":    300,
		"managers.process_manager.restart_on_failure": true,

		// Script Manager
		"managers.script_manager.script_timeout":     120,
		"managers.script_manager.max_concurrent":     5,
		"managers.script_manager.allowed_extensions": []string{".ps1", ".sh", ".py", ".js"},

		// Roadmap Manager
		"managers.roadmap_manager.validation_enabled": true,
		"managers.roadmap_manager.auto_progress":      false,
		"managers.roadmap_manager.phase_timeout":      3600,

		// Mode Manager
		"managers.mode_manager.default_mode":   "development",
		"managers.mode_manager.allowed_modes":  []string{"development", "testing", "production"},
		"managers.mode_manager.mode_switching": true,

		// Integrated Manager
		"managers.integrated_manager.centralized_errors": true,
		"managers.integrated_manager.hook_timeout":       30,
		"managers.integrated_manager.queue_size":         100,
	}

	for key, value := range managerDefaults {
		rimc.configManager.SetDefault(key, value)
	}

	return nil
}

// CreateManagerConfigFile creates a configuration file template for a specific manager
func (rimc *RealIntegratedManagerConnector) CreateManagerConfigFile(managerName, configPath, fileType string) error {
	if !rimc.isConnected || rimc.configManager == nil {
		return fmt.Errorf("connector not properly initialized")
	}

	// Get manager-specific configuration
	config, err := rimc.GetManagerConfig(managerName)
	if err != nil {
		rimc.propagateError("config-manager", err, map[string]interface{}{
			"operation":   "create_manager_config",
			"manager":     managerName,
			"config_path": configPath,
			"file_type":   fileType,
		})
		return fmt.Errorf("failed to get manager config: %w", err)
	}

	// Create the directory if it doesn't exist
	configDir := filepath.Dir(configPath)
	err = rimc.configManager.(*configManagerImpl).ensureDirectoryExists(configDir)
	if err != nil {
		rimc.propagateError("config-manager", err, map[string]interface{}{
			"operation":   "create_manager_config",
			"manager":     managerName,
			"config_path": configPath,
			"directory":   configDir,
		})
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	// Save the configuration to file
	err = rimc.configManager.SaveToFile(configPath, fileType, config)
	if err != nil {
		rimc.propagateError("config-manager", err, map[string]interface{}{
			"operation":   "create_manager_config",
			"manager":     managerName,
			"config_path": configPath,
			"file_type":   fileType,
		})
		return fmt.Errorf("failed to save manager config file: %w", err)
	}

	return nil
}
