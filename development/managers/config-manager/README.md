# ConfigManager Module

## Overview

The `ConfigManager` is responsible for handling all application configurations. It loads settings from various sources (files, environment variables, defaults), provides typed access to them, and manages source priorities.

## Features (Implemented)

- ✅ Load configuration from JSON, YAML, and TOML files
- ✅ Load configuration from environment variables with prefix filtering
- ✅ Support for default values
- ✅ Merge configurations with a defined priority order (env > files > defaults)
- ✅ Typed access to configuration values (string, int, bool)
- ✅ Unmarshal configuration sections into Go structs using mapstructure
- ✅ Basic validation of required configuration keys
- ✅ Comprehensive error handling with custom error types
- ✅ Normalized key access (case-insensitive)
- ✅ Flat key notation support (e.g., "database.host")

## Implementation Status

- **Phase 1: Conception et Initialisation** - ✅ COMPLETE
- **Phase 2: Implémentation des Fonctionnalités Clés** - ✅ COMPLETE  
- **Phase 3: Intégration et Tests Avancés** - 🔄 IN PROGRESS
- **Phase 4: Documentation et Finalisation** - ⏳ PENDING

## Structure

- `config_manager.go`: Contains the main `ConfigManager` interface and its implementation
- `loader.go`: Implements the logic for loading configurations from different sources (JSON/YAML/TOML/ENV)
- `types.go`: Defines any internal data structures used by the manager
- `config_manager_test.go`: Contains comprehensive unit tests for the manager
- Test configuration files: `test_config.json`, `test_config.yaml`, `test_config.toml`

## Usage

### Initialization

```go
cfgManager, err := configmanager.New()
if err != nil {
    log.Fatalf("Failed to create ConfigManager: %v", err)
}

// Register default values
cfgManager.RegisterDefaults(map[string]interface{}{
    "logging.level": "info",
    "server.port":   8080,
    "database.host": "localhost",
})

// Set required keys for validation
cfgManager.SetRequiredKeys([]string{"database.host", "server.port"})

// Load from configuration files (supports JSON, YAML, TOML)
if err := cfgManager.LoadConfigFile("config.yaml", "yaml"); err != nil {
    log.Printf("Warning: Could not load config file: %v", err)
}

// Load from environment variables (e.g., prefixed with "APP_")
cfgManager.LoadFromEnv("APP_")

// Validate that all required keys are present
if err := cfgManager.Validate(); err != nil {
    log.Fatalf("Configuration validation failed: %v", err)
}
```plaintext
### Accessing Configuration

```go
// Get string values
logLevel, err := cfgManager.GetString("logging.level")
if err != nil {
    log.Printf("Failed to get log level: %v", err)
}

// Get integer values
serverPort, err := cfgManager.GetInt("server.port")
if err != nil {
    log.Printf("Failed to get server port: %v", err)
}

// Get boolean values
debugMode, err := cfgManager.GetBool("server.debug")
if err != nil {
    log.Printf("Failed to get debug mode: %v", err)
}

// Check if a key is set
if cfgManager.IsSet("optional.feature") {
    // Handle optional configuration
}

// Unmarshal complex configuration sections
type DatabaseConfig struct {
    Host     string `mapstructure:"host"`
    Port     int    `mapstructure:"port"`
    Name     string `mapstructure:"name"`
    Username string `mapstructure:"username"`
    Password string `mapstructure:"password"`
}

var dbConfig DatabaseConfig
if err := cfgManager.UnmarshalKey("database", &dbConfig); err != nil {
    log.Fatalf("Failed to unmarshal database config: %v", err)
}
```plaintext
### Configuration File Examples

#### JSON (config.json)

```json
{
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "myapp"
  },
  "server": {
    "port": 8080,
    "debug": true
  }
}
```plaintext
#### YAML (config.yaml)

```yaml
database:
  host: localhost
  port: 5432
  name: myapp
server:
  port: 8080
  debug: true
```plaintext
#### TOML (config.toml)

```toml
[database]
host = "localhost"
port = 5432
name = "myapp"

[server]
port = 8080
debug = true
```plaintext
### Environment Variables

Environment variables are automatically converted to configuration keys:
- `APP_DATABASE_HOST=localhost` → `database.host`
- `APP_SERVER_PORT=8080` → `server.port`
- `APP_DEBUG_MODE=true` → `debug.mode`

## Priority Order

Configuration values are resolved in the following priority order (highest to lowest):
1. Environment variables
2. Configuration files
3. Default values

## Error Handling

The ConfigManager defines specific error types:
- `ErrKeyNotFound`: Configuration key was not found
- `ErrConfigParse`: Failed to parse configuration file
- `ErrInvalidType`: Type conversion failed
- `ErrInvalidFormat`: Invalid configuration file format

## Integration with IntegratedManager

The ConfigManager seamlessly integrates with the EMAIL_SENDER_1 project's IntegratedManager system for centralized management and error handling.

### Real Integration Usage

```go
import (
    configmanager "path/to/config-manager"
    integratedmanager "path/to/integrated-manager"
)

// Initialize the IntegratedManager (contains ErrorManager)
integratedMgr, err := integratedmanager.New()
if err != nil {
    log.Fatalf("Failed to create IntegratedManager: %v", err)
}

// Create connector for real integration
connector := configmanager.NewRealIntegratedManagerConnector(integratedMgr.GetErrorManager())

// Initialize ConfigManager with full integration
configMgr, err := connector.InitializeWithRealManager()
if err != nil {
    log.Fatalf("Failed to initialize ConfigManager with integration: %v", err)
}

// Load project-specific configurations
err = connector.LoadProjectDefaults("EMAIL_SENDER_1")
if err != nil {
    log.Printf("Warning: Could not load project defaults: %v", err)
}

// Validate manager configurations
managers := []string{"storage-manager", "container-manager", "process-manager"}
for _, manager := range managers {
    requiredKeys := []string{"enabled", "timeout", "priority"}
    if err := connector.ValidateManagerConfig(manager, requiredKeys); err != nil {
        log.Printf("Manager %s validation failed: %v", manager, err)
    }
}
```plaintext
### Advanced Features

#### Dynamic Configuration Management

```go
// Set configuration values dynamically
configMgr.Set("runtime.debug_mode", true)
configMgr.Set("feature_flags.new_algorithm", "v2")

// Save current configuration to file
config := configMgr.GetAll()
err = configMgr.SaveToFile("current_config.yaml", "yaml", config)
```plaintext
#### Manager-Specific Configuration

```go
// Configure specific managers
connector.SetManagerConfig("storage-manager", map[string]interface{}{
    "enabled":     true,
    "timeout":     30,
    "priority":    1,
    "max_retries": 3,
})

// Get manager configuration
storageConfig := connector.GetManagerConfig("storage-manager")
```plaintext
## Architecture

### Integration Layer

The ConfigManager provides multiple integration layers:

1. **Basic Integration** (`integration.go`): Mock-based integration for testing
2. **Real Integration** (`real_integration.go`): Full integration with actual IntegratedManager
3. **IntegratedConfigManager**: Wrapper that combines both approaches

### Error Propagation

All configuration errors are automatically propagated to the IntegratedManager's ErrorManager with detailed context:

```go
// Error context includes:
{
    "operation": "load_config_file", 
    "file_path": "/path/to/config.yaml",
    "file_type": "yaml",
    "manager": "config-manager"
}
```plaintext
## Testing

### Running Tests

```bash
# Run all tests

go test -v

# Run specific test suite

go test -v -run TestConfigManager
go test -v -run TestIntegration
go test -v -run TestRealIntegration

# Run with coverage

go test -v -cover
```plaintext
### Test Coverage

- ✅ Unit tests for all ConfigManager methods
- ✅ Integration tests with mock IntegratedManager
- ✅ Real integration tests with actual IntegratedManager interface
- ✅ Error handling and edge cases
- ✅ Configuration file format support (JSON, YAML, TOML)
- ✅ Environment variable loading
- ✅ Validation and type conversion

## Performance Considerations

- Configuration loading is optimized for startup time
- In-memory caching of parsed configurations
- Minimal memory footprint with lazy loading
- Thread-safe operations for concurrent access

## Future Enhancements

- [ ] Configuration watching for automatic reloading
- [ ] Encrypted configuration support
- [ ] Remote configuration sources (HTTP, database)
- [ ] Configuration schema validation
- [ ] Hot-reloading without restart
