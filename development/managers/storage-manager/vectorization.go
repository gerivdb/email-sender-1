package storage

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"gopkg.in/yaml.v2"
)

// === IMPLÉMENTATION PHASE 4.2.1.1: AUTO-INDEXATION DES FICHIERS DE CONFIGURATION ===

// IndexConfiguration indexe un fichier de configuration
func (sm *StorageManagerImpl) IndexConfiguration(ctx context.Context, filePath string) error {
	if !sm.vectorizationEnabled {
		return fmt.Errorf("vectorization is disabled")
	}

	// Lire le fichier de configuration
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("failed to read config file %s: %w", filePath, err)
	}

	// Déterminer le type de configuration
	configType := sm.detectConfigType(filePath)
	
	// Parser le contenu selon le type
	configData, err := sm.parseConfigContent(content, configType)
	if err != nil {
		return fmt.Errorf("failed to parse config %s: %w", filePath, err)
	}

	// Générer l'embedding du contenu
	configText := sm.configToText(configData, configType)
	embedding, err := sm.vectorizer.GenerateConfigEmbedding(ctx, configData)
	if err != nil {
		return fmt.Errorf("failed to generate embedding for %s: %w", filePath, err)
	}

	// Créer les métadonnées
	metadata := &ConfigMetadata{
		FilePath:     filePath,
		ConfigType:   configType,
		LastModified: time.Now(),
		Embedding:    embedding,
		Content:      configData,
		Tags:         sm.generateConfigTags(configData, configType),
	}

	// Stocker dans l'indexeur
	sm.configIndexer.mu.Lock()
	sm.configIndexer.indexedConfigs[filePath] = metadata
	sm.configIndexer.mu.Unlock()

	// Stocker dans Qdrant
	payload := map[string]interface{}{
		"file_path":     filePath,
		"config_type":   configType,
		"content":       configData,
		"tags":          metadata.Tags,
		"last_modified": metadata.LastModified.Unix(),
	}

	err = sm.qdrant.StoreVector(ctx, "configurations", filePath, embedding, payload)
	if err != nil {
		return fmt.Errorf("failed to store config vector: %w", err)
	}

	sm.logger.Printf("Configuration indexed: %s (type: %s)", filePath, configType)
	return nil
}

// UpdateConfigurationIndex met à jour l'index d'un fichier de configuration
func (sm *StorageManagerImpl) UpdateConfigurationIndex(ctx context.Context, filePath string) error {
	// Vérifier si le fichier existe toujours
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return sm.RemoveConfigurationIndex(ctx, filePath)
	}

	// Ré-indexer le fichier
	return sm.IndexConfiguration(ctx, filePath)
}

// RemoveConfigurationIndex supprime un fichier de l'index
func (sm *StorageManagerImpl) RemoveConfigurationIndex(ctx context.Context, filePath string) error {
	// Supprimer de l'indexeur local
	sm.configIndexer.mu.Lock()
	delete(sm.configIndexer.indexedConfigs, filePath)
	sm.configIndexer.mu.Unlock()

	// Supprimer de Qdrant
	err := sm.qdrant.DeleteVector(ctx, "configurations", filePath)
	if err != nil {
		return fmt.Errorf("failed to delete config vector: %w", err)
	}

	sm.logger.Printf("Configuration removed from index: %s", filePath)
	return nil
}

// WatchConfigurationDirectory surveille un répertoire pour les changements de configuration
func (sm *StorageManagerImpl) WatchConfigurationDirectory(ctx context.Context, dirPath string) error {
	// Ajouter le chemin aux chemins surveillés
	sm.configIndexer.mu.Lock()
	sm.configIndexer.watchedPaths = append(sm.configIndexer.watchedPaths, dirPath)
	sm.configIndexer.mu.Unlock()

	// Scanner le répertoire pour indexer les fichiers existants
	err := filepath.Walk(dirPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && sm.isConfigFile(path) {
			return sm.IndexConfiguration(ctx, path)
		}

		return nil
	})

	if err != nil {
		return fmt.Errorf("failed to index directory %s: %w", dirPath, err)
	}

	sm.logger.Printf("Started watching configuration directory: %s", dirPath)
	return nil
}

// === IMPLÉMENTATION PHASE 4.2.1.2: VECTORISATION DES SCHÉMAS DE BASE DE DONNÉES ===

// IndexDatabaseSchema indexe un schéma de base de données
func (sm *StorageManagerImpl) IndexDatabaseSchema(ctx context.Context, schemaName string) error {
	if !sm.vectorizationEnabled {
		return fmt.Errorf("vectorization is disabled")
	}

	// Extraire le schéma de la base de données
	schema, err := sm.extractDatabaseSchema(ctx, schemaName)
	if err != nil {
		return fmt.Errorf("failed to extract schema %s: %w", schemaName, err)
	}

	// Générer l'embedding du schéma
	embedding, err := sm.vectorizer.GenerateSchemaEmbedding(ctx, *schema)
	if err != nil {
		return fmt.Errorf("failed to generate schema embedding: %w", err)
	}

	// Stocker dans le vectoriseur de schémas
	sm.schemaVectorizer.mu.Lock()
	sm.schemaVectorizer.schemas[schemaName] = schema
	sm.schemaVectorizer.schemaEmbeddings[schemaName] = embedding
	sm.schemaVectorizer.mu.Unlock()

	// Stocker dans Qdrant
	payload := map[string]interface{}{
		"schema_name": schemaName,
		"tables":      len(schema.Tables),
		"relations":   len(schema.Relations),
		"indexes":     len(schema.Indexes),
		"version":     schema.Version,
		"updated_at":  schema.UpdatedAt.Unix(),
	}

	err = sm.qdrant.StoreVector(ctx, "database_schemas", schemaName, embedding, payload)
	if err != nil {
		return fmt.Errorf("failed to store schema vector: %w", err)
	}

	// Indexer également chaque table individuellement
	for _, table := range schema.Tables {
		err = sm.indexTableSchema(ctx, schemaName, table)
		if err != nil {
			sm.logger.Printf("Failed to index table %s.%s: %v", schemaName, table.Name, err)
		}
	}

	sm.logger.Printf("Database schema indexed: %s (%d tables)", schemaName, len(schema.Tables))
	return nil
}

// UpdateSchemaIndex met à jour l'index d'un schéma
func (sm *StorageManagerImpl) UpdateSchemaIndex(ctx context.Context, schemaName string) error {
	return sm.IndexDatabaseSchema(ctx, schemaName)
}

// GetSchemaEmbedding récupère l'embedding d'un schéma
func (sm *StorageManagerImpl) GetSchemaEmbedding(ctx context.Context, schemaName string) ([]float32, error) {
	sm.schemaVectorizer.mu.RLock()
	embedding, exists := sm.schemaVectorizer.schemaEmbeddings[schemaName]
	sm.schemaVectorizer.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("schema embedding not found: %s", schemaName)
	}

	return embedding, nil
}

// FindSimilarSchemas trouve des schémas similaires
func (sm *StorageManagerImpl) FindSimilarSchemas(ctx context.Context, schemaName string, threshold float64) ([]SearchResult, error) {
	embedding, err := sm.GetSchemaEmbedding(ctx, schemaName)
	if err != nil {
		return nil, err
	}

	// Rechercher dans Qdrant
	results, err := sm.qdrant.SearchVector(ctx, "database_schemas", embedding, 10)
	if err != nil {
		return nil, fmt.Errorf("failed to search similar schemas: %w", err)
	}

	var searchResults []SearchResult
	for _, result := range results {
		if float64(result.Score) >= threshold && result.ID != schemaName {
			searchResults = append(searchResults, SearchResult{
				Type:     "schema",
				ID:       result.ID,
				Name:     result.ID,
				Score:    result.Score,
				Content:  nil, // Schema content serait trop volumineux
				Metadata: result.Payload,
			})
		}
	}

	return searchResults, nil
}

// === IMPLÉMENTATION PHASE 4.2.1.3: RECHERCHE SÉMANTIQUE ===

// SearchConfigurations recherche dans les configurations
func (sm *StorageManagerImpl) SearchConfigurations(ctx context.Context, query string, limit int) ([]SearchResult, error) {
	if !sm.vectorizationEnabled {
		return nil, fmt.Errorf("vectorization is disabled")
	}

	// Générer l'embedding de la requête
	queryEmbedding, err := sm.vectorizer.GenerateEmbedding(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to generate query embedding: %w", err)
	}

	// Rechercher dans Qdrant
	results, err := sm.qdrant.SearchVector(ctx, "configurations", queryEmbedding, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to search configurations: %w", err)
	}

	var searchResults []SearchResult
	for _, result := range results {
		searchResults = append(searchResults, SearchResult{
			Type:        "configuration",
			ID:          result.ID,
			Name:        filepath.Base(result.ID),
			Score:       result.Score,
			Content:     result.Payload,
			Metadata:    result.Payload,
			Path:        result.ID,
			Description: fmt.Sprintf("Configuration file: %s", result.Payload["config_type"]),
		})
	}

	return searchResults, nil
}

// SearchSchemas recherche dans les schémas
func (sm *StorageManagerImpl) SearchSchemas(ctx context.Context, query string, limit int) ([]SearchResult, error) {
	if !sm.vectorizationEnabled {
		return nil, fmt.Errorf("vectorization is disabled")
	}

	queryEmbedding, err := sm.vectorizer.GenerateEmbedding(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to generate query embedding: %w", err)
	}

	results, err := sm.qdrant.SearchVector(ctx, "database_schemas", queryEmbedding, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to search schemas: %w", err)
	}

	var searchResults []SearchResult
	for _, result := range results {
		searchResults = append(searchResults, SearchResult{
			Type:        "schema",
			ID:          result.ID,
			Name:        result.ID,
			Score:       result.Score,
			Content:     nil,
			Metadata:    result.Payload,
			Description: fmt.Sprintf("Database schema with %v tables", result.Payload["tables"]),
		})
	}

	return searchResults, nil
}

// SearchTables recherche dans les tables
func (sm *StorageManagerImpl) SearchTables(ctx context.Context, query string, limit int) ([]SearchResult, error) {
	if !sm.vectorizationEnabled {
		return nil, fmt.Errorf("vectorization is disabled")
	}

	queryEmbedding, err := sm.vectorizer.GenerateEmbedding(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to generate query embedding: %w", err)
	}

	results, err := sm.qdrant.SearchVector(ctx, "database_tables", queryEmbedding, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to search tables: %w", err)
	}

	var searchResults []SearchResult
	for _, result := range results {
		searchResults = append(searchResults, SearchResult{
			Type:        "table",
			ID:          result.ID,
			Name:        result.Payload["table_name"].(string),
			Score:       result.Score,
			Content:     result.Payload,
			Metadata:    result.Payload,
			Description: fmt.Sprintf("Table %s in schema %s", result.Payload["table_name"], result.Payload["schema_name"]),
		})
	}

	return searchResults, nil
}

// SearchAll recherche dans tous les types
func (sm *StorageManagerImpl) SearchAll(ctx context.Context, query string, limit int) ([]SearchResult, error) {
	var allResults []SearchResult

	// Rechercher dans les configurations
	configResults, err := sm.SearchConfigurations(ctx, query, limit/3)
	if err == nil {
		allResults = append(allResults, configResults...)
	}

	// Rechercher dans les schémas
	schemaResults, err := sm.SearchSchemas(ctx, query, limit/3)
	if err == nil {
		allResults = append(allResults, schemaResults...)
	}

	// Rechercher dans les tables
	tableResults, err := sm.SearchTables(ctx, query, limit/3)
	if err == nil {
		allResults = append(allResults, tableResults...)
	}

	// Trier par score décroissant
	for i := 0; i < len(allResults)-1; i++ {
		for j := i + 1; j < len(allResults); j++ {
			if allResults[i].Score < allResults[j].Score {
				allResults[i], allResults[j] = allResults[j], allResults[i]
			}
		}
	}

	// Limiter les résultats
	if len(allResults) > limit {
		allResults = allResults[:limit]
	}

	return allResults, nil
}
