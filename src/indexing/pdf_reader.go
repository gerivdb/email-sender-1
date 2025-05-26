package indexing

import (
	"fmt"
	"path/filepath"

	"github.com/pdfcpu/pdfcpu/pkg/api"
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

// Fonction utilitaire pour extraire une chaîne depuis un dictionnaire PDF
func getPDFString(infoDict interface{}, key string) string {
	type finder interface {
		Find(string) (interface{}, bool)
	}
	dict, ok := infoDict.(finder)
	if !ok {
		return ""
	}
	if obj, found := dict.Find(key); found {
		if s, ok := obj.(string); ok {
			return s
		}
		return fmt.Sprintf("%v", obj)
	}
	return ""
}

// Read implements DocumentReader interface
func (r *PDFReader) Read(path string) (*Document, error) {
	ctx, err := api.ReadContextFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read PDF info: %v", err)
	}

	infoDict := ctx.XRefTable.Info
	var title, author, subject, keywords, creator, producer, creationDate, modDate string
	if infoDict != nil {
		title = getPDFString(infoDict, "Title")
		author = getPDFString(infoDict, "Author")
		subject = getPDFString(infoDict, "Subject")
		keywords = getPDFString(infoDict, "Keywords")
		creator = getPDFString(infoDict, "Creator")
		producer = getPDFString(infoDict, "Producer")
		creationDate = getPDFString(infoDict, "CreationDate")
		modDate = getPDFString(infoDict, "ModDate")
	}

	metadata := map[string]interface{}{
		"filename":          filepath.Base(path),
		"type":              "pdf",
		"title":             title,
		"author":            author,
		"subject":           subject,
		"keywords":          keywords,
		"creator":           creator,
		"producer":          producer,
		"creation_date":     creationDate,
		"modification_date": modDate,
	}

	doc := &Document{
		Metadata: metadata,
	}

	return doc, nil
}
