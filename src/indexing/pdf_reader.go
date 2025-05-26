package indexing

import (
	"fmt"
	"path/filepath"
	"time"

	"github.com/pdfcpu/pdfcpu/pkg/api"
	"github.com/pdfcpu/pdfcpu/pkg/pdfcpu"
)

// PDFReader implements DocumentReader for PDF files
type PDFReader struct{}

// NewPDFReader creates a new PDFReader instance
func NewPDFReader() *PDFReader {
	return &PDFReader{}
}

// GetSupportedExtensions returns supported file extensions
func (r *PDFReader) GetSupportedExtensions() []string {
	return []string{".pdf"}
}

// Read implements DocumentReader interface
func (r *PDFReader) Read(path string) (*Document, error) {
	// Extract text content
	content, err := api.ExtractText(path, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to extract text from PDF: %v", err)
	}

	// Get PDF metadata
	ctx, err := api.ReadContextFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read PDF context: %v", err)
	}

	// Extract PDF properties
	info := ctx.XRefTable.Info
	metadata := map[string]interface{}{
		"filename": filepath.Base(path),
		"type":     "pdf",
		"pages":    ctx.PageCount,
		"version":  ctx.Version(),
	}

	// Add optional metadata if available
	if info != nil {
		if info.Title != nil {
			metadata["title"] = *info.Title
		}
		if info.Author != nil {
			metadata["author"] = *info.Author
		}
		if info.Subject != nil {
			metadata["subject"] = *info.Subject
		}
		if info.Keywords != nil {
			metadata["keywords"] = *info.Keywords
		}
		if info.Creator != nil {
			metadata["creator"] = *info.Creator
		}
		if info.Producer != nil {
			metadata["producer"] = *info.Producer
		}
		if info.CreationDate != nil {
			if t, err := pdfcpu.DateTime(*info.CreationDate, nil); err == nil {
				metadata["creation_date"] = t.Format(time.RFC3339)
			}
		}
		if info.ModDate != nil {
			if t, err := pdfcpu.DateTime(*info.ModDate, nil); err == nil {
				metadata["modification_date"] = t.Format(time.RFC3339)
			}
		}
	}

	// Create document
	doc := &Document{
		Path:     path,
		Content:  content,
		Metadata: metadata,
		Encoding: "UTF-8", // PDFs are always decoded to UTF-8
	}

	return doc, nil
}
