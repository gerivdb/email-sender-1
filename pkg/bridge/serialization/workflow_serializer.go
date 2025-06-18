package serialization

import (
	"encoding/json"
	"fmt"
	"time"
)

// WorkflowSerializer interface pour la sérialisation des workflows
type WorkflowSerializer interface {
	SerializeToN8N(workflow *WorkflowData) ([]byte, error)
	DeserializeFromN8N(data []byte) (*WorkflowData, error)
	ValidateSchema(data []byte) error
}

// JSONWorkflowSerializer implémentation JSON
type JSONWorkflowSerializer struct {
	config    *SerializationConfig
	validator SchemaValidator
}

// NewJSONWorkflowSerializer crée un nouveau sérialiseur JSON
func NewJSONWorkflowSerializer(config *SerializationConfig, validator SchemaValidator) WorkflowSerializer {
	return &JSONWorkflowSerializer{
		config:    config,
		validator: validator,
	}
}

// SerializeToN8N convertit WorkflowData vers format JSON N8N
func (s *JSONWorkflowSerializer) SerializeToN8N(workflow *WorkflowData) ([]byte, error) {
	if workflow == nil {
		return nil, fmt.Errorf("workflow data cannot be nil")
	}

	// Validation avant sérialisation
	if err := s.validateWorkflowData(workflow); err != nil {
		return nil, fmt.Errorf("workflow validation failed: %w", err)
	}

	// Conversion vers format N8N
	n8nFormat := s.convertToN8NFormat(workflow)

	// Sérialisation JSON avec configuration
	var result []byte
	var err error

	if s.config.PrettyPrint {
		result, err = json.MarshalIndent(n8nFormat, "", "  ")
	} else {
		result, err = json.Marshal(n8nFormat)
	}

	if err != nil {
		return nil, fmt.Errorf("JSON serialization failed: %w", err)
	}

	// Validation du schéma de sortie
	if s.config.ValidateOutput && s.validator != nil {
		if err := s.validator.ValidateN8NSchema(result); err != nil {
			return nil, fmt.Errorf("output schema validation failed: %w", err)
		}
	}

	return result, nil
}

// DeserializeFromN8N convertit JSON N8N vers WorkflowData
func (s *JSONWorkflowSerializer) DeserializeFromN8N(data []byte) (*WorkflowData, error) {
	if len(data) == 0 {
		return nil, fmt.Errorf("input data cannot be empty")
	}

	// Validation du schéma d'entrée
	if s.config.ValidateInput && s.validator != nil {
		if err := s.validator.ValidateN8NSchema(data); err != nil {
			return nil, fmt.Errorf("input schema validation failed: %w", err)
		}
	}

	// Désérialisation JSON vers structure intermédiaire
	var n8nData N8NWorkflowData
	if err := json.Unmarshal(data, &n8nData); err != nil {
		return nil, fmt.Errorf("JSON deserialization failed: %w", err)
	}

	// Conversion vers format Go
	workflow := s.convertFromN8NFormat(&n8nData)

	// Validation post-désérialisation
	if err := s.validateWorkflowData(workflow); err != nil {
		return nil, fmt.Errorf("converted workflow validation failed: %w", err)
	}

	return workflow, nil
}

// ValidateSchema valide uniquement le schéma JSON
func (s *JSONWorkflowSerializer) ValidateSchema(data []byte) error {
	if s.validator == nil {
		return fmt.Errorf("no schema validator configured")
	}

	return s.validator.ValidateN8NSchema(data)
}

// convertToN8NFormat convertit WorkflowData vers N8NWorkflowData
func (s *JSONWorkflowSerializer) convertToN8NFormat(workflow *WorkflowData) *N8NWorkflowData {
	n8nData := &N8NWorkflowData{
		ID:          workflow.ID,
		Name:        workflow.Name,
		Active:      workflow.Active,
		CreatedAt:   workflow.CreatedAt.Format(time.RFC3339),
		UpdatedAt:   workflow.UpdatedAt.Format(time.RFC3339),
		Tags:        workflow.Tags,
		Settings:    s.convertSettings(workflow.Settings),
		Connections: s.convertConnections(workflow.Connections),
		Nodes:       make([]N8NNode, 0, len(workflow.Nodes)),
	}

	// Conversion des nodes
	for _, node := range workflow.Nodes {
		n8nNode := N8NNode{
			ID:          node.ID,
			Name:        node.Name,
			Type:        node.Type,
			TypeVersion: node.TypeVersion,
			Position:    [2]float64{node.Position.X, node.Position.Y},
			Parameters:  s.convertParameters(node.Parameters),
			Credentials: s.convertCredentials(node.Credentials),
		}

		// Conversion des données spécifiques au node
		if node.Disabled {
			n8nNode.Disabled = &node.Disabled
		}

		n8nData.Nodes = append(n8nData.Nodes, n8nNode)
	}

	return n8nData
}

// convertFromN8NFormat convertit N8NWorkflowData vers WorkflowData
func (s *JSONWorkflowSerializer) convertFromN8NFormat(n8nData *N8NWorkflowData) *WorkflowData {
	workflow := &WorkflowData{
		ID:          n8nData.ID,
		Name:        n8nData.Name,
		Active:      n8nData.Active,
		Tags:        n8nData.Tags,
		Settings:    s.convertSettingsFromN8N(n8nData.Settings),
		Connections: s.convertConnectionsFromN8N(n8nData.Connections),
		Nodes:       make([]WorkflowNode, 0, len(n8nData.Nodes)),
	}

	// Parsing des timestamps
	if createdAt, err := time.Parse(time.RFC3339, n8nData.CreatedAt); err == nil {
		workflow.CreatedAt = createdAt
	} else {
		workflow.CreatedAt = time.Now()
	}

	if updatedAt, err := time.Parse(time.RFC3339, n8nData.UpdatedAt); err == nil {
		workflow.UpdatedAt = updatedAt
	} else {
		workflow.UpdatedAt = time.Now()
	}

	// Conversion des nodes
	for _, n8nNode := range n8nData.Nodes {
		node := WorkflowNode{
			ID:          n8nNode.ID,
			Name:        n8nNode.Name,
			Type:        n8nNode.Type,
			TypeVersion: n8nNode.TypeVersion,
			Position: NodePosition{
				X: n8nNode.Position[0],
				Y: n8nNode.Position[1],
			},
			Parameters:  s.convertParametersFromN8N(n8nNode.Parameters),
			Credentials: s.convertCredentialsFromN8N(n8nNode.Credentials),
		}

		// Gestion des propriétés optionnelles
		if n8nNode.Disabled != nil {
			node.Disabled = *n8nNode.Disabled
		}

		workflow.Nodes = append(workflow.Nodes, node)
	}

	return workflow
}

// Méthodes utilitaires de conversion
func (s *JSONWorkflowSerializer) convertSettings(settings map[string]interface{}) map[string]interface{} {
	if settings == nil {
		return make(map[string]interface{})
	}
	return s.deepCopyMap(settings)
}

func (s *JSONWorkflowSerializer) convertSettingsFromN8N(settings map[string]interface{}) map[string]interface{} {
	if settings == nil {
		return make(map[string]interface{})
	}
	return s.deepCopyMap(settings)
}

func (s *JSONWorkflowSerializer) convertConnections(connections map[string]interface{}) map[string]interface{} {
	if connections == nil {
		return make(map[string]interface{})
	}
	return s.deepCopyMap(connections)
}

func (s *JSONWorkflowSerializer) convertConnectionsFromN8N(connections map[string]interface{}) map[string]interface{} {
	if connections == nil {
		return make(map[string]interface{})
	}
	return s.deepCopyMap(connections)
}

func (s *JSONWorkflowSerializer) convertParameters(params map[string]interface{}) map[string]interface{} {
	if params == nil {
		return make(map[string]interface{})
	}
	return s.deepCopyMap(params)
}

func (s *JSONWorkflowSerializer) convertParametersFromN8N(params map[string]interface{}) map[string]interface{} {
	if params == nil {
		return make(map[string]interface{})
	}
	return s.deepCopyMap(params)
}

func (s *JSONWorkflowSerializer) convertCredentials(creds map[string]string) map[string]string {
	if creds == nil {
		return make(map[string]string)
	}

	result := make(map[string]string)
	for k, v := range creds {
		result[k] = v
	}
	return result
}

func (s *JSONWorkflowSerializer) convertCredentialsFromN8N(creds map[string]string) map[string]string {
	if creds == nil {
		return make(map[string]string)
	}

	result := make(map[string]string)
	for k, v := range creds {
		result[k] = v
	}
	return result
}

// deepCopyMap fait une copie profonde d'une map
func (s *JSONWorkflowSerializer) deepCopyMap(original map[string]interface{}) map[string]interface{} {
	copy := make(map[string]interface{})
	for key, value := range original {
		copy[key] = s.deepCopyValue(value)
	}
	return copy
}

// deepCopyValue fait une copie profonde d'une valeur
func (s *JSONWorkflowSerializer) deepCopyValue(original interface{}) interface{} {
	if original == nil {
		return nil
	}

	switch v := original.(type) {
	case map[string]interface{}:
		return s.deepCopyMap(v)
	case []interface{}:
		copySlice := make([]interface{}, len(v))
		for i, item := range v {
			copySlice[i] = s.deepCopyValue(item)
		}
		return copySlice
	default:
		// Pour les types primitifs, une copie directe suffit
		return v
	}
}

// validateWorkflowData valide les données de workflow
func (s *JSONWorkflowSerializer) validateWorkflowData(workflow *WorkflowData) error {
	if workflow == nil {
		return fmt.Errorf("workflow cannot be nil")
	}

	if workflow.ID == "" {
		return fmt.Errorf("workflow ID cannot be empty")
	}

	if workflow.Name == "" {
		return fmt.Errorf("workflow name cannot be empty")
	}

	// Validation des nodes
	for i, node := range workflow.Nodes {
		if err := s.validateNode(&node, i); err != nil {
			return fmt.Errorf("node %d validation failed: %w", i, err)
		}
	}

	return nil
}

// validateNode valide un node individuel
func (s *JSONWorkflowSerializer) validateNode(node *WorkflowNode, index int) error {
	if node.ID == "" {
		return fmt.Errorf("node ID cannot be empty")
	}

	if node.Name == "" {
		return fmt.Errorf("node name cannot be empty")
	}

	if node.Type == "" {
		return fmt.Errorf("node type cannot be empty")
	}

	return nil
}
