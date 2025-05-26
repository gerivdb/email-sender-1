package chunking

import (
	"crypto/sha256"
	"fmt"
	"strings"
	"time"
	"unicode"
)

// FixedSizeChunker implémente un chunking basé sur une taille fixe
type FixedSizeChunker struct{}

// GetName retourne le nom de la stratégie
func (fs *FixedSizeChunker) GetName() string {
	return "fixed-size"
}

// GetDescription retourne une description de la stratégie
func (fs *FixedSizeChunker) GetDescription() string {
	return "Découpe le texte en chunks de taille fixe, en respectant optionnellement les limites de phrases"
}

// Chunk implémente l'interface ChunkingStrategy
func (fs *FixedSizeChunker) Chunk(text string, options ChunkingOptions) ([]*DocumentChunk, error) {
	if text == "" {
		return nil, fmt.Errorf("text cannot be empty")
	}

	// Valider les options
	if options.MaxChunkSize <= 0 {
		options.MaxChunkSize = 500 // Taille par défaut
	}
	if options.ChunkOverlap < 0 || options.ChunkOverlap >= options.MaxChunkSize {
		options.ChunkOverlap = options.MaxChunkSize / 10 // 10% par défaut
	}

	var chunks []*DocumentChunk
	textRunes := []rune(text)
	textLen := len(textRunes)

	// Position actuelle dans le texte
	pos := 0
	chunkIndex := 0

	for pos < textLen {
		// Calculer la fin théorique du chunk
		end := pos + options.MaxChunkSize
		if end > textLen {
			end = textLen
		}

		// Si on doit respecter les limites de phrases
		if options.PreserveStructure && end < textLen {
			// Chercher la fin de phrase la plus proche
			newEnd := end
			for i := end; i > pos; i-- {
				if isPunctuationMark(textRunes[i-1]) &&
					(i == textLen || unicode.IsSpace(textRunes[i])) {
					newEnd = i
					break
				}
			}
			// Si on a trouvé une fin de phrase pas trop éloignée
			if newEnd > pos+options.MaxChunkSize/2 {
				end = newEnd
			}
		}

		// Créer le chunk
		chunkText := string(textRunes[pos:end])

		// Ajouter du contexte si ce n'est pas le premier/dernier chunk
		var context string
		if pos > 0 || end < textLen {
			var contextParts []string

			// Contexte avant
			if pos > 0 {
				contextStart := pos - 50
				if contextStart < 0 {
					contextStart = 0
				}
				beforeCtx := string(textRunes[contextStart:pos])
				contextParts = append(contextParts, "Before: "+beforeCtx)
			}

			// Contexte après
			if end < textLen {
				contextEnd := end + 50
				if contextEnd > textLen {
					contextEnd = textLen
				}
				afterCtx := string(textRunes[end:contextEnd])
				contextParts = append(contextParts, "After: "+afterCtx)
			}

			context = strings.Join(contextParts, " | ")
		}

		// Générer un ID unique pour le chunk
		chunkHash := sha256.Sum256([]byte(fmt.Sprintf("%s-%d-%d", options.ParentDocumentID, pos, end)))
		chunkID := fmt.Sprintf("chunk-%x", chunkHash[:8])

		chunk := &DocumentChunk{
			ID:               chunkID,
			ParentDocumentID: options.ParentDocumentID,
			ChunkIndex:       chunkIndex,
			StartOffset:      pos,
			EndOffset:        end,
			Text:             chunkText,
			Context:          context,
			Metadata:         options.Metadata,
			CreatedAt:        time.Now(),
		}
		chunks = append(chunks, chunk)

		// Avancer au prochain chunk avec chevauchement
		pos = end - options.ChunkOverlap
		if pos >= textLen {
			break
		}
		if pos < 0 {
			pos = 0
		}
		chunkIndex++
	}

	return chunks, nil
}

// isPunctuationMark vérifie si un caractère est une marque de ponctuation qui termine une phrase
func isPunctuationMark(r rune) bool {
	return r == '.' || r == '!' || r == '?' || r == '\n'
}
