// SPDX-License-Identifier: MIT
// Package docmanager - QDrant Vectorizer Implementation
package docmanager

import (
	"encoding/json"
	"fmt"
	"time"
)

// TASK ATOMIQUE 3.1.5.3.2 - QDrant implementation

// QDrantClient interface pour abstraction du client QDrant
type QDrantClient interface {
	// Collection operations
	CreateCollection(name string, vectorSize int) error
	DeleteCollection(name string) error
	GetCollectionInfo(name string) (*QDrantCollectionInfo, error)

	// Point operations
	UpsertPoints(collection string, points []QDrantPoint) error
	GetPoints(collection string, ids []string) ([]QDrantPoint, error)
	DeletePoints(collection string, ids []string) error
	SearchPoints(collection string, vector []float64, limit int, filter map[string]interface{}) (*QDrantSearchResponse, error)

	// Health and monitoring
	GetHealth() (*QDrantHealth, error)
	GetCollections() ([]string, error)
	Close() error
}

// QDrantCollectionInfo informations sur une collection QDrant
type QDrantCollectionInfo struct {
	Name        string                 `json:"name"`
	VectorSize  int                    `json:"vector_size"`
	Distance    string                 `json:"distance"`
	PointsCount int64                  `json:"points_count"`
	Config      map[string]interface{} `json:"config"`
	Status      string                 `json:"status"`
}

// QDrantPoint point de données QDrant
type QDrantPoint struct {
	ID      string                 `json:"id"`
	Vector  []float64              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
	Version int                    `json:"version,omitempty"`
}

// QDrantSearchResponse réponse de recherche QDrant
type QDrantSearchResponse struct {
	Result []QDrantSearchResult `json:"result"`
	Time   float64              `json:"time"`
	Status string               `json:"status"`
}

// QDrantSearchResult résultat de recherche QDrant
type QDrantSearchResult struct {
	ID      string                 `json:"id"`
	Score   float64                `json:"score"`
	Payload map[string]interface{} `json:"payload"`
	Vector  []float64              `json:"vector,omitempty"`
}

// QDrantHealth état de santé QDrant
type QDrantHealth struct {
	Status  string `json:"status"`
	Version string `json:"version"`
	Commit  string `json:"commit"`
}

// QDrantVectorizer implémentation QDrant du vectorizer
// Implementation specific to QDrant but satisfies interface
type QDrantVectorizer struct {
	client         QDrantClient
	collectionName string
	vectorSize     int
	config         VectorizerConfig
	connected      bool
	embeddingModel EmbeddingModel
}

// EmbeddingModel interface pour les modèles d'embedding
type EmbeddingModel interface {
	GenerateEmbedding(text string) ([]float64, error)
	GetModelInfo() ModelInfo
}

// ModelInfo informations sur le modèle
type ModelInfo struct {
	Name        string
	Version     string
	VectorSize  int
	MaxTokens   int
	Description string
}

// MockQDrantClient implémentation mock pour les tests
type MockQDrantClient struct {
	collections map[string]*QDrantCollectionInfo
	points      map[string]map[string]QDrantPoint // collection -> id -> point
	connected   bool
	health      *QDrantHealth
}

// NewMockQDrantClient crée un client QDrant mock
func NewMockQDrantClient() *MockQDrantClient {
	return &MockQDrantClient{
		collections: make(map[string]*QDrantCollectionInfo),
		points:      make(map[string]map[string]QDrantPoint),
		connected:   true,
		health: &QDrantHealth{
			Status:  "ok",
			Version: "mock-1.0.0",
			Commit:  "mock-commit",
		},
	}
}

// CreateCollection crée une collection
func (mqc *MockQDrantClient) CreateCollection(name string, vectorSize int) error {
	if !mqc.connected {
		return fmt.Errorf("qdrant not connected")
	}

	mqc.collections[name] = &QDrantCollectionInfo{
		Name:        name,
		VectorSize:  vectorSize,
		Distance:    "cosine",
		PointsCount: 0,
		Config:      map[string]interface{}{},
		Status:      "ready",
	}

	mqc.points[name] = make(map[string]QDrantPoint)
	return nil
}

// DeleteCollection supprime une collection
func (mqc *MockQDrantClient) DeleteCollection(name string) error {
	if !mqc.connected {
		return fmt.Errorf("qdrant not connected")
	}

	delete(mqc.collections, name)
	delete(mqc.points, name)
	return nil
}

// GetCollectionInfo récupère les informations d'une collection
func (mqc *MockQDrantClient) GetCollectionInfo(name string) (*QDrantCollectionInfo, error) {
	if !mqc.connected {
		return nil, fmt.Errorf("qdrant not connected")
	}

	info, exists := mqc.collections[name]
	if !exists {
		return nil, fmt.Errorf("collection not found: %s", name)
	}

	// Mise à jour du compte de points
	if points, ok := mqc.points[name]; ok {
		info.PointsCount = int64(len(points))
	}

	return info, nil
}

// UpsertPoints insère ou met à jour des points
func (mqc *MockQDrantClient) UpsertPoints(collection string, points []QDrantPoint) error {
	if !mqc.connected {
		return fmt.Errorf("qdrant not connected")
	}

	collectionPoints, exists := mqc.points[collection]
	if !exists {
		return fmt.Errorf("collection not found: %s", collection)
	}

	for _, point := range points {
		collectionPoints[point.ID] = point
	}

	return nil
}

// GetPoints récupère des points par ID
func (mqc *MockQDrantClient) GetPoints(collection string, ids []string) ([]QDrantPoint, error) {
	if !mqc.connected {
		return nil, fmt.Errorf("qdrant not connected")
	}

	collectionPoints, exists := mqc.points[collection]
	if !exists {
		return nil, fmt.Errorf("collection not found: %s", collection)
	}

	var result []QDrantPoint
	for _, id := range ids {
		if point, ok := collectionPoints[id]; ok {
			result = append(result, point)
		}
	}

	return result, nil
}

// DeletePoints supprime des points
func (mqc *MockQDrantClient) DeletePoints(collection string, ids []string) error {
	if !mqc.connected {
		return fmt.Errorf("qdrant not connected")
	}

	collectionPoints, exists := mqc.points[collection]
	if !exists {
		return fmt.Errorf("collection not found: %s", collection)
	}

	for _, id := range ids {
		delete(collectionPoints, id)
	}

	return nil
}

// SearchPoints recherche des points similaires
func (mqc *MockQDrantClient) SearchPoints(collection string, vector []float64, limit int, filter map[string]interface{}) (*QDrantSearchResponse, error) {
	if !mqc.connected {
		return nil, fmt.Errorf("qdrant not connected")
	}

	collectionPoints, exists := mqc.points[collection]
	if !exists {
		return nil, fmt.Errorf("collection not found: %s", collection)
	}

	var results []QDrantSearchResult
	count := 0

	// Simulation simple: retourne tous les points avec score décroissant
	for id, point := range collectionPoints {
		if count >= limit {
			break
		}

		score := 0.9 - float64(count)*0.1
		if score < 0.1 {
			score = 0.1
		}

		result := QDrantSearchResult{
			ID:      id,
			Score:   score,
			Payload: point.Payload,
			Vector:  point.Vector,
		}

		results = append(results, result)
		count++
	}

	return &QDrantSearchResponse{
		Result: results,
		Time:   0.05, // temps simulé
		Status: "ok",
	}, nil
}

// GetHealth retourne l'état de santé
func (mqc *MockQDrantClient) GetHealth() (*QDrantHealth, error) {
	if !mqc.connected {
		return nil, fmt.Errorf("qdrant not connected")
	}
	return mqc.health, nil
}

// GetCollections retourne la liste des collections
func (mqc *MockQDrantClient) GetCollections() ([]string, error) {
	if !mqc.connected {
		return nil, fmt.Errorf("qdrant not connected")
	}

	var collections []string
	for name := range mqc.collections {
		collections = append(collections, name)
	}
	return collections, nil
}

// Close ferme la connexion
func (mqc *MockQDrantClient) Close() error {
	mqc.connected = false
	return nil
}

// SimpleEmbeddingModel modèle d'embedding simple pour les tests
type SimpleEmbeddingModel struct {
	info ModelInfo
}

// NewSimpleEmbeddingModel crée un modèle simple
func NewSimpleEmbeddingModel(vectorSize int) *SimpleEmbeddingModel {
	return &SimpleEmbeddingModel{
		info: ModelInfo{
			Name:        "simple-embedding",
			Version:     "1.0.0",
			VectorSize:  vectorSize,
			MaxTokens:   512,
			Description: "Simple embedding model for testing",
		},
	}
}

// GenerateEmbedding génère un embedding simple
func (sem *SimpleEmbeddingModel) GenerateEmbedding(text string) ([]float64, error) {
	embedding := make([]float64, sem.info.VectorSize)
	for i := range embedding {
		embedding[i] = float64((len(text)+i)%256) / 256.0
	}
	return embedding, nil
}

// GetModelInfo retourne les informations du modèle
func (sem *SimpleEmbeddingModel) GetModelInfo() ModelInfo {
	return sem.info
}

// NewQDrantVectorizer crée un nouveau vectorizer QDrant
func NewQDrantVectorizer(config VectorizerConfig) (*QDrantVectorizer, error) {
	// Pour les tests, on utilise un mock client
	var client QDrantClient
	if config.Host == "mock" || config.Host == "" {
		client = NewMockQDrantClient()
	} else {
		return nil, fmt.Errorf("real QDrant client not implemented yet")
	}

	qv := &QDrantVectorizer{
		client:         client,
		collectionName: config.Collection,
		vectorSize:     config.VectorSize,
		config:         config,
		connected:      true,
		embeddingModel: NewSimpleEmbeddingModel(config.VectorSize),
	}

	// Créer la collection si elle n'existe pas
	err := qv.ensureCollection()
	if err != nil {
		return nil, fmt.Errorf("failed to ensure collection: %w", err)
	}

	return qv, nil
}

// ensureCollection s'assure que la collection existe
func (qv *QDrantVectorizer) ensureCollection() error {
	_, err := qv.client.GetCollectionInfo(qv.collectionName)
	if err != nil {
		// Collection n'existe pas, la créer
		return qv.client.CreateCollection(qv.collectionName, qv.vectorSize)
	}
	return nil
}

// GenerateEmbedding génère un embedding
func (qv *QDrantVectorizer) GenerateEmbedding(text string) ([]float64, error) {
	if !qv.connected {
		return nil, ErrVectorizerUnavailable
	}
	return qv.embeddingModel.GenerateEmbedding(text)
}

// GenerateEmbeddingWithOptions génère un embedding avec options
func (qv *QDrantVectorizer) GenerateEmbeddingWithOptions(text string, options VectorizationOptions) ([]float64, VectorMetadata, error) {
	embedding, err := qv.GenerateEmbedding(text)
	if err != nil {
		return nil, VectorMetadata{}, err
	}

	modelInfo := qv.embeddingModel.GetModelInfo()
	metadata := VectorMetadata{
		VectorSize:    len(embedding),
		EmbeddingType: "qdrant",
		ModelVersion:  modelInfo.Version,
		CreatedAt:     time.Now(),
		Quality:       0.92, // qualité simulée pour QDrant
	}

	return embedding, metadata, nil
}

// IndexDocument indexe un document
func (qv *QDrantVectorizer) IndexDocument(doc *Document) error {
	if !qv.connected {
		return ErrVectorizerUnavailable
	}

	embedding, err := qv.GenerateEmbedding(string(doc.Content))
	if err != nil {
		return err
	}

	// Créer le payload avec les métadonnées du document
	payload := map[string]interface{}{
		"document_id": doc.ID,
		"path":        doc.Path,
		"version":     doc.Version,
		"content":     string(doc.Content),
		"indexed_at":  time.Now().Unix(),
	}

	// Ajouter les métadonnées du document
	if doc.Metadata != nil {
		for key, value := range doc.Metadata {
			payload[key] = value
		}
	}

	point := QDrantPoint{
		ID:      doc.ID,
		Vector:  embedding,
		Payload: payload,
		Version: doc.Version,
	}

	return qv.client.UpsertPoints(qv.collectionName, []QDrantPoint{point})
}

// IndexDocumentWithOptions indexe un document avec options
func (qv *QDrantVectorizer) IndexDocumentWithOptions(doc *Document, options VectorizationOptions) error {
	return qv.IndexDocument(doc) // version simplifiée
}

// RemoveDocument supprime un document de l'index
func (qv *QDrantVectorizer) RemoveDocument(id string) error {
	if !qv.connected {
		return ErrVectorizerUnavailable
	}
	return qv.client.DeletePoints(qv.collectionName, []string{id})
}

// UpdateDocument met à jour un document
func (qv *QDrantVectorizer) UpdateDocument(doc *Document) error {
	return qv.IndexDocument(doc) // UpsertPoints gère la mise à jour
}

// SearchSimilar recherche des documents similaires
func (qv *QDrantVectorizer) SearchSimilar(vector []float64, limit int) ([]*Document, error) {
	if !qv.connected {
		return nil, ErrVectorizerUnavailable
	}

	response, err := qv.client.SearchPoints(qv.collectionName, vector, limit, nil)
	if err != nil {
		return nil, err
	}

	var documents []*Document
	for _, result := range response.Result {
		doc := &Document{
			ID:      result.ID,
			Path:    getString(result.Payload, "path"),
			Content: []byte(getString(result.Payload, "content")),
			Version: getInt(result.Payload, "version"),
		}

		// Reconstruire les métadonnées
		metadata := make(map[string]interface{})
		for key, value := range result.Payload {
			if key != "document_id" && key != "path" && key != "content" && key != "version" && key != "indexed_at" {
				metadata[key] = value
			}
		}
		doc.Metadata = metadata

		documents = append(documents, doc)
	}

	return documents, nil
}

// SearchSimilarWithOptions recherche avec options avancées
func (qv *QDrantVectorizer) SearchSimilarWithOptions(vector []float64, options SearchOptions) ([]*SimilarityResult, error) {
	if !qv.connected {
		return nil, ErrVectorizerUnavailable
	}

	response, err := qv.client.SearchPoints(qv.collectionName, vector, options.Limit, options.FilterBy)
	if err != nil {
		return nil, err
	}

	var results []*SimilarityResult
	for i, result := range response.Result {
		if result.Score < options.MinScore {
			continue
		}

		doc := &Document{
			ID:      result.ID,
			Path:    getString(result.Payload, "path"),
			Content: []byte(getString(result.Payload, "content")),
			Version: getInt(result.Payload, "version"),
		}

		// Reconstruire les métadonnées
		metadata := make(map[string]interface{})
		for key, value := range result.Payload {
			if key != "document_id" && key != "path" && key != "content" && key != "version" && key != "indexed_at" {
				metadata[key] = value
			}
		}
		doc.Metadata = metadata

		similarityResult := &SimilarityResult{
			Document: doc,
			Score:    result.Score,
			Distance: 1.0 - result.Score,
			Metadata: VectorMetadata{
				DocumentID:    result.ID,
				VectorSize:    len(result.Vector),
				EmbeddingType: "qdrant",
				ModelVersion:  qv.embeddingModel.GetModelInfo().Version,
				Quality:       0.92,
			},
			Rank: i + 1,
		}

		results = append(results, similarityResult)
	}

	return results, nil
}

// SearchByText recherche par texte
func (qv *QDrantVectorizer) SearchByText(text string, limit int) ([]*Document, error) {
	vector, err := qv.GenerateEmbedding(text)
	if err != nil {
		return nil, err
	}
	return qv.SearchSimilar(vector, limit)
}

// SearchByTextWithOptions recherche par texte avec options
func (qv *QDrantVectorizer) SearchByTextWithOptions(text string, options SearchOptions) ([]*SimilarityResult, error) {
	vector, err := qv.GenerateEmbedding(text)
	if err != nil {
		return nil, err
	}
	return qv.SearchSimilarWithOptions(vector, options)
}

// GetIndexStats retourne les statistiques de l'index
func (qv *QDrantVectorizer) GetIndexStats() (IndexStats, error) {
	if !qv.connected {
		return IndexStats{}, ErrVectorizerUnavailable
	}

	info, err := qv.client.GetCollectionInfo(qv.collectionName)
	if err != nil {
		return IndexStats{}, err
	}

	modelInfo := qv.embeddingModel.GetModelInfo()

	return IndexStats{
		TotalDocuments:  info.PointsCount,
		TotalVectors:    info.PointsCount,
		VectorDimension: info.VectorSize,
		IndexSize:       info.PointsCount * int64(info.VectorSize) * 8, // approximation
		LastUpdated:     time.Now(),
		AverageQuality:  0.92,
		ModelVersion:    modelInfo.Version,
	}, nil
}

// OptimizeIndex optimise l'index QDrant
func (qv *QDrantVectorizer) OptimizeIndex() error {
	// QDrant optimise automatiquement, donc no-op
	return nil
}

// ReindexAll réindexe tous les documents
func (qv *QDrantVectorizer) ReindexAll() error {
	if !qv.connected {
		return ErrVectorizerUnavailable
	}

	// Récupérer tous les points
	info, err := qv.client.GetCollectionInfo(qv.collectionName)
	if err != nil {
		return err
	}

	// Pour une vraie implémentation, il faudrait paginer
	// Ici on simule juste la réindexation
	_ = info

	return nil
}

// BackupIndex sauvegarde l'index
func (qv *QDrantVectorizer) BackupIndex(path string) error {
	// Pour QDrant, cela nécessiterait d'exporter toute la collection
	// Simulation pour les tests
	return nil
}

// RestoreIndex restaure l'index
func (qv *QDrantVectorizer) RestoreIndex(path string) error {
	// Pour QDrant, cela nécessiterait d'importer une collection
	// Simulation pour les tests
	return nil
}

// IsConnected vérifie la connexion
func (qv *QDrantVectorizer) IsConnected() bool {
	return qv.connected
}

// Ping teste la connexion
func (qv *QDrantVectorizer) Ping() error {
	if !qv.connected {
		return ErrVectorizerUnavailable
	}

	_, err := qv.client.GetHealth()
	return err
}

// GetHealth retourne l'état de santé
func (qv *QDrantVectorizer) GetHealth() (map[string]interface{}, error) {
	if !qv.connected {
		return nil, ErrVectorizerUnavailable
	}

	health, err := qv.client.GetHealth()
	if err != nil {
		return nil, err
	}

	info, err := qv.client.GetCollectionInfo(qv.collectionName)
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"status":            health.Status,
		"version":           health.Version,
		"collection":        qv.collectionName,
		"vector_size":       qv.vectorSize,
		"total_documents":   info.PointsCount,
		"collection_status": info.Status,
	}, nil
}

// Close ferme la connexion
func (qv *QDrantVectorizer) Close() error {
	qv.connected = false
	return qv.client.Close()
}

// Fonctions utilitaires pour extraire des valeurs du payload

func getString(payload map[string]interface{}, key string) string {
	if val, ok := payload[key]; ok {
		if str, ok := val.(string); ok {
			return str
		}
	}
	return ""
}

func getInt(payload map[string]interface{}, key string) int {
	if val, ok := payload[key]; ok {
		switch v := val.(type) {
		case int:
			return v
		case float64:
			return int(v)
		case json.Number:
			if i, err := v.Int64(); err == nil {
				return int(i)
			}
		}
	}
	return 0
}
