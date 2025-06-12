package roadmapconnector

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

// DataMapper handles conversion between different data formats
type DataMapper struct {
	mappingConfig *MappingConfig
	transformers  map[string]DataTransformer
}

// MappingConfig defines how to map between data structures
type MappingConfig struct {
	FieldMappings    map[string]FieldMapping      `yaml:"field_mappings"`
	TypeMappings     map[string]string            `yaml:"type_mappings"`
	ValueMappings    map[string]map[string]string `yaml:"value_mappings"`
	DefaultValues    map[string]interface{}       `yaml:"default_values"`
	RequiredFields   []string                     `yaml:"required_fields"`
	OptionalFields   []string                     `yaml:"optional_fields"`
	DateFormat       string                       `yaml:"date_format"`
	TimezoneHandling string                       `yaml:"timezone_handling"`
}

// FieldMapping defines how to map a specific field
type FieldMapping struct {
	SourceField  string      `yaml:"source_field"`
	TargetField  string      `yaml:"target_field"`
	Transform    string      `yaml:"transform"`
	DefaultValue interface{} `yaml:"default_value"`
	Required     bool        `yaml:"required"`
	Validation   string      `yaml:"validation"`
}

// DataTransformer interface for custom data transformations
type DataTransformer interface {
	Transform(input interface{}) (interface{}, error)
	GetName() string
}

// DynamicPlan represents the internal dynamic plan format
type DynamicPlan struct {
	ID        string                 `json:"id"`
	Title     string                 `json:"title"`
	Version   string                 `json:"version"`
	Progress  float64                `json:"progress"`
	Phases    []DynamicPhase         `json:"phases"`
	Tasks     []DynamicTask          `json:"tasks"`
	Metadata  map[string]interface{} `json:"metadata"`
	CreatedAt time.Time              `json:"created_at"`
	UpdatedAt time.Time              `json:"updated_at"`
	Status    string                 `json:"status"`
	Owner     string                 `json:"owner"`
	Tags      []string               `json:"tags"`
}

// DynamicPhase represents a phase in the dynamic format
type DynamicPhase struct {
	ID          string     `json:"id"`
	Name        string     `json:"name"`
	Description string     `json:"description"`
	Status      string     `json:"status"`
	Progress    float64    `json:"progress"`
	StartDate   *time.Time `json:"start_date,omitempty"`
	EndDate     *time.Time `json:"end_date,omitempty"`
	Order       int        `json:"order"`
	TaskIDs     []string   `json:"task_ids"`
}

// DynamicTask represents a task in the dynamic format
type DynamicTask struct {
	ID           string                 `json:"id"`
	Title        string                 `json:"title"`
	Description  string                 `json:"description"`
	Status       string                 `json:"status"`
	Priority     int                    `json:"priority"`
	Progress     float64                `json:"progress"`
	Assignee     string                 `json:"assignee"`
	PhaseID      string                 `json:"phase_id"`
	ParentID     string                 `json:"parent_id,omitempty"`
	Dependencies []string               `json:"dependencies"`
	Metadata     map[string]interface{} `json:"metadata"`
	CreatedAt    time.Time              `json:"created_at"`
	UpdatedAt    time.Time              `json:"updated_at"`
	DueDate      *time.Time             `json:"due_date,omitempty"`
	Tags         []string               `json:"tags"`
}

// MappingResult contains the result of a mapping operation
type MappingResult struct {
	Success         bool                 `json:"success"`
	Result          interface{}          `json:"result"`
	Warnings        []string             `json:"warnings"`
	Errors          []string             `json:"errors"`
	MappedFields    map[string]string    `json:"mapped_fields"`
	UnmappedFields  []string             `json:"unmapped_fields"`
	Transformations []TransformationInfo `json:"transformations"`
}

// TransformationInfo tracks applied transformations
type TransformationInfo struct {
	Field         string      `json:"field"`
	Transformer   string      `json:"transformer"`
	OriginalValue interface{} `json:"original_value"`
	NewValue      interface{} `json:"new_value"`
	Success       bool        `json:"success"`
	Error         string      `json:"error,omitempty"`
}

// Built-in transformers
type StringTransformer struct{}
type DateTransformer struct{}
type StatusTransformer struct{}
type ProgressTransformer struct{}

// NewDataMapper creates a new data mapper with default configuration
func NewDataMapper() *DataMapper {
	mapper := &DataMapper{
		mappingConfig: getDefaultMappingConfig(),
		transformers:  make(map[string]DataTransformer),
	}

	// Register built-in transformers
	mapper.RegisterTransformer(&StringTransformer{})
	mapper.RegisterTransformer(&DateTransformer{})
	mapper.RegisterTransformer(&StatusTransformer{})
	mapper.RegisterTransformer(&ProgressTransformer{})

	return mapper
}

// RegisterTransformer registers a custom data transformer
func (dm *DataMapper) RegisterTransformer(transformer DataTransformer) {
	dm.transformers[transformer.GetName()] = transformer
}

// ConvertToRoadmapFormat converts dynamic plan to roadmap manager format
func (dm *DataMapper) ConvertToRoadmapFormat(dynamicPlan interface{}) (*RoadmapPlan, error) {
	// Convert to DynamicPlan struct if it's not already
	var plan *DynamicPlan
	switch v := dynamicPlan.(type) {
	case *DynamicPlan:
		plan = v
	case DynamicPlan:
		plan = &v
	case map[string]interface{}:
		data, err := json.Marshal(v)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal dynamic plan: %w", err)
		}
		if err := json.Unmarshal(data, &plan); err != nil {
			return nil, fmt.Errorf("failed to unmarshal to DynamicPlan: %w", err)
		}
	default:
		return nil, fmt.Errorf("unsupported dynamic plan type: %T", v)
	}

	// Create roadmap plan
	roadmapPlan := &RoadmapPlan{
		ID:        plan.ID,
		Title:     plan.Title,
		Version:   plan.Version,
		Progress:  plan.Progress,
		Status:    dm.mapStatus(plan.Status),
		Metadata:  plan.Metadata,
		CreatedAt: plan.CreatedAt,
		UpdatedAt: plan.UpdatedAt,
		Tags:      plan.Tags,
		Owner:     plan.Owner,
	}

	// Convert phases
	roadmapPlan.Phases = make([]RoadmapPhase, 0, len(plan.Phases))
	for _, phase := range plan.Phases {
		roadmapPhase := RoadmapPhase{
			ID:          phase.ID,
			Name:        phase.Name,
			Description: phase.Description,
			Status:      dm.mapStatus(phase.Status),
			Progress:    phase.Progress,
			StartDate:   phase.StartDate,
			EndDate:     phase.EndDate,
		}

		// Convert tasks for this phase
		roadmapPhase.Tasks = make([]RoadmapTask, 0)
		for _, task := range plan.Tasks {
			if task.PhaseID == phase.ID {
				roadmapTask := RoadmapTask{
					ID:           task.ID,
					Title:        task.Title,
					Description:  task.Description,
					Status:       dm.mapStatus(task.Status),
					Priority:     task.Priority,
					Assignee:     task.Assignee,
					Tags:         task.Tags,
					CreatedAt:    task.CreatedAt,
					UpdatedAt:    task.UpdatedAt,
					DueDate:      task.DueDate,
					Dependencies: task.Dependencies,
				}

				// Map estimated and actual hours from metadata
				if metadata := task.Metadata; metadata != nil {
					if estimated, ok := metadata["estimated_hours"].(float64); ok {
						roadmapTask.EstimatedHours = int(estimated)
					}
					if actual, ok := metadata["actual_hours"].(float64); ok {
						roadmapTask.ActualHours = int(actual)
					}
				}

				roadmapPhase.Tasks = append(roadmapPhase.Tasks, roadmapTask)
			}
		}

		roadmapPlan.Phases = append(roadmapPlan.Phases, roadmapPhase)
	}

	return roadmapPlan, nil
}

// ConvertFromRoadmapFormat converts roadmap manager format to dynamic plan
func (dm *DataMapper) ConvertFromRoadmapFormat(roadmapPlan *RoadmapPlan) (*DynamicPlan, error) {
	plan := &DynamicPlan{
		ID:        roadmapPlan.ID,
		Title:     roadmapPlan.Title,
		Version:   roadmapPlan.Version,
		Progress:  roadmapPlan.Progress,
		Status:    dm.mapStatusReverse(roadmapPlan.Status),
		Metadata:  roadmapPlan.Metadata,
		CreatedAt: roadmapPlan.CreatedAt,
		UpdatedAt: roadmapPlan.UpdatedAt,
		Tags:      roadmapPlan.Tags,
		Owner:     roadmapPlan.Owner,
	}

	// Convert phases
	plan.Phases = make([]DynamicPhase, 0, len(roadmapPlan.Phases))
	plan.Tasks = make([]DynamicTask, 0)

	for i, phase := range roadmapPlan.Phases {
		dynamicPhase := DynamicPhase{
			ID:          phase.ID,
			Name:        phase.Name,
			Description: phase.Description,
			Status:      dm.mapStatusReverse(phase.Status),
			Progress:    phase.Progress,
			StartDate:   phase.StartDate,
			EndDate:     phase.EndDate,
			Order:       i,
			TaskIDs:     make([]string, 0, len(phase.Tasks)),
		}

		// Convert tasks
		for _, task := range phase.Tasks {
			dynamicTask := DynamicTask{
				ID:           task.ID,
				Title:        task.Title,
				Description:  task.Description,
				Status:       dm.mapStatusReverse(task.Status),
				Priority:     task.Priority,
				Assignee:     task.Assignee,
				PhaseID:      phase.ID,
				Dependencies: task.Dependencies,
				Tags:         task.Tags,
				CreatedAt:    task.CreatedAt,
				UpdatedAt:    task.UpdatedAt,
				DueDate:      task.DueDate,
				Metadata:     make(map[string]interface{}),
			}

			// Store estimated and actual hours in metadata
			dynamicTask.Metadata["estimated_hours"] = float64(task.EstimatedHours)
			dynamicTask.Metadata["actual_hours"] = float64(task.ActualHours)

			plan.Tasks = append(plan.Tasks, dynamicTask)
			dynamicPhase.TaskIDs = append(dynamicPhase.TaskIDs, task.ID)
		}

		plan.Phases = append(plan.Phases, dynamicPhase)
	}

	return plan, nil
}

// MapWithCustomConfig applies custom mapping configuration
func (dm *DataMapper) MapWithCustomConfig(source interface{}, config *MappingConfig) (*MappingResult, error) {
	result := &MappingResult{
		Success:         true,
		Warnings:        []string{},
		Errors:          []string{},
		MappedFields:    make(map[string]string),
		UnmappedFields:  []string{},
		Transformations: []TransformationInfo{},
	}

	// Convert source to map for easier field access
	sourceMap := make(map[string]interface{})
	data, err := json.Marshal(source)
	if err != nil {
		result.Success = false
		result.Errors = append(result.Errors, fmt.Sprintf("Failed to marshal source: %v", err))
		return result, err
	}

	if err := json.Unmarshal(data, &sourceMap); err != nil {
		result.Success = false
		result.Errors = append(result.Errors, fmt.Sprintf("Failed to unmarshal source: %v", err))
		return result, err
	}

	// Apply field mappings
	targetMap := make(map[string]interface{})

	for sourceField, mapping := range config.FieldMappings {
		if sourceValue, exists := sourceMap[sourceField]; exists {
			// Apply transformation if specified
			if mapping.Transform != "" && dm.transformers[mapping.Transform] != nil {
				transformer := dm.transformers[mapping.Transform]
				transformedValue, err := transformer.Transform(sourceValue)

				transformInfo := TransformationInfo{
					Field:         sourceField,
					Transformer:   mapping.Transform,
					OriginalValue: sourceValue,
					NewValue:      transformedValue,
					Success:       err == nil,
				}

				if err != nil {
					transformInfo.Error = err.Error()
					result.Warnings = append(result.Warnings,
						fmt.Sprintf("Transformation failed for field %s: %v", sourceField, err))
				}

				result.Transformations = append(result.Transformations, transformInfo)

				if err == nil {
					targetMap[mapping.TargetField] = transformedValue
				} else {
					targetMap[mapping.TargetField] = sourceValue
				}
			} else {
				targetMap[mapping.TargetField] = sourceValue
			}

			result.MappedFields[sourceField] = mapping.TargetField
		} else if mapping.Required {
			result.Errors = append(result.Errors,
				fmt.Sprintf("Required field %s not found in source", sourceField))
			result.Success = false
		} else if mapping.DefaultValue != nil {
			targetMap[mapping.TargetField] = mapping.DefaultValue
			result.Warnings = append(result.Warnings,
				fmt.Sprintf("Using default value for field %s", mapping.TargetField))
		}
	}

	// Apply default values for missing fields
	for field, defaultValue := range config.DefaultValues {
		if _, exists := targetMap[field]; !exists {
			targetMap[field] = defaultValue
		}
	}

	result.Result = targetMap
	return result, nil
}

// mapStatus maps status values between formats
func (dm *DataMapper) mapStatus(status string) string {
	statusMap := map[string]string{
		"not_started": "pending",
		"in_progress": "in_progress",
		"completed":   "completed",
		"on_hold":     "blocked",
		"cancelled":   "cancelled",
		"archived":    "archived",
	}

	if mapped, exists := statusMap[status]; exists {
		return mapped
	}
	return status
}

// mapStatusReverse maps status values from roadmap format back to dynamic format
func (dm *DataMapper) mapStatusReverse(status string) string {
	statusMap := map[string]string{
		"pending":     "not_started",
		"in_progress": "in_progress",
		"completed":   "completed",
		"blocked":     "on_hold",
		"cancelled":   "cancelled",
		"archived":    "archived",
	}

	if mapped, exists := statusMap[status]; exists {
		return mapped
	}
	return status
}

// getDefaultMappingConfig returns default mapping configuration
func getDefaultMappingConfig() *MappingConfig {
	return &MappingConfig{
		FieldMappings: map[string]FieldMapping{
			"id":         {SourceField: "id", TargetField: "id", Required: true},
			"title":      {SourceField: "title", TargetField: "title", Required: true},
			"version":    {SourceField: "version", TargetField: "version", Required: true},
			"progress":   {SourceField: "progress", TargetField: "progress", Transform: "progress"},
			"status":     {SourceField: "status", TargetField: "status", Transform: "status"},
			"created_at": {SourceField: "created_at", TargetField: "created_at", Transform: "date"},
			"updated_at": {SourceField: "updated_at", TargetField: "updated_at", Transform: "date"},
		},
		TypeMappings: map[string]string{
			"string":  "string",
			"int":     "number",
			"float64": "number",
			"bool":    "boolean",
			"time":    "string",
		},
		DateFormat:       "2006-01-02T15:04:05Z07:00",
		TimezoneHandling: "UTC",
	}
}

// Built-in transformer implementations

func (st *StringTransformer) Transform(input interface{}) (interface{}, error) {
	if str, ok := input.(string); ok {
		return strings.TrimSpace(str), nil
	}
	return fmt.Sprintf("%v", input), nil
}

func (st *StringTransformer) GetName() string {
	return "string"
}

func (dt *DateTransformer) Transform(input interface{}) (interface{}, error) {
	switch v := input.(type) {
	case time.Time:
		return v.Format(time.RFC3339), nil
	case string:
		if t, err := time.Parse(time.RFC3339, v); err == nil {
			return t.Format(time.RFC3339), nil
		}
		return v, nil
	default:
		return input, fmt.Errorf("cannot transform %T to date", input)
	}
}

func (dt *DateTransformer) GetName() string {
	return "date"
}

func (st *StatusTransformer) Transform(input interface{}) (interface{}, error) {
	if status, ok := input.(string); ok {
		return strings.ToLower(strings.TrimSpace(status)), nil
	}
	return input, fmt.Errorf("status must be a string")
}

func (st *StatusTransformer) GetName() string {
	return "status"
}

func (pt *ProgressTransformer) Transform(input interface{}) (interface{}, error) {
	switch v := input.(type) {
	case float64:
		if v < 0 {
			return 0.0, nil
		}
		if v > 100 {
			return 100.0, nil
		}
		return v, nil
	case int:
		progress := float64(v)
		if progress < 0 {
			return 0.0, nil
		}
		if progress > 100 {
			return 100.0, nil
		}
		return progress, nil
	default:
		return 0.0, fmt.Errorf("progress must be a number")
	}
}

func (pt *ProgressTransformer) GetName() string {
	return "progress"
}
