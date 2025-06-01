package storage

import (
	"encoding/json"
	"os"
	"time"

	"email_sender/cmd/roadmap-cli/types"

	"github.com/google/uuid"
)

// JSONStorage handles JSON-based persistence for roadmap data
type JSONStorage struct {
	filePath string
	data     *RoadmapData
}

// RoadmapData represents the complete roadmap data structure
type RoadmapData struct {
	Items      []types.RoadmapItem `json:"items"`
	Milestones []types.Milestone   `json:"milestones"`
	LastUpdate time.Time           `json:"last_update"`
}

// NewJSONStorage creates a new JSON-based storage
func NewJSONStorage(filePath string) (*JSONStorage, error) {
	storage := &JSONStorage{
		filePath: filePath,
		data:     &RoadmapData{},
	}
	// Load existing data or create new
	if err := storage.load(); err != nil {
		// If file doesn't exist, create empty data
		storage.data = &RoadmapData{
			Items:      []types.RoadmapItem{},
			Milestones: []types.Milestone{},
			LastUpdate: time.Now(),
		}
	}

	return storage, nil
}

// load reads data from JSON file
func (js *JSONStorage) load() error {
	data, err := os.ReadFile(js.filePath)
	if err != nil {
		return err
	}

	return json.Unmarshal(data, js.data)
}

// save writes data to JSON file
func (js *JSONStorage) save() error {
	js.data.LastUpdate = time.Now()

	data, err := json.MarshalIndent(js.data, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(js.filePath, data, 0644)
}

// CreateItem adds a new roadmap item with basic fields
func (js *JSONStorage) CreateItem(title, description, priority string, targetDate time.Time) (*types.RoadmapItem, error) {
	item := types.RoadmapItem{
		ID:          uuid.New().String(),
		Title:       title,
		Description: description,
		Status:      types.StatusPlanned,
		Progress:    0,
		Priority:    types.Priority(priority),
		TargetDate:  targetDate,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	js.data.Items = append(js.data.Items, item)

	if err := js.save(); err != nil {
		return nil, err
	}

	return &item, nil
}

// CreateEnrichedItem adds a new roadmap item with enriched fields
func (js *JSONStorage) CreateEnrichedItem(options types.EnrichedItemOptions) (*types.RoadmapItem, error) {
	item := types.RoadmapItem{
		ID:            uuid.New().String(),
		Title:         options.Title,
		Description:   options.Description,
		Status:        options.Status,
		Progress:      0,
		Priority:      options.Priority,
		TargetDate:    options.TargetDate,
		CreatedAt:     time.Now(),
		UpdatedAt:     time.Now(),
		Inputs:        options.Inputs,
		Outputs:       options.Outputs,
		Scripts:       options.Scripts,
		Prerequisites: options.Prerequisites,
		Methods:       options.Methods,
		URIs:          options.URIs,
		Tools:         options.Tools,
		Frameworks:    options.Frameworks,
		Complexity:    options.Complexity,
		Effort:        options.Effort,
		BusinessValue: options.BusinessValue,
		TechnicalDebt: options.TechnicalDebt,
		RiskLevel:     options.RiskLevel,
		Tags:          options.Tags,
	}

	js.data.Items = append(js.data.Items, item)

	if err := js.save(); err != nil {
		return nil, err
	}

	return &item, nil
}

// CreateEnrichedItems adds multiple enriched roadmap items in batch
func (js *JSONStorage) CreateEnrichedItems(enrichedItems []types.EnrichedItemOptions) ([]types.RoadmapItem, error) {
	var createdItems []types.RoadmapItem

	for _, options := range enrichedItems {
		item := types.RoadmapItem{
			ID:            uuid.New().String(),
			Title:         options.Title,
			Description:   options.Description,
			Status:        options.Status,
			Progress:      0,
			Priority:      options.Priority,
			TargetDate:    options.TargetDate,
			CreatedAt:     time.Now(),
			UpdatedAt:     time.Now(),
			Inputs:        options.Inputs,
			Outputs:       options.Outputs,
			Scripts:       options.Scripts,
			Prerequisites: options.Prerequisites,
			Methods:       options.Methods,
			URIs:          options.URIs,
			Tools:         options.Tools,
			Frameworks:    options.Frameworks,
			Complexity:    options.Complexity,
			Effort:        options.Effort,
			BusinessValue: options.BusinessValue,
			TechnicalDebt: options.TechnicalDebt,
			RiskLevel:     options.RiskLevel,
			Tags:          options.Tags,
		}

		js.data.Items = append(js.data.Items, item)
		createdItems = append(createdItems, item)
	}

	if err := js.save(); err != nil {
		return nil, err
	}

	return createdItems, nil
}

// GetAllItems returns all roadmap items
func (js *JSONStorage) GetAllItems() ([]types.RoadmapItem, error) {
	return js.data.Items, nil
}

// CreateMilestone adds a new milestone
func (js *JSONStorage) CreateMilestone(title, description string, targetDate time.Time) (*types.Milestone, error) {
	milestone := types.Milestone{
		ID:          uuid.New().String(),
		Title:       title,
		Description: description,
		TargetDate:  targetDate,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	js.data.Milestones = append(js.data.Milestones, milestone)

	if err := js.save(); err != nil {
		return nil, err
	}

	return &milestone, nil
}

// GetAllMilestones returns all milestones
func (js *JSONStorage) GetAllMilestones() ([]types.Milestone, error) {
	return js.data.Milestones, nil
}

// UpdateItemStatus updates an item's status and progress
func (js *JSONStorage) UpdateItemStatus(id, status string, progress int) error {
	for i := range js.data.Items {
		if js.data.Items[i].ID == id {
			js.data.Items[i].Status = types.Status(status)
			js.data.Items[i].Progress = progress
			js.data.Items[i].UpdatedAt = time.Now()
			return js.save()
		}
	}
	return nil // Item not found
}

// DeleteItem removes an item by ID
func (js *JSONStorage) DeleteItem(id string) error {
	for i, item := range js.data.Items {
		if item.ID == id {
			js.data.Items = append(js.data.Items[:i], js.data.Items[i+1:]...)
			return js.save()
		}
	}
	return nil // Item not found
}

// Close is a no-op for JSON storage but maintains interface compatibility
func (js *JSONStorage) Close() error {
	return nil
}
