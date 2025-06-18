package serialization

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"strings"
)

// JSONSchemaValidator validateur de schéma JSON
type JSONSchemaValidator struct {
	n8nSchema *JSONSchema
	goSchema  *JSONSchema
	config    *SerializationConfig
}

// JSONSchema représente un schéma JSON simplifié
type JSONSchema struct {
	Type                 string                `json:"type"`
	Properties           map[string]JSONSchema `json:"properties"`
	Required             []string              `json:"required"`
	AdditionalProperties bool                  `json:"additionalProperties"`
	Items                *JSONSchema           `json:"items,omitempty"`
	Enum                 []interface{}         `json:"enum,omitempty"`
}

// NewJSONSchemaValidator crée un nouveau validateur
func NewJSONSchemaValidator(config *SerializationConfig) SchemaValidator {
	return &JSONSchemaValidator{
		config: config,
	}
}

// LoadSchema charge un schéma depuis un fichier
func (v *JSONSchemaValidator) LoadSchema(schemaPath string) error {
	data, err := ioutil.ReadFile(schemaPath)
	if err != nil {
		return fmt.Errorf("failed to read schema file: %w", err)
	}

	var schema JSONSchema
	if err := json.Unmarshal(data, &schema); err != nil {
		return fmt.Errorf("failed to parse schema: %w", err)
	}

	// Déterminer le type de schéma basé sur le nom du fichier
	if strings.Contains(schemaPath, "n8n") {
		v.n8nSchema = &schema
	} else if strings.Contains(schemaPath, "go") {
		v.goSchema = &schema
	}

	return nil
}

// ValidateN8NSchema valide les données contre le schéma N8N
func (v *JSONSchemaValidator) ValidateN8NSchema(data []byte) error {
	if v.n8nSchema == nil {
		// Si pas de schéma chargé, faire une validation basique
		return v.validateBasicJSON(data)
	}

	var jsonData interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return fmt.Errorf("invalid JSON: %w", err)
	}

	return v.validateAgainstSchema(jsonData, v.n8nSchema, "")
}

// ValidateGoSchema valide un workflow Go contre le schéma
func (v *JSONSchemaValidator) ValidateGoSchema(workflow *WorkflowData) error {
	if v.goSchema == nil {
		// Si pas de schéma chargé, faire une validation basique
		return v.validateBasicWorkflow(workflow)
	}

	// Convertir le workflow en interface{} pour validation
	data, err := json.Marshal(workflow)
	if err != nil {
		return fmt.Errorf("failed to marshal workflow: %w", err)
	}

	var jsonData interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return fmt.Errorf("failed to unmarshal for validation: %w", err)
	}

	return v.validateAgainstSchema(jsonData, v.goSchema, "")
}

// validateAgainstSchema valide des données contre un schéma
func (v *JSONSchemaValidator) validateAgainstSchema(data interface{}, schema *JSONSchema, path string) error {
	switch schema.Type {
	case "object":
		return v.validateObject(data, schema, path)
	case "array":
		return v.validateArray(data, schema, path)
	case "string":
		return v.validateString(data, schema, path)
	case "number", "integer":
		return v.validateNumber(data, schema, path)
	case "boolean":
		return v.validateBoolean(data, schema, path)
	default:
		// Type non spécifié ou non supporté
		return nil
	}
}

// validateObject valide un objet JSON
func (v *JSONSchemaValidator) validateObject(data interface{}, schema *JSONSchema, path string) error {
	obj, ok := data.(map[string]interface{})
	if !ok {
		return fmt.Errorf("expected object at %s, got %T", path, data)
	}

	// Vérifier les champs requis
	for _, required := range schema.Required {
		if _, exists := obj[required]; !exists {
			return fmt.Errorf("required field '%s' missing at %s", required, path)
		}
	}

	// Valider chaque propriété
	for key, value := range obj {
		propertyPath := path + "." + key
		if len(path) == 0 {
			propertyPath = key
		}

		if propSchema, exists := schema.Properties[key]; exists {
			if err := v.validateAgainstSchema(value, &propSchema, propertyPath); err != nil {
				return err
			}
		} else if !schema.AdditionalProperties && v.config.StrictMode {
			return fmt.Errorf("additional property '%s' not allowed at %s", key, path)
		}
	}

	return nil
}

// validateArray valide un tableau JSON
func (v *JSONSchemaValidator) validateArray(data interface{}, schema *JSONSchema, path string) error {
	arr, ok := data.([]interface{})
	if !ok {
		return fmt.Errorf("expected array at %s, got %T", path, data)
	}

	if schema.Items != nil {
		for i, item := range arr {
			itemPath := fmt.Sprintf("%s[%d]", path, i)
			if err := v.validateAgainstSchema(item, schema.Items, itemPath); err != nil {
				return err
			}
		}
	}

	return nil
}

// validateString valide une chaîne JSON
func (v *JSONSchemaValidator) validateString(data interface{}, schema *JSONSchema, path string) error {
	str, ok := data.(string)
	if !ok {
		return fmt.Errorf("expected string at %s, got %T", path, data)
	}

	// Vérifier les valeurs enum
	if len(schema.Enum) > 0 {
		for _, enumValue := range schema.Enum {
			if enumStr, ok := enumValue.(string); ok && enumStr == str {
				return nil
			}
		}
		return fmt.Errorf("value '%s' not in enum at %s", str, path)
	}

	return nil
}

// validateNumber valide un nombre JSON
func (v *JSONSchemaValidator) validateNumber(data interface{}, schema *JSONSchema, path string) error {
	switch data.(type) {
	case float64, int, int64:
		return nil
	default:
		return fmt.Errorf("expected number at %s, got %T", path, data)
	}
}

// validateBoolean valide un booléen JSON
func (v *JSONSchemaValidator) validateBoolean(data interface{}, schema *JSONSchema, path string) error {
	_, ok := data.(bool)
	if !ok {
		return fmt.Errorf("expected boolean at %s, got %T", path, data)
	}
	return nil
}

// validateBasicJSON fait une validation JSON basique
func (v *JSONSchemaValidator) validateBasicJSON(data []byte) error {
	var temp interface{}
	return json.Unmarshal(data, &temp)
}

// validateBasicWorkflow fait une validation basique d'un workflow
func (v *JSONSchemaValidator) validateBasicWorkflow(workflow *WorkflowData) error {
	if workflow == nil {
		return fmt.Errorf("workflow cannot be nil")
	}

	if workflow.ID == "" {
		return fmt.Errorf("workflow ID is required")
	}

	if workflow.Name == "" {
		return fmt.Errorf("workflow name is required")
	}

	if len(workflow.Nodes) == 0 {
		return fmt.Errorf("workflow must have at least one node")
	}

	// Validation des nodes
	for i, node := range workflow.Nodes {
		if err := v.validateBasicNode(&node, i); err != nil {
			return fmt.Errorf("node %d validation failed: %w", i, err)
		}
	}

	return nil
}

// validateBasicNode fait une validation basique d'un node
func (v *JSONSchemaValidator) validateBasicNode(node *WorkflowNode, index int) error {
	if node.ID == "" {
		return fmt.Errorf("node ID is required")
	}

	if node.Name == "" {
		return fmt.Errorf("node name is required")
	}

	if node.Type == "" {
		return fmt.Errorf("node type is required")
	}

	return nil
}

// DefaultN8NSchema retourne un schéma N8N par défaut
func DefaultN8NSchema() *JSONSchema {
	return &JSONSchema{
		Type:     "object",
		Required: []string{"id", "name", "nodes"},
		Properties: map[string]JSONSchema{
			"id":        {Type: "string"},
			"name":      {Type: "string"},
			"active":    {Type: "boolean"},
			"createdAt": {Type: "string"},
			"updatedAt": {Type: "string"},
			"tags": {
				Type:  "array",
				Items: &JSONSchema{Type: "string"},
			},
			"settings":    {Type: "object", AdditionalProperties: true},
			"connections": {Type: "object", AdditionalProperties: true},
			"nodes": {
				Type: "array",
				Items: &JSONSchema{
					Type:     "object",
					Required: []string{"id", "name", "type"},
					Properties: map[string]JSONSchema{
						"id":          {Type: "string"},
						"name":        {Type: "string"},
						"type":        {Type: "string"},
						"typeVersion": {Type: "integer"},
						"position": {
							Type:  "array",
							Items: &JSONSchema{Type: "number"},
						},
						"parameters":  {Type: "object", AdditionalProperties: true},
						"credentials": {Type: "object", AdditionalProperties: true},
						"disabled":    {Type: "boolean"},
					},
				},
			},
		},
	}
}

// DefaultGoSchema retourne un schéma Go par défaut
func DefaultGoSchema() *JSONSchema {
	return &JSONSchema{
		Type:     "object",
		Required: []string{"id", "name", "nodes"},
		Properties: map[string]JSONSchema{
			"id":         {Type: "string"},
			"name":       {Type: "string"},
			"active":     {Type: "boolean"},
			"created_at": {Type: "string"},
			"updated_at": {Type: "string"},
			"tags": {
				Type:  "array",
				Items: &JSONSchema{Type: "string"},
			},
			"settings":    {Type: "object", AdditionalProperties: true},
			"connections": {Type: "object", AdditionalProperties: true},
			"nodes": {
				Type: "array",
				Items: &JSONSchema{
					Type:     "object",
					Required: []string{"id", "name", "type"},
					Properties: map[string]JSONSchema{
						"id":          {Type: "string"},
						"name":        {Type: "string"},
						"type":        {Type: "string"},
						"typeVersion": {Type: "integer"},
						"position": {
							Type: "object",
							Properties: map[string]JSONSchema{
								"x": {Type: "number"},
								"y": {Type: "number"},
							},
						},
						"parameters":  {Type: "object", AdditionalProperties: true},
						"credentials": {Type: "object", AdditionalProperties: true},
						"disabled":    {Type: "boolean"},
					},
				},
			},
		},
	}
}
