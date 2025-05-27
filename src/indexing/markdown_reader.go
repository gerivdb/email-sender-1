package indexing

import (
	"bytes"

	"github.com/gomarkdown/markdown/ast"
	"github.com/gomarkdown/markdown/parser"
)

// MarkdownReader implements DocumentReader for markdown files
type MarkdownReader struct {
	TextReader // Embed TextReader for base functionality
}

// NewMarkdownReader creates a new MarkdownReader instance
func NewMarkdownReader() *MarkdownReader {
	return &MarkdownReader{}
}

// GetSupportedExtensions returns supported file extensions
func (r *MarkdownReader) GetSupportedExtensions() []string {
	return []string{".md", ".markdown"}
}

// Read implements DocumentReader interface
func (r *MarkdownReader) Read(path string) (*Document, error) {
	// First read the file as text to handle encoding
	doc, err := r.TextReader.Read(path)
	if err != nil {
		return nil, err
	}

	// Parse markdown
	extensions := parser.CommonExtensions | parser.AutoHeadingIDs
	p := parser.NewWithExtensions(extensions)

	node := p.Parse([]byte(doc.Content))

	// Extract metadata from frontmatter if present
	frontMatter := extractFrontMatter(node)
	for k, v := range frontMatter {
		doc.Metadata[k] = v
	}

	// Add markdown-specific metadata
	doc.Metadata["headings"] = extractHeadings(node)
	doc.Metadata["type"] = "markdown"

	return doc, nil
}

// extractFrontMatter extrait le frontmatter YAML du contenu markdown brut
func extractFrontMatter(_ ast.Node) map[string]interface{} {
	metadata := make(map[string]interface{})

	// On ne peut pas utiliser ast.YamlMetadata, donc on ne fait rien ici
	// (le frontmatter devrait être extrait avant le parsing markdown)
	return metadata
}

// extractHeadings extracts all headings with their levels
func extractHeadings(node ast.Node) []map[string]interface{} {
	var headings []map[string]interface{}

	ast.WalkFunc(node, func(n ast.Node, entering bool) ast.WalkStatus {
		if entering {
			if heading, ok := n.(*ast.Heading); ok {
				text := renderInline(heading)
				headings = append(headings, map[string]interface{}{
					"level": heading.Level,
					"text":  text,
				})
			}
		}
		return ast.GoToNext
	})

	return headings
}

// renderInline renders inline content of a node to plain text
func renderInline(node ast.Node) string {
	var buf bytes.Buffer
	ast.WalkFunc(node, func(n ast.Node, entering bool) ast.WalkStatus {
		if entering {
			if text, ok := n.(*ast.Text); ok {
				buf.Write(text.Literal)
			}
		}
		return ast.GoToNext
	})
	return buf.String()
}
