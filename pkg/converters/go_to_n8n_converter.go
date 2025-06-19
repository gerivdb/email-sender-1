package converters

import (
	"fmt"
	"reflect"
	"strings"
	"time"

	"go.uber.org/zap"
)

// GoToN8NConverter handles conversion from Go structs to N8N format
type GoToN8NConverter struct {
	logger               *zap.Logger
	useOmitEmpty         bool
	customJSONTags       map[string]string
	fieldNameTransformer FieldNameTransformer
	timeFormat           string
}

// FieldNameTransformer defines how to transform field names
type FieldNameTransformer func(string) string

// GoToN8NOptions provides options for Go to N8N conversion
type GoToN8NOptions struct {
	UseOmitEmpty         bool                 `json:"use_omit_empty"`
	CustomJSONTags       map[string]string    `json:"custom_json_tags"`
	FieldNameTransformer FieldNameTransformer `json:"-"`
	TimeFormat           string               `json:"time_format"`
}

// ReverseConversionResult represents the result of Go to N8N conversion
type ReverseConversionResult struct {
	N8NData         N8NData         `json:"n8n_data"`
	Errors          []string        `json:"errors,omitempty"`
	Warnings        []string        `json:"warnings,omitempty"`
	ReverseMetadata ReverseMetadata `json:"metadata"`
}

// ReverseMetadata contains reverse conversion metadata
type ReverseMetadata struct {
	StructCount     int               `json:"struct_count"`
	ConversionTime  time.Duration     `json:"conversion_time"`
	FieldsProcessed int               `json:"fields_processed"`
	SkippedFields   []string          `json:"skipped_fields,omitempty"`
	TypeTransforms  map[string]string `json:"type_transforms"`
}

// NewGoToN8NConverter creates a new Go to N8N converter
func NewGoToN8NConverter(logger *zap.Logger, options GoToN8NOptions) *GoToN8NConverter {
	converter := &GoToN8NConverter{
		logger:               logger,
		useOmitEmpty:         options.UseOmitEmpty,
		customJSONTags:       options.CustomJSONTags,
		fieldNameTransformer: options.FieldNameTransformer,
		timeFormat:           options.TimeFormat,
	}

	if converter.customJSONTags == nil {
		converter.customJSONTags = make(map[string]string)
	}

	if converter.timeFormat == "" {
		converter.timeFormat = time.RFC3339
	}

	if converter.fieldNameTransformer == nil {
		converter.fieldNameTransformer = DefaultFieldNameTransformer
	}

	return converter
}

// Convert converts Go structs to N8N data format
func (c *GoToN8NConverter) Convert(goStructs []GoStruct) (*ReverseConversionResult, error) {
	startTime := time.Now()

	result := &ReverseConversionResult{
		N8NData:  make(N8NData, 0, len(goStructs)),
		Errors:   make([]string, 0),
		Warnings: make([]string, 0),
		ReverseMetadata: ReverseMetadata{
			StructCount:     len(goStructs),
			FieldsProcessed: 0,
			SkippedFields:   make([]string, 0),
			TypeTransforms:  make(map[string]string),
		},
	}

	for i, goStruct := range goStructs {
		n8nItem, err := c.convertStruct(goStruct, i)
		if err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Struct %d: %v", i, err))
			c.logger.Error("Failed to convert Go struct",
				zap.Int("index", i),
				zap.Error(err))
			continue
		}

		result.N8NData = append(result.N8NData, *n8nItem)
		result.ReverseMetadata.FieldsProcessed += len(goStruct.Fields)
	}

	result.ReverseMetadata.ConversionTime = time.Since(startTime)

	c.logger.Info("Go to N8N conversion completed",
		zap.Int("structs_processed", len(goStructs)),
		zap.Int("items_converted", len(result.N8NData)),
		zap.Int("errors", len(result.Errors)),
		zap.Duration("duration", result.ReverseMetadata.ConversionTime))

	return result, nil
}

// convertStruct converts a single Go struct to N8N item
func (c *GoToN8NConverter) convertStruct(goStruct GoStruct, index int) (*N8NItem, error) {
	n8nItem := &N8NItem{
		JSON:   make(map[string]interface{}),
		Binary: make(map[string]interface{}),
	}

	for fieldName, fieldValue := range goStruct.Fields {
		// Handle special binary field
		if fieldName == "_binary" {
			if binaryData, ok := fieldValue.(map[string]interface{}); ok {
				n8nItem.Binary = c.convertBinaryFields(binaryData)
				continue
			}
		}

		// Transform field name
		transformedName := c.fieldNameTransformer(fieldName)

		// Apply custom JSON tags
		if customName, exists := c.customJSONTags[fieldName]; exists {
			transformedName = customName
		}

		// Convert field value
		convertedValue, err := c.convertValue(fieldValue, fieldName)
		if err != nil {
			c.logger.Warn("Failed to convert field value",
				zap.String("field", fieldName),
				zap.Error(err))
			continue
		}

		// Handle omitempty
		if c.useOmitEmpty && c.shouldOmitEmpty(convertedValue) {
			continue
		}

		n8nItem.JSON[transformedName] = convertedValue
	}

	// Clean up empty binary data
	if len(n8nItem.Binary) == 0 {
		n8nItem.Binary = nil
	}

	return n8nItem, nil
}

// convertValue converts a Go value to N8N compatible format
func (c *GoToN8NConverter) convertValue(value interface{}, fieldName string) (interface{}, error) {
	if value == nil {
		return nil, nil
	}

	switch v := value.(type) {
	case string:
		return v, nil
	case int, int8, int16, int32, int64:
		return c.convertInteger(v), nil
	case uint, uint8, uint16, uint32, uint64:
		return c.convertUnsignedInteger(v), nil
	case float32, float64:
		return c.convertFloat(v), nil
	case bool:
		return v, nil
	case time.Time:
		return c.convertTime(v), nil
	case []interface{}:
		return c.convertSlice(v, fieldName)
	case map[string]interface{}:
		return c.convertMap(v, fieldName)
	default:
		return c.convertReflectValue(reflect.ValueOf(value), fieldName)
	}
}

// convertInteger converts integer types to standard format
func (c *GoToN8NConverter) convertInteger(value interface{}) int64 {
	switch v := value.(type) {
	case int:
		return int64(v)
	case int8:
		return int64(v)
	case int16:
		return int64(v)
	case int32:
		return int64(v)
	case int64:
		return v
	default:
		return 0
	}
}

// convertUnsignedInteger converts unsigned integer types
func (c *GoToN8NConverter) convertUnsignedInteger(value interface{}) uint64 {
	switch v := value.(type) {
	case uint:
		return uint64(v)
	case uint8:
		return uint64(v)
	case uint16:
		return uint64(v)
	case uint32:
		return uint64(v)
	case uint64:
		return v
	default:
		return 0
	}
}

// convertFloat converts float types to standard format
func (c *GoToN8NConverter) convertFloat(value interface{}) float64 {
	switch v := value.(type) {
	case float32:
		return float64(v)
	case float64:
		return v
	default:
		return 0.0
	}
}

// convertTime converts time.Time to string format
func (c *GoToN8NConverter) convertTime(t time.Time) string {
	return t.Format(c.timeFormat)
}

// convertSlice converts slice/array types
func (c *GoToN8NConverter) convertSlice(slice []interface{}, fieldName string) ([]interface{}, error) {
	result := make([]interface{}, 0, len(slice))

	for i, item := range slice {
		convertedItem, err := c.convertValue(item, fmt.Sprintf("%s[%d]", fieldName, i))
		if err != nil {
			c.logger.Warn("Failed to convert slice item",
				zap.String("field", fieldName),
				zap.Int("index", i),
				zap.Error(err))
			continue
		}
		result = append(result, convertedItem)
	}

	return result, nil
}

// convertMap converts map types
func (c *GoToN8NConverter) convertMap(m map[string]interface{}, fieldName string) (map[string]interface{}, error) {
	result := make(map[string]interface{})

	for key, value := range m {
		convertedValue, err := c.convertValue(value, fmt.Sprintf("%s.%s", fieldName, key))
		if err != nil {
			c.logger.Warn("Failed to convert map value",
				zap.String("field", fieldName),
				zap.String("key", key),
				zap.Error(err))
			continue
		}

		// Transform key if needed
		transformedKey := c.fieldNameTransformer(key)
		result[transformedKey] = convertedValue
	}

	return result, nil
}

// convertReflectValue converts values using reflection
func (c *GoToN8NConverter) convertReflectValue(v reflect.Value, fieldName string) (interface{}, error) {
	if !v.IsValid() {
		return nil, nil
	}

	// Dereference pointers
	for v.Kind() == reflect.Ptr {
		if v.IsNil() {
			return nil, nil
		}
		v = v.Elem()
	}

	switch v.Kind() {
	case reflect.String:
		return v.String(), nil
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		return v.Int(), nil
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		return v.Uint(), nil
	case reflect.Float32, reflect.Float64:
		return v.Float(), nil
	case reflect.Bool:
		return v.Bool(), nil
	case reflect.Slice, reflect.Array:
		return c.convertReflectSlice(v, fieldName)
	case reflect.Map:
		return c.convertReflectMap(v, fieldName)
	case reflect.Struct:
		return c.convertReflectStruct(v, fieldName)
	case reflect.Interface:
		if v.IsNil() {
			return nil, nil
		}
		return c.convertValue(v.Interface(), fieldName)
	default:
		// For unknown types, convert to string
		return fmt.Sprintf("%v", v.Interface()), nil
	}
}

// convertReflectSlice converts slice using reflection
func (c *GoToN8NConverter) convertReflectSlice(v reflect.Value, fieldName string) ([]interface{}, error) {
	result := make([]interface{}, 0, v.Len())

	for i := 0; i < v.Len(); i++ {
		item := v.Index(i)
		convertedItem, err := c.convertReflectValue(item, fmt.Sprintf("%s[%d]", fieldName, i))
		if err != nil {
			c.logger.Warn("Failed to convert slice item via reflection",
				zap.String("field", fieldName),
				zap.Int("index", i),
				zap.Error(err))
			continue
		}
		result = append(result, convertedItem)
	}

	return result, nil
}

// convertReflectMap converts map using reflection
func (c *GoToN8NConverter) convertReflectMap(v reflect.Value, fieldName string) (map[string]interface{}, error) {
	result := make(map[string]interface{})

	for _, key := range v.MapKeys() {
		keyStr := fmt.Sprintf("%v", key.Interface())
		value := v.MapIndex(key)

		convertedValue, err := c.convertReflectValue(value, fmt.Sprintf("%s.%s", fieldName, keyStr))
		if err != nil {
			c.logger.Warn("Failed to convert map value via reflection",
				zap.String("field", fieldName),
				zap.String("key", keyStr),
				zap.Error(err))
			continue
		}

		transformedKey := c.fieldNameTransformer(keyStr)
		result[transformedKey] = convertedValue
	}

	return result, nil
}

// convertReflectStruct converts struct using reflection
func (c *GoToN8NConverter) convertReflectStruct(v reflect.Value, fieldName string) (map[string]interface{}, error) {
	result := make(map[string]interface{})
	structType := v.Type()

	for i := 0; i < v.NumField(); i++ {
		field := v.Field(i)
		fieldType := structType.Field(i)

		// Skip unexported fields
		if !fieldType.IsExported() {
			continue
		}

		// Get field name (check for json tag)
		fieldName := fieldType.Name
		if jsonTag := fieldType.Tag.Get("json"); jsonTag != "" {
			// Parse json tag
			if jsonTag == "-" {
				continue // Skip field
			}
			if commaIdx := strings.Index(jsonTag, ","); commaIdx != -1 {
				fieldName = jsonTag[:commaIdx]
			} else {
				fieldName = jsonTag
			}
		}

		// Convert field value
		convertedValue, err := c.convertReflectValue(field, fmt.Sprintf("%s.%s", fieldName, fieldName))
		if err != nil {
			c.logger.Warn("Failed to convert struct field via reflection",
				zap.String("field", fieldName),
				zap.String("struct_field", fieldType.Name),
				zap.Error(err))
			continue
		}

		// Handle omitempty
		if c.useOmitEmpty && c.shouldOmitEmpty(convertedValue) {
			continue
		}

		result[fieldName] = convertedValue
	}

	return result, nil
}

// convertBinaryFields converts binary metadata back to N8N format
func (c *GoToN8NConverter) convertBinaryFields(binaryData map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})

	for key, value := range binaryData {
		if metadata, ok := value.(map[string]interface{}); ok {
			n8nBinary := make(map[string]interface{})

			// Convert back to N8N binary format
			if fileName, exists := metadata["file_name"]; exists {
				n8nBinary["fileName"] = fileName
			}
			if mimeType, exists := metadata["mime_type"]; exists {
				n8nBinary["mimeType"] = mimeType
			}
			if fileSize, exists := metadata["file_size"]; exists {
				n8nBinary["fileSize"] = fileSize
			}
			if hasData, exists := metadata["has_data"]; exists && hasData == true {
				// For actual binary data, we'd need the original data
				// For now, we indicate that data was present
				n8nBinary["data"] = "[binary data]"
			}

			result[key] = n8nBinary
		}
	}

	return result
}

// shouldOmitEmpty determines if a value should be omitted when empty
func (c *GoToN8NConverter) shouldOmitEmpty(value interface{}) bool {
	if value == nil {
		return true
	}

	switch v := value.(type) {
	case string:
		return v == ""
	case int, int8, int16, int32, int64:
		return c.convertInteger(v) == 0
	case uint, uint8, uint16, uint32, uint64:
		return c.convertUnsignedInteger(v) == 0
	case float32, float64:
		return c.convertFloat(v) == 0.0
	case bool:
		return !v
	case []interface{}:
		return len(v) == 0
	case map[string]interface{}:
		return len(v) == 0
	default:
		// Use reflection for other types
		rv := reflect.ValueOf(value)
		if !rv.IsValid() {
			return true
		}
		return rv.IsZero()
	}
}

// DefaultFieldNameTransformer is the default field name transformer
func DefaultFieldNameTransformer(name string) string {
	return name // No transformation by default
}

// CamelToSnakeTransformer converts camelCase to snake_case
func CamelToSnakeTransformer(name string) string {
	var result []rune
	for i, r := range name {
		if i > 0 && 'A' <= r && r <= 'Z' {
			result = append(result, '_')
		}
		result = append(result, r)
	}
	return strings.ToLower(string(result))
}

// SnakeToCamelTransformer converts snake_case to camelCase
func SnakeToCamelTransformer(name string) string {
	parts := strings.Split(name, "_")
	if len(parts) <= 1 {
		return name
	}

	result := parts[0]
	for i := 1; i < len(parts); i++ {
		if len(parts[i]) > 0 {
			result += strings.ToUpper(parts[i][:1]) + parts[i][1:]
		}
	}
	return result
}

// RoundTripTest performs a round-trip conversion test
func (c *GoToN8NConverter) RoundTripTest(original N8NData, n8nToGoConverter *N8NToGoConverter) (*RoundTripResult, error) {
	// Convert N8N to Go
	goResult, err := n8nToGoConverter.Convert(original)
	if err != nil {
		return nil, fmt.Errorf("N8N to Go conversion failed: %w", err)
	}

	// Convert Go back to N8N
	n8nResult, err := c.Convert(goResult.Data)
	if err != nil {
		return nil, fmt.Errorf("Go to N8N conversion failed: %w", err)
	}

	// Compare results
	comparison := c.compareN8NData(original, n8nResult.N8NData)

	return &RoundTripResult{
		Original:   original,
		GoResult:   goResult,
		N8NResult:  n8nResult,
		Comparison: comparison,
		Success:    comparison.MatchPercentage > 95.0, // 95% match threshold
	}, nil
}

// RoundTripResult represents the result of a round-trip test
type RoundTripResult struct {
	Original   N8NData                  `json:"original"`
	GoResult   *ConversionResult        `json:"go_result"`
	N8NResult  *ReverseConversionResult `json:"n8n_result"`
	Comparison *DataComparison          `json:"comparison"`
	Success    bool                     `json:"success"`
}

// DataComparison represents comparison between two N8N datasets
type DataComparison struct {
	MatchPercentage float64  `json:"match_percentage"`
	Differences     []string `json:"differences"`
	MissingFields   []string `json:"missing_fields"`
	ExtraFields     []string `json:"extra_fields"`
	TypeMismatches  []string `json:"type_mismatches"`
}

// compareN8NData compares two N8N datasets
func (c *GoToN8NConverter) compareN8NData(original, converted N8NData) *DataComparison {
	comparison := &DataComparison{
		Differences:    make([]string, 0),
		MissingFields:  make([]string, 0),
		ExtraFields:    make([]string, 0),
		TypeMismatches: make([]string, 0),
	}

	if len(original) != len(converted) {
		comparison.Differences = append(comparison.Differences,
			fmt.Sprintf("Item count mismatch: original %d, converted %d", len(original), len(converted)))
	}

	totalFields := 0
	matchingFields := 0

	minLen := len(original)
	if len(converted) < minLen {
		minLen = len(converted)
	}

	for i := 0; i < minLen; i++ {
		origItem := original[i]
		convItem := converted[i]

		// Compare JSON fields
		for key, origValue := range origItem.JSON {
			totalFields++
			if convValue, exists := convItem.JSON[key]; exists {
				if c.valuesEqual(origValue, convValue) {
					matchingFields++
				} else {
					comparison.TypeMismatches = append(comparison.TypeMismatches,
						fmt.Sprintf("Item %d, field %s: %T vs %T", i, key, origValue, convValue))
				}
			} else {
				comparison.MissingFields = append(comparison.MissingFields,
					fmt.Sprintf("Item %d, missing field: %s", i, key))
			}
		}

		// Check for extra fields
		for key := range convItem.JSON {
			if _, exists := origItem.JSON[key]; !exists {
				comparison.ExtraFields = append(comparison.ExtraFields,
					fmt.Sprintf("Item %d, extra field: %s", i, key))
			}
		}
	}

	if totalFields > 0 {
		comparison.MatchPercentage = float64(matchingFields) / float64(totalFields) * 100.0
	}

	return comparison
}

// valuesEqual compares two values for equality
func (c *GoToN8NConverter) valuesEqual(a, b interface{}) bool {
	if a == nil && b == nil {
		return true
	}
	if a == nil || b == nil {
		return false
	}

	// Handle type conversions
	switch va := a.(type) {
	case string:
		if vb, ok := b.(string); ok {
			return va == vb
		}
	case int, int8, int16, int32, int64:
		if vb, ok := b.(int64); ok {
			return c.convertInteger(va) == vb
		}
	case float32, float64:
		if vb, ok := b.(float64); ok {
			return c.convertFloat(va) == vb
		}
	case bool:
		if vb, ok := b.(bool); ok {
			return va == vb
		}
	}

	// Fallback to string comparison
	return fmt.Sprintf("%v", a) == fmt.Sprintf("%v", b)
}

// GetReverseStatistics returns reverse conversion statistics
func (c *GoToN8NConverter) GetReverseStatistics(result *ReverseConversionResult) map[string]interface{} {
	if result == nil {
		return nil
	}

	successRate := 0.0
	if result.ReverseMetadata.StructCount > 0 {
		successRate = float64(len(result.N8NData)) / float64(result.ReverseMetadata.StructCount) * 100
	}

	return map[string]interface{}{
		"input_structs":    result.ReverseMetadata.StructCount,
		"converted_items":  len(result.N8NData),
		"success_rate":     successRate,
		"conversion_time":  result.ReverseMetadata.ConversionTime.String(),
		"errors":           len(result.Errors),
		"warnings":         len(result.Warnings),
		"fields_processed": result.ReverseMetadata.FieldsProcessed,
		"skipped_fields":   len(result.ReverseMetadata.SkippedFields),
	}
}
