package indexing

import "context"

// DocumentReader interface defines methods for reading different document formats
// Use Document type
type DocumentReader interface {
	// Read reads the content and metadata from a file with context
	Read(ctx context.Context, path string) (*Document, error)
	// GetSupportedExtensions returns the file extensions this reader supports
	GetSupportedExtensions() []string
}

// FileType represents supported document types
type FileType int

const (
	TypeUnknown FileType = iota
	TypeText
	TypeMarkdown
	TypePDF
)

// ReaderFactory creates appropriate DocumentReader based on file extension
type ReaderFactory struct {
	readers map[string]DocumentReader
}

// NewReaderFactory creates a new ReaderFactory instance
func NewReaderFactory() *ReaderFactory {
	rf := &ReaderFactory{
		readers: make(map[string]DocumentReader),
	}

	// Register default readers
	rf.RegisterReader(NewTextReader())
	rf.RegisterReader(NewMarkdownReader())
	rf.RegisterReader(NewPDFReader())

	return rf
}

// RegisterReader registers a new document reader
func (rf *ReaderFactory) RegisterReader(reader DocumentReader) {
	for _, ext := range reader.GetSupportedExtensions() {
		rf.readers[ext] = reader
	}
}

// GetReader returns appropriate reader for given file extension
func (rf *ReaderFactory) GetReader(ext string) (DocumentReader, bool) {
	reader, ok := rf.readers[ext]
	return reader, ok
}
