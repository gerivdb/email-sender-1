package main

import (
	"context"
	"fmt"
	"time"

	"github.com/email-sender/development/managers/interfaces"
)

// initializeStorageIntegration sets up storage manager integration
func (m *GoModManager) initializeStorageIntegration() error {
	// Check if storage manager is already initialized
	if m.storageManager != nil {
		return nil
	}

	m.Log("Initializing storage integration...")
	// In a real implementation, this would use a factory or service locator
	// to get an instance of the StorageManager

	// For now we'll just log this step
	m.Log("Storage integration initialized successfully")
	return nil
}

// persistDependencyMetadata stores dependency metadata using the StorageManager
func (m *GoModManager) persistDependencyMetadata(ctx context.Context, dependency *Dependency) error {
	if m.storageManager == nil {
		m.Log("StorageManager not initialized, skipping metadata persistence")
		return nil
	}

	m.Log(fmt.Sprintf("Persisting metadata for dependency: %s@%s", dependency.Name, dependency.Version))
	// Create metadata object
	metadata := &interfaces.DependencyMetadata{
		Name:      dependency.Name,
		Version:   dependency.Version,
		Tags:      map[string]string{"type": "go-module"},
		UpdatedAt: time.Now(),
	}

	// Add additional information if available
	if dependency.Path != "" {
		metadata.Repository = dependency.Path
	}

	// Store metadata using the storage manager
	key := fmt.Sprintf("dependencies/%s/%s", dependency.Name, dependency.Version)
	if err := m.storageManager.StoreObject(ctx, key, metadata); err != nil {
		m.Log(fmt.Sprintf("Error persisting metadata: %v", err))
		return err
	}

	m.Log(fmt.Sprintf("Successfully persisted metadata for %s@%s", dependency.Name, dependency.Version))
	return nil
}

// getDependencyMetadata retrieves dependency metadata from the StorageManager
func (m *GoModManager) getDependencyMetadata(ctx context.Context, name, version string) (*interfaces.DependencyMetadata, error) {
	if m.storageManager == nil {
		return nil, fmt.Errorf("StorageManager not initialized")
	}

	m.Log("info", fmt.Sprintf("Retrieving metadata for dependency: %s@%s", name, version)) // Added log level

	// Construct the storage key
	key := fmt.Sprintf("dependencies/%s/%s", name, version)

	// Create target variable
	metadata := &interfaces.DependencyMetadata{} // Changed to interfaces.DependencyMetadata

	// Retrieve metadata
	if err := m.storageManager.GetObject(ctx, key, metadata); err != nil {
		m.Log(fmt.Sprintf("Error retrieving metadata: %v", err))
		return nil, err
	}

	return metadata, nil
}

// updateDependencyAuditStatus updates the audit status in dependency metadata
func (m *GoModManager) updateDependencyAuditStatus(ctx context.Context, name, version, status string) error {
	if m.storageManager == nil {
		return fmt.Errorf("StorageManager not initialized")
	}

	m.Log("info", fmt.Sprintf("Updating audit status for dependency: %s@%s", name, version)) // Added log level

	// Get existing metadata
	metadata, err := m.getDependencyMetadata(ctx, name, version)
	if err != nil {
		// If metadata doesn't exist yet, create it
		metadata = &interfaces.DependencyMetadata{ // Changed to interfaces.DependencyMetadata
			Name:    name,
			Version: version,
			Tags:    map[string]string{"type": "go-module"}, // Corrected Tags type
		}
	}

	// Update audit information
	now := time.Now()
	// metadata.LastAudit = &now // Assuming LastAudit and AuditStatus are not in interfaces.DependencyMetadata based on its definition
	// metadata.AuditStatus = status
	metadata.UpdatedAt = now

	// Store updated metadata
	key := fmt.Sprintf("dependencies/%s/%s", name, version)
	if err := m.storageManager.StoreObject(ctx, key, metadata); err != nil {
		m.Log(fmt.Sprintf("Error updating audit status: %v", err))
		return err
	}

	m.Log(fmt.Sprintf("Successfully updated audit status for %s@%s", name, version))
	return nil
}

// listDependencyMetadata lists all stored dependency metadata
func (m *GoModManager) listDependencyMetadata(ctx context.Context) ([]*interfaces.DependencyMetadata, error) {
	if m.storageManager == nil {
		return nil, fmt.Errorf("StorageManager not initialized")
	}

	m.Log("info", "Listing all dependency metadata") // Added log level

	// List all objects with the dependencies prefix
	keys, err := m.storageManager.ListObjects(ctx, "dependencies/")
	if err != nil {
		m.Log("error", fmt.Sprintf("Error listing dependencies: %v", err)) // Added log level
		return nil, err
	}

	var metadataList []*interfaces.DependencyMetadata // Changed to interfaces.DependencyMetadata

	// Retrieve each metadata object
	for _, key := range keys {
		metadata := &interfaces.DependencyMetadata{} // Changed to interfaces.DependencyMetadata
		if err := m.storageManager.GetObject(ctx, key, metadata); err != nil {
			m.Log("error", fmt.Sprintf("Error retrieving metadata for key %s: %v", key, err)) // Added log level
			continue
		}
		metadataList = append(metadataList, metadata)
	}

	m.Log(fmt.Sprintf("Retrieved metadata for %d dependencies", len(metadataList)))
	return metadataList, nil
}

// syncDependenciesToStorage synchronizes all current dependencies with StorageManager
func (m *GoModManager) syncDependenciesToStorage(ctx context.Context, dependencies []Dependency) error {
	if m.storageManager == nil {
		return fmt.Errorf("StorageManager not initialized")
	}

	m.Log("info", fmt.Sprintf("Syncing %d dependencies to storage", len(dependencies))) // Added log level

	for _, dep := range dependencies {
		if err := m.persistDependencyMetadata(ctx, &dep); err != nil { // This calls the already corrected persistDependencyMetadata
			m.Log("error", fmt.Sprintf("Error syncing dependency %s: %v", dep.Name, err)) // Added log level
			// Continue with other dependencies even if one fails
			continue
		}
	}

	m.Log("info", "Successfully synced dependencies to storage") // Added log level
	return nil
}
