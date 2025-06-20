// SPDX-License-Identifier: MIT
// Package docmanager - Vectorization Strategy Framework
package docmanager

import (
	"fmt"
	"strings"
)

// TASK ATOMIQUE 3.1.2.3 - Vectorization Strategy Framework
// MICRO-TASK 3.1.2.3.2 - Strategy configuration system

// VectorizationStrategyFactory fabrique pour les stratégies de vectorisation
type VectorizationStrategyFactory struct {
	strategies map[string]func(VectorizationConfig) (VectorizationStrategy, error)
}

// NewVectorizationStrategyFactory crée une nouvelle fabrique
func NewVectorizationStrategyFactory() *VectorizationStrategyFactory {
	factory := &VectorizationStrategyFactory{
		strategies: make(map[string]func(VectorizationConfig) (VectorizationStrategy, error)),
	}

	// Enregistrer les stratégies par défaut
	factory.RegisterStrategy("openai", func(config VectorizationConfig) (VectorizationStrategy, error) {
		return NewOpenAIStrategy(config)
	})
	factory.RegisterStrategy("cohere", func(config VectorizationConfig) (VectorizationStrategy, error) {
		return NewCohereStrategy(config)
	})
	factory.RegisterStrategy("local", func(config VectorizationConfig) (VectorizationStrategy, error) {
		return NewLocalTransformerStrategy(config)
	})

	return factory
}

// RegisterStrategy enregistre une nouvelle stratégie
func (vsf *VectorizationStrategyFactory) RegisterStrategy(name string, creator func(VectorizationConfig) (VectorizationStrategy, error)) {
	vsf.strategies[name] = creator
}

// LoadVectorizationStrategy charge une stratégie selon la configuration
func (vsf *VectorizationStrategyFactory) LoadVectorizationStrategy(config VectorizationConfig) (VectorizationStrategy, error) {
	creator, exists := vsf.strategies[config.Strategy]
	if !exists {
		return nil, fmt.Errorf("vectorization strategy %s not found", config.Strategy)
	}

	return creator(config)
}

// ListStrategies retourne les stratégies disponibles
func (vsf *VectorizationStrategyFactory) ListStrategies() []string {
	names := make([]string, 0, len(vsf.strategies))
	for name := range vsf.strategies {
		names = append(names, name)
	}
	return names
}

// IMPLEMENTATIONS CONCRÈTES DES STRATÉGIES

// OpenAIStrategy stratégie utilisant l'API OpenAI
type OpenAIStrategy struct {
	config VectorizationConfig
}

func NewOpenAIStrategy(config VectorizationConfig) (*OpenAIStrategy, error) {
	if config.APIKey == "" {
		return nil, fmt.Errorf("OpenAI API key required")
	}
	return &OpenAIStrategy{config: config}, nil
}

func (oas *OpenAIStrategy) GenerateEmbedding(text string) ([]float64, error) {
	// TODO: Implémenter appel API OpenAI
	// Pour le moment, retourner un vecteur de test
	dimensions := oas.OptimalDimensions()
	embedding := make([]float64, dimensions)

	// Génération simplifiée basée sur le hash du texte
	hash := simpleHash(text)
	for i := 0; i < dimensions; i++ {
		embedding[i] = float64((hash>>uint(i))&1)*2.0 - 1.0
	}

	return embedding, nil
}

func (oas *OpenAIStrategy) SupportedModels() []string {
	return []string{"text-embedding-ada-002", "text-embedding-3-small", "text-embedding-3-large"}
}

func (oas *OpenAIStrategy) OptimalDimensions() int {
	if oas.config.Dimensions > 0 {
		return oas.config.Dimensions
	}
	return 1536 // Défaut pour OpenAI ada-002
}

func (oas *OpenAIStrategy) ModelName() string {
	if oas.config.ModelName != "" {
		return oas.config.ModelName
	}
	return "text-embedding-ada-002"
}

func (oas *OpenAIStrategy) RequiresAPIKey() bool {
	return true
}

// CohereStrategy stratégie utilisant l'API Cohere
type CohereStrategy struct {
	config VectorizationConfig
}

func NewCohereStrategy(config VectorizationConfig) (*CohereStrategy, error) {
	if config.APIKey == "" {
		return nil, fmt.Errorf("Cohere API key required")
	}
	return &CohereStrategy{config: config}, nil
}

func (cs *CohereStrategy) GenerateEmbedding(text string) ([]float64, error) {
	// TODO: Implémenter appel API Cohere
	dimensions := cs.OptimalDimensions()
	embedding := make([]float64, dimensions)

	// Génération simplifiée
	hash := simpleHash(text)
	for i := 0; i < dimensions; i++ {
		embedding[i] = float64((hash>>(uint(i)%32))&1)*2.0 - 1.0
	}

	return embedding, nil
}

func (cs *CohereStrategy) SupportedModels() []string {
	return []string{"embed-english-v3.0", "embed-multilingual-v3.0", "embed-english-light-v3.0"}
}

func (cs *CohereStrategy) OptimalDimensions() int {
	if cs.config.Dimensions > 0 {
		return cs.config.Dimensions
	}
	return 1024 // Défaut pour Cohere
}

func (cs *CohereStrategy) ModelName() string {
	if cs.config.ModelName != "" {
		return cs.config.ModelName
	}
	return "embed-english-v3.0"
}

func (cs *CohereStrategy) RequiresAPIKey() bool {
	return true
}

// LocalTransformerStrategy stratégie utilisant des transformers locaux
type LocalTransformerStrategy struct {
	config VectorizationConfig
}

func NewLocalTransformerStrategy(config VectorizationConfig) (*LocalTransformerStrategy, error) {
	return &LocalTransformerStrategy{config: config}, nil
}

func (lts *LocalTransformerStrategy) GenerateEmbedding(text string) ([]float64, error) {
	// TODO: Implémenter transformer local (BERT, etc.)
	dimensions := lts.OptimalDimensions()
	embedding := make([]float64, dimensions)

	// Génération basée sur les mots
	words := strings.Fields(strings.ToLower(text))
	for i, word := range words {
		if i >= dimensions {
			break
		}
		embedding[i] = float64(len(word)) / 10.0
	}

	return embedding, nil
}

func (lts *LocalTransformerStrategy) SupportedModels() []string {
	return []string{"sentence-transformers/all-MiniLM-L6-v2", "sentence-transformers/all-mpnet-base-v2", "bert-base-uncased"}
}

func (lts *LocalTransformerStrategy) OptimalDimensions() int {
	if lts.config.Dimensions > 0 {
		return lts.config.Dimensions
	}
	return 384 // Défaut pour MiniLM
}

func (lts *LocalTransformerStrategy) ModelName() string {
	if lts.config.ModelName != "" {
		return lts.config.ModelName
	}
	return "sentence-transformers/all-MiniLM-L6-v2"
}

func (lts *LocalTransformerStrategy) RequiresAPIKey() bool {
	return false
}

// Fonction utilitaire pour le hashing simple
func simpleHash(s string) uint32 {
	hash := uint32(0)
	for _, c := range s {
		hash = hash*31 + uint32(c)
	}
	return hash
}
