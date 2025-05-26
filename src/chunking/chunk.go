package chunking

import "time"

// DocumentChunk représente un morceau d'un document source
type DocumentChunk struct {
	// ID du chunk
	ID string `json:"id"`

	// ID du document parent
	ParentDocumentID string `json:"parent_document_id"`

	// Position du chunk dans le document
	ChunkIndex int `json:"chunk_index"`

	// Position de début dans le document source (en caractères)
	StartOffset int `json:"start_offset"`

	// Position de fin dans le document source (en caractères)
	EndOffset int `json:"end_offset"`

	// Texte du chunk
	Text string `json:"text"`

	// Contexte avant/après pour meilleure compréhension
	Context string `json:"context,omitempty"`

	// Vecteur d'embedding du chunk
	Vector []float32 `json:"vector,omitempty"`

	// Métadonnées additionnelles
	Metadata map[string]interface{} `json:"metadata,omitempty"`

	// Date de création
	CreatedAt time.Time `json:"created_at"`
}

// ChunkingStrategy détermine comment les documents sont découpés
type ChunkingStrategy interface {
	// Chunk découpe le texte en morceaux selon la stratégie
	Chunk(text string, options ChunkingOptions) ([]*DocumentChunk, error)

	// GetName retourne le nom de la stratégie
	GetName() string

	// GetDescription retourne une description de la stratégie
	GetDescription() string
}

// ChunkingOptions contient les options de configuration pour le chunking
type ChunkingOptions struct {
	// Taille maximale d'un chunk en caractères
	MaxChunkSize int

	// Taille du chevauchement entre chunks consécutifs
	ChunkOverlap int

	// ID du document parent
	ParentDocumentID string

	// Si true, respecte les limites de phrases/paragraphes
	PreserveStructure bool

	// Métadonnées à inclure dans chaque chunk
	Metadata map[string]interface{}
}
