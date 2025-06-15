package storage

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"path/filepath"
	"strings"
	"time"
)

// === MÉTHODES UTILITAIRES POUR LA VECTORISATION ===

// VectorizationMetrics métriques de vectorisation
type VectorizationMetrics struct {
	IndexedConfigurations int            `json:"indexed_configurations"`
	IndexedSchemas        int            `json:"indexed_schemas"`
	IndexedTables         int            `json:"indexed_tables"`
	LastIndexUpdate       time.Time      `json:"last_index_update"`
	VectorizationEnabled  bool           `json:"vectorization_enabled"`
	Collections           map[string]int `json:"collections"` // collection_name -> count
}

// EnableVectorization active la vectorisation
func (sm *StorageManagerImpl) EnableVectorization() error {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	sm.vectorizationEnabled = true
	sm.logger.Printf("Storage Manager vectorization enabled")
	return nil
}

// DisableVectorization désactive la vectorisation
func (sm *StorageManagerImpl) DisableVectorization() error {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	sm.vectorizationEnabled = false
	sm.logger.Printf("Storage Manager vectorization disabled")
	return nil
}

// GetVectorizationStatus retourne le statut de la vectorisation
func (sm *StorageManagerImpl) GetVectorizationStatus() bool {
	sm.mu.RLock()
	defer sm.mu.RUnlock()
	return sm.vectorizationEnabled
}

// GetVectorizationMetrics retourne les métriques de vectorisation
func (sm *StorageManagerImpl) GetVectorizationMetrics() VectorizationMetrics {
	sm.configIndexer.mu.RLock()
	configCount := len(sm.configIndexer.indexedConfigs)
	sm.configIndexer.mu.RUnlock()

	sm.schemaVectorizer.mu.RLock()
	schemaCount := len(sm.schemaVectorizer.schemas)
	sm.schemaVectorizer.mu.RUnlock()

	return VectorizationMetrics{
		IndexedConfigurations: configCount,
		IndexedSchemas:        schemaCount,
		IndexedTables:         0, // À implémenter
		LastIndexUpdate:       time.Now(),
		VectorizationEnabled:  sm.vectorizationEnabled,
		Collections: map[string]int{
			"configurations":   configCount,
			"database_schemas": schemaCount,
			"database_tables":  0,
		},
	}
}

// detectConfigType détecte le type d'un fichier de configuration
func (sm *StorageManagerImpl) detectConfigType(filePath string) string {
	ext := strings.ToLower(filepath.Ext(filePath))
	switch ext {
	case ".json":
		return "json"
	case ".yaml", ".yml":
		return "yaml"
	case ".env":
		return "env"
	case ".toml":
		return "toml"
	case ".ini":
		return "ini"
	default:
		return "unknown"
	}
}

// parseConfigContent parse le contenu d'un fichier de configuration
func (sm *StorageManagerImpl) parseConfigContent(content []byte, configType string) (map[string]interface{}, error) {
	var data map[string]interface{}

	switch configType {
	case "json":
		err := json.Unmarshal(content, &data)
		if err != nil {
			return nil, fmt.Errorf("failed to parse JSON: %w", err)
		}
	case "yaml", "yml":
		err := yaml.Unmarshal(content, &data)
		if err != nil {
			return nil, fmt.Errorf("failed to parse YAML: %w", err)
		}
	case "env":
		data = sm.parseEnvContent(string(content))
	default:
		// Pour les types non supportés, stocker le contenu brut
		data = map[string]interface{}{
			"raw_content": string(content),
			"type":        configType,
		}
	}

	return data, nil
}

// parseEnvContent parse un fichier .env
func (sm *StorageManagerImpl) parseEnvContent(content string) map[string]interface{} {
	data := make(map[string]interface{})
	lines := strings.Split(content, "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.SplitN(line, "=", 2)
		if len(parts) == 2 {
			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])
			// Supprimer les guillemets si présents
			if len(value) >= 2 && value[0] == '"' && value[len(value)-1] == '"' {
				value = value[1 : len(value)-1]
			}
			data[key] = value
		}
	}

	return data
}

// configToText convertit une configuration en texte pour la vectorisation
func (sm *StorageManagerImpl) configToText(config map[string]interface{}, configType string) string {
	var text strings.Builder
	
	text.WriteString(fmt.Sprintf("Configuration type: %s\n", configType))
	
	for key, value := range config {
		text.WriteString(fmt.Sprintf("%s: %v\n", key, value))
	}
	
	return text.String()
}

// generateConfigTags génère des tags pour une configuration
func (sm *StorageManagerImpl) generateConfigTags(config map[string]interface{}, configType string) []string {
	tags := []string{configType}
	
	// Ajouter des tags basés sur les clés
	for key := range config {
		keyLower := strings.ToLower(key)
		if strings.Contains(keyLower, "database") || strings.Contains(keyLower, "db") {
			tags = append(tags, "database")
		}
		if strings.Contains(keyLower, "server") || strings.Contains(keyLower, "port") {
			tags = append(tags, "server")
		}
		if strings.Contains(keyLower, "auth") || strings.Contains(keyLower, "token") {
			tags = append(tags, "authentication")
		}
		if strings.Contains(keyLower, "cache") || strings.Contains(keyLower, "redis") {
			tags = append(tags, "cache")
		}
	}
	
	return tags
}

// isConfigFile vérifie si un fichier est un fichier de configuration
func (sm *StorageManagerImpl) isConfigFile(filePath string) bool {
	configExts := []string{".json", ".yaml", ".yml", ".env", ".toml", ".ini", ".conf", ".config"}
	ext := strings.ToLower(filepath.Ext(filePath))
	
	for _, configExt := range configExts {
		if ext == configExt {
			return true
		}
	}
	
	return false
}

// extractDatabaseSchema extrait le schéma d'une base de données
func (sm *StorageManagerImpl) extractDatabaseSchema(ctx context.Context, schemaName string) (*DatabaseSchema, error) {
	schema := &DatabaseSchema{
		Name:      schemaName,
		Version:   "1.0",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
		Tables:    []TableSchema{},
		Relations: []RelationSchema{},
		Indexes:   []IndexSchema{},
		Constraints: []ConstraintSchema{},
	}

	// Requête pour récupérer les tables
	tablesQuery := `
		SELECT table_name, table_comment 
		FROM information_schema.tables 
		WHERE table_schema = $1 AND table_type = 'BASE TABLE'
	`
	
	rows, err := sm.db.QueryContext(ctx, tablesQuery, schemaName)
	if err != nil {
		return nil, fmt.Errorf("failed to query tables: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var tableName, comment string
		err := rows.Scan(&tableName, &comment)
		if err != nil {
			continue
		}

		table, err := sm.extractTableSchema(ctx, schemaName, tableName, comment)
		if err != nil {
			sm.logger.Printf("Failed to extract table schema %s.%s: %v", schemaName, tableName, err)
			continue
		}

		schema.Tables = append(schema.Tables, *table)
	}

	// Extraire les relations (clés étrangères)
	schema.Relations = sm.extractRelations(ctx, schemaName)

	// Extraire les indexes
	schema.Indexes = sm.extractIndexes(ctx, schemaName)

	return schema, nil
}

// extractTableSchema extrait le schéma d'une table
func (sm *StorageManagerImpl) extractTableSchema(ctx context.Context, schemaName, tableName, comment string) (*TableSchema, error) {
	table := &TableSchema{
		Name:        tableName,
		Comment:     comment,
		Columns:     []ColumnSchema{},
		PrimaryKey:  []string{},
		ForeignKeys: []ForeignKey{},
		Indexes:     []string{},
	}

	// Requête pour récupérer les colonnes
	columnsQuery := `
		SELECT column_name, data_type, is_nullable, column_default, column_comment
		FROM information_schema.columns 
		WHERE table_schema = $1 AND table_name = $2
		ORDER BY ordinal_position
	`
	
	rows, err := sm.db.QueryContext(ctx, columnsQuery, schemaName, tableName)
	if err != nil {
		return nil, fmt.Errorf("failed to query columns: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var colName, dataType, isNullable, comment string
		var defaultValue sql.NullString
		
		err := rows.Scan(&colName, &dataType, &isNullable, &defaultValue, &comment)
		if err != nil {
			continue
		}

		column := ColumnSchema{
			Name:     colName,
			Type:     dataType,
			Nullable: isNullable == "YES",
			Comment:  comment,
		}
		
		if defaultValue.Valid {
			column.DefaultValue = defaultValue.String
		}

		table.Columns = append(table.Columns, column)
	}

	return table, nil
}

// extractRelations extrait les relations entre tables
func (sm *StorageManagerImpl) extractRelations(ctx context.Context, schemaName string) []RelationSchema {
	var relations []RelationSchema

	query := `
		SELECT 
			tc.table_name,
			kcu.column_name,
			ccu.table_name AS foreign_table_name,
			ccu.column_name AS foreign_column_name
		FROM information_schema.table_constraints AS tc 
		JOIN information_schema.key_column_usage AS kcu
		  ON tc.constraint_name = kcu.constraint_name
		  AND tc.table_schema = kcu.table_schema
		JOIN information_schema.constraint_column_usage AS ccu
		  ON ccu.constraint_name = tc.constraint_name
		  AND ccu.table_schema = tc.table_schema
		WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = $1
	`

	rows, err := sm.db.QueryContext(ctx, query, schemaName)
	if err != nil {
		sm.logger.Printf("Failed to query relations: %v", err)
		return relations
	}
	defer rows.Close()

	for rows.Next() {
		var fromTable, fromColumn, toTable, toColumn string
		err := rows.Scan(&fromTable, &fromColumn, &toTable, &toColumn)
		if err != nil {
			continue
		}

		relation := RelationSchema{
			FromTable:  fromTable,
			ToTable:    toTable,
			FromColumn: fromColumn,
			ToColumn:   toColumn,
			Type:       "many-to-one", // Par défaut
		}

		relations = append(relations, relation)
	}

	return relations
}

// extractIndexes extrait les indexes
func (sm *StorageManagerImpl) extractIndexes(ctx context.Context, schemaName string) []IndexSchema {
	var indexes []IndexSchema

	query := `
		SELECT 
			i.relname as index_name,
			t.relname as table_name,
			ix.indisunique as is_unique,
			array_agg(a.attname) as column_names
		FROM pg_class t
		JOIN pg_index ix ON t.oid = ix.indrelid
		JOIN pg_class i ON i.oid = ix.indexrelid
		JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey)
		JOIN pg_namespace n ON n.oid = t.relnamespace
		WHERE n.nspname = $1
		GROUP BY i.relname, t.relname, ix.indisunique
	`

	rows, err := sm.db.QueryContext(ctx, query, schemaName)
	if err != nil {
		sm.logger.Printf("Failed to query indexes: %v", err)
		return indexes
	}
	defer rows.Close()

	for rows.Next() {
		var indexName, tableName string
		var isUnique bool
		var columns []string

		err := rows.Scan(&indexName, &tableName, &isUnique, &columns)
		if err != nil {
			continue
		}

		index := IndexSchema{
			Name:    indexName,
			Table:   tableName,
			Columns: columns,
			Unique:  isUnique,
			Type:    "btree", // Par défaut
		}

		indexes = append(indexes, index)
	}

	return indexes
}

// indexTableSchema indexe un schéma de table individuellement
func (sm *StorageManagerImpl) indexTableSchema(ctx context.Context, schemaName string, table TableSchema) error {
	// Créer un texte descriptif de la table
	tableText := fmt.Sprintf("Table: %s\nSchema: %s\nComment: %s\nColumns: ", 
		table.Name, schemaName, table.Comment)
	
	for _, col := range table.Columns {
		tableText += fmt.Sprintf("%s (%s), ", col.Name, col.Type)
	}

	// Générer l'embedding
	embedding, err := sm.vectorizer.GenerateEmbedding(ctx, tableText)
	if err != nil {
		return fmt.Errorf("failed to generate table embedding: %w", err)
	}

	// Payload pour Qdrant
	payload := map[string]interface{}{
		"schema_name": schemaName,
		"table_name":  table.Name,
		"comment":     table.Comment,
		"columns":     len(table.Columns),
		"primary_key": table.PrimaryKey,
		"indexes":     table.Indexes,
	}

	// Stocker dans Qdrant
	tableID := fmt.Sprintf("%s.%s", schemaName, table.Name)
	err = sm.qdrant.StoreVector(ctx, "database_tables", tableID, embedding, payload)
	if err != nil {
		return fmt.Errorf("failed to store table vector: %w", err)
	}

	return nil
}
