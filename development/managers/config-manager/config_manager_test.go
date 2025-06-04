package configmanager

import (
	"os"
	"testing"
)

// TestNewConfigManager checks the creation of a new ConfigManager.
func TestNewConfigManager(t *testing.T) {
	cm, err := New()
	if err != nil {
		t.Fatalf("New() error = %v, wantErr %v", err, false)
	}
	if cm == nil {
		t.Fatal("New() returned nil ConfigManager")
	}
}

// TestRegisterDefaults tests the RegisterDefaults functionality.
func TestRegisterDefaults(t *testing.T) {
	cm, err := New()
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	defaults := map[string]interface{}{
		"test.string": "default_value",
		"test.int":    42,
		"test.bool":   true,
	}

	cm.RegisterDefaults(defaults)

	// Test string default
	if !cm.IsSet("test.string") {
		t.Error("Expected test.string to be set after RegisterDefaults")
	}

	value, err := cm.GetString("test.string")
	if err != nil {
		t.Errorf("GetString() error = %v", err)
	}
	if value != "default_value" {
		t.Errorf("GetString() = %q, want %q", value, "default_value")
	}

	// Test int default
	intValue, err := cm.GetInt("test.int")
	if err != nil {
		t.Errorf("GetInt() error = %v", err)
	}
	if intValue != 42 {
		t.Errorf("GetInt() = %d, want %d", intValue, 42)
	}

	// Test bool default
	boolValue, err := cm.GetBool("test.bool")
	if err != nil {
		t.Errorf("GetBool() error = %v", err)
	}
	if !boolValue {
		t.Errorf("GetBool() = %t, want %t", boolValue, true)
	}
}

// TestIsSet tests the IsSet functionality.
func TestIsSet(t *testing.T) {
	cm, err := New()
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	// Test key that doesn't exist
	if cm.IsSet("nonexistent.key") {
		t.Error("Expected nonexistent.key to not be set")
	}

	// Test key after setting defaults
	cm.RegisterDefaults(map[string]interface{}{
		"existing.key": "value",
	})

	if !cm.IsSet("existing.key") {
		t.Error("Expected existing.key to be set after RegisterDefaults")
	}
}

// TestGetString_KeyNotFound tests error handling for missing keys.
func TestGetString_KeyNotFound(t *testing.T) {
	cm, err := New()
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	_, err = cm.GetString("nonexistent.key")
	if err == nil {
		t.Error("Expected error for nonexistent key")
	}
}

// TestLoadConfigFile_JSON tests loading JSON configuration files.
func TestLoadConfigFile_JSON(t *testing.T) {
	cm, err := New()
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	// Load test JSON config
	err = cm.LoadConfigFile("test_config.json", "json")
	if err != nil {
		t.Fatalf("LoadConfigFile() error = %v", err)
	}

	// Test that values were loaded correctly
	dbHost, err := cm.GetString("database.host")
	if err != nil {
		t.Errorf("GetString(database.host) error = %v", err)
	}
	if dbHost != "localhost" {
		t.Errorf("GetString(database.host) = %q, want %q", dbHost, "localhost")
	}

	dbPort, err := cm.GetInt("database.port")
	if err != nil {
		t.Errorf("GetInt(database.port) error = %v", err)
	}
	if dbPort != 5432 {
		t.Errorf("GetInt(database.port) = %d, want %d", dbPort, 5432)
	}
	serverDebug, err := cm.GetBool("server.debug")
	if err != nil {
		t.Errorf("GetBool(server.debug) error = %v", err)
	}
	if !serverDebug {
		t.Errorf("GetBool(server.debug) = %t, want %t", serverDebug, true)
	}
}

// TestLoadConfigFile_YAML tests loading YAML configuration files.
func TestLoadConfigFile_YAML(t *testing.T) {
	cm, err := New()
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	// Load test YAML config
	err = cm.LoadConfigFile("test_config.yaml", "yaml")
	if err != nil {
		t.Fatalf("LoadConfigFile() error = %v", err)
	}

	// Test that values were loaded correctly
	dbHost, err := cm.GetString("database.host")
	if err != nil {
		t.Errorf("GetString(database.host) error = %v", err)
	}
	if dbHost != "localhost" {
		t.Errorf("GetString(database.host) = %q, want %q", dbHost, "localhost")
	}
}

// TestLoadConfigFile_TOML tests loading TOML configuration files.
func TestLoadConfigFile_TOML(t *testing.T) {
	cm, err := New()
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	// Load test TOML config
	err = cm.LoadConfigFile("test_config.toml", "toml")
	if err != nil {
		t.Fatalf("LoadConfigFile() error = %v", err)
	}

	// Test that values were loaded correctly
	dbHost, err := cm.GetString("database.host")
	if err != nil {
		t.Errorf("GetString(database.host) error = %v", err)
	}
	if dbHost != "localhost" {
		t.Errorf("GetString(database.host) = %q, want %q", dbHost, "localhost")
	}
}

// TestLoadFromEnv tests loading from environment variables.
func TestLoadFromEnv(t *testing.T) {
	cm, err := New()
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	// Set test environment variables
	setEnv(t, "APP_TEST_HOST", "envhost")
	setEnv(t, "APP_TEST_PORT", "9000")
	setEnv(t, "APP_TEST_ENABLED", "true")

	// Load from environment
	cm.LoadFromEnv("APP_")

	// Test that env values were loaded
	host, err := cm.GetString("test.host")
	if err != nil {
		t.Errorf("GetString(test.host) error = %v", err)
	}
	if host != "envhost" {
		t.Errorf("GetString(test.host) = %q, want %q", host, "envhost")
	}

	port, err := cm.GetString("test.port")
	if err != nil {
		t.Errorf("GetString(test.port) error = %v", err)
	}
	if port != "9000" {
		t.Errorf("GetString(test.port) = %q, want %q", port, "9000")
	}
}

// TestUnmarshalKey tests unmarshaling configuration sections into structs.
func TestUnmarshalKey(t *testing.T) {
	cm, err := New()
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	// Set up test configuration
	cm.RegisterDefaults(map[string]interface{}{
		"database.host": "localhost",
		"database.port": 5432,
		"database.name": "testdb",
	})

	// Define target struct
	type DatabaseConfig struct {
		Host string `mapstructure:"host"`
		Port int    `mapstructure:"port"`
		Name string `mapstructure:"name"`
	}

	var dbConfig DatabaseConfig
	err = cm.UnmarshalKey("database", &dbConfig)
	if err != nil {
		t.Fatalf("UnmarshalKey() error = %v", err)
	}
	if dbConfig.Host != "localhost" {
		t.Errorf("UnmarshalKey() dbConfig.Host = %q, want %q", dbConfig.Host, "localhost")
	}
	if dbConfig.Port != 5432 {
		t.Errorf("UnmarshalKey() dbConfig.Port = %d, want %d", dbConfig.Port, 5432)
	}
	if dbConfig.Name != "testdb" {
		t.Errorf("UnmarshalKey() dbConfig.Name = %q, want %q", dbConfig.Name, "testdb")
	}
}

// TestValidation tests the validation functionality.
func TestValidation(t *testing.T) {
	cm, err := New()
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}

	// Set required keys
	cm.SetRequiredKeys([]string{"database.host", "server.port"})

	// Should fail validation (no config loaded)
	err = cm.Validate()
	if err == nil {
		t.Error("Expected validation to fail with missing required keys")
	}

	// Add some configuration
	cm.RegisterDefaults(map[string]interface{}{
		"database.host": "localhost",
		"server.port":   8080,
	})

	// Should pass validation now
	err = cm.Validate()
	if err != nil {
		t.Errorf("Validation failed unexpectedly: %v", err)
	}
}

// Helper function to set environment variables for testing
func setEnv(t *testing.T, key, value string) {
	t.Helper()
	originalValue, existed := os.LookupEnv(key)
	err := os.Setenv(key, value)
	if err != nil {
		t.Fatalf("Failed to set environment variable %s: %v", key, err)
	}
	if existed {
		t.Cleanup(func() {
			err := os.Setenv(key, originalValue)
			if err != nil {
				t.Fatalf("Failed to restore environment variable %s: %v", key, err)
			}
		})
	} else {
		t.Cleanup(func() {
			err := os.Unsetenv(key)
			if err != nil {
				t.Fatalf("Failed to unset environment variable %s: %v", key, err)
			}
		})
	}
}
