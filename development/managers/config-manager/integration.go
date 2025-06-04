package configmanager

import (
	"fmt"
	"path/filepath"
)

// IntegrationManager defines the interface for manager integration
// This interface should be implemented by the actual IntegratedManager
type IntegrationManager interface {
	InitializeConfigManager() (ConfigManager, error)
	GetConfigManager() ConfigManager
	PropagateError(module string, err error, context map[string]interface{})
}

// ErrorHook defines a function type for error handling hooks
type ErrorHook func(module string, err error, context map[string]interface{})

// IntegratedErrorManagerInterface defines the minimal interface we need
// from the actual IntegratedErrorManager without importing the package
type IntegratedErrorManagerInterface interface {
	PropagateError(module string, err error, context map[string]interface{})
	AddHook(module string, hook ErrorHook)
}

// RealIntegratedManagerAdapter adapts the real IntegratedManager to our interface
// This allows integration with the actual integrated-manager package
type RealIntegratedManagerAdapter struct {
	errorManager  IntegratedErrorManagerInterface
	configManager ConfigManager
}

// NewRealIntegratedManagerAdapter creates a new adapter with the real IntegratedManager
func NewRealIntegratedManagerAdapter(errorMgr IntegratedErrorManagerInterface) *RealIntegratedManagerAdapter {
	return &RealIntegratedManagerAdapter{
		errorManager: errorMgr,
	}
}

// InitializeConfigManager implements IntegrationManager interface
func (rima *RealIntegratedManagerAdapter) InitializeConfigManager() (ConfigManager, error) {
	cm, err := New()
	if err != nil {
		rima.PropagateError("config-manager", err, map[string]interface{}{
			"operation": "initialization",
			"phase":     "config_manager_creation",
		})
		return nil, fmt.Errorf("failed to create config manager: %w", err)
	}

	rima.configManager = cm
	return cm, nil
}

// GetConfigManager implements IntegrationManager interface
func (rima *RealIntegratedManagerAdapter) GetConfigManager() ConfigManager {
	return rima.configManager
}

// PropagateError implements IntegrationManager interface
func (rima *RealIntegratedManagerAdapter) PropagateError(module string, err error, context map[string]interface{}) {
	if rima.errorManager != nil {
		rima.errorManager.PropagateError(module, err, context)
	}
}

// IntegratedConfigManager wraps ConfigManager with integration capabilities
type IntegratedConfigManager struct {
	configManager      ConfigManager
	integrationManager IntegrationManager
	isInitialized      bool
}

// NewIntegratedConfigManager creates a new integrated config manager
func NewIntegratedConfigManager(integrationMgr IntegrationManager) (*IntegratedConfigManager, error) {
	icm := &IntegratedConfigManager{
		integrationManager: integrationMgr,
		isInitialized:      false,
	}

	return icm, nil
}

// Initialize initializes the config manager with default configurations
func (icm *IntegratedConfigManager) Initialize() error {
	if icm.isInitialized {
		return nil
	}

	// Create the config manager
	cm, err := New()
	if err != nil {
		if icm.integrationManager != nil {
			icm.integrationManager.PropagateError("config-manager", err, map[string]interface{}{
				"operation": "initialization",
				"phase":     "config_manager_creation",
			})
		}
		return fmt.Errorf("failed to create config manager: %w", err)
	}

	// Register default configurations for the EMAIL_SENDER_1 project
	err = icm.registerProjectDefaults(cm)
	if err != nil {
		if icm.integrationManager != nil {
			icm.integrationManager.PropagateError("config-manager", err, map[string]interface{}{
				"operation": "initialization",
				"phase":     "default_registration",
			})
		}
		return fmt.Errorf("failed to register default configurations: %w", err)
	}

	// Load environment variables with project prefix
	cm.LoadFromEnv("EMAIL_SENDER_")

	// Try to load main configuration file
	configPath := "projet/config/app-config.json"
	if err := cm.LoadConfigFile(configPath, "json"); err != nil {
		// Log but don't fail - config file is optional
		if icm.integrationManager != nil {
			icm.integrationManager.PropagateError("config-manager", err, map[string]interface{}{
				"operation":   "config_file_load",
				"config_path": configPath,
				"severity":    "warning",
			})
		}
	}

	// Set required keys for validation
	requiredKeys := []string{
		"app.name",
		"app.version",
		"logging.level",
		"managers.enabled",
	}
	cm.SetRequiredKeys(requiredKeys)

	// Validate configuration
	if err := cm.Validate(); err != nil {
		if icm.integrationManager != nil {
			icm.integrationManager.PropagateError("config-manager", err, map[string]interface{}{
				"operation":     "validation",
				"required_keys": requiredKeys,
			})
		}
		return fmt.Errorf("configuration validation failed: %w", err)
	}

	icm.configManager = cm
	icm.isInitialized = true

	return nil
}

// GetConfigManager returns the underlying config manager
func (icm *IntegratedConfigManager) GetConfigManager() ConfigManager {
	return icm.configManager
}

// IsInitialized returns whether the config manager has been initialized
func (icm *IntegratedConfigManager) IsInitialized() bool {
	return icm.isInitialized
}

// registerProjectDefaults registers default configurations for EMAIL_SENDER_1
func (icm *IntegratedConfigManager) registerProjectDefaults(cm ConfigManager) error {
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

		// Manager settings
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

		// Email configuration
		"email.smtp.host":     "localhost",
		"email.smtp.port":     587,
		"email.smtp.username": "",
		"email.smtp.password": "",
		"email.smtp.tls":      true,
		"email.from_address":  "noreply@emailsender.local",
		"email.from_name":     "Email Sender",

		// N8N integration
		"n8n.host":        "localhost",
		"n8n.port":        5678,
		"n8n.webhook_url": "http://localhost:5678/webhook",
		"n8n.api_key":     "",

		// MCP configuration
		"mcp.gateway.host": "localhost",
		"mcp.gateway.port": 8080,
		"mcp.servers":      []string{},

		// Security settings
		"security.jwt_secret":         "your-secret-key-here",
		"security.session_timeout":    3600, // seconds
		"security.max_login_attempts": 3,

		// Performance settings
		"performance.cache_ttl":           300, // seconds
		"performance.max_concurrent_jobs": 10,
		"performance.request_timeout":     30, // seconds

		// File paths
		"paths.data":      "data",
		"paths.logs":      "logs",
		"paths.temp":      "temp",
		"paths.uploads":   "uploads",
		"paths.templates": "templates",
		"paths.config":    "projet/config",
		"paths.scripts":   "development/scripts",
		"paths.managers":  "development/managers",
	}

	cm.RegisterDefaults(defaults)
	return nil
}

// GetManagerConfig returns configuration for a specific manager
func (icm *IntegratedConfigManager) GetManagerConfig(managerName string) (map[string]interface{}, error) {
	if !icm.isInitialized {
		return nil, fmt.Errorf("config manager not initialized")
	}

	managerConfig := make(map[string]interface{})
	configKey := fmt.Sprintf("managers.%s", managerName)

	// Check if manager is enabled
	enabled, err := icm.configManager.GetBool(fmt.Sprintf("%s.enabled", configKey))
	if err != nil {
		// Default to true if not specified
		enabled = true
	}
	managerConfig["enabled"] = enabled

	// Try to unmarshal specific manager configuration
	err = icm.configManager.UnmarshalKey(configKey, &managerConfig)
	if err != nil {
		// If no specific config found, that's okay
		if icm.integrationManager != nil {
			icm.integrationManager.PropagateError("config-manager", err, map[string]interface{}{
				"operation":  "get_manager_config",
				"manager":    managerName,
				"config_key": configKey,
				"severity":   "info",
			})
		}
	}

	return managerConfig, nil
}

// LoadManagerConfigFile loads a configuration file specific to a manager
func (icm *IntegratedConfigManager) LoadManagerConfigFile(managerName, configPath string) error {
	if !icm.isInitialized {
		return fmt.Errorf("config manager not initialized")
	}

	// Determine file type from extension
	ext := filepath.Ext(configPath)
	var fileType string
	switch ext {
	case ".json":
		fileType = "json"
	case ".yaml", ".yml":
		fileType = "yaml"
	case ".toml":
		fileType = "toml"
	default:
		return fmt.Errorf("unsupported config file type: %s", ext)
	}

	err := icm.configManager.LoadConfigFile(configPath, fileType)
	if err != nil {
		if icm.integrationManager != nil {
			icm.integrationManager.PropagateError("config-manager", err, map[string]interface{}{
				"operation":   "load_manager_config",
				"manager":     managerName,
				"config_path": configPath,
				"file_type":   fileType,
			})
		}
		return fmt.Errorf("failed to load config file for %s: %w", managerName, err)
	}

	return nil
}

// ValidateManagerConfig validates configuration for a specific manager
func (icm *IntegratedConfigManager) ValidateManagerConfig(managerName string, requiredKeys []string) error {
	if !icm.isInitialized {
		return fmt.Errorf("config manager not initialized")
	}

	// Add manager prefix to required keys
	prefixedKeys := make([]string, len(requiredKeys))
	for i, key := range requiredKeys {
		prefixedKeys[i] = fmt.Sprintf("managers.%s.%s", managerName, key)
	}

	// Temporarily set required keys for validation
	originalRequiredKeys := icm.configManager.(*configManagerImpl).requiredKeys
	icm.configManager.SetRequiredKeys(prefixedKeys)

	err := icm.configManager.Validate()

	// Restore original required keys
	icm.configManager.SetRequiredKeys(originalRequiredKeys)

	if err != nil {
		if icm.integrationManager != nil {
			icm.integrationManager.PropagateError("config-manager", err, map[string]interface{}{
				"operation":     "validate_manager_config",
				"manager":       managerName,
				"required_keys": requiredKeys,
			})
		}
		return fmt.Errorf("validation failed for %s manager: %w", managerName, err)
	}

	return nil
}
