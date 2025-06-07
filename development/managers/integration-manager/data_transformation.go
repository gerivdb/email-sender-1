package integration_manager

import (
	"encoding/json"
	"fmt"
	"reflect"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
	"github.com/your-org/email-sender/development/managers/interfaces"
)

// TransformData transforms data using the specified transformation
func (im *IntegrationManagerImpl) TransformData(transformationID string, data interface{}) (interface{}, error) {
	im.mutex.RLock()
	transformation, exists := im.transformations[transformationID]
	im.mutex.RUnlock()

	if !exists {
		return nil, fmt.Errorf("transformation not found: %s", transformationID)
	}

	startTime := time.Now()
	im.logger.WithFields(logrus.Fields{
		"transformation_id": transformationID,
		"transformation_type": transformation.Type,
		"data_type": reflect.TypeOf(data).String(),
	}).Info("Starting data transformation")

	result, err := im.executeTransformation(transformation, data)
	
	processingTime := time.Since(startTime)
	
	// Log transformation execution
	im.logTransformationExecution(transformationID, data, result, err, processingTime)

	if err != nil {
		im.logger.WithError(err).WithField("transformation_id", transformationID).Error("Data transformation failed")
		return nil, fmt.Errorf("transformation failed: %w", err)
	}

	im.logger.WithFields(logrus.Fields{
		"transformation_id": transformationID,
		"processing_time": processingTime,
	}).Info("Data transformation completed successfully")

	return result, nil
}

// RegisterTransformation registers a new data transformation
func (im *IntegrationManagerImpl) RegisterTransformation(transformation *interfaces.DataTransformation) error {
	im.mutex.Lock()
	defer im.mutex.Unlock()

	im.logger.WithFields(logrus.Fields{
		"transformation_id": transformation.ID,
		"type": transformation.Type,
		"name": transformation.Name,
	}).Info("Registering data transformation")

	// Validate transformation
	if err := im.validateTransformation(transformation); err != nil {
		im.logger.WithError(err).Error("Transformation validation failed")
		return fmt.Errorf("transformation validation failed: %w", err)
	}

	// Set transformation metadata
	transformation.CreatedAt = time.Now()
	transformation.UpdatedAt = time.Now()

	// Compile transformation if needed
	if err := im.compileTransformation(transformation); err != nil {
		im.logger.WithError(err).Error("Transformation compilation failed")
		return fmt.Errorf("transformation compilation failed: %w", err)
	}

	// Store transformation
	im.transformations[transformation.ID] = transformation

	im.logger.WithField("transformation_id", transformation.ID).Info("Data transformation registered successfully")
	return nil
}

// executeTransformation executes a data transformation
func (im *IntegrationManagerImpl) executeTransformation(transformation *interfaces.DataTransformation, data interface{}) (interface{}, error) {
	switch transformation.Type {
	case "script":
		return im.executeScriptTransformation(transformation, data)
	case "mapping":
		return im.executeMappingTransformation(transformation, data)
	case "filter":
		return im.executeFilterTransformation(transformation, data)
	case "aggregation":
		return im.executeAggregationTransformation(transformation, data)
	case "custom":
		return im.executeCustomTransformation(transformation, data)
	default:
		return nil, fmt.Errorf("unsupported transformation type: %s", transformation.Type)
	}
}

// executeScriptTransformation executes script-based transformation
func (im *IntegrationManagerImpl) executeScriptTransformation(transformation *interfaces.DataTransformation, data interface{}) (interface{}, error) {
	script, ok := transformation.Config["script"].(string)
	if !ok {
		return nil, fmt.Errorf("script not found in transformation config")
	}

	language, ok := transformation.Config["language"].(string)
	if !ok {
		language = "javascript" // Default to JavaScript
	}

	im.logger.WithFields(logrus.Fields{
		"transformation_id": transformation.ID,
		"language": language,
		"script_length": len(script),
	}).Debug("Executing script transformation")

	switch language {
	case "javascript":
		return im.executeJavaScriptTransformation(script, data)
	case "jsonpath":
		return im.executeJSONPathTransformation(script, data)
	case "regex":
		return im.executeRegexTransformation(script, data)
	default:
		return nil, fmt.Errorf("unsupported script language: %s", language)
	}
}

// executeJavaScriptTransformation executes JavaScript-based transformation
func (im *IntegrationManagerImpl) executeJavaScriptTransformation(script string, data interface{}) (interface{}, error) {
	// Note: In a real implementation, you would use a JavaScript engine like Otto or V8
	// For this example, we'll implement basic JavaScript-like operations
	
	// Convert data to JSON for script processing
	jsonData, err := json.Marshal(data)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal data: %w", err)
	}

	var result interface{}
	if err := json.Unmarshal(jsonData, &result); err != nil {
		return nil, fmt.Errorf("failed to unmarshal data: %w", err)
	}

	// Simple script execution simulation
	// In production, use a proper JavaScript engine
	if strings.Contains(script, "return") {
		// Extract return statement
		returnIndex := strings.Index(script, "return")
		if returnIndex != -1 {
			returnExpr := strings.TrimSpace(script[returnIndex+6:])
			returnExpr = strings.TrimSuffix(returnExpr, ";")
			
			// Simple expression evaluation
			if strings.HasPrefix(returnExpr, "data.") {
				fieldPath := strings.TrimPrefix(returnExpr, "data.")
				return im.getNestedField(result, fieldPath)
			}
		}
	}

	return result, nil
}

// executeJSONPathTransformation executes JSONPath-based transformation
func (im *IntegrationManagerImpl) executeJSONPathTransformation(jsonPath string, data interface{}) (interface{}, error) {
	// Simple JSONPath implementation
	// In production, use a proper JSONPath library
	
	if jsonPath == "$" {
		return data, nil
	}

	if strings.HasPrefix(jsonPath, "$.") {
		fieldPath := strings.TrimPrefix(jsonPath, "$.")
		return im.getNestedField(data, fieldPath)
	}

	return nil, fmt.Errorf("unsupported JSONPath expression: %s", jsonPath)
}

// executeRegexTransformation executes regex-based transformation
func (im *IntegrationManagerImpl) executeRegexTransformation(pattern string, data interface{}) (interface{}, error) {
	str, ok := data.(string)
	if !ok {
		return nil, fmt.Errorf("regex transformation requires string input")
	}

	// Parse regex pattern and replacement
	parts := strings.Split(pattern, "|")
	if len(parts) != 2 {
		return nil, fmt.Errorf("invalid regex pattern format, expected 'pattern|replacement'")
	}

	regex, err := regexp.Compile(parts[0])
	if err != nil {
		return nil, fmt.Errorf("invalid regex pattern: %w", err)
	}

	result := regex.ReplaceAllString(str, parts[1])
	return result, nil
}

// executeMappingTransformation executes field mapping transformation
func (im *IntegrationManagerImpl) executeMappingTransformation(transformation *interfaces.DataTransformation, data interface{}) (interface{}, error) {
	mappings, ok := transformation.Config["mappings"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("mappings not found in transformation config")
	}

	im.logger.WithFields(logrus.Fields{
		"transformation_id": transformation.ID,
		"mapping_count": len(mappings),
	}).Debug("Executing mapping transformation")

	result := make(map[string]interface{})
	
	for targetField, sourceField := range mappings {
		sourceFieldStr, ok := sourceField.(string)
		if !ok {
			continue
		}

		value, err := im.getNestedField(data, sourceFieldStr)
		if err != nil {
			im.logger.WithError(err).WithFields(logrus.Fields{
				"source_field": sourceFieldStr,
				"target_field": targetField,
			}).Warn("Failed to map field")
			continue
		}
		
		im.setNestedField(result, targetField, value)
	}

	return result, nil
}

// executeFilterTransformation executes data filtering transformation
func (im *IntegrationManagerImpl) executeFilterTransformation(transformation *interfaces.DataTransformation, data interface{}) (interface{}, error) {
	filters, ok := transformation.Config["filters"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("filters not found in transformation config")
	}

	im.logger.WithFields(logrus.Fields{
		"transformation_id": transformation.ID,
		"filter_count": len(filters),
	}).Debug("Executing filter transformation")

	// Handle array filtering
	if reflect.TypeOf(data).Kind() == reflect.Slice {
		return im.filterArray(data, filters)
	}

	// Handle object filtering
	return im.filterObject(data, filters)
}

// executeAggregationTransformation executes data aggregation transformation
func (im *IntegrationManagerImpl) executeAggregationTransformation(transformation *interfaces.DataTransformation, data interface{}) (interface{}, error) {
	aggregations, ok := transformation.Config["aggregations"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("aggregations not found in transformation config")
	}

	im.logger.WithFields(logrus.Fields{
		"transformation_id": transformation.ID,
		"aggregation_count": len(aggregations),
	}).Debug("Executing aggregation transformation")

	// Ensure data is an array
	dataArray, ok := data.([]interface{})
	if !ok {
		return nil, fmt.Errorf("aggregation transformation requires array input")
	}

	result := make(map[string]interface{})

	for aggName, aggConfig := range aggregations {
		aggConfigMap, ok := aggConfig.(map[string]interface{})
		if !ok {
			continue
		}

		aggType, _ := aggConfigMap["type"].(string)
		field, _ := aggConfigMap["field"].(string)

		switch aggType {
		case "count":
			result[aggName] = len(dataArray)
		case "sum":
			sum, err := im.sumField(dataArray, field)
			if err != nil {
				im.logger.WithError(err).Warn("Failed to calculate sum")
				continue
			}
			result[aggName] = sum
		case "avg":
			avg, err := im.avgField(dataArray, field)
			if err != nil {
				im.logger.WithError(err).Warn("Failed to calculate average")
				continue
			}
			result[aggName] = avg
		case "min":
			min, err := im.minField(dataArray, field)
			if err != nil {
				im.logger.WithError(err).Warn("Failed to calculate minimum")
				continue
			}
			result[aggName] = min
		case "max":
			max, err := im.maxField(dataArray, field)
			if err != nil {
				im.logger.WithError(err).Warn("Failed to calculate maximum")
				continue
			}
			result[aggName] = max
		case "group_by":
			grouped, err := im.groupByField(dataArray, field)
			if err != nil {
				im.logger.WithError(err).Warn("Failed to group by field")
				continue
			}
			result[aggName] = grouped
		}
	}

	return result, nil
}

// executeCustomTransformation executes custom transformation logic
func (im *IntegrationManagerImpl) executeCustomTransformation(transformation *interfaces.DataTransformation, data interface{}) (interface{}, error) {
	customType, ok := transformation.Config["custom_type"].(string)
	if !ok {
		return nil, fmt.Errorf("custom_type not found in transformation config")
	}

	im.logger.WithFields(logrus.Fields{
		"transformation_id": transformation.ID,
		"custom_type": customType,
	}).Debug("Executing custom transformation")

	switch customType {
	case "flatten":
		return im.flattenData(data)
	case "unflatten":
		return im.unflattenData(data)
	case "normalize":
		return im.normalizeData(data)
	case "denormalize":
		return im.denormalizeData(data)
	case "sort":
		sortField, _ := transformation.Config["sort_field"].(string)
		ascending, _ := transformation.Config["ascending"].(bool)
		return im.sortData(data, sortField, ascending)
	case "deduplicate":
		keyField, _ := transformation.Config["key_field"].(string)
		return im.deduplicateData(data, keyField)
	default:
		return nil, fmt.Errorf("unsupported custom transformation type: %s", customType)
	}
}

// validateTransformation validates transformation configuration
func (im *IntegrationManagerImpl) validateTransformation(transformation *interfaces.DataTransformation) error {
	if transformation.ID == "" {
		return fmt.Errorf("transformation ID is required")
	}

	if transformation.Type == "" {
		return fmt.Errorf("transformation type is required")
	}

	validTypes := map[string]bool{
		"script":      true,
		"mapping":     true,
		"filter":      true,
		"aggregation": true,
		"custom":      true,
	}

	if !validTypes[transformation.Type] {
		return fmt.Errorf("invalid transformation type: %s", transformation.Type)
	}

	if transformation.Config == nil {
		return fmt.Errorf("transformation config is required")
	}

	// Type-specific validation
	switch transformation.Type {
	case "script":
		if _, ok := transformation.Config["script"]; !ok {
			return fmt.Errorf("script is required for script transformation")
		}
	case "mapping":
		if _, ok := transformation.Config["mappings"]; !ok {
			return fmt.Errorf("mappings are required for mapping transformation")
		}
	case "filter":
		if _, ok := transformation.Config["filters"]; !ok {
			return fmt.Errorf("filters are required for filter transformation")
		}
	case "aggregation":
		if _, ok := transformation.Config["aggregations"]; !ok {
			return fmt.Errorf("aggregations are required for aggregation transformation")
		}
	case "custom":
		if _, ok := transformation.Config["custom_type"]; !ok {
			return fmt.Errorf("custom_type is required for custom transformation")
		}
	}

	return nil
}

// compileTransformation compiles transformation for better performance
func (im *IntegrationManagerImpl) compileTransformation(transformation *interfaces.DataTransformation) error {
	// Compile regex patterns, validate JSONPath expressions, etc.
	switch transformation.Type {
	case "script":
		language, _ := transformation.Config["language"].(string)
		if language == "regex" {
			script, _ := transformation.Config["script"].(string)
			if script != "" {
				parts := strings.Split(script, "|")
				if len(parts) == 2 {
					_, err := regexp.Compile(parts[0])
					if err != nil {
						return fmt.Errorf("invalid regex pattern: %w", err)
					}
				}
			}
		}
	}

	return nil
}

// Helper functions for data manipulation

// getNestedField gets a nested field value using dot notation
func (im *IntegrationManagerImpl) getNestedField(data interface{}, fieldPath string) (interface{}, error) {
	if fieldPath == "" {
		return data, nil
	}

	fields := strings.Split(fieldPath, ".")
	current := data

	for _, field := range fields {
		switch v := current.(type) {
		case map[string]interface{}:
			current = v[field]
		case map[interface{}]interface{}:
			current = v[field]
		default:
			return nil, fmt.Errorf("cannot access field '%s' on non-object type", field)
		}

		if current == nil {
			return nil, nil
		}
	}

	return current, nil
}

// setNestedField sets a nested field value using dot notation
func (im *IntegrationManagerImpl) setNestedField(data interface{}, fieldPath string, value interface{}) {
	if fieldPath == "" {
		return
	}

	fields := strings.Split(fieldPath, ".")
	current := data

	for i, field := range fields[:len(fields)-1] {
		switch v := current.(type) {
		case map[string]interface{}:
			if v[field] == nil {
				v[field] = make(map[string]interface{})
			}
			current = v[field]
		default:
			return
		}
	}

	lastField := fields[len(fields)-1]
	if m, ok := current.(map[string]interface{}); ok {
		m[lastField] = value
	}
}

// filterArray filters an array based on filter conditions
func (im *IntegrationManagerImpl) filterArray(data interface{}, filters map[string]interface{}) (interface{}, error) {
	dataArray, ok := data.([]interface{})
	if !ok {
		return nil, fmt.Errorf("expected array for filtering")
	}

	var result []interface{}

	for _, item := range dataArray {
		if im.matchesFilters(item, filters) {
			result = append(result, item)
		}
	}

	return result, nil
}

// filterObject filters an object by including/excluding fields
func (im *IntegrationManagerImpl) filterObject(data interface{}, filters map[string]interface{}) (interface{}, error) {
	include, hasInclude := filters["include"]
	exclude, hasExclude := filters["exclude"]

	if !hasInclude && !hasExclude {
		return data, nil
	}

	dataMap, ok := data.(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("expected object for filtering")
	}

	result := make(map[string]interface{})

	if hasInclude {
		includeFields, ok := include.([]interface{})
		if ok {
			for _, field := range includeFields {
				if fieldStr, ok := field.(string); ok {
					if value, exists := dataMap[fieldStr]; exists {
						result[fieldStr] = value
					}
				}
			}
		}
	} else {
		// Copy all fields first
		for k, v := range dataMap {
			result[k] = v
		}

		// Remove excluded fields
		if hasExclude {
			excludeFields, ok := exclude.([]interface{})
			if ok {
				for _, field := range excludeFields {
					if fieldStr, ok := field.(string); ok {
						delete(result, fieldStr)
					}
				}
			}
		}
	}

	return result, nil
}

// matchesFilters checks if an item matches filter conditions
func (im *IntegrationManagerImpl) matchesFilters(item interface{}, filters map[string]interface{}) bool {
	for field, condition := range filters {
		if field == "include" || field == "exclude" {
			continue
		}

		value, err := im.getNestedField(item, field)
		if err != nil {
			return false
		}

		if !im.matchesCondition(value, condition) {
			return false
		}
	}

	return true
}

// matchesCondition checks if a value matches a condition
func (im *IntegrationManagerImpl) matchesCondition(value interface{}, condition interface{}) bool {
	switch cond := condition.(type) {
	case map[string]interface{}:
		// Handle complex conditions like {"$gt": 10, "$lt": 20}
		for op, val := range cond {
			switch op {
			case "$eq":
				if value != val {
					return false
				}
			case "$ne":
				if value == val {
					return false
				}
			case "$gt":
				if !im.isGreaterThan(value, val) {
					return false
				}
			case "$lt":
				if !im.isLessThan(value, val) {
					return false
				}
			case "$gte":
				if !im.isGreaterThanOrEqual(value, val) {
					return false
				}
			case "$lte":
				if !im.isLessThanOrEqual(value, val) {
					return false
				}
			case "$in":
				if !im.isInArray(value, val) {
					return false
				}
			case "$nin":
				if im.isInArray(value, val) {
					return false
				}
			}
		}
		return true
	default:
		// Simple equality check
		return value == condition
	}
}

// Aggregation helper functions

func (im *IntegrationManagerImpl) sumField(data []interface{}, field string) (float64, error) {
	var sum float64
	for _, item := range data {
		value, err := im.getNestedField(item, field)
		if err != nil {
			continue
		}
		if num, ok := im.toFloat64(value); ok {
			sum += num
		}
	}
	return sum, nil
}

func (im *IntegrationManagerImpl) avgField(data []interface{}, field string) (float64, error) {
	sum, err := im.sumField(data, field)
	if err != nil {
		return 0, err
	}
	if len(data) == 0 {
		return 0, nil
	}
	return sum / float64(len(data)), nil
}

func (im *IntegrationManagerImpl) minField(data []interface{}, field string) (interface{}, error) {
	var min interface{}
	for _, item := range data {
		value, err := im.getNestedField(item, field)
		if err != nil {
			continue
		}
		if min == nil || im.isLessThan(value, min) {
			min = value
		}
	}
	return min, nil
}

func (im *IntegrationManagerImpl) maxField(data []interface{}, field string) (interface{}, error) {
	var max interface{}
	for _, item := range data {
		value, err := im.getNestedField(item, field)
		if err != nil {
			continue
		}
		if max == nil || im.isGreaterThan(value, max) {
			max = value
		}
	}
	return max, nil
}

func (im *IntegrationManagerImpl) groupByField(data []interface{}, field string) (map[string][]interface{}, error) {
	groups := make(map[string][]interface{})
	
	for _, item := range data {
		value, err := im.getNestedField(item, field)
		if err != nil {
			continue
		}
		
		key := fmt.Sprintf("%v", value)
		groups[key] = append(groups[key], item)
	}
	
	return groups, nil
}

// Custom transformation helper functions

func (im *IntegrationManagerImpl) flattenData(data interface{}) (interface{}, error) {
	result := make(map[string]interface{})
	im.flattenObject(data, "", result)
	return result, nil
}

func (im *IntegrationManagerImpl) flattenObject(data interface{}, prefix string, result map[string]interface{}) {
	switch v := data.(type) {
	case map[string]interface{}:
		for key, value := range v {
			newKey := key
			if prefix != "" {
				newKey = prefix + "." + key
			}
			im.flattenObject(value, newKey, result)
		}
	default:
		result[prefix] = data
	}
}

func (im *IntegrationManagerImpl) unflattenData(data interface{}) (interface{}, error) {
	dataMap, ok := data.(map[string]interface{})
	if !ok {
		return data, nil
	}

	result := make(map[string]interface{})
	
	for key, value := range dataMap {
		im.setNestedField(result, key, value)
	}
	
	return result, nil
}

func (im *IntegrationManagerImpl) normalizeData(data interface{}) (interface{}, error) {
	// Simple normalization - convert all string numbers to actual numbers
	return im.normalizeValue(data), nil
}

func (im *IntegrationManagerImpl) normalizeValue(value interface{}) interface{} {
	switch v := value.(type) {
	case string:
		// Try to convert string numbers to actual numbers
		if num, err := strconv.ParseFloat(v, 64); err == nil {
			if num == float64(int64(num)) {
				return int64(num)
			}
			return num
		}
		return v
	case map[string]interface{}:
		result := make(map[string]interface{})
		for k, val := range v {
			result[k] = im.normalizeValue(val)
		}
		return result
	case []interface{}:
		result := make([]interface{}, len(v))
		for i, val := range v {
			result[i] = im.normalizeValue(val)
		}
		return result
	default:
		return v
	}
}

func (im *IntegrationManagerImpl) denormalizeData(data interface{}) (interface{}, error) {
	// Simple denormalization - convert all numbers to strings
	return im.denormalizeValue(data), nil
}

func (im *IntegrationManagerImpl) denormalizeValue(value interface{}) interface{} {
	switch v := value.(type) {
	case int, int64, float64:
		return fmt.Sprintf("%v", v)
	case map[string]interface{}:
		result := make(map[string]interface{})
		for k, val := range v {
			result[k] = im.denormalizeValue(val)
		}
		return result
	case []interface{}:
		result := make([]interface{}, len(v))
		for i, val := range v {
			result[i] = im.denormalizeValue(val)
		}
		return result
	default:
		return v
	}
}

func (im *IntegrationManagerImpl) sortData(data interface{}, sortField string, ascending bool) (interface{}, error) {
	dataArray, ok := data.([]interface{})
	if !ok {
		return data, nil
	}

	// Create a copy to avoid modifying original data
	result := make([]interface{}, len(dataArray))
	copy(result, dataArray)

	sort.Slice(result, func(i, j int) bool {
		valueI, _ := im.getNestedField(result[i], sortField)
		valueJ, _ := im.getNestedField(result[j], sortField)
		
		if ascending {
			return im.isLessThan(valueI, valueJ)
		}
		return im.isGreaterThan(valueI, valueJ)
	})

	return result, nil
}

func (im *IntegrationManagerImpl) deduplicateData(data interface{}, keyField string) (interface{}, error) {
	dataArray, ok := data.([]interface{})
	if !ok {
		return data, nil
	}

	seen := make(map[string]bool)
	var result []interface{}

	for _, item := range dataArray {
		key := ""
		if keyField != "" {
			keyValue, err := im.getNestedField(item, keyField)
			if err == nil {
				key = fmt.Sprintf("%v", keyValue)
			}
		} else {
			// Use entire item as key
			keyBytes, _ := json.Marshal(item)
			key = string(keyBytes)
		}

		if !seen[key] {
			seen[key] = true
			result = append(result, item)
		}
	}

	return result, nil
}

// Comparison helper functions

func (im *IntegrationManagerImpl) toFloat64(value interface{}) (float64, bool) {
	switch v := value.(type) {
	case float64:
		return v, true
	case int:
		return float64(v), true
	case int64:
		return float64(v), true
	case string:
		if f, err := strconv.ParseFloat(v, 64); err == nil {
			return f, true
		}
	}
	return 0, false
}

func (im *IntegrationManagerImpl) isGreaterThan(a, b interface{}) bool {
	if numA, okA := im.toFloat64(a); okA {
		if numB, okB := im.toFloat64(b); okB {
			return numA > numB
		}
	}
	return fmt.Sprintf("%v", a) > fmt.Sprintf("%v", b)
}

func (im *IntegrationManagerImpl) isLessThan(a, b interface{}) bool {
	if numA, okA := im.toFloat64(a); okA {
		if numB, okB := im.toFloat64(b); okB {
			return numA < numB
		}
	}
	return fmt.Sprintf("%v", a) < fmt.Sprintf("%v", b)
}

func (im *IntegrationManagerImpl) isGreaterThanOrEqual(a, b interface{}) bool {
	return im.isGreaterThan(a, b) || a == b
}

func (im *IntegrationManagerImpl) isLessThanOrEqual(a, b interface{}) bool {
	return im.isLessThan(a, b) || a == b
}

func (im *IntegrationManagerImpl) isInArray(value interface{}, array interface{}) bool {
	arraySlice, ok := array.([]interface{})
	if !ok {
		return false
	}

	for _, item := range arraySlice {
		if item == value {
			return true
		}
	}
	return false
}

// logTransformationExecution logs transformation execution details
func (im *IntegrationManagerImpl) logTransformationExecution(transformationID string, input, output interface{}, err error, duration time.Duration) {
	data := map[string]interface{}{
		"transformation_id": transformationID,
		"processing_time":   duration.String(),
		"input_type":        reflect.TypeOf(input).String(),
		"success":           err == nil,
	}

	if output != nil {
		data["output_type"] = reflect.TypeOf(output).String()
	}

	if err != nil {
		data["error"] = err.Error()
	}

	level := logrus.InfoLevel
	if err != nil {
		level = logrus.ErrorLevel
	}

	im.logger.WithFields(data).Log(level, "Data transformation executed")
}
