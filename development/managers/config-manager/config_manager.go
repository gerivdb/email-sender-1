package configmanager

import (
	"errors"
	"fmt"
	"strconv"
	"strings"

	"github.com/mitchellh/mapstructure"
)

// ConfigManager specific errors
var (
	ErrKeyNotFound   = errors.New("configuration key not found")
	ErrConfigParse   = errors.New("failed to parse configuration")
	ErrInvalidType   = errors.New("invalid type conversion")
	ErrInvalidFormat = errors.New("invalid configuration format")
)

// ConfigManager defines the interface for managing configurations.
type ConfigManager interface {
	// Existing methods
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

	// Additional methods for complete functionality
	Get(key string) interface{}
	Set(key string, value interface{})
	SetDefault(key string, value interface{})
	GetAll() map[string]interface{}
	SaveToFile(filePath string, fileType string, config map[string]interface{}) error
}

// configManagerImpl is the concrete implementation of ConfigManager.
type configManagerImpl struct {
	// Internal storage for configuration values
	// This will likely be a map[string]interface{} or a more sophisticated structure
	// to handle priorities and different sources.
	settings     map[string]interface{}
	defaults     map[string]interface{}
	requiredKeys []string
}

// New creates a new instance of ConfigManager.
func New() (ConfigManager, error) {
	return &configManagerImpl{
		settings:     make(map[string]interface{}),
		defaults:     make(map[string]interface{}),
		requiredKeys: make([]string, 0),
	}, nil
}

// GetString retrieves a string value from the configuration.
func (cm *configManagerImpl) GetString(key string) (string, error) {
	value, err := cm.getValue(key)
	if err != nil {
		return "", err
	}

	switch v := value.(type) {
	case string:
		return v, nil
	case fmt.Stringer:
		return v.String(), nil
	default:
		return fmt.Sprintf("%v", v), nil
	}
}

// GetInt retrieves an integer value from the configuration.
func (cm *configManagerImpl) GetInt(key string) (int, error) {
	value, err := cm.getValue(key)
	if err != nil {
		return 0, err
	}

	switch v := value.(type) {
	case int:
		return v, nil
	case int32:
		return int(v), nil
	case int64:
		return int(v), nil
	case float32:
		return int(v), nil
	case float64:
		return int(v), nil
	case string:
		parsed, parseErr := strconv.Atoi(v)
		if parseErr != nil {
			return 0, fmt.Errorf("%w: cannot convert %q to int: %v", ErrInvalidType, v, parseErr)
		}
		return parsed, nil
	default:
		return 0, fmt.Errorf("%w: cannot convert %T to int", ErrInvalidType, v)
	}
}

// GetBool retrieves a boolean value from the configuration.
func (cm *configManagerImpl) GetBool(key string) (bool, error) {
	value, err := cm.getValue(key)
	if err != nil {
		return false, err
	}

	switch v := value.(type) {
	case bool:
		return v, nil
	case string:
		parsed, parseErr := strconv.ParseBool(v)
		if parseErr != nil {
			return false, fmt.Errorf("%w: cannot convert %q to bool: %v", ErrInvalidType, v, parseErr)
		}
		return parsed, nil
	case int:
		return v != 0, nil
	case float64:
		return v != 0, nil
	default:
		return false, fmt.Errorf("%w: cannot convert %T to bool", ErrInvalidType, v)
	}
}

// UnmarshalKey unmarshals a configuration section into a struct.
func (cm *configManagerImpl) UnmarshalKey(key string, targetStruct interface{}) error {
	normalizedKey := normalizeKey(key)

	// Collect all keys that start with the given key prefix
	sectionData := make(map[string]interface{})
	keyPrefix := normalizedKey + "."

	// First check settings (highest priority)
	for k, v := range cm.settings {
		if k == normalizedKey {
			// Direct match
			sectionData[k] = v
		} else if strings.HasPrefix(k, keyPrefix) {
			// Nested key
			sectionData[k] = v
		}
	}

	// Then check defaults if no settings found
	if len(sectionData) == 0 {
		for k, v := range cm.defaults {
			if k == normalizedKey {
				sectionData[k] = v
			} else if strings.HasPrefix(k, keyPrefix) {
				sectionData[k] = v
			}
		}
	}

	if len(sectionData) == 0 {
		return fmt.Errorf("%w: %s", ErrKeyNotFound, key)
	}

	// Convert flat keys back to nested structure for unmarshaling
	nestedData := unflattenMap(sectionData, normalizedKey)

	// Use mapstructure to decode into the target struct
	decoder, err := mapstructure.NewDecoder(&mapstructure.DecoderConfig{
		Metadata: nil,
		Result:   targetStruct,
		TagName:  "mapstructure",
	})
	if err != nil {
		return fmt.Errorf("failed to create decoder: %v", err)
	}

	if err := decoder.Decode(nestedData); err != nil {
		return fmt.Errorf("failed to decode configuration: %v", err)
	}

	return nil
}

// IsSet checks if a key is set in the configuration.
func (cm *configManagerImpl) IsSet(key string) bool {
	normalizedKey := normalizeKey(key)

	// Check in settings first (highest priority)
	if _, exists := cm.settings[normalizedKey]; exists {
		return true
	}

	// Check in defaults (lowest priority)
	if _, exists := cm.defaults[normalizedKey]; exists {
		return true
	}

	return false
}

// RegisterDefaults registers default configuration values.
func (cm *configManagerImpl) RegisterDefaults(defaults map[string]interface{}) {
	if cm.defaults == nil {
		cm.defaults = make(map[string]interface{})
	}
	for key, value := range defaults {
		cm.defaults[key] = value
	}
}

// LoadConfigFile loads configuration from a file.
func (cm *configManagerImpl) LoadConfigFile(filePath string, fileType string) error {
	// Auto-detect file type if not provided
	if fileType == "" {
		fileType = detectFileType(filePath)
		if fileType == "" {
			return fmt.Errorf("%w: cannot detect file type for %s", ErrInvalidFormat, filePath)
		}
	}

	var config map[string]interface{}
	var err error
	switch strings.ToLower(fileType) {
	case "json":
		config, err = loadFromJSON(filePath)
	case "yaml", "yml":
		config, err = loadFromYAML(filePath)
	case "toml":
		config, err = loadFromTOML(filePath)
	default:
		return fmt.Errorf("%w: unsupported file type %s", ErrInvalidFormat, fileType)
	}

	if err != nil {
		return err
	}

	// Merge loaded config into settings
	if cm.settings == nil {
		cm.settings = make(map[string]interface{})
	}

	for key, value := range config {
		normalizedKey := normalizeKey(key)
		cm.settings[normalizedKey] = value
	}

	return nil
}

// LoadFromEnv loads configuration from environment variables.
func (cm *configManagerImpl) LoadFromEnv(prefix string) {
	envConfig := loadFromEnv(prefix)

	// Merge env config into settings (env has higher priority than files and defaults)
	if cm.settings == nil {
		cm.settings = make(map[string]interface{})
	}

	for key, value := range envConfig {
		normalizedKey := normalizeKey(key)
		cm.settings[normalizedKey] = value
	}
}

// Validate validates that all required configuration keys are present.
func (cm *configManagerImpl) Validate() error {
	var missingKeys []string

	for _, key := range cm.requiredKeys {
		if !cm.IsSet(key) {
			missingKeys = append(missingKeys, key)
		}
	}

	if len(missingKeys) > 0 {
		return fmt.Errorf("missing required configuration keys: %v", missingKeys)
	}

	return nil
}

// SetRequiredKeys sets the list of required configuration keys for validation.
func (cm *configManagerImpl) SetRequiredKeys(keys []string) {
	cm.requiredKeys = make([]string, len(keys))
	copy(cm.requiredKeys, keys)
}

// normalizeKey normalizes configuration keys to lowercase for consistent access
func normalizeKey(key string) string {
	return strings.ToLower(key)
}

// getValue retrieves a value from configuration with priority order: settings > defaults
func (cm *configManagerImpl) getValue(key string) (interface{}, error) {
	normalizedKey := normalizeKey(key)

	// Check settings first (highest priority)
	if value, exists := cm.settings[normalizedKey]; exists {
		return value, nil
	}

	// Check defaults (lowest priority)
	if value, exists := cm.defaults[normalizedKey]; exists {
		return value, nil
	}

	return nil, fmt.Errorf("%w: %s", ErrKeyNotFound, key)
}

// unflattenMap converts flattened dot-notation keys back to nested structure
func unflattenMap(flat map[string]interface{}, keyPrefix string) interface{} {
	if len(flat) == 1 {
		for key, value := range flat {
			if key == keyPrefix {
				return value
			}
		}
	}

	result := make(map[string]interface{})
	prefix := keyPrefix + "."

	for key, value := range flat {
		if key == keyPrefix {
			return value
		}

		if strings.HasPrefix(key, prefix) {
			// Remove prefix to get the relative key
			relativeKey := strings.TrimPrefix(key, prefix)

			// Split by first dot to separate immediate key from nested keys
			parts := strings.SplitN(relativeKey, ".", 2)
			immediateKey := parts[0]

			if len(parts) == 1 {
				// No more nesting, direct assignment
				result[immediateKey] = value
			} else {
				// More nesting, recursively handle
				if result[immediateKey] == nil {
					result[immediateKey] = make(map[string]interface{})
				}

				// Create a sub-map for this level
				subMap := make(map[string]interface{})
				subKey := prefix + immediateKey
				subMap[subKey+"."+parts[1]] = value

				result[immediateKey] = unflattenMap(subMap, subKey)
			}
		}
	}

	if len(result) == 0 {
		// Return the direct value if no nested structure found
		return flat[keyPrefix]
	}

	return result
}

// Get returns the raw value for a key
func (cm *configManagerImpl) Get(key string) interface{} {
	value, _ := cm.getValue(key)
	return value
}

// Set sets a configuration value
func (cm *configManagerImpl) Set(key string, value interface{}) {
	normalizedKey := normalizeKey(key)
	cm.settings[normalizedKey] = value
}

// SetDefault sets a default value for a key
func (cm *configManagerImpl) SetDefault(key string, value interface{}) {
	normalizedKey := normalizeKey(key)
	cm.defaults[normalizedKey] = value
}

// GetAll returns all configuration values (settings merged with defaults)
func (cm *configManagerImpl) GetAll() map[string]interface{} {
	result := make(map[string]interface{})

	// First copy defaults
	for k, v := range cm.defaults {
		result[k] = v
	}

	// Then overlay settings (higher priority)
	for k, v := range cm.settings {
		result[k] = v
	}

	return result
}

// SaveToFile saves configuration to a file
func (cm *configManagerImpl) SaveToFile(filePath string, fileType string, config map[string]interface{}) error {
	return saveToFile(filePath, fileType, config)
}

// ensureDirectoryExists creates directory if it doesn't exist
func (cm *configManagerImpl) ensureDirectoryExists(dirPath string) error {
	return ensureDirectoryExists(dirPath)
}
