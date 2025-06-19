package mapping

import (
	"encoding/json"
	"fmt"
	"reflect"
	"strconv"
	"strings"
	"time"

	"go.uber.org/zap"
)

// ParameterType represents the type of a parameter
type ParameterType string

const (
	ParameterTypeString     ParameterType = "string"
	ParameterTypeNumber     ParameterType = "number"
	ParameterTypeBoolean    ParameterType = "boolean"
	ParameterTypeFile       ParameterType = "file"
	ParameterTypeCredential ParameterType = "credential"
	ParameterTypeArray      ParameterType = "array"
	ParameterTypeObject     ParameterType = "object"
	ParameterTypeDate       ParameterType = "date"
)

// Parameter represents a parameter definition
type Parameter struct {
	Name        string        `json:"name"`
	Type        ParameterType `json:"type"`
	Value       interface{}   `json:"value"`
	Required    bool          `json:"required"`
	Default     interface{}   `json:"default,omitempty"`
	Description string        `json:"description,omitempty"`
	Validation  *Validation   `json:"validation,omitempty"`
	Security    *Security     `json:"security,omitempty"`
}

// Validation represents parameter validation rules
type Validation struct {
	MinLength     *int          `json:"min_length,omitempty"`
	MaxLength     *int          `json:"max_length,omitempty"`
	MinValue      *float64      `json:"min_value,omitempty"`
	MaxValue      *float64      `json:"max_value,omitempty"`
	Pattern       *string       `json:"pattern,omitempty"`
	AllowedValues []interface{} `json:"allowed_values,omitempty"`
}

// Security represents security settings for parameters
type Security struct {
	Sensitive  bool `json:"sensitive"`
	MaskInLogs bool `json:"mask_in_logs"`
	Encrypted  bool `json:"encrypted"`
}

// N8NNodeParameter represents a parameter from N8N node
type N8NNodeParameter struct {
	Name        string      `json:"name"`
	DisplayName string      `json:"displayName"`
	Type        string      `json:"type"`
	Default     interface{} `json:"default"`
	Required    bool        `json:"required"`
	Options     []Option    `json:"options,omitempty"`
	TypeOptions TypeOptions `json:"typeOptions,omitempty"`
	Description string      `json:"description"`
}

// Option represents a parameter option
type Option struct {
	Name  string      `json:"name"`
	Value interface{} `json:"value"`
}

// TypeOptions represents type-specific options
type TypeOptions struct {
	MinValue       *float64 `json:"minValue,omitempty"`
	MaxValue       *float64 `json:"maxValue,omitempty"`
	MultipleValues bool     `json:"multipleValues,omitempty"`
}

// MappingResult represents the result of parameter mapping
type MappingResult struct {
	Arguments   []string               `json:"arguments"`
	Environment map[string]string      `json:"environment"`
	InputData   map[string]interface{} `json:"input_data,omitempty"`
	Errors      []string               `json:"errors,omitempty"`
	Warnings    []string               `json:"warnings,omitempty"`
}

// ParameterMapper handles parameter mapping from N8N to Go CLI
type ParameterMapper struct {
	logger        *zap.Logger
	sensitiveKeys map[string]bool
	encryptionKey []byte
}

// NewParameterMapper creates a new parameter mapper
func NewParameterMapper(logger *zap.Logger) *ParameterMapper {
	return &ParameterMapper{
		logger:        logger,
		sensitiveKeys: make(map[string]bool),
	}
}

// SetSensitiveKeys sets the list of sensitive parameter keys
func (pm *ParameterMapper) SetSensitiveKeys(keys []string) {
	pm.sensitiveKeys = make(map[string]bool)
	for _, key := range keys {
		pm.sensitiveKeys[strings.ToLower(key)] = true
	}
}

// SetEncryptionKey sets the encryption key for sensitive parameters
func (pm *ParameterMapper) SetEncryptionKey(key []byte) {
	pm.encryptionKey = key
}

// MapN8NParameters maps N8N node parameters to CLI arguments
func (pm *ParameterMapper) MapN8NParameters(n8nParams map[string]interface{}) (*MappingResult, error) {
	result := &MappingResult{
		Arguments:   make([]string, 0),
		Environment: make(map[string]string),
		InputData:   make(map[string]interface{}),
		Errors:      make([]string, 0),
		Warnings:    make([]string, 0),
	}

	for key, value := range n8nParams {
		param := &Parameter{
			Name:  key,
			Value: value,
			Type:  pm.inferParameterType(value),
			Security: &Security{
				Sensitive:  pm.isSensitiveKey(key),
				MaskInLogs: pm.isSensitiveKey(key),
			},
		}

		if err := pm.mapParameter(param, result); err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Error mapping parameter %s: %v", key, err))
			pm.logger.Error("Parameter mapping error",
				zap.String("parameter", key),
				zap.Error(err))
		}
	}

	return result, nil
}

// MapParameters maps a list of parameters to CLI arguments
func (pm *ParameterMapper) MapParameters(parameters []Parameter) (*MappingResult, error) {
	result := &MappingResult{
		Arguments:   make([]string, 0),
		Environment: make(map[string]string),
		InputData:   make(map[string]interface{}),
		Errors:      make([]string, 0),
		Warnings:    make([]string, 0),
	}

	for _, param := range parameters {
		if err := pm.validateParameter(&param); err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Validation error for %s: %v", param.Name, err))
			continue
		}

		if err := pm.mapParameter(&param, result); err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Mapping error for %s: %v", param.Name, err))
		}
	}

	return result, nil
}

// mapParameter maps a single parameter to the result
func (pm *ParameterMapper) mapParameter(param *Parameter, result *MappingResult) error {
	// Handle nil or empty values
	if param.Value == nil {
		if param.Required {
			return fmt.Errorf("required parameter %s is nil", param.Name)
		}
		if param.Default != nil {
			param.Value = param.Default
		} else {
			return nil // Skip optional nil parameters
		}
	}

	// Convert value to string for CLI arguments
	stringValue, err := pm.convertToString(param.Value, param.Type)
	if err != nil {
		return fmt.Errorf("failed to convert value: %w", err)
	}

	// Handle sensitive parameters
	if param.Security != nil && param.Security.Sensitive {
		stringValue = pm.handleSensitiveParameter(param.Name, stringValue, result)
	}

	// Map based on parameter type and destination
	switch param.Type {
	case ParameterTypeCredential:
		// Credentials go to environment variables
		envKey := strings.ToUpper(fmt.Sprintf("%s", param.Name))
		result.Environment[envKey] = stringValue
		result.Warnings = append(result.Warnings, fmt.Sprintf("Credential %s mapped to environment variable %s", param.Name, envKey))

	case ParameterTypeFile:
		// File parameters as arguments
		result.Arguments = append(result.Arguments, fmt.Sprintf("--%s", param.Name), stringValue)

	default:
		// Regular parameters as CLI arguments
		argName := pm.formatArgumentName(param.Name)
		result.Arguments = append(result.Arguments, fmt.Sprintf("--%s", argName), stringValue)

		// Also add to input data for JSON processing
		result.InputData[param.Name] = param.Value
	}

	// Log parameter mapping (with masking for sensitive data)
	logValue := stringValue
	if param.Security != nil && param.Security.MaskInLogs {
		logValue = pm.maskValue(stringValue)
	}

	pm.logger.Debug("Parameter mapped",
		zap.String("name", param.Name),
		zap.String("type", string(param.Type)),
		zap.String("value", logValue))

	return nil
}

// validateParameter validates a parameter against its validation rules
func (pm *ParameterMapper) validateParameter(param *Parameter) error {
	if param.Required && param.Value == nil {
		return fmt.Errorf("required parameter is missing")
	}

	if param.Value == nil {
		return nil // Skip validation for nil optional parameters
	}

	if param.Validation == nil {
		return nil // No validation rules
	}

	validation := param.Validation

	switch param.Type {
	case ParameterTypeString:
		str, ok := param.Value.(string)
		if !ok {
			return fmt.Errorf("expected string value")
		}

		if validation.MinLength != nil && len(str) < *validation.MinLength {
			return fmt.Errorf("string length %d is less than minimum %d", len(str), *validation.MinLength)
		}

		if validation.MaxLength != nil && len(str) > *validation.MaxLength {
			return fmt.Errorf("string length %d exceeds maximum %d", len(str), *validation.MaxLength)
		}

		if validation.Pattern != nil {
			// Pattern validation would require regexp package
			pm.logger.Debug("Pattern validation not implemented", zap.String("pattern", *validation.Pattern))
		}

	case ParameterTypeNumber:
		var num float64
		switch v := param.Value.(type) {
		case int:
			num = float64(v)
		case int64:
			num = float64(v)
		case float64:
			num = v
		case string:
			var err error
			num, err = strconv.ParseFloat(v, 64)
			if err != nil {
				return fmt.Errorf("invalid number format: %v", err)
			}
		default:
			return fmt.Errorf("expected numeric value")
		}

		if validation.MinValue != nil && num < *validation.MinValue {
			return fmt.Errorf("value %f is less than minimum %f", num, *validation.MinValue)
		}

		if validation.MaxValue != nil && num > *validation.MaxValue {
			return fmt.Errorf("value %f exceeds maximum %f", num, *validation.MaxValue)
		}
	}

	// Check allowed values
	if len(validation.AllowedValues) > 0 {
		allowed := false
		for _, allowedValue := range validation.AllowedValues {
			if reflect.DeepEqual(param.Value, allowedValue) {
				allowed = true
				break
			}
		}
		if !allowed {
			return fmt.Errorf("value not in allowed values list")
		}
	}

	return nil
}

// inferParameterType infers the parameter type from its value
func (pm *ParameterMapper) inferParameterType(value interface{}) ParameterType {
	if value == nil {
		return ParameterTypeString
	}

	switch v := value.(type) {
	case bool:
		return ParameterTypeBoolean
	case int, int32, int64, float32, float64:
		return ParameterTypeNumber
	case string:
		// Check if it looks like a file path
		if strings.Contains(v, "/") || strings.Contains(v, "\\") || strings.HasSuffix(v, ".json") || strings.HasSuffix(v, ".yml") {
			return ParameterTypeFile
		}
		// Check if it looks like a credential
		if strings.Contains(strings.ToLower(v), "password") || strings.Contains(strings.ToLower(v), "secret") || strings.Contains(strings.ToLower(v), "token") {
			return ParameterTypeCredential
		}
		return ParameterTypeString
	case []interface{}:
		return ParameterTypeArray
	case map[string]interface{}:
		return ParameterTypeObject
	case time.Time:
		return ParameterTypeDate
	default:
		return ParameterTypeString
	}
}

// convertToString converts a value to its string representation
func (pm *ParameterMapper) convertToString(value interface{}, paramType ParameterType) (string, error) {
	if value == nil {
		return "", nil
	}

	switch paramType {
	case ParameterTypeString, ParameterTypeFile, ParameterTypeCredential:
		if str, ok := value.(string); ok {
			return str, nil
		}
		return fmt.Sprintf("%v", value), nil

	case ParameterTypeNumber:
		switch v := value.(type) {
		case int:
			return strconv.Itoa(v), nil
		case int64:
			return strconv.FormatInt(v, 10), nil
		case float64:
			return strconv.FormatFloat(v, 'f', -1, 64), nil
		case string:
			// Validate it's a valid number
			if _, err := strconv.ParseFloat(v, 64); err != nil {
				return "", fmt.Errorf("invalid number format: %s", v)
			}
			return v, nil
		default:
			return fmt.Sprintf("%v", value), nil
		}

	case ParameterTypeBoolean:
		switch v := value.(type) {
		case bool:
			return strconv.FormatBool(v), nil
		case string:
			if b, err := strconv.ParseBool(v); err == nil {
				return strconv.FormatBool(b), nil
			}
			return v, nil
		default:
			return fmt.Sprintf("%v", value), nil
		}

	case ParameterTypeArray, ParameterTypeObject:
		// Convert to JSON string
		jsonBytes, err := json.Marshal(value)
		if err != nil {
			return "", fmt.Errorf("failed to marshal JSON: %w", err)
		}
		return string(jsonBytes), nil

	case ParameterTypeDate:
		if t, ok := value.(time.Time); ok {
			return t.Format(time.RFC3339), nil
		}
		return fmt.Sprintf("%v", value), nil

	default:
		return fmt.Sprintf("%v", value), nil
	}
}

// isSensitiveKey checks if a parameter key is sensitive
func (pm *ParameterMapper) isSensitiveKey(key string) bool {
	lowerKey := strings.ToLower(key)

	// Check configured sensitive keys
	if pm.sensitiveKeys[lowerKey] {
		return true
	}

	// Check common sensitive patterns
	sensitivePatterns := []string{
		"password", "secret", "token", "key", "credential",
		"auth", "api_key", "access_token", "private",
	}

	for _, pattern := range sensitivePatterns {
		if strings.Contains(lowerKey, pattern) {
			return true
		}
	}

	return false
}

// handleSensitiveParameter handles sensitive parameter processing
func (pm *ParameterMapper) handleSensitiveParameter(name, value string, result *MappingResult) string {
	if len(pm.encryptionKey) > 0 {
		// In a real implementation, encrypt the value
		encrypted := pm.encryptValue(value)
		result.Warnings = append(result.Warnings, fmt.Sprintf("Parameter %s was encrypted", name))
		return encrypted
	} else {
		result.Warnings = append(result.Warnings, fmt.Sprintf("Sensitive parameter %s processed without encryption", name))
		return value
	}
}

// encryptValue encrypts a sensitive value (placeholder implementation)
func (pm *ParameterMapper) encryptValue(value string) string {
	// This is a placeholder. In a real implementation, use proper encryption
	// like AES-GCM with the encryption key
	return fmt.Sprintf("encrypted:%s", value[0:min(len(value), 4)])
}

// maskValue masks a value for logging
func (pm *ParameterMapper) maskValue(value string) string {
	if len(value) <= 4 {
		return "****"
	}
	return value[0:2] + "****" + value[len(value)-2:]
}

// formatArgumentName formats a parameter name for CLI arguments
func (pm *ParameterMapper) formatArgumentName(name string) string {
	// Convert camelCase to kebab-case
	var result strings.Builder
	for i, char := range name {
		if i > 0 && 'A' <= char && char <= 'Z' {
			result.WriteRune('-')
		}
		result.WriteRune(char)
	}
	return strings.ToLower(result.String())
}

// min returns the minimum of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// BuildCommandLine builds a complete command line from mapping result
func (pm *ParameterMapper) BuildCommandLine(binaryPath, command string, result *MappingResult) []string {
	cmdLine := []string{binaryPath, "execute", command}
	cmdLine = append(cmdLine, result.Arguments...)
	return cmdLine
}

// BuildEnvironment builds environment variables map
func (pm *ParameterMapper) BuildEnvironment(result *MappingResult, baseEnv map[string]string) map[string]string {
	env := make(map[string]string)

	// Copy base environment
	for k, v := range baseEnv {
		env[k] = v
	}

	// Add mapped environment variables
	for k, v := range result.Environment {
		env[k] = v
	}

	return env
}
