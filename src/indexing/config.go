package indexing

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
)

// IndexingConfig holds all configuration for the indexing system
type IndexingConfig struct {
	// Data storage configuration
	DataDir string `json:"dataDir"`

	// Qdrant configuration
	Qdrant struct {
		Host       string `json:"host"`
		Port       int    `json:"port"`
		Collection string `json:"collection"`
	} `json:"qdrant"`

	// Chunking configuration
	Chunking struct {
		ChunkSize    int `json:"chunkSize"`
		ChunkOverlap int `json:"chunkOverlap"`
	} `json:"chunking"`

	// Batch processing configuration
	Batch struct {
		Size           int `json:"size"`
		MaxConcurrent  int `json:"maxConcurrent"`
		RetryAttempts  int `json:"retryAttempts"`
		TimeoutSeconds int `json:"timeoutSeconds"`
	} `json:"batch"`

	// Embedding configuration
	Embedding struct {
		Model      string `json:"model"`
		Dimensions int    `json:"dimensions"`
		BatchSize  int    `json:"batchSize"`
	} `json:"embedding"`

	// Supported file types and their configuration
	FileTypes struct {
		TextMaxSizeMB    int      `json:"textMaxSizeMB"`
		PDFMaxSizeMB     int      `json:"pdfMaxSizeMB"`
		SupportedFormats []string `json:"supportedFormats"`
		ExcludePatterns  []string `json:"excludePatterns"`
	} `json:"fileTypes"`
}

// DefaultConfig returns a configuration with sensible defaults
func DefaultConfig() *IndexingConfig {
	return &IndexingConfig{
		DataDir: "data", // Default data directory

		Qdrant: struct {
			Host       string `json:"host"`
			Port       int    `json:"port"`
			Collection string `json:"collection"`
		}{
			Host:       "localhost",
			Port:       6334,
			Collection: "documents",
		},
		Chunking: struct {
			ChunkSize    int `json:"chunkSize"`
			ChunkOverlap int `json:"chunkOverlap"`
		}{
			ChunkSize:    1000,
			ChunkOverlap: 200,
		},
		Batch: struct {
			Size           int `json:"size"`
			MaxConcurrent  int `json:"maxConcurrent"`
			RetryAttempts  int `json:"retryAttempts"`
			TimeoutSeconds int `json:"timeoutSeconds"`
		}{
			Size:           100,
			MaxConcurrent:  4,
			RetryAttempts:  3,
			TimeoutSeconds: 30,
		},
		Embedding: struct {
			Model      string `json:"model"`
			Dimensions int    `json:"dimensions"`
			BatchSize  int    `json:"batchSize"`
		}{
			Model:      "text-embedding-3-small",
			Dimensions: 1536,
			BatchSize:  32,
		},
		FileTypes: struct {
			TextMaxSizeMB    int      `json:"textMaxSizeMB"`
			PDFMaxSizeMB     int      `json:"pdfMaxSizeMB"`
			SupportedFormats []string `json:"supportedFormats"`
			ExcludePatterns  []string `json:"excludePatterns"`
		}{
			TextMaxSizeMB:    10,
			PDFMaxSizeMB:     50,
			SupportedFormats: []string{".txt", ".md", ".markdown", ".pdf"},
			ExcludePatterns:  []string{".*", "~*", "tmp*"},
		},
	}
}

// LoadConfig loads configuration from a JSON file
func LoadConfig(path string) (*IndexingConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	config := DefaultConfig()
	if err := json.Unmarshal(data, config); err != nil {
		return nil, err
	}

	return config, nil
}

// SaveConfig saves the configuration to a JSON file
func (c *IndexingConfig) SaveConfig(path string) error {
	// Ensure directory exists
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	// Marshal with indentation for readability
	data, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(path, data, 0644)
}

// Validate checks if the configuration is valid
func (c *IndexingConfig) Validate() error {
	// Basic validation can be added here
	if c.Qdrant.Host == "" {
		return errors.New("qdrant host cannot be empty")
	}
	if c.Qdrant.Port <= 0 {
		return errors.New("invalid qdrant port")
	}
	if c.Chunking.ChunkSize <= 0 {
		return errors.New("chunk size must be positive")
	}
	if c.Chunking.ChunkOverlap >= c.Chunking.ChunkSize {
		return errors.New("chunk overlap must be less than chunk size")
	}
	return nil
}
