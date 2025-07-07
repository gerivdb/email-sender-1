package configmanager

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/BurntSushi/toml"
	"gopkg.in/yaml.v3"
)

// loadFromEnv loads configuration from environment variables
func loadFromEnv(prefix string) map[string]interface{} {
	config := make(map[string]interface{})

	for _, env := range os.Environ() {
		parts := strings.SplitN(env, "=", 2)
		if len(parts) != 2 {
			continue
		}

		key, value := parts[0], parts[1]

		// Check if the environment variable starts with the prefix
		if prefix != "" && !strings.HasPrefix(key, prefix) {
			continue
		}

		// Remove prefix and convert to config key
		configKey := key
		if prefix != "" {
			configKey = strings.TrimPrefix(key, prefix)
		}

		// Convert environment variable name to config key format
		// E.g., "DATABASE_HOST" -> "database.host"
		configKey = strings.ToLower(configKey)
		configKey = strings.ReplaceAll(configKey, "_", ".")

		if configKey != "" {
			config[configKey] = value
		}
	}

	return config
}

// loadFromJSON loads configuration from a JSON file
func loadFromJSON(filePath string) (map[string]interface{}, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("%w: failed to read JSON file %s: %v", ErrConfigParse, filePath, err)
	}

	var config map[string]interface{}
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("%w: failed to parse JSON file %s: %v", ErrConfigParse, filePath, err)
	}
	return flattenMap(config, ""), nil
}

// loadFromYAML loads configuration from a YAML file
func loadFromYAML(filePath string) (map[string]interface{}, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("%w: failed to read YAML file %s: %v", ErrConfigParse, filePath, err)
	}

	var config map[string]interface{}
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("%w: failed to parse YAML file %s: %v", ErrConfigParse, filePath, err)
	}

	return flattenMap(config, ""), nil
}

// loadFromTOML loads configuration from a TOML file
func loadFromTOML(filePath string) (map[string]interface{}, error) {
	var config map[string]interface{}

	if _, err := toml.DecodeFile(filePath, &config); err != nil {
		return nil, fmt.Errorf("%w: failed to parse TOML file %s: %v", ErrConfigParse, filePath, err)
	}

	return flattenMap(config, ""), nil
}

// flattenMap flattens nested maps into dot-notation keys
func flattenMap(m map[string]interface{}, prefix string) map[string]interface{} {
	result := make(map[string]interface{})

	for key, value := range m {
		fullKey := key
		if prefix != "" {
			fullKey = prefix + "." + key
		}

		switch v := value.(type) {
		case map[string]interface{}:
			// Recursively flatten nested maps
			nested := flattenMap(v, fullKey)
			for nestedKey, nestedValue := range nested {
				result[nestedKey] = nestedValue
			}
		default:
			result[fullKey] = value
		}
	}

	return result
}

// detectFileType detects file type from extension
func detectFileType(filePath string) string {
	ext := strings.ToLower(filepath.Ext(filePath))
	switch ext {
	case ".json":
		return "json"
	case ".yaml", ".yml":
		return "yaml"
	case ".toml":
		return "toml"
	default:
		return ""
	}
}

// saveToFile saves configuration data to a file in the specified format
func saveToFile(filePath string, fileType string, config map[string]interface{}) error {
	var data []byte
	var err error

	switch strings.ToLower(fileType) {
	case "json":
		data, err = json.MarshalIndent(config, "", "  ")
	case "yaml", "yml":
		data, err = yaml.Marshal(config)
	case "toml":
		var buf strings.Builder
		err = toml.NewEncoder(&buf).Encode(config)
		if err == nil {
			data = []byte(buf.String())
		}
	default:
		return fmt.Errorf("unsupported file type: %s", fileType)
	}

	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	return os.WriteFile(filePath, data, 0644)
}

// ensureDirectoryExists creates a directory if it doesn't exist
func ensureDirectoryExists(dirPath string) error {
	return os.MkdirAll(dirPath, 0755)
}
