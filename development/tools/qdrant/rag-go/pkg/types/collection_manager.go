package types

import (
	"encoding/json"
	"fmt"
	"sync"
)

// CollectionManager handles operations on collections
type CollectionManager struct {
	// collections is a map of collection name to Collection
	collections map[string]*Collection

	// mutex protects the collections map
	mutex sync.RWMutex
}

// NewCollectionManager creates a new collection manager
func NewCollectionManager() *CollectionManager {
	return &CollectionManager{
		collections: make(map[string]*Collection),
		mutex:       sync.RWMutex{},
	}
}

// CreateCollection creates a new collection with the given configuration
func (cm *CollectionManager) CreateCollection(config CollectionConfig) (*Collection, error) {
	// Validate the configuration
	if err := ValidateCollectionConfig(config); err != nil {
		return nil, fmt.Errorf("invalid collection configuration: %w", err)
	}

	// Create the collection
	collection, err := NewCollectionFromConfig(config)
	if err != nil {
		return nil, fmt.Errorf("failed to create collection: %w", err)
	}

	// Add the collection to the manager
	cm.mutex.Lock()
	defer cm.mutex.Unlock()

	// Check if collection already exists
	if _, exists := cm.collections[config.Name]; exists {
		return nil, fmt.Errorf("collection already exists: %s", config.Name)
	}

	cm.collections[config.Name] = collection
	return collection, nil
}

// DeleteCollection deletes a collection with the given name
func (cm *CollectionManager) DeleteCollection(name string) error {
	cm.mutex.Lock()
	defer cm.mutex.Unlock()

	// Check if collection exists
	if _, exists := cm.collections[name]; !exists {
		return fmt.Errorf("collection not found: %s", name)
	}

	delete(cm.collections, name)
	return nil
}

// GetCollection gets a collection with the given name
func (cm *CollectionManager) GetCollection(name string) (*Collection, error) {
	cm.mutex.RLock()
	defer cm.mutex.RUnlock()

	// Check if collection exists
	collection, exists := cm.collections[name]
	if !exists {
		return nil, fmt.Errorf("collection not found: %s", name)
	}

	return collection, nil
}

// ListCollections lists all collections
func (cm *CollectionManager) ListCollections() []*Collection {
	cm.mutex.RLock()
	defer cm.mutex.RUnlock()

	collections := make([]*Collection, 0, len(cm.collections))
	for _, collection := range cm.collections {
		collections = append(collections, collection)
	}

	return collections
}

// CollectionExists checks if a collection exists
func (cm *CollectionManager) CollectionExists(name string) bool {
	cm.mutex.RLock()
	defer cm.mutex.RUnlock()

	_, exists := cm.collections[name]
	return exists
}

// GetCollectionCount returns the number of collections
func (cm *CollectionManager) GetCollectionCount() int {
	cm.mutex.RLock()
	defer cm.mutex.RUnlock()

	return len(cm.collections)
}

// UpdateCollection updates a collection with new data
func (cm *CollectionManager) UpdateCollection(name string, updated *Collection) error {
	cm.mutex.Lock()
	defer cm.mutex.Unlock()

	// Check if collection exists
	collection, exists := cm.collections[name]
	if !exists {
		return fmt.Errorf("collection not found: %s", name)
	}

	// Update the collection
	collection.Update(updated)
	return nil
}

// UpdateDocumentCount updates the document count for a collection
func (cm *CollectionManager) UpdateDocumentCount(name string, count int) error {
	cm.mutex.Lock()
	defer cm.mutex.Unlock()

	// Check if collection exists
	collection, exists := cm.collections[name]
	if !exists {
		return fmt.Errorf("collection not found: %s", name)
	}

	// Update the document count
	collection.UpdateDocumentCount(count)
	return nil
}

// IncrementDocumentCount increments the document count for a collection
func (cm *CollectionManager) IncrementDocumentCount(name string, increment int) error {
	cm.mutex.Lock()
	defer cm.mutex.Unlock()

	// Check if collection exists
	collection, exists := cm.collections[name]
	if !exists {
		return fmt.Errorf("collection not found: %s", name)
	}

	// Increment the document count
	collection.IncrementDocumentCount(increment)
	return nil
}

// ToJSON serializes the collection manager to JSON
func (cm *CollectionManager) ToJSON() ([]byte, error) {
	cm.mutex.RLock()
	defer cm.mutex.RUnlock()

	return json.Marshal(cm.collections)
}

// FromJSON deserializes the collection manager from JSON
func (cm *CollectionManager) FromJSON(data []byte) error {
	collections := make(map[string]*Collection)
	if err := json.Unmarshal(data, &collections); err != nil {
		return fmt.Errorf("failed to unmarshal collection manager: %w", err)
	}

	// Validate each collection
	for name, collection := range collections {
		if err := collection.Validate(); err != nil {
			return fmt.Errorf("invalid collection %s: %w", name, err)
		}
	}

	cm.mutex.Lock()
	defer cm.mutex.Unlock()
	cm.collections = collections

	return nil
}

// CreateOrUpdateCollection creates a new collection or updates an existing one
func (cm *CollectionManager) CreateOrUpdateCollection(config CollectionConfig) (*Collection, error) {
	cm.mutex.Lock()
	defer cm.mutex.Unlock()

	// Check if collection exists
	collection, exists := cm.collections[config.Name]
	if exists {
		// Update the existing collection
		newCollection, err := NewCollectionFromConfig(config)
		if err != nil {
			return nil, fmt.Errorf("failed to create updated collection: %w", err)
		}

		collection.Update(newCollection)
		return collection, nil
	}

	// Create a new collection
	newCollection, err := NewCollectionFromConfig(config)
	if err != nil {
		return nil, fmt.Errorf("failed to create collection: %w", err)
	}

	cm.collections[config.Name] = newCollection
	return newCollection, nil
}
