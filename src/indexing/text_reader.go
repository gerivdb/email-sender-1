package indexing

import (
	"bufio"
	"bytes"
	"io"
	"os"
	"path/filepath"

	"github.com/saintfish/chardet"
	"golang.org/x/text/encoding"
	"golang.org/x/text/encoding/charmap"
	"golang.org/x/text/encoding/unicode"
)

// TextReader implements DocumentReader for text files
type TextReader struct{}

// NewTextReader creates a new TextReader instance
func NewTextReader() *TextReader {
	return &TextReader{}
}

// GetSupportedExtensions returns supported file extensions
func (r *TextReader) GetSupportedExtensions() []string {
	return []string{".txt"}
}

// Read implements DocumentReader interface
func (r *TextReader) Read(path string) (*Document, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// Read the first 4096 bytes for encoding detection
	buffer := make([]byte, 4096)
	n, err := file.Read(buffer)
	if err != nil && err != io.EOF {
		return nil, err
	}
	buffer = buffer[:n]

	// Detect encoding
	detector := chardet.NewTextDetector()
	result, err := detector.DetectBest(buffer)
	if err != nil {
		return nil, err
	}

	// Rewind file for full read
	if _, err := file.Seek(0, 0); err != nil {
		return nil, err
	}

	// Create appropriate decoder
	var decoder *encoding.Decoder
	switch result.Charset {
	case "UTF-8":
		decoder = unicode.UTF8.NewDecoder()
	case "UTF-16LE":
		decoder = unicode.UTF16(unicode.LittleEndian, unicode.UseBOM).NewDecoder()
	case "UTF-16BE":
		decoder = unicode.UTF16(unicode.BigEndian, unicode.UseBOM).NewDecoder()
	case "ISO-8859-1":
		decoder = charmap.ISO8859_1.NewDecoder()
	case "windows-1252":
		decoder = charmap.Windows1252.NewDecoder()
	default:
		decoder = unicode.UTF8.NewDecoder() // fallback to UTF-8
	}

	// Read and decode the content
	reader := bufio.NewReader(decoder.Reader(file))
	var content bytes.Buffer

	for {
		line, err := reader.ReadString('\n')
		if err != nil && err != io.EOF {
			return nil, err
		}
		content.WriteString(line)
		if err == io.EOF {
			break
		}
	}

	// Create document with metadata
	fileInfo, err := file.Stat()
	if err != nil {
		return nil, err
	}

	doc := &Document{
		Path:    path,
		Content: content.String(),
		Metadata: map[string]interface{}{
			"filename":   filepath.Base(path),
			"extension":  filepath.Ext(path),
			"size":       fileInfo.Size(),
			"encoding":   result.Charset,
			"confidence": result.Confidence,
		},
		Encoding: result.Charset,
	}

	return doc, nil
}
