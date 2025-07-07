package chunking

import (
	"crypto/sha256"
	"fmt"
	"regexp"
	"strings"
	"time"
)

// SemanticChunker implémente un chunking basé sur la structure sémantique du texte
type SemanticChunker struct{}

// GetName retourne le nom de la stratégie
func (sc *SemanticChunker) GetName() string {
	return "semantic"
}

// GetDescription retourne une description de la stratégie
func (sc *SemanticChunker) GetDescription() string {
	return "Découpe le texte en préservant la structure sémantique (paragraphes, sections)"
}

// Chunk implémente l'interface ChunkingStrategy
func (sc *SemanticChunker) Chunk(text string, options ChunkingOptions) ([]*DocumentChunk, error) {
	if text == "" {
		return nil, fmt.Errorf("text cannot be empty")
	}

	// Valider les options
	if options.MaxChunkSize <= 0 {
		options.MaxChunkSize = 500
	}

	var chunks []*DocumentChunk
	chunkIndex := 0

	// Détection des sections avec titres (style Markdown)
	sections := sc.extractSections(text)

	for _, section := range sections {
		// Découper chaque section en paragraphes
		paragraphs := sc.extractParagraphs(section.content)

		var currentChunk strings.Builder
		var startOffset = section.startOffset

		for _, p := range paragraphs {
			// Si l'ajout de ce paragraphe dépasse la taille max
			if currentChunk.Len()+len(p.content) > options.MaxChunkSize && currentChunk.Len() > 0 {
				// Créer un nouveau chunk avec le contenu accumulé
				chunk := sc.createChunk(
					currentChunk.String(),
					startOffset,
					startOffset+currentChunk.Len(),
					section.title,
					chunkIndex,
					options,
				)
				chunks = append(chunks, chunk)

				currentChunk.Reset()
				startOffset = p.startOffset
				chunkIndex++
			}

			// Ajouter le paragraphe au chunk courant
			if currentChunk.Len() > 0 {
				currentChunk.WriteString("\n\n")
			}
			currentChunk.WriteString(p.content)
		}

		// Créer le dernier chunk de la section s'il reste du contenu
		if currentChunk.Len() > 0 {
			chunk := sc.createChunk(
				currentChunk.String(),
				startOffset,
				startOffset+currentChunk.Len(),
				section.title,
				chunkIndex,
				options,
			)
			chunks = append(chunks, chunk)
			chunkIndex++
		}
	}

	return chunks, nil
}

// Structure pour représenter une section avec son titre
type section struct {
	title       string
	content     string
	startOffset int
}

// Structure pour représenter un paragraphe
type paragraph struct {
	content     string
	startOffset int
}

// extractSections découpe le texte en sections basées sur les titres
func (sc *SemanticChunker) extractSections(text string) []section {
	var sections []section

	// Regex pour détecter les titres style Markdown (## Titre)
	titleRegex := regexp.MustCompile(`(?m)^(#{1,6})\s+(.+)$`)

	// Trouver tous les titres et leur position
	matches := titleRegex.FindAllStringSubmatchIndex(text, -1)

	if len(matches) == 0 {
		// Pas de titre trouvé, traiter tout le texte comme une seule section
		sections = append(sections, section{
			title:       "",
			content:     text,
			startOffset: 0,
		})
		return sections
	}

	// Traiter chaque section
	for i := 0; i < len(matches); i++ {
		match := matches[i]
		startPos := match[0]
		titleEnd := match[1]
		title := text[match[4]:match[5]] // Le texte du titre sans les #

		var endPos int
		if i < len(matches)-1 {
			endPos = matches[i+1][0]
		} else {
			endPos = len(text)
		}

		// Le contenu commence après le titre et va jusqu'au début de la prochaine section
		content := text[titleEnd:endPos]

		sections = append(sections, section{
			title:       title,
			content:     strings.TrimSpace(content),
			startOffset: startPos,
		})
	}

	return sections
}

// extractParagraphs découpe le texte en paragraphes
func (sc *SemanticChunker) extractParagraphs(text string) []paragraph {
	var paragraphs []paragraph

	// Séparer par lignes vides (2 retours à la ligne ou plus)
	parts := strings.Split(text, "\n\n")
	offset := 0

	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			paragraphs = append(paragraphs, paragraph{
				content:     trimmed,
				startOffset: offset,
			})
		}
		offset += len(part) + 2 // +2 pour les \n\n
	}

	return paragraphs
}

// createChunk crée un nouveau DocumentChunk avec les métadonnées appropriées
func (sc *SemanticChunker) createChunk(content string, start, end int, sectionTitle string, index int, options ChunkingOptions) *DocumentChunk {
	// Générer un ID unique pour le chunk
	chunkHash := sha256.Sum256([]byte(fmt.Sprintf("%s-%d-%d", options.ParentDocumentID, start, end)))
	chunkID := fmt.Sprintf("chunk-%x", chunkHash[:8])

	// Copier les métadonnées
	metadata := make(map[string]interface{})
	if options.Metadata != nil {
		for k, v := range options.Metadata {
			metadata[k] = v
		}
	}
	// Ajouter le titre de la section aux métadonnées
	if sectionTitle != "" {
		metadata["section_title"] = sectionTitle
	}

	return &DocumentChunk{
		ID:               chunkID,
		ParentDocumentID: options.ParentDocumentID,
		ChunkIndex:       index,
		StartOffset:      start,
		EndOffset:        end,
		Text:             content,
		Metadata:         metadata,
		CreatedAt:        time.Now(),
	}
}
