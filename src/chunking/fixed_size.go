package chunking

import (
	"crypto/sha256"
	"fmt"
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
		options.MaxChunkSize = 500
	}
	if options.ChunkOverlap < 0 {
		options.ChunkOverlap = 0
	}
	if options.ChunkOverlap >= options.MaxChunkSize {
		options.ChunkOverlap = options.MaxChunkSize - 1
	}

	textRunes := []rune(text)
	textLen := len(textRunes)
	chunks := make([]*DocumentChunk, 0)
	pos := 0
	chunkIndex := 0

	for pos < textLen { // Calculer la fin du chunk
		end := pos + options.MaxChunkSize
		if end > textLen {
			end = textLen
		}

		// Si ce n'est pas le dernier chunk possible, vérifier s'il reste assez de texte
		// pour justifier un chunk séparé
		remainingAfterChunk := textLen - end
		minChunkSize := options.MaxChunkSize / 4 // Taille minimale = 25% de MaxChunkSize
		if remainingAfterChunk > 0 && remainingAfterChunk < minChunkSize {
			// Si le reste est trop petit, l'inclure dans ce chunk
			end = textLen
		}

		// Si on préserve la structure ET qu'on n'est pas à la fin, chercher une fin de phrase
		if options.PreserveStructure && end < textLen {
			// Chercher en arrière d'abord (jusqu'à la moitié de MaxChunkSize)
			minEnd := pos + options.MaxChunkSize/2
			foundBoundary := false

			for i := end; i > minEnd; i-- {
				if isPunctuationMark(textRunes[i-1]) &&
					(i == textLen || unicode.IsSpace(textRunes[i])) {
					end = i
					foundBoundary = true
					break
				}
			}

			// Si pas trouvé en arrière, chercher en avant (permettre de dépasser MaxChunkSize)
			if !foundBoundary {
				maxSearch := pos + options.MaxChunkSize + 10 // Permettre 10 caractères de plus
				if maxSearch > textLen {
					maxSearch = textLen
				}
				for i := end; i < maxSearch; i++ {
					if isPunctuationMark(textRunes[i]) &&
						(i+1 == textLen || unicode.IsSpace(textRunes[i+1])) {
						end = i + 1
						break
					}
				}
			}
		}

		// Créer le chunk
		chunkText := string(textRunes[pos:end])
		hashBytes := sha256.Sum256([]byte(fmt.Sprintf("%s-%d", options.ParentDocumentID, chunkIndex)))
		chunkID := fmt.Sprintf("chunk-%x", hashBytes[:8])

		chunk := &DocumentChunk{
			ID:               chunkID,
			ParentDocumentID: options.ParentDocumentID,
			ChunkIndex:       chunkIndex,
			StartOffset:      pos,
			EndOffset:        end,
			Text:             chunkText,
			Metadata:         options.Metadata,
			CreatedAt:        time.Now(),
		}

		chunks = append(chunks, chunk)

		// Si on a traité tout le texte, arrêter
		if end >= textLen {
			break
		}

		// Calculer la prochaine position avec overlap
		nextPos := end - options.ChunkOverlap
		if nextPos <= pos {
			nextPos = pos + 1 // S'assurer qu'on progresse
		}
		pos = nextPos
		chunkIndex++

		// Protection contre les boucles infinies
		if chunkIndex > textLen {
			break
		}
	}

	return chunks, nil
}

// isPunctuationMark vérifie si un caractère est une marque de ponctuation qui termine une phrase
func isPunctuationMark(r rune) bool {
	return r == '.' || r == '!' || r == '?' || r == '\n'
}
