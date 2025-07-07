package configmanager

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/mitchellh/mapstructure"
	"go.uber.org/zap"
)

// Config Manager specific errors
var (
	ErrKeyNotFound   = errors.New("configuration key not found")
	ErrConfigParse   = errors.New("failed to parse configuration")
	ErrInvalidType   = errors.New("invalid type conversion")
	ErrInvalidFormat = errors.New("invalid configuration format")
)

// ErrorManager interface pour découpler la dépendance
type ErrorManager interface {
	ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error
	CatalogError(entry ErrorEntry) error
	ValidateErrorEntry(entry ErrorEntry) error
}

// ErrorEntry représente une erreur cataloguée
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

// ErrorHooks définit les callbacks d'erreur
type ErrorHooks struct {
	OnError func(error)
}

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
	Cleanup() error
	GetErrorManager() ErrorManager
	GetLogger() *zap.Logger
}

// configManagerImpl is the concrete implementation of ConfigManager.
type configManagerImpl struct {
	// Internal storage for configuration values
	// This will likely be a map[string]interface{} or a more sophisticated structure
	// to handle priorities and different sources.
	settings     map[string]interface{}
	defaults     map[string]interface{}
	requiredKeys []string

	// ErrorManager integration
	logger       *zap.Logger
	errorManager *ErrorManagerImpl
}

// ErrorManagerImpl implémente l'interface ErrorManager localement
type ErrorManagerImpl struct {
	logger *zap.Logger
}

// ProcessError traite une erreur avec le système de gestion centralisé
func (em *ErrorManagerImpl) ProcessError(ctx context.Context, err error, component, operation string, hooks *ErrorHooks) error {
	if err == nil {
		return nil
	}

	// Generate unique error ID
	errorID := uuid.New().String()

	// Determine error severity
	severity := determineSeverity(err)

	// Create error entry for cataloging
	errorEntry := ErrorEntry{
		ID:             errorID,
		Timestamp:      time.Now(),
		Message:        err.Error(),
		StackTrace:     fmt.Sprintf("%+v", err),
		Module:         "config-manager",
		ErrorCode:      generateErrorCode(component, operation),
		ManagerContext: fmt.Sprintf("component=%s, operation=%s", component, operation),
		Severity:       severity,
	}

	// Validate error entry
	if validationErr := em.ValidateErrorEntry(errorEntry); validationErr != nil {
		em.logger.Error("Error entry validation failed",
			zap.Error(validationErr),
			zap.String("error_id", errorID))
		return validationErr
	}

	// Catalog the error
	if catalogErr := em.CatalogError(errorEntry); catalogErr != nil {
		em.logger.Error("Failed to catalog error",
			zap.Error(catalogErr),
			zap.String("error_id", errorID))
	}

	// Execute error hooks if provided
	if hooks != nil && hooks.OnError != nil {
		hooks.OnError(err)
	}

	// Log structured error information
	em.logger.Error("Config Manager error processed",
		zap.String("error_id", errorID),
		zap.String("component", component),
		zap.String("operation", operation),
		zap.String("severity", severity),
		zap.Error(err))

	return err
}

// CatalogError catalog une erreur avec les détails structurés
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

// ValidateErrorEntry valide une entrée d'erreur
func (em *ErrorManagerImpl) ValidateErrorEntry(entry ErrorEntry) error {
	if entry.ID == "" {
		return errors.New("ID cannot be empty")
	}
	if entry.Timestamp.IsZero() {
		return errors.New("Timestamp cannot be zero")
	}
	if entry.Message == "" {
		return errors.New("Message cannot be empty")
	}
	if entry.Module == "" {
		return errors.New("Module cannot be empty")
	}
	if entry.ErrorCode == "" {
		return errors.New("ErrorCode cannot be empty")
	}
	if !isValidSeverity(entry.Severity) {
		return errors.New("Invalid severity level")
	}
	return nil
}

// Helper functions
func isValidSeverity(severity string) bool {
	validSeverities := []string{"low", "medium", "high", "critical"}
	for _, s := range validSeverities {
		if severity == s {
			return true
		}
	}
	return false
}

func determineSeverity(err error) string {
	errorMsg := strings.ToLower(err.Error())
	if strings.Contains(errorMsg, "critical") || strings.Contains(errorMsg, "fatal") {
		return "critical"
	}
	if strings.Contains(errorMsg, "timeout") || strings.Contains(errorMsg, "connection") {
		return "high"
	}
	if strings.Contains(errorMsg, "not found") || strings.Contains(errorMsg, "invalid") {
		return "medium"
	}
	return "low"
}

func generateErrorCode(component, operation string) string {
	compCode := strings.ToUpper(strings.ReplaceAll(component, "-", "_"))
	opCode := strings.ToUpper(strings.ReplaceAll(operation, "-", "_"))
	return fmt.Sprintf("CFG_%s_%s_001", compCode, opCode)
}

// New creates a new instance of ConfigManager with ErrorManager integration.
func New() (ConfigManager, error) {
	// Initialize logger
	logger, err := zap.NewProduction()
	if err != nil {
		return nil, fmt.Errorf("failed to initialize logger: %w", err)
	}

	// Initialize ErrorManager
	errorManager := &ErrorManagerImpl{
		logger: logger,
	}

	return &configManagerImpl{
		settings:     make(map[string]interface{}),
		defaults:     make(map[string]interface{}),
		requiredKeys: make([]string, 0),
		logger:       logger,
		errorManager: errorManager,
	}, nil
}

// GetString retrieves a string value from the configuration with error handling.
func (cm *configManagerImpl) GetString(key string) (string, error) {
	ctx := context.Background()
	value, err := cm.getValue(key)
	if err != nil {
		// Process error with ErrorManager
		if processErr := cm.errorManager.ProcessError(ctx, err, "config-access", "get-string", &ErrorHooks{
			OnError: func(e error) {
				cm.logger.Warn("GetString failed", zap.String("key", key), zap.Error(e))
			},
		}); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
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

// GetInt retrieves an integer value from the configuration with error handling.
func (cm *configManagerImpl) GetInt(key string) (int, error) {
	ctx := context.Background()
	value, err := cm.getValue(key)
	if err != nil {
		// Process error with ErrorManager
		if processErr := cm.errorManager.ProcessError(ctx, err, "config-access", "get-int", &ErrorHooks{
			OnError: func(e error) {
				cm.logger.Warn("GetInt failed", zap.String("key", key), zap.Error(e))
			},
		}); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
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
			conversionErr := fmt.Errorf("%w: cannot convert %q to int: %v", ErrInvalidType, v, parseErr)
			// Process conversion error
			if processErr := cm.errorManager.ProcessError(ctx, conversionErr, "config-conversion", "string-to-int", nil); processErr != nil {
				cm.logger.Error("Error processing failed", zap.Error(processErr))
			}
			return 0, conversionErr
		}
		return parsed, nil
	default:
		typeErr := fmt.Errorf("%w: cannot convert %T to int", ErrInvalidType, v)
		// Process type error
		if processErr := cm.errorManager.ProcessError(ctx, typeErr, "config-conversion", "type-to-int", nil); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
		return 0, typeErr
	}
}

// GetBool retrieves a boolean value from the configuration with error handling.
func (cm *configManagerImpl) GetBool(key string) (bool, error) {
	ctx := context.Background()
	value, err := cm.getValue(key)
	if err != nil {
		// Process error with ErrorManager
		if processErr := cm.errorManager.ProcessError(ctx, err, "config-access", "get-bool", &ErrorHooks{
			OnError: func(e error) {
				cm.logger.Warn("GetBool failed", zap.String("key", key), zap.Error(e))
			},
		}); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
		return false, err
	}

	switch v := value.(type) {
	case bool:
		return v, nil
	case string:
		parsed, parseErr := strconv.ParseBool(v)
		if parseErr != nil {
			conversionErr := fmt.Errorf("%w: cannot convert %q to bool: %v", ErrInvalidType, v, parseErr)
			// Process conversion error
			if processErr := cm.errorManager.ProcessError(ctx, conversionErr, "config-conversion", "string-to-bool", nil); processErr != nil {
				cm.logger.Error("Error processing failed", zap.Error(processErr))
			}
			return false, conversionErr
		}
		return parsed, nil
	case int:
		return v != 0, nil
	case float64:
		return v != 0, nil
	default:
		typeErr := fmt.Errorf("%w: cannot convert %T to bool", ErrInvalidType, v)
		// Process type error
		if processErr := cm.errorManager.ProcessError(ctx, typeErr, "config-conversion", "type-to-bool", nil); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
		return false, typeErr
	}
}

// UnmarshalKey unmarshals a configuration section into a struct with error handling.
func (cm *configManagerImpl) UnmarshalKey(key string, targetStruct interface{}) error {
	ctx := context.Background()
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
		notFoundErr := fmt.Errorf("%w: %s", ErrKeyNotFound, key)
		// Process not found error
		if processErr := cm.errorManager.ProcessError(ctx, notFoundErr, "config-unmarshal", "key-not-found", nil); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
		return notFoundErr
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
		decoderErr := fmt.Errorf("failed to create decoder: %v", err)
		// Process decoder creation error
		if processErr := cm.errorManager.ProcessError(ctx, decoderErr, "config-unmarshal", "decoder-creation", nil); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
		return decoderErr
	}

	if err := decoder.Decode(nestedData); err != nil {
		decodeErr := fmt.Errorf("failed to decode configuration: %v", err)
		// Process decoding error
		if processErr := cm.errorManager.ProcessError(ctx, decodeErr, "config-unmarshal", "decoding", &ErrorHooks{
			OnError: func(e error) {
				cm.logger.Warn("UnmarshalKey decoding failed", zap.String("key", key), zap.Error(e))
			},
		}); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
		return decodeErr
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

// LoadConfigFile loads configuration from a file with error handling.
func (cm *configManagerImpl) LoadConfigFile(filePath string, fileType string) error {
	ctx := context.Background()

	// Auto-detect file type if not provided
	if fileType == "" {
		fileType = detectFileType(filePath)
		if fileType == "" {
			formatErr := fmt.Errorf("%w: cannot detect file type for %s", ErrInvalidFormat, filePath)
			// Process format detection error
			if processErr := cm.errorManager.ProcessError(ctx, formatErr, "config-loading", "file-type-detection", &ErrorHooks{
				OnError: func(e error) {
					cm.logger.Warn("File type detection failed", zap.String("file_path", filePath), zap.Error(e))
				},
			}); processErr != nil {
				cm.logger.Error("Error processing failed", zap.Error(processErr))
			}
			return formatErr
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
		unsupportedErr := fmt.Errorf("%w: unsupported file type %s", ErrInvalidFormat, fileType)
		// Process unsupported file type error
		if processErr := cm.errorManager.ProcessError(ctx, unsupportedErr, "config-loading", "unsupported-file-type", nil); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
		return unsupportedErr
	}

	if err != nil {
		// Process config loading error
		if processErr := cm.errorManager.ProcessError(ctx, err, "config-loading", "file-parsing", &ErrorHooks{
			OnError: func(e error) {
				cm.logger.Warn("Config file parsing failed",
					zap.String("file_path", filePath),
					zap.String("file_type", fileType),
					zap.Error(e))
			},
		}); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
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

	// Log successful loading
	cm.logger.Info("Configuration file loaded successfully",
		zap.String("file_path", filePath),
		zap.String("file_type", fileType),
		zap.Int("keys_loaded", len(config)))

	return nil
}

// LoadFromEnv loads configuration from environment variables with error handling.
func (cm *configManagerImpl) LoadFromEnv(prefix string) {
	envConfig := loadFromEnv(prefix)

	// Merge env config into settings (env has higher priority than files and defaults)
	if cm.settings == nil {
		cm.settings = make(map[string]interface{})
	}

	keysLoaded := 0
	for key, value := range envConfig {
		normalizedKey := normalizeKey(key)
		cm.settings[normalizedKey] = value
		keysLoaded++
	}

	// Log environment variables loading
	cm.logger.Info("Environment variables loaded",
		zap.String("prefix", prefix),
		zap.Int("keys_loaded", keysLoaded))
}

// Validate validates that all required configuration keys are present with error handling.
func (cm *configManagerImpl) Validate() error {
	ctx := context.Background()
	var missingKeys []string

	for _, key := range cm.requiredKeys {
		if !cm.IsSet(key) {
			missingKeys = append(missingKeys, key)
		}
	}

	if len(missingKeys) > 0 {
		validationErr := fmt.Errorf("missing required configuration keys: %v", missingKeys)
		// Process validation error
		if processErr := cm.errorManager.ProcessError(ctx, validationErr, "config-validation", "missing-required-keys", &ErrorHooks{
			OnError: func(e error) {
				cm.logger.Warn("Configuration validation failed",
					zap.Strings("missing_keys", missingKeys),
					zap.Error(e))
			},
		}); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
		return validationErr
	}

	// Log successful validation
	cm.logger.Info("Configuration validation successful",
		zap.Strings("required_keys", cm.requiredKeys))

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

// SaveToFile saves configuration to a file with error handling
func (cm *configManagerImpl) SaveToFile(filePath string, fileType string, config map[string]interface{}) error {
	ctx := context.Background()

	if err := saveToFile(filePath, fileType, config); err != nil {
		// Process save error
		if processErr := cm.errorManager.ProcessError(ctx, err, "config-saving", "file-write", &ErrorHooks{
			OnError: func(e error) {
				cm.logger.Warn("Config file save failed",
					zap.String("file_path", filePath),
					zap.String("file_type", fileType),
					zap.Error(e))
			},
		}); processErr != nil {
			cm.logger.Error("Error processing failed", zap.Error(processErr))
		}
		return err
	}

	// Log successful save
	cm.logger.Info("Configuration file saved successfully",
		zap.String("file_path", filePath),
		zap.String("file_type", fileType),
		zap.Int("keys_saved", len(config)))

	return nil
}

// ensureDirectoryExists creates directory if it doesn't exist
func (cm *configManagerImpl) ensureDirectoryExists(dirPath string) error {
	return ensureDirectoryExists(dirPath)
}

// Cleanup performs cleanup operations for the config manager
func (cm *configManagerImpl) Cleanup() error {
	if cm.logger != nil {
		if err := cm.logger.Sync(); err != nil {
			return fmt.Errorf("failed to sync logger: %w", err)
		}
	}
	return nil
}

// GetErrorManager returns the ErrorManager instance for external use
func (cm *configManagerImpl) GetErrorManager() ErrorManager {
	return cm.errorManager
}

// GetLogger returns the logger instance for external use
func (cm *configManagerImpl) GetLogger() *zap.Logger {
	return cm.logger
}
