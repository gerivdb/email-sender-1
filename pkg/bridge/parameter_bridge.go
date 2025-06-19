package bridge

import (
	"context"
	"encoding/json"
	"fmt"
	"reflect"
	"strconv"
	"strings"
	"time"

	"go.uber.org/zap"
)

// ParameterBridge gère la transformation des paramètres entre N8N et Go
type ParameterBridge struct {
	logger          *zap.Logger
	typeConverters  map[string]TypeConverter
	validationRules map[string]ValidationRule
	defaultValues   map[string]interface{}
}

// TypeConverter définit une fonction de conversion de type
type TypeConverter func(value interface{}) (interface{}, error)

// ValidationRule définit une règle de validation
type ValidationRule struct {
	Required    bool
	MinLength   *int
	MaxLength   *int
	Pattern     *string
	AllowedVals []interface{}
	Validator   func(value interface{}) error
}

// N8NParameter représente un paramètre venant de N8N
type N8NParameter struct {
	Name     string      `json:"name"`
	Value    interface{} `json:"value"`
	Type     string      `json:"type"`
	Required bool        `json:"required"`
	Source   string      `json:"source"` // "input", "config", "expression"
}

// GoParameter représente un paramètre transformé pour Go
type GoParameter struct {
	Name             string      `json:"name"`
	Value            interface{} `json:"value"`
	Type             string      `json:"type"`
	OriginalType     string      `json:"original_type"`
	Transformed      bool        `json:"transformed"`
	ValidationErrors []string    `json:"validation_errors,omitempty"`
}

// BridgeRequest représente une demande de transformation
type BridgeRequest struct {
	Parameters    []N8NParameter         `json:"parameters"`
	TargetSchema  string                 `json:"target_schema"`
	Context       map[string]interface{} `json:"context"`
	TraceID       string                 `json:"trace_id"`
	CorrelationID string                 `json:"correlation_id"`
}

// BridgeResponse représente la réponse de transformation
type BridgeResponse struct {
	Parameters       []GoParameter          `json:"parameters"`
	ParameterMap     map[string]interface{} `json:"parameter_map"`
	ValidationErrors []string               `json:"validation_errors"`
	TransformStats   TransformStats         `json:"transform_stats"`
	Success          bool                   `json:"success"`
	Message          string                 `json:"message"`
}

// TransformStats contient les statistiques de transformation
type TransformStats struct {
	TotalParameters   int           `json:"total_parameters"`
	TransformedParams int           `json:"transformed_params"`
	ValidationErrors  int           `json:"validation_errors"`
	ProcessingTime    time.Duration `json:"processing_time"`
	SuccessRate       float64       `json:"success_rate"`
}

// NewParameterBridge crée une nouvelle instance de ParameterBridge
func NewParameterBridge(logger *zap.Logger) *ParameterBridge {
	bridge := &ParameterBridge{
		logger:          logger,
		typeConverters:  make(map[string]TypeConverter),
		validationRules: make(map[string]ValidationRule),
		defaultValues:   make(map[string]interface{}),
	}

	// Enregistrer les convertisseurs de type par défaut
	bridge.registerDefaultConverters()

	// Enregistrer les règles de validation par défaut
	bridge.registerDefaultValidations()

	return bridge
}

// registerDefaultConverters enregistre les convertisseurs de type par défaut
func (pb *ParameterBridge) registerDefaultConverters() {
	// Convertisseur string
	pb.typeConverters["string"] = func(value interface{}) (interface{}, error) {
		switch v := value.(type) {
		case string:
			return v, nil
		case int, int32, int64:
			return fmt.Sprintf("%d", v), nil
		case float32, float64:
			return fmt.Sprintf("%f", v), nil
		case bool:
			return fmt.Sprintf("%t", v), nil
		default:
			return fmt.Sprintf("%v", v), nil
		}
	}

	// Convertisseur int
	pb.typeConverters["int"] = func(value interface{}) (interface{}, error) {
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
			return strconv.Atoi(v)
		default:
			return 0, fmt.Errorf("cannot convert %T to int", value)
		}
	}

	// Convertisseur float64
	pb.typeConverters["float64"] = func(value interface{}) (interface{}, error) {
		switch v := value.(type) {
		case float64:
			return v, nil
		case float32:
			return float64(v), nil
		case int:
			return float64(v), nil
		case int32:
			return float64(v), nil
		case int64:
			return float64(v), nil
		case string:
			return strconv.ParseFloat(v, 64)
		default:
			return 0.0, fmt.Errorf("cannot convert %T to float64", value)
		}
	}

	// Convertisseur bool
	pb.typeConverters["bool"] = func(value interface{}) (interface{}, error) {
		switch v := value.(type) {
		case bool:
			return v, nil
		case string:
			lower := strings.ToLower(v)
			if lower == "true" || lower == "1" || lower == "yes" {
				return true, nil
			}
			if lower == "false" || lower == "0" || lower == "no" {
				return false, nil
			}
			return false, fmt.Errorf("cannot convert string '%s' to bool", v)
		case int:
			return v != 0, nil
		default:
			return false, fmt.Errorf("cannot convert %T to bool", value)
		}
	}

	// Convertisseur array
	pb.typeConverters["array"] = func(value interface{}) (interface{}, error) {
		switch v := value.(type) {
		case []interface{}:
			return v, nil
		case string:
			// Tenter de parser comme JSON
			var arr []interface{}
			if err := json.Unmarshal([]byte(v), &arr); err != nil {
				// Si ce n'est pas du JSON, diviser par virgules
				parts := strings.Split(v, ",")
				result := make([]interface{}, len(parts))
				for i, part := range parts {
					result[i] = strings.TrimSpace(part)
				}
				return result, nil
			}
			return arr, nil
		default:
			// Utiliser la réflexion pour les slices Go
			val := reflect.ValueOf(value)
			if val.Kind() == reflect.Slice {
				result := make([]interface{}, val.Len())
				for i := 0; i < val.Len(); i++ {
					result[i] = val.Index(i).Interface()
				}
				return result, nil
			}
			return nil, fmt.Errorf("cannot convert %T to array", value)
		}
	}

	// Convertisseur object
	pb.typeConverters["object"] = func(value interface{}) (interface{}, error) {
		switch v := value.(type) {
		case map[string]interface{}:
			return v, nil
		case string:
			var obj map[string]interface{}
			if err := json.Unmarshal([]byte(v), &obj); err != nil {
				return nil, fmt.Errorf("cannot parse string as JSON object: %w", err)
			}
			return obj, nil
		default:
			return nil, fmt.Errorf("cannot convert %T to object", value)
		}
	}
}

// registerDefaultValidations enregistre les règles de validation par défaut
func (pb *ParameterBridge) registerDefaultValidations() {
	// Validation pour email
	pb.validationRules["email"] = ValidationRule{
		Pattern: stringPtr(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`),
		Validator: func(value interface{}) error {
			if str, ok := value.(string); ok {
				if !strings.Contains(str, "@") {
					return fmt.Errorf("invalid email format")
				}
			}
			return nil
		},
	}

	// Validation pour URL
	pb.validationRules["url"] = ValidationRule{
		Validator: func(value interface{}) error {
			if str, ok := value.(string); ok {
				if !strings.HasPrefix(str, "http://") && !strings.HasPrefix(str, "https://") {
					return fmt.Errorf("URL must start with http:// or https://")
				}
			}
			return nil
		},
	}

	// Validation pour port
	pb.validationRules["port"] = ValidationRule{
		Validator: func(value interface{}) error {
			var port int
			switch v := value.(type) {
			case int:
				port = v
			case string:
				var err error
				port, err = strconv.Atoi(v)
				if err != nil {
					return fmt.Errorf("port must be a number")
				}
			default:
				return fmt.Errorf("port must be a number")
			}

			if port < 1 || port > 65535 {
				return fmt.Errorf("port must be between 1 and 65535")
			}
			return nil
		},
	}
}

// TransformParameters transforme les paramètres N8N en paramètres Go
func (pb *ParameterBridge) TransformParameters(ctx context.Context, request *BridgeRequest) (*BridgeResponse, error) {
	startTime := time.Now()

	pb.logger.Info("Starting parameter transformation",
		zap.String("trace_id", request.TraceID),
		zap.String("correlation_id", request.CorrelationID),
		zap.Int("parameter_count", len(request.Parameters)))

	response := &BridgeResponse{
		Parameters:       make([]GoParameter, 0, len(request.Parameters)),
		ParameterMap:     make(map[string]interface{}),
		ValidationErrors: make([]string, 0),
		Success:          true,
	}

	transformedCount := 0
	errorCount := 0

	for _, n8nParam := range request.Parameters {
		goParam, err := pb.transformSingleParameter(n8nParam, request.TargetSchema)
		if err != nil {
			pb.logger.Warn("Parameter transformation failed",
				zap.String("parameter_name", n8nParam.Name),
				zap.Error(err))

			response.ValidationErrors = append(response.ValidationErrors,
				fmt.Sprintf("Parameter '%s': %s", n8nParam.Name, err.Error()))
			errorCount++

			// Ajouter le paramètre avec erreur
			goParam = &GoParameter{
				Name:             n8nParam.Name,
				Value:            n8nParam.Value,
				Type:             n8nParam.Type,
				OriginalType:     n8nParam.Type,
				Transformed:      false,
				ValidationErrors: []string{err.Error()},
			}
		} else {
			transformedCount++
		}

		response.Parameters = append(response.Parameters, *goParam)
		response.ParameterMap[goParam.Name] = goParam.Value
	}

	// Calculer les statistiques
	processingTime := time.Since(startTime)
	totalParams := len(request.Parameters)
	successRate := float64(transformedCount) / float64(totalParams) * 100

	response.TransformStats = TransformStats{
		TotalParameters:   totalParams,
		TransformedParams: transformedCount,
		ValidationErrors:  errorCount,
		ProcessingTime:    processingTime,
		SuccessRate:       successRate,
	}

	// Déterminer le succès global
	if errorCount > 0 {
		response.Success = false
		response.Message = fmt.Sprintf("Transformation completed with %d errors", errorCount)
	} else {
		response.Message = "All parameters transformed successfully"
	}

	pb.logger.Info("Parameter transformation completed",
		zap.String("trace_id", request.TraceID),
		zap.Int("total_params", totalParams),
		zap.Int("transformed_params", transformedCount),
		zap.Int("errors", errorCount),
		zap.Float64("success_rate", successRate),
		zap.Duration("processing_time", processingTime))

	return response, nil
}

// transformSingleParameter transforme un seul paramètre
func (pb *ParameterBridge) transformSingleParameter(n8nParam N8NParameter, targetSchema string) (*GoParameter, error) {
	// Déterminer le type cible
	targetType := pb.determineTargetType(n8nParam, targetSchema)

	// Validation des paramètres requis
	if n8nParam.Required && pb.isEmpty(n8nParam.Value) {
		return nil, fmt.Errorf("required parameter '%s' is empty", n8nParam.Name)
	}

	// Si la valeur est vide et pas requise, utiliser la valeur par défaut
	if pb.isEmpty(n8nParam.Value) && !n8nParam.Required {
		if defaultVal, exists := pb.defaultValues[n8nParam.Name]; exists {
			n8nParam.Value = defaultVal
		}
	}

	// Convertir le type
	convertedValue, err := pb.convertType(n8nParam.Value, targetType)
	if err != nil {
		return nil, fmt.Errorf("type conversion failed: %w", err)
	}

	// Valider le paramètre
	if err := pb.validateParameter(n8nParam.Name, convertedValue); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	return &GoParameter{
		Name:         n8nParam.Name,
		Value:        convertedValue,
		Type:         targetType,
		OriginalType: n8nParam.Type,
		Transformed:  targetType != n8nParam.Type,
	}, nil
}

// determineTargetType détermine le type cible basé sur le schéma
func (pb *ParameterBridge) determineTargetType(param N8NParameter, targetSchema string) string {
	// Logique de mapping des types basée sur le schéma cible
	// Pour l'instant, utiliser des règles simples

	switch targetSchema {
	case "email":
		if param.Name == "recipients" {
			return "array"
		}
		if strings.Contains(param.Name, "email") {
			return "string"
		}
	case "http":
		if param.Name == "url" {
			return "string"
		}
		if param.Name == "timeout" {
			return "int"
		}
		if param.Name == "headers" {
			return "object"
		}
	}

	// Mapping par type original
	switch param.Type {
	case "number":
		return "float64"
	case "integer":
		return "int"
	case "boolean":
		return "bool"
	case "array":
		return "array"
	case "object":
		return "object"
	default:
		return "string"
	}
}

// convertType convertit une valeur vers le type cible
func (pb *ParameterBridge) convertType(value interface{}, targetType string) (interface{}, error) {
	if converter, exists := pb.typeConverters[targetType]; exists {
		return converter(value)
	}

	// Fallback: retourner la valeur telle quelle
	return value, nil
}

// validateParameter valide un paramètre selon les règles définies
func (pb *ParameterBridge) validateParameter(name string, value interface{}) error {
	// Validation par nom de paramètre
	if rule, exists := pb.validationRules[name]; exists {
		return pb.applyValidationRule(rule, value)
	}

	// Validation par type de paramètre (email, url, etc.)
	for ruleType, rule := range pb.validationRules {
		if strings.Contains(strings.ToLower(name), ruleType) {
			if err := pb.applyValidationRule(rule, value); err != nil {
				return err
			}
		}
	}

	return nil
}

// applyValidationRule applique une règle de validation
func (pb *ParameterBridge) applyValidationRule(rule ValidationRule, value interface{}) error {
	// Validation de longueur pour les strings
	if str, ok := value.(string); ok {
		if rule.MinLength != nil && len(str) < *rule.MinLength {
			return fmt.Errorf("value too short, minimum length is %d", *rule.MinLength)
		}
		if rule.MaxLength != nil && len(str) > *rule.MaxLength {
			return fmt.Errorf("value too long, maximum length is %d", *rule.MaxLength)
		}
	}

	// Validation avec fonction personnalisée
	if rule.Validator != nil {
		return rule.Validator(value)
	}

	return nil
}

// isEmpty vérifie si une valeur est vide
func (pb *ParameterBridge) isEmpty(value interface{}) bool {
	if value == nil {
		return true
	}

	switch v := value.(type) {
	case string:
		return strings.TrimSpace(v) == ""
	case []interface{}:
		return len(v) == 0
	case map[string]interface{}:
		return len(v) == 0
	default:
		return false
	}
}

// RegisterTypeConverter enregistre un convertisseur de type personnalisé
func (pb *ParameterBridge) RegisterTypeConverter(typeName string, converter TypeConverter) {
	pb.typeConverters[typeName] = converter
	pb.logger.Debug("Registered custom type converter", zap.String("type", typeName))
}

// RegisterValidationRule enregistre une règle de validation personnalisée
func (pb *ParameterBridge) RegisterValidationRule(name string, rule ValidationRule) {
	pb.validationRules[name] = rule
	pb.logger.Debug("Registered validation rule", zap.String("name", name))
}

// SetDefaultValue définit une valeur par défaut pour un paramètre
func (pb *ParameterBridge) SetDefaultValue(paramName string, defaultValue interface{}) {
	pb.defaultValues[paramName] = defaultValue
	pb.logger.Debug("Set default value",
		zap.String("parameter", paramName),
		zap.Any("value", defaultValue))
}

// GetSupportedTypes retourne les types supportés
func (pb *ParameterBridge) GetSupportedTypes() []string {
	types := make([]string, 0, len(pb.typeConverters))
	for typeName := range pb.typeConverters {
		types = append(types, typeName)
	}
	return types
}

// Helper function
func stringPtr(s string) *string {
	return &s
}
