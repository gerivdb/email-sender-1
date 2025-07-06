package tests

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time" // Added for time.Now() in mock

	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"

	"EMAIL_SENDER_1/development/managers/dependencymanager" // New import
	"EMAIL_SENDER_1/development/managers/interfaces"        // New import
)

// TestConfigManagerIntegration tests integration with ConfigManager
func TestConfigManagerIntegration(t *testing.T) {
	logger := zaptest.NewLogger(t)
	tempDir := t.TempDir()
	configPath := filepath.Join(tempDir, "dependency-manager.config.json")

	// Create a test config file
	configContent := `{
		"name": "dependency-manager",
		"version": "1.0.0",
		"settings": {
			"logPath": "test-logs/dependency-manager.log",
			"logLevel": "info",
			"goModPath": "go.mod",
			"autoTidy": true,
			"vulnerabilityCheck": true,
			"backupOnChange": true
		}
	}`

	err := os.WriteFile(configPath, []byte(configContent), 0o644)
	if err != nil {
		t.Fatalf("Failed to create test config file: %v", err)
	}

	// Create ErrorManager for ConfigManager
	errorManager := &interfaces.ErrorManagerImpl{logger: logger}

	// Create ConfigManager
	configManager := interfaces.NewDepConfigManager(&interfaces.Config{}, logger) // Pass a dummy config

	// Load config file
	err = configManager.LoadConfigFile(configPath, "json")
	if err != nil {
		t.Fatalf("Failed to load config file: %v", err)
	}

	// Test GetString
	logPath, err := configManager.GetString("dependency-manager.settings.logPath")
	if err != nil {
		t.Errorf("GetString failed: %v", err)
	}
	if logPath != "test-logs/dependency-manager.log" {
		t.Errorf("Expected logPath to be 'test-logs/dependency-manager.log', got '%s'", logPath)
	}

	// Test GetBool
	autoTidy, err := configManager.GetBool("dependency-manager.settings.autoTidy")
	if err != nil {
		t.Errorf("GetBool failed: %v", err)
	}
	if !autoTidy {
		t.Errorf("Expected autoTidy to be true")
	}

	// Test IsSet
	if !configManager.IsSet("dependency-manager.settings.logPath") {
		t.Error("IsSet failed for existing key")
	}
	if configManager.IsSet("dependency-manager.nonexistent") {
		t.Error("IsSet incorrectly returned true for non-existent key")
	}

	// Test SetDefault and Get
	configManager.SetDefault("dependency-manager.test.default", "default-value")
	value := configManager.Get("dependency-manager.test.default")
	if value != "default-value" {
		t.Errorf("Expected default value to be 'default-value', got '%v'", value)
	}

	// Test Set and Get
	configManager.Set("dependency-manager.test.custom", "custom-value")
	customValue := configManager.Get("dependency-manager.test.custom")
	if customValue != "custom-value" {
		t.Errorf("Expected custom value to be 'custom-value', got '%v'", customValue)
	}

	// Create DependencyManager with ConfigManager
	manager := &dependencymanager.GoModManager{
		modFilePath:   "go.mod",
		configManager: configManager,
		logger:        logger,
		errorManager:  errorManager,
	}

	// Test the integration
	// This will use configManager.GetString to get logPath
	// manager.Log("TEST", "Config integration test") // Removed m.Log as it's not part of dependencymanager.GoModManager
	manager.Logger.Info("Config integration test") // Use manager's logger directly

	// Test backupGoMod which uses configManager.GetBool
	err = manager.BackupGoMod() // Corrected method name
	if err != nil {
		// We expect an error since we're not actually modifying a real go.mod file
		t.Logf("Expected error in backupGoMod: %v", err)
	}
}

// TestConfigDefaultFallback tests that default config is used when file not found
func TestConfigDefaultFallback(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &interfaces.ErrorManagerImpl{logger: logger}

	// Non-existent config path
	nonExistentPath := "/tmp/nonexistent/config.json"

	// Create ConfigManager with nil config
	configManager := interfaces.NewDepConfigManager(&interfaces.Config{}, logger) // Pass a dummy config

	// Try to load non-existent file
	err := configManager.LoadConfigFile(nonExistentPath, "json")
	if err == nil {
		// We actually expect it to return nil and use defaults
		t.Logf("LoadConfigFile with non-existent file did not return error, using defaults")
	}

	// Check defaults are set
	logLevel, err := configManager.GetString("dependency-manager.settings.logLevel")
	if err != nil {
		t.Errorf("GetString for default logLevel failed: %v", err)
	}

	// Default log level should be "info"
	if logLevel != "info" {
		t.Errorf("Expected default logLevel to be 'info', got '%s'", logLevel)
	}

	// Test setting required keys and validation
	configManager.SetRequiredKeys([]string{"dependency-manager.settings.logPath"})
	err = configManager.Validate()
	if err != nil {
		t.Errorf("Validation failed: %v", err)
	}

	// Test validation with non-existent required key
	configManager.SetRequiredKeys([]string{"dependency-manager.nonexistent"})
	err = configManager.Validate()
	if err == nil {
		t.Error("Expected validation to fail for non-existent required key")
	}
}

// TestErrorManagerIntegration tests integration with ErrorManager
func TestErrorManagerIntegration(t *testing.T) {
	logger := zaptest.NewLogger(t)
	errorManager := &interfaces.ErrorManagerImpl{logger: logger}

	// Test ProcessError
	// Simplified the ProcessError call as the original was malformed
	testErr := errorManager.ProcessError(
		fmt.Errorf("simulated error"),
		"test-component",
		zap.String("operation", "test-operation"),
	)
	if testErr == nil {
		t.Errorf("Expected an error from ProcessError, got nil")
	}

	// Test CatalogError
	entry := interfaces.ErrorEntry{
		ID:        "test-id",
		Timestamp: time.Now(),
		Message:   "test message",
		Module:    "test-module",
		ErrorCode: "TEST-001",
		Severity:  "low",
	}
	err := errorManager.CatalogError(&entry)
	if err != nil {
		t.Errorf("CatalogError failed: %v", err)
	}

	// Test ValidateErrorEntry
	validEntry := interfaces.ErrorEntry{
		ID:        "valid-id",
		Timestamp: time.Now(),
		Message:   "valid message",
		Module:    "valid-module",
		ErrorCode: "VALID-001",
		Severity:  "medium",
	}
	err = errorManager.ValidateErrorEntry(&validEntry)
	if err != nil {
		t.Errorf("ValidateErrorEntry failed for valid entry: %v", err)
	}

	invalidEntry := interfaces.ErrorEntry{
		ID:        "", // Invalid
		Timestamp: time.Now(),
		Message:   "invalid message",
		Module:    "invalid-module",
		ErrorCode: "INVALID-001",
		Severity:  "invalid", // Invalid
	}
	err = errorManager.ValidateErrorEntry(&invalidEntry)
	if err == nil {
		t.Error("Expected ValidateErrorEntry to fail for invalid entry, got nil")
	}
}
