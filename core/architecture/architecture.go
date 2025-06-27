/*
Package architecture fournit des fonctions pour analyser la structure cible du projet et générer des rapports d’architecture.

Fonctions principales :
- ScanPatterns : détecte les patterns d’architecture dans le projet.
- ExportPatternsJSON : exporte les patterns détectés au format JSON.
- ExportGapAnalysis : génère un rapport markdown d’écarts d’architecture.

Utilisation typique :
patterns, err := architecture.ScanPatterns("chemin/du/projet")
err := architecture.ExportPatternsJSON(patterns, "architecture-patterns-scan.json")
err := architecture.ExportGapAnalysis(patterns, "ARCHITECTURE_GAP_ANALYSIS.md")
*/
package architecture

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

type Pattern struct {
	Name        string   `json:"name"`
	Files       []string `json:"files"`
	Description string   `json:"description"`
}

// ScanPatterns détecte les patterns d’architecture dans le dossier root.
func ScanPatterns(root string) ([]Pattern, error) {
	var patterns []Pattern
	var files []string
	filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		files = append(files, path)
		return nil
	})
	// Exemple : détection très simple (à adapter selon besoins réels)
	if len(files) > 0 {
		patterns = append(patterns, Pattern{
			Name:        "Fichiers présents",
			Files:       files,
			Description: "Liste brute des fichiers détectés (à spécialiser pour vrais patterns)",
		})
	}
	return patterns, nil
}

// ExportPatternsJSON exporte les patterns détectés au format JSON.
func ExportPatternsJSON(patterns []Pattern, outPath string) error {
	data, err := json.MarshalIndent(patterns, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(outPath, data, 0644)
}

// ExportGapAnalysis génère un rapport markdown d’écarts d’architecture.
func ExportGapAnalysis(patterns []Pattern, outPath string) error {
	f, err := os.Create(outPath)
	if err != nil {
		return err
	}
	defer f.Close()
	f.WriteString("# ARCHITECTURE_GAP_ANALYSIS.md\n\n| Pattern | Description | Nb fichiers |\n|---|---|---|\n")
	for _, p := range patterns {
		f.WriteString(fmt.Sprintf("| %s | %s | %d |\n", p.Name, p.Description, len(p.Files)))
	}
	return nil
}
