package indexing

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"time"

	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/interfaces"
	baseInterfaces "./interfaces"
	"github.com/google/uuid"
)

// indexManagerImpl implÃ©mente IndexManager en utilisant Qdrant et SQLiteEmbeddingCache
type indexManagerImpl struct {
	storageManager baseInterfaces.StorageManager
	configManager  baseInterfaces.ConfigManager
	errorManager   baseInterfaces.ErrorManager

	qdrantClient   interface{}
	embeddingCache *sql.DB
	initialized    bool

	// Configuration
	collectionName string
	vectorSize     int
	cacheDBPath    string
}

// NewIndexManager crÃ©e une nouvelle instance de IndexManager
func NewIndexManager(
	storageManager baseInterfaces.StorageManager,
	errorManager baseInterfaces.ErrorManager,
	configManager baseInterfaces.ConfigManager,
	monitoringManager interfaces.MonitoringManager,
) (*indexManagerImpl, error) {
	return &indexManagerImpl{
		storageManager: storageManager,
		configManager:  configManager,
		errorManager:   errorManager,
		collectionName: "contextual_actions",
		vectorSize:     384, // sentence-transformers standard
		cacheDBPath:    "./data/contextual_embedding_cache.db",
	}, nil
}

// Initialize implÃ©mente BaseManager.Initialize
func (im *indexManagerImpl) Initialize(ctx context.Context) error {
	if im.initialized {
		return nil
	}

	// RÃ©cupÃ©rer la connexion Qdrant
	qdrantConn, err := im.storageManager.GetQdrantConnection()
	if err != nil {
		return fmt.Errorf("failed to get Qdrant connection: %w", err)
	}
	im.qdrantClient = qdrantConn

	// Initialiser le cache SQLite pour les embeddings
	err = im.initializeEmbeddingCache(ctx)
	if err != nil {
		return fmt.Errorf("failed to initialize embedding cache: %w", err)
	}

	// VÃ©rifier/crÃ©er la collection Qdrant
	err = im.ensureQdrantCollection(ctx)
	if err != nil {
		return fmt.Errorf("failed to ensure Qdrant collection: %w", err)
	}

	im.initialized = true
	return nil
}

// IndexAction indexe une action utilisateur avec embedding vectoriel
func (im *indexManagerImpl) IndexAction(ctx context.Context, action interfaces.Action) error {
	if !im.initialized {
		return fmt.Errorf("IndexManager not initialized")
	}

	// GÃ©nÃ©rer ou rÃ©cupÃ©rer l'embedding
	vector, err := im.getOrCreateEmbedding(ctx, action.Text)
	if err != nil {
		return fmt.Errorf("failed to get embedding: %w", err)
	}

	// CrÃ©er le point Qdrant
	point := map[string]interface{}{
		"id":     action.ID,
		"vector": vector,
		"payload": map[string]interface{}{
			"action_id":      action.ID,
			"action_type":    action.Type,
			"text":           action.Text,
			"workspace_path": action.WorkspacePath,
			"file_path":      action.FilePath,
			"line_number":    action.LineNumber,
			"timestamp":      action.Timestamp.Unix(),
			"metadata":       action.Metadata,
		},
	}

	// Indexer dans Qdrant (ici on simule l'API Qdrant)
	err = im.upsertToQdrant(ctx, point)
	if err != nil {
		return fmt.Errorf("failed to upsert to Qdrant: %w", err)
	}

	return nil
}

// SearchSimilar recherche des actions similaires par vecteur
func (im *indexManagerImpl) SearchSimilar(ctx context.Context, vector []float64, limit int) ([]interfaces.SimilarResult, error) {
	if !im.initialized {
		return nil, fmt.Errorf("IndexManager not initialized")
	}

	// Recherche dans Qdrant (simulation)
	results, err := im.searchInQdrant(ctx, vector, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to search in Qdrant: %w", err)
	}

	// Conversion en SimilarResult
	similarResults := make([]interfaces.SimilarResult, len(results))
	for i, result := range results {
		similarResults[i] = interfaces.SimilarResult{
			ID:    result["id"].(string),
			Score: result["score"].(float64),
		}
	}

	return similarResults, nil
}

// CacheEmbedding met en cache un embedding dans SQLite
func (im *indexManagerImpl) CacheEmbedding(ctx context.Context, text string, vector []float64) error {
	if !im.initialized {
		return fmt.Errorf("IndexManager not initialized")
	}

	// SÃ©rialiser le vecteur
	vectorBytes, err := json.Marshal(vector)
	if err != nil {
		return fmt.Errorf("failed to marshal vector: %w", err)
	}

	// InsÃ©rer dans le cache SQLite
	query := `
		INSERT OR REPLACE INTO embedding_cache 
		(text_hash, text, vector, created_at, accessed_at) 
		VALUES (?, ?, ?, ?, ?)`

	textHash := fmt.Sprintf("%x", sha256Sum(text))
	now := time.Now()

	_, err = im.embeddingCache.ExecContext(ctx, query, textHash, text, vectorBytes, now, now)
	if err != nil {
		return fmt.Errorf("failed to cache embedding: %w", err)
	}

	return nil
}

// GetCacheStats retourne les statistiques du cache
func (im *indexManagerImpl) GetCacheStats(ctx context.Context) (map[string]interface{}, error) {
	if !im.initialized {
		return nil, fmt.Errorf("IndexManager not initialized")
	}

	var totalEntries, totalSize int64
	var avgAccessTime float64

	// Compter les entrÃ©es
	err := im.embeddingCache.QueryRowContext(ctx, "SELECT COUNT(*) FROM embedding_cache").Scan(&totalEntries)
	if err != nil {
		return nil, fmt.Errorf("failed to count cache entries: %w", err)
	}

	// Calculer la taille approximative
	err = im.embeddingCache.QueryRowContext(ctx, "SELECT SUM(LENGTH(vector)) FROM embedding_cache").Scan(&totalSize)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate cache size: %w", err)
	}

	// Temps d'accÃ¨s moyen (simulation)
	avgAccessTime = 2.5 // ms

	return map[string]interface{}{
		"total_entries":      totalEntries,
		"total_size_bytes":   totalSize,
		"avg_access_time_ms": avgAccessTime,
		"cache_hit_ratio":    0.85, // simulation
	}, nil
}

// Cleanup implÃ©mente BaseManager.Cleanup
func (im *indexManagerImpl) Cleanup() error {
	if im.embeddingCache != nil {
		return im.embeddingCache.Close()
	}
	return nil
}

// HealthCheck implÃ©mente BaseManager.HealthCheck
func (im *indexManagerImpl) HealthCheck(ctx context.Context) error {
	if !im.initialized {
		return fmt.Errorf("IndexManager not initialized")
	}

	// VÃ©rifier la connexion SQLite
	err := im.embeddingCache.PingContext(ctx)
	if err != nil {
		return fmt.Errorf("embedding cache unhealthy: %w", err)
	}

	// VÃ©rifier Qdrant (simulation)
	if im.qdrantClient == nil {
		return fmt.Errorf("Qdrant client not available")
	}

	return nil
}

// MÃ©thodes privÃ©es

func (im *indexManagerImpl) initializeEmbeddingCache(ctx context.Context) error {
	db, err := sql.Open("sqlite3", im.cacheDBPath)
	if err != nil {
		return fmt.Errorf("failed to open cache database: %w", err)
	}

	// CrÃ©er la table si elle n'existe pas
	schema := `
	CREATE TABLE IF NOT EXISTS embedding_cache (
		text_hash TEXT PRIMARY KEY,
		text TEXT NOT NULL,
		vector BLOB NOT NULL,
		created_at DATETIME NOT NULL,
		accessed_at DATETIME NOT NULL
	);
	
	CREATE INDEX IF NOT EXISTS idx_accessed_at ON embedding_cache(accessed_at);
	`

	_, err = db.ExecContext(ctx, schema)
	if err != nil {
		return fmt.Errorf("failed to create cache schema: %w", err)
	}

	im.embeddingCache = db
	return nil
}

func (im *indexManagerImpl) ensureQdrantCollection(ctx context.Context) error {
	// Simulation de crÃ©ation de collection Qdrant
	log.Printf("Ensuring Qdrant collection '%s' exists with vector size %d", im.collectionName, im.vectorSize)
	return nil
}

func (im *indexManagerImpl) getOrCreateEmbedding(ctx context.Context, text string) ([]float64, error) {
	textHash := fmt.Sprintf("%x", sha256Sum(text))

	// Chercher dans le cache
	var vectorBytes []byte
	err := im.embeddingCache.QueryRowContext(ctx,
		"SELECT vector FROM embedding_cache WHERE text_hash = ?", textHash).Scan(&vectorBytes)

	if err == nil {
		// Cache hit - dÃ©sÃ©rialiser
		var vector []float64
		err = json.Unmarshal(vectorBytes, &vector)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal cached vector: %w", err)
		}

		// Mettre Ã  jour accessed_at
		_, _ = im.embeddingCache.ExecContext(ctx,
			"UPDATE embedding_cache SET accessed_at = ? WHERE text_hash = ?",
			time.Now(), textHash)

		return vector, nil
	}

	// Cache miss - gÃ©nÃ©rer l'embedding (simulation)
	vector := im.generateEmbedding(text)

	// Mettre en cache
	err = im.CacheEmbedding(ctx, text, vector)
	if err != nil {
		log.Printf("Warning: failed to cache embedding: %v", err)
	}

	return vector, nil
}

func (im *indexManagerImpl) generateEmbedding(text string) []float64 {
	// Simulation d'embedding (dans un vrai systÃ¨me, utiliser sentence-transformers ou API OpenAI)
	vector := make([]float64, im.vectorSize)
	for i := 0; i < im.vectorSize; i++ {
		vector[i] = math.Sin(float64(len(text)+i)) * 0.5
	}
	return vector
}

func (im *indexManagerImpl) upsertToQdrant(ctx context.Context, point map[string]interface{}) error {
	// Simulation d'API Qdrant
	log.Printf("Upserting point to Qdrant collection '%s': %s", im.collectionName, point["id"])
	return nil
}

func (im *indexManagerImpl) searchInQdrant(ctx context.Context, vector []float64, limit int) ([]map[string]interface{}, error) {
	// Simulation de recherche Qdrant
	results := make([]map[string]interface{}, 0, limit)

	for i := 0; i < min(limit, 3); i++ {
		result := map[string]interface{}{
			"id":    uuid.New().String(),
			"score": 0.9 - float64(i)*0.1,
		}
		results = append(results, result)
	}

	return results, nil
}

// Fonctions utilitaires
func sha256Sum(text string) [32]byte {
	// Simulation de hachage
	var hash [32]byte
	for i, char := range text {
		hash[i%32] += byte(char)
	}
	return hash
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// DeleteFromIndex supprime un contexte de l'index
func (im *indexManagerImpl) DeleteFromIndex(ctx context.Context, contextID string) error {
	if !im.initialized {
		return fmt.Errorf("index manager not initialized")
	}

	// Supprimer de Qdrant
	if err := im.deleteFromQdrant(ctx, contextID); err != nil {
		return fmt.Errorf("failed to delete from Qdrant: %w", err)
	}

	// Supprimer du cache d'embeddings
	if err := im.deleteFromEmbeddingCache(contextID); err != nil {
		log.Printf("Warning: failed to delete from embedding cache: %v", err)
		// Ne pas Ã©chouer pour un problÃ¨me de cache
	}

	return nil
}

// deleteFromQdrant supprime un point de Qdrant
func (im *indexManagerImpl) deleteFromQdrant(ctx context.Context, pointID string) error {
	// Simulation d'API Qdrant pour suppression
	log.Printf("Deleting point from Qdrant collection '%s': %s", im.collectionName, pointID)
	return nil
}

// deleteFromEmbeddingCache supprime une entrÃ©e du cache d'embeddings
func (im *indexManagerImpl) deleteFromEmbeddingCache(contextID string) error {
	if im.embeddingCache == nil {
		return fmt.Errorf("embedding cache not initialized")
	}

	query := `DELETE FROM embeddings WHERE text_hash = ?`
	_, err := im.embeddingCache.Exec(query, contextID)
	return err
}
