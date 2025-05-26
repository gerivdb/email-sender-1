package chunking

import (
	"fmt"
	"regexp"
	"strings"
)

// AdaptiveChunker sélectionne automatiquement la meilleure stratégie de chunking
type AdaptiveChunker struct {
	fixedSizeChunker *FixedSizeChunker
	semanticChunker  *SemanticChunker
}

// NewAdaptiveChunker crée une nouvelle instance d'AdaptiveChunker
func NewAdaptiveChunker() *AdaptiveChunker {
	return &AdaptiveChunker{
		fixedSizeChunker: &FixedSizeChunker{},
		semanticChunker:  &SemanticChunker{},
	}
}

// GetName retourne le nom de la stratégie
func (ac *AdaptiveChunker) GetName() string {
	return "adaptive"
}

// GetDescription retourne une description de la stratégie
func (ac *AdaptiveChunker) GetDescription() string {
	return "Sélectionne automatiquement la meilleure stratégie de chunking selon le contenu"
}

// Chunk implémente l'interface ChunkingStrategy
func (ac *AdaptiveChunker) Chunk(text string, options ChunkingOptions) ([]*DocumentChunk, error) {
	if text == "" {
		return nil, fmt.Errorf("text cannot be empty")
	}

	// Analyser le contenu pour déterminer la meilleure stratégie
	contentType := ac.analyzeContent(text)

	// Ajuster les options selon le type de contenu
	adjustedOptions := ac.adjustOptions(options, contentType)

	// Choisir la stratégie appropriée
	var strategy ChunkingStrategy
	switch contentType {
	case "markdown", "structured":
		strategy = ac.semanticChunker
	default:
		strategy = ac.fixedSizeChunker
	}

	return strategy.Chunk(text, adjustedOptions)
}

// ContentType représente le type de contenu détecté
type ContentType string

const (
	ContentTypeMarkdown   ContentType = "markdown"
	ContentTypeStructured ContentType = "structured"
	ContentTypeProse      ContentType = "prose"
	ContentTypeCode       ContentType = "code"
)

// analyzeContent détermine le type de contenu
func (ac *AdaptiveChunker) analyzeContent(text string) ContentType {
	// Détecter le markdown par la présence de titres et de formatage
	if ac.isMarkdown(text) {
		return ContentTypeMarkdown
	}

	// Détecter le contenu structuré par la présence de motifs répétitifs
	if ac.isStructured(text) {
		return ContentTypeStructured
	}

	// Détecter le code source
	if ac.isCode(text) {
		return ContentTypeCode
	}

	// Par défaut, considérer comme de la prose
	return ContentTypeProse
}

// adjustOptions ajuste les options de chunking selon le type de contenu
func (ac *AdaptiveChunker) adjustOptions(options ChunkingOptions, contentType ContentType) ChunkingOptions {
	adjusted := options

	switch contentType {
	case ContentTypeMarkdown:
		// Pour le markdown, utiliser des chunks plus grands pour préserver la structure
		adjusted.MaxChunkSize = max(options.MaxChunkSize, 1000)
		adjusted.PreserveStructure = true

	case ContentTypeStructured:
		// Pour le contenu structuré, augmenter le chevauchement
		adjusted.ChunkOverlap = max(options.ChunkOverlap, options.MaxChunkSize/5)
		adjusted.PreserveStructure = true

	case ContentTypeCode:
		// Pour le code, chunks plus petits et plus de chevauchement
		adjusted.MaxChunkSize = min(options.MaxChunkSize, 500)
		adjusted.ChunkOverlap = max(options.ChunkOverlap, options.MaxChunkSize/3)
		adjusted.PreserveStructure = true

	case ContentTypeProse:
		// Pour la prose, utiliser les valeurs par défaut
		if adjusted.MaxChunkSize == 0 {
			adjusted.MaxChunkSize = 500
		}
		if adjusted.ChunkOverlap == 0 {
			adjusted.ChunkOverlap = adjusted.MaxChunkSize / 10
		}
	}

	return adjusted
}

// isMarkdown détecte si le texte contient du markdown
func (ac *AdaptiveChunker) isMarkdown(text string) bool {
	// Regex pour détecter les éléments markdown communs
	patterns := []string{
		`(?m)^#{1,6}\s+.+$`,   // Headers
		`\[.+?\]\(.+?\)`,      // Links
		`(?m)^[\*\-\+]\s+.+$`, // Lists
		"```[\\s\\S]+?```",    // Code blocks
		`\*\*.+?\*\*`,         // Bold
		`_.+?_`,               // Italic
	}

	score := 0
	for _, pattern := range patterns {
		re := regexp.MustCompile(pattern)
		matches := re.FindAllString(text, -1)
		if len(matches) > 0 {
			score++
		}
	}

	return score >= 2 // Au moins 2 types d'éléments markdown
}

// isStructured détecte si le texte a une structure répétitive
func (ac *AdaptiveChunker) isStructured(text string) bool {
	lines := strings.Split(text, "\n")
	if len(lines) < 5 {
		return false
	}

	// Compter les lignes qui commencent de la même façon
	patterns := make(map[string]int)
	for _, line := range lines {
		if len(line) > 0 {
			// Prendre les 3 premiers caractères non-espaces
			start := strings.TrimSpace(line)
			if len(start) >= 3 {
				start = start[:3]
				patterns[start]++
			}
		}
	}

	// Si plusieurs lignes suivent le même motif
	for _, count := range patterns {
		if count >= len(lines)/3 {
			return true
		}
	}

	return false
}

// isCode détecte s'il s'agit de code source
func (ac *AdaptiveChunker) isCode(text string) bool {
	// Motifs communs dans le code source
	patterns := []string{
		`^(func|def|class|var|let|const)\s+\w+`,
		`^import\s+[\w\*\{\}\s,\.]+`,
		`^package\s+[\w\.]+`,
		`[\w\s]*{[\s\S]*}`,
		`if\s*\(.+?\)`,
		`for\s*\(.+?\)`,
		`return\s+.+`,
	}

	score := 0
	for _, pattern := range patterns {
		re := regexp.MustCompile(pattern)
		if re.MatchString(text) {
			score++
		}
	}

	// Aussi vérifier l'indentation cohérente
	lines := strings.Split(text, "\n")
	indentedLines := 0
	for _, line := range lines {
		if strings.HasPrefix(line, "\t") || strings.HasPrefix(line, "    ") {
			indentedLines++
		}
	}
	if float64(indentedLines)/float64(len(lines)) > 0.3 {
		score++
	}

	return score >= 2 // Au moins 2 indicateurs de code
}

// Helpers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
