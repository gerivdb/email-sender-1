package converters

import (
	"fmt"
	"reflect"
	"regexp"
	"strings"
	"time"

	"go.uber.org/zap"
)

// SchemaValidator validates data schemas across N8N and Go platforms
type SchemaValidator struct {
	logger         *zap.Logger
	strictMode     bool
	schemaRegistry map[string]*Schema
	typeCheckers   map[string]TypeChecker
}

// Schema represents a data schema definition
type Schema struct {
	Name        string               `json:"name"`
	Version     string               `json:"version"`
	Type        string               `json:"type"`
	Properties  map[string]*Property `json:"properties"`
	Required    []string             `json:"required"`
	Description string               `json:"description,omitempty"`
	Examples    []interface{}        `json:"examples,omitempty"`
}

// Property represents a schema property
type Property struct {
	Type        string               `json:"type"`
	Format      string               `json:"format,omitempty"`
	Description string               `json:"description,omitempty"`
	Required    bool                 `json:"required"`
	Default     interface{}          `json:"default,omitempty"`
	Enum        []interface{}        `json:"enum,omitempty"`
	Pattern     string               `json:"pattern,omitempty"`
	MinLength   *int                 `json:"minLength,omitempty"`
	MaxLength   *int                 `json:"maxLength,omitempty"`
	Minimum     *float64             `json:"minimum,omitempty"`
	Maximum     *float64             `json:"maximum,omitempty"`
	Items       *Property            `json:"items,omitempty"`
	Properties  map[string]*Property `json:"properties,omitempty"`
}

// ValidationResult represents schema validation results
type ValidationResult struct {
	Valid              bool              `json:"valid"`
	Errors             []ValidationError `json:"errors,omitempty"`
	Warnings           []ValidationError `json:"warnings,omitempty"`
	CompatibilityScore float64           `json:"compatibility_score"`
	Suggestions        []string          `json:"suggestions,omitempty"`
	SchemaUsed         string            `json:"schema_used,omitempty"`
}

// ValidationError represents a validation error
type ValidationError struct {
	Path     string `json:"path"`
	Message  string `json:"message"`
	Expected string `json:"expected"`
	Actual   string `json:"actual"`
	Severity string `json:"severity"` // "error", "warning", "info"
	Code     string `json:"code"`
}

// TypeChecker validates specific data types
type TypeChecker func(value interface{}, property *Property) error

// SchemaValidatorOptions provides configuration for the validator
type SchemaValidatorOptions struct {
	StrictMode           bool                   `json:"strict_mode"`
	CustomTypeCheckers   map[string]TypeChecker `json:"-"`
	AllowAdditionalProps bool                   `json:"allow_additional_props"`
	ValidateFormats      bool                   `json:"validate_formats"`
}

// NewSchemaValidator creates a new schema validator
func NewSchemaValidator(logger *zap.Logger, options SchemaValidatorOptions) *SchemaValidator {
	validator := &SchemaValidator{
		logger:         logger,
		strictMode:     options.StrictMode,
		schemaRegistry: make(map[string]*Schema),
		typeCheckers:   getDefaultTypeCheckers(),
	}

	// Add custom type checkers
	if options.CustomTypeCheckers != nil {
		for name, checker := range options.CustomTypeCheckers {
			validator.typeCheckers[name] = checker
		}
	}

	return validator
}

// RegisterSchema registers a schema in the validator
func (sv *SchemaValidator) RegisterSchema(schema *Schema) error {
	if schema.Name == "" {
		return fmt.Errorf("schema name cannot be empty")
	}

	sv.schemaRegistry[schema.Name] = schema
	sv.logger.Info("Schema registered", zap.String("name", schema.Name), zap.String("version", schema.Version))
	return nil
}

// ValidateData validates data against a registered schema
func (sv *SchemaValidator) ValidateData(data interface{}, schemaName string) (*ValidationResult, error) {
	schema, exists := sv.schemaRegistry[schemaName]
	if !exists {
		return nil, fmt.Errorf("schema '%s' not found", schemaName)
	}

	result := &ValidationResult{
		Valid:              true,
		Errors:             make([]ValidationError, 0),
		Warnings:           make([]ValidationError, 0),
		CompatibilityScore: 100.0,
		Suggestions:        make([]string, 0),
		SchemaUsed:         schemaName,
	}

	// Validate the data against the schema
	sv.validateValue(data, schema, "", result)

	// Calculate final compatibility score
	if len(result.Errors) > 0 {
		result.Valid = false
		errorWeight := float64(len(result.Errors)) * 10.0
		warningWeight := float64(len(result.Warnings)) * 2.0
		result.CompatibilityScore = 100.0 - errorWeight - warningWeight
		if result.CompatibilityScore < 0 {
			result.CompatibilityScore = 0
		}
	}

	sv.logger.Info("Schema validation completed",
		zap.String("schema", schemaName),
		zap.Bool("valid", result.Valid),
		zap.Int("errors", len(result.Errors)),
		zap.Int("warnings", len(result.Warnings)),
		zap.Float64("score", result.CompatibilityScore))

	return result, nil
}

// ValidateN8NToGoCompatibility validates compatibility between N8N and Go data
func (sv *SchemaValidator) ValidateN8NToGoCompatibility(n8nData N8NData, goData []GoStruct) (*CompatibilityResult, error) {
	result := &CompatibilityResult{
		Compatible:         true,
		Issues:             make([]CompatibilityIssue, 0),
		MappingSuggestions: make([]MappingSuggestion, 0),
		OverallScore:       100.0,
	}

	// Check data count compatibility
	if len(n8nData) != len(goData) {
		result.Issues = append(result.Issues, CompatibilityIssue{
			Type:        "count_mismatch",
			Severity:    "warning",
			Description: fmt.Sprintf("N8N data has %d items, Go data has %d items", len(n8nData), len(goData)),
			Impact:      "Data synchronization issues may occur",
		})
	}

	minLen := len(n8nData)
	if len(goData) < minLen {
		minLen = len(goData)
	}

	// Validate each item pair
	for i := 0; i < minLen; i++ {
		sv.validateItemCompatibility(n8nData[i], goData[i], i, result)
	}

	// Calculate overall score
	if len(result.Issues) > 0 {
		for _, issue := range result.Issues {
			switch issue.Severity {
			case "error":
				result.OverallScore -= 15.0
			case "warning":
				result.OverallScore -= 5.0
			case "info":
				result.OverallScore -= 1.0
			}
		}
		if result.OverallScore < 70.0 {
			result.Compatible = false
		}
	}

	return result, nil
}

// validateValue validates a value against schema properties
func (sv *SchemaValidator) validateValue(value interface{}, schema *Schema, path string, result *ValidationResult) {
	if value == nil {
		if contains(schema.Required, path) {
			result.Errors = append(result.Errors, ValidationError{
				Path:     path,
				Message:  "Required field is missing",
				Expected: "non-null value",
				Actual:   "null",
				Severity: "error",
				Code:     "required_field_missing",
			})
		}
		return
	}

	// Validate against schema properties
	for propName, property := range schema.Properties {
		currentPath := path
		if currentPath != "" {
			currentPath += "."
		}
		currentPath += propName

		// Extract value for this property
		var propValue interface{}
		if dataMap, ok := value.(map[string]interface{}); ok {
			propValue = dataMap[propName]
		} else if goStruct, ok := value.(GoStruct); ok {
			propValue = goStruct.Fields[propName]
		} else {
			// Use reflection to get field value
			rv := reflect.ValueOf(value)
			if rv.Kind() == reflect.Ptr {
				rv = rv.Elem()
			}
			if rv.Kind() == reflect.Struct {
				field := rv.FieldByName(propName)
				if field.IsValid() {
					propValue = field.Interface()
				}
			}
		}

		sv.validateProperty(propValue, property, currentPath, result)
	}
}

// validateProperty validates a single property
func (sv *SchemaValidator) validateProperty(value interface{}, property *Property, path string, result *ValidationResult) {
	// Check if required
	if property.Required && value == nil {
		result.Errors = append(result.Errors, ValidationError{
			Path:     path,
			Message:  "Required property is missing",
			Expected: property.Type,
			Actual:   "null",
			Severity: "error",
			Code:     "required_property_missing",
		})
		return
	}

	if value == nil {
		return // Optional property is nil, that's okay
	}

	// Validate type
	if err := sv.validateType(value, property.Type, property); err != nil {
		result.Errors = append(result.Errors, ValidationError{
			Path:     path,
			Message:  err.Error(),
			Expected: property.Type,
			Actual:   fmt.Sprintf("%T", value),
			Severity: "error",
			Code:     "type_mismatch",
		})
		return
	}

	// Validate format
	if property.Format != "" {
		if err := sv.validateFormat(value, property.Format); err != nil {
			result.Warnings = append(result.Warnings, ValidationError{
				Path:     path,
				Message:  err.Error(),
				Expected: property.Format,
				Actual:   fmt.Sprintf("%v", value),
				Severity: "warning",
				Code:     "format_mismatch",
			})
		}
	}

	// Validate constraints
	sv.validateConstraints(value, property, path, result)
}

// validateType validates the type of a value
func (sv *SchemaValidator) validateType(value interface{}, expectedType string, property *Property) error {
	if checker, exists := sv.typeCheckers[expectedType]; exists {
		return checker(value, property)
	}

	// Default type checking
	switch expectedType {
	case "string":
		if _, ok := value.(string); !ok {
			return fmt.Errorf("expected string, got %T", value)
		}
	case "number", "integer":
		switch value.(type) {
		case int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64, float32, float64:
			return nil
		default:
			return fmt.Errorf("expected number, got %T", value)
		}
	case "boolean":
		if _, ok := value.(bool); !ok {
			return fmt.Errorf("expected boolean, got %T", value)
		}
	case "array":
		if reflect.TypeOf(value).Kind() != reflect.Slice {
			return fmt.Errorf("expected array, got %T", value)
		}
	case "object":
		switch value.(type) {
		case map[string]interface{}, GoStruct:
			return nil
		default:
			if reflect.TypeOf(value).Kind() != reflect.Struct {
				return fmt.Errorf("expected object, got %T", value)
			}
		}
	}

	return nil
}

// validateFormat validates value format
func (sv *SchemaValidator) validateFormat(value interface{}, format string) error {
	str, ok := value.(string)
	if !ok {
		return fmt.Errorf("format validation requires string value")
	}

	switch format {
	case "date":
		if _, err := time.Parse("2006-01-02", str); err != nil {
			return fmt.Errorf("invalid date format: %s", str)
		}
	case "date-time":
		if _, err := time.Parse(time.RFC3339, str); err != nil {
			return fmt.Errorf("invalid date-time format: %s", str)
		}
	case "email":
		emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
		if !emailRegex.MatchString(str) {
			return fmt.Errorf("invalid email format: %s", str)
		}
	case "uri":
		if !strings.HasPrefix(str, "http://") && !strings.HasPrefix(str, "https://") {
			return fmt.Errorf("invalid URI format: %s", str)
		}
	case "uuid":
		uuidRegex := regexp.MustCompile(`^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)
		if !uuidRegex.MatchString(str) {
			return fmt.Errorf("invalid UUID format: %s", str)
		}
	}

	return nil
}

// validateConstraints validates value constraints
func (sv *SchemaValidator) validateConstraints(value interface{}, property *Property, path string, result *ValidationResult) {
	// String constraints
	if str, ok := value.(string); ok {
		if property.MinLength != nil && len(str) < *property.MinLength {
			result.Errors = append(result.Errors, ValidationError{
				Path:     path,
				Message:  fmt.Sprintf("String length %d is less than minimum %d", len(str), *property.MinLength),
				Expected: fmt.Sprintf("length >= %d", *property.MinLength),
				Actual:   fmt.Sprintf("length = %d", len(str)),
				Severity: "error",
				Code:     "min_length_violation",
			})
		}
		if property.MaxLength != nil && len(str) > *property.MaxLength {
			result.Errors = append(result.Errors, ValidationError{
				Path:     path,
				Message:  fmt.Sprintf("String length %d exceeds maximum %d", len(str), *property.MaxLength),
				Expected: fmt.Sprintf("length <= %d", *property.MaxLength),
				Actual:   fmt.Sprintf("length = %d", len(str)),
				Severity: "error",
				Code:     "max_length_violation",
			})
		}
		if property.Pattern != "" {
			if matched, _ := regexp.MatchString(property.Pattern, str); !matched {
				result.Warnings = append(result.Warnings, ValidationError{
					Path:     path,
					Message:  fmt.Sprintf("String does not match pattern: %s", property.Pattern),
					Expected: property.Pattern,
					Actual:   str,
					Severity: "warning",
					Code:     "pattern_mismatch",
				})
			}
		}
	}

	// Number constraints
	if num := getNumericValue(value); num != nil {
		if property.Minimum != nil && *num < *property.Minimum {
			result.Errors = append(result.Errors, ValidationError{
				Path:     path,
				Message:  fmt.Sprintf("Value %f is less than minimum %f", *num, *property.Minimum),
				Expected: fmt.Sprintf(">= %f", *property.Minimum),
				Actual:   fmt.Sprintf("%f", *num),
				Severity: "error",
				Code:     "minimum_violation",
			})
		}
		if property.Maximum != nil && *num > *property.Maximum {
			result.Errors = append(result.Errors, ValidationError{
				Path:     path,
				Message:  fmt.Sprintf("Value %f exceeds maximum %f", *num, *property.Maximum),
				Expected: fmt.Sprintf("<= %f", *property.Maximum),
				Actual:   fmt.Sprintf("%f", *num),
				Severity: "error",
				Code:     "maximum_violation",
			})
		}
	}

	// Enum validation
	if len(property.Enum) > 0 {
		found := false
		for _, enumValue := range property.Enum {
			if reflect.DeepEqual(value, enumValue) {
				found = true
				break
			}
		}
		if !found {
			result.Errors = append(result.Errors, ValidationError{
				Path:     path,
				Message:  "Value is not in the allowed enum values",
				Expected: fmt.Sprintf("one of %v", property.Enum),
				Actual:   fmt.Sprintf("%v", value),
				Severity: "error",
				Code:     "enum_violation",
			})
		}
	}
}

// validateItemCompatibility validates compatibility between N8N and Go items
func (sv *SchemaValidator) validateItemCompatibility(n8nItem N8NItem, goStruct GoStruct, index int, result *CompatibilityResult) {
	// Check for missing fields
	for key := range n8nItem.JSON {
		if _, exists := goStruct.Fields[key]; !exists {
			result.Issues = append(result.Issues, CompatibilityIssue{
				Type:        "missing_field",
				Severity:    "warning",
				Field:       key,
				Index:       index,
				Description: fmt.Sprintf("N8N field '%s' not found in Go struct", key),
				Impact:      "Data may be lost during conversion",
			})

			result.MappingSuggestions = append(result.MappingSuggestions, MappingSuggestion{
				SourceField: key,
				TargetField: suggestFieldName(key, goStruct.Fields),
				Confidence:  0.7,
				Reason:      "Field name similarity",
			})
		}
	}

	// Check for extra fields
	for key := range goStruct.Fields {
		if _, exists := n8nItem.JSON[key]; !exists {
			result.Issues = append(result.Issues, CompatibilityIssue{
				Type:        "extra_field",
				Severity:    "info",
				Field:       key,
				Index:       index,
				Description: fmt.Sprintf("Go field '%s' not found in N8N data", key),
				Impact:      "Field will be empty or use default value",
			})
		}
	}

	// Check type compatibility
	for key, n8nValue := range n8nItem.JSON {
		if goValue, exists := goStruct.Fields[key]; exists {
			if !sv.typesCompatible(n8nValue, goValue) {
				result.Issues = append(result.Issues, CompatibilityIssue{
					Type:        "type_incompatible",
					Severity:    "error",
					Field:       key,
					Index:       index,
					Description: fmt.Sprintf("Type mismatch: N8N %T vs Go %T", n8nValue, goValue),
					Impact:      "Type conversion may fail or produce unexpected results",
				})
			}
		}
	}
}

// CompatibilityResult represents cross-platform compatibility results
type CompatibilityResult struct {
	Compatible         bool                 `json:"compatible"`
	Issues             []CompatibilityIssue `json:"issues,omitempty"`
	MappingSuggestions []MappingSuggestion  `json:"mapping_suggestions,omitempty"`
	OverallScore       float64              `json:"overall_score"`
}

// CompatibilityIssue represents a compatibility issue
type CompatibilityIssue struct {
	Type        string `json:"type"`
	Severity    string `json:"severity"`
	Field       string `json:"field,omitempty"`
	Index       int    `json:"index,omitempty"`
	Description string `json:"description"`
	Impact      string `json:"impact"`
}

// MappingSuggestion represents a field mapping suggestion
type MappingSuggestion struct {
	SourceField string  `json:"source_field"`
	TargetField string  `json:"target_field"`
	Confidence  float64 `json:"confidence"`
	Reason      string  `json:"reason"`
}

// CreateN8NSchema creates a schema from N8N data
func (sv *SchemaValidator) CreateN8NSchema(n8nData N8NData, name string) (*Schema, error) {
	schema := &Schema{
		Name:       name,
		Version:    "1.0.0",
		Type:       "object",
		Properties: make(map[string]*Property),
		Required:   make([]string, 0),
	}

	// Analyze all items to infer schema
	fieldTypes := make(map[string]map[string]int)
	fieldRequired := make(map[string]int)

	for _, item := range n8nData {
		for key, value := range item.JSON {
			if fieldTypes[key] == nil {
				fieldTypes[key] = make(map[string]int)
			}
			fieldTypes[key][inferType(value)]++
			fieldRequired[key]++
		}
	}

	// Create properties
	for fieldName, types := range fieldTypes {
		property := &Property{
			Required: fieldRequired[fieldName] == len(n8nData),
		}

		// Determine the most common type
		mostCommonType := ""
		maxCount := 0
		for typeName, count := range types {
			if count > maxCount {
				maxCount = count
				mostCommonType = typeName
			}
		}
		property.Type = mostCommonType

		schema.Properties[fieldName] = property

		if property.Required {
			schema.Required = append(schema.Required, fieldName)
		}
	}

	return schema, nil
}

// Helper functions
func getDefaultTypeCheckers() map[string]TypeChecker {
	return map[string]TypeChecker{
		"string": func(value interface{}, property *Property) error {
			if _, ok := value.(string); !ok {
				return fmt.Errorf("expected string, got %T", value)
			}
			return nil
		},
		"number": func(value interface{}, property *Property) error {
			switch value.(type) {
			case int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64, float32, float64:
				return nil
			default:
				return fmt.Errorf("expected number, got %T", value)
			}
		},
		"boolean": func(value interface{}, property *Property) error {
			if _, ok := value.(bool); !ok {
				return fmt.Errorf("expected boolean, got %T", value)
			}
			return nil
		},
	}
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

func getNumericValue(value interface{}) *float64 {
	switch v := value.(type) {
	case int:
		f := float64(v)
		return &f
	case int8:
		f := float64(v)
		return &f
	case int16:
		f := float64(v)
		return &f
	case int32:
		f := float64(v)
		return &f
	case int64:
		f := float64(v)
		return &f
	case uint:
		f := float64(v)
		return &f
	case uint8:
		f := float64(v)
		return &f
	case uint16:
		f := float64(v)
		return &f
	case uint32:
		f := float64(v)
		return &f
	case uint64:
		f := float64(v)
		return &f
	case float32:
		f := float64(v)
		return &f
	case float64:
		return &v
	default:
		return nil
	}
}

func inferType(value interface{}) string {
	if value == nil {
		return "null"
	}

	switch value.(type) {
	case string:
		return "string"
	case int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64:
		return "integer"
	case float32, float64:
		return "number"
	case bool:
		return "boolean"
	case []interface{}:
		return "array"
	case map[string]interface{}:
		return "object"
	default:
		return "unknown"
	}
}

func (sv *SchemaValidator) typesCompatible(n8nValue, goValue interface{}) bool {
	n8nType := inferType(n8nValue)
	goType := inferType(goValue)

	// Exact match
	if n8nType == goType {
		return true
	}

	// Compatible conversions
	switch n8nType {
	case "integer":
		return goType == "number" || goType == "string"
	case "number":
		return goType == "integer" || goType == "string"
	case "string":
		return true // Strings can be converted to most types
	case "boolean":
		return goType == "string"
	default:
		return false
	}
}

func suggestFieldName(sourceField string, targetFields map[string]interface{}) string {
	sourceField = strings.ToLower(sourceField)

	bestMatch := ""
	bestScore := 0.0

	for targetField := range targetFields {
		score := stringSimilarity(sourceField, strings.ToLower(targetField))
		if score > bestScore {
			bestScore = score
			bestMatch = targetField
		}
	}

	if bestScore > 0.5 {
		return bestMatch
	}
	return ""
}

func stringSimilarity(s1, s2 string) float64 {
	if s1 == s2 {
		return 1.0
	}

	// Simple Levenshtein-based similarity
	maxLen := len(s1)
	if len(s2) > maxLen {
		maxLen = len(s2)
	}

	if maxLen == 0 {
		return 1.0
	}

	distance := levenshteinDistance(s1, s2)
	return 1.0 - float64(distance)/float64(maxLen)
}

func levenshteinDistance(s1, s2 string) int {
	if len(s1) == 0 {
		return len(s2)
	}
	if len(s2) == 0 {
		return len(s1)
	}

	matrix := make([][]int, len(s1)+1)
	for i := range matrix {
		matrix[i] = make([]int, len(s2)+1)
		matrix[i][0] = i
	}

	for j := 0; j <= len(s2); j++ {
		matrix[0][j] = j
	}

	for i := 1; i <= len(s1); i++ {
		for j := 1; j <= len(s2); j++ {
			cost := 0
			if s1[i-1] != s2[j-1] {
				cost = 1
			}

			matrix[i][j] = min(
				matrix[i-1][j]+1,      // deletion
				matrix[i][j-1]+1,      // insertion
				matrix[i-1][j-1]+cost, // substitution
			)
		}
	}

	return matrix[len(s1)][len(s2)]
}

func min(a, b, c int) int {
	if a < b && a < c {
		return a
	}
	if b < c {
		return b
	}
	return c
}
