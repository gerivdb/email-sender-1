// cmd/auto-roadmap-runner/migrate.go
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

type Metadata struct {
	Authors string `json:"authors"`
	Date    string `json:"date"`
	Version string `json:"version"`
}

type Roadmap struct {
	ID         string    `json:"id"`
	Title      string    `json:"title"`
	Objectives string    `json:"objectives"`
	Sections   []string  `json:"sections"`
	Metadata   Metadata  `json:"metadata"`
	Links      []string  `json:"links"`
	Tags       []string  `json:"tags"`
	Embeddings []float64 `json:"embeddings"`
}

func RunMigration() {
	root := "projet/roadmaps/plans/consolidated"
	files, err := filepath.Glob(filepath.Join(root, "*.md"))
	if err != nil {
		fmt.Println("Erreur lors de la recherche des fichiers:", err)
		return
	}
	var roadmaps []Roadmap
	for _, file := range files {
		content, readErr := os.ReadFile(file)
		if readErr != nil {
			fmt.Printf("Erreur lecture %s: %v\n", file, readErr)
			continue
		}
		roadmap := Roadmap{
			ID:         filepath.Base(file),
			Title:      extractTitle(string(content)),
			Objectives: extractObjectives(string(content)),
			Sections:   extractSections(string(content)),
			Metadata:   extractMetadata(string(content)),
			Links:      extractLinks(string(content)),
			Tags:       extractTags(string(content)),
			Embeddings: []float64{}, // À calculer via modèle ML
		}
		roadmaps = append(roadmaps, roadmap)
	}
	data, marshalErr := json.MarshalIndent(roadmaps, "", "  ")
	if marshalErr != nil {
		fmt.Println("Erreur JSON:", marshalErr)
		return
	}
	writeErr := os.WriteFile(filepath.Join(root, "roadmaps.json"), data, 0o644)
	if writeErr != nil {
		fmt.Println("Erreur écriture roadmaps.json:", writeErr)
		return
	}
	fmt.Println("Migration terminée. Fichier généré: roadmaps.json")
}

// Fonctions d’extraction à compléter selon la structure Markdown
// Le paramètre content est intentionnellement inutilisé dans ces stubs
func extractTitle(_ string) string      { return "" }
func extractObjectives(_ string) string { return "" }
func extractSections(_ string) []string { return []string{} }
func extractMetadata(_ string) Metadata { return Metadata{} }
func extractLinks(_ string) []string    { return []string{} }
func extractTags(_ string) []string     { return []string{} }
