package converters

import (
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"go.uber.org/zap"
)

// N8NItem represents an N8N workflow item
type N8NItem struct {
	JSON   map[string]interface{} `json:"json"`
	Binary map[string]interface{} `json:"binary,omitempty"`
}

// N8NData represents N8N workflow execution data
type N8NData []N8NItem

// GoStruct represents a generic Go struct for data conversion
type GoStruct struct {
	Fields map[string]interface{} `json:"fields"`
	Type   string                 `json:"type"`
}

// ConversionResult represents the result of N8N to Go conversion
type ConversionResult struct {
	Data     []GoStruct `json:"data"`
	Errors   []string   `json:"errors,omitempty"`
	Warnings []string   `json:"warnings,omitempty"`
	Metadata Metadata   `json:"metadata"`
}

// Metadata contains conversion metadata
type Metadata struct {
	ItemCount       int               `json:"item_count"`
	ConversionTime  time.Duration     `json:"conversion_time"`
	TypeMapping     map[string]string `json:"type_mapping"`
	SkippedFields   []string          `json:"skipped_fields,omitempty"`
	ConvertedFields int               `json:"converted_fields"`
}

// N8NToGoConverter handles conversion from N8N format to Go structs
type N8NToGoConverter struct {
	logger            *zap.Logger
	typeMapping       map[string]string
	nullHandling      NullHandlingStrategy
	validationEnabled bool
}

// NullHandlingStrategy defines how to handle null values
type NullHandlingStrategy string

const (
	NullHandlingSkip    NullHandlingStrategy = "skip"
	NullHandlingDefault NullHandlingStrategy = "default"
	NullHandlingError   NullHandlingStrategy = "error"
)

// ConversionOptions provides options for conversion
type ConversionOptions struct {
	NullHandling      NullHandlingStrategy `json:"null_handling"`
	TypeValidation    bool                 `json:"type_validation"`
	SkipBinaryData    bool                 `json:"skip_binary_data"`
	MaxFieldDepth     int                  `json:"max_field_depth"`
	CustomTypeMapping map[string]string    `json:"custom_type_mapping"`
}

// NewN8NToGoConverter creates a new converter instance
func NewN8NToGoConverter(logger *zap.Logger, options ConversionOptions) *N8NToGoConverter {
	converter := &N8NToGoConverter{
		logger:            logger,
		typeMapping:       getDefaultTypeMapping(),
		nullHandling:      options.NullHandling,
		validationEnabled: options.TypeValidation,
	}

	// Apply custom type mappings
	if options.CustomTypeMapping != nil {
		for k, v := range options.CustomTypeMapping {
			converter.typeMapping[k] = v
		}
	}

	if converter.nullHandling == "" {
		converter.nullHandling = NullHandlingDefault
	}

	return converter
}

// Convert converts N8N data format to Go structs
func (c *N8NToGoConverter) Convert(n8nData N8NData) (*ConversionResult, error) {
	startTime := time.Now()

	result := &ConversionResult{
		Data:     make([]GoStruct, 0, len(n8nData)),
		Errors:   make([]string, 0),
		Warnings: make([]string, 0),
		Metadata: Metadata{
			ItemCount:       len(n8nData),
			TypeMapping:     c.typeMapping,
			SkippedFields:   make([]string, 0),
			ConvertedFields: 0,
		},
	}

	for i, item := range n8nData {
		goStruct, err := c.convertItem(item, i)
		if err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Item %d: %v", i, err))
			c.logger.Error("Failed to convert N8N item",
				zap.Int("index", i),
				zap.Error(err))
			continue
		}

		result.Data = append(result.Data, *goStruct)
		result.Metadata.ConvertedFields += len(goStruct.Fields)
	}

	result.Metadata.ConversionTime = time.Since(startTime)

	c.logger.Info("N8N to Go conversion completed",
		zap.Int("items_processed", len(n8nData)),
		zap.Int("items_converted", len(result.Data)),
		zap.Int("errors", len(result.Errors)),
		zap.Duration("duration", result.Metadata.ConversionTime))

	return result, nil
}

// convertItem converts a single N8N item to Go struct
func (c *N8NToGoConverter) convertItem(item N8NItem, index int) (*GoStruct, error) {
	goStruct := &GoStruct{
		Fields: make(map[string]interface{}),
		Type:   "object",
	}

	// Convert JSON fields
	if item.JSON != nil {
		for key, value := range item.JSON {
			convertedValue, err := c.convertValue(value, key, 0)
			if err != nil {
				if c.nullHandling == NullHandlingError {
					return nil, fmt.Errorf("failed to convert field '%s': %w", key, err)
				}
				c.logger.Warn("Skipping field due to conversion error",
					zap.String("field", key),
					zap.Error(err))
				continue
			}

			if convertedValue != nil {
				goStruct.Fields[key] = convertedValue
			}
		}
	}

	// Handle binary data if present and not skipped
	if item.Binary != nil && len(item.Binary) > 0 {
		binaryFields := make(map[string]interface{})
		for key, value := range item.Binary {
			// Convert binary metadata only, not the actual binary data
			if metadata, ok := value.(map[string]interface{}); ok {
				binaryFields[key] = c.convertBinaryMetadata(metadata)
			}
		}
		if len(binaryFields) > 0 {
			goStruct.Fields["_binary"] = binaryFields
		}
	}

	return goStruct, nil
}

// convertValue converts a single value with type inference
func (c *N8NToGoConverter) convertValue(value interface{}, fieldName string, depth int) (interface{}, error) {
	if value == nil {
		return c.handleNullValue(fieldName)
	}

	// Prevent infinite recursion
	if depth > 10 {
		return nil, fmt.Errorf("maximum field depth exceeded for field '%s'", fieldName)
	}

	switch v := value.(type) {
	case string:
		return c.convertString(v)
	case int, int32, int64:
		return c.convertInteger(v)
	case float32, float64:
		return c.convertFloat(v)
	case bool:
		return v, nil
	case []interface{}:
		return c.convertArray(v, fieldName, depth+1)
	case map[string]interface{}:
		return c.convertObject(v, fieldName, depth+1)
	case json.Number:
		return c.convertJSONNumber(v)
	default:
		// Try to convert unknown types to string
		return fmt.Sprintf("%v", v), nil
	}
}

// convertString handles string conversion with special cases
func (c *N8NToGoConverter) convertString(s string) (interface{}, error) {
	// Try to detect if string contains a number
	if num, err := strconv.ParseFloat(s, 64); err == nil {
		if num == float64(int64(num)) {
			return int64(num), nil
		}
		return num, nil
	}

	// Try to detect if string contains a boolean
	if b, err := strconv.ParseBool(s); err == nil {
		return b, nil
	}

	// Try to detect if string contains a date/time
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t, nil
	}
	if t, err := time.Parse("2006-01-02", s); err == nil {
		return t, nil
	}

	return s, nil
}

// convertInteger handles integer conversion
func (c *N8NToGoConverter) convertInteger(i interface{}) (interface{}, error) {
	switch v := i.(type) {
	case int:
		return int64(v), nil
	case int32:
		return int64(v), nil
	case int64:
		return v, nil
	default:
		return nil, fmt.Errorf("unsupported integer type: %T", i)
	}
}

// convertFloat handles float conversion
func (c *N8NToGoConverter) convertFloat(f interface{}) (interface{}, error) {
	switch v := f.(type) {
	case float32:
		return float64(v), nil
	case float64:
		return v, nil
	default:
		return nil, fmt.Errorf("unsupported float type: %T", f)
	}
}

// convertArray handles array conversion
func (c *N8NToGoConverter) convertArray(arr []interface{}, fieldName string, depth int) ([]interface{}, error) {
	result := make([]interface{}, 0, len(arr))

	for i, item := range arr {
		convertedItem, err := c.convertValue(item, fmt.Sprintf("%s[%d]", fieldName, i), depth)
		if err != nil {
			if c.nullHandling == NullHandlingError {
				return nil, err
			}
			c.logger.Warn("Skipping array item due to conversion error",
				zap.String("field", fieldName),
				zap.Int("index", i),
				zap.Error(err))
			continue
		}

		if convertedItem != nil {
			result = append(result, convertedItem)
		}
	}

	return result, nil
}

// convertObject handles object conversion
func (c *N8NToGoConverter) convertObject(obj map[string]interface{}, fieldName string, depth int) (map[string]interface{}, error) {
	result := make(map[string]interface{})

	for key, value := range obj {
		convertedValue, err := c.convertValue(value, fmt.Sprintf("%s.%s", fieldName, key), depth)
		if err != nil {
			if c.nullHandling == NullHandlingError {
				return nil, err
			}
			c.logger.Warn("Skipping object field due to conversion error",
				zap.String("field", fmt.Sprintf("%s.%s", fieldName, key)),
				zap.Error(err))
			continue
		}

		if convertedValue != nil {
			result[key] = convertedValue
		}
	}

	return result, nil
}

// convertJSONNumber handles json.Number conversion
func (c *N8NToGoConverter) convertJSONNumber(num json.Number) (interface{}, error) {
	// Try integer first
	if i, err := num.Int64(); err == nil {
		return i, nil
	}

	// Fall back to float
	if f, err := num.Float64(); err == nil {
		return f, nil
	}

	return nil, fmt.Errorf("invalid JSON number: %s", string(num))
}

// convertBinaryMetadata converts binary field metadata
func (c *N8NToGoConverter) convertBinaryMetadata(metadata map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})

	// Extract common binary metadata fields
	if fileName, ok := metadata["fileName"]; ok {
		result["file_name"] = fileName
	}
	if mimeType, ok := metadata["mimeType"]; ok {
		result["mime_type"] = mimeType
	}
	if fileSize, ok := metadata["fileSize"]; ok {
		result["file_size"] = fileSize
	}
	if data, ok := metadata["data"]; ok && data != nil {
		// For binary data, we just indicate its presence
		result["has_data"] = true
		if dataStr, ok := data.(string); ok {
			result["data_length"] = len(dataStr)
		}
	}

	return result
}

// handleNullValue handles null values according to strategy
func (c *N8NToGoConverter) handleNullValue(fieldName string) (interface{}, error) {
	switch c.nullHandling {
	case NullHandlingSkip:
		return nil, nil
	case NullHandlingDefault:
		return "", nil // Return empty string as default
	case NullHandlingError:
		return nil, fmt.Errorf("null value not allowed for field '%s'", fieldName)
	default:
		return nil, nil
	}
}

// getDefaultTypeMapping returns default type mappings
func getDefaultTypeMapping() map[string]string {
	return map[string]string{
		"string":  "string",
		"number":  "float64",
		"integer": "int64",
		"boolean": "bool",
		"array":   "[]interface{}",
		"object":  "map[string]interface{}",
		"null":    "interface{}",
	}
}

// ValidateConversion validates the conversion result
func (c *N8NToGoConverter) ValidateConversion(result *ConversionResult) error {
	if !c.validationEnabled {
		return nil
	}

	if result == nil {
		return fmt.Errorf("conversion result is nil")
	}

	if len(result.Errors) > 0 {
		return fmt.Errorf("conversion completed with %d errors", len(result.Errors))
	}

	// Validate that we converted something
	if result.Metadata.ItemCount > 0 && len(result.Data) == 0 {
		return fmt.Errorf("no items were converted from %d input items", result.Metadata.ItemCount)
	}

	return nil
}

// GetStatistics returns conversion statistics
func (c *N8NToGoConverter) GetStatistics(result *ConversionResult) map[string]interface{} {
	if result == nil {
		return nil
	}

	successRate := 0.0
	if result.Metadata.ItemCount > 0 {
		successRate = float64(len(result.Data)) / float64(result.Metadata.ItemCount) * 100
	}

	return map[string]interface{}{
		"input_items":      result.Metadata.ItemCount,
		"converted_items":  len(result.Data),
		"success_rate":     successRate,
		"conversion_time":  result.Metadata.ConversionTime.String(),
		"errors":           len(result.Errors),
		"warnings":         len(result.Warnings),
		"converted_fields": result.Metadata.ConvertedFields,
		"skipped_fields":   len(result.Metadata.SkippedFields),
	}
}

// ConvertWithValidation converts and validates in one step
func (c *N8NToGoConverter) ConvertWithValidation(n8nData N8NData) (*ConversionResult, error) {
	result, err := c.Convert(n8nData)
	if err != nil {
		return nil, fmt.Errorf("conversion failed: %w", err)
	}

	if err := c.ValidateConversion(result); err != nil {
		return result, fmt.Errorf("validation failed: %w", err)
	}

	return result, nil
}
