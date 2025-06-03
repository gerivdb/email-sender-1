package storage

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"

	"email_sender/cmd/roadmap-cli/types"
)

// StorageManager manages roadmap data persistence
type StorageManager struct {
	storageDir  string
	jsonStorage *JSONStorage
}

// NewStorageManager creates a new storage manager
func NewStorageManager() *StorageManager {
	homeDir, _ := os.UserHomeDir()
	storageDir := filepath.Join(homeDir, ".roadmap-cli")

	// Ensure storage directory exists
	os.MkdirAll(storageDir, 0755)

	// Initialize JSON storage
	jsonPath := filepath.Join(storageDir, "roadmap.json")
	jsonStorage, _ := NewJSONStorage(jsonPath)

	return &StorageManager{
		storageDir:  storageDir,
		jsonStorage: jsonStorage,
	}
}

// GetStorageDir returns the storage directory path
func (sm *StorageManager) GetStorageDir() string {
	return sm.storageDir
}

// SaveRoadmap saves a roadmap to storage
func (sm *StorageManager) SaveRoadmap(roadmap *types.Roadmap) error {
	roadmapFile := filepath.Join(sm.storageDir, "roadmap.json")

	data, err := json.MarshalIndent(roadmap, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(roadmapFile, data, 0644)
}

// LoadRoadmap loads a roadmap from storage
func (sm *StorageManager) LoadRoadmap() (*types.Roadmap, error) {
	roadmapFile := filepath.Join(sm.storageDir, "roadmap.json")

	if _, err := os.Stat(roadmapFile); os.IsNotExist(err) {
		// Return empty roadmap if file doesn't exist
		return &types.Roadmap{
			Version:   "1.0",
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
			Items:     []types.RoadmapItem{},
		}, nil
	}

	data, err := os.ReadFile(roadmapFile)
	if err != nil {
		return nil, err
	}

	var roadmap types.Roadmap
	err = json.Unmarshal(data, &roadmap)
	if err != nil {
		return nil, err
	}

	return &roadmap, nil
}

// SaveAdvancedRoadmap saves an advanced roadmap to storage
func (sm *StorageManager) SaveAdvancedRoadmap(roadmap *types.AdvancedRoadmap) error {
	roadmapFile := filepath.Join(sm.storageDir, "advanced_roadmap.json")

	data, err := json.MarshalIndent(roadmap, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(roadmapFile, data, 0644)
}

// LoadAdvancedRoadmap loads an advanced roadmap from storage
func (sm *StorageManager) LoadAdvancedRoadmap() (*types.AdvancedRoadmap, error) {
	roadmapFile := filepath.Join(sm.storageDir, "advanced_roadmap.json")

	if _, err := os.Stat(roadmapFile); os.IsNotExist(err) {
		// Return empty advanced roadmap if file doesn't exist
		return &types.AdvancedRoadmap{
			Version:     "2.0",
			Name:        "Empty Roadmap",
			Description: "No roadmap data found",
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
			Items:       []types.AdvancedRoadmapItem{},
			Hierarchy:   make(map[string][]string),
			MaxDepth:    5,
		}, nil
	}

	data, err := os.ReadFile(roadmapFile)
	if err != nil {
		return nil, err
	}

	var roadmap types.AdvancedRoadmap
	err = json.Unmarshal(data, &roadmap)
	if err != nil {
		return nil, err
	}

	return &roadmap, nil
}

// CreateItem creates a new roadmap item
func (sm *StorageManager) CreateItem(title, description, status, priority string) (*types.RoadmapItem, error) {
	// Use current time as default target date
	targetDate := time.Now().AddDate(0, 1, 0) // Default to 1 month from now
	item, err := sm.jsonStorage.CreateItem(title, description, priority, targetDate)
	if err != nil {
		return nil, err
	}

	// Update status if provided and different from default
	if status != "" && status != string(types.StatusPlanned) {
		err = sm.jsonStorage.UpdateItemStatus(item.ID, status, 0)
		if err != nil {
			return nil, err
		}
		item.Status = types.Status(status)
	}

	return item, nil
}

// GetAllItems returns all roadmap items
func (sm *StorageManager) GetAllItems() ([]types.RoadmapItem, error) {
	return sm.jsonStorage.GetAllItems()
}

// UpdateItem updates an existing roadmap item
func (sm *StorageManager) UpdateItem(id string, updates map[string]interface{}) error {
	return sm.jsonStorage.UpdateItem(id, updates)
}

// DeleteItem deletes a roadmap item
func (sm *StorageManager) DeleteItem(id string) error {
	return sm.jsonStorage.DeleteItem(id)
}
