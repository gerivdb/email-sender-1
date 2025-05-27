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

	// Pré-allouer la slice pour éviter les réallocations
	estimatedChunks := (len(text) / (options.MaxChunkSize - options.ChunkOverlap)) + 1
	chunks := make([]*DocumentChunk, 0, estimatedChunks)

	textRunes := []rune(text)
	textLen := len(textRunes)
	pos := 0
	chunkIndex := 0

	for pos < textLen {
		// Calculer la fin théorique du chunk
		end := pos + options.MaxChunkSize
		if end > textLen {
			end = textLen
		}

		// Optimisation : ne chercher la fin de phrase que si nécessaire
		if options.PreserveStructure && end < textLen {
			// Recherche de la fin de phrase la plus proche, limité à 50 caractères en arrière
			searchLimit := end
			for i := end; i > pos && i > end-50; i-- {
				if isPunctuationMark(textRunes[i-1]) &&
					(i == textLen || unicode.IsSpace(textRunes[i])) {
					end = i
					break
				}
			}
			if end > searchLimit { // Si aucune fin de phrase trouvée
				end = searchLimit
			}
		}

		// Créer le chunk
		chunkText := string(textRunes[pos:end])

		// Générer un ID unique pour le chunk (optimisé)
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

		// Ajouter du contexte seulement si nécessaire et de manière optimisée
		if pos > 0 || end < textLen {
			var contextBuilder strings.Builder
			contextBuilder.Grow(200) // Pré-allouer pour la taille attendue

			if pos > 0 {
				contextStart := pos - 25 // Réduit à 25 caractères
				if contextStart < 0 {
					contextStart = 0
				}
				contextBuilder.WriteString("Before: ")
				contextBuilder.WriteString(string(textRunes[contextStart:pos]))
			}

			if end < textLen {
				if pos > 0 {
					contextBuilder.WriteString(" | ")
				}
				contextEnd := end + 25 // Réduit à 25 caractères
				if contextEnd > textLen {
					contextEnd = textLen
				}
				contextBuilder.WriteString("After: ")
				contextBuilder.WriteString(string(textRunes[end:contextEnd]))
			}

			chunk.Context = contextBuilder.String()
		}

		chunks = append(chunks, chunk)

		// Avancer au prochain chunk
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
