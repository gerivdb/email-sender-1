package types

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
)

// MaxContentSize defines the maximum size for document content (100KB)
const MaxContentSize = 100 * 1024

// Document represents a document in the RAG system
type Document struct {
	// ID is the unique identifier for the document
	ID string `json:"id"`

	// Content is the textual content of the document
	Content string `json:"content"`

	// Metadata contains additional information about the document
	Metadata map[string]interface{} `json:"metadata"`

	// Vector is the embedding vector for the document
	Vector []float32 `json:"vector"`
}

// NewDocument creates a new document with the given content
func NewDocument(content string) *Document {
	return &Document{
		ID:       uuid.New().String(),
		Content:  content,
		Metadata: make(map[string]interface{}),
		Vector:   make([]float32, 0),
	}
}

// NewDocumentWithID creates a new document with a specific ID
func NewDocumentWithID(id, content string) *Document {
	return &Document{
		ID:       id,
		Content:  content,
		Metadata: make(map[string]interface{}),
		Vector:   make([]float32, 0),
	}
}

// Validate checks if the document is valid
func (d *Document) Validate() error {
	// Check if ID is not empty
	if strings.TrimSpace(d.ID) == "" {
		return errors.New("document ID cannot be empty")
	}

	// Validate ID format (should be UUID)
	if _, err := uuid.Parse(d.ID); err != nil {
		return fmt.Errorf("document ID must be a valid UUID: %w", err)
	}

	// Check content size
	if len(d.Content) > MaxContentSize {
		return fmt.Errorf("document content exceeds maximum size of %d bytes", MaxContentSize)
	}

	// Validate UTF-8 encoding
	if !utf8.ValidString(d.Content) {
		return errors.New("document content must be valid UTF-8")
	}

	// Validate vector dimension if vector is present
	if len(d.Vector) > 0 {
		for i, val := range d.Vector {
			if val != val { // Check for NaN
				return fmt.Errorf("vector contains NaN at index %d", i)
			}
		}
	}

	return nil
}

// ToJSON serializes the document to JSON
func (d *Document) ToJSON() ([]byte, error) {
	// Validate before serialization
	if err := d.Validate(); err != nil {
		return nil, fmt.Errorf("document validation failed: %w", err)
	}

	data, err := json.Marshal(d)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal document to JSON: %w", err)
	}

	return data, nil
}

// FromJSON deserializes the document from JSON
func (d *Document) FromJSON(data []byte) error {
	if err := json.Unmarshal(data, d); err != nil {
		return fmt.Errorf("failed to unmarshal document from JSON: %w", err)
	}

	// Validate after deserialization
	if err := d.Validate(); err != nil {
		return fmt.Errorf("document validation failed after deserialization: %w", err)
	}

	return nil
}

// SetMetadata sets a metadata field
func (d *Document) SetMetadata(key string, value interface{}) {
	if d.Metadata == nil {
		d.Metadata = make(map[string]interface{})
	}
	d.Metadata[key] = value
}

// GetMetadata gets a metadata field
func (d *Document) GetMetadata(key string) (interface{}, bool) {
	if d.Metadata == nil {
		return nil, false
	}
	value, exists := d.Metadata[key]
	return value, exists
}

// SetSource sets the source metadata
func (d *Document) SetSource(source string) {
	d.SetMetadata("source", source)
}

// GetSource gets the source metadata
func (d *Document) GetSource() string {
	if source, exists := d.GetMetadata("source"); exists {
		if sourceStr, ok := source.(string); ok {
			return sourceStr
		}
	}
	return ""
}

// SetCreatedAt sets the creation timestamp
func (d *Document) SetCreatedAt(t time.Time) {
	d.SetMetadata("created_at", t.Format(time.RFC3339))
}

// GetCreatedAt gets the creation timestamp
func (d *Document) GetCreatedAt() *time.Time {
	if createdAt, exists := d.GetMetadata("created_at"); exists {
		if createdAtStr, ok := createdAt.(string); ok {
			if t, err := time.Parse(time.RFC3339, createdAtStr); err == nil {
				return &t
			}
		}
	}
	return nil
}

// SetModifiedAt sets the modification timestamp
func (d *Document) SetModifiedAt(t time.Time) {
	d.SetMetadata("modified_at", t.Format(time.RFC3339))
}

// GetModifiedAt gets the modification timestamp
func (d *Document) GetModifiedAt() *time.Time {
	if modifiedAt, exists := d.GetMetadata("modified_at"); exists {
		if modifiedAtStr, ok := modifiedAt.(string); ok {
			if t, err := time.Parse(time.RFC3339, modifiedAtStr); err == nil {
				return &t
			}
		}
	}
	return nil
}

// SetFileType sets the file type metadata
func (d *Document) SetFileType(fileType string) {
	d.SetMetadata("file_type", fileType)
}

// GetFileType gets the file type metadata
func (d *Document) GetFileType() string {
	if fileType, exists := d.GetMetadata("file_type"); exists {
		if fileTypeStr, ok := fileType.(string); ok {
			return fileTypeStr
		}
	}
	return ""
}

// SetOriginalSize sets the original document size
func (d *Document) SetOriginalSize(size int64) {
	d.SetMetadata("original_size", size)
}

// GetOriginalSize gets the original document size
func (d *Document) GetOriginalSize() int64 {
	if size, exists := d.GetMetadata("original_size"); exists {
		switch v := size.(type) {
		case int64:
			return v
		case float64:
			return int64(v)
		case int:
			return int64(v)
		}
	}
	return 0
}

// SetVector sets the embedding vector
func (d *Document) SetVector(vector []float32) {
	d.Vector = make([]float32, len(vector))
	copy(d.Vector, vector)
}

// GetVectorDimension returns the dimension of the vector
func (d *Document) GetVectorDimension() int {
	return len(d.Vector)
}

// ValidateVectorDimension checks if the vector has the expected dimension
func (d *Document) ValidateVectorDimension(expectedDim int) error {
	if len(d.Vector) != expectedDim {
		return fmt.Errorf("vector dimension mismatch: expected %d, got %d", expectedDim, len(d.Vector))
	}
	return nil
}
