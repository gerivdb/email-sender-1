// SPDX-License-Identifier: MIT
// Package docmanager - Document Vectorizer Interface
package docmanager

import (
	"time"
)

// TASK ATOMIQUE 3.1.5.3.1 - Vectorization abstraction

// VectorMetadata métadonnées d'un vecteur
type VectorMetadata struct {
	DocumentID    string
	VectorSize    int
	EmbeddingType string
	ModelVersion  string
	CreatedAt     time.Time
	Quality       float64
}

// SimilarityResult résultat de recherche de similarité
type SimilarityResult struct {
	Document *Document
	Score    float64
	Distance float64
	Metadata VectorMetadata
	Rank     int
}

// VectorizationOptions options pour la vectorisation
type VectorizationOptions struct {
	Model           string
	MaxTokens       int
	ChunkSize       int
	OverlapSize     int
	NormalizeVector bool
	IncludeMetadata bool
}

// SearchOptions options pour la recherche vectorielle
type SearchOptions struct {
	Limit           int
	MinScore        float64
	IncludeMetadata bool
	FilterBy        map[string]interface{}
	ExcludeIDs      []string
}

// IndexStats statistiques de l'index vectoriel
type IndexStats struct {
	TotalDocuments  int64
	TotalVectors    int64
	VectorDimension int
	IndexSize       int64
	LastUpdated     time.Time
	AverageQuality  float64
	ModelVersion    string
}

// DocumentVectorizer interface abstraite pour les opérations vectorielles
// Validation: Interface abstracts vector database operations
type DocumentVectorizer interface {
	// Core vectorization operations
	GenerateEmbedding(text string) ([]float64, error)
	GenerateEmbeddingWithOptions(text string, options VectorizationOptions) ([]float64, VectorMetadata, error)

	// Document indexing operations
	IndexDocument(doc *Document) error
	IndexDocumentWithOptions(doc *Document, options VectorizationOptions) error
	RemoveDocument(id string) error
	UpdateDocument(doc *Document) error

	// Search operations
	SearchSimilar(vector []float64, limit int) ([]*Document, error)
	SearchSimilarWithOptions(vector []float64, options SearchOptions) ([]*SimilarityResult, error)
	SearchByText(text string, limit int) ([]*Document, error)
	SearchByTextWithOptions(text string, options SearchOptions) ([]*SimilarityResult, error)

	// Index management
	GetIndexStats() (IndexStats, error)
	OptimizeIndex() error
	ReindexAll() error
	BackupIndex(path string) error
	RestoreIndex(path string) error

	// Health and monitoring
	IsConnected() bool
	Ping() error
	GetHealth() (map[string]interface{}, error)
	Close() error
}

// VectorizerConfig configuration pour un vectorizer
type VectorizerConfig struct {
	Provider   string // "qdrant", "pinecone", "weaviate", "memory"
	Host       string
	Port       int
	APIKey     string
	Collection string
	VectorSize int
	Model      string
	Timeout    time.Duration
	MaxRetries int
	BatchSize  int
}

// VectorizerProvider factory pour créer des instances de vectorizer
type VectorizerProvider interface {
	CreateVectorizer(config VectorizerConfig) (DocumentVectorizer, error)
	SupportedProviders() []string
	ValidateConfig(config VectorizerConfig) error
}

// DefaultVectorizerProvider implémentation par défaut du factory
type DefaultVectorizerProvider struct {
	providers map[string]func(VectorizerConfig) (DocumentVectorizer, error)
}

// NewDefaultVectorizerProvider crée un nouveau provider par défaut
func NewDefaultVectorizerProvider() *DefaultVectorizerProvider {
	provider := &DefaultVectorizerProvider{
		providers: make(map[string]func(VectorizerConfig) (DocumentVectorizer, error)),
	}

	// Enregistrement des providers disponibles
	provider.RegisterProvider("memory", func(config VectorizerConfig) (DocumentVectorizer, error) {
		return NewMemoryVectorizer(config), nil
	})

	provider.RegisterProvider("qdrant", func(config VectorizerConfig) (DocumentVectorizer, error) {
		return NewQDrantVectorizer(config)
	})

	return provider
}

// RegisterProvider enregistre un nouveau provider de vectorizer
func (dvp *DefaultVectorizerProvider) RegisterProvider(name string, factory func(VectorizerConfig) (DocumentVectorizer, error)) {
	dvp.providers[name] = factory
}

// CreateVectorizer crée une instance de vectorizer selon la configuration
func (dvp *DefaultVectorizerProvider) CreateVectorizer(config VectorizerConfig) (DocumentVectorizer, error) {
	factory, exists := dvp.providers[config.Provider]
	if !exists {
		// Fallback to memory vectorizer
		return NewMemoryVectorizer(config), nil
	}
	return factory(config)
}

// SupportedProviders retourne la liste des providers supportés
func (dvp *DefaultVectorizerProvider) SupportedProviders() []string {
	providers := make([]string, 0, len(dvp.providers))
	for name := range dvp.providers {
		providers = append(providers, name)
	}
	return providers
}

// ValidateConfig valide une configuration de vectorizer
func (dvp *DefaultVectorizerProvider) ValidateConfig(config VectorizerConfig) error {
	if config.Provider == "" {
		return ErrInvalidDocument // réutilisation d'une erreur existante
	}
	if config.VectorSize <= 0 {
		return ErrInvalidDocument
	}
	return nil
}

// MemoryVectorizer implémentation en mémoire pour les tests
type MemoryVectorizer struct {
	config    VectorizerConfig
	vectors   map[string][]float64
	documents map[string]*Document
	metadata  map[string]VectorMetadata
	connected bool
}

// NewMemoryVectorizer crée un nouveau vectorizer en mémoire
func NewMemoryVectorizer(config VectorizerConfig) *MemoryVectorizer {
	return &MemoryVectorizer{
		config:    config,
		vectors:   make(map[string][]float64),
		documents: make(map[string]*Document),
		metadata:  make(map[string]VectorMetadata),
		connected: true,
	}
}

// GenerateEmbedding génère un embedding simple
func (mv *MemoryVectorizer) GenerateEmbedding(text string) ([]float64, error) {
	if !mv.connected {
		return nil, ErrVectorizerUnavailable
	}

	size := mv.config.VectorSize
	if size <= 0 {
		size = 384 // taille par défaut
	}

	embedding := make([]float64, size)
	for i := range embedding {
		embedding[i] = float64((len(text)+i)%256) / 256.0
	}
	return embedding, nil
}

// GenerateEmbeddingWithOptions génère un embedding avec options
func (mv *MemoryVectorizer) GenerateEmbeddingWithOptions(text string, options VectorizationOptions) ([]float64, VectorMetadata, error) {
	embedding, err := mv.GenerateEmbedding(text)
	if err != nil {
		return nil, VectorMetadata{}, err
	}

	metadata := VectorMetadata{
		VectorSize:    len(embedding),
		EmbeddingType: "memory",
		ModelVersion:  mv.config.Model,
		CreatedAt:     time.Now(),
		Quality:       0.85, // qualité simulée
	}

	return embedding, metadata, nil
}

// IndexDocument indexe un document
func (mv *MemoryVectorizer) IndexDocument(doc *Document) error {
	if !mv.connected {
		return ErrVectorizerUnavailable
	}

	embedding, err := mv.GenerateEmbedding(string(doc.Content))
	if err != nil {
		return err
	}

	mv.vectors[doc.ID] = embedding
	mv.documents[doc.ID] = doc
	mv.metadata[doc.ID] = VectorMetadata{
		DocumentID:    doc.ID,
		VectorSize:    len(embedding),
		EmbeddingType: "memory",
		ModelVersion:  mv.config.Model,
		CreatedAt:     time.Now(),
		Quality:       0.85,
	}

	return nil
}

// IndexDocumentWithOptions indexe un document avec options
func (mv *MemoryVectorizer) IndexDocumentWithOptions(doc *Document, options VectorizationOptions) error {
	return mv.IndexDocument(doc) // version simplifiée
}

// RemoveDocument supprime un document de l'index
func (mv *MemoryVectorizer) RemoveDocument(id string) error {
	if !mv.connected {
		return ErrVectorizerUnavailable
	}

	delete(mv.vectors, id)
	delete(mv.documents, id)
	delete(mv.metadata, id)
	return nil
}

// UpdateDocument met à jour un document
func (mv *MemoryVectorizer) UpdateDocument(doc *Document) error {
	return mv.IndexDocument(doc)
}

// SearchSimilar recherche des documents similaires
func (mv *MemoryVectorizer) SearchSimilar(vector []float64, limit int) ([]*Document, error) {
	if !mv.connected {
		return nil, ErrVectorizerUnavailable
	}

	// Simulation simple: retourne tous les documents (limité)
	docs := make([]*Document, 0, limit)
	count := 0
	for _, doc := range mv.documents {
		if count >= limit {
			break
		}
		docs = append(docs, doc)
		count++
	}
	return docs, nil
}

// SearchSimilarWithOptions recherche avec options avancées
func (mv *MemoryVectorizer) SearchSimilarWithOptions(vector []float64, options SearchOptions) ([]*SimilarityResult, error) {
	if !mv.connected {
		return nil, ErrVectorizerUnavailable
	}

	results := make([]*SimilarityResult, 0, options.Limit)
	count := 0
	rank := 1

	for id, doc := range mv.documents {
		if count >= options.Limit {
			break
		}

		// Simulation de score de similarité
		score := 0.8 - float64(count)*0.1
		if score < options.MinScore {
			continue
		}

		result := &SimilarityResult{
			Document: doc,
			Score:    score,
			Distance: 1.0 - score,
			Metadata: mv.metadata[id],
			Rank:     rank,
		}

		results = append(results, result)
		count++
		rank++
	}

	return results, nil
}

// SearchByText recherche par texte
func (mv *MemoryVectorizer) SearchByText(text string, limit int) ([]*Document, error) {
	vector, err := mv.GenerateEmbedding(text)
	if err != nil {
		return nil, err
	}
	return mv.SearchSimilar(vector, limit)
}

// SearchByTextWithOptions recherche par texte avec options
func (mv *MemoryVectorizer) SearchByTextWithOptions(text string, options SearchOptions) ([]*SimilarityResult, error) {
	vector, err := mv.GenerateEmbedding(text)
	if err != nil {
		return nil, err
	}
	return mv.SearchSimilarWithOptions(vector, options)
}

// GetIndexStats retourne les statistiques de l'index
func (mv *MemoryVectorizer) GetIndexStats() (IndexStats, error) {
	if !mv.connected {
		return IndexStats{}, ErrVectorizerUnavailable
	}

	return IndexStats{
		TotalDocuments:  int64(len(mv.documents)),
		TotalVectors:    int64(len(mv.vectors)),
		VectorDimension: mv.config.VectorSize,
		IndexSize:       int64(len(mv.documents) * mv.config.VectorSize * 8), // approximation
		LastUpdated:     time.Now(),
		AverageQuality:  0.85,
		ModelVersion:    mv.config.Model,
	}, nil
}

// OptimizeIndex optimise l'index (no-op pour memory)
func (mv *MemoryVectorizer) OptimizeIndex() error {
	return nil
}

// ReindexAll réindexe tous les documents
func (mv *MemoryVectorizer) ReindexAll() error {
	if !mv.connected {
		return ErrVectorizerUnavailable
	}

	// Réindexation de tous les documents
	for id, doc := range mv.documents {
		err := mv.IndexDocument(doc)
		if err != nil {
			return err
		}
		_ = id // éviter l'avertissement unused
	}

	return nil
}

// BackupIndex sauvegarde l'index (simulation)
func (mv *MemoryVectorizer) BackupIndex(path string) error {
	return nil // simulation
}

// RestoreIndex restaure l'index (simulation)
func (mv *MemoryVectorizer) RestoreIndex(path string) error {
	return nil // simulation
}

// IsConnected vérifie la connexion
func (mv *MemoryVectorizer) IsConnected() bool {
	return mv.connected
}

// Ping teste la connexion
func (mv *MemoryVectorizer) Ping() error {
	if !mv.connected {
		return ErrVectorizerUnavailable
	}
	return nil
}

// GetHealth retourne l'état de santé
func (mv *MemoryVectorizer) GetHealth() (map[string]interface{}, error) {
	if !mv.connected {
		return nil, ErrVectorizerUnavailable
	}

	return map[string]interface{}{
		"status":          "healthy",
		"total_documents": len(mv.documents),
		"total_vectors":   len(mv.vectors),
		"memory_usage":    len(mv.documents) * mv.config.VectorSize * 8,
	}, nil
}

// Close ferme la connexion
func (mv *MemoryVectorizer) Close() error {
	mv.connected = false
	return nil
}
